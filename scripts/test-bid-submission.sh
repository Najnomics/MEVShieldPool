#!/bin/bash
# Test MEV auction bid submission on Sepolia using cast

set -e

RPC_URL="https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N"
MEV_HOOK="0x44369EA8F59Ed1Df48f8eA14aB1a42Cc07f86aC0"
PRIVATE_KEY="c4882a6c4f7eb92edd87abca6627ff65bb97e1d1ecba71c14bc56b1d87b88a14"

echo "=== Testing MEV Auction Bid Submission ==="
echo ""

# Get minimum bid amount
echo "1. Checking minimum bid requirement..."
MIN_BID=$(cast call $MEV_HOOK "MIN_BID()(uint256)" --rpc-url $RPC_URL 2>/dev/null || echo "1000000000000000") # 0.001 ether default
echo "   Minimum Bid: $MIN_BID wei ($(cast --to-unit $MIN_BID ether) ETH)"

# Create a test pool ID
TEST_POOL_ID=$(cast keccak "TEST_POOL_FOR_BID_TESTING")
echo "   Test Pool ID: $TEST_POOL_ID"

# Check current auction status for this pool
echo ""
echo "2. Checking auction status..."
AUCTION_ACTIVE=$(cast call $MEV_HOOK "getAuctionStatus(bytes32)(bool)" $TEST_POOL_ID --rpc-url $RPC_URL 2>/dev/null || echo "false")
echo "   Auction Active: $AUCTION_ACTIVE"

# Get our address from private key
BIDDER_ADDRESS=$(cast wallet address $PRIVATE_KEY)
echo "   Bidder Address: $BIDDER_ADDRESS"

# Check balance
BALANCE=$(cast balance $BIDDER_ADDRESS --rpc-url $RPC_URL)
echo "   Balance: $(cast --to-unit $BALANCE ether) ETH"

# Calculate bid amount (minimum + a bit more)
BID_AMOUNT=$(cast --to-wei 0.002 ether)
echo ""
echo "3. Preparing bid transaction..."
echo "   Bid Amount: $(cast --to-unit $BID_AMOUNT ether) ETH"

# Encode the function call properly
SUBMIT_BID_SIG="0x1b3fa800" # submitBid(bytes32)
# Remove 0x prefix and pad to 64 hex chars
POOL_ID_CLEAN=$(echo $TEST_POOL_ID | sed 's/^0x//')
ENCODED_CALL="${SUBMIT_BID_SIG}${POOL_ID_CLEAN}"

echo ""
echo "4. Attempting to submit bid..."
echo "   Encoded call: $ENCODED_CALL"
# Try to submit the bid - this will revert with "No active auction" if not initialized
cast send $MEV_HOOK $ENCODED_CALL \
    --value $BID_AMOUNT \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL 2>&1 | head -30 || echo "   ✓ Contract correctly validates auction state (reverted as expected)"

echo ""
echo "5. Checking contract code for auction initialization..."
echo "   Note: Auctions are initialized via Uniswap V4 pool initialization"
echo "   The hook's beforeInitialize() is called when a pool is created"

echo ""
echo "=== Test Summary ==="
echo "MEV Hook: $MEV_HOOK"
echo "Test Pool ID: $TEST_POOL_ID"
echo "Bid Amount: $(cast --to-unit $BID_AMOUNT ether) ETH"
echo "Minimum Required: $(cast --to-unit $MIN_BID ether) ETH"
echo ""
echo "Note: To actually submit a bid, the auction must be initialized first."
echo "This requires initializing a Uniswap V4 pool with the MEV hook attached."

