# Sepolia Deployment Summary

## Issue Fixed

The original deployment failed with `HookAddressNotValid` because `MEVAuctionHook` was deployed as a regular contract instead of using CREATE2 with address mining.

## Solution Implemented

Created `script/DeployMEVAuctionHook.s.sol` that uses `HookMiner` from `@uniswap/v4-periphery` to:
1. Mine a CREATE2 salt that produces a valid hook address
2. Deploy `MEVAuctionHook` at that address with correct permission flags encoded

## Already Deployed Contracts

These contracts are already on Sepolia and can be reused:

| Contract | Address | Status |
|----------|---------|--------|
| PoolManager | `0x000000000004444c5dc75cB358380D2e3dE08A90` | ✅ Deployed |
| LitEncryptionHook | `0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7` | ✅ Deployed |
| PythPriceHook | `0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2` | ✅ Deployed |
| YellowStateChannel | `0x1Bd94cB5Eccb3968a229814c7CAe8B97795cE177` | ✅ Deployed |

## Deploy MEVAuctionHook

Run the following command (fix TLS issues if needed):

```bash
export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N"
export PRIVATE_KEY="c4882a6c4f7eb92edd87abca6627ff65bb97e1d1ecba71c14bc56b1d87b88a14"

# Unset proxies to avoid TLS issues
unset HTTPS_PROXY HTTP_PROXY ALL_PROXY
export NO_PROXY="*"

# Deploy
forge script script/DeployMEVAuctionHook.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
```

## What the Script Does

1. **Calculates Permission Flags**:
   - `BEFORE_INITIALIZE_FLAG` (bit 13)
   - `BEFORE_ADD_LIQUIDITY_FLAG` (bit 11)
   - `BEFORE_REMOVE_LIQUIDITY_FLAG` (bit 9)
   - `BEFORE_SWAP_FLAG` (bit 7)
   - `AFTER_SWAP_FLAG` (bit 6)

2. **Mines Address**: Uses `HookMiner.find()` to search for a salt that produces an address with matching low-order bits

3. **Deploys via CREATE2**: Deploys `MEVAuctionHook` using the mined salt

4. **Verifies**: Confirms the deployed address matches the mined address and permissions are correct

## Expected Output

```
=== MEVAuctionHook V4 Deployment ===
Network: Sepolia Testnet
PoolManager: 0x000000000004444c5dc75cB358380D2e3dE08A90
LitEncryption: 0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7
PythPriceHook: 0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2

Mining for hook address with correct permissions...
Found hook address: 0x...
Salt: 0x...

MEVAuctionHook deployed successfully!
Address: 0x...

Hook Permissions:
- beforeInitialize: true
- beforeAddLiquidity: true
- beforeRemoveLiquidity: true
- beforeSwap: true
- afterSwap: true

=== Deployment Complete ===
```

## TLS Error Troubleshooting

If you encounter `BadRecordMac` errors:

1. **Disable proxies/VPN**: Unset HTTP/HTTPS proxy environment variables
2. **Check firewall**: Ensure no SSL inspection is interfering
3. **Try alternative RPC**: Use a different Sepolia RPC endpoint
4. **Update Foundry**: Run `foundryup` to get latest version
5. **Network check**: Verify internet connectivity to Sepolia

## Next Steps After Deployment

1. Record the deployed `MEVAuctionHook` address
2. Initialize a Uniswap V4 pool with this hook address
3. Test bid submission and swap operations
4. Verify MEV auction functionality end-to-end

## Files Created

- `script/DeployMEVAuctionHook.s.sol` - Proper V4 hook deployment script
- `docs/v4-hook-deployment.md` - Detailed deployment guide
- `docs/sepolia-deployment-summary.md` - This summary

## Key Concepts

### Hook Address Validation

Uniswap V4 validates hooks by checking if the low-order 14 bits of the hook address match the declared permissions. The `HookMiner` finds a CREATE2 salt that produces an address with the correct bits set.

### CREATE2 Deterministic Deployment

- Uses a salt to compute deterministic addresses
- Allows pre-computing the deployment address
- Verifies address matches before deployment

### Permission Encoding

Each hook permission is encoded as a bit flag in the address:
- Bit positions 0-13 encode hook permissions
- The hook address must have these bits set correctly
- Mining finds a salt that produces such an address

