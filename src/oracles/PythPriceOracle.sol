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