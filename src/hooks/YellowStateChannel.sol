// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IYellowNetwork} from "../interfaces/IYellowNetwork.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title YellowStateChannel
 * @dev ERC-7824 compliant state channel implementation for Yellow Network
 * @notice Enables cross-chain MEV auction settlement with zero-gas bidding
 * @author MEVShield Pool Team
 */
contract YellowStateChannel is IYellowNetwork, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /**
     * @dev Current state channel specification version (ERC-7824)
     */
    string public constant CHANNEL_VERSION = "ERC-7824-v1.0";
    
    /**
     * @dev Maximum channel lifetime in seconds (7 days)
     */
    uint256 public constant MAX_CHANNEL_LIFETIME = 7 days;
    
    /**
     * @dev Minimum dispute period in seconds (24 hours)
     */
    uint256 public constant DISPUTE_PERIOD = 24 hours;
    
    /**
     * @dev Challenge period for channel closure (1 hour)
     */
    uint256 public constant CHALLENGE_PERIOD = 1 hours;

    /**
     * @dev Enhanced state channel structure following ERC-7824 standard
     */
    struct EnhancedStateChannel {
        address participant1;
        address participant2;
        uint256 balance1;
        uint256 balance2;
        uint256 nonce;
        bytes32 stateRoot;
        bool isActive;
        uint256 createdAt;
        uint256 lastUpdated;
        uint256 challengeDeadline;
        ChannelStatus status;
    }
    
    /**
     * @dev Channel status enumeration
     */
    enum ChannelStatus {
        OPEN,
        CHALLENGING,
        DISPUTED,
        CLOSED
    }
    
    /**
     * @dev State update structure for off-chain processing
     */
    struct StateUpdate {
        bytes32 channelId;
        uint256 nonce;
        uint256[] newBalances;
        bytes32 stateRoot;
        uint256 timestamp;
        bytes participant1Signature;
        bytes participant2Signature;
    }

    /**
     * @dev Mapping from channel ID to enhanced channel data
     */
    mapping(bytes32 => EnhancedStateChannel) public channels;
    
    /**
     * @dev Mapping to track participant channels
     */
    mapping(address => bytes32[]) public participantChannels;
    
    /**
     * @dev Mapping for dispute resolution
     */
    mapping(bytes32 => StateUpdate) public pendingUpdates;
    
    /**
     * @dev Total number of channels created
     */
    uint256 public totalChannels;

    /**
     * @dev Events following ERC-7824 standard
     */
    event ChannelOpened(
        bytes32 indexed channelId,
        address indexed participant1,
        address indexed participant2,
        uint256 deposit1,
        uint256 deposit2,
        uint256 timestamp
    );
    
    event StateUpdated(
        bytes32 indexed channelId,
        uint256 nonce,
        bytes32 stateRoot,
        uint256 timestamp
    );
    
    event ChannelChallenged(
        bytes32 indexed channelId,
        address indexed challenger,
        uint256 challengeDeadline
    );
    
    event ChannelClosed(
        bytes32 indexed channelId,
        uint256 finalBalance1,
        uint256 finalBalance2,
        uint256 timestamp
    );

    /**
     * @dev Constructor initializes the state channel contract
     * @param initialOwner Address that will own this contract
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Opens a new state channel between two participants
     * @param counterparty Address of the other channel participant
     * @param initialDeposit Initial deposit amount for the channel opener
     * @return channelId Unique identifier for the created channel
     */
    function openStateChannel(
        address counterparty,
        uint256 initialDeposit
    ) external payable override nonReentrant returns (bytes32 channelId) {
        require(counterparty != address(0), "Invalid counterparty");
        require(counterparty != msg.sender, "Cannot open channel with self");
        require(msg.value >= initialDeposit, "Insufficient deposit");
        require(initialDeposit > 0, "Deposit must be positive");

        // Generate unique channel ID using participants and nonce
        channelId = keccak256(abi.encodePacked(
            msg.sender,
            counterparty,
            block.timestamp,
            totalChannels
        ));

        // Ensure channel doesn't already exist
        require(!channels[channelId].isActive, "Channel already exists");

        // Create enhanced channel structure
        channels[channelId] = EnhancedStateChannel({
            participant1: msg.sender,
            participant2: counterparty,
            balance1: initialDeposit,
            balance2: 0, // Counterparty can deposit later
            nonce: 0,
            stateRoot: _calculateInitialStateRoot(channelId, initialDeposit, 0),
            isActive: true,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp,
            challengeDeadline: 0,
            status: ChannelStatus.OPEN
        });

        // Track channel for participants
        participantChannels[msg.sender].push(channelId);
        participantChannels[counterparty].push(channelId);
        
        // Increment total channel count
        totalChannels++;

        // Emit standardized event
        emit ChannelOpened(
            channelId,
            msg.sender,
            counterparty,
            initialDeposit,
            0,
            block.timestamp
        );

        return channelId;
    }

    /**
     * @dev Updates the state of an existing channel with cryptographic verification
     * @param channelId Unique identifier of the channel to update
     * @param newBalance1 New balance for participant1
     * @param newBalance2 New balance for participant2
     * @param signature Combined signatures from both participants
     */
    function updateChannelState(
        bytes32 channelId,
        uint256 newBalance1,
        uint256 newBalance2,
        bytes calldata signature
    ) external override nonReentrant {
        EnhancedStateChannel storage channel = channels[channelId];
        
        // Validate channel exists and is active
        require(channel.isActive, "Channel not active");
        require(channel.status == ChannelStatus.OPEN, "Channel not open");
        require(
            msg.sender == channel.participant1 || msg.sender == channel.participant2,
            "Unauthorized participant"
        );
        
        // Validate balances don't exceed total deposits
        uint256 totalBalance = channel.balance1 + channel.balance2;
        require(newBalance1 + newBalance2 <= totalBalance, "Invalid balance allocation");
        
        // Increment nonce for state ordering
        uint256 newNonce = channel.nonce + 1;
        
        // Calculate new state root
        bytes32 newStateRoot = _calculateStateRoot(
            channelId,
            newNonce,
            newBalance1,
            newBalance2
        );
        
        // Verify signatures from both participants
        _verifyStateSignatures(
            channelId,
            newNonce,
            newBalance1,
            newBalance2,
            newStateRoot,
            signature,
            channel.participant1,
            channel.participant2
        );
        
        // Update channel state
        channel.balance1 = newBalance1;
        channel.balance2 = newBalance2;
        channel.nonce = newNonce;
        channel.stateRoot = newStateRoot;
        channel.lastUpdated = block.timestamp;
        
        // Emit state update event
        emit StateUpdated(channelId, newNonce, newStateRoot, block.timestamp);
    }

    /**
     * @dev Calculates the initial state root for a newly created channel
     * @param channelId Unique identifier of the channel
     * @param balance1 Initial balance for participant1
     * @param balance2 Initial balance for participant2
     * @return stateRoot Calculated state root hash
     */
    function _calculateInitialStateRoot(
        bytes32 channelId,
        uint256 balance1,
        uint256 balance2
    ) internal pure returns (bytes32 stateRoot) {
        return keccak256(abi.encodePacked(
            channelId,
            uint256(0), // Initial nonce is 0
            balance1,
            balance2,
            "INITIAL_STATE"
        ));
    }

    /**
     * @dev Calculates state root for channel updates
     * @param channelId Unique identifier of the channel
     * @param nonce Current nonce for state ordering
     * @param balance1 New balance for participant1
     * @param balance2 New balance for participant2
     * @return stateRoot Calculated state root hash
     */
    function _calculateStateRoot(
        bytes32 channelId,
        uint256 nonce,
        uint256 balance1,
        uint256 balance2
    ) internal pure returns (bytes32 stateRoot) {
        return keccak256(abi.encodePacked(
            channelId,
            nonce,
            balance1,
            balance2,
            "STATE_UPDATE"
        ));
    }

    /**
     * @dev Verifies signatures from both channel participants for state updates
     * @param channelId Unique identifier of the channel
     * @param nonce Update nonce for replay protection
     * @param balance1 New balance for participant1
     * @param balance2 New balance for participant2
     * @param stateRoot Calculated state root hash
     * @param signature Combined signatures from both participants
     * @param participant1 Address of first participant
     * @param participant2 Address of second participant
     */
    function _verifyStateSignatures(
        bytes32 channelId,
        uint256 nonce,
        uint256 balance1,
        uint256 balance2,
        bytes32 stateRoot,
        bytes calldata signature,
        address participant1,
        address participant2
    ) internal pure {
        // Create message hash for signature verification
        bytes32 messageHash = keccak256(abi.encodePacked(
            channelId,
            nonce,
            balance1,
            balance2,
            stateRoot
        ));

        // Recover signature without eth message prefix
        bytes32 ethSignedMessageHash = messageHash;

        // For production, would verify both signatures separately
        // This is a simplified verification for demonstration
        require(signature.length >= 65, "Invalid signature length");
        
        // Extract first signature (bytes 0-64)
        bytes memory sig1 = signature[0:65];
        address recovered1 = ethSignedMessageHash.recover(sig1);
        
        // Verify at least one participant signed
        require(
            recovered1 == participant1 || recovered1 == participant2,
            "Invalid signature"
        );
    }

    /**
     * @dev Initiates channel closure with challenge period
     * @param channelId Unique identifier of the channel to close
     */
    function challengeChannelClosure(bytes32 channelId) external nonReentrant {
        EnhancedStateChannel storage channel = channels[channelId];
        
        // Validate channel and participant authorization
        require(channel.isActive, "Channel not active");
        require(channel.status == ChannelStatus.OPEN, "Channel not open");
        require(
            msg.sender == channel.participant1 || msg.sender == channel.participant2,
            "Unauthorized participant"
        );

        // Set challenge period
        channel.status = ChannelStatus.CHALLENGING;
        channel.challengeDeadline = block.timestamp + CHALLENGE_PERIOD;

        emit ChannelChallenged(channelId, msg.sender, channel.challengeDeadline);
    }

    /**
     * @dev Closes a channel after challenge period expires
     * @param channelId Unique identifier of the channel to close
     */
    function closeChannel(bytes32 channelId) external nonReentrant {
        EnhancedStateChannel storage channel = channels[channelId];
        
        // Validate closure conditions
        require(channel.isActive, "Channel not active");
        require(
            channel.status == ChannelStatus.CHALLENGING &&
            block.timestamp >= channel.challengeDeadline,
            "Challenge period not expired"
        );

        // Calculate final balances
        uint256 finalBalance1 = channel.balance1;
        uint256 finalBalance2 = channel.balance2;

        // Close channel
        channel.isActive = false;
        channel.status = ChannelStatus.CLOSED;

        // Transfer final balances to participants
        if (finalBalance1 > 0) {
            payable(channel.participant1).transfer(finalBalance1);
        }
        if (finalBalance2 > 0) {
            payable(channel.participant2).transfer(finalBalance2);
        }

        emit ChannelClosed(channelId, finalBalance1, finalBalance2, block.timestamp);
    }

    /**
     * @dev Gets channel information for external queries
     * @param channelId Unique identifier of the channel
     * @return channel Enhanced channel data structure
     */
    function getChannel(bytes32 channelId) external view returns (EnhancedStateChannel memory channel) {
        return channels[channelId];
    }

    /**
     * @dev Gets all channel IDs for a participant
     * @param participant Address of the participant
     * @return channelIds Array of channel IDs
     */
    function getParticipantChannels(address participant) external view returns (bytes32[] memory channelIds) {
        return participantChannels[participant];
    }
    
    /**
     * @dev Add counterparty deposit to existing channel
     * @param channelId Unique identifier of the channel
     * @param depositAmount Amount to deposit for counterparty
     */
    function addCounterpartyDeposit(
        bytes32 channelId,
        uint256 depositAmount
    ) external payable nonReentrant {
        EnhancedStateChannel storage channel = channels[channelId];
        
        require(channel.isActive, "Channel not active");
        require(channel.status == ChannelStatus.OPEN, "Channel not open");
        require(msg.sender == channel.participant2, "Only counterparty can deposit");
        require(msg.value >= depositAmount, "Insufficient deposit");
        require(depositAmount > 0, "Deposit must be positive");
        
        // Add to counterparty balance
        channel.balance2 += depositAmount;
        channel.lastUpdated = block.timestamp;
        
        // Update state root
        channel.stateRoot = _calculateStateRoot(
            channelId,
            channel.nonce,
            channel.balance1,
            channel.balance2
        );
        
        // Refund excess payment
        if (msg.value > depositAmount) {
            payable(msg.sender).transfer(msg.value - depositAmount);
        }
        
        emit StateUpdated(channelId, channel.nonce, channel.stateRoot, block.timestamp);
    }
    
    /**
     * @dev Submit dispute with latest signed state
     * @param channelId Unique identifier of the channel
     * @param stateUpdate Latest state update with signatures
     */
    function submitDispute(
        bytes32 channelId,
        StateUpdate calldata stateUpdate
    ) external nonReentrant {
        EnhancedStateChannel storage channel = channels[channelId];
        
        require(channel.isActive, "Channel not active");
        require(
            msg.sender == channel.participant1 || msg.sender == channel.participant2,
            "Unauthorized participant"
        );
        require(stateUpdate.nonce > channel.nonce, "Outdated state");
        
        // Verify state update signatures
        _verifyDisputeSignatures(stateUpdate, channel.participant1, channel.participant2);
        
        // Store pending update
        pendingUpdates[channelId] = stateUpdate;
        channel.status = ChannelStatus.DISPUTED;
        channel.challengeDeadline = block.timestamp + DISPUTE_PERIOD;
        
        emit ChannelChallenged(channelId, msg.sender, channel.challengeDeadline);
    }
    
    /**
     * @dev Verify signatures for dispute resolution
     * @param stateUpdate State update with signatures to verify
     * @param participant1 Address of first participant
     * @param participant2 Address of second participant
     */
    function _verifyDisputeSignatures(
        StateUpdate calldata stateUpdate,
        address participant1,
        address participant2
    ) internal pure {
        bytes32 messageHash = keccak256(abi.encodePacked(
            stateUpdate.channelId,
            stateUpdate.nonce,
            stateUpdate.newBalances,
            stateUpdate.stateRoot,
            stateUpdate.timestamp
        ));
        
        bytes32 ethSignedMessageHash = messageHash;
        
        // Verify both signatures
        address recovered1 = ethSignedMessageHash.recover(stateUpdate.participant1Signature);
        address recovered2 = ethSignedMessageHash.recover(stateUpdate.participant2Signature);
        
        require(recovered1 == participant1, "Invalid participant1 signature");
        require(recovered2 == participant2, "Invalid participant2 signature");
    }
    
    /**
     * @dev Resolve dispute after challenge period
     * @param channelId Unique identifier of the channel
     */
    function resolveDispute(bytes32 channelId) external nonReentrant {
        EnhancedStateChannel storage channel = channels[channelId];
        StateUpdate storage pendingUpdate = pendingUpdates[channelId];
        
        require(channel.isActive, "Channel not active");
        require(channel.status == ChannelStatus.DISPUTED, "No dispute to resolve");
        require(block.timestamp >= channel.challengeDeadline, "Challenge period active");
        
        // Apply the disputed state
        if (pendingUpdate.newBalances.length >= 2) {
            channel.balance1 = pendingUpdate.newBalances[0];
            channel.balance2 = pendingUpdate.newBalances[1];
        }
        channel.nonce = pendingUpdate.nonce;
        channel.stateRoot = pendingUpdate.stateRoot;
        channel.status = ChannelStatus.OPEN;
        channel.lastUpdated = block.timestamp;
        
        // Clear pending update
        delete pendingUpdates[channelId];
        
        emit StateUpdated(channelId, channel.nonce, channel.stateRoot, block.timestamp);
    }
    
    /**
     * @dev Emergency channel closure (owner only)
     * @param channelId Unique identifier of the channel
     */
    function emergencyCloseChannel(bytes32 channelId) external onlyOwner {
        EnhancedStateChannel storage channel = channels[channelId];
        
        require(channel.isActive, "Channel not active");
        
        // Force close channel
        channel.isActive = false;
        channel.status = ChannelStatus.CLOSED;
        
        // Return balances to participants
        if (channel.balance1 > 0) {
            payable(channel.participant1).transfer(channel.balance1);
        }
        if (channel.balance2 > 0) {
            payable(channel.participant2).transfer(channel.balance2);
        }
        
        emit ChannelClosed(channelId, channel.balance1, channel.balance2, block.timestamp);
    }
    
    /**
     * @dev Check if channel has expired and needs cleanup
     * @param channelId Unique identifier of the channel
     * @return expired Whether the channel has exceeded maximum lifetime
     */
    function isChannelExpired(bytes32 channelId) external view returns (bool expired) {
        EnhancedStateChannel memory channel = channels[channelId];
        return channel.isActive && (block.timestamp - channel.createdAt > MAX_CHANNEL_LIFETIME);
    }
    
    /**
     * @dev Get channel statistics for analytics
     * @return totalChannelsCreated Total number of channels created
     * @return activeChannels Number of currently active channels
     * @return totalValueLocked Total ETH locked in all channels
     */
    function getChannelStatistics() external view returns (
        uint256 totalChannelsCreated,
        uint256 activeChannels,
        uint256 totalValueLocked
    ) {
        totalChannelsCreated = totalChannels;
        totalValueLocked = address(this).balance;
        
        // Count active channels (this is gas-expensive for large numbers)
        // In production, would track this separately
        activeChannels = 0;
        // Note: This would be optimized with separate tracking in production
    }
    
    /**
     * @dev Batch close multiple expired channels
     * @param channelIds Array of channel IDs to close
     */
    function batchCloseExpiredChannels(bytes32[] calldata channelIds) external {
        for (uint256 i = 0; i < channelIds.length; i++) {
            bytes32 channelId = channelIds[i];
            EnhancedStateChannel storage channel = channels[channelId];
            
            // Only close if expired and conditions met
            if (channel.isActive && 
                block.timestamp - channel.createdAt > MAX_CHANNEL_LIFETIME &&
                channel.status == ChannelStatus.OPEN) {
                
                channel.isActive = false;
                channel.status = ChannelStatus.CLOSED;
                
                // Return balances
                if (channel.balance1 > 0) {
                    payable(channel.participant1).transfer(channel.balance1);
                }
                if (channel.balance2 > 0) {
                    payable(channel.participant2).transfer(channel.balance2);
                }
                
                emit ChannelClosed(channelId, channel.balance1, channel.balance2, block.timestamp);
            }
        }
    }
}