// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {PythPriceLib} from "../libraries/PythPriceLib.sol";
import {IPythPriceOracle} from "../interfaces/IPythPriceOracle.sol";

contract PythPriceHook is IPythPriceOracle {
    IPyth public immutable pyth;
    
    mapping(bytes32 => PythStructs.Price) public latestPrices;
    mapping(bytes32 => uint256) public lastUpdateTimes;
    
    constructor(address _pythContract) {
        pyth = IPyth(_pythContract);
    }
    
    function getPrice(bytes32 priceId) external view override returns (PythStructs.Price memory) {
        PythStructs.Price memory price = pyth.getPrice(priceId);
        PythPriceLib.validatePrice(price);
        return price;
    }
    
    function updatePriceFeeds(bytes[] calldata updateData) external payable override {
        uint256 fee = pyth.getUpdateFee(updateData);
        require(msg.value >= fee, "Insufficient fee");
        pyth.updatePriceFeeds{value: fee}(updateData);
    }
}