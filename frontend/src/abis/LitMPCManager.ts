export const LIT_MPC_MANAGER_ABI = [
  {
    "type": "function",
    "name": "encryptBid",
    "inputs": [
      {"name": "poolId", "type": "bytes32", "internalType": "bytes32"},
      {"name": "amount", "type": "uint256", "internalType": "uint256"},
      {"name": "accessConditions", "type": "bytes", "internalType": "bytes"}
    ],
    "outputs": [
      {"name": "encryptedData", "type": "bytes", "internalType": "bytes"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "decryptBid",
    "inputs": [
      {"name": "encryptedData", "type": "bytes", "internalType": "bytes"},
      {"name": "sessionKeyHash", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {"name": "amount", "type": "uint256", "internalType": "uint256"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "generateSessionKey",
    "inputs": [
      {"name": "poolId", "type": "bytes32", "internalType": "bytes32"},
      {"name": "duration", "type": "uint256", "internalType": "uint256"}
    ],
    "outputs": [
      {"name": "sessionKeyHash", "type": "bytes32", "internalType": "bytes32"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "executeLitAction",
    "inputs": [
      {"name": "actionCode", "type": "string", "internalType": "string"},
      {"name": "actionParams", "type": "bytes", "internalType": "bytes"}
    ],
    "outputs": [
      {"name": "result", "type": "bytes", "internalType": "bytes"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initializePoolMPC",
    "inputs": [
      {"name": "poolId", "type": "bytes32", "internalType": "bytes32"},
      {"name": "threshold", "type": "uint256", "internalType": "uint256"},
      {"name": "nodeAddresses", "type": "address[]", "internalType": "address[]"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "validateMPCSignature",
    "inputs": [
      {"name": "signature", "type": "bytes", "internalType": "bytes"},
      {"name": "messageHash", "type": "bytes32", "internalType": "bytes32"},
      {"name": "poolId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {"name": "isValid", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getPoolMPCParams",
    "inputs": [
      {"name": "poolId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {
        "name": "params",
        "type": "tuple",
        "internalType": "struct LitMPCManager.EnhancedMPCParams",
        "components": [
          {"name": "threshold", "type": "uint256", "internalType": "uint256"},
          {"name": "totalNodes", "type": "uint256", "internalType": "uint256"},
          {"name": "activeNodes", "type": "uint256", "internalType": "uint256"},
          {"name": "encryptionAlgorithm", "type": "uint8", "internalType": "enum LitMPCManager.EncryptionAlgorithm"},
          {"name": "teeProtected", "type": "bool", "internalType": "bool"},
          {"name": "isActive", "type": "bool", "internalType": "bool"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getSessionKeyInfo",
    "inputs": [
      {"name": "sessionKeyHash", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {
        "name": "keyInfo",
        "type": "tuple",
        "internalType": "struct LitMPCManager.SessionKeyInfo",
        "components": [
          {"name": "poolId", "type": "bytes32", "internalType": "bytes32"},
          {"name": "creator", "type": "address", "internalType": "address"},
          {"name": "expiryTime", "type": "uint256", "internalType": "uint256"},
          {"name": "isActive", "type": "bool", "internalType": "bool"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "BidEncrypted",
    "inputs": [
      {"name": "poolId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "bidder", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "sessionKeyHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "SessionKeyGenerated",
    "inputs": [
      {"name": "poolId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "sessionKeyHash", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "creator", "type": "address", "indexed": true, "internalType": "address"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "LitActionExecuted",
    "inputs": [
      {"name": "actionHash", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "executor", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "gasUsed", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  }
] as const;