// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title InitializePoolWithTokens
 * @dev Initialize a Uniswap V4 pool with MEV hook using real tokens
 */
contract InitializePoolWithTokens is Script {
    using PoolIdLibrary for PoolKey;

    // Sepolia addresses - PoolManager may need to be deployed or use different address
    // For now, we'll need to deploy our own PoolManager or use an existing one
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    // Latest MEVAuctionHook deployed with correct PoolManager
    address constant MEV_HOOK = 0xD3839BaA9fF7D533aBCfc204a968f9F47E0DaaC0;
    
    // WETH9 on Sepolia
    address constant WETH9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    function run() external {
        vm.startBroadcast();

        // Use recently deployed test tokens
        address tokenA = 0xe6ee6FBE2E0f047bd082a60d70FcDBF637eC3d38; // TokenA
        address tokenB = 0x3932ED745f6e348CcE56621c4ff9Da47Afbf7945; // TokenB

        // Ensure addresses are ordered correctly (currency0 < currency1)
        address currency0 = tokenA < tokenB ? tokenA : tokenB;
        address currency1 = tokenA < tokenB ? tokenB : tokenA;

        IPoolManager poolManager = IPoolManager(POOL_MANAGER);

        // Create pool key
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(currency0),
            currency1: Currency.wrap(currency1),
            fee: 3000, // 0.3%
            tickSpacing: 60,
            hooks: IHooks(MEV_HOOK)
        });

        PoolId poolId = key.toId();
        console.log("\n=== Pool Configuration ===");
        console.log("Pool ID:", vm.toString(uint256(PoolId.unwrap(poolId))));
        console.log("Currency0:", currency0);
        console.log("Currency1:", currency1);
        console.log("Fee:", key.fee, "(0.3%)");
        console.log("Tick Spacing:", key.tickSpacing);
        console.log("Hooks:", address(key.hooks));

        // sqrtPriceX96 for initial price (1:1 = sqrt(1) * 2^96)
        uint160 sqrtPriceX96 = 79228162514264337593543950336;

        console.log("\nInitializing pool...");
        console.log("This will trigger the hook's beforeInitialize() to start the auction");

        // Initialize the pool
        // PoolManager.initialize signature: (PoolKey, uint160)
        // The hook's beforeInitialize will be called automatically
        poolManager.initialize(key, sqrtPriceX96);

        console.log("\nPool initialized successfully!");
        console.log("Auction is now active for this pool");
        console.log("\nPool ID for bid submission:");
        console.log(uint256(PoolId.unwrap(poolId)));

        vm.stopBroadcast();
    }
}

