// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

/**
 * @title InitializePool
 * @dev Script to initialize a Uniswap V4 pool with MEV hook attached
 */
contract InitializePool is Script {
    using PoolIdLibrary for PoolKey;

    // Sepolia addresses
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    address constant MEV_HOOK = 0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0;
    
    // WETH9 on Sepolia
    address constant WETH9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    
    // For testing, we'll use ETH as currency0 and a test token as currency1
    // Or create a simple token for testing
    address constant TEST_TOKEN = address(0x1); // Placeholder - would need actual token

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IPoolManager poolManager = IPoolManager(POOL_MANAGER);

        // Create pool key
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(WETH9),
            currency1: Currency.wrap(TEST_TOKEN),
            fee: 3000, // 0.3%
            tickSpacing: 60,
            hooks: IHooks(MEV_HOOK)
        });

        PoolId poolId = key.toId();
        console.log("Pool ID:", uint256(PoolId.unwrap(poolId)));

        // sqrtPriceX96 for initial price (1:1 = sqrt(1) * 2^96)
        uint160 sqrtPriceX96 = 79228162514264337593543950336;

        console.log("Initializing pool...");
        console.log("Currency0 (WETH):", address(Currency.unwrap(key.currency0)));
        console.log("Currency1 (Test):", address(Currency.unwrap(key.currency1)));
        console.log("Fee:", key.fee);
        console.log("Tick Spacing:", key.tickSpacing);
        console.log("Hooks:", address(key.hooks));

        // Initialize the pool
        // This will call the hook's beforeInitialize() which sets up the auction
        // PoolManager.initialize(PoolKey, uint160, bytes)
        bytes memory initData = "";
        poolManager.initialize(key, sqrtPriceX96, initData);

        console.log("Pool initialized successfully!");
        console.log("Auction should now be active for this pool");

        vm.stopBroadcast();
    }
}

