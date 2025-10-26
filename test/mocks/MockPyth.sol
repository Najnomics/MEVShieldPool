// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title MockPyth
 * @dev Minimal mock Pyth contract for testing price feeds
 * @notice Provides deterministic price data for unit tests
 * @author MEVShield Pool Team
 */
contract MockPyth {
    /**
     * @dev Mock price structure matching Pyth format
     */
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint publishTime;
    }
    
    /**
     * @dev Mapping from price feed ID to mock price data
     */
    mapping(bytes32 => Price) public prices;
    
    /**
     * @dev Mock price feed IDs for testing
     */
    bytes32 public constant ETH_USD_FEED = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
    bytes32 public constant USDC_USD_FEED = 0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a;
    
    /**
     * @dev Constructor sets up mock price data
     */
    constructor() {
        // Set ETH/USD mock price: $2000.00
        prices[ETH_USD_FEED] = Price({
            price: 200000000000, // $2000 with 8 decimals
            conf: 1000000000,    // $10 confidence
            expo: -8,            // 8 decimal places
            publishTime: block.timestamp
        });
        
        // Set USDC/USD mock price: $1.00
        prices[USDC_USD_FEED] = Price({
            price: 100000000,    // $1.00 with 8 decimals
            conf: 1000000,       // $0.01 confidence
            expo: -8,            // 8 decimal places
            publishTime: block.timestamp
        });
    }
    
    /**
     * @dev Updates mock price for testing scenarios
     * @param id Price feed identifier
     * @param price New price value
     * @param conf Confidence interval
     */
    function updatePrice(bytes32 id, int64 price, uint64 conf) external {
        Price storage p = prices[id];
        p.price = price;
        p.conf = conf;
        p.expo = p.expo == 0 ? -8 : p.expo; // Preserve or set expo to -8
        p.publishTime = block.timestamp;
    }
    
    /**
     * @dev Gets current price for given feed ID
     * @param id Price feed identifier
     * @return price Mock price structure
     */
    function getPrice(bytes32 id) external view returns (Price memory price) {
        return prices[id];
    }
    
    /**
     * @dev Gets latest price no older than specified age
     * @param id Price feed identifier
     * @param age Maximum age in seconds
     * @return price Mock price structure
     */
    function getPriceNoOlderThan(bytes32 id, uint age) external view returns (Price memory price) {
        require(block.timestamp - prices[id].publishTime <= age, "Price too old");
        return prices[id];
    }
}