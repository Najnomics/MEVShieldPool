import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';
import { http } from 'wagmi';
import { RPC_URLS, SEPOLIA_CHAIN_ID } from './contracts';

export const config = getDefaultConfig({
  appName: 'MEVShield Pool',
  projectId: 'MEVShieldPool', // Replace with your WalletConnect project ID if needed
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(RPC_URLS[SEPOLIA_CHAIN_ID]),
  },
  ssr: false,
});

