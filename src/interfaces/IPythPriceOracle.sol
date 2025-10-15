// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IPythPriceOracle {
    struct PriceData {
        int64 price;
        uint64 conf;
        int32 expo;
        uint publishTime;
    }
    
    event PriceUpdated(
        bytes32 indexed priceId,
        int64 price,
        uint64 confidence
    );
    
    function getPrice(bytes32 priceId) external view returns (PriceData memory);
    
    function updatePriceFeeds(bytes[] calldata updateData) external payable;
    
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256);
}