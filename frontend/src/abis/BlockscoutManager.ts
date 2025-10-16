export const BLOCKSCOUT_MANAGER_ABI = [
  {
    "type": "function",
    "name": "deployAutoscoutExplorer",
    "inputs": [
      {"name": "explorerName", "type": "string", "internalType": "string"},
      {"name": "chainName", "type": "string", "internalType": "string"},
      {"name": "chainId", "type": "uint256", "internalType": "uint256"},
      {"name": "rpcUrl", "type": "string", "internalType": "string"},
      {"name": "currency", "type": "string", "internalType": "string"},
      {"name": "isTestnet", "type": "bool", "internalType": "bool"},
      {"name": "logoUrl", "type": "string", "internalType": "string"},
      {"name": "brandColor", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {"name": "explorerUrl", "type": "string", "internalType": "string"}
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "getExplorerStatus",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {
        "name": "status",
        "type": "tuple",
        "internalType": "struct BlockscoutManager.ExplorerStatus",
        "components": [
          {"name": "isActive", "type": "bool", "internalType": "bool"},
          {"name": "deployedAt", "type": "uint256", "internalType": "uint256"},
          {"name": "lastUpdated", "type": "uint256", "internalType": "uint256"},
          {"name": "blockHeight", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "updateExplorerConfig",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "internalType": "string"},
      {"name": "newConfig", "type": "bytes", "internalType": "bytes"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "enableMEVInsights",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "internalType": "string"},
      {"name": "mevDetectionRules", "type": "bytes[]", "internalType": "bytes[]"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "configureMCPServer",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "internalType": "string"},
      {"name": "serverConfig", "type": "tuple", "internalType": "struct BlockscoutManager.MCPServerConfig",
        "components": [
          {"name": "apiEndpoint", "type": "string", "internalType": "string"},
          {"name": "aiModel", "type": "string", "internalType": "string"},
          {"name": "enableAnalytics", "type": "bool", "internalType": "bool"},
          {"name": "maxQueryRate", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getMEVReport",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "internalType": "string"},
      {"name": "fromBlock", "type": "uint256", "internalType": "uint256"},
      {"name": "toBlock", "type": "uint256", "internalType": "uint256"}
    ],
    "outputs": [
      {
        "name": "report",
        "type": "tuple",
        "internalType": "struct BlockscoutManager.MEVReport",
        "components": [
          {"name": "totalMEVDetected", "type": "uint256", "internalType": "uint256"},
          {"name": "arbitrageCount", "type": "uint256", "internalType": "uint256"},
          {"name": "sandwichCount", "type": "uint256", "internalType": "uint256"},
          {"name": "frontrunCount", "type": "uint256", "internalType": "uint256"},
          {"name": "averageGasPrice", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getExplorerMetrics",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {
        "name": "metrics",
        "type": "tuple",
        "internalType": "struct BlockscoutManager.ExplorerMetrics",
        "components": [
          {"name": "totalTransactions", "type": "uint256", "internalType": "uint256"},
          {"name": "totalBlocks", "type": "uint256", "internalType": "uint256"},
          {"name": "averageBlockTime", "type": "uint256", "internalType": "uint256"},
          {"name": "uptime", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "pauseExplorer",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getUserExplorers",
    "inputs": [
      {"name": "user", "type": "address", "internalType": "address"}
    ],
    "outputs": [
      {"name": "explorerUrls", "type": "string[]", "internalType": "string[]"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "ExplorerDeployed",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "deployer", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "chainId", "type": "uint256", "indexed": true, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "MEVInsightsEnabled",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "rulesCount", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "MCPServerConfigured",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "aiModel", "type": "string", "indexed": false, "internalType": "string"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ExplorerPaused",
    "inputs": [
      {"name": "explorerUrl", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "admin", "type": "address", "indexed": true, "internalType": "address"}
    ],
    "anonymous": false
  }
] as const;