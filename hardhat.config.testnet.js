require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: "env.testnet.config" });

module.exports = {
  solidity: "0.8.28",
  networks: {
    berachainBepolia: {
      url: "https://bepolia.rpc.berachain.com",
      chainId: 80069,
      accounts: [process.env.PRIVATE_KEY],   // Read from .env file
      timeout: 300000, // 5 minutes
      httpHeaders: { "User-Agent": "hardhat" },
    },
  },
};