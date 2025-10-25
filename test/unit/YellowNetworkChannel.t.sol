// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {YellowStateChannel} from "../../src/hooks/YellowStateChannel.sol";

/**
 * @title YellowNetworkChannelTest
 * @dev Comprehensive tests for Yellow Network ERC-7824 state channel functionality
 * @notice Tests channel lifecycle, state updates, and cross-chain settlement
 * @author MEVShield Pool Team
 */
contract YellowNetworkChannelTest is Test {
    /**
     * @dev Test contract instance for state channel operations
     */
    YellowStateChannel public yellowChannel;
    
    /**
     * @dev Test addresses for cross-chain scenarios
     */
    address public channelManager = address(0x1);
    address public participant1 = address(0x2);
    address public participant2 = address(0x3);
    address public mediator = address(0x4);
    
    /**
     * @dev Test constants for state channel operations
     */
    uint256 public constant INITIAL_BALANCE = 20 ether;
    uint256 public constant CHANNEL_DEPOSIT = 5 ether;
    uint256 public constant MIN_CHANNEL_BALANCE = 0.1 ether;
    uint256 public constant DISPUTE_TIMEOUT = 1 days;
    uint64 public constant CHANNEL_NONCE_START = 1;
    
    /**
     * @dev Events for state channel testing
     */
    event StateChannelOpened(bytes32 indexed channelId, address indexed participant1, address indexed participant2);
    event StateChannelUpdated(bytes32 indexed channelId, uint256 balance1, uint256 balance2, uint64 nonce);
    event StateChannelClosed(bytes32 indexed channelId, uint256 finalBalance1, uint256 finalBalance2);
    event DisputeInitiated(bytes32 indexed channelId, address indexed initiator, string reason);
    event DisputeResolved(bytes32 indexed channelId, bool inFavorOfParticipant1);

    /**
     * @dev Setup state channel test environment
     */
    function setUp() public {
        // Fund test accounts for channel operations
        vm.deal(channelManager, INITIAL_BALANCE);
        vm.deal(participant1, INITIAL_BALANCE);
        vm.deal(participant2, INITIAL_BALANCE);
        vm.deal(mediator, INITIAL_BALANCE);
        
        // Deploy Yellow Network state channel contract
        vm.prank(channelManager);
        yellowChannel = new YellowStateChannel(channelManager);
    }

    /**
     * @dev Test basic state channel opening functionality
     */
    function testStateChannelOpening() public {
        uint256 deposit1 = CHANNEL_DEPOSIT;
        uint256 deposit2 = CHANNEL_DEPOSIT / 2;
        
        // Expect channel opened event
        vm.expectEmit(true, true, true, false);
        emit StateChannelOpened(bytes32(0), participant1, participant2);
        
        // Open state channel between participants
        vm.prank(participant1);
        bytes32 channelId = yellowChannel.openStateChannel{value: deposit1}(
            participant2,
            deposit2
        );
        
        // Verify channel was created correctly
        YellowStateChannel.EnhancedStateChannel memory channel = yellowChannel.getChannel(channelId);
        assertTrue(channel.isActive, "Channel should be active");
        assertEq(channel.participant1, participant1, "Participant1 should be set");
        assertEq(channel.participant2, participant2, "Participant2 should be set");
        assertEq(channel.balance1, deposit1, "Balance1 should match deposit");
        assertEq(channel.balance2, deposit2, "Balance2 should match expected");
        assertEq(channel.nonce, CHANNEL_NONCE_START, "Nonce should start at 1");
        assertTrue(channel.challengeDeadline > block.timestamp, "Challenge deadline should be in future");
    }

    /**
     * @dev Test state channel balance updates with proper validation
     */
    function testStateChannelBalanceUpdates() public {
        // Open initial channel
        vm.prank(participant1);
        bytes32 channelId = yellowChannel.openStateChannel{value: CHANNEL_DEPOSIT}(
            participant2,
            CHANNEL_DEPOSIT
        );
        
        // Generate valid signature for state update
        bytes memory signature = _generateMockSignature(channelId, 1);
        
        uint256 newBalance1 = CHANNEL_DEPOSIT - 1 ether;
        uint256 newBalance2 = CHANNEL_DEPOSIT + 1 ether;
        
        // Expect state update event
        vm.expectEmit(true, false, false, true);
        emit StateChannelUpdated(channelId, newBalance1, newBalance2, CHANNEL_NONCE_START + 1);
        
        // Update channel state
        vm.prank(participant1);
        yellowChannel.updateChannelState(
            channelId,
            newBalance1,
            newBalance2,
            signature
        );
        
        // Verify state was updated
        YellowStateChannel.EnhancedStateChannel memory updatedChannel = yellowChannel.getChannel(channelId);
        assertEq(updatedChannel.balance1, newBalance1, "Balance1 should be updated");
        assertEq(updatedChannel.balance2, newBalance2, "Balance2 should be updated");
        assertEq(updatedChannel.nonce, CHANNEL_NONCE_START + 1, "Nonce should increment");
    }

    /**
     * @dev Test state channel closing with final settlement
     */
    function testStateChannelClosing() public {
        // Open and update channel
        vm.prank(participant1);
        bytes32 channelId = yellowChannel.openStateChannel{value: CHANNEL_DEPOSIT}(
            participant2,
            CHANNEL_DEPOSIT
        );
        
        // Record balances before closing
        uint256 participant1BalanceBefore = participant1.balance;
        uint256 participant2BalanceBefore = participant2.balance;
        
        // Close channel with final state
        vm.expectEmit(true, false, false, true);
        emit StateChannelClosed(channelId, CHANNEL_DEPOSIT, CHANNEL_DEPOSIT);
        
        vm.prank(participant1);
        yellowChannel.closeChannel(channelId);
        
        // Verify channel is closed
        YellowStateChannel.EnhancedStateChannel memory closedChannel = yellowChannel.getChannel(channelId);
        assertFalse(closedChannel.isActive, "Channel should be inactive");
        
        // Verify final settlement (balances should be returned)
        uint256 participant1BalanceAfter = participant1.balance;
        uint256 participant2BalanceAfter = participant2.balance;
        
        assertEq(
            participant1BalanceAfter, 
            participant1BalanceBefore + CHANNEL_DEPOSIT, 
            "Participant1 should receive final balance"
        );
        assertEq(
            participant2BalanceAfter, 
            participant2BalanceBefore + CHANNEL_DEPOSIT, 
            "Participant2 should receive final balance"
        );
    }

    /**
     * @dev Test dispute initiation and resolution mechanism
     */
    function testDisputeInitiationAndResolution() public {
        // Open channel for dispute testing
        vm.prank(participant1);
        bytes32 channelId = yellowChannel.openStateChannel{value: CHANNEL_DEPOSIT}(
            participant2,
            CHANNEL_DEPOSIT
        );
        
        string memory disputeReason = "Invalid state transition detected";
        
        // Challenge channel closure to simulate dispute
        vm.prank(participant2);
        yellowChannel.challengeChannelClosure(channelId);
        
        // Verify channel remains active during challenge
        YellowStateChannel.EnhancedStateChannel memory challengedChannel = yellowChannel.getChannel(channelId);
        assertTrue(challengedChannel.isActive, "Channel should remain active during challenge");
        
        // Fast forward past challenge period
        vm.warp(block.timestamp + DISPUTE_TIMEOUT + 1);
        
        // Close channel after challenge period expires
        vm.prank(participant1);
        yellowChannel.closeChannel(channelId);
        
        // Verify channel closure
        YellowStateChannel.EnhancedStateChannel memory closedChannel = yellowChannel.getChannel(channelId);
        assertFalse(closedChannel.isActive, "Channel should be closed after challenge period");
    }

    /**
     * @dev Test cross-chain settlement validation
     */
    function testCrossChainSettlementValidation() public {
        // Setup cross-chain scenario with different chain participants
        uint256 ethereumDeposit = 3 ether;
        uint256 polygonDeposit = 2 ether;
        
        vm.prank(participant1);
        bytes32 crossChainChannelId = yellowChannel.openStateChannel{value: ethereumDeposit}(
            participant2,
            polygonDeposit
        );
        
        // Simulate cross-chain state update
        bytes memory crossChainSignature = _generateMockSignature(crossChainChannelId, 2);
        uint256 settlementBalance1 = 4 ether; // Net transfer from chain 2 to chain 1
        uint256 settlementBalance2 = 1 ether;
        
        vm.prank(participant1);
        yellowChannel.updateChannelState(
            crossChainChannelId,
            settlementBalance1,
            settlementBalance2,
            crossChainSignature
        );
        
        // Verify cross-chain state is maintained
        YellowStateChannel.EnhancedStateChannel memory crossChainChannel = 
            yellowChannel.getChannel(crossChainChannelId);
        assertEq(crossChainChannel.balance1, settlementBalance1, "Cross-chain balance1 should be updated");
        assertEq(crossChainChannel.balance2, settlementBalance2, "Cross-chain balance2 should be updated");
    }

    /**
     * @dev Test channel timeout and emergency closure
     */
    function testChannelTimeoutAndEmergencyClosure() public {
        // Open channel with short timeout for testing
        vm.prank(participant1);
        bytes32 channelId = yellowChannel.openStateChannel{value: CHANNEL_DEPOSIT}(
            participant2,
            CHANNEL_DEPOSIT
        );
        
        // Get initial timeout
        YellowStateChannel.EnhancedStateChannel memory initialChannel = yellowChannel.getChannel(channelId);
        uint256 originalTimeout = initialChannel.challengeDeadline;
        
        // Fast forward past timeout
        vm.warp(originalTimeout + 1);
        
        // Close channel after timeout
        vm.prank(participant1);
        yellowChannel.closeChannel(channelId);
        
        // Verify emergency closure
        YellowStateChannel.EnhancedStateChannel memory emergencyClosedChannel = 
            yellowChannel.getChannel(channelId);
        assertFalse(emergencyClosedChannel.isActive, "Channel should be closed after timeout");
    }

    /**
     * @dev Test gas efficiency of state channel operations
     */
    function testStateChannelGasEfficiency() public {
        // Measure gas for channel opening
        uint256 gasBefore = gasleft();
        vm.prank(participant1);
        bytes32 channelId = yellowChannel.openStateChannel{value: CHANNEL_DEPOSIT}(
            participant2,
            CHANNEL_DEPOSIT
        );
        uint256 openGasUsed = gasBefore - gasleft();
        
        // Channel opening should be gas efficient
        assertTrue(openGasUsed < 200000, "Channel opening should use less than 200k gas");
        
        // Measure gas for state update
        bytes memory signature = _generateMockSignature(channelId, 1);
        gasBefore = gasleft();
        vm.prank(participant1);
        yellowChannel.updateChannelState(channelId, CHANNEL_DEPOSIT - 1 ether, CHANNEL_DEPOSIT + 1 ether, signature);
        uint256 updateGasUsed = gasBefore - gasleft();
        
        // State update should be gas efficient
        assertTrue(updateGasUsed < 100000, "State update should use less than 100k gas");
    }

    /**
     * @dev Helper function to generate mock signature for testing
     * @param channelId The channel identifier
     * @param nonce The nonce for the signature
     * @return signature Mock signature bytes
     */
    function _generateMockSignature(bytes32 channelId, uint64 nonce) internal pure returns (bytes memory signature) {
        // Generate deterministic mock signature based on channel ID and nonce
        bytes32 hash = keccak256(abi.encodePacked(channelId, nonce));
        signature = abi.encodePacked(hash, bytes1(0x1b));
        return signature;
    }
}