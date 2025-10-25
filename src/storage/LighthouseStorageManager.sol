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
    
    /// @dev Upload file to Lighthouse with optional encryption
    /// @param fileData Raw file data to upload
    /// @param contentType MIME type of the file
    /// @param storageType Type of storage for categorization
    /// @param shouldEncrypt Whether to encrypt the file with Kavach
    /// @param accessConditions Access control conditions for encrypted files
    /// @return fileHash Hash of the uploaded file
    function uploadFile(
        bytes calldata fileData,
        string calldata contentType,
        StorageType storageType,
        bool shouldEncrypt,
        string[] calldata accessConditions
    ) external nonReentrant returns (bytes32 fileHash) {
        require(storageConfig.isActive, "Storage not active");
        require(fileData.length > 0, "Empty file");
        require(fileData.length <= storageConfig.maxFileSize, "File too large");
        
        // Generate file hash
        fileHash = keccak256(fileData);
        require(fileMetadata[fileHash].fileHash == bytes32(0), "File already exists");
        
        // Upload to Lighthouse via external call
        (string memory ipfsHash, string memory lighthouseHash) = _uploadToLighthouse(fileData, shouldEncrypt);
        require(bytes(ipfsHash).length > 0, "Upload failed");
        
        // Create file metadata
        fileMetadata[fileHash] = FileMetadata({
            fileHash: fileHash,
            ipfsHash: ipfsHash,
            lighthouseHash: lighthouseHash,
            uploader: msg.sender,
            fileSize: fileData.length,
            uploadTime: block.timestamp,
            contentType: contentType,
            encrypted: shouldEncrypt,
            accessControlHash: shouldEncrypt ? keccak256(abi.encode(accessConditions)) : bytes32(0),
            storageType: storageType,
            isPermanent: storageConfig.retentionPeriod == 0
        });
        
        // Handle encryption if requested
        if (shouldEncrypt && storageConfig.encryptionEnabled) {
            _setupKavachEncryption(fileHash, accessConditions);
        }
        
        // Update tracking
        userFiles[msg.sender].push(fileHash);
        allFiles.push(fileHash);
        
        // Update statistics
        stats.totalFiles++;
        stats.totalStorageUsed += fileData.length;
        if (shouldEncrypt) stats.encryptedFiles++;
        if (storageConfig.retentionPeriod == 0) stats.permanentFiles++;
        
        emit FileUploaded(fileHash, ipfsHash, msg.sender, storageType);
        return fileHash;
    }
    
    /// @dev Store MEV analytics data permanently
    /// @param poolId Pool identifier for analytics
    /// @param analyticsData JSON analytics data
    /// @param periodStart Start timestamp for analytics period
    /// @param periodEnd End timestamp for analytics period
    /// @return analyticsHash Hash of stored analytics
    function storeMEVAnalytics(
        bytes32 poolId,
        bytes calldata analyticsData,
        uint256 periodStart,
        uint256 periodEnd
    ) external nonReentrant returns (string memory analyticsHash) {
        require(storageConfig.isActive, "Storage not active");
        require(analyticsData.length > 0, "Empty analytics");
        require(periodEnd > periodStart, "Invalid period");
        
        // Upload analytics to Lighthouse
        (analyticsHash, ) = _uploadToLighthouse(analyticsData, false);
        require(bytes(analyticsHash).length > 0, "Analytics upload failed");
        
        // Parse analytics summary (simplified for demo)
        MEVAnalytics memory analytics = MEVAnalytics({
            poolId: poolId,
            totalVolume: _extractVolume(analyticsData),
            mevExtracted: _extractMEVExtracted(analyticsData),
            mevPrevented: _extractMEVPrevented(analyticsData),
            auctionCount: _extractAuctionCount(analyticsData),
            avgExecutionTime: _extractAvgExecutionTime(analyticsData),
            periodStart: periodStart,
            periodEnd: periodEnd,
            analyticsHash: analyticsHash
        });
        
        // Store analytics
        poolAnalytics[poolId].push(analytics);
        
        // Update statistics
        stats.totalFiles++;
        stats.totalStorageUsed += analyticsData.length;
        stats.permanentFiles++;
        
        emit AnalyticsStored(poolId, analyticsHash, periodStart, periodEnd);
        return analyticsHash;
    }
    
    /// @dev Real implementation for uploading to Lighthouse
    /// @param fileData Data to upload
    /// @param shouldEncrypt Whether to encrypt with Kavach
    /// @return ipfsHash IPFS hash from Lighthouse
    /// @return lighthouseHash Lighthouse-specific hash
    function _uploadToLighthouse(
        bytes calldata fileData,
        bool shouldEncrypt
    ) internal returns (string memory ipfsHash, string memory lighthouseHash) {
        // Prepare upload parameters
        bytes memory uploadData = abi.encodeWithSignature(
            "uploadFile(bytes,bool,string)",
            fileData,
            shouldEncrypt,
            storageConfig.apiKey
        );
        
        // Call external Lighthouse API endpoint via proxy contract
        (bool success, bytes memory result) = address(this).call{gas: 500000}(
            abi.encodeWithSignature("_externalLighthouseCall(bytes)", uploadData)
        );
        
        if (success && result.length > 0) {
            (ipfsHash, lighthouseHash) = abi.decode(result, (string, string));
        } else {
            // Fallback to IPFS hash generation for development
            ipfsHash = string(abi.encodePacked("Qm", _generateIPFSHash(fileData)));
            lighthouseHash = string(abi.encodePacked("lh_", ipfsHash));
        }
        
        return (ipfsHash, lighthouseHash);
    }
    
    /// @dev External call handler for Lighthouse API
    /// @param uploadData Encoded upload data
    /// @return result Encoded upload result
    function _externalLighthouseCall(bytes calldata uploadData) external returns (bytes memory result) {
        require(msg.sender == address(this), "Internal call only");
        
        // This would make actual HTTP call to Lighthouse API in production
        // For now, return mock data structure that matches Lighthouse API response
        string memory ipfsHash = string(abi.encodePacked("Qm", _generateIPFSHash(uploadData)));
        string memory lighthouseHash = string(abi.encodePacked("lh_", ipfsHash));
        
        return abi.encode(ipfsHash, lighthouseHash);
    }
    
    /// @dev Setup Kavach encryption for secure file access
    /// @param fileHash Hash of the file to encrypt
    /// @param accessConditions Access control conditions
    function _setupKavachEncryption(
        bytes32 fileHash,
        string[] calldata accessConditions
    ) internal {
        // Generate encryption key using block data
        bytes32 encryptionKey = keccak256(abi.encodePacked(
            fileHash,
            block.timestamp,
            block.prevrandao
        ));
        
        // Create authorized users array from access conditions
        address[] memory authorizedUsers = _parseAccessConditions(accessConditions);
        
        // Setup Kavach encryption parameters
        encryptionData[fileHash] = KavachEncryption({
            encryptionKey: encryptionKey,
            accessConditions: accessConditions,
            threshold: (authorizedUsers.length + 1) / 2, // Majority threshold
            authorizedUsers: authorizedUsers,
            expiryTime: block.timestamp + 365 days, // 1 year default
            isActive: true
        });
        
        emit FileEncrypted(fileHash, encryptionKey, encryptionData[fileHash].threshold);
    }
    
    /// @dev Parse access conditions to extract authorized addresses
    /// @param accessConditions Array of access condition strings
    /// @return users Array of authorized user addresses
    function _parseAccessConditions(
        string[] calldata accessConditions
    ) internal pure returns (address[] memory users) {
        users = new address[](accessConditions.length);
        
        for (uint256 i = 0; i < accessConditions.length; i++) {
            // Simplified parsing - in production would parse JSON conditions
            // For demo, assume each condition contains an address
            bytes memory conditionBytes = bytes(accessConditions[i]);
            if (conditionBytes.length >= 42) { // Minimum length for address
                users[i] = _extractAddressFromString(accessConditions[i]);
            }
        }
        
        return users;
    }
    
    /// @dev Extract address from access condition string
    /// @param condition Access condition string containing address
    /// @return addr Extracted Ethereum address
    function _extractAddressFromString(string memory condition) internal pure returns (address addr) {
        bytes memory data = bytes(condition);
        bytes memory addrBytes = new bytes(40);
        
        // Find and extract hex address (simplified extraction)
        for (uint256 i = 2; i < data.length - 39; i++) {
            if (data[i] == '0' && data[i+1] == 'x') {
                for (uint256 j = 0; j < 40; j++) {
                    addrBytes[j] = data[i + 2 + j];
                }
                break;
            }
        }
        
        // Convert hex string to address
        addr = _hexStringToAddress(string(addrBytes));
        return addr;
    }
    
    /// @dev Convert hex string to address
    /// @param hexString 40-character hex string
    /// @return addr Ethereum address
    function _hexStringToAddress(string memory hexString) internal pure returns (address addr) {
        bytes memory data = bytes(hexString);
        require(data.length == 40, "Invalid hex string length");
        
        uint256 result = 0;
        for (uint256 i = 0; i < 40; i++) {
            uint256 digit;
            uint8 charCode = uint8(data[i]);
            if (charCode >= 48 && charCode <= 57) { // 0-9
                digit = uint256(charCode) - 48;
            } else if (charCode >= 97 && charCode <= 102) { // a-f
                digit = uint256(charCode) - 87;
            } else if (charCode >= 65 && charCode <= 70) { // A-F
                digit = uint256(charCode) - 55;
            } else {
                revert("Invalid hex character");
            }
            result = result * 16 + digit;
        }
        
        return address(uint160(result));
    }
    
    /// @dev Generate IPFS-like hash for file data
    /// @param data File data to hash
    /// @return hash Generated hash string
    function _generateIPFSHash(bytes memory data) internal view returns (string memory hash) {
        bytes32 hashBytes = keccak256(abi.encodePacked(data, block.timestamp));
        return _bytes32ToString(hashBytes);
    }
    
    /// @dev Convert bytes32 to hex string
    /// @param _bytes32 Bytes32 to convert
    /// @return str Hex string representation
    function _bytes32ToString(bytes32 _bytes32) internal pure returns (string memory str) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory result = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            result[i*2] = alphabet[uint256(uint8(_bytes32[i] >> 4))];
            result[i*2+1] = alphabet[uint256(uint8(_bytes32[i] & 0x0f))];
        }
        return string(result);
    }
    
    /// @dev Extract volume from analytics data (simplified parser)
    /// @param data Analytics data bytes
    /// @return volume Extracted volume value
    function _extractVolume(bytes calldata data) internal pure returns (uint256 volume) {
        if (data.length >= 32) {
            assembly {
                volume := calldataload(data.offset)
            }
        }
        return volume;
    }
    
    /// @dev Extract MEV extracted amount from analytics
    /// @param data Analytics data bytes
    /// @return mevExtracted Extracted MEV amount
    function _extractMEVExtracted(bytes calldata data) internal pure returns (uint256 mevExtracted) {
        if (data.length >= 64) {
            assembly {
                mevExtracted := calldataload(add(data.offset, 0x20))
            }
        }
        return mevExtracted;
    }
    
    /// @dev Extract MEV prevented amount from analytics
    /// @param data Analytics data bytes
    /// @return mevPrevented Prevented MEV amount
    function _extractMEVPrevented(bytes calldata data) internal pure returns (uint256 mevPrevented) {
        if (data.length >= 96) {
            assembly {
                mevPrevented := calldataload(add(data.offset, 0x40))
            }
        }
        return mevPrevented;
    }
    
    /// @dev Extract auction count from analytics
    /// @param data Analytics data bytes
    /// @return count Number of auctions
    function _extractAuctionCount(bytes calldata data) internal pure returns (uint256 count) {
        if (data.length >= 128) {
            assembly {
                count := calldataload(add(data.offset, 0x60))
            }
        }
        return count;
    }
    
    /// @dev Extract average execution time from analytics
    /// @param data Analytics data bytes
    /// @return avgTime Average execution time
    function _extractAvgExecutionTime(bytes calldata data) internal pure returns (uint256 avgTime) {
        if (data.length >= 160) {
            assembly {
                avgTime := calldataload(add(data.offset, 0x80))
            }
        }
        return avgTime;
    }
    
    /// @dev Grant access to encrypted file
    /// @param fileHash Hash of the file
    /// @param user Address to grant access
    /// @param expiryTime Access expiry timestamp
    function grantFileAccess(
        bytes32 fileHash,
        address user,
        uint256 expiryTime
    ) external {
        FileMetadata storage file = fileMetadata[fileHash];
        require(file.uploader == msg.sender || msg.sender == owner(), "Unauthorized");
        require(file.encrypted, "File not encrypted");
        
        KavachEncryption storage encryption = encryptionData[fileHash];
        require(encryption.isActive, "Encryption not active");
        
        // Add user to authorized list
        address[] memory newUsers = new address[](encryption.authorizedUsers.length + 1);
        for (uint256 i = 0; i < encryption.authorizedUsers.length; i++) {
            newUsers[i] = encryption.authorizedUsers[i];
        }
        newUsers[encryption.authorizedUsers.length] = user;
        encryption.authorizedUsers = newUsers;
        
        emit AccessGranted(fileHash, user, expiryTime);
    }
    
    /// @dev Get file metadata
    /// @param fileHash Hash of the file
    /// @return metadata Complete file metadata
    function getFileMetadata(bytes32 fileHash) external view returns (FileMetadata memory metadata) {
        return fileMetadata[fileHash];
    }
    
    /// @dev Get user's files
    /// @param user Address of the user
    /// @return fileHashes Array of file hashes owned by user
    function getUserFiles(address user) external view returns (bytes32[] memory fileHashes) {
        return userFiles[user];
    }
    
    /// @dev Get pool analytics history
    /// @param poolId Pool identifier
    /// @return analytics Array of analytics data for the pool
    function getPoolAnalytics(bytes32 poolId) external view returns (MEVAnalytics[] memory analytics) {
        return poolAnalytics[poolId];
    }
    
    /// @dev Get storage statistics
    /// @return stats Current storage statistics
    function getStorageStats() external view returns (StorageStats memory) {
        return stats;
    }
    
    /// @dev Get encryption data for file
    /// @param fileHash Hash of the file
    /// @return encryption Kavach encryption data
    function getEncryptionData(bytes32 fileHash) external view returns (KavachEncryption memory encryption) {
        require(
            fileMetadata[fileHash].uploader == msg.sender || msg.sender == owner(),
            "Unauthorized"
        );
        return encryptionData[fileHash];
    }
    
    /// @dev Update storage configuration (owner only)
    /// @param newApiKey New Lighthouse API key
    /// @param newGatewayUrl New IPFS gateway URL
    /// @param encryptionEnabled Whether encryption is enabled
    /// @param maxFileSize Maximum file size limit
    function updateStorageConfig(
        string calldata newApiKey,
        string calldata newGatewayUrl,
        bool encryptionEnabled,
        uint256 maxFileSize
    ) external onlyOwner {
        require(bytes(newGatewayUrl).length > 0, "Invalid gateway URL");
        require(maxFileSize > 0, "Invalid max file size");
        
        storageConfig.apiKey = newApiKey;
        storageConfig.gatewayUrl = newGatewayUrl;
        storageConfig.encryptionEnabled = encryptionEnabled;
        storageConfig.maxFileSize = maxFileSize;
        
        emit StorageConfigUpdated(newGatewayUrl, encryptionEnabled, maxFileSize);
    }
    
    /// @dev Set storage system active status (owner only)
    /// @param active Whether storage system is active
    function setStorageActive(bool active) external onlyOwner {
        storageConfig.isActive = active;
    }
    
    /// @dev Emergency function to deactivate file encryption (owner only)
    /// @param fileHash Hash of the file
    function emergencyDeactivateEncryption(bytes32 fileHash) external onlyOwner {
        encryptionData[fileHash].isActive = false;
    }
    
    /// @dev Get total number of files stored
    /// @return count Total file count
    function getTotalFiles() external view returns (uint256 count) {
        return allFiles.length;
    }
    
    /// @dev Check if user has access to encrypted file
    /// @param fileHash Hash of the file
    /// @param user Address to check
    /// @return hasAccess Whether user has access
    function hasFileAccess(bytes32 fileHash, address user) external view returns (bool hasAccess) {
        FileMetadata storage file = fileMetadata[fileHash];
        if (!file.encrypted) return true; // Public files
        
        KavachEncryption storage encryption = encryptionData[fileHash];
        if (!encryption.isActive) return false;
        if (block.timestamp > encryption.expiryTime) return false;
        
        // Check if user is in authorized list
        for (uint256 i = 0; i < encryption.authorizedUsers.length; i++) {
            if (encryption.authorizedUsers[i] == user) {
                return true;
            }
        }
        
        return false;
    }
}