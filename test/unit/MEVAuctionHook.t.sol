// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MEVAuctionHook} from "../../src/hooks/MEVAuctionHook.sol";
import {LitEncryptionHook} from "../../src/hooks/LitEncryptionHook.sol";
import {PythPriceHook} from "../../src/hooks/PythPriceHook.sol";
import {AuctionLib} from "../../src/libraries/AuctionLib.sol";
import {MockPyth} from "../mocks/MockPyth.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

/**
 * @title MEVAuctionHookTest
 * @dev Comprehensive unit tests for MEV auction functionality
 * @notice Tests all auction mechanisms, encryption integration, and price feeds
 * @author MEVShield Pool Team
 */
contract MEVAuctionHookTest is Test {
    using PoolIdLibrary for PoolKey;

    /**
     * @dev Test contracts and configuration
     */
    MEVAuctionHook public mevHook;
    LitEncryptionHook public litHook;
    PythPriceHook public pythHook;
    IPoolManager public poolManager;
    
    /**
     * @dev Test addresses and pools
     */
    address public owner = address(0x1);
    address public bidder1 = address(0x2);
    address public bidder2 = address(0x3);
    address public liquidityProvider = address(0x4);
    
    PoolKey public testPool;
    PoolId public testPoolId;
    
    /**
     * @dev Test constants
     */
    uint256 public constant INITIAL_BALANCE = 100 ether;
    uint256 public constant MIN_BID = 0.001 ether;
    
    /**
     * @dev Events for testing
     */
    event BidSubmitted(PoolId indexed poolId, address indexed bidder, uint256 amount);
    event AuctionWon(PoolId indexed poolId, address indexed winner, uint256 amount);
    event MEVDistributed(PoolId indexed poolId, uint256 lpAmount, uint256 protocolAmount);

    /**
     * @dev Setup function run before each test
     */
    function setUp() public {
        // Set up test accounts with ETH
        vm.deal(owner, INITIAL_BALANCE);
        vm.deal(bidder1, INITIAL_BALANCE);
        vm.deal(bidder2, INITIAL_BALANCE);
        vm.deal(liquidityProvider, INITIAL_BALANCE);
        
        // Deploy mock Pyth contract for testing
        address mockPyth = _deployMockPyth();
        
        // Deploy protocol contracts
        vm.startPrank(owner);
        
        // Deploy PoolManager for testing
        poolManager = new PoolManager(owner);
        
        // Deploy supporting contracts
        litHook = new LitEncryptionHook(owner);
        pythHook = new PythPriceHook(mockPyth);
        
        // Deploy main MEV auction hook
        mevHook = new MEVAuctionHook(poolManager, litHook, pythHook);
        
        vm.stopPrank();
        
        // Create test pool
        testPool = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(0x1000)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(mevHook))
        });
        testPoolId = testPool.toId();
        
        // Note: Pool initialization would happen automatically in production
    }

    /**
     * @dev Mock Pyth contract for testing price feeds
     * @return mockPyth Address of deployed mock Pyth contract
     */
    function _deployMockPyth() internal returns (address mockPyth) {
        // Deploy minimal mock Pyth for testing
        mockPyth = address(new MockPyth());
        return mockPyth;
    }

    /**
     * @dev Test basic auction initialization
     */
    function testAuctionInitialization() public {
        // Verify auction was initialized in setUp
        (uint256 highestBid, address highestBidder, uint256 deadline, bool isActive,, uint256 totalMEV) = 
            mevHook.auctions(testPoolId);
        
        assertEq(highestBid, 0, "Initial highest bid should be 0");
        assertEq(highestBidder, address(0), "Initial highest bidder should be null");
        assertTrue(deadline > 0, "Auction deadline should be set");
        assertTrue(isActive, "Auction should be active");
        assertEq(totalMEV, 0, "Initial total MEV should be 0");
    }

    /**
     * @dev Test successful bid submission
     */
    function testSuccessfulBidSubmission() public {
        uint256 bidAmount = 1 ether;
        
        // Submit bid from bidder1
        vm.prank(bidder1);
        vm.deal(bidder1, bidAmount + INITIAL_BALANCE);
        
        vm.expectEmit(true, true, false, true);
        emit BidSubmitted(testPoolId, bidder1, bidAmount);
        
        mevHook.submitBid{value: bidAmount}(PoolId.unwrap(testPoolId));
        
        // Verify bid was recorded
        (uint256 highestBid, address highestBidder,,,, ) = mevHook.auctions(testPoolId);
        assertEq(highestBid, bidAmount, "Highest bid should be updated");
        assertEq(highestBidder, bidder1, "Highest bidder should be bidder1");
    }

    /**
     * @dev Test bid amount validation
     */
    function testBidAmountValidation() public {
        uint256 lowBid = MIN_BID - 1;
        
        // Attempt to submit bid below minimum
        vm.prank(bidder1);
        vm.expectRevert("Bid below minimum");
        mevHook.submitBid{value: lowBid}(PoolId.unwrap(testPoolId));
    }

    /**
     * @dev Test bid refund mechanism
     */
    function testBidRefund() public {
        uint256 firstBid = 1 ether;
        uint256 secondBid = 2 ether;
        
        // Submit first bid
        vm.prank(bidder1);
        uint256 bidder1BalanceBefore = bidder1.balance;
        mevHook.submitBid{value: firstBid}(testPoolId);
        
        // Submit higher bid from bidder2
        vm.prank(bidder2);
        mevHook.submitBid{value: secondBid}(testPoolId);
        
        // Verify bidder1 was refunded
        uint256 bidder1BalanceAfter = bidder1.balance;
        assertEq(bidder1BalanceAfter, bidder1BalanceBefore - firstBid + firstBid, "Bidder1 should be refunded");
        
        // Verify auction state
        (uint256 highestBid, address highestBidder,,,, ) = mevHook.auctions(testPoolId);
        assertEq(highestBid, secondBid, "Highest bid should be second bid");
        assertEq(highestBidder, bidder2, "Highest bidder should be bidder2");
    }

    /**
     * @dev Test auction expiration and finalization
     */
    function testAuctionExpiration() public {
        uint256 bidAmount = 1 ether;
        
        // Submit bid
        vm.prank(bidder1);
        mevHook.submitBid{value: bidAmount}(PoolId.unwrap(testPoolId));
        
        // Fast forward past auction deadline
        vm.warp(block.timestamp + 13 seconds);
        
        // Check auction is expired
        (,, uint256 deadline, bool isActive,, ) = mevHook.auctions(testPoolId);
        assertTrue(block.timestamp >= deadline, "Auction should be expired");
        
        // Finalize auction through beforeSwap hook
        vm.prank(address(poolManager));
        bytes4 result = mevHook.beforeSwap(
            bidder1,
            testPool,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1e18,
                sqrtPriceLimitX96: 0
            }),
            ""
        );
        
        // Verify auction was finalized
        (, address highestBidder,, bool newIsActive,, ) = mevHook.auctions(testPoolId);
        assertTrue(newIsActive, "New auction should be started");
    }

    /**
     * @dev Test MEV distribution mechanism
     */
    function testMEVDistribution() public {
        uint256 bidAmount = 2 ether;
        uint256 mevValue = 1 ether;
        
        // Submit winning bid
        vm.prank(bidder1);
        mevHook.submitBid{value: bidAmount}(PoolId.unwrap(testPoolId));
        
        // Fast forward and trigger MEV distribution
        vm.warp(block.timestamp + 13 seconds);
        
        // Mock MEV capture by sending ETH to hook
        vm.deal(address(mevHook), mevValue);
        
        // Get LP balance before distribution
        uint256 lpBalanceBefore = liquidityProvider.balance;
        
        // Trigger MEV distribution
        vm.prank(address(poolManager));
        vm.expectEmit(true, false, false, true);
        emit MEVDistributed(testPoolId, (mevValue * 90) / 100, (mevValue * 10) / 100);
        
        mevHook.afterSwap(
            bidder1,
            testPool,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1e18,
                sqrtPriceLimitX96: 0
            }),
            0,
            ""
        );
        
        // Verify MEV was tracked
        (,,,,, uint256 totalMEV) = mevHook.auctions(testPoolId);
        assertEq(totalMEV, mevValue, "Total MEV should be tracked");
    }

    /**
     * @dev Test encrypted bid submission
     */
    function testEncryptedBidSubmission() public {
        bytes memory encryptedBid = "encrypted_bid_data";
        bytes memory decryptionKey = "decryption_key";
        uint256 bidAmount = 1.5 ether;
        
        // Submit encrypted bid
        vm.prank(bidder1);
        mevHook.submitEncryptedBid{value: bidAmount}(PoolId.unwrap(testPoolId), encryptedBid, decryptionKey);
        
        // Verify bid was recorded
        (uint256 highestBid, address highestBidder,,,, ) = mevHook.auctions(testPoolId);
        assertEq(highestBid, bidAmount, "Encrypted bid should be recorded");
        assertEq(highestBidder, bidder1, "Bidder should be recorded");
    }
}