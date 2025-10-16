export const PYTH_PRICE_ORACLE_ABI = [
  {
    "type": "function",
    "name": "getPrice",
    "inputs": [
      {"name": "priceId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {
        "name": "price",
        "type": "tuple",
        "internalType": "struct PythStructs.Price",
        "components": [
          {"name": "price", "type": "int64", "internalType": "int64"},
          {"name": "conf", "type": "uint64", "internalType": "uint64"},
          {"name": "expo", "type": "int32", "internalType": "int32"},
          {"name": "publishTime", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getPriceUnsafe",
    "inputs": [
      {"name": "priceId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {
        "name": "price",
        "type": "tuple",
        "internalType": "struct PythStructs.Price",
        "components": [
          {"name": "price", "type": "int64", "internalType": "int64"},
          {"name": "conf", "type": "uint64", "internalType": "uint64"},
          {"name": "expo", "type": "int32", "internalType": "int32"},
          {"name": "publishTime", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "updatePriceFeeds",
    "inputs": [
      {"name": "updateData", "type": "bytes[]", "internalType": "bytes[]"}
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "getUpdateFee",
    "inputs": [
      {"name": "updateData", "type": "bytes[]", "internalType": "bytes[]"}
    ],
    "outputs": [
      {"name": "feeAmount", "type": "uint256", "internalType": "uint256"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getValidTimePeriod",
    "inputs": [],
    "outputs": [
      {"name": "validTimePeriod", "type": "uint256", "internalType": "uint256"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "calculateMEVOpportunity",
    "inputs": [
      {"name": "priceId1", "type": "bytes32", "internalType": "bytes32"},
      {"name": "priceId2", "type": "bytes32", "internalType": "bytes32"},
      {"name": "amount", "type": "uint256", "internalType": "uint256"}
    ],
    "outputs": [
      {"name": "mevValue", "type": "uint256", "internalType": "uint256"},
      {"name": "confidence", "type": "uint256", "internalType": "uint256"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getCachedPrice",
    "inputs": [
      {"name": "priceId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {
        "name": "cachedPrice",
        "type": "tuple",
        "internalType": "struct PythPriceOracle.CachedPrice",
        "components": [
          {"name": "price", "type": "int64", "internalType": "int64"},
          {"name": "conf", "type": "uint64", "internalType": "uint64"},
          {"name": "expo", "type": "int32", "internalType": "int32"},
          {"name": "publishTime", "type": "uint256", "internalType": "uint256"},
          {"name": "cacheTime", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "isPriceStale",
    "inputs": [
      {"name": "priceId", "type": "bytes32", "internalType": "bytes32"},
      {"name": "maxAge", "type": "uint256", "internalType": "uint256"}
    ],
    "outputs": [
      {"name": "isStale", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "PriceUpdated",
    "inputs": [
      {"name": "priceId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "price", "type": "int64", "indexed": false, "internalType": "int64"},
      {"name": "conf", "type": "uint64", "indexed": false, "internalType": "uint64"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "MEVOpportunityDetected",
    "inputs": [
      {"name": "priceId1", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "priceId2", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "mevValue", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  }
] as const;