import React, { useState } from 'react';
import { useWeb3 } from '../contexts/Web3Context';
import { parseEther, formatEther } from 'viem';
import { 
  CurrencyDollarIcon, 
  ClockIcon, 
  ShieldCheckIcon,
  PlusIcon,
  EyeIcon
} from '@heroicons/react/24/outline';
import LoadingSpinner from '../components/LoadingSpinner';

const AuctionInterface: React.FC = () => {
  const { 
    submitBid, 
    activeAuctions, 
    isSubmittingBid, 
    isConnected,
    refreshData 
  } = useWeb3();

  const [bidAmount, setBidAmount] = useState('');
  const [selectedAuction, setSelectedAuction] = useState<string>('');
  const [encryptBid, setEncryptBid] = useState(true);

  const handleSubmitBid = async () => {
    if (!selectedAuction || !bidAmount) return;
    
    try {
      await submitBid(selectedAuction, parseEther(bidAmount), encryptBid);
      setBidAmount('');
      setSelectedAuction('');
      await refreshData();
    } catch (error) {
      console.error('Error submitting bid:', error);
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