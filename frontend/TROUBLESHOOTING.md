# Frontend Troubleshooting Guide

## MetaMask Connection Issues

If MetaMask is not connecting, try these steps:

### 1. Check Browser Console
Open Chrome DevTools (F12) and check the Console tab for errors.

### 2. Verify MetaMask is Installed
- Make sure MetaMask extension is installed and enabled
- Unlock MetaMask with your password
- Make sure you're using Chrome/Firefox/Brave (Safari has limited support)

### 3. Check Network Configuration
- MetaMask should be connected to **Sepolia Testnet**
- If not, switch networks in MetaMask: Settings → Networks → Add Network
- Sepolia Network Details:
  - Network Name: Sepolia
  - RPC URL: https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
  - Chain ID: 11155111
  - Currency Symbol: ETH

### 4. Clear Browser Cache
1. Open Chrome DevTools (F12)
2. Right-click the refresh button
3. Select "Empty Cache and Hard Reload"

### 5. Reset MetaMask Connection
1. In MetaMask, go to Settings → Advanced
2. Click "Reset Account" (this won't delete your account, just clears site connections)
3. Refresh the page and try connecting again

### 6. Check WalletConnect Project ID
If you're still having issues, you may need a proper WalletConnect Project ID:
1. Go to https://cloud.walletconnect.com/
2. Create a new project
3. Copy the Project ID
4. Update `frontend/src/config/wagmi.ts` with the real Project ID

### 7. Common Errors

**Error: "User rejected the request"**
- You clicked "Reject" in MetaMask - try connecting again and click "Approve"

**Error: "MetaMask connection failed"**
- Make sure MetaMask is unlocked
- Try disabling other browser extensions temporarily
- Check if MetaMask has permission to access the site

**Error: "Unsupported network"**
- Switch MetaMask to Sepolia Testnet before connecting

## Development Server Issues

### Server won't start
```bash
cd frontend
ulimit -n 10240
npm install --legacy-peer-deps
PORT=3001 npm start
```

### TypeScript Compilation Errors
The code should now compile correctly. If you see errors:
1. Stop the server (Ctrl+C)
2. Delete `node_modules` and `package-lock.json`
3. Run `npm install --legacy-peer-deps` again
4. Restart the server

### Port Already in Use
```bash
# Kill process on port 3001
lsof -ti:3001 | xargs kill -9
```

## Testing Connection

After connecting:
1. You should see your wallet address in the top right
2. The "Connect Wallet" button should change to show your address
3. Clicking it should show a disconnect option
4. Dashboard should load MEV auction data

If you're still having issues, check the browser console for specific error messages.
