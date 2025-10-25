/**
 * Hardhat 3 Configuration for MEVShield Pool
 * Advanced testing and deployment configuration using Hardhat 3 Alpha
 * 
 * Features:
 * - Multi-chain deployment support
 * - Advanced testing with Solidity tests
 * - Performance optimization with Rust components
 * - OP Stack simulation capabilities
 * - Modernized CLI and plugin system
 * 
 * Built for Hardhat $5,000 Best Projects using Hardhat 3 Prize
 */

require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-verify");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-deploy");
require("@openzeppelin/hardhat-upgrades");

// Load environment variables
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000000";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || "";
const ARBISCAN_API_KEY = process.env.ARBISCAN_API_KEY || "";
const OPTIMISM_API_KEY = process.env.OPTIMISM_API_KEY || "";
const BASESCAN_API_KEY = process.env.BASESCAN_API_KEY || "";

// RPC URLs
const ETHEREUM_RPC = process.env.ETHEREUM_RPC || "https://eth-mainnet.alchemyapi.io/v2/your-api-key";
const SEPOLIA_RPC = process.env.SEPOLIA_RPC || "https://eth-sepolia.g.alchemy.com/v2/your-api-key";
const POLYGON_RPC = process.env.POLYGON_RPC || "https://polygon-mainnet.g.alchemy.com/v2/your-api-key";
const ARBITRUM_RPC = process.env.ARBITRUM_RPC || "https://arb-mainnet.g.alchemy.com/v2/your-api-key";
const OPTIMISM_RPC = process.env.OPTIMISM_RPC || "https://opt-mainnet.g.alchemy.com/v2/your-api-key";
const BASE_RPC = process.env.BASE_RPC || "https://mainnet.base.org";
const HEDERA_RPC = process.env.HEDERA_RPC || "https://mainnet.hashio.io/api";
const ARCOLOGY_RPC = process.env.ARCOLOGY_RPC || "https://devnet.arcology.network/rpc";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  // Hardhat 3 specific configuration
  version: "3.0.0-alpha.1",
  
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yul: true,
          yulDetails: {
            stackAllocation: true,
            optimizerSteps: "dhfoDgvulfnTUtnIf"
          }
        }
      },
      viaIR: true,
      metadata: {
        bytecodeHash: "none"
      }
    },
    // Multiple compiler versions for different contracts
    compilers: [
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.26", // For newer contracts
        settings: {
          optimizer: {
            enabled: true,
            runs: 800 // Higher optimization for frequently called contracts
          }
        }
      }
    ]
  },

  // Networks configuration for multi-chain deployment
  networks: {
    // Local development
    hardhat: {
      chainId: 31337,
      gas: 12000000,
      blockGasLimit: 12000000,
      allowUnlimitedContractSize: true,
      timeout: 120000,
      forking: {
        url: ETHEREUM_RPC,
        blockNumber: 18500000 // Pin to specific block for consistency
      },
      // Hardhat 3 parallel execution
      parallel: {
        enabled: true,
        workers: 4
      }
    },

    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
      gas: 12000000,
      timeout: 120000
    },

    // Ethereum networks
    mainnet: {
      url: ETHEREUM_RPC,
      accounts: [PRIVATE_KEY],
      chainId: 1,
      gas: 8000000,
      gasPrice: 20000000000, // 20 gwei
      timeout: 120000,
      confirmations: 2
    },

    sepolia: {
      url: SEPOLIA_RPC,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
      gas: 8000000,
      gasPrice: 10000000000, // 10 gwei
      timeout: 120000,
      confirmations: 1
    },

    // Layer 2 networks
    polygon: {
      url: POLYGON_RPC,
      accounts: [PRIVATE_KEY],
      chainId: 137,
      gas: 8000000,
      gasPrice: 30000000000, // 30 gwei
      timeout: 120000,
      confirmations: 2
    },

    polygonMumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [PRIVATE_KEY],
      chainId: 80001,
      gas: 8000000,
      gasPrice: 10000000000,
      timeout: 120000
    },

    arbitrumOne: {
      url: ARBITRUM_RPC,
      accounts: [PRIVATE_KEY],
      chainId: 42161,
      gas: 8000000,
      timeout: 120000,
      confirmations: 1
    },

    arbitrumGoerli: {
      url: "https://goerli-rollup.arbitrum.io/rpc",
      accounts: [PRIVATE_KEY],
      chainId: 421613,
      gas: 8000000,
      timeout: 120000
    },

    optimisticEthereum: {
      url: OPTIMISM_RPC,
      accounts: [PRIVATE_KEY],
      chainId: 10,
      gas: 8000000,
      timeout: 120000,
      confirmations: 1
    },

    optimisticGoerli: {
      url: "https://goerli.optimism.io",
      accounts: [PRIVATE_KEY],
      chainId: 420,
      gas: 8000000,
      timeout: 120000
    },

    base: {
      url: BASE_RPC,
      accounts: [PRIVATE_KEY],
      chainId: 8453,
      gas: 8000000,
      timeout: 120000,
      confirmations: 1
    },

    baseGoerli: {
      url: "https://goerli.base.org",
      accounts: [PRIVATE_KEY],
      chainId: 84531,
      gas: 8000000,
      timeout: 120000
    },

    // Avalanche
    avalanche: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      accounts: [PRIVATE_KEY],
      chainId: 43114,
      gas: 8000000,
      timeout: 120000
    },

    avalancheFuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [PRIVATE_KEY],
      chainId: 43113,
      gas: 8000000,
      timeout: 120000
    },

    // Hedera
    hedera: {
      url: HEDERA_RPC,
      accounts: [PRIVATE_KEY],
      chainId: 295,
      gas: 10000000,
      timeout: 120000
    },

    hederaTestnet: {
      url: "https://testnet.hashio.io/api",
      accounts: [PRIVATE_KEY],
      chainId: 296,
      gas: 10000000,
      timeout: 120000
    },

    // Arcology DevNet
    arcology: {
      url: ARCOLOGY_RPC,
      accounts: [PRIVATE_KEY],
      chainId: 789,
      gas: 20000000, // Higher gas limit for parallel execution
      timeout: 300000, // Longer timeout for complex operations
      // Arcology-specific parallel execution settings
      parallel: {
        enabled: true,
        maxWorkers: 8
      }
    }
  },

  // Enhanced verification for multi-chain deployment
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
      sepolia: ETHERSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY,
      polygonMumbai: POLYGONSCAN_API_KEY,
      arbitrumOne: ARBISCAN_API_KEY,
      arbitrumGoerli: ARBISCAN_API_KEY,
      optimisticEthereum: OPTIMISM_API_KEY,
      optimisticGoerli: OPTIMISM_API_KEY,
      base: BASESCAN_API_KEY,
      baseGoerli: BASESCAN_API_KEY,
      avalanche: "snowtrace",
      avalancheFuji: "snowtrace"
    },
    customChains: [
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org"
        }
      },
      {
        network: "baseGoerli",
        chainId: 84531,
        urls: {
          apiURL: "https://api-goerli.basescan.org/api",
          browserURL: "https://goerli.basescan.org"
        }
      },
      {
        network: "hedera",
        chainId: 295,
        urls: {
          apiURL: "https://server-verify.hashscan.io",
          browserURL: "https://hashscan.io"
        }
      },
      {
        network: "arcology",
        chainId: 789,
        urls: {
          apiURL: "https://devnet.arcology.network/api",
          browserURL: "https://devnet.arcology.network"
        }
      }
    ]
  },

  // Gas reporting configuration
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    gasPrice: 20,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    maxMethodDiff: 10,
    // Hardhat 3 enhanced gas reporting
    includeIntrinsicGas: true,
    showTimeSpent: true,
    outputFile: "gas-report.txt",
    noColors: true
  },

  // Contract size reporting
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    only: ["MEVAuctionHook", "PythPriceOracle", "LitMPCManager"]
  },

  // Testing configuration for Hardhat 3
  mocha: {
    timeout: 300000, // 5 minutes
    parallel: true, // Hardhat 3 parallel testing
    jobs: 4,
    reporter: "spec",
    reporterOptions: {
      maxDiffSize: 8192
    }
  },

  // Deployment configuration
  namedAccounts: {
    deployer: {
      default: 0,
      1: 0, // mainnet
      137: 0, // polygon
      42161: 0, // arbitrum
      10: 0, // optimism
      8453: 0, // base
      43114: 0, // avalanche
      295: 0, // hedera
      789: 0 // arcology
    },
    admin: {
      default: 1,
      1: "0x742d35Cc6631C0532925a3b8D1C9Eff31de2569", // mainnet admin
      137: "0x742d35Cc6631C0532925a3b8D1C9Eff31de2569" // polygon admin
    }
  },

  // Paths configuration
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
    deploy: "./deploy",
    deployments: "./deployments"
  },

  // External contracts for testing
  external: {
    contracts: [
      {
        artifacts: "node_modules/@uniswap/v4-core/artifacts",
        deploy: "node_modules/@uniswap/v4-core/deploy"
      },
      {
        artifacts: "node_modules/@pythnetwork/pyth-sdk-solidity/artifacts"
      }
    ],
    deployments: {
      hardhat: [
        "node_modules/@uniswap/v4-core/deployments/hardhat",
        "node_modules/@pythnetwork/pyth-sdk-solidity/deployments/hardhat"
      ]
    }
  },

  // Hardhat 3 specific features
  hardhat3: {
    // Rust-based performance optimizations
    rustOptimizations: {
      enabled: true,
      compilation: true,
      execution: true
    },

    // OP Stack simulation
    opStack: {
      enabled: true,
      l1ChainId: 1,
      l2ChainId: 10
    },

    // Enhanced debugging
    debugging: {
      enabled: true,
      printOpcodes: false,
      printMemory: false,
      printStack: false
    },

    // Parallel execution configuration
    parallelism: {
      compilation: {
        enabled: true,
        workers: 4
      },
      testing: {
        enabled: true,
        workers: 4
      }
    }
  },

  // TypeChain configuration for type-safe contract interactions
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v6",
    alwaysGenerateOverloads: false,
    externalArtifacts: [
      "node_modules/@uniswap/v4-core/artifacts/contracts/**/*.sol/!(*.dbg.json)",
      "node_modules/@pythnetwork/pyth-sdk-solidity/artifacts/contracts/**/*.sol/!(*.dbg.json)"
    ]
  },

  // Defender configuration for automated operations
  defender: {
    apiKey: process.env.DEFENDER_API_KEY,
    apiSecret: process.env.DEFENDER_API_SECRET
  },

  // Coverage configuration
  solidity_coverage: {
    includePaths: ["./src"],
    excludePaths: ["./test", "./node_modules"],
    measureStatementCoverage: true,
    measureBranchCoverage: true,
    measureFunctionCoverage: true,
    measureLineCoverage: true
  }
};

// Export deployment tasks
require("./tasks/deploy-all");
require("./tasks/verify-all");
require("./tasks/test-integration");
require("./tasks/benchmark-performance");