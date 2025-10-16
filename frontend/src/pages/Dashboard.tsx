import React from 'react';
import { useWeb3 } from '../contexts/Web3Context';
import { formatEther } from 'viem';
import { 
  CurrencyDollarIcon, 
  ChartBarIcon, 
  ClockIcon, 
  BeakerIcon,
  ShieldCheckIcon,
  TrendingUpIcon
} from '@heroicons/react/24/outline';
import LoadingSpinner from '../components/LoadingSpinner';

const Dashboard: React.FC = () => {
  const { 
    mevMetrics, 
    activeAuctions, 
    activePools, 
    isLoading, 
    isConnected 
  } = useWeb3();

  if (!isConnected) {
    return (
      <div className="min-h-96 flex items-center justify-center">
        <div className="text-center">
          <ShieldCheckIcon className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100">
            Connect Wallet
          </h3>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            Connect your wallet to view MEV auction dashboard.
          </p>
        </div>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="min-h-96 flex items-center justify-center">
        <LoadingSpinner size="large" />
      </div>
    );
  }

  const statsCards = [
    {
      name: 'Total MEV Prevented',
      value: formatEther(mevMetrics.totalMEVPrevented),
      unit: 'ETH',
      icon: ShieldCheckIcon,
      color: 'text-emerald-300',
      bgColor: 'from-emerald-500/20 to-green-500/20',
      shadowColor: 'shadow-emerald-500/20',
      borderColor: 'border-emerald-400/30',
    },
    {
      name: 'Active Auctions',
      value: activeAuctions.length.toString(),
      unit: 'auctions',
      icon: CurrencyDollarIcon,
      color: 'text-cyan-300',
      bgColor: 'from-cyan-500/20 to-blue-500/20',
      shadowColor: 'shadow-cyan-500/20',
      borderColor: 'border-cyan-400/30',
    },
    {
      name: 'Active Pools',
      value: activePools.length.toString(),
      unit: 'pools',
      icon: BeakerIcon,
      color: 'text-purple-300',
      bgColor: 'from-purple-500/20 to-violet-500/20',
      shadowColor: 'shadow-purple-500/20',
      borderColor: 'border-purple-400/30',
    },
    {
      name: 'Avg Auction Time',
      value: Math.round(mevMetrics.averageAuctionTime / 60).toString(),
      unit: 'min',
      icon: ClockIcon,
      color: 'text-orange-300',
      bgColor: 'from-orange-500/20 to-amber-500/20',
      shadowColor: 'shadow-orange-500/20',
      borderColor: 'border-orange-400/30',
    },
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="backdrop-blur-sm bg-gradient-to-r from-gray-800/30 to-gray-900/30 border border-gray-700/30 rounded-2xl p-6 shadow-xl">
        <h1 className="text-3xl font-bold bg-gradient-to-r from-white via-cyan-200 to-blue-300 bg-clip-text text-transparent">
          MEV Dashboard
        </h1>
        <p className="mt-2 text-gray-300 font-medium">
          Real-time MEV protection and auction analytics with advanced glassmorphism design
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {statsCards.map((stat) => (
          <div
            key={stat.name}
            className={`backdrop-blur-xl bg-gradient-to-br ${stat.bgColor} border ${stat.borderColor} rounded-2xl overflow-hidden shadow-2xl ${stat.shadowColor} hover:shadow-3xl hover:scale-105 transition-all duration-300`}
          >
            <div className="p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className={`p-4 rounded-2xl bg-white/10 backdrop-blur-sm border border-white/20 shadow-lg`}>
                    <stat.icon className={`h-8 w-8 ${stat.color}`} />
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-300 truncate mb-1">
                      {stat.name}
                    </dt>
                    <dd className="flex items-baseline">
                      <div className="text-3xl font-bold text-white">
                        {stat.value}
                      </div>
                      <div className={`ml-2 text-sm font-medium ${stat.color}`}>
                        {stat.unit}
                      </div>
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Active Auctions */}
        <div className="backdrop-blur-xl bg-gradient-to-br from-gray-800/40 to-gray-900/40 border border-gray-700/30 rounded-2xl shadow-2xl shadow-cyan-500/10">
          <div className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold bg-gradient-to-r from-cyan-300 to-blue-300 bg-clip-text text-transparent">
                Active Auctions
              </h3>
              <div className="p-3 rounded-xl bg-cyan-500/20 border border-cyan-400/30 backdrop-blur-sm">
                <CurrencyDollarIcon className="h-6 w-6 text-cyan-300" />
              </div>
            </div>
            <div className="space-y-4">
              {activeAuctions.length === 0 ? (
                <div className="text-center py-8">
                  <CurrencyDollarIcon className="mx-auto h-12 w-12 text-gray-500 mb-4" />
                  <p className="text-gray-400 font-medium">
                    No active auctions
                  </p>
                </div>
              ) : (
                activeAuctions.slice(0, 5).map((auction) => (
                  <div 
                    key={auction.auctionId}
                    className="flex items-center justify-between p-4 bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl hover:bg-white/10 transition-all duration-200"
                  >
                    <div>
                      <p className="text-sm font-bold text-white mb-1">
                        Pool: {auction.poolId.slice(0, 8)}...
                      </p>
                      <p className="text-xs text-cyan-300 font-medium">
                        Highest Bid: {formatEther(auction.highestBid)} ETH
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-bold text-white">
                        {new Date(auction.deadline * 1000).toLocaleTimeString()}
                      </p>
                      <p className="text-xs text-gray-400">
                        Deadline
                      </p>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Top Pools */}
        <div className="backdrop-blur-xl bg-gradient-to-br from-purple-800/40 to-violet-900/40 border border-purple-700/30 rounded-2xl shadow-2xl shadow-purple-500/10">
          <div className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold bg-gradient-to-r from-purple-300 to-violet-300 bg-clip-text text-transparent">
                Top Performing Pools
              </h3>
              <div className="p-3 rounded-xl bg-purple-500/20 border border-purple-400/30 backdrop-blur-sm">
                <TrendingUpIcon className="h-6 w-6 text-purple-300" />
              </div>
            </div>
            <div className="space-y-4">
              {mevMetrics.topPools.length === 0 ? (
                <div className="text-center py-8">
                  <TrendingUpIcon className="mx-auto h-12 w-12 text-gray-500 mb-4" />
                  <p className="text-gray-400 font-medium">
                    No pool data available
                  </p>
                </div>
              ) : (
                mevMetrics.topPools.slice(0, 5).map((pool) => (
                  <div 
                    key={pool.poolId}
                    className="flex items-center justify-between p-4 bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl hover:bg-white/10 transition-all duration-200"
                  >
                    <div>
                      <p className="text-sm font-bold text-white mb-1">
                        {pool.token0.slice(0, 6)}.../{pool.token1.slice(0, 6)}...
                      </p>
                      <p className="text-xs text-purple-300 font-medium">
                        Fee: {pool.fee / 10000}%
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-bold text-white">
                        {pool.liquidity.toString().slice(0, 8)}...
                      </p>
                      <p className="text-xs text-gray-400">
                        Liquidity
                      </p>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>

      {/* MEV Analytics Chart */}
      <div className="backdrop-blur-xl bg-gradient-to-br from-gray-800/40 to-slate-900/40 border border-gray-700/30 rounded-2xl shadow-2xl shadow-blue-500/10">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-2xl font-bold bg-gradient-to-r from-blue-300 via-cyan-300 to-purple-300 bg-clip-text text-transparent">
              MEV Protection Analytics
            </h3>
            <div className="p-3 rounded-xl bg-blue-500/20 border border-blue-400/30 backdrop-blur-sm">
              <ChartBarIcon className="h-6 w-6 text-blue-300" />
            </div>
          </div>
          <div className="h-80 flex items-center justify-center bg-gradient-to-br from-gray-900/20 to-black/20 backdrop-blur-sm border border-white/10 rounded-2xl">
            <div className="text-center">
              <div className="p-6 rounded-2xl bg-gradient-to-br from-blue-500/20 to-purple-500/20 border border-blue-400/30 backdrop-blur-sm mb-6">
                <ChartBarIcon className="mx-auto h-16 w-16 text-blue-300 mb-4" />
                <p className="text-lg font-bold text-white mb-2">
                  Advanced MEV Analytics
                </p>
                <p className="text-gray-400 font-medium">
                  Real-time charts and insights will be displayed here
                </p>
              </div>
              <div className="grid grid-cols-3 gap-4 text-center">
                <div className="p-3 rounded-xl bg-white/5 backdrop-blur-sm border border-white/10">
                  <p className="text-xs text-gray-400 mb-1">Protection Rate</p>
                  <p className="text-lg font-bold text-green-300">99.8%</p>
                </div>
                <div className="p-3 rounded-xl bg-white/5 backdrop-blur-sm border border-white/10">
                  <p className="text-xs text-gray-400 mb-1">Gas Saved</p>
                  <p className="text-lg font-bold text-cyan-300">2.4M</p>
                </div>
                <div className="p-3 rounded-xl bg-white/5 backdrop-blur-sm border border-white/10">
                  <p className="text-xs text-gray-400 mb-1">Avg Response</p>
                  <p className="text-lg font-bold text-purple-300">12ms</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;