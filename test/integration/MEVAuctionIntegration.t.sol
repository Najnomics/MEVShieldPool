// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MEVAuctionHook} from "../../src/hooks/MEVAuctionHook.sol";
import {LitEncryptionHook} from "../../src/hooks/LitEncryptionHook.sol";
import {PythPriceHook} from "../../src/hooks/PythPriceHook.sol";
import {YellowStateChannel} from "../../src/hooks/YellowStateChannel.sol";
import {MockPyth} from "../mocks/MockPyth.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

/**
 * @title MEVAuctionIntegrationTest
 * @dev Integration tests for MEV auction with encrypted bids and cross-chain settlement
 * @notice Tests full protocol integration including Lit encryption and Yellow Network channels
 * @author MEVShield Pool Team
 */
contract MEVAuctionIntegrationTest is Test {
    using PoolIdLibrary for PoolKey;

    /**
     * @dev Protocol contract instances
     */
    MEVAuctionHook public mevHook;
    LitEncryptionHook public litHook;
    PythPriceHook public pythHook;
    YellowStateChannel public yellowChannel;
    IPoolManager public poolManager;
    MockPyth public mockPyth;
    
    /**
     * @dev Test participant addresses
     */
    address public auctioneer = address(0x1);
    address public bidder1 = address(0x2);
    address public bidder2 = address(0x3);
    address public crossChainBidder = address(0x4);
    address public liquidityProvider = address(0x5);
    
    /**
     * @dev Test pool configuration
     */
    PoolKey public testPool;
    PoolId public testPoolId;
    
    /**
     * @dev Test constants for integration scenarios
     */
    uint256 public constant INITIAL_BALANCE = 100 ether;
    uint256 public constant CROSS_CHAIN_DEPOSIT = 10 ether;
    bytes32 public constant TEST_CHANNEL_ID = keccak256("test_channel_1");
    
    /**
     * @dev Integration test events
     */
    event CrossChainBidProcessed(bytes32 indexed channelId, address indexed bidder, uint256 amount);
    event EncryptedBidDecrypted(PoolId indexed poolId, address indexed bidder, uint256 revealedAmount);
    event MEVCapturedAndDistributed(PoolId indexed poolId, uint256 totalMEV, uint256 lpShare, uint256 protocolShare);

    /**
     * @dev Setup integration test environment
     */
    function setUp() public {
        // Fund test accounts with sufficient ETH
        vm.deal(auctioneer, INITIAL_BALANCE);
        vm.deal(bidder1, INITIAL_BALANCE);
        vm.deal(bidder2, INITIAL_BALANCE);
        vm.deal(crossChainBidder, INITIAL_BALANCE);
        vm.deal(liquidityProvider, INITIAL_BALANCE);
        
        // Deploy mock Pyth contract for price feeds
        mockPyth = new MockPyth();
        
        // Deploy core protocol contracts
        vm.startPrank(auctioneer);
        
        // Deploy PoolManager with high gas limit for complex operations
        poolManager = new PoolManager(1000000);
        
        // Deploy encryption and price feed hooks
        litHook = new LitEncryptionHook(auctioneer);
        pythHook = new PythPriceHook(address(mockPyth));
        
        // Deploy Yellow Network state channel
        yellowChannel = new YellowStateChannel(auctioneer);
        
        // Deploy main MEV auction hook with all integrations
        mevHook = new MEVAuctionHook(poolManager, litHook, pythHook);
        
        vm.stopPrank();
        
        // Create test pool with MEV hook
        testPool = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(0x1000)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(mevHook))
        });
        testPoolId = testPool.toId();
        
        // Initialize pool and auction
        vm.prank(address(poolManager));
        mevHook.beforeInitialize(address(0), testPool, 0, "");
        
        // Setup Lit encryption for the test pool
        bytes32 poolBytes = bytes32(uint256(uint160(address(testPoolId))));
        vm.prank(auctioneer);
        litHook.initializePool(poolBytes, 2, 3); // 2-of-3 threshold encryption
    }

    /**
     * @dev Test complete encrypted bid workflow with price feed integration
     */
    function testEncryptedBidWithPriceFeedIntegration() public {
        uint256 bidAmount = 2 ether;
        bytes memory encryptedBidData = "encrypted_auction_bid_v1";
        bytes memory decryptionKey = "test_decryption_key_123";
        
        // Update mock price feed to simulate market conditions
        vm.prank(auctioneer);
        mockPyth.updatePrice(
            mockPyth.ETH_USD_FEED(),
            220000000000, // $2200 ETH price
            1000000000    // $10 confidence
        );
        
        // Submit encrypted bid through integrated system
        vm.prank(bidder1);
        mevHook.submitEncryptedBid{value: bidAmount}(testPoolId, encryptedBidData, decryptionKey);
        
        // Verify bid was processed through encryption layer
        (uint256 highestBid, address highestBidder,,,, ) = mevHook.auctions(testPoolId);
        assertEq(highestBid, bidAmount, "Encrypted bid amount should be recorded");
        assertEq(highestBidder, bidder1, "Encrypted bidder should be recorded");
        
        // Verify price feed integration
        (int64 price,) = pythHook.getLatestPrice(mockPyth.ETH_USD_FEED());
        assertEq(price, 220000000000, "Price feed should be updated");
    }

    /**
     * @dev Test cross-chain bid submission through Yellow Network state channels
     */
    function testCrossChainBidSubmission() public {
        uint256 channelDeposit = CROSS_CHAIN_DEPOSIT;
        uint256 bidAmount = 3 ether;
        
        // Open state channel between cross-chain bidder and auctioneer
        vm.prank(crossChainBidder);
        bytes32 channelId = yellowChannel.openStateChannel{value: channelDeposit}(
            auctioneer,
            channelDeposit
        );
        
        // Verify channel was created
        YellowStateChannel.EnhancedStateChannel memory channel = yellowChannel.getChannel(channelId);
        assertTrue(channel.isActive, "Channel should be active");
        assertEq(channel.balance1, channelDeposit, "Channel balance should match deposit");
        
        // Simulate cross-chain bid through state channel update
        vm.prank(crossChainBidder);
        bytes memory signature = abi.encodePacked(
            bytes32(0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef),
            bytes1(0x1b)
        );
        
        yellowChannel.updateChannelState(
            channelId,
            channelDeposit - bidAmount, // Reduced balance after bid
            0,                          // Auctioneer receives bid
            signature
        );
        
        // Emit cross-chain bid processed event
        emit CrossChainBidProcessed(channelId, crossChainBidder, bidAmount);
    }