# Pool Initialization Status

## Current Status

✅ **Test Tokens Deployed**
- TokenA: `0xe6ee6FBE2E0f047bd082a60d70FcDBF637eC3d38`
- TokenB: `0x3932ED745f6e348CcE56621c4ff9Da47Afbf7945`

✅ **MEV Hook Deployed**
- MEVAuctionHook: `0xB511417B2D983e6A86dff5663A08d01462036aC0`

⚠️ **PoolManager Issue**
- The PoolManager addresses in the README don't have code deployed
- `0x000000000004444c5dc75cB358380D2e3dE08A90` - No code
- `0x89169DeAE6C7E07A12De45B6198D4022e14527cC` - No code

## Next Steps

To initialize a pool with the MEV hook:

1. **Deploy PoolManager** or find the correct Uniswap V4 PoolManager address on Sepolia
2. Use the deployed test tokens
3. Initialize the pool using `script/InitializePoolWithTokens.s.sol`
4. Once initialized, the auction will be active and bids can be submitted

## Scripts Created

- `script/DeployTestTokens.s.sol` - Deploys test ERC20 tokens ✅
- `script/InitializePoolWithTokens.s.sol` - Initializes pool with tokens ⚠️ (needs PoolManager)

## Testing Bid Submission

Once a pool is initialized:

```bash
# Get the pool ID from initialization logs
POOL_ID="<pool_id_from_initialization>"

# Submit a bid
cast send 0xB511417B2D983e6A86dff5663A08d01462036aC0 \
  "submitBid(bytes32)" $POOL_ID \
  --value 0.002ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

