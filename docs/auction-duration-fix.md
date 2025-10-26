# Auction Duration Fix

## Issue
Auctions were expiring too quickly (12 seconds), making it impossible to submit bids after pool initialization.

## Root Cause
The `AUCTION_DURATION` constant in `src/libraries/AuctionLib.sol` was set to `12 seconds`, which is insufficient for searchers to:
1. Analyze MEV opportunities
2. Prepare bids
3. Submit transactions

## Solution
Increased auction duration from `12 seconds` to `5 minutes` (300 seconds).

## Changes Made

### Code Update
```solidity
// Before
uint256 public constant AUCTION_DURATION = 12 seconds;

// After
uint256 public constant AUCTION_DURATION = 5 minutes; // Reasonable duration for searchers to submit bids
```

### Redeployment
- **New Hook Address**: `0xB511417B2D983e6A86dff5663A08d01462036aC0`
- **Deployment Transaction**: Successful
- **Verification**: Submitted to Etherscan
- **Pool Initialized**: Pool ID `26282756708538069910862534158750760320053768499940364003422645886916113207248`

## Testing
With the 5-minute duration, searchers now have sufficient time to:
- Monitor pool state
- Calculate optimal bid amounts
- Submit bids before auction expiry

## Configuration Updated
- ✅ `.env` - Updated hook address
- ✅ `README.md` - Updated deployment table
- ✅ `script/InitializePoolWithTokens.s.sol` - Updated hook address
- ✅ New pool initialized with 5-minute auction duration

## Next Steps
Future pools initialized with this hook will automatically use the 5-minute auction duration, providing a more realistic bidding window for searchers.

