// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AuctionLib} from "../../src/libraries/AuctionLib.sol";

contract TestMEVAuctionHook {
    using AuctionLib for AuctionLib.AuctionData;

    mapping(bytes32 => AuctionLib.AuctionData) public auctions;

    event BidSubmitted(bytes32 indexed poolId, address indexed bidder, uint256 amount);

    constructor() {}

    function submitBid(bytes32 poolId) external payable {
        require(msg.value >= AuctionLib.MIN_BID, "Bid below minimum");

        AuctionLib.AuctionData storage auction = auctions[poolId];
        if (!auction.isActive) {
            auctions[poolId] = AuctionLib.AuctionData({
                highestBid: 0,
                highestBidder: address(0),
                deadline: block.timestamp + AuctionLib.AUCTION_DURATION,
                isActive: true,
                blockHash: blockhash(block.number - 1),
                totalMEVCollected: 0
            });
            auction = auctions[poolId];
        }
        require(!auction.isAuctionExpired(), "Auction expired");

        if (auction.highestBid > 0 && msg.value > auction.highestBid) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        if (msg.value > auction.highestBid) {
            auction.highestBid = msg.value;
            auction.highestBidder = msg.sender;
            emit BidSubmitted(poolId, msg.sender, msg.value);
        }
    }

    function submitEncryptedBid(bytes32 poolId, bytes calldata, bytes calldata) external payable {
        // mirror submitBid logic for test purposes
        this.submitBid{value: msg.value}(poolId);
    }
}


