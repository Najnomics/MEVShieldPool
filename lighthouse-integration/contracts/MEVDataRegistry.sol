// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title MEVDataRegistry
 * @dev On-chain registry for MEV DataCoins with Lighthouse integration
 * @notice Manages MEV data monetization and revenue distribution
 * 
 * Features:
 * - DataCoin registration and metadata storage
 * - Subscription management with tiered access
 * - Automated revenue distribution
 * - Data quality scoring and reputation system
 * - Integration with Lighthouse IPFS storage
 * 
 * Built for Lighthouse $1,000 DataCoins Integration Prize
 */
contract MEVDataRegistry is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    Counters.Counter private _dataCoinIds;
    
    // DataCoin structure
    struct DataCoin {
        uint256 id;
        address collector;
        string ipfsHash;
        string dataType;
        uint256 price;
        uint256 timestamp;
        uint256 subscribers;
        uint256 totalRevenue;
        uint8 qualityScore; // 0-100
        bool active;
        bytes32 dataHash;
    }
    
    // Subscription structure
    struct Subscription {
        uint256 id;
        uint256 dataCoinId;
        address subscriber;
        uint256 startTime;
        uint256 duration;
        uint256 paidAmount;
        bool active;
        uint8 accessTier; // 1=basic, 2=premium, 3=enterprise
    }
    
    // Data collector reputation
    struct CollectorProfile {
        address collector;
        uint256 totalDataCoins;
        uint256 totalRevenue;
        uint256 totalSubscribers;
        uint256 reputationScore; // 0-1000
        bool verified;
    }
    
    // Mappings
    mapping(uint256 => DataCoin) public dataCoins;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => CollectorProfile) public collectors;
    mapping(address => uint256[]) public collectorDataCoins;
    mapping(address => uint256[]) public subscriberSubscriptions;
    mapping(string => uint256[]) public dataTypeCoins; // dataType => coinIds
    
    // Revenue distribution settings
    uint256 public collectorShare = 80; // 80%
    uint256 public protocolShare = 20; // 20%
    uint256 public constant PERCENTAGE_BASE = 100;
    
    // Subscription pricing tiers
    mapping(uint8 => uint256) public tierMultipliers; // tier => multiplier (basis points)
    
    // Events
    event DataCoinRegistered(
        uint256 indexed coinId,
        address indexed collector,
        string dataType,
        uint256 price,
        string ipfsHash
    );
    
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        uint256 indexed dataCoinId,
        address indexed subscriber,
        uint256 duration,
        uint256 amount
    );
    
    event RevenueDistributed(
        uint256 indexed dataCoinId,
        address indexed collector,
        uint256 collectorAmount,
        uint256 protocolAmount
    );
    
    event QualityScoreUpdated(
        uint256 indexed dataCoinId,
        uint8 oldScore,
        uint8 newScore
    );
    
    event CollectorVerified(address indexed collector);
    
    constructor() {
        // Initialize tier multipliers (basis points)
        tierMultipliers[1] = 10000; // Basic: 1x
        tierMultipliers[2] = 15000; // Premium: 1.5x
        tierMultipliers[3] = 25000; // Enterprise: 2.5x
    }
    
    /**
     * @dev Register a new MEV DataCoin
     * @param ipfsHash IPFS hash of encrypted data
     * @param dataType Type of MEV data (arbitrage, liquidation, etc.)
     * @param basePrice Base price for data access
     * @param dataHash Hash of the raw data for verification
     */
    function registerDataCoin(
        string memory ipfsHash,
        string memory dataType,
        uint256 basePrice,
        bytes32 dataHash
    ) external returns (uint256) {
        require(bytes(ipfsHash).length > 0, "Invalid IPFS hash");
        require(bytes(dataType).length > 0, "Invalid data type");
        require(basePrice > 0, "Price must be greater than 0");
        
        _dataCoinIds.increment();
        uint256 newCoinId = _dataCoinIds.current();
        
        // Create DataCoin
        dataCoins[newCoinId] = DataCoin({
            id: newCoinId,
            collector: msg.sender,
            ipfsHash: ipfsHash,
            dataType: dataType,
            price: basePrice,
            timestamp: block.timestamp,
            subscribers: 0,
            totalRevenue: 0,
            qualityScore: 50, // Initial score
            active: true,
            dataHash: dataHash
        });
        
        // Update collector profile
        CollectorProfile storage profile = collectors[msg.sender];
        if (profile.collector == address(0)) {
            profile.collector = msg.sender;
            profile.reputationScore = 100; // Initial reputation
        }
        profile.totalDataCoins++;
        
        // Add to mappings
        collectorDataCoins[msg.sender].push(newCoinId);
        dataTypeCoins[dataType].push(newCoinId);
        
        emit DataCoinRegistered(newCoinId, msg.sender, dataType, basePrice, ipfsHash);
        return newCoinId;
    }
    
    /**
     * @dev Subscribe to a DataCoin
     * @param dataCoinId ID of the DataCoin to subscribe to
     * @param duration Subscription duration in days
     * @param accessTier Access tier (1=basic, 2=premium, 3=enterprise)
     */
    function subscribe(
        uint256 dataCoinId,
        uint256 duration,
        uint8 accessTier
    ) external payable nonReentrant {
        require(dataCoins[dataCoinId].active, "DataCoin not active");
        require(duration > 0 && duration <= 365, "Invalid duration");
        require(accessTier >= 1 && accessTier <= 3, "Invalid access tier");
        
        DataCoin storage dataCoin = dataCoins[dataCoinId];
        
        // Calculate subscription price
        uint256 subscriptionPrice = calculateSubscriptionPrice(
            dataCoin.price,
            duration,
            accessTier
        );
        
        require(msg.value >= subscriptionPrice, "Insufficient payment");
        
        // Create subscription
        uint256 subscriptionId = _createSubscription(
            dataCoinId,
            msg.sender,
            duration,
            accessTier,
            subscriptionPrice
        );
        
        // Update DataCoin stats
        dataCoin.subscribers++;
        dataCoin.totalRevenue += subscriptionPrice;
        
        // Update collector profile
        CollectorProfile storage profile = collectors[dataCoin.collector];
        profile.totalRevenue += subscriptionPrice;
        profile.totalSubscribers++;
        
        // Distribute revenue
        _distributeRevenue(dataCoinId, subscriptionPrice);
        
        // Refund excess payment
        if (msg.value > subscriptionPrice) {
            payable(msg.sender).transfer(msg.value - subscriptionPrice);
        }
        
        emit SubscriptionCreated(
            subscriptionId,
            dataCoinId,
            msg.sender,
            duration,
            subscriptionPrice
        );
    }
    
    /**
     * @dev Calculate subscription price based on duration and tier
     */
    function calculateSubscriptionPrice(
        uint256 basePrice,
        uint256 duration,
        uint8 accessTier
    ) public view returns (uint256) {
        uint256 tierMultiplier = tierMultipliers[accessTier];
        require(tierMultiplier > 0, "Invalid tier");
        
        return (basePrice * duration * tierMultiplier) / (10000 * 30); // Normalize to daily rate
    }
    
    /**
     * @dev Create a new subscription
     */
    function _createSubscription(
        uint256 dataCoinId,
        address subscriber,
        uint256 duration,
        uint8 accessTier,
        uint256 amount
    ) internal returns (uint256) {
        uint256 subscriptionId = uint256(keccak256(
            abi.encodePacked(dataCoinId, subscriber, block.timestamp)
        ));
        
        subscriptions[subscriptionId] = Subscription({
            id: subscriptionId,
            dataCoinId: dataCoinId,
            subscriber: subscriber,
            startTime: block.timestamp,
            duration: duration * 1 days,
            paidAmount: amount,
            active: true,
            accessTier: accessTier
        });
        
        subscriberSubscriptions[subscriber].push(subscriptionId);
        return subscriptionId;
    }
    
    /**
     * @dev Distribute revenue between collector and protocol
     */
    function _distributeRevenue(uint256 dataCoinId, uint256 amount) internal {
        DataCoin storage dataCoin = dataCoins[dataCoinId];
        
        uint256 collectorAmount = (amount * collectorShare) / PERCENTAGE_BASE;
        uint256 protocolAmount = amount - collectorAmount;
        
        // Transfer to collector
        payable(dataCoin.collector).transfer(collectorAmount);
        
        // Protocol amount stays in contract
        
        emit RevenueDistributed(
            dataCoinId,
            dataCoin.collector,
            collectorAmount,
            protocolAmount
        );
    }
    
    /**
     * @dev Check if subscription is valid and active
     */
    function isSubscriptionValid(uint256 subscriptionId) external view returns (bool) {
        Subscription memory sub = subscriptions[subscriptionId];
        
        if (!sub.active) return false;
        if (block.timestamp > sub.startTime + sub.duration) return false;
        
        return dataCoins[sub.dataCoinId].active;
    }
    
    /**
     * @dev Update quality score for a DataCoin (only owner)
     */
    function updateQualityScore(uint256 dataCoinId, uint8 newScore) external onlyOwner {
        require(dataCoins[dataCoinId].collector != address(0), "DataCoin not found");
        require(newScore <= 100, "Score must be 0-100");
        
        uint8 oldScore = dataCoins[dataCoinId].qualityScore;
        dataCoins[dataCoinId].qualityScore = newScore;
        
        // Update collector reputation based on quality change
        CollectorProfile storage profile = collectors[dataCoins[dataCoinId].collector];
        if (newScore > oldScore) {
            profile.reputationScore += (newScore - oldScore) * 2;
        } else {
            profile.reputationScore = profile.reputationScore > (oldScore - newScore) * 2 
                ? profile.reputationScore - (oldScore - newScore) * 2 
                : 0;
        }
        
        // Cap reputation at 1000
        if (profile.reputationScore > 1000) {
            profile.reputationScore = 1000;
        }
        
        emit QualityScoreUpdated(dataCoinId, oldScore, newScore);
    }
    
    /**
     * @dev Verify a data collector (only owner)
     */
    function verifyCollector(address collector) external onlyOwner {
        require(collectors[collector].collector != address(0), "Collector not found");
        
        collectors[collector].verified = true;
        collectors[collector].reputationScore += 100; // Bonus for verification
        
        if (collectors[collector].reputationScore > 1000) {
            collectors[collector].reputationScore = 1000;
        }
        
        emit CollectorVerified(collector);
    }
    
    /**
     * @dev Get DataCoins by data type
     */
    function getDataCoinsByType(string memory dataType) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return dataTypeCoins[dataType];
    }
    
    /**
     * @dev Get collector's DataCoins
     */
    function getCollectorDataCoins(address collector) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return collectorDataCoins[collector];
    }
    
    /**
     * @dev Get subscriber's subscriptions
     */
    function getSubscriberSubscriptions(address subscriber) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return subscriberSubscriptions[subscriber];
    }
    
    /**
     * @dev Get marketplace statistics
     */
    function getMarketplaceStats() external view returns (
        uint256 totalDataCoins,
        uint256 totalCollectors,
        uint256 totalRevenue,
        uint256 averagePrice
    ) {
        totalDataCoins = _dataCoinIds.current();
        
        uint256 totalPriceSum = 0;
        uint256 activeCoins = 0;
        
        for (uint256 i = 1; i <= totalDataCoins; i++) {
            if (dataCoins[i].active) {
                totalRevenue += dataCoins[i].totalRevenue;
                totalPriceSum += dataCoins[i].price;
                activeCoins++;
            }
        }
        
        // Count unique collectors
        // Note: This is gas-intensive for large datasets, consider off-chain calculation
        totalCollectors = 0; // Placeholder - implement more efficient counting
        
        averagePrice = activeCoins > 0 ? totalPriceSum / activeCoins : 0;
    }
    
    /**
     * @dev Update revenue share percentages (only owner)
     */
    function updateRevenueShares(
        uint256 newCollectorShare,
        uint256 newProtocolShare
    ) external onlyOwner {
        require(
            newCollectorShare + newProtocolShare == PERCENTAGE_BASE,
            "Shares must sum to 100%"
        );
        
        collectorShare = newCollectorShare;
        protocolShare = newProtocolShare;
    }
    
    /**
     * @dev Update tier multipliers (only owner)
     */
    function updateTierMultiplier(uint8 tier, uint256 multiplier) external onlyOwner {
        require(tier >= 1 && tier <= 3, "Invalid tier");
        require(multiplier > 0, "Multiplier must be positive");
        
        tierMultipliers[tier] = multiplier;
    }
    
    /**
     * @dev Deactivate a DataCoin (collector or owner)
     */
    function deactivateDataCoin(uint256 dataCoinId) external {
        require(
            dataCoins[dataCoinId].collector == msg.sender || msg.sender == owner(),
            "Not authorized"
        );
        
        dataCoins[dataCoinId].active = false;
    }
    
    /**
     * @dev Withdraw protocol revenue (only owner)
     */
    function withdrawProtocolRevenue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount <= address(this).balance, "Insufficient balance");
        
        to.transfer(amount);
    }
    
    /**
     * @dev Emergency pause (only owner)
     */
    function pause() external onlyOwner {
        // Implement pausable functionality if needed
        // This would require importing Pausable from OpenZeppelin
    }
    
    /**
     * @dev Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}