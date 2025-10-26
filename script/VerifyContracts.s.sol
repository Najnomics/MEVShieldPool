// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";

/**
 * @title VerifyContracts
 * @dev Script to verify deployed contracts on Etherscan
 * @notice Run with: forge script script/VerifyContracts.s.sol --rpc-url $SEPOLIA_RPC_URL --verify --etherscan-api-key $ETHERSCAN_API_KEY
 */
contract VerifyContracts is Script {
    // Deployed contract addresses on Sepolia
    address constant MEV_AUCTION_HOOK = 0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0;
    address constant LIT_ENCRYPTION_HOOK = 0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7;
    address constant PYTH_PRICE_HOOK = 0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2;
    address constant YELLOW_STATE_CHANNEL = 0x1Bd94cB5Eccb3968a229814c7CAe8B97795cE177;
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    
    // Constructor arguments for MEVAuctionHook
    address constant POOL_MANAGER_ARG = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    address constant LIT_ENCRYPTION_ARG = 0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7;
    address constant PYTH_PRICE_HOOK_ARG = 0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2;
    
    function run() external {
        console.log("=== Contract Verification Script ===");
        console.log("Network: Sepolia Testnet");
        console.log("");
        console.log("To verify contracts, run the following commands:");
        console.log("");
        
        // MEVAuctionHook verification command
        console.log("1. Verify MEVAuctionHook:");
        console.log("forge verify-contract \\");
        console.log("  0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0 \\");
        console.log("  src/hooks/MEVAuctionHook.sol:MEVAuctionHook \\");
        console.log("  --chain-id 11155111 \\");
        console.log("  --rpc-url $SEPOLIA_RPC_URL \\");
        console.log("  --etherscan-api-key $ETHERSCAN_API_KEY \\");
        console.log("  --constructor-args $(cast abi-encode \"constructor(address,address,address)\" \\");
        console.log("    0xE03A1074c86CFeDd5C142C4F04F1a1536e203543 \\");
        console.log("    0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7 \\");
        console.log("    0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2)");
        console.log("");
        
        // LitEncryptionHook verification command
        console.log("2. Verify LitEncryptionHook:");
        console.log("forge verify-contract \\");
        console.log("  0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7 \\");
        console.log("  src/hooks/LitEncryptionHook.sol:LitEncryptionHook \\");
        console.log("  --chain-id 11155111 \\");
        console.log("  --rpc-url $SEPOLIA_RPC_URL \\");
        console.log("  --etherscan-api-key $ETHERSCAN_API_KEY \\");
        console.log("  --constructor-args $(cast abi-encode \"constructor(address)\" 0x$(cast wallet address --private-key $PRIVATE_KEY))");
        console.log("");
        
        // PythPriceHook verification command
        console.log("3. Verify PythPriceHook:");
        console.log("forge verify-contract \\");
        console.log("  0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2 \\");
        console.log("  src/hooks/PythPriceHook.sol:PythPriceHook \\");
        console.log("  --chain-id 11155111 \\");
        console.log("  --rpc-url $SEPOLIA_RPC_URL \\");
        console.log("  --etherscan-api-key $ETHERSCAN_API_KEY \\");
        console.log("  --constructor-args $(cast abi-encode \"constructor(address)\" 0xDd24F84d36BF92C65F92307595335bdFab5Bbd21)");
        console.log("");
        
        console.log("=== Verification Commands Generated ===");
        console.log("Copy and run the commands above to verify each contract.");
    }
}

