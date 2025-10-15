// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILitEncryption {
    struct EncryptedBid {
        bytes encryptedAmount;
        bytes accessControlConditions;
        string dataToEncryptHash;
        uint256 timestamp;
    }
    
    event BidEncrypted(
        bytes32 indexed poolId,
        address indexed bidder,
        bytes encryptedData
    );
    
    event BidDecrypted(
        bytes32 indexed poolId,
        address indexed bidder,
        uint256 amount
    );
    
    function encryptBid(
        bytes32 poolId,
        uint256 amount,
        bytes calldata accessConditions
    ) external returns (bytes memory encryptedData);
}