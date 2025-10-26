#!/bin/bash
# Submit MEV auction bid using cast with the correct hook and pool

set -e

RPC_URL="https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N"
MEV_HOOK="0x6e5D7D71E5e2AEeE0FE6CB88eb1c525A64AcAac0"
PRIVATE_KEY="c4882a6c4f7eb92edd87abca6627ff65bb97e1d1ecba71c14bc56b1d87b88a14"

# Pool ID from initialization attempt
POOL_ID="88673380286223871183719623224819725015369975901139241117826301322969024774079"
BID_AMOUNT=$(cast --to-wei 0.002 ether)

echo "=== Submitting MEV Auction Bid ==="
echo "Hook: $MEV_HOOK"
echo "Pool ID: $POOL_ID"
echo "Bid Amount: $(cast --to-unit $BID_AMOUNT ether) ETH"
echo ""

# Convert pool ID to hex (remove 0x if present, pad to 64 chars)
POOL_ID_HEX=$(printf "%064x" $POOL_ID)

# Function signature: submitBid(bytes32)
SUBMIT_SIG="0x1b3fa800"
ENCODED_CALL="${SUBMIT_SIG}${POOL_ID_HEX}"

echo "Encoded call: $ENCODED_CALL"
echo ""

# Submit the bid
cast send $MEV_HOOK $ENCODED_CALL \
    --value $BID_AMOUNT \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL \
    --gas-limit 500000 \
    -vv

echo ""
echo "=== Bid Submitted Successfully ==="

