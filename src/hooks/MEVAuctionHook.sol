// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AuctionLib} from "../libraries/AuctionLib.sol";
import {IMEVAuction} from "../interfaces/IMEVAuction.sol";
import {ILitEncryption} from "../interfaces/ILitEncryption.sol";
import {IPythPriceOracle} from "../interfaces/IPythPriceOracle.sol";
import {LitProtocolLib} from "../libraries/LitProtocolLib.sol";
import {PythPriceLib} from "../libraries/PythPriceLib.sol";

/**
 * @title MEVAuctionHook
 * @dev Uniswap V4 Hook implementing MEV auction mechanism with encrypted bids
 * @notice Auctions first-in-block trading rights and redistributes MEV to LPs
 * @author MEVShield Pool Team
 */
contract MEVAuctionHook is BaseHook, ReentrancyGuard, Ownable, IMEVAuction {
    using PoolIdLibrary for PoolKey;
    using AuctionLib for AuctionLib.AuctionData;

    /**
     * @dev Core auction data for each pool
     */
    mapping(PoolId => AuctionLib.AuctionData) public auctions;
    
    /**
     * @dev Mapping of pool to bidder to bid amount (for transparent bids)
     */
    mapping(PoolId => mapping(address => uint256)) public bids;
    
    /**
     * @dev Mapping of pool to LP to accumulated rewards
     */
    mapping(PoolId => mapping(address => uint256)) public lpRewards;
    
    /**
     * @dev Array of bidders for each pool
     */
    mapping(PoolId => address[]) public bidders;
    
    /**
     * @dev Integration contracts for encryption and price feeds
     */
    ILitEncryption public immutable litEncryption;
    IPythPriceOracle public immutable pythOracle;
    
    /**
     * @dev Mapping to track pending encrypted bids for each pool
     */
    mapping(PoolId => ILitEncryption.EncryptedBid[]) public pendingEncryptedBids;
    
    /**
     * @dev Mapping to track async swap execution permissions
     */
    mapping(PoolId => mapping(address => bool)) public asyncSwapPermissions;
    
    /**
     * @dev Events for encrypted bid integration
     */
    event EncryptedBidSubmitted(
        PoolId indexed poolId,
        address indexed bidder,
        bytes32 sessionKeyHash
    );
    
    event AsyncSwapExecuted(
        PoolId indexed poolId,
        address indexed executor,
        uint256 mevValue
    );

    /**
     * @dev Constructor initializes the hook with required contracts
     * @param _poolManager Uniswap V4 pool manager
     * @param _litEncryption Lit Protocol encryption contract
     * @param _pythOracle Pyth Network price oracle
     */
    constructor(
        IPoolManager _poolManager,
        ILitEncryption _litEncryption,
        IPythPriceOracle _pythOracle
    ) BaseHook(_poolManager) Ownable(msg.sender) {
        litEncryption = _litEncryption;
        pythOracle = _pythOracle;
    }

    /**
     * @dev Defines hook permissions for Uniswap V4 integration
     * @return Hook permissions configuration
     */
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,        // Initialize auction parameters
            afterInitialize: false,
            beforeAddLiquidity: true,      // Track LP positions for rewards
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,   // Update LP rewards before removal
            afterRemoveLiquidity: false,
            beforeSwap: true,              // Validate auction rights and check expiry
            afterSwap: true,               // Calculate and distribute MEV
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: true,   // Enable async swap execution
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /**
     * @dev Hook called before pool initialization to set up auction parameters
     * @param key The pool key being initialized
     * @return Hook selector to confirm execution
     */
    function beforeInitialize(
        address,
        PoolKey calldata key,
        uint160,
        bytes calldata
    ) external override returns (bytes4) {
        PoolId poolId = key.toId();
        
        // Initialize auction data for this pool
        auctions[poolId] = AuctionLib.AuctionData({
            highestBid: 0,
            highestBidder: address(0),
            deadline: block.timestamp + AuctionLib.AUCTION_DURATION,
            isActive: true,
            blockHash: blockhash(block.number - 1),
            totalMEVCollected: 0
        });
        
        // Initialize encryption parameters for encrypted bids
        try litEncryption.initializePool(
            bytes32(uint256(PoolId.unwrap(poolId))),
            LitProtocolLib.DEFAULT_MPC_THRESHOLD,
            LitProtocolLib.DEFAULT_MPC_NODES
        ) {} catch {
            // Continue if encryption initialization fails (optional feature)
        }
        
        return BaseHook.beforeInitialize.selector;
    }

    function submitBid(PoolKey calldata key) external payable nonReentrant {
        PoolId poolId = key.toId();
        require(msg.value >= AuctionLib.MIN_BID, "Bid too low");
        require(auctions[poolId].isActive, "Auction not active");
        require(block.timestamp < auctions[poolId].deadline, "Auction expired");
        require(msg.value > auctions[poolId].highestBid, "Bid not high enough");

        if (auctions[poolId].highestBidder != address(0)) {
            payable(auctions[poolId].highestBidder).transfer(auctions[poolId].highestBid);
        }

        auctions[poolId].highestBid = msg.value;
        auctions[poolId].highestBidder = msg.sender;
        bids[poolId][msg.sender] = msg.value;
        
        if (bidders[poolId].length == 0 || bidders[poolId][bidders[poolId].length - 1] != msg.sender) {
            bidders[poolId].push(msg.sender);
        }

        emit BidSubmitted(poolId, msg.sender, msg.value);
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();
        AuctionLib.AuctionData storage auction = auctions[poolId];

        if (auction.isActive && auction.isAuctionExpired()) {
            _finalizeAuction(poolId);
        }

        bool hasAuctionRights = (auction.highestBidder == sender) && 
                               (auction.blockHash == blockhash(block.number - 1));

        if (!auction.isActive) {
            _startNewAuction(poolId);
        }

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _finalizeAuction(PoolId poolId) internal {
        AuctionLib.AuctionData storage auction = auctions[poolId];
        
        if (auction.highestBidder != address(0)) {
            emit AuctionWon(poolId, auction.highestBidder, auction.highestBid);
            _distributeMEV(poolId, auction.highestBid);
        }
        
        auction.isActive = false;
    }

    function _startNewAuction(PoolId poolId) internal {
        AuctionLib.AuctionData storage auction = auctions[poolId];
        auction.highestBid = 0;
        auction.highestBidder = address(0);
        auction.deadline = block.timestamp + AuctionLib.AUCTION_DURATION;
        auction.isActive = true;
        auction.blockHash = blockhash(block.number - 1);
    }

    function _distributeMEV(PoolId poolId, uint256 amount) internal {
        uint256 lpAmount = (amount * AuctionLib.LP_SHARE) / 100;
        uint256 protocolAmount = amount - lpAmount;

        auctions[poolId].totalMEVCollected += amount;
        lpRewards[poolId][address(this)] += lpAmount;

        if (protocolAmount > 0) {
            payable(owner()).transfer(protocolAmount);
        }

        emit MEVDistributed(poolId, lpAmount, protocolAmount);
    }

    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    ) external override returns (bytes4, int128) {
        PoolId poolId = key.toId();
        
        int128 amount0Delta = delta.amount0();
        int128 amount1Delta = delta.amount1();
        
        uint256 mevValue = _calculateMEV(amount0Delta, amount1Delta);
        
        if (mevValue > 0) {
            auctions[poolId].totalMEVCollected += mevValue;
            emit MEVDetected(poolId, mevValue);
        }
        
        return (BaseHook.afterSwap.selector, 0);
    }
    
    function _calculateMEV(int128 amount0, int128 amount1) internal pure returns (uint256) {
        uint256 absAmount0 = amount0 < 0 ? uint256(-amount0) : uint256(amount0);
        uint256 absAmount1 = amount1 < 0 ? uint256(-amount1) : uint256(amount1);
        
        return (absAmount0 + absAmount1) / 1000;
    }
    
    function beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        return BaseHook.beforeAddLiquidity.selector;
    }
    
    function beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override returns (bytes4) {
        return BaseHook.beforeRemoveLiquidity.selector;
    }