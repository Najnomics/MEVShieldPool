// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolId} from "v4-core/src/types/PoolId.sol";

library AuctionLib {
    uint256 public constant AUCTION_DURATION = 12 seconds;
    uint256 public constant LP_SHARE = 90;
    uint256 public constant PROTOCOL_FEE = 10;
    uint256 public constant MIN_BID = 0.001 ether;

    struct AuctionData {
        uint256 highestBid;
        address highestBidder;
        uint256 deadline;
        bool isActive;
        bytes32 blockHash;
        uint256 totalMEVCollected;
    }

    function isAuctionExpired(AuctionData storage auction) internal view returns (bool) {
        return block.timestamp >= auction.deadline;
    }