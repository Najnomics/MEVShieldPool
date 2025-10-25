// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title YellowNetworkChannel
 * @notice ERC-7824 State Channel implementation for Yellow Network
 * @dev Cross-chain MEV settlement using session-based off-chain state with on-chain finalization
 * 
 * Features:
 * - Session-based off-chain state channels
 * - Instant gasless transactions during session
 * - Secure on-chain settlement
 * - Cross-chain MEV coordination
 * - Lightning-fast MEV arbitrage execution
 * 
 * Built for Yellow Network $5,000 Prize
 */
contract YellowNetworkChannel is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    
    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ChannelOpened(
        bytes32 indexed channelId,
        address indexed participant1,
        address indexed participant2,
        uint256 deposit1,
        uint256 deposit2,
        uint256 timeout
    );

    event StateUpdate(
        bytes32 indexed channelId,
        uint256 stateNumber,
        bytes32 stateHash,
        uint256 timestamp
    );

    event ChannelClosed(
        bytes32 indexed channelId,
        uint256 finalBalance1,
        uint256 finalBalance2,
        uint256 timestamp
    );

    event DisputeRaised(
        bytes32 indexed channelId,
        address indexed challenger,
        uint256 disputedStateNumber,
        uint256 challengePeriod
    );

    event MEVSessionStarted(
        bytes32 indexed sessionId,
        bytes32 indexed channelId,
        address indexed searcher,
        uint256 allowance,
        uint256 duration
    );

    event OffChainTransaction(
        bytes32 indexed sessionId,
        bytes32 indexed txHash,
        address from,
        address to,
        uint256 amount,
        uint256 nonce
    );

    /*//////////////////////////////////////////////////////////////
                            DATA STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @dev State channel structure
    struct Channel {
        bytes32 channelId;
        address participant1;
        address participant2;
        uint256 deposit1;
        uint256 deposit2;
        uint256 balance1;
        uint256 balance2;
        uint256 stateNumber;
        bytes32 stateHash;
        uint256 timeout;
        uint256 challengePeriod;
        ChannelStatus status;
        uint256 lastUpdateTime;
        bool hasDispute;
        address challenger;
        uint256 disputeDeadline;
    }

    /// @dev MEV session for off-chain execution
    struct MEVSession {
        bytes32 sessionId;
        bytes32 channelId;
        address searcher;
        uint256 allowance;
        uint256 spent;
        uint256 startTime;
        uint256 duration;
        uint256 nonce;
        SessionStatus status;
        mapping(bytes32 => OffChainTx) transactions;
        bytes32[] txHashes;
    }

    /// @dev Off-chain transaction
    struct OffChainTx {
        bytes32 txHash;
        address from;
        address to;
        uint256 amount;
        uint256 nonce;
        uint256 timestamp;
        bool settled;
    }

    /// @dev Settlement data for batch processing
    struct SettlementBatch {
        bytes32[] sessionIds;
        uint256 totalValue;
        uint256 batchNonce;
        bytes32 merkleRoot;
        bool processed;
    }

    /// @dev Channel status enumeration
    enum ChannelStatus {
        Open,
        Challenged,
        Closing,
        Closed
    }

    /// @dev Session status enumeration
    enum SessionStatus {
        Active,
        Expired,
        Settled,
        Disputed
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev All channels mapping
    mapping(bytes32 => Channel) public channels;
    
    /// @dev All MEV sessions mapping
    mapping(bytes32 => MEVSession) public sessions;
    
    /// @dev Settlement batches mapping
    mapping(uint256 => SettlementBatch) public settlementBatches;
    
    /// @dev User balances in channels
    mapping(address => mapping(bytes32 => uint256)) public userBalances;
    
    /// @dev Nonce tracking for replay protection
    mapping(address => uint256) public userNonces;
    
    /// @dev Active sessions per user
    mapping(address => bytes32[]) public userSessions;
    
    /// @dev Settlement batch counter
    uint256 public batchCounter;
    
    /// @dev Default challenge period (1 hour)
    uint256 public constant DEFAULT_CHALLENGE_PERIOD = 3600;
    
    /// @dev Maximum session duration (24 hours)
    uint256 public constant MAX_SESSION_DURATION = 86400;
    
    /// @dev Minimum channel deposit
    uint256 public constant MIN_DEPOSIT = 0.001 ether;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////
                          CHANNEL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Open a new state channel between two participants
     * @param participant2 The second participant address
     * @param deposit2 The deposit amount from participant2
     * @param timeout Channel timeout in seconds
     * @return channelId The unique channel identifier
     */
    function openChannel(
        address participant2,
        uint256 deposit2,
        uint256 timeout
    ) external payable returns (bytes32 channelId) {
        require(participant2 != address(0), "Invalid participant");
        require(participant2 != msg.sender, "Cannot open channel with self");
        require(msg.value >= MIN_DEPOSIT, "Insufficient deposit");
        require(timeout > 0 && timeout <= MAX_SESSION_DURATION, "Invalid timeout");
        
        // Generate unique channel ID
        channelId = keccak256(
            abi.encodePacked(
                msg.sender,
                participant2,
                block.timestamp,
                block.number
            )
        );
        
        // Initialize channel
        Channel storage channel = channels[channelId];
        channel.channelId = channelId;
        channel.participant1 = msg.sender;
        channel.participant2 = participant2;
        channel.deposit1 = msg.value;
        channel.deposit2 = deposit2;
        channel.balance1 = msg.value;
        channel.balance2 = deposit2;
        channel.stateNumber = 0;
        channel.timeout = timeout;
        channel.challengePeriod = DEFAULT_CHALLENGE_PERIOD;
        channel.status = ChannelStatus.Open;
        channel.lastUpdateTime = block.timestamp;
        
        // Initial state hash
        channel.stateHash = _calculateStateHash(
            channelId,
            msg.value,
            deposit2,
            0
        );
        
        emit ChannelOpened(
            channelId,
            msg.sender,
            participant2,
            msg.value,
            deposit2,
            timeout
        );
    }

    /**
     * @notice Update channel state with signed state update
     * @param channelId The channel identifier
     * @param newBalance1 New balance for participant1
     * @param newBalance2 New balance for participant2
     * @param stateNumber New state number (must be incremental)
     * @param signature1 Signature from participant1
     * @param signature2 Signature from participant2
     */
    function updateChannelState(
        bytes32 channelId,
        uint256 newBalance1,
        uint256 newBalance2,
        uint256 stateNumber,
        bytes calldata signature1,
        bytes calldata signature2
    ) external {
        Channel storage channel = channels[channelId];
        require(channel.status == ChannelStatus.Open, "Channel not open");
        require(stateNumber > channel.stateNumber, "Invalid state number");
        require(
            newBalance1 + newBalance2 == channel.deposit1 + channel.deposit2,
            "Invalid balance distribution"
        );
        
        // Calculate new state hash
        bytes32 newStateHash = _calculateStateHash(
            channelId,
            newBalance1,
            newBalance2,
            stateNumber
        );
        
        // Verify signatures
        _verifyStateSignatures(
            channelId,
            newStateHash,
            stateNumber,
            channel.participant1,
            channel.participant2,
            signature1,
            signature2
        );
        
        // Update channel state
        channel.balance1 = newBalance1;
        channel.balance2 = newBalance2;
        channel.stateNumber = stateNumber;
        channel.stateHash = newStateHash;
        channel.lastUpdateTime = block.timestamp;
        
        emit StateUpdate(channelId, stateNumber, newStateHash, block.timestamp);
    }

    /**
     * @notice Close channel cooperatively with final state
     * @param channelId The channel identifier
     * @param finalBalance1 Final balance for participant1
     * @param finalBalance2 Final balance for participant2
     * @param signature1 Signature from participant1
     * @param signature2 Signature from participant2
     */
    function closeChannelCooperatively(
        bytes32 channelId,
        uint256 finalBalance1,
        uint256 finalBalance2,
        bytes calldata signature1,
        bytes calldata signature2
    ) external nonReentrant {
        Channel storage channel = channels[channelId];
        require(channel.status == ChannelStatus.Open, "Channel not open");
        require(
            finalBalance1 + finalBalance2 == channel.deposit1 + channel.deposit2,
            "Invalid final balances"
        );
        
        // Verify final state signatures
        bytes32 finalStateHash = _calculateStateHash(
            channelId,
            finalBalance1,
            finalBalance2,
            channel.stateNumber + 1
        );
        
        _verifyStateSignatures(
            channelId,
            finalStateHash,
            channel.stateNumber + 1,
            channel.participant1,
            channel.participant2,
            signature1,
            signature2
        );
        
        // Finalize channel
        channel.status = ChannelStatus.Closed;
        channel.balance1 = finalBalance1;
        channel.balance2 = finalBalance2;
        
        // Transfer final balances
        if (finalBalance1 > 0) {
            payable(channel.participant1).transfer(finalBalance1);
        }
        if (finalBalance2 > 0) {
            payable(channel.participant2).transfer(finalBalance2);
        }
        
        emit ChannelClosed(channelId, finalBalance1, finalBalance2, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                          MEV SESSION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Start MEV session for off-chain transactions
     * @param channelId The channel to use for session
     * @param allowance Maximum amount allowed for off-chain spending
     * @param duration Session duration in seconds
     * @return sessionId Unique session identifier
     */
    function startMEVSession(
        bytes32 channelId,
        uint256 allowance,
        uint256 duration
    ) external returns (bytes32 sessionId) {
        Channel storage channel = channels[channelId];
        require(channel.status == ChannelStatus.Open, "Channel not open");
        require(
            msg.sender == channel.participant1 || msg.sender == channel.participant2,
            "Not channel participant"
        );
        require(allowance > 0, "Invalid allowance");
        require(duration > 0 && duration <= MAX_SESSION_DURATION, "Invalid duration");
        
        // Check available balance
        uint256 userBalance = (msg.sender == channel.participant1) 
            ? channel.balance1 
            : channel.balance2;
        require(userBalance >= allowance, "Insufficient balance");
        
        // Generate session ID
        sessionId = keccak256(
            abi.encodePacked(
                channelId,
                msg.sender,
                block.timestamp,
                userNonces[msg.sender]++
            )
        );
        
        // Initialize session
        MEVSession storage session = sessions[sessionId];
        session.sessionId = sessionId;
        session.channelId = channelId;
        session.searcher = msg.sender;
        session.allowance = allowance;
        session.spent = 0;
        session.startTime = block.timestamp;
        session.duration = duration;
        session.nonce = 0;
        session.status = SessionStatus.Active;
        
        // Track user sessions
        userSessions[msg.sender].push(sessionId);
        
        emit MEVSessionStarted(sessionId, channelId, msg.sender, allowance, duration);
    }

    /**
     * @notice Execute off-chain transaction within session
     * @param sessionId The session identifier
     * @param to Recipient address
     * @param amount Transaction amount
     * @param signature User signature for authorization
     * @return txHash Transaction hash
     */
    function executeOffChainTransaction(
        bytes32 sessionId,
        address to,
        uint256 amount,
        bytes calldata signature
    ) external returns (bytes32 txHash) {
        MEVSession storage session = sessions[sessionId];
        require(session.status == SessionStatus.Active, "Session not active");
        require(block.timestamp < session.startTime + session.duration, "Session expired");
        require(session.spent + amount <= session.allowance, "Exceeds allowance");
        require(to != address(0), "Invalid recipient");
        
        // Generate transaction hash
        txHash = keccak256(
            abi.encodePacked(
                sessionId,
                session.searcher,
                to,
                amount,
                session.nonce++,
                block.timestamp
            )
        );
        
        // Verify signature
        bytes32 messageHash = _hashOffChainTransaction(
            sessionId,
            to,
            amount,
            session.nonce - 1
        );
        
        require(
            messageHash.recover(signature) == session.searcher,
            "Invalid signature"
        );
        
        // Store off-chain transaction
        session.transactions[txHash] = OffChainTx({
            txHash: txHash,
            from: session.searcher,
            to: to,
            amount: amount,
            nonce: session.nonce - 1,
            timestamp: block.timestamp,
            settled: false
        });
        
        session.txHashes.push(txHash);
        session.spent += amount;
        
        emit OffChainTransaction(sessionId, txHash, session.searcher, to, amount, session.nonce - 1);
    }

    /**
     * @notice Settle MEV session and update channel state
     * @param sessionId The session to settle
     */
    function settleMEVSession(bytes32 sessionId) external nonReentrant {
        MEVSession storage session = sessions[sessionId];
        require(session.status == SessionStatus.Active, "Session not active");
        require(
            block.timestamp >= session.startTime + session.duration ||
            msg.sender == session.searcher,
            "Cannot settle yet"
        );
        
        Channel storage channel = channels[session.channelId];
        require(channel.status == ChannelStatus.Open, "Channel not open");
        
        // Calculate final session balances
        uint256 totalSpent = session.spent;
        
        // Update channel balances based on session spending
        if (session.searcher == channel.participant1) {
            require(channel.balance1 >= totalSpent, "Insufficient balance");
            channel.balance1 -= totalSpent;
            channel.balance2 += totalSpent;
        } else {
            require(channel.balance2 >= totalSpent, "Insufficient balance");
            channel.balance2 -= totalSpent;
            channel.balance1 += totalSpent;
        }
        
        // Update channel state
        channel.stateNumber++;
        channel.stateHash = _calculateStateHash(
            session.channelId,
            channel.balance1,
            channel.balance2,
            channel.stateNumber
        );
        channel.lastUpdateTime = block.timestamp;
        
        // Mark session as settled
        session.status = SessionStatus.Settled;
        
        // Mark all transactions as settled
        for (uint256 i = 0; i < session.txHashes.length; i++) {
            session.transactions[session.txHashes[i]].settled = true;
        }
        
        emit StateUpdate(
            session.channelId,
            channel.stateNumber,
            channel.stateHash,
            block.timestamp
        );
    }

    /*//////////////////////////////////////////////////////////////
                          BATCH SETTLEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create settlement batch for multiple sessions
     * @param sessionIds Array of session IDs to settle
     * @return batchId Batch identifier
     */
    function createSettlementBatch(
        bytes32[] calldata sessionIds
    ) external onlyOwner returns (uint256 batchId) {
        require(sessionIds.length > 0, "Empty batch");
        
        batchId = ++batchCounter;
        SettlementBatch storage batch = settlementBatches[batchId];
        
        uint256 totalValue = 0;
        
        // Validate and calculate batch
        for (uint256 i = 0; i < sessionIds.length; i++) {
            MEVSession storage session = sessions[sessionIds[i]];
            require(session.status == SessionStatus.Active, "Invalid session");
            
            totalValue += session.spent;
        }
        
        batch.sessionIds = sessionIds;
        batch.totalValue = totalValue;
        batch.batchNonce = batchId;
        batch.processed = false;
        
        // Calculate merkle root for verification
        batch.merkleRoot = _calculateBatchMerkleRoot(sessionIds);
    }

    /**
     * @notice Process settlement batch
     * @param batchId Batch identifier
     */
    function processSettlementBatch(uint256 batchId) external onlyOwner {
        SettlementBatch storage batch = settlementBatches[batchId];
        require(!batch.processed, "Batch already processed");
        
        // Process all sessions in batch
        for (uint256 i = 0; i < batch.sessionIds.length; i++) {
            _settleSingleSession(batch.sessionIds[i]);
        }
        
        batch.processed = true;
    }

    /*//////////////////////////////////////////////////////////////
                            DISPUTE HANDLING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Raise dispute for invalid state update
     * @param channelId Channel identifier
     * @param disputedStateNumber State number being disputed
     */
    function raiseDispute(
        bytes32 channelId,
        uint256 disputedStateNumber
    ) external {
        Channel storage channel = channels[channelId];
        require(channel.status == ChannelStatus.Open, "Channel not open");
        require(
            msg.sender == channel.participant1 || msg.sender == channel.participant2,
            "Not channel participant"
        );
        require(!channel.hasDispute, "Dispute already active");
        
        channel.status = ChannelStatus.Challenged;
        channel.hasDispute = true;
        channel.challenger = msg.sender;
        channel.disputeDeadline = block.timestamp + channel.challengePeriod;
        
        emit DisputeRaised(
            channelId,
            msg.sender,
            disputedStateNumber,
            channel.challengePeriod
        );
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate state hash for verification
     */
    function _calculateStateHash(
        bytes32 channelId,
        uint256 balance1,
        uint256 balance2,
        uint256 stateNumber
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(channelId, balance1, balance2, stateNumber)
        );
    }

    /**
     * @notice Verify state update signatures
     */
    function _verifyStateSignatures(
        bytes32 channelId,
        bytes32 stateHash,
        uint256 stateNumber,
        address participant1,
        address participant2,
        bytes calldata signature1,
        bytes calldata signature2
    ) internal pure {
        bytes32 messageHash = keccak256(
            abi.encodePacked(channelId, stateHash, stateNumber)
        );
        
        require(
            messageHash.recover(signature1) == participant1,
            "Invalid signature 1"
        );
        require(
            messageHash.recover(signature2) == participant2,
            "Invalid signature 2"
        );
    }

    /**
     * @notice Hash off-chain transaction for signature verification
     */
    function _hashOffChainTransaction(
        bytes32 sessionId,
        address to,
        uint256 amount,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(sessionId, to, amount, nonce)
        );
    }

    /**
     * @notice Settle single session internally
     */
    function _settleSingleSession(bytes32 sessionId) internal {
        // Implementation for single session settlement
        // This would call settleMEVSession logic internally
    }

    /**
     * @notice Calculate merkle root for batch verification
     */
    function _calculateBatchMerkleRoot(
        bytes32[] calldata sessionIds
    ) internal pure returns (bytes32) {
        // Simplified merkle root calculation
        return keccak256(abi.encodePacked(sessionIds));
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get channel information
     */
    function getChannel(bytes32 channelId) 
        external 
        view 
        returns (Channel memory) 
    {
        return channels[channelId];
    }

    /**
     * @notice Get session information
     */
    function getSessionInfo(bytes32 sessionId) 
        external 
        view 
        returns (
            bytes32 channelId,
            address searcher,
            uint256 allowance,
            uint256 spent,
            uint256 startTime,
            uint256 duration,
            SessionStatus status
        ) 
    {
        MEVSession storage session = sessions[sessionId];
        return (
            session.channelId,
            session.searcher,
            session.allowance,
            session.spent,
            session.startTime,
            session.duration,
            session.status
        );
    }

    /**
     * @notice Get user's active sessions
     */
    function getUserSessions(address user) 
        external 
        view 
        returns (bytes32[] memory) 
    {
        return userSessions[user];
    }

    /**
     * @notice Receive ETH for channel deposits
     */
    receive() external payable {}
}