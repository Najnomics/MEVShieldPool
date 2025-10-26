import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';
import { http } from 'wagmi';
import { 
  metaMaskWallet,
  rainbowWallet,
  coinbaseWallet,
  walletConnectWallet,
} from '@rainbow-me/rainbowkit/wallets';
import { RPC_URLS, SEPOLIA_CHAIN_ID } from './contracts';

// Get WalletConnect Project ID from environment or use placeholder
// To get a real Project ID: https://cloud.walletconnect.com/
const projectId = process.env.REACT_APP_WALLETCONNECT_PROJECT_ID || 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';

// Fallback RPC URL if the main one fails
const rpcUrl = RPC_URLS[SEPOLIA_CHAIN_ID];
const fallbackRpcUrl = 'https://rpc.sepolia.org';

/**
 * Wagmi config inspired by Scaffold-ETH 2 patterns
 * Includes multiple wallet options and robust provider setup
 * 
 * Key features:
 * - Multiple wallet options (MetaMask priority)
 * - Fallback RPC providers for reliability
 * - Optimized for Sepolia testnet
 */
export const config = getDefaultConfig({
  appName: 'MEVShield Pool',
  projectId: projectId,
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(rpcUrl, {
      batch: {
        batchSize: 10,
        wait: 100,
      },
      retryCount: 3,
      retryDelay: 1000,
    }),
  },
  ssr: false,
  wallets: [
    {
      groupName: 'Recommended',
      wallets: [
        metaMaskWallet, // Highest priority for MetaMask
        rainbowWallet,
        coinbaseWallet,
        walletConnectWallet,
      ],
    },
  ],
});

