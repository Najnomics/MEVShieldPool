import React, { useState } from 'react';
import { useWeb3 } from '../contexts/Web3Context';
import { isAddress } from 'viem';
import { 
  BeakerIcon, 
  PlusIcon, 
  EyeIcon,
  ShieldCheckIcon,
  WalletIcon
} from '@heroicons/react/24/outline';
import LoadingSpinner from '../components/LoadingSpinner';

const PoolManagement: React.FC = () => {
  const { 
    createPool, 
    activePools, 
    isCreatingPool, 
    isConnected,
    refreshData 
  } = useWeb3();

  const [token0, setToken0] = useState('');
  const [token1, setToken1] = useState('');
  const [fee, setFee] = useState('3000');

  const handleCreatePool = async () => {
    if (!isAddress(token0) || !isAddress(token1) || !fee) return;
    
    try {
      await createPool(token0 as `0x${string}`, token1 as `0x${string}`, parseInt(fee));
      setToken0('');
      setToken1('');
      setFee('3000');
      await refreshData();
    } catch (error) {
      console.error('Error creating pool:', error);
    }
  };

  if (!isConnected) {
    return (
      <div className="min-h-96 flex items-center justify-center">
        <div className="text-center backdrop-blur-xl bg-gradient-to-br from-gray-800/40 to-gray-900/40 border border-gray-700/30 rounded-2xl p-8 shadow-2xl">
          <WalletIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
          <h3 className="text-xl font-bold text-white mb-2">
            Connect Wallet
          </h3>
          <p className="text-gray-300">
            Connect your wallet to manage liquidity pools.
          </p>
        </div>
      </div>
    );
  };

  const feeOptions = [
    { value: '500', label: '0.05% (Stable Pairs)' },
    { value: '3000', label: '0.30% (Standard)' },
    { value: '10000', label: '1.00% (Exotic Pairs)' },
  ];