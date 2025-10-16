import React from 'react';
import { useWeb3 } from '../contexts/Web3Context';
import { formatEther } from 'viem';
import { 
  ChartBarIcon, 
  TrendingUpIcon, 
  ShieldCheckIcon,
  ClockIcon,
  EyeIcon,
  ArrowTrendingUpIcon
} from '@heroicons/react/24/outline';

const AnalyticsPage: React.FC = () => {
  const { 
    mevMetrics, 
    activeAuctions, 
    activePools,
    isConnected,
    isLoading 
  } = useWeb3();

  if (!isConnected) {
    return (
      <div className="min-h-96 flex items-center justify-center">
        <div className="text-center backdrop-blur-xl bg-gradient-to-br from-gray-800/40 to-gray-900/40 border border-gray-700/30 rounded-2xl p-8 shadow-2xl">
          <ChartBarIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
          <h3 className="text-xl font-bold text-white mb-2">
            Connect Wallet
          </h3>
          <p className="text-gray-300">
            Connect your wallet to view detailed MEV analytics.
          </p>
        </div>
      </div>
    );
  }

  const performanceMetrics = [
    {
      name: 'MEV Protection Rate',
      value: '99.8%',
      change: '+0.2%',
      icon: ShieldCheckIcon,
      color: 'text-green-300',
      bgColor: 'from-green-500/20 to-emerald-500/20',
      borderColor: 'border-green-400/30',
    },
    {
      name: 'Average Response Time',
      value: '12ms',
      change: '-2ms',
      icon: ClockIcon,
      color: 'text-cyan-300',
      bgColor: 'from-cyan-500/20 to-blue-500/20',
      borderColor: 'border-cyan-400/30',
    },
    {
      name: 'Gas Efficiency',
      value: '95.3%',
      change: '+1.2%',
      icon: TrendingUpIcon,
      color: 'text-purple-300',
      bgColor: 'from-purple-500/20 to-violet-500/20',
      borderColor: 'border-purple-400/30',
    },
    {
      name: 'Successful Auctions',
      value: mevMetrics.totalAuctions.toString(),
      change: '+12',
      icon: ArrowTrendingUpIcon,
      color: 'text-orange-300',
      bgColor: 'from-orange-500/20 to-amber-500/20',
      borderColor: 'border-orange-400/30',
    },
  ];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="backdrop-blur-sm bg-gradient-to-r from-gray-800/30 to-gray-900/30 border border-gray-700/30 rounded-2xl p-6 shadow-xl">
        <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-300 via-purple-300 to-cyan-300 bg-clip-text text-transparent">
          MEV Analytics Dashboard
        </h1>
        <p className="mt-2 text-gray-300 font-medium">
          Advanced analytics and insights for MEV protection performance
        </p>
      </div>

      {/* Performance Metrics */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {performanceMetrics.map((metric) => (
          <div
            key={metric.name}
            className={`backdrop-blur-xl bg-gradient-to-br ${metric.bgColor} border ${metric.borderColor} rounded-2xl overflow-hidden shadow-2xl hover:shadow-3xl hover:scale-105 transition-all duration-300`}
          >
            <div className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex-shrink-0">
                  <div className="p-3 rounded-xl bg-white/10 backdrop-blur-sm border border-white/20">
                    <metric.icon className={`h-6 w-6 ${metric.color}`} />
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-2xl font-bold text-white">
                    {metric.value}
                  </p>
                  <p className={`text-sm font-medium ${metric.color}`}>
                    {metric.change}
                  </p>
                </div>
              </div>
              <div className="mt-4">
                <p className="text-sm font-medium text-gray-300">
                  {metric.name}
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>