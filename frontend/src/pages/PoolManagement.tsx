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

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="backdrop-blur-sm bg-gradient-to-r from-gray-800/30 to-gray-900/30 border border-gray-700/30 rounded-2xl p-6 shadow-xl">
        <h1 className="text-3xl font-bold bg-gradient-to-r from-purple-300 via-blue-300 to-cyan-300 bg-clip-text text-transparent">
          Pool Management
        </h1>
        <p className="mt-2 text-gray-300 font-medium">
          Create and manage Uniswap V4 liquidity pools with MEV protection
        </p>
      </div>

      {/* Create Pool Form */}
      <div className="backdrop-blur-xl bg-gradient-to-br from-purple-800/40 to-violet-900/40 border border-purple-700/30 rounded-2xl shadow-2xl shadow-purple-500/10">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold bg-gradient-to-r from-purple-300 to-violet-300 bg-clip-text text-transparent">
              Create New Pool
            </h3>
            <div className="p-3 rounded-xl bg-purple-500/20 border border-purple-400/30 backdrop-blur-sm">
              <PlusIcon className="h-6 w-6 text-purple-300" />
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Token 0 */}
            <div className="space-y-4">
              <label className="block text-sm font-bold text-purple-200">
                Token 0 Address
              </label>
              <input
                type="text"
                value={token0}
                onChange={(e) => setToken0(e.target.value)}
                placeholder="0x..."
                className="w-full px-4 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-400/50 focus:border-purple-400/50 transition-all duration-200"
              />
              {token0 && !isAddress(token0) && (
                <p className="text-red-400 text-xs">Invalid address format</p>
              )}
            </div>

            {/* Token 1 */}
            <div className="space-y-4">
              <label className="block text-sm font-bold text-purple-200">
                Token 1 Address
              </label>
              <input
                type="text"
                value={token1}
                onChange={(e) => setToken1(e.target.value)}
                placeholder="0x..."
                className="w-full px-4 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-400/50 focus:border-purple-400/50 transition-all duration-200"
              />
              {token1 && !isAddress(token1) && (
                <p className="text-red-400 text-xs">Invalid address format</p>
              )}
            </div>

            {/* Fee Tier */}
            <div className="space-y-4">
              <label className="block text-sm font-bold text-purple-200">
                Fee Tier
              </label>
              <select
                value={fee}
                onChange={(e) => setFee(e.target.value)}
                className="w-full px-4 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-purple-400/50 focus:border-purple-400/50 transition-all duration-200"
              >
                {feeOptions.map((option) => (
                  <option key={option.value} value={option.value} className="bg-gray-800 text-white">
                    {option.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Create Button */}
          <div className="mt-6">
            <button
              onClick={handleCreatePool}
              disabled={!isAddress(token0) || !isAddress(token1) || !fee || isCreatingPool}
              className="w-full px-6 py-4 bg-gradient-to-r from-purple-500 to-violet-600 hover:from-purple-600 hover:to-violet-700 disabled:from-gray-600 disabled:to-gray-700 text-white font-bold rounded-xl shadow-lg shadow-purple-500/25 hover:shadow-purple-500/40 transition-all duration-200 disabled:cursor-not-allowed"
            >
              {isCreatingPool ? (
                <div className="flex items-center justify-center space-x-2">
                  <LoadingSpinner size="small" />
                  <span>Creating Pool...</span>
                </div>
              ) : (
                'Create Pool'
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Active Pools List */}
      <div className="backdrop-blur-xl bg-gradient-to-br from-gray-800/40 to-gray-900/40 border border-gray-700/30 rounded-2xl shadow-2xl">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
              Active Pools
            </h3>
            <div className="p-3 rounded-xl bg-gray-500/20 border border-gray-400/30 backdrop-blur-sm">
              <EyeIcon className="h-6 w-6 text-gray-300" />
            </div>
          </div>

          <div className="space-y-4">
            {activePools.length === 0 ? (
              <div className="text-center py-12">
                <BeakerIcon className="mx-auto h-16 w-16 text-gray-500 mb-4" />
                <p className="text-gray-400 font-medium text-lg">
                  No active pools found
                </p>
                <p className="text-gray-500 mt-2">
                  Create your first pool to start earning MEV protection fees
                </p>
              </div>
            ) : (
              activePools.map((pool) => (
                <div 
                  key={pool.poolId}
                  className="p-6 bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl hover:bg-white/10 transition-all duration-200"
                >
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div>
                      <p className="text-sm text-gray-400 mb-1">Pool ID</p>
                      <p className="text-white font-bold font-mono text-sm">{pool.poolId.slice(0, 16)}...</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-400 mb-1">Token Pair</p>
                      <p className="text-white font-bold">
                        {pool.token0.slice(0, 6)}.../{pool.token1.slice(0, 6)}...
                      </p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-400 mb-1">Fee Tier</p>
                      <p className="text-purple-300 font-bold">
                        {pool.fee / 10000}%
                      </p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-400 mb-1">Liquidity</p>
                      <p className="text-cyan-300 font-bold">
                        {pool.liquidity.toString().slice(0, 8)}...
                      </p>
                    </div>
                  </div>
                  
                  <div className="mt-4 pt-4 border-t border-gray-700/50 flex items-center justify-between">
                    <div className="flex items-center space-x-4">
                      <div className="flex items-center space-x-2">
                        <div className={`h-2 w-2 rounded-full ${pool.isActive ? 'bg-green-400' : 'bg-red-400'}`}></div>
                        <span className={`text-sm font-medium ${pool.isActive ? 'text-green-300' : 'text-red-300'}`}>
                          {pool.isActive ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <ShieldCheckIcon className="h-4 w-4 text-blue-400" />
                        <span className="text-sm text-blue-300 font-medium">MEV Protected</span>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-gray-400">Current Tick</p>
                      <p className="text-white font-bold">{pool.tick}</p>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default PoolManagement;