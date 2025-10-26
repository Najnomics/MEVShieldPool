import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther, Address } from 'viem';
import { MEV_AUCTION_HOOK_ABI } from '../abis/MEVAuctionHook';
import { CONTRACT_ADDRESSES, SEPOLIA_CHAIN_ID } from '../config/contracts';

const mevHookAddress = CONTRACT_ADDRESSES[SEPOLIA_CHAIN_ID].mevAuctionHook;

// Read auction data for a pool
export function useAuction(poolId: `0x${string}`) {
  return useReadContract({
    address: mevHookAddress,
    abi: MEV_AUCTION_HOOK_ABI,
    functionName: 'auctions',
    args: [poolId],
  });
}

export function useMEVAuction() {
  // Get minimum bid
  const { data: minBid } = useReadContract({
    address: mevHookAddress,
    abi: MEV_AUCTION_HOOK_ABI,
    functionName: 'MIN_BID',
  });

  // Submit bid
  const { writeContract, data: hash, isPending } = useWriteContract();
  
  const submitBid = async (poolId: `0x${string}`, amount: string) => {
    const amountWei = parseEther(amount);
    return writeContract({
      address: mevHookAddress,
      abi: MEV_AUCTION_HOOK_ABI,
      functionName: 'submitBid',
      args: [poolId],
      value: amountWei,
    });
  };

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  return {
    useAuction,
    minBid: minBid ? formatEther(minBid) : '0.001',
    submitBid,
    isSubmitting: isPending || isConfirming,
    isSuccess,
    hash,
  };
}
