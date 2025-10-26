# Manual Hook Deployment Instructions

## Issue
Foundry is crashing with "Attempted to create a NULL object" error when trying to deploy to Sepolia. This is a known Foundry bug on macOS related to proxy detection.

## Solution
Deploy manually using cast or by running forge on a different machine.

## Hook Address (from simulation)
The new hook will be deployed at: `0xB511417B2D983e6A86dff5663A08d01462036aC0`

## Manual Deployment Steps

### Option 1: Deploy with cast (recommended)
```bash
# 1. Get the contract bytecode
forge inspect src/hooks/MEVAuctionHook.sol:MEVAuctionHook bytecode > /tmp/hook_bytecode.txt

# 2. Get constructor arguments (PoolManager address)
# PoolManager: 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
# Encoded: 0x000000000000000000000000E03A1074c86CFeDd5C142C4F04F1a1536e203543

# 3. Deploy via CREATE2 Deployer
# Salt: 0x00000000000000000000000000000000000000000000000000000000000034ae
# CREATE2 Deployer: 0x4e59b44847b379578588920cA78FbF26c0B4956C

cast send 0x4e59b44847b379578588920cA78FbF26c0B4956C \
  "deploy(uint256,bytes32)" \
  0 \
  "0x$(cat /tmp/hook_bytecode.txt)000000000000000000000000E03A1074c86CFeDd5C142C4F04F1a1536e203543" \
  --value 0 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### Option 2: Try on a different machine
Run the deployment script on a Linux machine or in a Docker container:
```bash
forge script script/DeployMEVAuctionHook.s.sol:DeployMEVAuctionHook \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N \
  --private-key <YOUR_KEY> \
  --broadcast
```

### Option 3: Temporarily disable proxy detection
```bash
export NO_PROXY="*"
export HTTPS_PROXY=""
export HTTP_PROXY=""
export ALL_PROXY=""

forge script script/DeployMEVAuctionHook.s.sol:DeployMEVAuctionHook \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N \
  --private-key <YOUR_KEY> \
  --broadcast
```

## After Deployment
1. Update `.env` with new hook address
2. Update `script/InitializePoolWithTokens.s.sol` with new address
3. Initialize pool: `forge script script/InitializePoolWithTokens.s.sol --broadcast --rpc-url $RPC_URL --private-key $PRIVATE_KEY`
4. Submit bid with cast using the pool initialization script

## Summary
- ✅ BaseHook fixed (switched to @openzeppelin/uniswap-hooks)
- ✅ Build successful
- ✅ Local simulation successful
- ⚠️  Foundry deployment blocked by macOS proxy bug
- 🔧 Manual deployment required

