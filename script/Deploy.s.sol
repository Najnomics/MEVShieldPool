// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MEVAuctionHook} from "../src/hooks/MEVAuctionHook.sol";
import {LitEncryptionHook} from "../src/hooks/LitEncryptionHook.sol";
import {PythPriceHook} from "../src/hooks/PythPriceHook.sol";
import {YellowStateChannel} from "../src/hooks/YellowStateChannel.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPythPriceOracle} from "../src/interfaces/IPythPriceOracle.sol";

/**
 * @title Deploy
 * @dev Deployment script for MEVShield Pool protocol on multiple networks
 * @notice Deploys all protocol components with proper configuration
 * @author MEVShield Pool Team
 */
contract Deploy is Script {
    /**
     * @dev Deployment configuration structure
     */
    struct DeploymentConfig {
        address pythContract;
        address poolManagerAddress;
        address deployer;
        uint256 chainId;
        string networkName;
    }

    /**
     * @dev Deployed contract addresses
     */
    struct DeployedContracts {
        address poolManager;
        address litEncryption;
        address pythPriceHook;
        address yellowStateChannel;
        address mevAuctionHook;
    }

    /**
     * @dev Network-specific Pyth contract addresses
     */
    mapping(uint256 => address) public pythContracts;
    mapping(uint256 => address) public poolManagers;

    /**
     * @dev Deployment events for tracking
     */
    event ContractDeployed(string contractName, address contractAddress, uint256 chainId);
    event DeploymentComplete(DeployedContracts contracts, uint256 chainId);

    /**
     * @dev Initialize network configurations
     */
    function _initializeNetworkConfig() internal {
        // Ethereum Mainnet
        pythContracts[1] = 0x4305FB66699C3B2702D4d05CF36551390A4c69C6;
        
        // Ethereum Sepolia Testnet
        pythContracts[11155111] = 0xDd24F84d36BF92C65F92307595335bdFab5Bbd21;
        
        // Arbitrum One
        pythContracts[42161] = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;
        
        // Polygon
        pythContracts[137] = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;
        
        // Base
        pythContracts[8453] = 0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a;

        // For development and testing, we'll deploy our own PoolManager
        // In production, use the official Uniswap V4 PoolManager addresses
    }

    /**
     * @dev Main deployment function
     */
    function run() external {
        // Initialize network configurations
        _initializeNetworkConfig();
        
        // Get deployment configuration
        DeploymentConfig memory config = _getDeploymentConfig();
        
        console.log("Starting MEVShield Pool deployment on", config.networkName);
        console.log("Chain ID:", config.chainId);
        console.log("Deployer:", config.deployer);
        
        // Start broadcasting transactions
        vm.startBroadcast();
        
        // Deploy all contracts
        DeployedContracts memory deployed = _deployAllContracts(config);
        
        // Configure contracts
        _configureContracts(deployed, config);
        
        // Stop broadcasting
        vm.stopBroadcast();
        
        // Log deployment completion
        _logDeployment(deployed, config);
        
        // Emit deployment complete event
        emit DeploymentComplete(deployed, config.chainId);
    }

    /**
     * @dev Gets deployment configuration for current network
     * @return config Deployment configuration structure
     */
    function _getDeploymentConfig() internal view returns (DeploymentConfig memory config) {
        uint256 chainId = block.chainid;
        
        config = DeploymentConfig({
            pythContract: pythContracts[chainId],
            poolManagerAddress: poolManagers[chainId],
            deployer: msg.sender,
            chainId: chainId,
            networkName: _getNetworkName(chainId)
        });
        
        // Validate configuration
        require(config.pythContract != address(0), "Pyth contract not configured for this network");
    }

    /**
     * @dev Deploys all protocol contracts in correct order
     * @param config Deployment configuration
     * @return deployed Deployed contract addresses
     */
    function _deployAllContracts(DeploymentConfig memory config) internal returns (DeployedContracts memory deployed) {
        console.log("Deploying protocol contracts...");
        
        // 1. Deploy PoolManager if not exists (for testing)
        if (config.poolManagerAddress == address(0)) {
            deployed.poolManager = address(new PoolManager(config.deployer)); // Pass deployer as owner
            emit ContractDeployed("PoolManager", deployed.poolManager, config.chainId);
            console.log("PoolManager deployed at:", deployed.poolManager);
        } else {
            deployed.poolManager = config.poolManagerAddress;
            console.log("Using existing PoolManager at:", deployed.poolManager);
        }
        
        // 2. Deploy Lit Protocol Encryption Hook
        deployed.litEncryption = address(new LitEncryptionHook(config.deployer));
        emit ContractDeployed("LitEncryptionHook", deployed.litEncryption, config.chainId);
        console.log("LitEncryptionHook deployed at:", deployed.litEncryption);
        
        // 3. Deploy Pyth Price Hook
        deployed.pythPriceHook = address(new PythPriceHook(config.pythContract));
        emit ContractDeployed("PythPriceHook", deployed.pythPriceHook, config.chainId);
        console.log("PythPriceHook deployed at:", deployed.pythPriceHook);
        
        // 4. Deploy Yellow Network State Channel
        deployed.yellowStateChannel = address(new YellowStateChannel(config.deployer));
        emit ContractDeployed("YellowStateChannel", deployed.yellowStateChannel, config.chainId);
        console.log("YellowStateChannel deployed at:", deployed.yellowStateChannel);
        
        // 5. Deploy MEV Auction Hook (main contract)
        deployed.mevAuctionHook = address(new MEVAuctionHook(
            IPoolManager(deployed.poolManager),
            LitEncryptionHook(deployed.litEncryption),
            IPythPriceOracle(deployed.pythPriceHook)
        ));
        emit ContractDeployed("MEVAuctionHook", deployed.mevAuctionHook, config.chainId);
        console.log("MEVAuctionHook deployed at:", deployed.mevAuctionHook);
        
        return deployed;
    }

    /**
     * @dev Configures deployed contracts with initial parameters
     * @param deployed Deployed contract addresses
     * @param config Deployment configuration
     */
    function _configureContracts(DeployedContracts memory deployed, DeploymentConfig memory config) internal {
        console.log("Configuring contracts...");
        
        // Configure Lit Encryption Hook with sample pool
        LitEncryptionHook litHook = LitEncryptionHook(deployed.litEncryption);
        bytes32 samplePoolId = keccak256(abi.encodePacked("SAMPLE_POOL"));
        litHook.initializePool(samplePoolId, 2, 3); // 2-of-3 MPC
        console.log("Initialized sample pool in LitEncryptionHook");
        
        console.log("Configuration complete");
    }

    /**
     * @dev Logs deployment information
     * @param deployed Deployed contract addresses
     * @param config Deployment configuration
     */
    function _logDeployment(DeployedContracts memory deployed, DeploymentConfig memory config) internal view {
        console.log("\n=== MEVShield Pool Deployment Complete ===");
        console.log("Network:", config.networkName);
        console.log("Chain ID:", config.chainId);
        console.log("Deployer:", config.deployer);
        console.log("\nDeployed Contracts:");
        console.log("- PoolManager:", deployed.poolManager);
        console.log("- LitEncryptionHook:", deployed.litEncryption);
        console.log("- PythPriceHook:", deployed.pythPriceHook);
        console.log("- YellowStateChannel:", deployed.yellowStateChannel);
        console.log("- MEVAuctionHook:", deployed.mevAuctionHook);
        console.log("==========================================");
    }

    /**
     * @dev Gets network name from chain ID
     * @param chainId Blockchain network chain ID
     * @return networkName Human-readable network name
     */
    function _getNetworkName(uint256 chainId) internal pure returns (string memory networkName) {
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 11155111) return "Ethereum Sepolia";
        if (chainId == 42161) return "Arbitrum One";
        if (chainId == 137) return "Polygon";
        if (chainId == 8453) return "Base";
        if (chainId == 31337) return "Localhost";
        return "Unknown Network";
    }

    /**
     * @dev Verification helper for post-deployment validation
     * @param deployed Deployed contract addresses
     */
    function verifyDeployment(DeployedContracts memory deployed) external view {
        console.log("Verifying deployment...");
        
        // Verify all contracts are deployed
        require(deployed.poolManager.code.length > 0, "PoolManager not deployed");
        require(deployed.litEncryption.code.length > 0, "LitEncryptionHook not deployed");
        require(deployed.pythPriceHook.code.length > 0, "PythPriceHook not deployed");
        require(deployed.yellowStateChannel.code.length > 0, "YellowStateChannel not deployed");
        require(deployed.mevAuctionHook.code.length > 0, "MEVAuctionHook not deployed");
        
        console.log("All contracts verified successfully");
    }
}