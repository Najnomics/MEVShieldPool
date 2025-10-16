export const YELLOW_STATE_CHANNEL_ABI = [
  {
    "type": "function",
    "name": "openStateChannel",
    "inputs": [
      {"name": "counterparty", "type": "address", "internalType": "address"},
      {"name": "initialDeposit", "type": "uint256", "internalType": "uint256"}
    ],
    "outputs": [
      {"name": "channelId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "updateChannelState",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "internalType": "bytes32"},
      {"name": "newBalance1", "type": "uint256", "internalType": "uint256"},
      {"name": "newBalance2", "type": "uint256", "internalType": "uint256"},
      {"name": "nonce", "type": "uint256", "internalType": "uint256"},
      {"name": "signature1", "type": "bytes", "internalType": "bytes"},
      {"name": "signature2", "type": "bytes", "internalType": "bytes"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "closeChannel",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initiateDispute",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "internalType": "bytes32"},
      {"name": "disputedStateRoot", "type": "bytes32", "internalType": "bytes32"},
      {"name": "proof", "type": "bytes", "internalType": "bytes"}
    ],
    "outputs": [
      {"name": "disputeId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "resolveDispute",
    "inputs": [
      {"name": "disputeId", "type": "bytes32", "internalType": "bytes32"},
      {"name": "resolution", "type": "bytes", "internalType": "bytes"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getChannelInfo",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {
        "name": "channel",
        "type": "tuple",
        "internalType": "struct YellowStateChannel.EnhancedStateChannel",
        "components": [
          {"name": "participant1", "type": "address", "internalType": "address"},
          {"name": "participant2", "type": "address", "internalType": "address"},
          {"name": "balance1", "type": "uint256", "internalType": "uint256"},
          {"name": "balance2", "type": "uint256", "internalType": "uint256"},
          {"name": "nonce", "type": "uint256", "internalType": "uint256"},
          {"name": "stateRoot", "type": "bytes32", "internalType": "bytes32"},
          {"name": "isActive", "type": "bool", "internalType": "bool"},
          {"name": "createdAt", "type": "uint256", "internalType": "uint256"},
          {"name": "lastUpdated", "type": "uint256", "internalType": "uint256"},
          {"name": "challengeDeadline", "type": "uint256", "internalType": "uint256"},
          {"name": "status", "type": "uint8", "internalType": "enum YellowStateChannel.ChannelStatus"}
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "validateStateTransition",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "internalType": "bytes32"},
      {"name": "oldStateRoot", "type": "bytes32", "internalType": "bytes32"},
      {"name": "newStateRoot", "type": "bytes32", "internalType": "bytes32"},
      {"name": "signatures", "type": "bytes[]", "internalType": "bytes[]"}
    ],
    "outputs": [
      {"name": "isValid", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "emergencyWithdraw",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "internalType": "bytes32"}
    ],
    "outputs": [
      {"name": "success", "type": "bool", "internalType": "bool"}
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getUserChannels",
    "inputs": [
      {"name": "user", "type": "address", "internalType": "address"}
    ],
    "outputs": [
      {"name": "channelIds", "type": "bytes32[]", "internalType": "bytes32[]"}
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "StateChannelOpened",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "participant1", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "participant2", "type": "address", "indexed": true, "internalType": "address"},
      {"name": "initialDeposit", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "StateChannelUpdated",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "newStateRoot", "type": "bytes32", "indexed": false, "internalType": "bytes32"},
      {"name": "nonce", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "StateChannelClosed",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "finalBalance1", "type": "uint256", "indexed": false, "internalType": "uint256"},
      {"name": "finalBalance2", "type": "uint256", "indexed": false, "internalType": "uint256"}
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "DisputeInitiated",
    "inputs": [
      {"name": "channelId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "disputeId", "type": "bytes32", "indexed": true, "internalType": "bytes32"},
      {"name": "initiator", "type": "address", "indexed": true, "internalType": "address"}
    ],
    "anonymous": false
  }
] as const;