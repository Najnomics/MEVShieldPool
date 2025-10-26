## Sepolia Testnet Deployment Guide

This guide describes how to deploy MEVShield Pool components to Sepolia using Foundry.

### Prerequisites

- Foundry installed (`foundryup`)
- Funded Sepolia deployer key
- RPC URL (Alchemy/Infura/etc.)
- Pyth v2 EVM contract address on Sepolia

### Environment

Create `.env` with:

```
SEPOLIA_RPC_URL=https://eth-sepolia.example
PRIVATE_KEY=0x...
PYTH_CONTRACT=0xDd24F84d36BF92C65F92307595335bdFab5Bbd21 # Example; verify from Pyth docs
```

Notes:
- Verify the Pyth contract address from official docs: https://pyth.network/developers
- Price IDs (e.g. ETH/USD) are chain-agnostic; example ETH/USD:
  - `0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace`

### Build

```
forge build
```

### Deploy

```
forge script script/DeployMEVAuctionHook.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast && \
forge script script/DeploySupportingContracts.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --sig "run()"
```

The script deploys:
- LitEncryptionHook (MPC-only path)
- PythPriceHook (configured with `PYTH_CONTRACT`)
- YellowNetworkChannel (state channel)
- MEVAuctionHook (main contract) – uses IPythPriceOracle interface

### Uniswap V4 Hook Address (Important)

Uniswap V4 hooks require specific deployment addresses (CREATE2 and flags). For production-like deployment:
- Use the official `v4-template` and Hook Deployer tooling.
- Ensure your hook address satisfies the Uniswap v4 hook address mask.
- Reference: https://docs.uniswap.org/contracts/v4/guides/hooks/your-first-hook

For local testing, this repo uses a test-double in unit tests; integration on Sepolia should use the real hook deploy flow.

### Pyth Updates On-Chain

To update price feeds:

```
# Call PythPriceOracle.updatePriceFeeds with received updateData
# Ensure to send the exact fee (getUpdateFee)
```

### Verification & Ops

- Record deployed addresses and verify code if needed.
- Set alerting for:
  - Hook events (HookSwap/MEVDetected)
  - Channel disputes/closures
  - Pyth update errors


