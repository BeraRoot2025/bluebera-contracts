require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config({ path: "env.mainnet.config" });

const {
  PRIVATE_KEY,
  BERA_MAINNET_RPC,
  ETHERSCAN_API_KEY_BERA
} = process.env;

module.exports = {
  solidity: {
    version: "0.8.28",
    settings: { optimizer: { enabled: true, runs: 500 } }
  },
  networks: {
    // Berachain Mainnet
    berachain: {
      chainId: 80094,
      url: BERA_MAINNET_RPC || "https://rpc.berachain.com",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      timeout: 300000, // 5 minutes
      gasPrice: "auto",
      gas: "auto"
    },
    
    // Alternative RPC endpoints
    berachainAlt: {
      chainId: 80094,
      url: "https://rpc.berachain.com",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      timeout: 600000, // 10 minutes
      gasPrice: "auto",
      gas: "auto"
    },
    
    // Conservative settings
    berachainConservative: {
      chainId: 80094,
      url: "https://rpc.berachain.com",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      timeout: 900000, // 15 minutes
      gasPrice: 1000000000, // 1 gwei
      gas: 5000000,
      allowUnlimitedContractSize: true
    },
    
    // HTTP client optimized settings
    berachainOptimized: {
      chainId: 80094,
      url: "https://rpc.berachain.com",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      timeout: 600000, // 10 minutes
      gasPrice: "auto",
      gas: "auto",
      // Custom HTTP client settings
      httpHeaders: {
        "User-Agent": "Hardhat/2.22.10",
        "Accept": "application/json",
        "Content-Type": "application/json"
      }
    }
  },
  etherscan: {
    apiKey: {
      berachain: ETHERSCAN_API_KEY_BERA || "DUMMY"
    },
    customChains: [
      {
        network: "berachain",
        chainId: 80094,
        // Fill in compatible API based on your mainnet browser choice (choose one)
        apiURL: "https://api.berascan.com/api",   // BeraScan (Etherscan compatible)
        browserURL: "https://berascan.com"
      }
      // If you need to switch to another compatible browser (e.g. Routescan/beratrail), change the above two URLs to corresponding addresses
    ]
  }
};
