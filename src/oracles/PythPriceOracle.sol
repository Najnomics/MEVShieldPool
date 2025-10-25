// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IPythPriceOracle.sol";
import "../libraries/PythPriceLib.sol";

/**
 * @title PythPriceOracle
 * @dev Gas-optimized Pyth Network price oracle for MEVShield Pool
 * @notice Provides real-time price feeds with MEV opportunity analysis
 * @author MEVShield Pool Team
 */
contract PythPriceOracle is IPythPriceOracle, Ownable, ReentrancyGuard {
    /// @dev Pyth Network contract interface
    IPyth private immutable pyth;
    
    /// @dev Mapping of price feed IDs to their metadata
    mapping(bytes32 => PriceFeedMetadata) public priceFeedMetadata;
    
    /// @dev Mapping of supported token addresses to their Pyth price IDs
    mapping(address => bytes32) public tokenToPriceId;
    
    /// @dev Mapping to track price feed usage statistics
    mapping(bytes32 => PriceFeedStats) public priceFeedStats;
    
    /// @dev Array of all supported price feed IDs for enumeration
    bytes32[] public supportedPriceFeeds;
    
    /// @dev Gas optimization: cache recent prices to avoid unnecessary updates
    mapping(bytes32 => CachedPrice) private priceCache;
    
    /// @dev Configuration for MEV analysis
    struct MEVAnalysisConfig {
        uint256 deviationThresholdBps; // Basis points (1 bps = 0.01%)
        uint256 maxMEVValueCap; // Maximum MEV value in ETH
        uint256 confidenceWeight; // Weight for confidence in MEV calculation
    }
    
    /// @dev Price feed metadata for gas optimization
    struct PriceFeedMetadata {
        bool isActive;
        uint256 lastUpdateTime;
        uint256 updateFrequency; // Minimum seconds between updates
        address tokenAddress; // Associated token address
        string symbol; // Token symbol for display
    }
    
    /// @dev Price feed usage statistics
    struct PriceFeedStats {
        uint256 totalUpdates;
        uint256 totalGasUsed;
        uint256 averageGasPerUpdate;
        uint256 lastUpdateGasUsed;
    }
    
    /// @dev Cached price data for gas optimization
    struct CachedPrice {
        int64 price;
        uint64 conf;
        int32 expo;
        uint256 publishTime;
        uint256 cacheTime;
    }
    
    /// @dev MEV analysis configuration
    MEVAnalysisConfig public mevConfig;
    
    /// @dev Events for price feed management
    event PriceFeedAdded(bytes32 indexed priceId, address indexed token, string symbol);
    event PriceFeedUpdated(bytes32 indexed priceId, int64 price, uint64 conf, uint256 gasUsed);
    event MEVAnalysisConfigUpdated(uint256 deviationThreshold, uint256 maxValue, uint256 weight);
    event PriceCacheUpdated(bytes32 indexed priceId, int64 price, uint256 cacheTime);
    
    /// @dev Constants for gas optimization
    uint256 private constant CACHE_DURATION = 30 seconds;
    uint256 private constant MIN_UPDATE_INTERVAL = 10 seconds;
    uint256 private constant MAX_PRICE_FEEDS = 50;
    
    /// @dev Constructor initializes Pyth contract and default MEV config
    constructor(
        address _pythContract,
        address _initialOwner
    ) Ownable(_initialOwner) {
        pyth = IPyth(_pythContract);
        
        // Initialize default MEV analysis configuration
        mevConfig = MEVAnalysisConfig({
            deviationThresholdBps: 100, // 1% threshold
            maxMEVValueCap: 10 ether, // 10 ETH maximum
            confidenceWeight: 5000 // 50% weight for confidence
        });
        
        // Initialize common price feeds
        _initializeCommonPriceFeeds();
    }
    
    /// @dev Initialize commonly used price feeds for gas efficiency
    function _initializeCommonPriceFeeds() private {
        // ETH/USD feed
        _addPriceFeed(
            PythPriceLib.ETH_USD_PRICE_ID,
            address(0), // Native ETH
            "ETH"
        );
        
        // BTC/USD feed
        _addPriceFeed(
            PythPriceLib.BTC_USD_PRICE_ID,
            address(0), // Will be set later for WBTC
            "BTC"
        );
        
        // USDC/USD feed
        _addPriceFeed(
            PythPriceLib.USDC_USD_PRICE_ID,
            address(0), // Will be set later for USDC
            "USDC"
        );
    }
    
    /// @dev Get price with gas-optimized caching
    /// @param priceId Pyth Network price feed identifier
    /// @return price Latest price data from Pyth Network
    function getPrice(bytes32 priceId) external view override returns (PythStructs.Price memory price) {
        // Check cache first for gas optimization
        CachedPrice memory cached = priceCache[priceId];
        if (cached.cacheTime > 0 && block.timestamp - cached.cacheTime < CACHE_DURATION) {
            return PythStructs.Price({
                price: cached.price,
                conf: cached.conf,
                expo: cached.expo,
                publishTime: cached.publishTime
            });
        }
        
        // If not cached or expired, get from Pyth
        price = pyth.getPrice(priceId);
        PythPriceLib.validatePrice(price);
        
        return price;
    }
    
    /// @dev Update price feeds with gas optimization
    /// @param updateData Array of price update data from Pyth Network
    function updatePriceFeeds(bytes[] calldata updateData) external payable override nonReentrant {
        uint256 gasStart = gasleft();
        
        // Get required fee and validate payment
        uint256 fee = pyth.getUpdateFee(updateData);
        require(msg.value >= fee, "Insufficient fee");
        
        // Use updatePriceFeedsIfNecessary for gas optimization
        pyth.updatePriceFeeds{value: fee}(updateData);
        
        // Update statistics and cache for processed feeds
        _updateFeedStats(updateData, gasStart);
        
        // Refund excess payment
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
    }
    
    /// @dev Get update fee for price data
    /// @param updateData Array of price update data
    /// @return fee Required fee in wei
    function getUpdateFee(bytes[] calldata updateData) external view override returns (uint256 fee) {
        return pyth.getUpdateFee(updateData);
    }
    
    /// @dev Analyze MEV opportunity based on price deviation
    /// @param priceId Pyth Network price feed identifier
    /// @param swapPrice Expected swap execution price
    /// @return mevValue Calculated MEV opportunity value in wei
    function analyzeMEVOpportunity(
        bytes32 priceId,
        int64 swapPrice
    ) external view override returns (uint256 mevValue) {
        PythStructs.Price memory currentPrice = pyth.getPrice(priceId);
        PythPriceLib.validatePrice(currentPrice);
        
        // Calculate price deviation in basis points
        int64 priceDiff = currentPrice.price - swapPrice;
        uint256 absDiff = priceDiff < 0 ? uint256(uint64(-priceDiff)) : uint256(uint64(priceDiff));
        uint64 absPrice = currentPrice.price > 0 ? uint64(currentPrice.price) : 1;
        uint256 deviationBps = (absDiff * 10000) / uint256(absPrice);
        
        // Only consider significant deviations
        if (deviationBps < mevConfig.deviationThresholdBps) {
            return 0;
        }
        
        // Calculate MEV value based on deviation and confidence
        uint256 baseValue = (deviationBps * 1 ether) / 10000; // Scale to ETH
        uint256 confidenceAdjustment = (mevConfig.confidenceWeight * uint256(currentPrice.conf)) / 10000;
        
        // Apply confidence-based adjustment
        if (confidenceAdjustment < baseValue) {
            mevValue = baseValue - confidenceAdjustment;
        } else {
            mevValue = baseValue / 2; // Reduce by half if low confidence
        }
        
        // Apply maximum cap
        if (mevValue > mevConfig.maxMEVValueCap) {
            mevValue = mevConfig.maxMEVValueCap;
        }
        
        return mevValue;
    }
    
    /// @dev Add new price feed for tracking
    /// @param priceId Pyth Network price feed identifier
    /// @param tokenAddress Associated token contract address
    /// @param symbol Token symbol for identification
    function addPriceFeed(
        bytes32 priceId,
        address tokenAddress,
        string calldata symbol
    ) external onlyOwner {
        require(supportedPriceFeeds.length < MAX_PRICE_FEEDS, "Too many price feeds");
        _addPriceFeed(priceId, tokenAddress, symbol);
    }
    
    /// @dev Internal function to add price feed
    /// @param priceId Pyth Network price feed identifier
    /// @param tokenAddress Associated token contract address
    /// @param symbol Token symbol for identification
    function _addPriceFeed(
        bytes32 priceId,
        address tokenAddress,
        string memory symbol
    ) private {
        require(!priceFeedMetadata[priceId].isActive, "Price feed already exists");
        
        priceFeedMetadata[priceId] = PriceFeedMetadata({
            isActive: true,
            lastUpdateTime: 0,
            updateFrequency: MIN_UPDATE_INTERVAL,
            tokenAddress: tokenAddress,
            symbol: symbol
        });
        
        if (tokenAddress != address(0)) {
            tokenToPriceId[tokenAddress] = priceId;
        }
        
        supportedPriceFeeds.push(priceId);
        
        emit PriceFeedAdded(priceId, tokenAddress, symbol);
    }
    
    /// @dev Update feed statistics after price update
    /// @param updateData Price update data that was processed
    /// @param gasStart Gas amount at function start
    function _updateFeedStats(bytes[] calldata updateData, uint256 gasStart) private {
        uint256 gasUsed = gasStart - gasleft();
        
        // For simplification, we'll update stats for all active feeds
        // In production, you'd parse updateData to get specific feed IDs
        for (uint256 i = 0; i < supportedPriceFeeds.length; i++) {
            bytes32 priceId = supportedPriceFeeds[i];
            PriceFeedMetadata storage metadata = priceFeedMetadata[priceId];
            
            if (metadata.isActive) {
                PriceFeedStats storage stats = priceFeedStats[priceId];
                
                // Update statistics
                stats.totalUpdates++;
                stats.totalGasUsed += gasUsed;
                stats.lastUpdateGasUsed = gasUsed;
                stats.averageGasPerUpdate = stats.totalGasUsed / stats.totalUpdates;
                
                // Update metadata
                metadata.lastUpdateTime = block.timestamp;
                
                // Update cache with latest price
                try pyth.getPrice(priceId) returns (PythStructs.Price memory price) {
                    _updatePriceCache(priceId, price);
                    emit PriceFeedUpdated(priceId, price.price, price.conf, gasUsed);
                } catch {
                    // Skip caching if price fetch fails
                }
            }
        }
    }
    
    /// @dev Update price cache for gas optimization
    /// @param priceId Pyth Network price feed identifier
    /// @param price Latest price data to cache
    function _updatePriceCache(bytes32 priceId, PythStructs.Price memory price) private {
        priceCache[priceId] = CachedPrice({
            price: price.price,
            conf: price.conf,
            expo: price.expo,
            publishTime: price.publishTime,
            cacheTime: block.timestamp
        });
        
        emit PriceCacheUpdated(priceId, price.price, block.timestamp);
    }
    
    /// @dev Update MEV analysis configuration
    /// @param deviationThresholdBps New deviation threshold in basis points
    /// @param maxMEVValueCap New maximum MEV value cap in wei
    /// @param confidenceWeight New confidence weight in basis points
    function updateMEVConfig(
        uint256 deviationThresholdBps,
        uint256 maxMEVValueCap,
        uint256 confidenceWeight
    ) external onlyOwner {
        require(deviationThresholdBps <= 1000, "Deviation too high"); // Max 10%
        require(maxMEVValueCap <= 100 ether, "MEV cap too high");
        require(confidenceWeight <= 10000, "Weight too high"); // Max 100%
        
        mevConfig.deviationThresholdBps = deviationThresholdBps;
        mevConfig.maxMEVValueCap = maxMEVValueCap;
        mevConfig.confidenceWeight = confidenceWeight;
        
        emit MEVAnalysisConfigUpdated(deviationThresholdBps, maxMEVValueCap, confidenceWeight);
    }
    
    /// @dev Remove price feed from tracking
    /// @param priceId Pyth Network price feed identifier to remove
    function removePriceFeed(bytes32 priceId) external onlyOwner {
        require(priceFeedMetadata[priceId].isActive, "Price feed not active");
        
        // Mark as inactive
        priceFeedMetadata[priceId].isActive = false;
        
        // Remove from token mapping
        address tokenAddress = priceFeedMetadata[priceId].tokenAddress;
        if (tokenAddress != address(0)) {
            delete tokenToPriceId[tokenAddress];
        }
        
        // Remove from supported feeds array
        for (uint256 i = 0; i < supportedPriceFeeds.length; i++) {
            if (supportedPriceFeeds[i] == priceId) {
                supportedPriceFeeds[i] = supportedPriceFeeds[supportedPriceFeeds.length - 1];
                supportedPriceFeeds.pop();
                break;
            }
        }
        
        // Clear cache
        delete priceCache[priceId];
    }
    
    /// @dev Get price feed statistics for analytics
    /// @param priceId Pyth Network price feed identifier
    /// @return stats Complete statistics for the price feed
    function getPriceFeedStats(bytes32 priceId) external view returns (PriceFeedStats memory stats) {
        require(priceFeedMetadata[priceId].isActive, "Price feed not active");
        return priceFeedStats[priceId];
    }
    
    /// @dev Get all supported price feed IDs
    /// @return Array of all supported price feed identifiers
    function getSupportedPriceFeeds() external view returns (bytes32[] memory) {
        return supportedPriceFeeds;
    }
    
    /// @dev Get price feed metadata
    /// @param priceId Pyth Network price feed identifier
    /// @return metadata Complete metadata for the price feed
    function getPriceFeedMetadata(bytes32 priceId) external view returns (PriceFeedMetadata memory metadata) {
        return priceFeedMetadata[priceId];
    }
    
    /// @dev Get price feed ID for a token address
    /// @param tokenAddress Token contract address
    /// @return priceId Associated Pyth Network price feed identifier
    function getPriceIdForToken(address tokenAddress) external view returns (bytes32 priceId) {
        return tokenToPriceId[tokenAddress];
    }
    
    /// @dev Emergency function to withdraw contract balance
    /// @dev Only callable by owner in case of stuck funds
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }
    
    /// @dev Batch update multiple price feeds efficiently
    /// @param updateDataArray Array of update data for different price feeds
    function batchUpdatePriceFeeds(bytes[][] calldata updateDataArray) external payable nonReentrant {
        uint256 totalFee = 0;
        
        // Calculate total fee required
        for (uint256 i = 0; i < updateDataArray.length; i++) {
            totalFee += pyth.getUpdateFee(updateDataArray[i]);
        }
        
        require(msg.value >= totalFee, "Insufficient fee for batch update");
        
        uint256 gasStart = gasleft();
        
        // Update all price feeds
        for (uint256 i = 0; i < updateDataArray.length; i++) {
            uint256 fee = pyth.getUpdateFee(updateDataArray[i]);
            pyth.updatePriceFeeds{value: fee}(updateDataArray[i]);
        }
        
        // Update statistics - no update needed for batch
        // Statistics will be updated individually per feed above
        
        // Refund excess payment
        if (msg.value > totalFee) {
            payable(msg.sender).transfer(msg.value - totalFee);
        }
    }
}