// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IYellowNetwork {
    struct StateChannel {
        address participant1;
        address participant2;
        uint256 balance1;
        uint256 balance2;
        uint256 nonce;
        bool isActive;
    }
    
    event ChannelOpened(
        bytes32 indexed channelId,
        address indexed participant1,
        address indexed participant2
    );
    
    function openStateChannel(
        address counterparty,
        uint256 initialDeposit
    ) external payable returns (bytes32 channelId);
    
    function updateChannelState(
        bytes32 channelId,
        uint256 newBalance1,
        uint256 newBalance2,
        bytes calldata signature
    ) external;
}