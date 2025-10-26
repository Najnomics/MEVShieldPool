// Contract addresses and configuration for Sepolia Testnet
export const SEPOLIA_CHAIN_ID = 11155111;

export const CONTRACT_ADDRESSES = {
  [SEPOLIA_CHAIN_ID]: {
    mevAuctionHook: '0xB511417B2D983e6A86dff5663A08d01462036aC0' as const,
    pythPriceOracle: '0x3d0f3EB4Bd1263a02BF70b2a6BcEaD21E7E654d2' as const,
    litMPCManager: '0x5eBD47dc03f512Afa54aB323B79060792aE56Ea7' as const,
    yellowStateChannel: '0x1Bd94cB5Eccb3968a229814c7CAe8B97795cE177' as const,
    poolManager: '0xE03A1074c86CFeDd5C142C4F04F1a1536e203543' as const,
  },
} as const;

// RPC URLs
export const RPC_URLS = {
  [SEPOLIA_CHAIN_ID]: 'https://eth-sepolia.g.alchemy.com/v2/FlEUrYqZ9gYvgFxtEVA6zWB0zrQwGL4N',
} as const;

// Known Pool IDs (from initialization)
export const KNOWN_POOLS = [
  {
    poolId: '26282756708538069910862534158750760320053768499940364003422645886916113207248',
    token0: '0x3932ED745f6e348CcE56621c4ff9Da47Afbf7945',
    token1: '0xe6ee6FBE2E0f047bd082a60d70FcDBF637eC3d38',
    fee: 3000,
  },
] as const;

