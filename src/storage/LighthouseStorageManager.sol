// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title LighthouseStorageManager
 * @dev Decentralized storage manager using Lighthouse protocol for MEV auction data
 * @notice Handles permanent storage of auction data, analytics, and MEV protection logs
 * @author MEVShield Pool Team
 */
contract LighthouseStorageManager is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    
    /// @dev Lighthouse storage configuration
    struct StorageConfig {
        string apiKey; // Lighthouse API key (encrypted)
        string gatewayUrl; // IPFS gateway URL
        bool encryptionEnabled; // Kavach encryption enabled
        uint256 maxFileSize; // Maximum file size in bytes
        uint256 retentionPeriod; // Data retention period (0 = forever)
        bool isActive; // Storage system active status
    }
    
    /// @dev Stored file metadata
    struct FileMetadata {
        bytes32 fileHash;
        string ipfsHash;
        string lighthouseHash;
        address uploader;
        uint256 fileSize;
        uint256 uploadTime;
        string contentType;
        bool encrypted;
        bytes32 accessControlHash;
        StorageType storageType;
        bool isPermanent;
    }
    
    /// @dev Storage type enumeration
    enum StorageType {
        AUCTION_DATA,
        MEV_ANALYTICS,
        PRICE_HISTORY,
        AUDIT_LOGS,
        USER_DATA,
        SYSTEM_BACKUP
    }
    
    /// @dev Kavach encryption parameters for secure storage
    struct KavachEncryption {
        bytes32 encryptionKey;
        string[] accessConditions;
        uint256 threshold;
        address[] authorizedUsers;
        uint256 expiryTime;
        bool isActive;
    }
    
    /// @dev Data analytics structure for MEV insights
    struct MEVAnalytics {
        bytes32 poolId;
        uint256 totalVolume;
        uint256 mevExtracted;
        uint256 mevPrevented;
        uint256 auctionCount;
        uint256 avgExecutionTime;
        uint256 periodStart;
        uint256 periodEnd;
        string analyticsHash; // IPFS hash of detailed analytics
    }
    
    /// @dev Storage configuration
    StorageConfig public storageConfig;
    
    /// @dev Mapping from file hash to metadata
    mapping(bytes32 => FileMetadata) public fileMetadata;
    
    /// @dev Mapping from uploader to their files
    mapping(address => bytes32[]) public userFiles;
    
    /// @dev Mapping for Kavach encryption data
    mapping(bytes32 => KavachEncryption) public encryptionData;
    
    /// @dev Mapping from pool ID to analytics data
    mapping(bytes32 => MEVAnalytics[]) public poolAnalytics;
    
    /// @dev Array of all file hashes for enumeration
    bytes32[] public allFiles;
    
    /// @dev Storage statistics
    struct StorageStats {
        uint256 totalFiles;
        uint256 totalStorageUsed;
        uint256 encryptedFiles;
        uint256 permanentFiles;
        uint256 totalCost;
        uint256 avgUploadTime;
    }
    
    StorageStats public stats;
    
    /// @dev Events for storage operations
    event FileUploaded(
        bytes32 indexed fileHash,
        string ipfsHash,
        address indexed uploader,
        StorageType storageType
    );
    
    event FileEncrypted(
        bytes32 indexed fileHash,
        bytes32 encryptionKey,
        uint256 threshold
    );
    
    event AnalyticsStored(
        bytes32 indexed poolId,
        string analyticsHash,
        uint256 periodStart,
        uint256 periodEnd
    );
    
    event AccessGranted(
        bytes32 indexed fileHash,
        address indexed user,
        uint256 expiryTime
    );
    
    event StorageConfigUpdated(
        string gatewayUrl,
        bool encryptionEnabled,
        uint256 maxFileSize
    );
    
    /// @dev Constructor initializes Lighthouse storage
    /// @param _initialOwner Address that will own this contract
    constructor(address _initialOwner) Ownable(_initialOwner) {
        // Initialize default storage configuration
        storageConfig = StorageConfig({
            apiKey: "", // To be set by owner
            gatewayUrl: "https://gateway.lighthouse.storage/ipfs/",
            encryptionEnabled: true,
            maxFileSize: 100 * 1024 * 1024, // 100MB default
            retentionPeriod: 0, // Permanent storage
            isActive: true
        });
        
        // Initialize statistics
        stats = StorageStats({
            totalFiles: 0,
            totalStorageUsed: 0,
            encryptedFiles: 0,
            permanentFiles: 0,
            totalCost: 0,
            avgUploadTime: 0
        });
    }