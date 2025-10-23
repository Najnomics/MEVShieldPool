// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {PythPriceLib} from "../libraries/PythPriceLib.sol";
import {IPythPriceOracle} from "../interfaces/IPythPriceOracle.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PythPriceHook - Enhanced Pyth Pull Oracle Integration
 * @dev Advanced MEV detection and price monitoring using Pyth Network
 * @notice Implements pull oracle methodology for real-time price feeds
 * @author MEVShield Pool Team - ETHOnline 2025
 */
contract PythPriceHook is IPythPriceOracle, Ownable, ReentrancyGuard {
    IPyth public immutable pyth;
    
    // Enhanced price tracking
    mapping(bytes32 => PythStructs.Price) public latestPrices;
    mapping(bytes32 => uint256) public lastUpdateTimes;
    mapping(bytes32 => uint256) public priceUpdateCounts;
    mapping(bytes32 => bool) public supportedPriceIds;
    
    // MEV opportunity tracking
    mapping(bytes32 => MEVOpportunity[]) public mevOpportunities;
    mapping(bytes32 => uint256) public totalMEVDetected;
    
    // Performance metrics
    uint256 public totalUpdates;
    uint256 public totalMEVCaptured;
    uint256 public averageUpdateLatency;
    
    struct MEVOpportunity {
        bytes32 priceId;
        int64 pythPrice;
        int64 marketPrice;
        uint256 deviation;
        uint256 estimatedProfit;
        uint256 timestamp;
        uint256 blockNumber;
        bool executed;
    }
    
    struct PriceFeedConfig {
        bytes32 priceId;
        string symbol;
        uint256 maxStaleness;
        uint256 confidenceThreshold;
        bool active;
    }
    
    // Supported price feeds for MEV detection
    PriceFeedConfig[] public priceFeeds;
    mapping(bytes32 => uint256) public priceFeedIndex;
    
    // Events for enhanced monitoring
    event PriceUpdated(bytes32 indexed priceId, int64 price, uint64 conf, uint256 timestamp);
    event MEVOpportunityDetected(bytes32 indexed priceId, uint256 deviation, uint256 estimatedProfit);
    event MEVOpportunityExecuted(bytes32 indexed priceId, uint256 actualProfit);
    event PriceFeedAdded(bytes32 indexed priceId, string symbol);
    event PriceFeedRemoved(bytes32 indexed priceId);
    
    constructor(address _pythContract) Ownable(msg.sender) {
        pyth = IPyth(_pythContract);
        
        // Initialize with common trading pairs for MEV detection
        _addDefaultPriceFeeds();
    }
    
    /**
     * @dev Initialize default price feeds for major trading pairs
     */
    function _addDefaultPriceFeeds() internal {
        // ETH/USD - Most important for MEV detection
        _addPriceFeed(
            PythPriceLib.ETH_USD_PRICE_ID, 
            "ETH/USD", 
            60, // 60 seconds max staleness
            1000 // 10% confidence threshold (in basis points)
        );
        
        // Add more major pairs
        _addPriceFeed(
            PythPriceLib.BTC_USD_PRICE_ID,
            "BTC/USD",
            60,
            1000
        );
    }
    
    /**
     * @dev Enhanced price retrieval with validation and MEV detection
     * @param priceId Pyth price feed identifier
     * @return price Current price data with validation
     */
    function getPrice(bytes32 priceId) external view override returns (PythStructs.Price memory price) {
        price = pyth.getPrice(priceId);
        PythPriceLib.validatePrice(price);
        
        // Additional staleness check
        require(
            block.timestamp - price.publishTime <= _getMaxStaleness(priceId),
            "Price data too stale"
        );
        
        return price;
    }
    
    /**
     * @dev Pull oracle implementation - fetch and update price feeds
     * @param updateData Hermes price update data
     */
    function updatePriceFeeds(bytes[] calldata updateData) external payable override nonReentrant {
        uint256 fee = pyth.getUpdateFee(updateData);
        require(msg.value >= fee, "Insufficient fee");
        
        // Record update start time for latency measurement
        uint256 updateStart = block.timestamp;
        
        // Update prices using Pyth pull oracle
        pyth.updatePriceFeeds{value: fee}(updateData);
        
        // Process each updated price for MEV detection
        for (uint256 i = 0; i < priceFeeds.length; i++) {
            PriceFeedConfig memory feed = priceFeeds[i];
            if (feed.active) {
                _processPriceUpdate(feed.priceId, updateStart);
            }
        }
        
        totalUpdates++;
        
        // Update average latency
        uint256 latency = block.timestamp - updateStart;
        averageUpdateLatency = (averageUpdateLatency * (totalUpdates - 1) + latency) / totalUpdates;
        
        // Return any excess payment
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
    }
    
    /**
     * @dev Process individual price update for MEV detection
     * @param priceId Price feed identifier
     * @param updateTime Timestamp of the update
     */
    function _processPriceUpdate(bytes32 priceId, uint256 updateTime) internal {
        try pyth.getPrice(priceId) returns (PythStructs.Price memory newPrice) {
            // Store previous price for comparison
            PythStructs.Price memory previousPrice = latestPrices[priceId];
            
            // Update stored price
            latestPrices[priceId] = newPrice;
            lastUpdateTimes[priceId] = updateTime;
            priceUpdateCounts[priceId]++;
            
            emit PriceUpdated(priceId, newPrice.price, newPrice.conf, updateTime);
            
            // Detect MEV opportunities if we have previous price data
            if (previousPrice.publishTime > 0) {
                _detectMEVOpportunity(priceId, previousPrice, newPrice);
            }
        } catch {
            // Handle price update failure gracefully
        }
    }
    
    /**
     * @dev Advanced MEV opportunity detection
     * @param priceId Price feed identifier
     * @param previousPrice Previous price data
     * @param currentPrice Current price data
     */
    function _detectMEVOpportunity(
        bytes32 priceId,
        PythStructs.Price memory previousPrice,
        PythStructs.Price memory currentPrice
    ) internal {
        // Calculate price deviation
        int64 priceDiff = currentPrice.price - previousPrice.price;
        uint256 deviation = priceDiff > 0 ? uint256(uint64(priceDiff)) : uint256(uint64(-priceDiff));
        
        // Calculate deviation percentage (in basis points)
        uint256 deviationBps = (deviation * 10000) / uint256(uint64(previousPrice.price));
        
        // Significant price movement threshold (50 basis points = 0.5%)
        if (deviationBps >= 50) {
            // Estimate MEV opportunity value
            uint256 estimatedProfit = _calculateMEVProfit(priceId, deviation, deviationBps);
            
            // Store MEV opportunity
            MEVOpportunity memory opportunity = MEVOpportunity({
                priceId: priceId,
                pythPrice: currentPrice.price,
                marketPrice: previousPrice.price, // Simulated market price
                deviation: deviationBps,
                estimatedProfit: estimatedProfit,
                timestamp: block.timestamp,
                blockNumber: block.number,
                executed: false
            });
            
            mevOpportunities[priceId].push(opportunity);
            totalMEVDetected += estimatedProfit;
            
            emit MEVOpportunityDetected(priceId, deviationBps, estimatedProfit);
        }
    }
    
    /**
     * @dev Calculate estimated MEV profit from price deviation
     * @param priceId Price feed identifier
     * @param deviation Absolute price deviation
     * @param deviationBps Deviation in basis points
     * @return estimatedProfit Estimated MEV profit in wei
     */
    function _calculateMEVProfit(
        bytes32 priceId,
        uint256 deviation,
        uint256 deviationBps
    ) internal pure returns (uint256 estimatedProfit) {
        // Base MEV calculation: higher deviation = higher opportunity
        // This is a simplified model - production would use more sophisticated calculations
        
        if (priceId == PythPriceLib.ETH_USD_PRICE_ID) {
            // ETH-based MEV opportunities tend to be larger
            estimatedProfit = (deviation * deviationBps * 1e12) / 10000; // Scale to wei
        } else {
            // Other assets
            estimatedProfit = (deviation * deviationBps * 1e10) / 10000;
        }
        
        // Cap maximum estimated profit
        if (estimatedProfit > 10 ether) {
            estimatedProfit = 10 ether;
        }
        
        return estimatedProfit;
    }
    
    /**
     * @dev Enhanced MEV analysis for auction integration
     * @param priceId Pyth price feed ID
     * @param swapPrice Expected swap price
     * @param swapAmount Amount being swapped
     * @return mevValue Calculated MEV opportunity value
     * @return confidence Confidence level of the opportunity
     */
    function analyzeMEVOpportunity(
        bytes32 priceId,
        int64 swapPrice,
        uint256 swapAmount
    ) external view returns (uint256 mevValue, uint256 confidence) {
        PythStructs.Price memory currentPrice = pyth.getPrice(priceId);
        PythPriceLib.validatePrice(currentPrice);
        
        // Calculate price difference
        int64 priceDiff = swapPrice - currentPrice.price;
        
        if (priceDiff > 0) {
            // Positive MEV opportunity
            uint256 deviation = uint256(uint64(priceDiff));
            uint256 deviationBps = (deviation * 10000) / uint256(uint64(currentPrice.price));
            
            // Calculate MEV value based on swap amount and deviation
            mevValue = (swapAmount * deviationBps) / 10000;
            
            // Confidence based on price confidence and staleness
            confidence = _calculateConfidence(currentPrice);
            
            // Adjust MEV value by confidence
            mevValue = (mevValue * confidence) / 100;
        } else {
            mevValue = 0;
            confidence = 0;
        }
        
        return (mevValue, confidence);
    }
    
    /**
     * @dev Calculate confidence level for price data
     * @param price Pyth price structure
     * @return confidence Confidence percentage (0-100)
     */
    function _calculateConfidence(PythStructs.Price memory price) internal view returns (uint256 confidence) {
        // Base confidence from Pyth price confidence interval
        uint256 baseConfidence = 100;
        
        // Reduce confidence for wide confidence intervals
        uint256 confInterval = (uint256(price.conf) * 10000) / uint256(uint64(price.price));
        if (confInterval > 100) { // > 1%
            baseConfidence = baseConfidence * (1000 - confInterval) / 1000;
        }
        
        // Reduce confidence for stale data
        uint256 staleness = block.timestamp - price.publishTime;
        if (staleness > 30) { // > 30 seconds
            baseConfidence = baseConfidence * (300 - staleness) / 300;
        }
        
        // Ensure minimum confidence
        if (baseConfidence < 10) {
            baseConfidence = 10;
        }
        
        return baseConfidence;
    }
    
    /**
     * @dev Add new price feed for monitoring
     * @param priceId Pyth price feed ID
     * @param symbol Trading pair symbol
     * @param maxStaleness Maximum allowed staleness in seconds
     * @param confidenceThreshold Confidence threshold in basis points
     */
    function addPriceFeed(
        bytes32 priceId,
        string calldata symbol,
        uint256 maxStaleness,
        uint256 confidenceThreshold
    ) external onlyOwner {
        _addPriceFeed(priceId, symbol, maxStaleness, confidenceThreshold);
    }
    
    function _addPriceFeed(
        bytes32 priceId,
        string memory symbol,
        uint256 maxStaleness,
        uint256 confidenceThreshold
    ) internal {
        require(!supportedPriceIds[priceId], "Price feed already exists");
        
        PriceFeedConfig memory config = PriceFeedConfig({
            priceId: priceId,
            symbol: symbol,
            maxStaleness: maxStaleness,
            confidenceThreshold: confidenceThreshold,
            active: true
        });
        
        priceFeeds.push(config);
        priceFeedIndex[priceId] = priceFeeds.length - 1;
        supportedPriceIds[priceId] = true;
        
        emit PriceFeedAdded(priceId, symbol);
    }
    
    /**
     * @dev Remove price feed from monitoring
     * @param priceId Pyth price feed ID to remove
     */
    function removePriceFeed(bytes32 priceId) external onlyOwner {
        require(supportedPriceIds[priceId], "Price feed not found");
        
        uint256 index = priceFeedIndex[priceId];
        priceFeeds[index].active = false;
        supportedPriceIds[priceId] = false;
        
        emit PriceFeedRemoved(priceId);
    }
    
    /**
     * @dev Get maximum allowed staleness for a price feed
     * @param priceId Price feed identifier
     * @return maxStaleness Maximum staleness in seconds
     */
    function _getMaxStaleness(bytes32 priceId) internal view returns (uint256 maxStaleness) {
        if (supportedPriceIds[priceId]) {
            uint256 index = priceFeedIndex[priceId];
            return priceFeeds[index].maxStaleness;
        }
        return 300; // Default 5 minutes
    }
    
    /**
     * @dev Get recent MEV opportunities for a price feed
     * @param priceId Price feed identifier
     * @param limit Maximum number of opportunities to return
     * @return opportunities Array of recent MEV opportunities
     */
    function getRecentMEVOpportunities(
        bytes32 priceId,
        uint256 limit
    ) external view returns (MEVOpportunity[] memory opportunities) {
        MEVOpportunity[] storage allOpportunities = mevOpportunities[priceId];
        uint256 total = allOpportunities.length;
        
        if (total == 0) {
            return new MEVOpportunity[](0);
        }
        
        uint256 count = limit > total ? total : limit;
        opportunities = new MEVOpportunity[](count);
        
        // Return most recent opportunities
        for (uint256 i = 0; i < count; i++) {
            opportunities[i] = allOpportunities[total - 1 - i];
        }
        
        return opportunities;
    }
    
    /**
     * @dev Get performance metrics
     * @return metrics Performance data structure
     */
    function getPerformanceMetrics() external view returns (
        uint256 _totalUpdates,
        uint256 _totalMEVDetected,
        uint256 _totalMEVCaptured,
        uint256 _averageLatency,
        uint256 _activePriceFeeds
    ) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < priceFeeds.length; i++) {
            if (priceFeeds[i].active) {
                activeCount++;
            }
        }
        
        return (
            totalUpdates,
            totalMEVDetected,
            totalMEVCaptured,
            averageUpdateLatency,
            activeCount
        );
    }
    
    /**
     * @dev Get update fee for price data
     * @param updateData Hermes update data
     * @return fee Required fee in wei
     */
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256 fee) {
        return pyth.getUpdateFee(updateData);
    }
    
    /**
     * @dev Emergency withdrawal of contract balance
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Accept ETH for fee payments
     */
    receive() external payable {}
}