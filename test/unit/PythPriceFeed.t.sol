// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {PythPriceHook} from "../../src/hooks/PythPriceHook.sol";
import {MockPyth} from "../mocks/MockPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title PythPriceFeedTest
 * @dev Comprehensive tests for Pyth Network price feed integration
 * @notice Tests price validation, staleness checks, and MEV calculation accuracy
 * @author MEVShield Pool Team
 */
contract PythPriceFeedTest is Test {
    /**
     * @dev Test contract instances for price feed testing
     */
    PythPriceHook public pythHook;
    MockPyth public mockPyth;
    
    /**
     * @dev Test addresses for price feed scenarios
     */
    address public priceManager = address(0x1);
    address public priceConsumer = address(0x2);
    
    /**
     * @dev Test constants for price feed validation
     */
    uint256 public constant INITIAL_BALANCE = 5 ether;
    int64 public constant BASE_ETH_PRICE = 200000000000; // $2000 USD with 8 decimals
    uint64 public constant BASE_CONFIDENCE = 100000000; // $1 USD confidence
    int32 public constant PRICE_EXPO = -8; // 8 decimal places
    uint64 public constant PUBLISH_TIME_TOLERANCE = 60; // 60 seconds
    
    /**
     * @dev Price feed identifiers for testing
     */
    bytes32 public constant ETH_USD_FEED_ID = keccak256("ETH/USD");
    bytes32 public constant BTC_USD_FEED_ID = keccak256("BTC/USD");
    
    /**
     * @dev Events for price feed testing
     */
    event PriceUpdated(bytes32 indexed feedId, int64 price, uint64 confidence);
    event PriceValidationFailed(bytes32 indexed feedId, string reason);
    event StalePriceDetected(bytes32 indexed feedId, uint64 age);

    /**
     * @dev Setup price feed test environment
     */
    function setUp() public {
        // Fund test accounts for price operations
        vm.deal(priceManager, INITIAL_BALANCE);
        vm.deal(priceConsumer, INITIAL_BALANCE);
        
        // Deploy mock Pyth contract with initial price data
        mockPyth = new MockPyth();
        
        // Deploy Pyth price hook with mock contract
        vm.prank(priceManager);
        pythHook = new PythPriceHook(address(mockPyth));
        
        // Initialize with base ETH price
        _updateMockPrice(ETH_USD_FEED_ID, BASE_ETH_PRICE, BASE_CONFIDENCE);
    }

    /**
     * @dev Helper function to update mock price data
     * @param feedId The price feed identifier
     * @param price The price value with proper decimals
     * @param confidence The confidence interval for the price
     */
    function _updateMockPrice(bytes32 feedId, int64 price, uint64 confidence) internal {
        vm.prank(priceManager);
        mockPyth.updatePrice(feedId, price, confidence);
    }

    /**
     * @dev Test basic price retrieval functionality
     */
    function testBasicPriceRetrieval() public {
        // Get current ETH price
        PythStructs.Price memory ethPrice = pythHook.getPrice(ETH_USD_FEED_ID);
        
        // Verify price data is correct
        assertEq(ethPrice.price, BASE_ETH_PRICE, "ETH price should match base price");
        assertEq(ethPrice.conf, BASE_CONFIDENCE, "Confidence should match base confidence");
        assertEq(ethPrice.expo, PRICE_EXPO, "Exponent should be -8 for USD prices");
        assertTrue(ethPrice.publishTime > 0, "Publish time should be set");
    }

    /**
     * @dev Test price update validation and event emission
     */
    function testPriceUpdateValidation() public {
        int64 newPrice = 210000000000; // $2100 USD
        uint64 newConfidence = 150000000; // $1.50 USD confidence
        
        // Expect price update event
        vm.expectEmit(true, false, false, true);
        emit PriceUpdated(ETH_USD_FEED_ID, newPrice, newConfidence);
        
        // Update price through hook
        vm.prank(priceManager);
        _updateMockPrice(ETH_USD_FEED_ID, newPrice, newConfidence);
        
        // Verify price was updated
        PythStructs.Price memory updatedPrice = pythHook.getPrice(ETH_USD_FEED_ID);
        assertEq(updatedPrice.price, newPrice, "Price should be updated");
        assertEq(updatedPrice.conf, newConfidence, "Confidence should be updated");
    }

    /**
     * @dev Test price staleness detection and validation
     */
    function testPriceStalenessDetection() public {
        // Get initial price
        PythStructs.Price memory initialPrice = pythHook.getPrice(ETH_USD_FEED_ID);
        uint256 initialTime = initialPrice.publishTime;
        
        // Fast forward to make price stale
        vm.warp(block.timestamp + PUBLISH_TIME_TOLERANCE + 1);
        
        // Price should now be considered stale
        bool isStale = pythHook.isPriceStale(ETH_USD_FEED_ID, PUBLISH_TIME_TOLERANCE);
        assertTrue(isStale, "Price should be detected as stale");
        
        // Update with fresh price
        _updateMockPrice(ETH_USD_FEED_ID, BASE_ETH_PRICE, BASE_CONFIDENCE);
        
        // Price should no longer be stale
        bool isStillStale = pythHook.isPriceStale(ETH_USD_FEED_ID, PUBLISH_TIME_TOLERANCE);
        assertFalse(isStillStale, "Fresh price should not be stale");
    }

    /**
     * @dev Test price confidence validation for MEV calculations
     */
    function testPriceConfidenceValidation() public {
        // Test with high confidence (low uncertainty)
        uint64 highConfidence = 50000000; // $0.50 confidence
        _updateMockPrice(ETH_USD_FEED_ID, BASE_ETH_PRICE, highConfidence);
        
        PythStructs.Price memory highConfPrice = pythHook.getPrice(ETH_USD_FEED_ID);
        bool isHighConfValid = pythHook.isPriceConfidenceAcceptable(
            ETH_USD_FEED_ID, 
            100000000 // Accept up to $1 confidence
        );
        assertTrue(isHighConfValid, "High confidence price should be acceptable");
        
        // Test with low confidence (high uncertainty)
        uint64 lowConfidence = 200000000; // $2.00 confidence
        _updateMockPrice(ETH_USD_FEED_ID, BASE_ETH_PRICE, lowConfidence);
        
        bool isLowConfValid = pythHook.isPriceConfidenceAcceptable(
            ETH_USD_FEED_ID,
            100000000 // Accept up to $1 confidence
        );
        assertFalse(isLowConfValid, "Low confidence price should be rejected");
    }

    /**
     * @dev Test multi-asset price feed management
     */
    function testMultiAssetPriceFeedManagement() public {
        int64 btcPrice = 4500000000000; // $45,000 USD with 8 decimals
        uint64 btcConfidence = 500000000; // $5 USD confidence
        
        // Add BTC price feed
        _updateMockPrice(BTC_USD_FEED_ID, btcPrice, btcConfidence);
        
        // Retrieve both ETH and BTC prices
        PythStructs.Price memory ethPrice = pythHook.getPrice(ETH_USD_FEED_ID);
        PythStructs.Price memory btcPriceData = pythHook.getPrice(BTC_USD_FEED_ID);
        
        // Verify both prices are correctly stored
        assertEq(ethPrice.price, BASE_ETH_PRICE, "ETH price should remain unchanged");
        assertEq(btcPriceData.price, btcPrice, "BTC price should be set correctly");
        
        // Calculate price ratio for cross-asset MEV opportunities
        uint256 priceRatio = pythHook.calculatePriceRatio(ETH_USD_FEED_ID, BTC_USD_FEED_ID);
        assertTrue(priceRatio > 0, "Price ratio should be calculable");
    }

    /**
     * @dev Test price feed error handling and recovery
     */
    function testPriceFeedErrorHandling() public {
        bytes32 invalidFeedId = keccak256("INVALID/USD");
        
        // Attempt to get price for non-existent feed
        vm.expectRevert("Price feed not found");
        pythHook.getPrice(invalidFeedId);
        
        // Test recovery after price feed becomes available
        _updateMockPrice(invalidFeedId, 100000000000, 50000000);
        
        // Should now work after feed is added
        PythStructs.Price memory recoveredPrice = pythHook.getPrice(invalidFeedId);
        assertEq(recoveredPrice.price, 100000000000, "Recovered price should be correct");
    }

    /**
     * @dev Test MEV opportunity detection using price feeds
     */
    function testMEVOpportunityDetection() public {
        // Set up price feeds with arbitrage opportunity
        int64 ethPrice1 = 200000000000; // $2000 on exchange 1
        int64 ethPrice2 = 202000000000; // $2020 on exchange 2 (1% higher)
        
        bytes32 feed1 = keccak256("ETH/USD/EXCHANGE1");
        bytes32 feed2 = keccak256("ETH/USD/EXCHANGE2");
        
        _updateMockPrice(feed1, ethPrice1, BASE_CONFIDENCE);
        _updateMockPrice(feed2, ethPrice2, BASE_CONFIDENCE);
        
        // Calculate potential MEV opportunity
        uint256 priceDiff = pythHook.calculatePriceDifference(feed1, feed2);
        assertTrue(priceDiff > 0, "Price difference should be detected");
        
        // Verify MEV opportunity threshold
        bool isMEVOpportunity = pythHook.isMEVOpportunityPresent(
            feed1, 
            feed2, 
            50000000 // 0.5% minimum threshold
        );
        assertTrue(isMEVOpportunity, "MEV opportunity should be detected");
    }

    /**
     * @dev Test gas efficiency of price feed operations
     */
    function testPriceFeedGasEfficiency() public {
        // Measure gas for single price retrieval
        uint256 gasBefore = gasleft();
        PythStructs.Price memory price = pythHook.getPrice(ETH_USD_FEED_ID);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Price retrieval should be gas efficient
        assertTrue(gasUsed < 50000, "Price retrieval should use less than 50k gas");
        
        // Measure gas for price update
        gasBefore = gasleft();
        _updateMockPrice(ETH_USD_FEED_ID, BASE_ETH_PRICE + 1000000000, BASE_CONFIDENCE);
        gasUsed = gasBefore - gasleft();
        
        // Price update should be reasonably efficient
        assertTrue(gasUsed < 100000, "Price update should use less than 100k gas");
    }
}
}