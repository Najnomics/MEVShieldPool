import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useAccount, usePublicClient, useWalletClient, useNetwork } from 'wagmi';
import { Contract, formatEther, parseEther, Address } from 'viem';
import { toast } from 'react-toastify';

// Contract ABIs and addresses
import { MEV_AUCTION_HOOK_ABI } from '../abis/MEVAuctionHook';
import { PYTH_PRICE_ORACLE_ABI } from '../abis/PythPriceOracle';
import { LIT_MPC_MANAGER_ABI } from '../abis/LitMPCManager';
import { YELLOW_STATE_CHANNEL_ABI } from '../abis/YellowStateChannel';
import { LIGHTHOUSE_STORAGE_ABI } from '../abis/LighthouseStorageManager';
import { BLOCKSCOUT_MANAGER_ABI } from '../abis/BlockscoutManager';

// Types
interface ContractAddresses {
  [chainId: number]: {
    mevAuctionHook: Address;
    pythPriceOracle: Address;
    litMPCManager: Address;
    yellowStateChannel: Address;
    lighthouseStorage: Address;
    blockscoutManager: Address;
  };
}

interface PoolData {
  poolId: string;
  token0: Address;
  token1: Address;
  fee: number;
  liquidity: bigint;
  tick: number;
  isActive: boolean;
}

interface AuctionData {
  auctionId: string;
  poolId: string;
  highestBid: bigint;
  highestBidder: Address;
  deadline: number;
  isActive: boolean;
  totalMEVCollected: bigint;
}

interface MEVMetrics {
  totalMEVPrevented: bigint;
  totalAuctions: number;
  averageAuctionTime: number;
  topPools: PoolData[];
}

interface Web3ContextType {
  // Connection state
  isConnected: boolean;
  address: Address | undefined;
  chainId: number | undefined;
  
  // Contract instances
  contracts: {
    mevAuctionHook: any;
    pythPriceOracle: any;
    litMPCManager: any;
    yellowStateChannel: any;
    lighthouseStorage: any;
    blockscoutManager: any;
  };
  
  // Pool management
  pools: PoolData[];
  activePools: PoolData[];
  
  // Auction data
  activeAuctions: AuctionData[];
  userBids: AuctionData[];
  
  // MEV metrics
  mevMetrics: MEVMetrics;
  
  // Functions
  submitBid: (poolId: string, amount: bigint, encrypted?: boolean) => Promise<string>;
  createPool: (token0: Address, token1: Address, fee: number) => Promise<string>;
  executeAuction: (auctionId: string) => Promise<boolean>;
  getPriceData: (priceId: string) => Promise<any>;
  uploadToLighthouse: (data: Uint8Array, encrypted?: boolean) => Promise<string>;
  deployBlockscoutExplorer: (config: any) => Promise<string>;
  refreshData: () => Promise<void>;
  
  // Loading states
  isLoading: boolean;
  isSubmittingBid: boolean;
  isCreatingPool: boolean;
}

const Web3Context = createContext<Web3ContextType | undefined>(undefined);

// Contract addresses for different chains
const CONTRACT_ADDRESSES: ContractAddresses = {
  1: { // Ethereum Mainnet
    mevAuctionHook: '0x0000000000000000000000000000000000000000' as Address,
    pythPriceOracle: '0x0000000000000000000000000000000000000000' as Address,
    litMPCManager: '0x0000000000000000000000000000000000000000' as Address,
    yellowStateChannel: '0x0000000000000000000000000000000000000000' as Address,
    lighthouseStorage: '0x0000000000000000000000000000000000000000' as Address,
    blockscoutManager: '0x0000000000000000000000000000000000000000' as Address,
  },
  137: { // Polygon
    mevAuctionHook: '0x0000000000000000000000000000000000000000' as Address,
    pythPriceOracle: '0x0000000000000000000000000000000000000000' as Address,
    litMPCManager: '0x0000000000000000000000000000000000000000' as Address,
    yellowStateChannel: '0x0000000000000000000000000000000000000000' as Address,
    lighthouseStorage: '0x0000000000000000000000000000000000000000' as Address,
    blockscoutManager: '0x0000000000000000000000000000000000000000' as Address,
  },
  42161: { // Arbitrum One
    mevAuctionHook: '0x0000000000000000000000000000000000000000' as Address,
    pythPriceOracle: '0x0000000000000000000000000000000000000000' as Address,
    litMPCManager: '0x0000000000000000000000000000000000000000' as Address,
    yellowStateChannel: '0x0000000000000000000000000000000000000000' as Address,
    lighthouseStorage: '0x0000000000000000000000000000000000000000' as Address,
    blockscoutManager: '0x0000000000000000000000000000000000000000' as Address,
  },
};

export const Web3Provider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const { address, isConnected } = useAccount();
  const { chain } = useNetwork();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  // State
  const [pools, setPools] = useState<PoolData[]>([]);
  const [activeAuctions, setActiveAuctions] = useState<AuctionData[]>([]);
  const [userBids, setUserBids] = useState<AuctionData[]>([]);
  const [mevMetrics, setMevMetrics] = useState<MEVMetrics>({
    totalMEVPrevented: 0n,
    totalAuctions: 0,
    averageAuctionTime: 0,
    topPools: [],
  });
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmittingBid, setIsSubmittingBid] = useState(false);
  const [isCreatingPool, setIsCreatingPool] = useState(false);

  // Contract instances
  const contracts = React.useMemo(() => {
    if (!chain?.id || !CONTRACT_ADDRESSES[chain.id]) {
      return {
        mevAuctionHook: null,
        pythPriceOracle: null,
        litMPCManager: null,
        yellowStateChannel: null,
        lighthouseStorage: null,
        blockscoutManager: null,
      };
    }

    const addresses = CONTRACT_ADDRESSES[chain.id];
    
    return {
      mevAuctionHook: {
        address: addresses.mevAuctionHook,
        abi: MEV_AUCTION_HOOK_ABI,
      },
      pythPriceOracle: {
        address: addresses.pythPriceOracle,
        abi: PYTH_PRICE_ORACLE_ABI,
      },
      litMPCManager: {
        address: addresses.litMPCManager,
        abi: LIT_MPC_MANAGER_ABI,
      },
      yellowStateChannel: {
        address: addresses.yellowStateChannel,
        abi: YELLOW_STATE_CHANNEL_ABI,
      },
      lighthouseStorage: {
        address: addresses.lighthouseStorage,
        abi: LIGHTHOUSE_STORAGE_ABI,
      },
      blockscoutManager: {
        address: addresses.blockscoutManager,
        abi: BLOCKSCOUT_MANAGER_ABI,
      },
    };
  }, [chain?.id]);