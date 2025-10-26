#!/bin/bash
# Initialize a Uniswap V4 pool with MEV hook attached

set -e

RPC_URL="https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N"
POOL_MANAGER="0xE03A1074c86CFeDd5C142C4F04F1a1536e203543"
MEV_HOOK="0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0"
PRIVATE_KEY="c4882a6c4f7eb92edd87abca6627ff65bb97e1d1ecba71c14bc56b1d87b88a14"

echo "=== Initializing Uniswap V4 Pool with MEV Hook ==="
echo ""

# Get addresses
BIDDER_ADDRESS=$(cast wallet address $PRIVATE_KEY)
echo "1. Account Information:"
echo "   Address: $BIDDER_ADDRESS"
BALANCE=$(cast balance $BIDDER_ADDRESS --rpc-url $RPC_URL)
echo "   Balance: $(cast --to-unit $BALANCE ether) ETH"

echo ""
echo "2. Pool Configuration:"
echo "   PoolManager: $POOL_MANAGER"
echo "   MEV Hook: $MEV_HOOK"

# Check hook permissions
HOOK_PERMS=$(cast call $MEV_HOOK "getHookPermissions()(uint16)" --rpc-url $RPC_URL)
echo "   Hook Permissions: $HOOK_PERMS"

# For testing, we'll use common test tokens
# On Sepolia, we can use WETH9 or deploy test tokens
# For now, let's create a deterministic pool key
echo ""
echo "3. Creating Pool Key..."

# We need to construct a PoolKey struct:
# - currency0: Currency address
# - currency1: Currency address  
# - fee: uint24
# - tickSpacing: int24
# - hooks: IHooks address

# Use WETH9 on Sepolia: 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14
# Or use a simple test token pattern
CURRENCY0="0xfff9976782d46cc05630d1f6ebab18b2324d6b14" # WETH9 Sepolia
CURRENCY1="0x0000000000000000000000000000000000000001" # Placeholder - would need actual token
FEE="3000" # 0.3% fee (3000 = 0.3%)
TICK_SPACING="60"

echo "   Currency0: $CURRENCY0"
echo "   Currency1: $CURRENCY1 (test token - would need actual address)"
echo "   Fee: $FEE (0.3%)"
echo "   Tick Spacing: $TICK_SPACING"
echo "   Hooks: $MEV_HOOK"

echo ""
echo "4. Encoding Pool Key and Initialize Call..."

# Encode PoolKey struct: (address,address,uint24,int24,address)
# Then call PoolManager.initialize(PoolKey, sqrtPriceX96, bytes)

# PoolKey encoding: 
# - abi.encode(address currency0, address currency1, uint24 fee, int24 tickSpacing, address hooks)
POOL_KEY_ENCODED=$(cast abi-encode "f(address,address,uint24,int24,address)" \
    $CURRENCY0 $CURRENCY1 $FEE $TICK_SPACING $MEV_HOOK)

# sqrtPriceX96 - for a simple test, use sqrt(1) * 2^96
# sqrt(1) * 2^96 = 2^96 = 79228162514264337593543950336
SQRT_PRICE_X96="79228162514264337593543950336"

# PoolManager.initialize function signature
INITIALIZE_SIG=$(cast sig "initialize((address,address,uint24,int24,address),uint160,bytes)")

echo ""
echo "5. Attempting to initialize pool..."
echo "   ⚠️  Note: This requires actual token addresses and may need token approvals"
echo "   This is a test setup - production pools require proper token setup"

# Encode the full call
INITIALIZE_CALL=$(cast abi-encode "initialize((address,address,uint24,int24,address),uint160,bytes)" \
    $POOL_KEY_ENCODED $SQRT_PRICE_X96 "0x")

echo ""
echo "=== Summary ==="
echo "To initialize a pool, you need:"
echo "1. Two valid token addresses (Currency0 and Currency1)"
echo "2. Call PoolManager.initialize(PoolKey, sqrtPriceX96, bytes)"
echo "3. The hook's beforeInitialize() will be called automatically"
echo ""
echo "After initialization, the auction will be active and you can submit bids!"
echo ""
echo "For a complete test, deploy test tokens first or use existing Sepolia tokens:"
echo "- WETH9: 0xfff9976782d46cc05630d1f6ebab18b2324d6b14"
echo "- USDC: Check Sepolia token list"

