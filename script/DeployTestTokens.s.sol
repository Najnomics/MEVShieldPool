// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleTestToken
 * @dev Simple ERC20 token for testing
 */
contract SimpleTestToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10**18); // Mint 1M tokens
    }
}

/**
 * @title DeployTestTokens
 * @dev Deploy test tokens for pool initialization
 */
contract DeployTestTokens is Script {
    function run() external {
        // Use the private key passed via --private-key flag
        vm.startBroadcast();

        console.log("Deploying test tokens...");

        // Deploy TokenA
        SimpleTestToken tokenA = new SimpleTestToken("Test Token A", "TTA");
        console.log("TokenA deployed at:", address(tokenA));

        // Deploy TokenB
        SimpleTestToken tokenB = new SimpleTestToken("Test Token B", "TTB");
        console.log("TokenB deployed at:", address(tokenB));

        // Or use WETH9 on Sepolia: 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14
        address weth9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
        console.log("WETH9 on Sepolia:", weth9);

        console.log("\n=== Deployment Summary ===");
        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("WETH9:", weth9);
        console.log("\nYou can now use these tokens to initialize a pool!");

        vm.stopBroadcast();
    }
}

