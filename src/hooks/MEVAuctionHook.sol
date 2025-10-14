// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AuctionLib} from "../libraries/AuctionLib.sol";
import {IMEVAuction} from "../interfaces/IMEVAuction.sol";

contract MEVAuctionHook is BaseHook, ReentrancyGuard, Ownable, IMEVAuction {
    using PoolIdLibrary for PoolKey;
    using AuctionLib for AuctionLib.AuctionData;

    mapping(PoolId => AuctionLib.AuctionData) public auctions;
    mapping(PoolId => mapping(address => uint256)) public bids;
    mapping(PoolId => mapping(address => uint256)) public lpRewards;
    mapping(PoolId => address[]) public bidders;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) Ownable(msg.sender) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeInitialize(
        address,
        PoolKey calldata key,
        uint160,
        bytes calldata
    ) external override returns (bytes4) {
        PoolId poolId = key.toId();
        auctions[poolId] = AuctionLib.AuctionData({
            highestBid: 0,
            highestBidder: address(0),
            deadline: block.timestamp + AuctionLib.AUCTION_DURATION,
            isActive: true,
            blockHash: blockhash(block.number - 1),
            totalMEVCollected: 0
        });
        return BaseHook.beforeInitialize.selector;
    }

    function submitBid(PoolKey calldata key) external payable nonReentrant {
        PoolId poolId = key.toId();
        require(msg.value >= AuctionLib.MIN_BID, "Bid too low");
        require(auctions[poolId].isActive, "Auction not active");
        require(block.timestamp < auctions[poolId].deadline, "Auction expired");
        require(msg.value > auctions[poolId].highestBid, "Bid not high enough");

        if (auctions[poolId].highestBidder != address(0)) {
            payable(auctions[poolId].highestBidder).transfer(auctions[poolId].highestBid);
        }

        auctions[poolId].highestBid = msg.value;
        auctions[poolId].highestBidder = msg.sender;
        bids[poolId][msg.sender] = msg.value;
        
        if (bidders[poolId].length == 0 || bidders[poolId][bidders[poolId].length - 1] != msg.sender) {
            bidders[poolId].push(msg.sender);
        }

        emit BidSubmitted(poolId, msg.sender, msg.value);
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();
        AuctionLib.AuctionData storage auction = auctions[poolId];

        if (auction.isActive && auction.isAuctionExpired()) {
            _finalizeAuction(poolId);
        }

        bool hasAuctionRights = (auction.highestBidder == sender) && 
                               (auction.blockHash == blockhash(block.number - 1));

        if (!auction.isActive) {
            _startNewAuction(poolId);
        }

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }