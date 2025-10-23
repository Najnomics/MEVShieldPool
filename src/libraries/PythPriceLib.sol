// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title PythPriceLib - Enhanced Pyth Network Integration Library
 * @dev Utilities for working with Pyth Network price feeds and MEV detection
 * @author MEVShield Pool Team - ETHOnline 2025
 */
library PythPriceLib {
    // Mainnet Pyth Network price feed IDs
    bytes32 public constant ETH_USD_PRICE_ID = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
    bytes32 public constant USDC_USD_PRICE_ID = 0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a;
    bytes32 public constant BTC_USD_PRICE_ID = 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43;
    bytes32 public constant USDT_USD_PRICE_ID = 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca8e69b61c7ce4c4b1fd8b2cbe2;
    bytes32 public constant WBTC_USD_PRICE_ID = 0xc9d8b075a5c69303365ae23633d4e085199bf5c520a3b90fed1322a3fd1c4e0e;
    
    // Price validation parameters
    uint256 public constant MAX_PRICE_AGE = 60; // 1 minute for real-time MEV detection
    uint256 public constant CONFIDENCE_THRESHOLD = 1000; // 10% in basis points
    uint256 public constant MAX_CONFIDENCE_INTERVAL = 1000; // 10% in basis points
    
    // MEV detection thresholds
    uint256 public constant MIN_MEV_THRESHOLD = 10; // 0.1% in basis points
    uint256 public constant HIGH_MEV_THRESHOLD = 100; // 1% in basis points
    uint256 public constant EXTREME_MEV_THRESHOLD = 500; // 5% in basis points
    
    // Default MPC parameters for Lit Protocol integration
    uint256 public constant DEFAULT_MPC_THRESHOLD = 2;
    uint256 public constant DEFAULT_MPC_NODES = 3;
    
    error PriceTooOld();
    error PriceConfidenceTooLow();
    error InvalidPriceData();
    error PriceValidationFailed(string reason);
    error PriceDataStale(uint256 age, uint256 maxAge);
    error InvalidPriceValue(int64 price);
    
    /**
     * @dev Enhanced price validation with MEV detection focus
     * @param price Pyth price structure to validate
     */
    function validatePrice(PythStructs.Price memory price) internal view {
        // Check if price is positive
        if (price.price <= 0) {
            revert InvalidPriceValue(price.price);
        }
        
        // Check if publish time is valid
        if (price.publishTime == 0) {
            revert PriceValidationFailed("Invalid publish time");
        }
        
        // Check price staleness
        uint256 age = block.timestamp - price.publishTime;
        if (age > MAX_PRICE_AGE) {
            revert PriceDataStale(age, MAX_PRICE_AGE);
        }
        
        // Check confidence interval
        if (price.conf > uint64(CONFIDENCE_THRESHOLD)) {
            revert PriceConfidenceTooLow();
        }
    }
    
    /**
     * @dev Calculate price deviation between two prices
     * @param price1 First price
     * @param price2 Second price
     * @return deviation Absolute price deviation
     * @return deviationBps Deviation in basis points
     */
    function calculatePriceDeviation(
        int64 price1,
        int64 price2
    ) internal pure returns (uint256 deviation, uint256 deviationBps) {
        int64 diff = price1 > price2 ? price1 - price2 : price2 - price1;
        deviation = uint256(uint64(diff));
        
        if (price2 != 0) {
            deviationBps = (deviation * 10000) / uint256(uint64(price2));
        } else {
            deviationBps = 0;
        }
        
        return (deviation, deviationBps);
    }
    
    /**
     * @dev Format Pyth price to standard 18 decimal format
     * @param price Pyth price structure
     * @return formattedPrice Price in 18 decimal format
     */
    function formatPrice(
        PythStructs.Price memory price
    ) internal pure returns (uint256 formattedPrice) {
        require(price.price > 0, "Invalid price for formatting");
        
        uint256 absPrice = uint256(uint64(price.price));
        
        if (price.expo >= 0) {
            // Positive exponent: multiply by 10^expo
            formattedPrice = absPrice * (10 ** uint32(price.expo)) * 1e10;
        } else {
            // Negative exponent: divide by 10^(-expo)
            uint32 negExpo = uint32(-price.expo);
            if (negExpo <= 18) {
                formattedPrice = (absPrice * (10 ** (18 - negExpo)));
            } else {
                formattedPrice = absPrice / (10 ** (negExpo - 18));
            }
        }
        
        return formattedPrice;
    }
    
    /**
     * @dev Determine MEV risk level based on price deviation
     * @param deviationBps Price deviation in basis points
     * @return riskLevel Risk level (0=none, 1=low, 2=medium, 3=high, 4=extreme)
     */
    function getMEVRiskLevel(uint256 deviationBps) internal pure returns (uint8 riskLevel) {
        if (deviationBps < MIN_MEV_THRESHOLD) {
            return 0; // No significant MEV risk
        } else if (deviationBps < HIGH_MEV_THRESHOLD) {
            return 1; // Low MEV risk
        } else if (deviationBps < 200) { // 2%
            return 2; // Medium MEV risk
        } else if (deviationBps < EXTREME_MEV_THRESHOLD) {
            return 3; // High MEV risk
        } else {
            return 4; // Extreme MEV risk
        }
    }
    
    /**
     * @dev Calculate estimated MEV value based on price deviation and volume
     * @param deviationBps Price deviation in basis points
     * @param tradeVolume Trade volume in wei
     * @param liquidityDepth Available liquidity depth
     * @return mevValue Estimated MEV value in wei
     */
    function calculateMEVValue(
        uint256 deviationBps,
        uint256 tradeVolume,
        uint256 liquidityDepth
    ) internal pure returns (uint256 mevValue) {
        if (deviationBps < MIN_MEV_THRESHOLD || tradeVolume == 0) {
            return 0;
        }
        
        // Base MEV calculation: deviation percentage of trade volume
        uint256 baseMEV = (tradeVolume * deviationBps) / 10000;
        
        // Adjust based on liquidity depth
        if (liquidityDepth > 0 && tradeVolume > liquidityDepth / 10) {
            // Large trade relative to liquidity - higher MEV potential
            uint256 liquidityImpact = (tradeVolume * 10000) / liquidityDepth;
            baseMEV = (baseMEV * (10000 + liquidityImpact)) / 10000;
        }
        
        // Cap MEV value at reasonable limits
        uint256 maxMEV = tradeVolume / 20; // Max 5% of trade volume
        return baseMEV > maxMEV ? maxMEV : baseMEV;
    }
    
    /**
     * @dev Validate MPC parameters for Lit Protocol integration
     * @param threshold Minimum signatures required
     * @param totalNodes Total number of MPC nodes
     * @return valid Whether parameters are valid
     */
    function validateMPCParams(uint256 threshold, uint256 totalNodes) internal pure returns (bool valid) {
        return threshold > 0 && 
               threshold <= totalNodes && 
               totalNodes <= 10 && // Reasonable upper limit
               threshold >= (totalNodes * 2) / 3; // At least 2/3 majority
    }
    
    /**
     * @dev Generate session key hash for Lit Protocol encryption
     * @param poolId Pool identifier
     * @param round Auction round number
     * @param timestamp Current timestamp
     * @return sessionKeyHash Generated session key hash
     */
    function generateSessionKeyHash(
        bytes32 poolId,
        uint256 round,
        uint256 timestamp
    ) internal pure returns (bytes32 sessionKeyHash) {
        return keccak256(abi.encodePacked(poolId, round, timestamp, "MEVShield"));
    }
    
    /**
     * @dev Check if session is still valid based on timestamp
     * @param sessionTimestamp Session creation timestamp
     * @return valid Whether session is still valid
     */
    function isSessionValid(uint256 sessionTimestamp) internal view returns (bool valid) {
        return block.timestamp - sessionTimestamp <= 3600; // 1 hour validity
    }
    
    /**
     * @dev Get price feed name by ID
     * @param priceId Pyth price feed ID
     * @return symbol Price feed symbol
     */
    function getPriceFeedSymbol(bytes32 priceId) internal pure returns (string memory symbol) {
        if (priceId == ETH_USD_PRICE_ID) return "ETH/USD";
        if (priceId == BTC_USD_PRICE_ID) return "BTC/USD";
        if (priceId == USDC_USD_PRICE_ID) return "USDC/USD";
        if (priceId == USDT_USD_PRICE_ID) return "USDT/USD";
        if (priceId == WBTC_USD_PRICE_ID) return "WBTC/USD";
        return "UNKNOWN";
    }
}