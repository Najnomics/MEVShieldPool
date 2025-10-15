// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "v4-core/src/types/PoolKey.sol";

interface IMEVAuction {
    struct Auction {
        uint256 highestBid;
        address highestBidder;
        uint256 deadline;
        bool isActive;
        bytes32 blockHash;
    }

    struct EncryptedBid {
        address bidder;
        bytes encryptedData;
        bytes32 dataHash;
        uint256 timestamp;
        bool revealed;
    }

    event BidSubmitted(bytes32 indexed poolId, address indexed bidder, uint256 amount);
    event AuctionWon(bytes32 indexed poolId, address indexed winner, uint256 amount);
    event MEVDistributed(bytes32 indexed poolId, uint256 lpAmount, uint256 protocolAmount);

    function submitBid(bytes32 poolId) external payable;
    function submitEncryptedBid(bytes32 poolId, bytes calldata encryptedBid, bytes calldata decryptionKey) external payable;
}