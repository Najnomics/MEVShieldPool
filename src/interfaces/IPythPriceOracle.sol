// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

interface IPythPriceOracle {
    event PriceUpdated(
        bytes32 indexed priceId,
        int64 price,
        uint64 confidence
    );
    
    event MEVPriceAnalysis(
        bytes32 indexed poolId,
        int64 currentPrice,
        int64 expectedPrice,
        uint256 deviation
    );
    
    function getPrice(bytes32 priceId) external view returns (PythStructs.Price memory);
    
    function updatePriceFeeds(bytes[] calldata updateData) external payable;
    
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256);
    
    function analyzeMEVOpportunity(
        bytes32 priceId,
        int64 swapPrice
    ) external view returns (uint256 mevValue);
}