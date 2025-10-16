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
      color: 'text-green-600',
      bgColor: 'bg-green-100 dark:bg-green-900',
    },
    {
      name: 'Active Auctions',
      value: activeAuctions.length.toString(),
      unit: 'auctions',
      icon: CurrencyDollarIcon,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100 dark:bg-blue-900',
    },
    {
      name: 'Active Pools',
      value: activePools.length.toString(),
      unit: 'pools',
      icon: BeakerIcon,
      color: 'text-purple-600',
      bgColor: 'bg-purple-100 dark:bg-purple-900',
    },
    {
      name: 'Avg Auction Time',
      value: Math.round(mevMetrics.averageAuctionTime / 60).toString(),
      unit: 'min',
      icon: ClockIcon,
      color: 'text-orange-600',
      bgColor: 'bg-orange-100 dark:bg-orange-900',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          MEV Dashboard
        </h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
          Real-time MEV protection and auction analytics
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {statsCards.map((stat) => (
          <div
            key={stat.name}
            className="bg-white dark:bg-gray-800 overflow-hidden shadow rounded-lg border border-gray-200 dark:border-gray-700"
          >
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <div className={`p-3 rounded-md ${stat.bgColor}`}>
                    <stat.icon className={`h-6 w-6 ${stat.color}`} />
                  </div>
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">
                      {stat.name}
                    </dt>
                    <dd className="flex items-baseline">
                      <div className="text-2xl font-semibold text-gray-900 dark:text-white">
                        {stat.value}
                      </div>
                      <div className="ml-2 text-sm text-gray-500 dark:text-gray-400">
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
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Active Auctions */}
        <div className="bg-white dark:bg-gray-800 shadow rounded-lg border border-gray-200 dark:border-gray-700">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                Active Auctions
              </h3>
              <CurrencyDollarIcon className="h-5 w-5 text-gray-400" />
            </div>
            <div className="space-y-3">
              {activeAuctions.length === 0 ? (
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  No active auctions
                </p>
              ) : (
                activeAuctions.slice(0, 5).map((auction) => (
                  <div 
                    key={auction.auctionId}
                    className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-md"
                  >
                    <div>
                      <p className="text-sm font-medium text-gray-900 dark:text-white">
                        Pool: {auction.poolId.slice(0, 8)}...
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        Highest Bid: {formatEther(auction.highestBid)} ETH
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-gray-900 dark:text-white">
                        {new Date(auction.deadline * 1000).toLocaleTimeString()}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
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
        <div className="bg-white dark:bg-gray-800 shadow rounded-lg border border-gray-200 dark:border-gray-700">
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                Top Performing Pools
              </h3>
              <TrendingUpIcon className="h-5 w-5 text-gray-400" />
            </div>
            <div className="space-y-3">
              {mevMetrics.topPools.length === 0 ? (
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  No pool data available
                </p>
              ) : (
                mevMetrics.topPools.slice(0, 5).map((pool) => (
                  <div 
                    key={pool.poolId}
                    className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-md"
                  >
                    <div>
                      <p className="text-sm font-medium text-gray-900 dark:text-white">
                        {pool.token0.slice(0, 6)}.../{pool.token1.slice(0, 6)}...
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        Fee: {pool.fee / 10000}%
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-gray-900 dark:text-white">
                        {pool.liquidity.toString().slice(0, 8)}...
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
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

      {/* MEV Analytics Chart Placeholder */}
      <div className="bg-white dark:bg-gray-800 shadow rounded-lg border border-gray-200 dark:border-gray-700">
        <div className="p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">
              MEV Protection Analytics
            </h3>
            <ChartBarIcon className="h-5 w-5 text-gray-400" />
          </div>
          <div className="h-64 flex items-center justify-center bg-gray-50 dark:bg-gray-700 rounded-md">
            <div className="text-center">
              <ChartBarIcon className="mx-auto h-12 w-12 text-gray-400" />
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                MEV analytics chart will be displayed here
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;