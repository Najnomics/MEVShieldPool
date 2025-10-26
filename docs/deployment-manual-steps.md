# Manual Deployment Steps for MEVAuctionHook

## Issue
The deployment script keeps hitting TLS/proxy errors, preventing successful deployment to Sepolia.

## Hook Address (from simulation)
- **Target Address**: `0xB511417B2D983e6A86dff5663A08d01462036aC0`
- **Salt**: `0x00000000000000000000000000000000000000000000000000000000000062ae`
- **Permissions**: beforeInitialize, beforeAddLiquidity, beforeRemoveLiquidity, beforeSwap, afterSwap

## Deployment Options

### Option 1: Deploy via Foundry (from Linux/Docker)
```bash
cd /Users/najnomics/october/MEVShieldPool
forge script script/DeployMEVAuctionHook.s.sol:DeployMEVAuctionHook \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N \
  --private-key c4882a6c4f7eb92edd87abca6627ff65bb97e1d1ecba71c14bc56b1d87b88a14 \
  --broadcast -vv
```

### Option 2: Deploy via Etherscan Broadcast TXN
1. Get deployment bytecode:
   ```bash
   forge inspect src/hooks/MEVAuctionHook.sol:MEVAuctionHook bytecode > hook_bytecode.txt
   ```

2. Get constructor args:
   ```bash
   cast calldata "constructor(address,address,address)" \
     0xE03A1074c86CFeDd5C142C4F04F1a1536e203543 \
     0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7 \
     0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2
   ```

3. Combine bytecode + constructor args
4. Use Etherscan "Broadcast TXN" tool or cast send

### Option 3: Use create2factory directly
The script calculated these values:
- Salt: `0x00000000000000000000000000000000000000000000000000000000000062ae`
- CREATE2 Factory: `0x4e59b44847b379578588920cA78FbF26c0B4956C`

## After Deployment

### 1. Verify Contract Code
```bash
cast code 0xB511417B2D983e6A86dff5663A08d01462036aC0 \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N
```

### 2. Verify PoolManager
```bash
cast call 0xB511417B2D983e6A86dff5663A08d01462036aC0 \
  "poolManager()(address)" \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N
```
Should return: `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543`

### 3. Verify Contract on Etherscan
```bash
forge verify-contract 0xB511417B2D983e6A86dff5663A08d01462036aC0 \
  src/hooks/MEVAuctionHook.sol:MEVAuctionHook \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" \
    0xE03A1074c86CFeDd5C142C4F04F1a1536e203543 \
    0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7 \
    0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2) \
  --etherscan-api-key ZWEHBPN2B5DY8DAISHIUQ7PRMMPFENTGXS \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N \
  --chain sepolia
```

### 4. Update Configuration
```bash
# Update .env
sed -i.bak 's/MEV_AUCTION_HOOK=.*/MEV_AUCTION_HOOK=0xB511417B2D983e6A86dff5663A08d01462036aC0/' .env

# Update InitializePoolWithTokens.s.sol (already done)
```

### 5. Initialize Pool
```bash
forge script script/InitializePoolWithTokens.s.sol:InitializePoolWithTokens \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N \
  --private-key c4882a6c4f7eb92edd87abca6627ff65bb97e1d1ecba71c14bc56b1d87b88a14 \
  --broadcast -vv
```

### 6. Submit Bid
```bash
# Get Pool ID from initialization logs (e.g., 34229472685399027887349370470681606596695199796966705095526113066254675628314)
POOL_ID="0x$(printf '%064x' 34229472685399027887349370470681606596695199796966705095526113066254675628314)"
BID_WEI=$(cast --to-wei 0.002 ether)

cast send 0xB511417B2D983e6A86dff5663A08d01462036aC0 \
  "submitBid(bytes32)" $POOL_ID \
  --value $BID_WEI \
  --private-key c4882a6c4f7eb92edd87abca6627ff65bb97e1d1ecba71c14bc56b1d87b88a14 \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N -vv
```

## Summary
- ✅ Code ready and correct
- ✅ BaseHook fixed
- ✅ Hook address calculated: `0xB511417B2D983e6A86dff5663A08d01462036aC0`
- ⏳ Deployment blocked by TLS/proxy issues on macOS
- ⏳ Need to deploy via alternative method or different machine

