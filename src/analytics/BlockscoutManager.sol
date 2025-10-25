// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title BlockscoutManager
 * @dev Comprehensive Blockscout integration with Autoscout deployment and MCP server
 * @notice Manages blockchain analytics, custom explorer deployment, and AI-powered insights
 * @author MEVShield Pool Team
 */
contract BlockscoutManager is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    
    /// @dev Autoscout deployment configuration
    struct AutoscoutConfig {
        string explorerName;
        string chainName;
        uint256 chainId;
        string rpcUrl;
        string currency;
        bool isTestnet;
        string logoUrl;
        string brandColor;
        address deployerAddress;
        uint256 deploymentTime;
        AutoscoutStatus status;
    }
    
    /// @dev Autoscout deployment status
    enum AutoscoutStatus {
        PENDING,
        DEPLOYING,
        ACTIVE,
        UPDATING,
        FAILED,
        SUSPENDED
    }
    
    /// @dev MCP server configuration for AI integration
    struct MCPServerConfig {
        string serverEndpoint;
        string apiKey;
        bool aiAnalyticsEnabled;
        bool smartResponseSlicing;
        uint256 maxPageSize;
        bool contextOptimization;
        uint256 cacheTimeout;
        bool isActive;
    }
    
    /// @dev Blockchain analytics data structure
    struct BlockchainAnalytics {
        uint256 totalTransactions;
        uint256 totalBlocks;
        uint256 totalAddresses;
        uint256 averageBlockTime;
        uint256 networkHashrate;
        uint256 totalValueLocked;
        uint256 mevMetrics;
        uint256 lastUpdated;
        string analyticsHash; // IPFS hash for detailed data
    }
    
    /// @dev Custom analytics query structure
    struct AnalyticsQuery {
        bytes32 queryId;
        address requester;
        string queryType; // "whale_trades", "mev_analysis", "token_flows", etc.
        bytes queryParams;
        uint256 requestTime;
        uint256 responseTime;
        string responseHash; // IPFS hash of response data
        QueryStatus status;
        uint256 processingFee;
    }
    
    /// @dev Analytics query status
    enum QueryStatus {
        SUBMITTED,
        PROCESSING,
        COMPLETED,
        FAILED,
        EXPIRED
    }
    
    /// @dev MEV-specific analytics structure
    struct MEVInsights {
        bytes32 poolId;
        uint256 mevExtracted;
        uint256 mevPrevented;
        uint256 arbitrageOpportunities;
        uint256 sandwichAttacks;
        uint256 liquidationEvents;
        uint256 frontRunningDetected;
        uint256 periodStart;
        uint256 periodEnd;
        string detailedReportHash;
    }
    
    /// @dev Current Autoscout deployment configuration
    AutoscoutConfig public autoscoutConfig;
    
    /// @dev MCP server configuration for AI analytics
    MCPServerConfig public mcpConfig;
    
    /// @dev Latest blockchain analytics
    BlockchainAnalytics public latestAnalytics;
    
    /// @dev Mapping from query ID to analytics query
    mapping(bytes32 => AnalyticsQuery) public analyticsQueries;
    
    /// @dev Mapping from pool ID to MEV insights
    mapping(bytes32 => MEVInsights[]) public poolMEVInsights;
    
    /// @dev Array of all query IDs for enumeration
    bytes32[] public allQueries;
    
    /// @dev Supported analytics query types
    mapping(string => bool) public supportedQueryTypes;
    
    /// @dev Analytics processing fees in wei
    mapping(string => uint256) public queryTypeFees;
    
    /// @dev Statistics for Blockscout integration
    struct IntegrationStats {
        uint256 totalExplorersDeployed;
        uint256 totalAnalyticsQueries;
        uint256 totalMEVReports;
        uint256 averageQueryTime;
        uint256 totalFeesCollected;
        uint256 activeExplorers;
    }
    
    IntegrationStats public stats;
    
    /// @dev Events for Blockscout integration
    event AutoscoutDeploymentRequested(
        string indexed explorerName,
        uint256 indexed chainId,
        address indexed deployer
    );
    
    event AutoscoutDeploymentCompleted(
        string indexed explorerName,
        string explorerUrl,
        uint256 deploymentTime
    );
    
    event AnalyticsQuerySubmitted(
        bytes32 indexed queryId,
        address indexed requester,
        string queryType,
        uint256 fee
    );
    
    event AnalyticsQueryCompleted(
        bytes32 indexed queryId,
        string responseHash,
        uint256 processingTime
    );
    
    event MEVInsightsGenerated(
        bytes32 indexed poolId,
        uint256 mevExtracted,
        uint256 mevPrevented,
        string reportHash
    );
    
    event MCPServerConfigured(
        string serverEndpoint,
        bool aiAnalyticsEnabled,
        uint256 maxPageSize
    );
    
    /// @dev Constructor initializes Blockscout integration
    /// @param _initialOwner Address that will own this contract
    constructor(address _initialOwner) Ownable(_initialOwner) {
        // Initialize default MCP server configuration
        mcpConfig = MCPServerConfig({
            serverEndpoint: "https://mcp.blockscout.com/mcp",
            apiKey: "",
            aiAnalyticsEnabled: true,
            smartResponseSlicing: true,
            maxPageSize: 100,
            contextOptimization: true,
            cacheTimeout: 300, // 5 minutes
            isActive: false
        });
        
        // Initialize supported query types with fees
        supportedQueryTypes["whale_trades"] = true;
        supportedQueryTypes["mev_analysis"] = true;
        supportedQueryTypes["token_flows"] = true;
        supportedQueryTypes["contract_interactions"] = true;
        supportedQueryTypes["nft_analytics"] = true;
        supportedQueryTypes["defi_metrics"] = true;
        
        queryTypeFees["whale_trades"] = 0.001 ether;
        queryTypeFees["mev_analysis"] = 0.002 ether;
        queryTypeFees["token_flows"] = 0.001 ether;
        queryTypeFees["contract_interactions"] = 0.0005 ether;
        queryTypeFees["nft_analytics"] = 0.001 ether;
        queryTypeFees["defi_metrics"] = 0.0015 ether;
        
        // Initialize statistics
        stats = IntegrationStats({
            totalExplorersDeployed: 0,
            totalAnalyticsQueries: 0,
            totalMEVReports: 0,
            averageQueryTime: 0,
            totalFeesCollected: 0,
            activeExplorers: 0
        });
    }
    
    /// @dev Deploy custom blockchain explorer using Autoscout
    /// @param explorerName Name for the explorer
    /// @param chainName Name of the blockchain
    /// @param chainId Chain ID for the blockchain
    /// @param rpcUrl RPC endpoint URL
    /// @param currency Native currency symbol
    /// @param isTestnet Whether this is a testnet
    /// @param logoUrl URL for chain logo
    /// @param brandColor Hex color for branding
    /// @return deploymentId Unique identifier for the deployment
    function deployAutoscoutExplorer(
        string calldata explorerName,
        string calldata chainName,
        uint256 chainId,
        string calldata rpcUrl,
        string calldata currency,
        bool isTestnet,
        string calldata logoUrl,
        string calldata brandColor
    ) external nonReentrant returns (bytes32 deploymentId) {
        require(bytes(explorerName).length > 0, "Invalid explorer name");
        require(bytes(chainName).length > 0, "Invalid chain name");
        require(bytes(rpcUrl).length > 0, "Invalid RPC URL");
        require(chainId > 0, "Invalid chain ID");
        
        // Generate deployment ID (packed -> encode to reduce inline asm pressure)
        deploymentId = keccak256(abi.encode(
            explorerName,
            chainId,
            msg.sender,
            block.timestamp
        ));
        
        // Update Autoscout configuration - split initialization to avoid stack too deep
        autoscoutConfig.explorerName = explorerName;
        autoscoutConfig.chainName = chainName;
        autoscoutConfig.chainId = chainId;
        autoscoutConfig.rpcUrl = rpcUrl;
        autoscoutConfig.currency = currency;
        autoscoutConfig.isTestnet = isTestnet;
        autoscoutConfig.logoUrl = logoUrl;
        autoscoutConfig.brandColor = brandColor;
        autoscoutConfig.deployerAddress = msg.sender;
        autoscoutConfig.deploymentTime = block.timestamp;
        autoscoutConfig.status = AutoscoutStatus.PENDING;
        
        // Initiate deployment process
        _initiateAutoscoutDeployment();
        
        // Update statistics
        stats.totalExplorersDeployed++;
        
        // Emit event using cached values
        string memory cachedExplorerName = explorerName;
        uint256 cachedChainId = chainId;
        address cachedSender = msg.sender;
        emit AutoscoutDeploymentRequested(cachedExplorerName, cachedChainId, cachedSender);
        return deploymentId;
    }
    
    /// @dev Submit analytics query to Blockscout MCP server
    /// @param queryType Type of analytics query
    /// @param queryParams Encoded query parameters
    /// @return queryId Unique identifier for the query
    function submitAnalyticsQuery(
        string calldata queryType,
        bytes calldata queryParams
    ) external payable nonReentrant returns (bytes32 queryId) {
        require(supportedQueryTypes[queryType], "Unsupported query type");
        require(mcpConfig.isActive, "MCP server not active");
        
        uint256 requiredFee = queryTypeFees[queryType];
        require(msg.value >= requiredFee, "Insufficient fee");
        
        // Generate query ID
        queryId = keccak256(abi.encodePacked(
            queryType,
            queryParams,
            msg.sender,
            block.timestamp,
            allQueries.length
        ));
        
        // Create analytics query
        analyticsQueries[queryId] = AnalyticsQuery({
            queryId: queryId,
            requester: msg.sender,
            queryType: queryType,
            queryParams: queryParams,
            requestTime: block.timestamp,
            responseTime: 0,
            responseHash: "",
            status: QueryStatus.SUBMITTED,
            processingFee: requiredFee
        });
        
        // Add to tracking
        allQueries.push(queryId);
        
        // Process query through MCP server
        _processMCPQuery(queryId);
        
        // Update statistics
        stats.totalAnalyticsQueries++;
        stats.totalFeesCollected += requiredFee;
        
        // Refund excess payment
        if (msg.value > requiredFee) {
            payable(msg.sender).transfer(msg.value - requiredFee);
        }
        
        emit AnalyticsQuerySubmitted(queryId, msg.sender, queryType, requiredFee);
        return queryId;
    }
    
    /// @dev Generate MEV insights for a specific pool
    /// @param poolId Pool identifier
    /// @param periodStart Start timestamp for analysis
    /// @param periodEnd End timestamp for analysis
    /// @return insightHash Hash of generated insights
    function generateMEVInsights(
        bytes32 poolId,
        uint256 periodStart,
        uint256 periodEnd
    ) external returns (string memory insightHash) {
        require(periodEnd > periodStart, "Invalid period");
        require(mcpConfig.isActive, "MCP server not active");
        
        // Query MEV data through MCP server
        bytes memory mevQueryParams = abi.encode(poolId, periodStart, periodEnd);
        bytes32 queryId = keccak256(abi.encode(
            "mev_analysis",
            mevQueryParams,
            block.timestamp
        ));
        
        // Simulate MEV analysis (in production would call MCP server)
        MEVInsights memory insights = _analyzeMEVData(poolId, periodStart, periodEnd);
        
        // Store insights
        poolMEVInsights[poolId].push(insights);
        
        // Update statistics
        stats.totalMEVReports++;
        
        insightHash = insights.detailedReportHash;
        emit MEVInsightsGenerated(poolId, insights.mevExtracted, insights.mevPrevented, insightHash);
        
        return insightHash;
    }
    
    /// @dev Initiate Autoscout deployment process
    function _initiateAutoscoutDeployment() internal {
        autoscoutConfig.status = AutoscoutStatus.DEPLOYING;
        
        // In production, this would make HTTP call to Autoscout API
        // For now, simulate deployment completion after delay
        _completeAutoscoutDeployment();
    }
    
    /// @dev Complete Autoscout deployment
    function _completeAutoscoutDeployment() internal {
        autoscoutConfig.status = AutoscoutStatus.ACTIVE;
        stats.activeExplorers++;
        
        // Generate explorer URL
        string memory explorerUrl = string.concat(
            "https://",
            autoscoutConfig.explorerName,
            ".blockscout.com"
        );
        
        emit AutoscoutDeploymentCompleted(
            autoscoutConfig.explorerName,
            explorerUrl,
            block.timestamp - autoscoutConfig.deploymentTime
        );
    }
    
    /// @dev Process analytics query through MCP server
    /// @param queryId Query identifier to process
    function _processMCPQuery(bytes32 queryId) internal {
        AnalyticsQuery storage query = analyticsQueries[queryId];
        query.status = QueryStatus.PROCESSING;
        
        // Simulate MCP server processing
        // In production, would make actual HTTP call to MCP server
        string memory responseHash = _generateResponseHash(queryId);
        
        query.responseHash = responseHash;
        query.responseTime = block.timestamp;
        query.status = QueryStatus.COMPLETED;
        
        // Update average query time
        uint256 processingTime = block.timestamp - query.requestTime;
        _updateAverageQueryTime(processingTime);
        
        emit AnalyticsQueryCompleted(queryId, responseHash, processingTime);
    }
    
    /// @dev Analyze MEV data for insights generation
    /// @param poolId Pool identifier
    /// @param periodStart Analysis period start
    /// @param periodEnd Analysis period end
    /// @return insights Generated MEV insights
    function _analyzeMEVData(
        bytes32 poolId,
        uint256 periodStart,
        uint256 periodEnd
    ) internal view returns (MEVInsights memory insights) {
        // Simulate MEV analysis based on pool and time period
        uint256 periodDuration = periodEnd - periodStart;
        uint256 baseVolume = uint256(poolId) % 1000000; // Pseudo-random base
        
        insights = MEVInsights({
            poolId: poolId,
            mevExtracted: (baseVolume * periodDuration) / 86400, // Per day scaling
            mevPrevented: (baseVolume * periodDuration * 3) / 86400, // 3x prevented
            arbitrageOpportunities: (periodDuration / 3600) * 5, // 5 per hour
            sandwichAttacks: (periodDuration / 3600) * 2, // 2 per hour
            liquidationEvents: (periodDuration / 7200) * 1, // 1 per 2 hours
            frontRunningDetected: (periodDuration / 1800) * 3, // 3 per 30 min
            periodStart: periodStart,
            periodEnd: periodEnd,
            detailedReportHash: _generateReportHash(poolId, periodStart, periodEnd)
        });
        
        return insights;
    }
    
    /// @dev Generate response hash for analytics query
    /// @param queryId Query identifier
    /// @return hash Generated response hash
    function _generateResponseHash(bytes32 queryId) internal view returns (string memory hash) {
        bytes32 hashBytes = keccak256(abi.encode(
            queryId,
            block.timestamp,
            block.prevrandao
        ));
        return _bytes32ToHex(hashBytes);
    }
    
    /// @dev Generate report hash for MEV insights
    /// @param poolId Pool identifier
    /// @param periodStart Period start timestamp
    /// @param periodEnd Period end timestamp
    /// @return hash Generated report hash
    function _generateReportHash(
        bytes32 poolId,
        uint256 periodStart,
        uint256 periodEnd
    ) internal view returns (string memory hash) {
        bytes32 hashBytes = keccak256(abi.encode(
            poolId,
            periodStart,
            periodEnd,
            block.timestamp
        ));
        return string.concat("ipfs://", _bytes32ToHex(hashBytes));
    }
    
    /// @dev Convert bytes32 to hex string
    /// @param _bytes32 Bytes32 to convert
    /// @return hex Hex string representation
    function _bytes32ToHex(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(_bytes32[i] >> 4)];
            str[i*2+1] = alphabet[uint8(_bytes32[i] & 0x0f)];
        }
        return string(str);
    }
    
    /// @dev Update average query processing time
    /// @param processingTime Latest processing time
    function _updateAverageQueryTime(uint256 processingTime) internal {
        if (stats.averageQueryTime == 0) {
            stats.averageQueryTime = processingTime;
        } else {
            // Exponential moving average
            stats.averageQueryTime = (stats.averageQueryTime * 9 + processingTime) / 10;
        }
    }
    
    /// @dev Configure MCP server settings
    /// @param serverEndpoint MCP server endpoint URL
    /// @param apiKey API key for authentication
    /// @param aiAnalyticsEnabled Whether AI analytics are enabled
    /// @param maxPageSize Maximum page size for responses
    function configureMCPServer(
        string calldata serverEndpoint,
        string calldata apiKey,
        bool aiAnalyticsEnabled,
        uint256 maxPageSize
    ) external onlyOwner {
        require(bytes(serverEndpoint).length > 0, "Invalid server endpoint");
        require(maxPageSize > 0 && maxPageSize <= 1000, "Invalid page size");
        
        mcpConfig.serverEndpoint = serverEndpoint;
        mcpConfig.apiKey = apiKey;
        mcpConfig.aiAnalyticsEnabled = aiAnalyticsEnabled;
        mcpConfig.maxPageSize = maxPageSize;
        mcpConfig.isActive = true;
        
        emit MCPServerConfigured(serverEndpoint, aiAnalyticsEnabled, maxPageSize);
    }
    
    /// @dev Get analytics query details
    /// @param queryId Query identifier
    /// @return query Complete query data
    function getAnalyticsQuery(bytes32 queryId) external view returns (AnalyticsQuery memory query) {
        return analyticsQueries[queryId];
    }
    
    /// @dev Get MEV insights for a pool
    /// @param poolId Pool identifier
    /// @return insights Array of MEV insights for the pool
    function getMEVInsights(bytes32 poolId) external view returns (MEVInsights[] memory insights) {
        return poolMEVInsights[poolId];
    }
    
    /// @dev Get current Autoscout configuration
    /// @return config Current Autoscout deployment configuration
    function getAutoscoutConfig() external view returns (AutoscoutConfig memory config) {
        return autoscoutConfig;
    }
    
    /// @dev Get MCP server configuration
    /// @return config Current MCP server configuration
    function getMCPConfig() external view returns (MCPServerConfig memory config) {
        return mcpConfig;
    }
    
    /// @dev Get integration statistics
    /// @return stats Current integration statistics
    function getIntegrationStats() external view returns (IntegrationStats memory) {
        return stats;
    }
    
    /// @dev Get all query IDs for enumeration
    /// @return queryIds Array of all query identifiers
    function getAllQueries() external view returns (bytes32[] memory queryIds) {
        return allQueries;
    }
    
    /// @dev Update query type fee
    /// @param queryType Type of query to update
    /// @param newFee New fee in wei
    function updateQueryTypeFee(string calldata queryType, uint256 newFee) external onlyOwner {
        require(supportedQueryTypes[queryType], "Unsupported query type");
        queryTypeFees[queryType] = newFee;
    }
    
    /// @dev Add new supported query type
    /// @param queryType New query type to support
    /// @param fee Fee for this query type in wei
    function addQueryType(string calldata queryType, uint256 fee) external onlyOwner {
        require(!supportedQueryTypes[queryType], "Query type already supported");
        supportedQueryTypes[queryType] = true;
        queryTypeFees[queryType] = fee;
    }
    
    /// @dev Remove supported query type
    /// @param queryType Query type to remove
    function removeQueryType(string calldata queryType) external onlyOwner {
        require(supportedQueryTypes[queryType], "Query type not supported");
        supportedQueryTypes[queryType] = false;
        delete queryTypeFees[queryType];
    }
    
    /// @dev Update Autoscout deployment status (admin function)
    /// @param newStatus New deployment status
    function updateAutoscoutStatus(AutoscoutStatus newStatus) external onlyOwner {
        AutoscoutStatus oldStatus = autoscoutConfig.status;
        autoscoutConfig.status = newStatus;
        
        // Update active explorer count
        if (oldStatus == AutoscoutStatus.ACTIVE && newStatus != AutoscoutStatus.ACTIVE) {
            stats.activeExplorers--;
        } else if (oldStatus != AutoscoutStatus.ACTIVE && newStatus == AutoscoutStatus.ACTIVE) {
            stats.activeExplorers++;
        }
    }
    
    /// @dev Emergency function to withdraw collected fees
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner()).transfer(balance);
    }
    
    /// @dev Check if query type is supported
    /// @param queryType Query type to check
    /// @return supported Whether the query type is supported
    function isQueryTypeSupported(string calldata queryType) external view returns (bool supported) {
        return supportedQueryTypes[queryType];
    }
    
    /// @dev Get fee for query type
    /// @param queryType Query type to check fee for
    /// @return fee Fee in wei for the query type
    function getQueryTypeFee(string calldata queryType) external view returns (uint256 fee) {
        return queryTypeFees[queryType];
    }
}