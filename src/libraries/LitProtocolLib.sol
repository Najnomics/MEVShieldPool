// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title LitProtocolLib
 * @dev Library for Lit Protocol MPC/TSS encryption utilities
 * @notice Provides helper functions for encrypted bid management and access control
 * @author MEVShield Pool Team
 */
library LitProtocolLib {
    /**
     * @dev Structure defining access control conditions for Lit Protocol
     * @param contractAddress The contract address to check
     * @param standardContractType Type of contract (ERC20, ERC721, etc.)
     * @param chain The blockchain network identifier
     * @param method The contract method to call for verification
     * @param parameters Parameters to pass to the method
     * @param returnValueTest Test to apply to the return value
     */
    struct AccessControlCondition {
        string contractAddress;
        string standardContractType;
        string chain;
        string method;
        string parameters;
        string returnValueTest;
    }
    
    /**
     * @dev Structure containing encryption parameters for a session
     * @param sessionKey The session key used for encryption
     * @param accessControlConditions Encoded access control conditions
     * @param encryptedSymmetricKey The encrypted symmetric key
     * @param timestamp When the encryption session was created
     * @param mpcThreshold Number of MPC nodes required for decryption
     */
    struct EncryptionParams {
        bytes32 sessionKey;
        bytes accessControlConditions;
        bytes encryptedSymmetricKey;
        uint256 timestamp;
        uint256 mpcThreshold;
    }
    
    /**
     * @dev Constants for MPC threshold cryptography
     */
    uint256 public constant DEFAULT_MPC_THRESHOLD = 2;
    uint256 public constant DEFAULT_MPC_NODES = 3;
    uint256 public constant MAX_MPC_NODES = 100;
    uint256 public constant SESSION_KEY_EXPIRY = 1 hours;
    
    /**
     * @dev Errors for access control and encryption validation
     */
    error InvalidMPCThreshold();
    error SessionKeyExpired();
    error AccessConditionNotMet();
    error InvalidEncryptionParams();
    
    /**
     * @dev Creates access control conditions for encrypted bid submission
     * @param bidder The address submitting the bid
     * @param minBidAmount Minimum bid amount required
     * @param auctionDeadline Deadline for the auction
     * @return conditions Encoded access control conditions
     */
    function createBidConditions(
        address bidder,
        uint256 minBidAmount,
        uint256 auctionDeadline
    ) internal view returns (bytes memory conditions) {
        AccessControlCondition[] memory accessConditions = new AccessControlCondition[](2);
        
        // Condition 1: Bidder must have sufficient balance
        accessConditions[0] = AccessControlCondition({
            contractAddress: "0x0000000000000000000000000000000000000000", // ETH balance
            standardContractType: "",
            chain: "ethereum",
            method: "eth_getBalance",
            parameters: string(abi.encodePacked('["', addressToString(bidder), '", "latest"]')),
            returnValueTest: string(abi.encodePacked('{"comparator": ">=", "value": "', uintToString(minBidAmount), '"}'))
        });
        
        // Condition 2: Current time must be before auction deadline
        accessConditions[1] = AccessControlCondition({
            contractAddress: "0x0000000000000000000000000000000000000000",
            standardContractType: "",
            chain: "ethereum", 
            method: "eth_blockNumber",
            parameters: "[]",
            returnValueTest: string(abi.encodePacked('{"comparator": "<=", "value": "', uintToString(auctionDeadline), '"}'))
        });
        
        return abi.encode(accessConditions);
    }
    
    /**
     * @dev Validates MPC threshold parameters
     * @param threshold Number of nodes required for decryption
     * @param totalNodes Total number of MPC nodes
     * @return valid Whether the parameters are valid
     */
    function validateMPCParams(
        uint256 threshold,
        uint256 totalNodes
    ) internal pure returns (bool valid) {
        return threshold > 0 && 
               threshold <= totalNodes && 
               totalNodes <= MAX_MPC_NODES &&
               threshold * 2 > totalNodes; // Ensure true majority threshold
    }
    
    /**
     * @dev Generates a session key hash for encryption
     * @param poolId The pool identifier
     * @param auctionRound The current auction round
     * @param timestamp Current block timestamp
     * @return sessionKeyHash The generated session key hash
     */
    function generateSessionKeyHash(
        bytes32 poolId,
        uint256 auctionRound,
        uint256 timestamp
    ) internal view returns (bytes32 sessionKeyHash) {
        return keccak256(abi.encodePacked(
            poolId,
            auctionRound,
            timestamp,
            block.prevrandao,
            msg.sender
        ));
    }
    
    /**
     * @dev Validates that a session key is still valid
     * @param sessionTimestamp When the session was created
     * @return valid Whether the session is still valid
     */
    function isSessionValid(uint256 sessionTimestamp) internal view returns (bool valid) {
        return block.timestamp <= sessionTimestamp + SESSION_KEY_EXPIRY;
    }
    
    /**
     * @dev Converts address to string for JSON formatting
     * @param addr The address to convert
     * @return str String representation of the address
     */
    function addressToString(address addr) internal pure returns (string memory str) {
        bytes memory data = abi.encodePacked(addr);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory result = new bytes(2 + data.length * 2);
        result[0] = "0";
        result[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            result[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            result[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(result);
    }
    
    /**
     * @dev Converts uint256 to string
     * @param value The uint256 value to convert
     * @return str String representation of the value
     */
    function uintToString(uint256 value) internal pure returns (string memory str) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}