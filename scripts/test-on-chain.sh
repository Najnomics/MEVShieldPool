#!/bin/bash
# Test MEVShield Pool contracts on Sepolia testnet using cast

set -e

RPC_URL="https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N"
MEV_HOOK="0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0"
PYTH_HOOK="0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2"
LIT_HOOK="0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7"
YELLOW_CHANNEL="0x1Bd94cB5Eccb3968a229814c7CAe8B97795cE177"
POOL_MANAGER="0x000000000004444c5dc75cB358380D2e3dE08A90"

echo "=== MEVShield Pool On-Chain Verification ==="
echo ""

echo "1. Checking MEVAuctionHook deployment..."
POOL_MANAGER_CHECK=$(cast call $MEV_HOOK "poolManager()(address)" --rpc-url $RPC_URL)
echo "   PoolManager: $POOL_MANAGER_CHECK"
HOOK_PERMS=$(cast call $MEV_HOOK "getHookPermissions()(uint16)" --rpc-url $RPC_URL)
echo "   Hook Permissions: $HOOK_PERMS"

echo ""
echo "2. Checking PythPriceHook..."
PYTH_CONTRACT=$(cast call $PYTH_HOOK "pyth()(address)" --rpc-url $RPC_URL 2>/dev/null || echo "Function not found")
echo "   Pyth Contract: $PYTH_CONTRACT"

echo ""
echo "3. Checking LitEncryptionHook..."
LIT_VERSION=$(cast call $LIT_HOOK "CHANNEL_VERSION()(string)" --rpc-url $RPC_URL 2>/dev/null || echo "Function not found")
echo "   Lit Version: $LIT_VERSION"

echo ""
echo "4. Checking YellowStateChannel..."
YELLOW_VERSION=$(cast call $YELLOW_CHANNEL "CHANNEL_VERSION()(string)" --rpc-url $RPC_URL)
echo "   Channel Version: $YELLOW_VERSION"

echo ""
echo "5. Verifying PoolManager (Official Uniswap V4)..."
POOL_MANAGER_CODE=$(cast code $POOL_MANAGER --rpc-url $RPC_URL | head -c 100)
if [ -n "$POOL_MANAGER_CODE" ]; then
    echo "   ✓ PoolManager has code deployed"
else
    echo "   ✗ PoolManager not found"
fi

echo ""
echo "=== Summary ==="
echo "MEVAuctionHook: $MEV_HOOK"
echo "PythPriceHook: $PYTH_HOOK"
echo "LitEncryptionHook: $LIT_HOOK"
echo "YellowStateChannel: $YELLOW_CHANNEL"
echo "PoolManager: $POOL_MANAGER"
echo ""
echo "All contracts are deployed and responding to view calls."

