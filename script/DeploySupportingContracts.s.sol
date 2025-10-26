// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LitEncryptionHook} from "../src/hooks/LitEncryptionHook.sol";
import {PythPriceHook} from "../src/hooks/PythPriceHook.sol";
import {YellowStateChannel} from "../src/hooks/YellowStateChannel.sol";

/**
 * @title DeploySupportingContracts
 * @dev Deploys LitEncryptionHook, PythPriceHook, and YellowStateChannel
 * @notice These are regular contracts (not V4 hooks), so they can be deployed normally
 */
contract DeploySupportingContracts is Script {
    // Pyth contract address on Sepolia
    address constant PYTH_CONTRACT = 0xDd24F84d36BF92C65F92307595335bdFab5Bbd21;
    
    function run() external {
        console.log("=== Deploying Supporting Contracts ===");
        console.log("Network: Sepolia Testnet");
        console.log("Pyth Contract:", PYTH_CONTRACT);
        
        // Get deployer address
        address deployer = msg.sender;
        console.log("Deployer:", deployer);
        
        vm.startBroadcast();
        
        // 1. Deploy LitEncryptionHook
        console.log("\nDeploying LitEncryptionHook...");
        LitEncryptionHook litHook = new LitEncryptionHook(deployer);
        console.log("LitEncryptionHook deployed at:", address(litHook));
        
        // 2. Deploy PythPriceHook
        console.log("\nDeploying PythPriceHook...");
        PythPriceHook pythHook = new PythPriceHook(PYTH_CONTRACT);
        console.log("PythPriceHook deployed at:", address(pythHook));
        
        // 3. Deploy YellowStateChannel
        console.log("\nDeploying YellowStateChannel...");
        YellowStateChannel yellowChannel = new YellowStateChannel(deployer);
        console.log("YellowStateChannel deployed at:", address(yellowChannel));
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Complete ===");
        console.log("LitEncryptionHook:", address(litHook));
        console.log("PythPriceHook:", address(pythHook));
        console.log("YellowStateChannel:", address(yellowChannel));
        console.log("\nUpdate .env with these addresses!");
    }
}

