# MEVShield Pool Frontend

React frontend for the MEVShield Pool dApp, connected to deployed Sepolia contracts.

## Features

- 🔗 **Wallet Connection**: RainbowKit integration for MetaMask, WalletConnect, and more
- 💰 **MEV Auctions**: Submit bids to active MEV auctions
- 📊 **Dashboard**: Real-time MEV metrics and analytics
- 🏊 **Pool Management**: View and manage Uniswap V4 pools
- 🔒 **Privacy**: Optional encrypted bid submission via Lit Protocol

## Setup

```bash
cd frontend
npm install
npm start
```

## Configuration

Contract addresses are configured in `src/config/contracts.ts`:
- MEVAuctionHook: `0xB511417B2D983e6A86dff5663A08d01462036aC0`
- Sepolia Testnet (Chain ID: 11155111)

## Known Pools

The frontend is pre-configured with the initialized pool:
- Pool ID: `26282756708538069910862534158750760320053768499940364003422645886916113207248`
- Token Pair: TokenA / TokenB
- Fee: 0.3%

## Usage

1. **Connect Wallet**: Click "Connect Wallet" button (top right)
2. **View Auctions**: Navigate to "MEV Auctions" to see active auctions
3. **Submit Bid**: Select a pool, enter bid amount (min 0.001 ETH), and submit
4. **Monitor**: Track your bids and auction status in real-time

## Development

The frontend uses:
- React 18 with TypeScript
- Wagmi v2 for Ethereum interactions
- RainbowKit for wallet connections
- Viem for contract encoding/decoding
- Tailwind CSS for styling

## Contract Integration

All contract interactions are handled through:
- `src/hooks/useMEVAuction.ts` - Main hook for auction operations
- `src/config/contracts.ts` - Contract addresses and configuration
- `src/abis/MEVAuctionHook.ts` - Contract ABI

