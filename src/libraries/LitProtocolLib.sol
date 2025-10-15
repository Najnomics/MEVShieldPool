// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library LitProtocolLib {
    struct AccessControlCondition {
        string contractAddress;
        string standardContractType;
        string chain;
        string method;
        string parameters;
        string returnValueTest;
    }
    
    struct EncryptionParams {
        bytes32 sessionKey;
        bytes accessControlConditions;
        bytes encryptedSymmetricKey;
        uint256 timestamp;
    }
    
    function createBidConditions(
        address bidder,
        uint256 minAmount
    ) internal pure returns (bytes memory) {
        return abi.encode(bidder, minAmount, block.timestamp);
    }
}