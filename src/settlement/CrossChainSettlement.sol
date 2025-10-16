// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "../interfaces/IYellowNetwork.sol";
import "../hooks/YellowStateChannel.sol";

/**
 * @title CrossChainSettlement
 * @dev Cross-chain MEV auction settlement using Yellow Network state channels
 * @notice Enables zero-gas bidding and cross-chain final settlement
 * @author MEVShield Pool Team
 */
contract CrossChainSettlement is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    
    /// @dev Yellow Network state channel contract
    YellowStateChannel public immutable stateChannelContract;
    
    /// @dev Cross-chain settlement configuration
    struct SettlementConfig {
        uint256 minimumSettlementAmount; // Minimum amount for cross-chain settlement
        uint256 settlementFee; // Fee for cross-chain settlement in basis points
        uint256 maxSettlementDelay; // Maximum delay for settlement finalization
        bool isActive; // Whether cross-chain settlement is active
    }
    
    /// @dev Cross-chain auction settlement data
    struct CrossChainAuction {
        bytes32 auctionId;
        bytes32 channelId;
        address winner;
        uint256 winningBid;
        uint256 targetChainId;
        uint256 createdAt;
        uint256 settlementDeadline;
        SettlementStatus status;
        bytes32 proofHash;
    }
    
    /// @dev Settlement status enumeration
    enum SettlementStatus {
        PENDING,
        PROCESSING,
        SETTLED,
        DISPUTED,
        CANCELLED
    }
    
    /// @dev Cross-chain proof structure for settlement verification
    struct CrossChainProof {
        bytes32 auctionId;
        bytes32 sourceBlockHash;
        bytes32 targetBlockHash;
        uint256 sourceChainId;
        uint256 targetChainId;
        bytes merkleProof;
        bytes validatorSignatures;
    }
    
    /// @dev Configuration for cross-chain settlement
    SettlementConfig public settlementConfig;
    
    /// @dev Mapping from auction ID to cross-chain auction data
    mapping(bytes32 => CrossChainAuction) public crossChainAuctions;
    
    /// @dev Mapping from channel ID to pending settlements
    mapping(bytes32 => bytes32[]) public channelSettlements;
    
    /// @dev Mapping of supported target chain IDs
    mapping(uint256 => bool) public supportedChains;
    
    /// @dev Array of all cross-chain auction IDs for enumeration
    bytes32[] public allAuctionIds;
    
    /// @dev Events for cross-chain settlement tracking
    event CrossChainAuctionCreated(
        bytes32 indexed auctionId,
        bytes32 indexed channelId,
        address indexed winner,
        uint256 winningBid,
        uint256 targetChainId
    );
    
    event SettlementInitiated(
        bytes32 indexed auctionId,
        uint256 targetChainId,
        bytes32 proofHash
    );
    
    event SettlementCompleted(
        bytes32 indexed auctionId,
        uint256 timestamp,
        uint256 finalAmount
    );
    
    event SettlementDisputed(
        bytes32 indexed auctionId,
        address indexed disputer,
        string reason
    );
    
    event ChainSupportUpdated(uint256 chainId, bool supported);
    
    /// @dev Constructor initializes settlement contract
    /// @param _stateChannelContract Address of the Yellow Network state channel contract
    /// @param _initialOwner Address that will own this contract
    constructor(
        address _stateChannelContract,
        address _initialOwner
    ) Ownable(_initialOwner) {
        stateChannelContract = YellowStateChannel(_stateChannelContract);
        
        // Initialize default settlement configuration
        settlementConfig = SettlementConfig({
            minimumSettlementAmount: 0.01 ether,
            settlementFee: 50, // 0.5% fee
            maxSettlementDelay: 24 hours,
            isActive: true
        });
        
        // Initialize supported chains (example chains)
        supportedChains[1] = true; // Ethereum Mainnet
        supportedChains[137] = true; // Polygon
        supportedChains[42161] = true; // Arbitrum One
        supportedChains[10] = true; // Optimism
    }
    
    /// @dev Create cross-chain auction settlement using state channel
    /// @param channelId State channel ID for settlement
    /// @param auctionWinner Address of the auction winner
    /// @param winningBidAmount Winning bid amount from auction
    /// @param targetChainId Chain ID where final settlement will occur
    /// @return auctionId Unique identifier for the cross-chain auction
    function createCrossChainAuction(
        bytes32 channelId,
        address auctionWinner,
        uint256 winningBidAmount,
        uint256 targetChainId
    ) external nonReentrant returns (bytes32 auctionId) {
        require(settlementConfig.isActive, "Settlement not active");
        require(supportedChains[targetChainId], "Chain not supported");
        require(winningBidAmount >= settlementConfig.minimumSettlementAmount, "Amount too low");
        require(auctionWinner != address(0), "Invalid winner");
        
        // Verify channel exists and caller is participant
        YellowStateChannel.EnhancedStateChannel memory channel = stateChannelContract.getChannel(channelId);
        require(channel.isActive, "Channel not active");
        require(
            msg.sender == channel.participant1 || msg.sender == channel.participant2,
            "Unauthorized caller"
        );
        
        // Generate unique auction ID
        auctionId = keccak256(abi.encodePacked(
            channelId,
            auctionWinner,
            winningBidAmount,
            targetChainId,
            block.timestamp,
            allAuctionIds.length
        ));
        
        // Create cross-chain auction
        crossChainAuctions[auctionId] = CrossChainAuction({
            auctionId: auctionId,
            channelId: channelId,
            winner: auctionWinner,
            winningBid: winningBidAmount,
            targetChainId: targetChainId,
            createdAt: block.timestamp,
            settlementDeadline: block.timestamp + settlementConfig.maxSettlementDelay,
            status: SettlementStatus.PENDING,
            proofHash: bytes32(0)
        });
        
        // Track settlement for channel
        channelSettlements[channelId].push(auctionId);
        allAuctionIds.push(auctionId);
        
        emit CrossChainAuctionCreated(
            auctionId,
            channelId,
            auctionWinner,
            winningBidAmount,
            targetChainId
        );
        
        return auctionId;
    }
    
    /// @dev Initiate settlement with cross-chain proof
    /// @param auctionId Unique identifier for the auction
    /// @param proof Cross-chain proof for settlement verification
    function initiateSettlement(
        bytes32 auctionId,
        CrossChainProof calldata proof
    ) external nonReentrant {
        CrossChainAuction storage auction = crossChainAuctions[auctionId];
        
        require(auction.status == SettlementStatus.PENDING, "Invalid status");
        require(block.timestamp <= auction.settlementDeadline, "Settlement expired");
        require(proof.auctionId == auctionId, "Proof mismatch");
        require(proof.targetChainId == auction.targetChainId, "Chain mismatch");
        
        // Verify cross-chain proof
        _verifycrossChainProof(proof);
        
        // Update auction status
        auction.status = SettlementStatus.PROCESSING;
        auction.proofHash = keccak256(abi.encode(proof));
        
        emit SettlementInitiated(auctionId, auction.targetChainId, auction.proofHash);
    }
    
    /// @dev Complete settlement after verification
    /// @param auctionId Unique identifier for the auction
    function completeSettlement(bytes32 auctionId) external nonReentrant {
        CrossChainAuction storage auction = crossChainAuctions[auctionId];
        
        require(auction.status == SettlementStatus.PROCESSING, "Invalid status");
        require(auction.proofHash != bytes32(0), "No proof submitted");
        
        // Calculate settlement amount after fees
        uint256 settlementFeeAmount = (auction.winningBid * settlementConfig.settlementFee) / 10000;
        uint256 finalAmount = auction.winningBid - settlementFeeAmount;
        
        // Update auction status
        auction.status = SettlementStatus.SETTLED;
        
        // Transfer settlement amount to winner
        payable(auction.winner).transfer(finalAmount);
        
        // Transfer fee to contract owner
        if (settlementFeeAmount > 0) {
            payable(owner()).transfer(settlementFeeAmount);
        }
        
        emit SettlementCompleted(auctionId, block.timestamp, finalAmount);
    }
    
    /// @dev Dispute a settlement
    /// @param auctionId Unique identifier for the auction
    /// @param reason Reason for the dispute
    function disputeSettlement(bytes32 auctionId, string calldata reason) external {
        CrossChainAuction storage auction = crossChainAuctions[auctionId];
        
        require(
            auction.status == SettlementStatus.PROCESSING || 
            auction.status == SettlementStatus.PENDING,
            "Cannot dispute"
        );
        
        // Verify caller is authorized to dispute
        YellowStateChannel.EnhancedStateChannel memory channel = stateChannelContract.getChannel(auction.channelId);
        require(
            msg.sender == channel.participant1 || 
            msg.sender == channel.participant2 ||
            msg.sender == auction.winner,
            "Unauthorized disputer"
        );
        
        auction.status = SettlementStatus.DISPUTED;
        
        emit SettlementDisputed(auctionId, msg.sender, reason);
    }
    
    /// @dev Verify cross-chain proof (simplified implementation)
    /// @param proof Cross-chain proof to verify
    function _verifycrossChainProof(CrossChainProof calldata proof) internal pure {
        // Simplified proof verification for demonstration
        // In production, would verify Merkle proofs, validator signatures, etc.
        require(proof.merkleProof.length > 0, "Invalid Merkle proof");
        require(proof.validatorSignatures.length > 0, "Invalid validator signatures");
        require(proof.sourceBlockHash != bytes32(0), "Invalid source block");
        require(proof.targetBlockHash != bytes32(0), "Invalid target block");
    }
    
    /// @dev Update settlement configuration
    /// @param minimumAmount New minimum settlement amount
    /// @param feeInBps New settlement fee in basis points
    /// @param maxDelay New maximum settlement delay
    function updateSettlementConfig(
        uint256 minimumAmount,
        uint256 feeInBps,
        uint256 maxDelay
    ) external onlyOwner {
        require(feeInBps <= 1000, "Fee too high"); // Max 10%
        require(maxDelay <= 7 days, "Delay too long");
        
        settlementConfig.minimumSettlementAmount = minimumAmount;
        settlementConfig.settlementFee = feeInBps;
        settlementConfig.maxSettlementDelay = maxDelay;
    }
    
    /// @dev Add or remove supported chain
    /// @param chainId Chain ID to update support for
    /// @param supported Whether the chain is supported
    function updateChainSupport(uint256 chainId, bool supported) external onlyOwner {
        require(chainId != 0, "Invalid chain ID");
        supportedChains[chainId] = supported;
        emit ChainSupportUpdated(chainId, supported);
    }
    
    /// @dev Cancel expired settlement
    /// @param auctionId Unique identifier for the auction
    function cancelExpiredSettlement(bytes32 auctionId) external {
        CrossChainAuction storage auction = crossChainAuctions[auctionId];
        
        require(auction.status == SettlementStatus.PENDING, "Cannot cancel");
        require(block.timestamp > auction.settlementDeadline, "Not expired");
        
        auction.status = SettlementStatus.CANCELLED;
        
        // Return funds to channel
        // In production, would update state channel balance
    }
    
    /// @dev Get auction details
    /// @param auctionId Unique identifier for the auction
    /// @return auction Complete auction data
    function getAuction(bytes32 auctionId) external view returns (CrossChainAuction memory auction) {
        return crossChainAuctions[auctionId];
    }
    
    /// @dev Get all settlements for a channel
    /// @param channelId State channel ID
    /// @return auctionIds Array of auction IDs for the channel
    function getChannelSettlements(bytes32 channelId) external view returns (bytes32[] memory auctionIds) {
        return channelSettlements[channelId];
    }
    
    /// @dev Get total number of auctions created
    /// @return count Total auction count
    function getTotalAuctions() external view returns (uint256 count) {
        return allAuctionIds.length;
    }
    
    /// @dev Emergency withdrawal function
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }
    
    /// @dev Receive function to accept ETH
    receive() external payable {}
}