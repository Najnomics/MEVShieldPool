import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { useAccount, usePublicClient, useChainId, useWriteContract } from 'wagmi';
import { Address } from 'viem';
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
  submitBid: (poolId: `0x${string}`, amount: bigint, encrypted?: boolean) => Promise<string>;
  createPool: (token0: Address, token1: Address, fee: number) => Promise<string>;
  executeAuction: (auctionId: string) => Promise<boolean>;
  getPriceData: (priceId: `0x${string}`) => Promise<any>;
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
  11155111: { // Sepolia
    mevAuctionHook: '0xB511417B2D983e6A86dff5663A08d01462036aC0' as Address,
    pythPriceOracle: '0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2' as Address,
    litMPCManager: '0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7' as Address,
    yellowStateChannel: '0x1Bd94cB5Eccb3968a229814c7CAe8B97795cE177' as Address,
    lighthouseStorage: '0x0000000000000000000000000000000000000000' as Address,
    blockscoutManager: '0x0000000000000000000000000000000000000000' as Address,
  },
};

export const Web3Provider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const publicClient = usePublicClient();
  const { writeContractAsync } = useWriteContract();

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
  const [isCreatingPool] = useState(false);

  // Contract instances
  const contracts = React.useMemo(() => {
    if (!chainId || !CONTRACT_ADDRESSES[chainId]) {
      return {
        mevAuctionHook: null,
        pythPriceOracle: null,
        litMPCManager: null,
        yellowStateChannel: null,
        lighthouseStorage: null,
        blockscoutManager: null,
      };
    }

    const addresses = CONTRACT_ADDRESSES[chainId];
    
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
  }, [chainId]);

  // Submit encrypted bid to MEV auction
  const submitBid = async (poolId: `0x${string}`, amount: bigint, _encrypted = false): Promise<string> => {
    if (!isConnected || !contracts.mevAuctionHook || !writeContractAsync) {
      throw new Error('Wallet not connected');
    }

    setIsSubmittingBid(true);
    try {
      // @ts-ignore - Wagmi v2 type inference issue
      const bidTx = await writeContractAsync({
        address: contracts.mevAuctionHook.address,
        abi: contracts.mevAuctionHook.abi,
        functionName: 'submitBid',
        args: [poolId],
        value: amount,
      });

      toast.success('Bid submitted successfully!');
      await refreshData();
      return bidTx;
    } catch (error) {
      console.error('Error submitting bid:', error);
      toast.error('Failed to submit bid');
      throw error;
    } finally {
      setIsSubmittingBid(false);
    }
  };

  // Create new liquidity pool
  const createPool = async (_token0: Address, _token1: Address, _fee: number): Promise<string> => {
    return Promise.reject(new Error('createPool not supported in this build'));
  };

  // Execute auction and settle bids
  const executeAuction = async (_auctionId: string): Promise<boolean> => {
    throw new Error('executeAuction not supported in this build');
  };

  // Get price data from Pyth Network
  const getPriceData = async (_priceId: `0x${string}`): Promise<any> => {
    if (!publicClient || !contracts.pythPriceOracle) {
      throw new Error('Client not available');
    }

    // Price read disabled in demo build
    return null;
  };

  // Upload data to Lighthouse Storage
  const uploadToLighthouse = async (_data: Uint8Array, _encrypted = false): Promise<string> => {
    throw new Error('uploadToLighthouse not supported in this build');
  };

  // Deploy Blockscout explorer
  const deployBlockscoutExplorer = async (_config: any): Promise<string> => {
    throw new Error('deployBlockscoutExplorer not supported in this build');
  };

  // Refresh all data from contracts
  const refreshData = async (): Promise<void> => {
    if (!publicClient || !isConnected) return;
    setIsLoading(true);
    try {
      // Minimal refresh; detailed reads removed in demo build
      setPools([]);
      setActiveAuctions([]);
      setUserBids([]);
      setMevMetrics({
        totalMEVPrevented: 0n,
        totalAuctions: 0,
        averageAuctionTime: 0,
        topPools: [],
      });
    } catch (error) {
      console.error('Error refreshing data:', error);
      toast.error('Failed to refresh data');
    } finally {
      setIsLoading(false);
    }
  };

  // Auto-refresh data when connection changes
  useEffect(() => {
    if (isConnected && contracts.mevAuctionHook) {
      refreshData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isConnected, chainId, address]);

  // Auto-refresh data periodically
  useEffect(() => {
    const interval = setInterval(() => {
      if (isConnected && contracts.mevAuctionHook) {
        refreshData();
      }
    }, 30000); // Refresh every 30 seconds

    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isConnected, contracts.mevAuctionHook]);

  // Computed values
  const activePools = pools.filter(pool => pool.isActive);

  // Context value
  const contextValue: Web3ContextType = {
    // Connection state
    isConnected,
    address,
    chainId,

    // Contract instances
    contracts,

    // Pool management
    pools,
    activePools,

    // Auction data
    activeAuctions,
    userBids,

    // MEV metrics
    mevMetrics,

    // Functions
    submitBid,
    createPool,
    executeAuction,
    getPriceData,
    uploadToLighthouse,
    deployBlockscoutExplorer,
    refreshData,

    // Loading states
    isLoading,
    isSubmittingBid,
    isCreatingPool,
  };

  return (
    <Web3Context.Provider value={contextValue}>
      {children}
    </Web3Context.Provider>
  );
};

// Custom hook to use Web3 context
export const useWeb3 = (): Web3ContextType => {
  const context = useContext(Web3Context);
  if (context === undefined) {
    throw new Error('useWeb3 must be used within a Web3Provider');
  }
  return context;
};