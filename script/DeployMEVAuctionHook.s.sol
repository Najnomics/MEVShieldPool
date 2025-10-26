// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {MEVAuctionHook} from "../src/hooks/MEVAuctionHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {ILitEncryption} from "../src/interfaces/ILitEncryption.sol";
import {IPythPriceOracle} from "../src/interfaces/IPythPriceOracle.sol";

/**
 * @title DeployMEVAuctionHook
 * @dev Proper V4 hook deployment using HookMiner for CREATE2 address matching
 * @notice Deploys MEVAuctionHook at a valid address that encodes hook permissions
 */
contract DeployMEVAuctionHook is Script {
    // CREATE2 Deployer Proxy address (standard for V4 deployments)
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    
    // Already deployed contracts on Sepolia
    address constant POOL_MANAGER = 0x89169DeAE6C7E07A12De45B6198D4022e14527cC;
    address constant LIT_ENCRYPTION = 0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7;
    address constant PYTH_PRICE_HOOK = 0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2;
    
    function run() external {
        console.log("=== MEVAuctionHook V4 Deployment ===");
        console.log("Network: Sepolia Testnet");
        console.log("PoolManager:", POOL_MANAGER);
        console.log("LitEncryption:", LIT_ENCRYPTION);
        console.log("PythPriceHook:", PYTH_PRICE_HOOK);
        
        // Calculate hook permissions flags based on getHookPermissions()
        // beforeInitialize: true, beforeAddLiquidity: true, beforeRemoveLiquidity: true, beforeSwap: true, afterSwap: true
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG |
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG
        );
        
        console.log("\nMining for hook address with correct permissions...");
        
        // Prepare constructor arguments
        bytes memory constructorArgs = abi.encode(
            IPoolManager(POOL_MANAGER),
            ILitEncryption(LIT_ENCRYPTION),
            IPythPriceOracle(PYTH_PRICE_HOOK)
        );
        
        // In forge script, we must use CREATE2 Deployer Proxy as the deployer
        // This is because vm.startBroadcast() uses CREATE2 Deployer Proxy internally
        address deployer = CREATE2_DEPLOYER;
        
        // Mine for the correct CREATE2 address using CREATE2 Deployer Proxy
        (address hookAddress, bytes32 salt) = HookMiner.find(
            deployer,
            flags,
            type(MEVAuctionHook).creationCode,
            constructorArgs
        );
        
        console.log("Found hook address:", hookAddress);
        console.log("Salt:", vm.toString(salt));
        console.log("Using CREATE2 Deployer Proxy:", deployer);
        
        // Deploy the hook using CREATE2 via broadcast
        // Create2Deployer will be used automatically when broadcasting
        vm.startBroadcast();
        
        MEVAuctionHook hook = new MEVAuctionHook{salt: salt}(
            IPoolManager(POOL_MANAGER),
            ILitEncryption(LIT_ENCRYPTION),
            IPythPriceOracle(PYTH_PRICE_HOOK)
        );
        
        vm.stopBroadcast();
        
        // Verify deployment
        require(address(hook) == hookAddress, "Hook address mismatch!");
        console.log("\nMEVAuctionHook deployed successfully!");
        console.log("Address:", address(hook));
        
        // Verify permissions
        Hooks.Permissions memory perms = hook.getHookPermissions();
        console.log("\nHook Permissions:");
        console.log("- beforeInitialize:", perms.beforeInitialize);
        console.log("- beforeAddLiquidity:", perms.beforeAddLiquidity);
        console.log("- beforeRemoveLiquidity:", perms.beforeRemoveLiquidity);
        console.log("- beforeSwap:", perms.beforeSwap);
        console.log("- afterSwap:", perms.afterSwap);
        
        console.log("\n=== Deployment Complete ===");
        console.log("MEVAuctionHook:", address(hook));
        console.log("\nNext steps:");
        console.log("1. Record the hook address for pool initialization");
        console.log("2. Initialize pools with this hook address");
        console.log("3. Test swap operations with auction functionality");
    }
}

