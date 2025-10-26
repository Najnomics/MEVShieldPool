# Etherscan Contract Verification Guide

## Overview

Verifying contracts on Etherscan allows anyone to:
- View and interact with your contract source code
- Debug transactions more easily
- Build trust with users
- Use Etherscan's built-in contract interaction tools

## Getting Your Etherscan API Key

### Step 1: Create Etherscan Account

1. Go to [Etherscan.io](https://etherscan.io/)
2. Click "Sign Up" or "Login" (top right)
3. Create a free account

### Step 2: Generate API Key

1. Log in to Etherscan
2. Go to [API-KEYs](https://etherscan.io/myapikey)
3. Click "Add" to create a new API key
4. Name it (e.g., "MEVShield Pool - Sepolia")
5. Copy the API key (starts with `...`)

**Important:** Different networks have different Etherscan explorers:
- **Sepolia**: [sepolia.etherscan.io](https://sepolia.etherscan.io) → Use Sepolia API key
- **Mainnet**: [etherscan.io](https://etherscan.io) → Use mainnet API key

## Adding API Key to .env

Add your Etherscan API key to your `.env` file:

```bash
# Etherscan API Key for Contract Verification
ETHERSCAN_API_KEY=your_api_key_here

# Sepolia-specific (if different)
SEPOLIA_ETHERSCAN_API_KEY=your_sepolia_api_key_here
```

## Verifying Contracts with Foundry

### Single Contract Verification

For `MEVAuctionHook`:

```bash
forge verify-contract \
  0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0 \
  src/hooks/MEVAuctionHook.sol:MEVAuctionHook \
  --chain-id 11155111 \
  --rpc-url $SEPOLIA_RPC_URL \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" \
    0x000000000004444c5dc75cB358380D2e3dE08A90 \
    0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7 \
    0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2)
```

### Simplified Verification (If TLS Errors)

If you're still experiencing TLS errors, use `--skip-simulation`:

```bash
forge verify-contract \
  0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0 \
  src/hooks/MEVAuctionHook.sol:MEVAuctionHook \
  --chain-id 11155111 \
  --rpc-url $SEPOLIA_RPC_URL \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --skip-simulation \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" \
    0x000000000004444c5dc75cB358380D2e3dE08A90 \
    0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7 \
    0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2)
```

### Verify All Contracts

Create a verification script (`script/Verify.s.sol`):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script";

contract Verify is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address mevHook = 0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0;
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Verification happens automatically after broadcast
        // Or use: forge verify-contract with --watch flag
        
        vm.stopBroadcast();
    }
}
```

Then run:

```bash
forge script script/Verify.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## Manual Verification (Alternative)

If automated verification fails, you can verify manually:

### Step 1: Get Constructor Arguments

```bash
cast abi-encode "constructor(address,address,address)" \
  0x000000000004444c5dc75cB358380D2e3dE08A90 \
  0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7 \
  0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2
```

### Step 2: Go to Etherscan

1. Visit: https://sepolia.etherscan.io/address/0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0
2. Click "Contract" tab
3. Click "Verify and Publish"
4. Select:
   - Compiler: `v0.8.26`
   - License: `MIT`
   - Optimization: `Yes` (with 200 runs, via-ir enabled)
5. Paste your contract source code
6. Paste constructor arguments from Step 1
7. Submit

## Troubleshooting

### "Invalid API Key"
- Double-check the API key in `.env`
- Ensure you're using the correct network's API key
- Verify the API key is active on Etherscan

### "Constructor Arguments Mismatch"
- Verify constructor arguments match exactly
- Use `cast abi-encode` to generate correct encoding
- Check contract deployment logs for actual args

### "Contract Already Verified"
- Contract is already verified, no action needed
- View verified contract at Etherscan URL

### TLS Errors During Verification
- Use `--skip-simulation` flag
- Try manual verification via browser
- Check network connectivity

## Post-Verification

Once verified, you can:
- View full source code on Etherscan
- Interact with contract via Etherscan UI
- Debug transactions more easily
- Share verified contract URL with users

## Example: Verified Contract URLs

After verification, your contracts will be available at:

- **MEVAuctionHook**: https://sepolia.etherscan.io/address/0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0#code
- **LitEncryptionHook**: https://sepolia.etherscan.io/address/0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7#code
- **PythPriceHook**: https://sepolia.etherscan.io/address/0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2#code

## API Key Limits

Free Etherscan API keys have rate limits:
- **5 calls/second** for contract verification
- **No daily limit** for verification (unlimited)

For production/automation, consider upgrading to a paid plan if needed.

