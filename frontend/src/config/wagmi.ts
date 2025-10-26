import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';
import { http } from 'wagmi';
import { metaMaskWallet } from '@rainbow-me/rainbowkit/wallets';
import { RPC_URLS, SEPOLIA_CHAIN_ID } from './contracts';

// Get WalletConnect Project ID from environment or use placeholder
// To get a real Project ID: https://cloud.walletconnect.com/
const projectId = process.env.REACT_APP_WALLETCONNECT_PROJECT_ID || 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';

export const config = getDefaultConfig({
  appName: 'MEVShield Pool',
  projectId: projectId,
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(RPC_URLS[SEPOLIA_CHAIN_ID]),
  },
  ssr: false,
  wallets: [
    {
      groupName: 'Recommended',
      wallets: [metaMaskWallet],
    },
  ],
});

