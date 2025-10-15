// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

library PythPriceLib {
    bytes32 public constant ETH_USD_PRICE_ID = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
    bytes32 public constant USDC_USD_PRICE_ID = 0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a;
    bytes32 public constant BTC_USD_PRICE_ID = 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43;
    
    uint256 public constant MAX_PRICE_AGE = 60;
    uint256 public constant CONFIDENCE_THRESHOLD = 1000;
    
    error PriceTooOld();
    error PriceConfidenceTooLow();
    error InvalidPriceData();
    
    function validatePrice(PythStructs.Price memory price) internal view {
        if (block.timestamp - price.publishTime > MAX_PRICE_AGE) {
            revert PriceTooOld();
        }
        if (price.conf > uint64(CONFIDENCE_THRESHOLD)) {
            revert PriceConfidenceTooLow();
        }
    }