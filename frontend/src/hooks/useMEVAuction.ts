import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { MEV_AUCTION_HOOK_ABI } from '../abis/MEVAuctionHook';
import { CONTRACT_ADDRESSES, SEPOLIA_CHAIN_ID } from '../config/contracts';

const mevHookAddress = CONTRACT_ADDRESSES[SEPOLIA_CHAIN_ID].mevAuctionHook;

// Read auction data for a pool
export function useAuction(poolId: `0x${string}` | undefined) {
  // @ts-ignore - Wagmi v2 type inference issue
  const result = useReadContract(poolId ? {
    address: mevHookAddress,
    abi: MEV_AUCTION_HOOK_ABI,
    functionName: 'auctions',
    args: [poolId],
  } : undefined);
  return result;
}

export function useMEVAuction() {
  // Get minimum bid
  // @ts-ignore - Wagmi v2 type inference issue
  const { data: minBid } = useReadContract({
    address: mevHookAddress,
    abi: MEV_AUCTION_HOOK_ABI,
    functionName: 'MIN_BID',
  });

  // Submit bid
  const { writeContractAsync, data: hash, isPending } = useWriteContract();
  
  const submitBid = async (poolId: `0x${string}`, amount: string) => {
    if (!writeContractAsync) {
      throw new Error('Wallet not connected');
    }
    const amountWei = parseEther(amount);
    // @ts-ignore - Wagmi v2 type inference issue
    return writeContractAsync({
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
