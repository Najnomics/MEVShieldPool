# WalletConnect Setup Instructions

## Why You Need a WalletConnect Project ID

RainbowKit uses WalletConnect for wallet connections. The 403 error you're seeing means the placeholder Project ID is invalid.

## Quick Fix - Get a Real Project ID

1. **Go to WalletConnect Cloud**: https://cloud.walletconnect.com/
2. **Sign up/Login** (use GitHub, Google, or email)
3. **Create a new project**:
   - Click "Create New Project"
   - Name it "MEVShield Pool" or similar
   - Copy the Project ID (long string of letters/numbers)
4. **Add to your environment**:
   - Create/edit `.env` file in the `frontend` directory
   - Add: `REACT_APP_WALLETCONNECT_PROJECT_ID=your_project_id_here`
   - Restart the dev server

## Alternative: Use Without WalletConnect

If you want to test with MetaMask only (no WalletConnect), you can modify the config to skip WalletConnect initialization. However, RainbowKit works best with a valid Project ID.

## Current Status

The app will work with MetaMask even with the 403 error (it just won't support WalletConnect wallets). The TypeScript errors have been fixed, so the app should compile now.

## Test MetaMask Connection

1. Make sure MetaMask is installed and unlocked
2. Switch to Sepolia Testnet in MetaMask
3. Click "Connect Wallet" in the app
4. MetaMask should prompt you to connect (even with the 403 error)

