import React, { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { useMEVAuction, useAuction } from '../hooks/useMEVAuction';
import { formatEther } from 'viem';
import { 
  ClockIcon, 
  ShieldCheckIcon,
  PlusIcon,
  EyeIcon
} from '@heroicons/react/24/outline';
import LoadingSpinner from '../components/LoadingSpinner';
import { KNOWN_POOLS } from '../config/contracts';
import { toast } from 'react-toastify';

const AuctionInterface: React.FC = () => {
  const { isConnected } = useAccount();
  const { submitBid, minBid, isSubmitting, isSuccess, hash } = useMEVAuction();
  const [bidAmount, setBidAmount] = useState('');
  const [selectedPoolId, setSelectedPoolId] = useState<string>('');
  const [encryptBid, setEncryptBid] = useState(false);

  // Convert known pool ID to hex format
  const poolIdHex = selectedPoolId ? `0x${BigInt(selectedPoolId).toString(16).padStart(64, '0')}` as `0x${string}` : undefined;
  const { data: auctionData } = useAuction(poolIdHex || '0x0' as `0x${string}`);

  useEffect(() => {
    if (isSuccess && hash) {
      toast.success('Bid submitted successfully!');
      setBidAmount('');
    }
  }, [isSuccess, hash]);

  const handleSubmitBid = async () => {
    if (!selectedPoolId || !bidAmount || !poolIdHex) {
      toast.error('Please select a pool and enter bid amount');
      return;
    }
    
    try {
      await submitBid(poolIdHex, bidAmount);
    } catch (error: any) {
      console.error('Error submitting bid:', error);
      toast.error(error?.message || 'Failed to submit bid');
    }
  };

  if (!isConnected) {
    return (
      <div className="min-h-96 flex items-center justify-center">
        <div className="text-center backdrop-blur-xl bg-gradient-to-br from-gray-800/40 to-gray-900/40 border border-gray-700/30 rounded-2xl p-8 shadow-2xl">
          <ShieldCheckIcon className="mx-auto h-16 w-16 text-gray-400 mb-4" />
          <h3 className="text-xl font-bold text-white mb-2">
            Connect Wallet
          </h3>
          <p className="text-gray-300">
            Connect your wallet to participate in MEV auctions.
          </p>
        </div>
      </div>
    );
  }

  const auction = auctionData as any;
  const isAuctionActive = auction?.isActive || false;

  const PoolAuctionRow: React.FC<{ poolId: string }> = ({ poolId }) => {
    const poolHex = `0x${BigInt(poolId).toString(16).padStart(64, '0')}` as `0x${string}`;
    const { data: poolAuction } = useAuction(poolHex);
    const poolAuctionData = poolAuction as any;
    return (
      <div 
        className="p-6 bg-white/5 backdrop-blur-sm border border-white/10 rounded-xl hover:bg-white/10 transition-all duration-200"
      >
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <p className="text-sm text-gray-400 mb-1">Pool ID</p>
            <p className="text-white font-bold">{poolId.slice(0, 16)}...</p>
          </div>
          {poolAuctionData && (
            <>
              <div>
                <p className="text-sm text-gray-400 mb-1">Highest Bid</p>
                <p className="text-cyan-300 font-bold text-lg">
                  {formatEther(poolAuctionData.highestBid || 0n)} ETH
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-400 mb-1">Time Remaining</p>
                <div className="flex items-center space-x-2">
                  <ClockIcon className="h-4 w-4 text-orange-400" />
                  <p className="text-orange-300 font-bold">
                    {poolAuctionData.deadline ? Math.max(0, Math.floor((Number(poolAuctionData.deadline) - Date.now() / 1000) / 60)) : 0} min
                  </p>
                </div>
              </div>
            </>
          )}
        </div>
        {poolAuctionData?.highestBidder && poolAuctionData.highestBidder !== '0x0000000000000000000000000000000000000000' && (
          <div className="mt-4 pt-4 border-top border-gray-700/50">
            <p className="text-sm text-gray-400">Leading Bidder</p>
            <p className="text-white font-mono text-sm">
              {poolAuctionData.highestBidder.slice(0, 8)}...{poolAuctionData.highestBidder.slice(-6)}
            </p>
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="backdrop-blur-sm bg-gradient-to-r from-gray-800/30 to-gray-900/30 border border-gray-700/30 rounded-2xl p-6 shadow-xl">
        <h1 className="text-3xl font-bold bg-gradient-to-r from-cyan-300 via-blue-300 to-purple-300 bg-clip-text text-transparent">
          MEV Auction Interface
        </h1>
        <p className="mt-2 text-gray-300 font-medium">
          Submit bids and participate in MEV auctions with advanced privacy protection
        </p>
      </div>

      {/* Bid Submission Form */}
      <div className="backdrop-blur-xl bg-gradient-to-br from-cyan-800/40 to-blue-900/40 border border-cyan-700/30 rounded-2xl shadow-2xl shadow-cyan-500/10">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold bg-gradient-to-r from-cyan-300 to-blue-300 bg-clip-text text-transparent">
              Submit Bid
            </h3>
            <div className="p-3 rounded-xl bg-cyan-500/20 border border-cyan-400/30 backdrop-blur-sm">
              <PlusIcon className="h-6 w-6 text-cyan-300" />
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Pool Selection */}
            <div className="space-y-4">
              <label className="block text-sm font-bold text-cyan-200">
                Select Pool
              </label>
              <select
                value={selectedPoolId}
                onChange={(e) => setSelectedPoolId(e.target.value)}
                className="w-full px-4 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400/50 focus:border-cyan-400/50 transition-all duration-200"
              >
                <option value="" className="bg-gray-800 text-white">Choose pool...</option>
                {KNOWN_POOLS.map((pool) => (
                  <option key={pool.poolId} value={pool.poolId} className="bg-gray-800 text-white">
                    Pool: {pool.poolId.slice(0, 8)}... - {pool.token0.slice(0, 6)}/{pool.token1.slice(0, 6)}
                  </option>
                ))}
              </select>
              {auction && (
                <div className="mt-2 text-sm text-cyan-200">
                  Status: {isAuctionActive ? '✅ Active' : '❌ Inactive'}
                  {auction.highestBid && (
                    <div>Current Bid: {formatEther(auction.highestBid)} ETH</div>
                  )}
                </div>
              )}
            </div>

            {/* Bid Amount */}
            <div className="space-y-4">
              <label className="block text-sm font-bold text-cyan-200">
                Bid Amount (ETH)
              </label>
              <input
                type="number"
                step="0.001"
                min={minBid}
                value={bidAmount}
                onChange={(e) => setBidAmount(e.target.value)}
                placeholder={`Min: ${minBid} ETH`}
                className="w-full px-4 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400/50 focus:border-cyan-400/50 transition-all duration-200"
              />
            </div>
          </div>

          {/* Encryption Toggle & Submit */}
          <div className="mt-6 space-y-4">
            <div className="flex items-center space-x-3">
              <input
                type="checkbox"
                id="encrypt-bid"
                checked={encryptBid}
                onChange={(e) => setEncryptBid(e.target.checked)}
                className="w-4 h-4 text-cyan-600 bg-gray-100 border-gray-300 rounded focus:ring-cyan-500 dark:focus:ring-cyan-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
              />
              <label htmlFor="encrypt-bid" className="text-sm font-medium text-cyan-200">
                Encrypt bid using Lit Protocol (recommended)
              </label>
            </div>

            <button
              onClick={handleSubmitBid}
              disabled={!selectedPoolId || !bidAmount || isSubmitting || !isAuctionActive}
              className="w-full px-6 py-4 bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-600 hover:to-blue-700 disabled:from-gray-600 disabled:to-gray-700 text-white font-bold rounded-xl shadow-lg shadow-cyan-500/25 hover:shadow-cyan-500/40 transition-all duration-200 disabled:cursor-not-allowed"
            >
              {isSubmitting ? (
                <div className="flex items-center justify-center space-x-2">
                  <LoadingSpinner size="small" />
                  <span>Submitting Bid...</span>
                </div>
              ) : (
                'Submit Bid'
              )}
            </button>
            {hash && (
              <div className="text-sm text-green-300 text-center">
                Transaction: {hash.slice(0, 10)}...{hash.slice(-8)}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Active Auctions List */}
      <div className="backdrop-blur-xl bg-gradient-to-br from-gray-800/40 to-gray-900/40 border border-gray-700/30 rounded-2xl shadow-2xl">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
              Known Pools
            </h3>
            <div className="p-3 rounded-xl bg-gray-500/20 border border-gray-400/30 backdrop-blur-sm">
              <EyeIcon className="h-6 w-6 text-gray-300" />
            </div>
          </div>

          <div className="space-y-4">
            {KNOWN_POOLS.map((pool) => (
              <PoolAuctionRow key={pool.poolId} poolId={pool.poolId} />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AuctionInterface;
