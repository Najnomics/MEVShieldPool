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

  // Submit encrypted bid to MEV auction
  const submitBid = async (poolId: string, amount: bigint, encrypted = true): Promise<string> => {
    if (!isConnected || !walletClient || !contracts.mevAuctionHook) {
      throw new Error('Wallet not connected');
    }

    setIsSubmittingBid(true);
    try {
      let bidHash: string;

      if (encrypted) {
        // Encrypt bid using Lit Protocol
        const encryptedBid = await walletClient.writeContract({
          address: contracts.litMPCManager.address,
          abi: contracts.litMPCManager.abi,
          functionName: 'encryptBid',
          args: [poolId, amount, '[]'], // Empty access conditions for demo
        });
        bidHash = encryptedBid;
      } else {
        // Submit regular bid
        const bidTx = await walletClient.writeContract({
          address: contracts.mevAuctionHook.address,
          abi: contracts.mevAuctionHook.abi,
          functionName: 'submitBid',
          args: [poolId],
          value: amount,
        });
        bidHash = bidTx;
      }

      toast.success('Bid submitted successfully!');
      await refreshData();
      return bidHash;
    } catch (error) {
      console.error('Error submitting bid:', error);
      toast.error('Failed to submit bid');
      throw error;
    } finally {
      setIsSubmittingBid(false);
    }
  };

  // Create new liquidity pool
  const createPool = async (token0: Address, token1: Address, fee: number): Promise<string> => {
    if (!isConnected || !walletClient || !contracts.mevAuctionHook) {
      throw new Error('Wallet not connected');
    }

    setIsCreatingPool(true);
    try {
      const poolTx = await walletClient.writeContract({
        address: contracts.mevAuctionHook.address,
        abi: contracts.mevAuctionHook.abi,
        functionName: 'createPool',
        args: [token0, token1, fee],
      });

      toast.success('Pool created successfully!');
      await refreshData();
      return poolTx;
    } catch (error) {
      console.error('Error creating pool:', error);
      toast.error('Failed to create pool');
      throw error;
    } finally {
      setIsCreatingPool(false);
    }
  };

  // Execute auction and settle bids
  const executeAuction = async (auctionId: string): Promise<boolean> => {
    if (!isConnected || !walletClient || !contracts.mevAuctionHook) {
      throw new Error('Wallet not connected');
    }

    try {
      await walletClient.writeContract({
        address: contracts.mevAuctionHook.address,
        abi: contracts.mevAuctionHook.abi,
        functionName: 'executeAuction',
        args: [auctionId],
      });

      toast.success('Auction executed successfully!');
      await refreshData();
      return true;
    } catch (error) {
      console.error('Error executing auction:', error);
      toast.error('Failed to execute auction');
      return false;
    }
  };

  // Get price data from Pyth Network
  const getPriceData = async (priceId: string): Promise<any> => {
    if (!publicClient || !contracts.pythPriceOracle) {
      throw new Error('Client not available');
    }

    try {
      const priceData = await publicClient.readContract({
        address: contracts.pythPriceOracle.address,
        abi: contracts.pythPriceOracle.abi,
        functionName: 'getPrice',
        args: [priceId],
      });

      return priceData;
    } catch (error) {
      console.error('Error getting price data:', error);
      throw error;
    }
  };

  // Upload data to Lighthouse Storage
  const uploadToLighthouse = async (data: Uint8Array, encrypted = false): Promise<string> => {
    if (!isConnected || !walletClient || !contracts.lighthouseStorage) {
      throw new Error('Wallet not connected');
    }

    try {
      const uploadTx = await walletClient.writeContract({
        address: contracts.lighthouseStorage.address,
        abi: contracts.lighthouseStorage.abi,
        functionName: 'uploadFile',
        args: [data, 'application/octet-stream', 0, encrypted, []],
      });

      toast.success('File uploaded to Lighthouse!');
      return uploadTx;
    } catch (error) {
      console.error('Error uploading to Lighthouse:', error);
      toast.error('Failed to upload file');
      throw error;
    }
  };

  // Deploy Blockscout explorer
  const deployBlockscoutExplorer = async (config: any): Promise<string> => {
    if (!isConnected || !walletClient || !contracts.blockscoutManager) {
      throw new Error('Wallet not connected');
    }

    try {
      const deployTx = await walletClient.writeContract({
        address: contracts.blockscoutManager.address,
        abi: contracts.blockscoutManager.abi,
        functionName: 'deployAutoscoutExplorer',
        args: [
          config.explorerName,
          config.chainName,
          config.chainId,
          config.rpcUrl,
          config.currency,
          config.isTestnet,
          config.logoUrl,
          config.brandColor,
        ],
      });

      toast.success('Blockscout explorer deployment initiated!');
      return deployTx;
    } catch (error) {
      console.error('Error deploying explorer:', error);
      toast.error('Failed to deploy explorer');
      throw error;
    }
  };

  // Refresh all data from contracts
  const refreshData = async (): Promise<void> => {
    if (!publicClient || !isConnected) return;

    setIsLoading(true);
    try {
      // Fetch pool data
      const poolsData = await publicClient.readContract({
        address: contracts.mevAuctionHook?.address,
        abi: contracts.mevAuctionHook?.abi,
        functionName: 'getAllPools',
        args: [],
      });

      // Fetch active auctions
      const auctionsData = await publicClient.readContract({
        address: contracts.mevAuctionHook?.address,
        abi: contracts.mevAuctionHook?.abi,
        functionName: 'getActiveAuctions',
        args: [],
      });

      // Fetch user bids if connected
      let userBidsData: any[] = [];
      if (address) {
        userBidsData = await publicClient.readContract({
          address: contracts.mevAuctionHook?.address,
          abi: contracts.mevAuctionHook?.abi,
          functionName: 'getUserBids',
          args: [address],
        });
      }

      // Fetch MEV metrics
      const metricsData = await publicClient.readContract({
        address: contracts.mevAuctionHook?.address,
        abi: contracts.mevAuctionHook?.abi,
        functionName: 'getMEVMetrics',
        args: [],
      });

      // Update state
      setPools(poolsData || []);
      setActiveAuctions(auctionsData || []);
      setUserBids(userBidsData || []);
      setMevMetrics(metricsData || {
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
  }, [isConnected, chain?.id, address]);

  // Auto-refresh data periodically
  useEffect(() => {
    const interval = setInterval(() => {
      if (isConnected && contracts.mevAuctionHook) {
        refreshData();
      }
    }, 30000); // Refresh every 30 seconds

    return () => clearInterval(interval);
  }, [isConnected, contracts.mevAuctionHook]);

  // Computed values
  const activePools = pools.filter(pool => pool.isActive);

  // Context value
  const contextValue: Web3ContextType = {
    // Connection state
    isConnected,
    address,
    chainId: chain?.id,

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