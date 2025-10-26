# Uniswap V4 Hook Deployment Guide

## Problem

Uniswap V4 hooks must be deployed at addresses where the low-order bits encode the hook's permissions. Regular contract deployment doesn't satisfy this requirement, causing `HookAddressNotValid` errors.

## Solution

Use `HookMiner` from `@uniswap/v4-periphery` to mine a CREATE2 salt that produces a valid hook address matching the permission flags.

## Deployment Steps

### 1. Already Deployed Contracts (Sepolia)

These contracts are already deployed and working:
- **PoolManager**: `0x000000000004444c5dc75cB358380D2e3dE08A90`
- **LitEncryptionHook**: `0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7`
- **PythPriceHook**: `0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2`
- **YellowStateChannel**: `0x1Bd94cB5Eccb3968a229814c7CAe8B97795cE177`

### 2. Deploy MEVAuctionHook with Correct Address

```bash
# Set environment variables
export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N"
export PRIVATE_KEY="c4882a6c4f7eb92edd87abca6627ff65bb97e1d1ecba71c14bc56b1d87b88a14"

# Deploy MEVAuctionHook using HookMiner
forge script script/DeployMEVAuctionHook.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
```

### 3. How It Works

The `DeployMEVAuctionHook.s.sol` script:

1. **Calculates permission flags** based on `getHookPermissions()`:
   - `BEFORE_INITIALIZE_FLAG`
   - `BEFORE_ADD_LIQUIDITY_FLAG`
   - `BEFORE_REMOVE_LIQUIDITY_FLAG`
   - `BEFORE_SWAP_FLAG`
   - `AFTER_SWAP_FLAG`

2. **Mines for valid address** using `HookMiner.find()`:
   - Uses CREATE2 Deployer Proxy: `0x4e59b44847b379578588920cA78FbF26c0B4956C`
   - Tests salts until one produces an address with matching low-order bits
   - Returns the `(hookAddress, salt)` pair

3. **Deploys via CREATE2**:
   ```solidity
   new MEVAuctionHook{salt: salt}(
       IPoolManager(POOL_MANAGER),
       ILitEncryption(LIT_ENCRYPTION),
       IPythPriceOracle(PYTH_PRICE_HOOK)
   )
   ```

4. **Verifies deployment**:
   - Confirms deployed address matches mined address
   - Verifies hook permissions are correct

### 4. Expected Output

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
MEVAuctionHook: 0x...
```

### 5. Next Steps

After successful deployment:

1. **Record the hook address** for pool initialization
2. **Initialize pools** with this hook address when creating V4 pools
3. **Test swap operations** to verify auction functionality

## Key Concepts

### Hook Address Validation

Uniswap V4 validates hook addresses by checking if the low-order 14 bits match the hook's declared permissions:

```solidity
// Hook address must have these bits set to match permissions
uint160(address(hook)) & Hooks.ALL_HOOK_MASK == flags
```

### CREATE2 Deterministic Deployment

- Uses a salt to compute a deterministic address
- `HookMiner` finds a salt that produces an address with correct flags
- The mined address can be verified before deployment

### Permission Flags

Each hook permission corresponds to a bit flag:
- `BEFORE_INITIALIZE_FLAG`: 0x1 << 159
- `BEFORE_ADD_LIQUIDITY_FLAG`: 0x1 << 155
- `BEFORE_REMOVE_LIQUIDITY_FLAG`: 0x1 << 155 (same bit, different phase)
- `BEFORE_SWAP_FLAG`: 0x1 << 157
- `AFTER_SWAP_FLAG`: 0x1 << 156

## Troubleshooting

### HookMiner fails to find salt

- Try increasing `MAX_LOOP` in HookMiner (default: 160,444)
- Ensure CREATE2 Deployer Proxy is available on the network
- Verify hook contract bytecode hasn't changed

### Address mismatch after deployment

- Ensure constructor arguments match exactly
- Check that `creationCode` includes all dependencies
- Verify CREATE2 Deployer Proxy is being used correctly

### Permission validation fails

- Double-check `getHookPermissions()` returns correct flags
- Verify permission flags are calculated correctly
- Ensure hook contract implements all declared hooks

## References

- [Uniswap V4 Hooks Documentation](https://docs.uniswap.org/sdk/v4/guides/hooks)
- [V4 Template Deployment](https://github.com/Uniswap/v4-template)
- [HookMiner Source](https://github.com/Uniswap/v4-periphery/blob/main/src/utils/HookMiner.sol)

