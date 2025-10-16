export const MEV_AUCTION_HOOK_ABI = [
  {
    "type": "function",
    "name": "submitBid",
    "inputs": [
      {"name": "poolId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {"name": "auctionId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "createPool",
    "inputs": [
      {"name": "token0", "type": "address", "internalType": "address"},
      {"name": "token1", "type": "address", "internalType": "address"},
      {"name": "fee", "type": "uint24", "internalType": "uint24"}
    ],
    "outputs": [
      {"name": "poolId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "executeAuction",
    "inputs": [
      {"name": "auctionId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getAllPools",
    "inputs": [],
    "outputs": [
      {
        "name": "pools",
        "type": "tuple[]",
        "internalType": "struct MEVAuctionHook.PoolData[]",
        "components": [
          {"name": "poolId", "type": "bytes32", "internalType": "bytes32"},
          {"name": "token0", "type": "address", "internalType": "address"},
          {"name": "token1", "type": "address", "internalType": "address"},
          {"name": "fee", "type": "uint24", "internalType": "uint24"},
          {"name": "liquidity", "type": "uint128", "internalType": "uint128"},
          {"name": "tick", "type": "int24", "internalType": "int24"},
          {"name": "isActive", "type": "bool", "internalType": "bool"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getActiveAuctions",
    "inputs": [],
    "outputs": [
      {
        "name": "auctions",
        "type": "tuple[]",
        "internalType": "struct MEVAuctionHook.AuctionData[]",
        "components": [
          {"name": "auctionId", "type": "bytes32", "internalType": "bytes32"},
          {"name": "poolId", "type": "bytes32", "internalType": "bytes32"},
          {"name": "highestBid", "type": "uint256", "internalType": "uint256"},
          {"name": "highestBidder", "type": "address", "internalType": "address"},
          {"name": "deadline", "type": "uint256", "internalType": "uint256"},
          {"name": "isActive", "type": "bool", "internalType": "bool"},
          {"name": "totalMEVCollected", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getUserBids",
    "inputs": [
      {"name": "user", "type": "address", "internalType": "address"}
    ],
    "outputs": [
      {
        "name": "userBids",
        "type": "tuple[]",
        "internalType": "struct MEVAuctionHook.AuctionData[]",
        "components": [
          {"name": "auctionId", "type": "bytes32", "internalType": "bytes32"},
          {"name": "poolId", "type": "bytes32", "internalType": "bytes32"},
          {"name": "highestBid", "type": "uint256", "internalType": "uint256"},
          {"name": "highestBidder", "type": "address", "internalType": "address"},
          {"name": "deadline", "type": "uint256", "internalType": "uint256"},
          {"name": "isActive", "type": "bool", "internalType": "bool"},
          {"name": "totalMEVCollected", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getMEVMetrics",
    "inputs": [],
    "outputs": [
      {
        "name": "metrics",
        "type": "tuple",
        "internalType": "struct MEVAuctionHook.MEVMetrics",
        "components": [
          {"name": "totalMEVPrevented", "type": "uint256", "internalType": "uint256"},
          {"name": "totalAuctions", "type": "uint256", "internalType": "uint256"},
          {"name": "averageAuctionTime", "type": "uint256", "internalType": "uint256"},
          {
            "name": "topPools",
            "type": "tuple[]",
            "internalType": "struct MEVAuctionHook.PoolData[]",
            "components": [
              {"name": "poolId", "type": "bytes32", "internalType": "bytes32"},
              {"name": "token0", "type": "address", "internalType": "address"},
              {"name": "token1", "type": "address", "internalType": "address"},
              {"name": "fee", "type": "uint24", "internalType": "uint24"},
              {"name": "liquidity", "type": "uint128", "internalType": "uint128"},
              {"name": "tick", "type": "int24", "internalType": "int24"},
              {"name": "isActive", "type": "bool", "internalType": "bool"}
            ]
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "BidSubmitted",
    "inputs": [
      {"name": "auctionId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "bidder", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "amount", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "AuctionExecuted",
    "inputs": [
      {"name": "auctionId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "winner", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "winningBid", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "PoolCreated",
    "inputs": [
      {"name": "poolId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "token0", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "token1", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "fee", "type": "uint24", "indexed": false, "internalType": "uint24"}
    ],
    "anonymous": false
  }
] as const;