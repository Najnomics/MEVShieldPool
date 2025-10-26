# Redeployment Status

## Contract Deployment Status (Sepolia)

| Contract | Address | Status | Action Needed |
|----------|---------|--------|---------------|
| MEVAuctionHook | `0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0` | ✅ Deployed | None |
| YellowStateChannel | `0x1Bd94cB5Eccb3968a229814c7CAe8B97795cE177` | ✅ Deployed | None |
| LitEncryptionHook | `0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7` | ❌ Not Deployed | **Need to deploy** |
| PythPriceHook | `0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2` | ❌ Not Deployed | **Need to deploy** |

## Why Redeployment?

The addresses in `.env` were computed but never successfully broadcast due to TLS errors. The script found the correct addresses via CREATE2 determinism, but the actual transaction to deploy them failed.

## Deployment Options

### Option 1: Deploy with Fixed TLS Issues

Once TLS issues are resolved, run:

```bash
forge script script/DeploySupportingContracts.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

The addresses will match:
- LitEncryptionHook: `0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7`
- PythPriceHook: `0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2`

### Option 2: Manual Deployment via Wallet

If automated deployment continues to fail:

1. Use MetaMask or another wallet
2. Deploy the contracts with these constructor arguments:
   - **LitEncryptionHook**: `deployer address` (0xDABb1162402e3B56e7e7B86337f575F022587121)
   - **PythPriceHook**: `0xDd24F84d36BF92C65F92307595335bdFab5Bbd21`

### Option 3: Use Different RPC Provider

Try deploying with a different RPC endpoint:

```bash
# Public Sepolia RPC
export SEPOLIA_RPC_URL="https://rpc.sepolia.org"

# Or Infura
export SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/YOUR_KEY"
```

## Impact

The MEVAuctionHook is deployed and functional, but it references LitEncryptionHook and PythPriceHook in its constructor. Until these are deployed:

- ✅ Hook address is valid for pool initialization
- ❌ Encrypted bid functionality won't work
- ❌ Pyth price integration won't work

## Next Steps

1. Resolve TLS/network issues
2. Deploy LitEncryptionHook and PythPriceHook
3. Verify all contracts on Etherscan
4. Initialize V4 pools with MEVAuctionHook

