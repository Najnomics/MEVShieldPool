export const LIGHTHOUSE_STORAGE_ABI = [
  {
    "type": "function",
    "name": "uploadFile",
    "inputs": [
      {"name": "data", "type": "bytes", "internalType": "bytes"},
      {"name": "mimeType", "type": "string", "internalType": "string"},
      {"name": "replicationFactor", "type": "uint256", "internalType": "uint256"},
      {"name": "encrypted", "type": "bool", "internalType": "bool"},
      {"name": "accessConditions", "type": "bytes[]", "internalType": "bytes[]"}
    ],
    "outputs": [
      {"name": "fileHash", "type": "string", "internalType": "string"}
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "getFile",
    "inputs": [
      {"name": "fileHash", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {"name": "data", "type": "bytes", "internalType": "bytes"},
      {"name": "metadata", "type": "tuple", "internalType": "struct LighthouseStorageManager.FileMetadata",
        "components": [
          {"name": "size", "type": "uint256", "internalType": "uint256"},
          {"name": "mimeType", "type": "string", "internalType": "string"},
          {"name": "uploadTime", "type": "uint256", "internalType": "uint256"},
          {"name": "uploader", "type": "address", "internalType": "address"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "deleteFile",
    "inputs": [
      {"name": "fileHash", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "shareFile",
    "inputs": [
      {"name": "fileHash", "type": "string", "internalType": "string"},
      {"name": "recipient", "type": "address", "internalType": "address"},
      {"name": "accessLevel", "type": "uint8", "internalType": "uint8"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "pinToIPFS",
    "inputs": [
      {"name": "fileHash", "type": "string", "internalType": "string"}
    ],
    "outputs": [
      {"name": "ipfsHash", "type": "string", "internalType": "string"}
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "getStorageStats",
    "inputs": [
      {"name": "user", "type": "address", "internalType": "address"}
    ],
    "outputs": [
      {
        "name": "stats",
        "type": "tuple",
        "internalType": "struct LighthouseStorageManager.StorageStats",
        "components": [
          {"name": "totalFiles", "type": "uint256", "internalType": "uint256"},
          {"name": "totalSize", "type": "uint256", "internalType": "uint256"},
          {"name": "storageUsed", "type": "uint256", "internalType": "uint256"},
          {"name": "totalCost", "type": "uint256", "internalType": "uint256"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "enableKavachEncryption",
    "inputs": [
      {"name": "fileHash", "type": "string", "internalType": "string"},
      {"name": "publicKey", "type": "bytes", "internalType": "bytes"}
    ],
    "outputs": [
      {"name": "encryptedHash", "type": "string", "internalType": "string"}
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "decryptKavachFile",
    "inputs": [
      {"name": "encryptedHash", "type": "string", "internalType": "string"},
      {"name": "privateKey", "type": "bytes", "internalType": "bytes"}
    ],
    "outputs": [
      {"name": "decryptedData", "type": "bytes", "internalType": "bytes"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getUserFiles",
    "inputs": [
      {"name": "user", "type": "address", "internalType": "address"}
    ],
    "outputs": [
      {"name": "fileHashes", "type": "string[]", "internalType": "string[]"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "FileUploaded",
    "inputs": [
      {"name": "fileHash", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "uploader", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "size", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "FileShared",
    "inputs": [
      {"name": "fileHash", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "owner", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "recipient", "type": "address", "indexed": true, "internalType": "address"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "FileDeleted",
    "inputs": [
      {"name": "fileHash", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "owner", "type": "address", "indexed": true, "internalType": "address"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "FilePinnedToIPFS",
    "inputs": [
      {"name": "fileHash", "type": "string", "indexed": true, "internalType": "string"},
      {"name": "ipfsHash", "type": "string", "indexed": false, "internalType": "string"}
    ],
    "anonymous": false
  }
] as const;