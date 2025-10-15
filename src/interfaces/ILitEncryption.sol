// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ILitEncryption
 * @dev Interface for Lit Protocol MPC/TSS encryption integration
 * @notice Provides encrypted bid submission using threshold cryptography
 * @author MEVShield Pool Team
 */
interface ILitEncryption {
    /**
     * @dev Structure representing an encrypted bid submission
     * @param encryptedAmount The bid amount encrypted using Lit Protocol
     * @param accessControlConditions Conditions required for decryption
     * @param sessionKeyHash Hash of the session key used for encryption
     * @param timestamp Block timestamp when the bid was encrypted
     * @param bidder Address of the account that submitted the bid
     */
    struct EncryptedBid {
        bytes encryptedAmount;
        bytes accessControlConditions;
        bytes32 sessionKeyHash;
        uint256 timestamp;
        address bidder;
    }
    
    /**
     * @dev Structure for MPC threshold signature parameters
     * @param threshold Minimum number of nodes required for decryption
     * @param totalNodes Total number of nodes in the MPC network
     * @param sessionKey Encrypted session key for this auction round
     */
    struct MPCParams {
        uint256 threshold;
        uint256 totalNodes;
        bytes encryptedSessionKey;
    }
    
    /**
     * @dev Emitted when a bid is successfully encrypted
     * @param poolId The pool where the bid was submitted
     * @param bidder Address that submitted the encrypted bid
     * @param encryptedData The encrypted bid data
     * @param sessionKeyHash Hash of the session key used
     */
    event BidEncrypted(
        bytes32 indexed poolId,
        address indexed bidder,
        bytes encryptedData,
        bytes32 sessionKeyHash
    );
    
    /**
     * @dev Emitted when a bid is successfully decrypted
     * @param poolId The pool where the bid was decrypted
     * @param bidder Address that submitted the original bid
     * @param amount The decrypted bid amount
     * @param winner Whether this bid won the auction
     */
    event BidDecrypted(
        bytes32 indexed poolId,
        address indexed bidder,
        uint256 amount,
        bool winner
    );
    
    /**
     * @dev Emitted when MPC parameters are updated for a pool
     * @param poolId The pool that had its parameters updated
     * @param threshold New threshold for decryption
     * @param totalNodes New total number of MPC nodes
     */
    event MPCParamsUpdated(
        bytes32 indexed poolId,
        uint256 threshold,
        uint256 totalNodes
    );
    
    /**
     * @dev Encrypts a bid using Lit Protocol MPC/TSS
     * @param poolId The pool where the bid is being submitted
     * @param amount The bid amount to encrypt
     * @param accessConditions Access control conditions for decryption
     * @return encryptedData The encrypted bid data
     */
    function encryptBid(
        bytes32 poolId,
        uint256 amount,
        bytes calldata accessConditions
    ) external returns (bytes memory encryptedData);
    
    /**
     * @dev Decrypts winning bids using threshold signatures
     * @param poolId The pool where auction ended
     * @param encryptedBids Array of encrypted bids to decrypt
     * @param signatures Threshold signatures from MPC network
     * @return decryptedAmounts Array of decrypted bid amounts
     */
    function decryptWinningBids(
        bytes32 poolId,
        EncryptedBid[] calldata encryptedBids,
        bytes[] calldata signatures
    ) external returns (uint256[] memory decryptedAmounts);
    
    /**
     * @dev Updates MPC parameters for a specific pool
     * @param poolId The pool to update parameters for
     * @param newThreshold New threshold for MPC decryption
     * @param newTotalNodes New total number of MPC nodes
     */
    function updateMPCParams(
        bytes32 poolId,
        uint256 newThreshold,
        uint256 newTotalNodes
    ) external;
    
    /**
     * @dev Retrieves MPC parameters for a pool
     * @param poolId The pool to get parameters for
     * @return params The MPC parameters for the pool
     */
    function getMPCParams(bytes32 poolId) external view returns (MPCParams memory params);
    
    /**
     * @dev Validates that access control conditions are met
     * @param bidder Address of the bidder
     * @param conditions Access control conditions to validate
     * @return valid Whether the conditions are satisfied
     */
    function validateAccessConditions(
        address bidder,
        bytes calldata conditions
    ) external view returns (bool valid);
}