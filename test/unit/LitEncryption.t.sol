// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {LitEncryptionHook} from "../../src/hooks/LitEncryptionHook.sol";
import {LitProtocolLib} from "../../src/libraries/LitProtocolLib.sol";

/**
 * @title LitEncryptionTest
 * @dev Comprehensive tests for Lit Protocol MPC/TSS encryption functionality
 * @notice Tests access control, session management, and encryption parameters
 * @author MEVShield Pool Team
 */
contract LitEncryptionTest is Test {
    /**
     * @dev Test contract instances
     */
    LitEncryptionHook public litHook;
    
    /**
     * @dev Test addresses for encryption scenarios
     */
    address public encryptionManager = address(0x1);
    address public bidder = address(0x2);
    address public unauthorizedUser = address(0x3);
    
    /**
     * @dev Test constants for encryption testing
     */
    uint256 public constant INITIAL_BALANCE = 10 ether;
    uint256 public constant MIN_BID_AMOUNT = 0.1 ether;
    uint256 public constant AUCTION_DEADLINE = 1000;
    bytes32 public constant TEST_POOL_ID = keccak256("test_pool_encryption");
    
    /**
     * @dev Events for encryption testing
     */
    event EncryptionSessionCreated(bytes32 indexed sessionKey, address indexed creator);
    event AccessControlValidated(address indexed user, bool hasAccess);
    event DecryptionRequested(bytes32 indexed sessionKey, address indexed requester);

    /**
     * @dev Setup encryption test environment
     */
    function setUp() public {
        // Fund test accounts for encryption operations
        vm.deal(encryptionManager, INITIAL_BALANCE);
        vm.deal(bidder, INITIAL_BALANCE);
        vm.deal(unauthorizedUser, INITIAL_BALANCE);
        
        // Deploy Lit encryption hook
        vm.prank(encryptionManager);
        litHook = new LitEncryptionHook(encryptionManager);
    }

    /**
     * @dev Test MPC threshold parameter validation
     */
    function testMPCThresholdValidation() public {
        // Test valid threshold configurations
        assertTrue(
            LitProtocolLib.validateMPCParams(2, 3),
            "2-of-3 threshold should be valid"
        );
        assertTrue(
            LitProtocolLib.validateMPCParams(3, 5),
            "3-of-5 threshold should be valid"
        );
        assertTrue(
            LitProtocolLib.validateMPCParams(51, 100),
            "51-of-100 threshold should be valid"
        );
        
        // Test invalid threshold configurations
        assertFalse(
            LitProtocolLib.validateMPCParams(0, 3),
            "0 threshold should be invalid"
        );
        assertFalse(
            LitProtocolLib.validateMPCParams(2, 2),
            "50% threshold should be invalid (need majority)"
        );
        assertFalse(
            LitProtocolLib.validateMPCParams(4, 3),
            "Threshold > total nodes should be invalid"
        );
        assertFalse(
            LitProtocolLib.validateMPCParams(3, 101),
            "Too many nodes should be invalid"
        );
    }

    /**
     * @dev Test access control condition creation for bid encryption
     */
    function testBidAccessControlConditions() public {
        // Create access control conditions for encrypted bidding
        bytes memory conditions = LitProtocolLib.createBidConditions(
            bidder,
            MIN_BID_AMOUNT,
            AUCTION_DEADLINE
        );
        
        // Verify conditions were created (non-empty)
        assertTrue(conditions.length > 0, "Access control conditions should be generated");
        
        // Decode and verify structure
        LitProtocolLib.AccessControlCondition[] memory decodedConditions = 
            abi.decode(conditions, (LitProtocolLib.AccessControlCondition[]));
        
        assertEq(decodedConditions.length, 2, "Should have 2 access control conditions");
        
        // Verify balance condition
        assertEq(decodedConditions[0].chain, "ethereum", "Chain should be ethereum");
        assertEq(decodedConditions[0].method, "eth_getBalance", "Method should check balance");
        
        // Verify timing condition
        assertEq(decodedConditions[1].method, "eth_blockNumber", "Method should check block number");
    }

    /**
     * @dev Test session key generation and validation
     */
    function testSessionKeyManagement() public {
        uint256 auctionRound = 1;
        uint256 currentTime = block.timestamp;
        
        // Generate session key hash
        bytes32 sessionKey1 = LitProtocolLib.generateSessionKeyHash(
            TEST_POOL_ID,
            auctionRound,
            currentTime
        );
        
        // Generate another session key with same parameters
        bytes32 sessionKey2 = LitProtocolLib.generateSessionKeyHash(
            TEST_POOL_ID,
            auctionRound,
            currentTime
        );
        
        // Session keys should be identical for same parameters
        assertEq(sessionKey1, sessionKey2, "Session keys should be deterministic");
        
        // Generate session key with different round
        bytes32 sessionKey3 = LitProtocolLib.generateSessionKeyHash(
            TEST_POOL_ID,
            auctionRound + 1,
            currentTime
        );
        
        // Should be different for different round
        assertTrue(sessionKey1 != sessionKey3, "Session keys should differ for different rounds");
    }

    /**
     * @dev Test session expiry validation
     */
    function testSessionExpiryValidation() public {
        uint256 sessionTimestamp = block.timestamp;
        
        // Fresh session should be valid
        assertTrue(
            LitProtocolLib.isSessionValid(sessionTimestamp),
            "Fresh session should be valid"
        );
        
        // Fast forward within expiry window
        vm.warp(block.timestamp + 30 minutes);
        assertTrue(
            LitProtocolLib.isSessionValid(sessionTimestamp),
            "Session should still be valid within window"
        );
        
        // Fast forward past expiry
        vm.warp(sessionTimestamp + LitProtocolLib.SESSION_KEY_EXPIRY + 1);
        assertFalse(
            LitProtocolLib.isSessionValid(sessionTimestamp),
            "Session should expire after timeout"
        );
    }

    /**
     * @dev Test address to string conversion for JSON formatting
     */
    function testAddressStringConversion() public {
        address testAddress = 0x742d35Cc6874C41532Da6B3Bc1234567890AbCdE;
        string memory addressString = LitProtocolLib.addressToString(testAddress);
        
        // Should be lowercase hex with 0x prefix
        assertEq(
            addressString,
            "0x742d35cc6874c41532da6b3bc1234567890abcde",
            "Address should be lowercase hex"
        );
        
        // Test zero address
        string memory zeroString = LitProtocolLib.addressToString(address(0));
        assertEq(
            zeroString,
            "0x0000000000000000000000000000000000000000",
            "Zero address should be formatted correctly"
        );
    }

    /**
     * @dev Test uint256 to string conversion
     */
    function testUintStringConversion() public {
        // Test zero conversion
        assertEq(LitProtocolLib.uintToString(0), "0", "Zero should convert to '0'");
        
        // Test small numbers
        assertEq(LitProtocolLib.uintToString(42), "42", "Small number conversion");
        assertEq(LitProtocolLib.uintToString(999), "999", "Three digit number");
        
        // Test large numbers
        assertEq(
            LitProtocolLib.uintToString(1000000000000000000), // 1 ether in wei
            "1000000000000000000",
            "Large number conversion"
        );
        
        // Test edge case
        assertEq(
            LitProtocolLib.uintToString(type(uint256).max),
            "115792089237316195423570985008687907853269984665640564039457584007913129639935",
            "Max uint256 conversion"
        );
    }

    /**
     * @dev Test complete encryption workflow simulation
     */
    function testCompleteEncryptionWorkflow() public {
        uint256 auctionRound = 1;
        bytes32 sessionKey = LitProtocolLib.generateSessionKeyHash(
            TEST_POOL_ID,
            auctionRound,
            block.timestamp
        );
        
        // Create access control conditions
        bytes memory conditions = LitProtocolLib.createBidConditions(
            bidder,
            MIN_BID_AMOUNT,
            block.timestamp + 1 hours
        );
        
        // Validate MPC parameters
        uint256 threshold = 2;
        uint256 totalNodes = 3;
        assertTrue(
            LitProtocolLib.validateMPCParams(threshold, totalNodes),
            "MPC parameters should be valid"
        );
        
        // Create encryption params structure
        LitProtocolLib.EncryptionParams memory params = LitProtocolLib.EncryptionParams({
            sessionKey: sessionKey,
            accessControlConditions: conditions,
            encryptedSymmetricKey: "mock_encrypted_symmetric_key",
            timestamp: block.timestamp,
            mpcThreshold: threshold
        });
        
        // Verify all components are properly set
        assertEq(params.sessionKey, sessionKey, "Session key should match");
        assertEq(params.accessControlConditions, conditions, "Conditions should match");
        assertEq(params.timestamp, block.timestamp, "Timestamp should match");
        assertEq(params.mpcThreshold, threshold, "Threshold should match");
        
        // Verify session is valid
        assertTrue(
            LitProtocolLib.isSessionValid(params.timestamp),
            "Encryption session should be valid"
        );
    }

    /**
     * @dev Test error cases for invalid encryption parameters
     */
    function testEncryptionErrorCases() public {
        // Test invalid MPC threshold error
        vm.expectRevert(LitProtocolLib.InvalidMPCThreshold.selector);
        litHook.validateEncryptionParams(0, 3, block.timestamp);
        
        // Test session expiry error  
        uint256 expiredTimestamp = block.timestamp - LitProtocolLib.SESSION_KEY_EXPIRY - 1;
        vm.expectRevert(LitProtocolLib.SessionKeyExpired.selector);
        litHook.validateEncryptionParams(2, 3, expiredTimestamp);
    }
}