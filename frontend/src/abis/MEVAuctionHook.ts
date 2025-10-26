// Updated ABI matching the deployed MEVAuctionHook contract
export const MEV_AUCTION_HOOK_ABI = [
  {
    type: 'function',
    name: 'submitBid',
    inputs: [
      { name: 'poolId', type: 'bytes32', internalType: 'bytes32' }
    ],
    outputs: [],
    stateMutability: 'payable'
  },
  {
    type: 'function',
    name: 'submitEncryptedBid',
    inputs: [
      { name: 'poolId', type: 'bytes32', internalType: 'bytes32' },
      { name: 'encryptedBid', type: 'bytes', internalType: 'bytes' },
      { name: 'decryptionKey', type: 'bytes', internalType: 'bytes' }
    ],
    outputs: [],
    stateMutability: 'payable'
  },
  {
    type: 'function',
    name: 'auctions',
    inputs: [
      { name: '', type: 'bytes32', internalType: 'bytes32' }
    ],
    outputs: [
      { name: 'highestBid', type: 'uint256', internalType: 'uint256' },
      { name: 'highestBidder', type: 'address', internalType: 'address' },
      { name: 'deadline', type: 'uint256', internalType: 'uint256' },
      { name: 'isActive', type: 'bool', internalType: 'bool' },
      { name: 'blockHash', type: 'bytes32', internalType: 'bytes32' },
      { name: 'totalMEVCollected', type: 'uint256', internalType: 'uint256' }
    ],
    stateMutability: 'view'
  },
  {
    type: 'function',
    name: 'bids',
    inputs: [
      { name: '', type: 'bytes32', internalType: 'bytes32' },
      { name: '', type: 'address', internalType: 'address' }
    ],
    outputs: [
      { name: '', type: 'uint256', internalType: 'uint256' }
    ],
    stateMutability: 'view'
  },
  {
    type: 'function',
    name: 'MIN_BID',
    inputs: [],
    outputs: [
      { name: '', type: 'uint256', internalType: 'uint256' }
    ],
    stateMutability: 'view'
  },
  {
    type: 'function',
    name: 'poolManager',
    inputs: [],
    outputs: [
      { name: '', type: 'address', internalType: 'address' }
    ],
    stateMutability: 'view'
  },
  {
    type: 'event',
    name: 'BidSubmitted',
    inputs: [
      { name: 'poolId', type: 'bytes32', indexed: true, internalType: 'bytes32' },
      { name: 'bidder', type: 'address', indexed: true, internalType: 'address' },
      { name: 'amount', type: 'uint256', indexed: false, internalType: 'uint256' }
    ],
    anonymous: false
  },
  {
    type: 'event',
    name: 'EncryptedBidSubmitted',
    inputs: [
      { name: 'poolId', type: 'bytes32', indexed: true, internalType: 'bytes32' },
      { name: 'bidder', type: 'address', indexed: true, internalType: 'address' },
      { name: 'sessionKeyHash', type: 'bytes32', indexed: false, internalType: 'bytes32' }
    ],
    anonymous: false
  },
  {
    type: 'event',
    name: 'AuctionWon',
    inputs: [
      { name: 'poolId', type: 'bytes32', indexed: true, internalType: 'bytes32' },
      { name: 'winner', type: 'address', indexed: true, internalType: 'address' },
      { name: 'winningBid', type: 'uint256', indexed: false, internalType: 'uint256' }
    ],
    anonymous: false
  },
  {
    type: 'event',
    name: 'HookSwap',
    inputs: [
      { name: 'poolId', type: 'bytes32', indexed: true, internalType: 'bytes32' },
      { name: 'amount0Delta', type: 'int128', indexed: false, internalType: 'int128' },
      { name: 'amount1Delta', type: 'int128', indexed: false, internalType: 'int128' },
      { name: 'mevValue', type: 'uint256', indexed: false, internalType: 'uint256' },
      { name: 'timestamp', type: 'uint256', indexed: false, internalType: 'uint256' }
    ],
    anonymous: false
  }
] as const;
