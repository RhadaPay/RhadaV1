import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import '@typechain/hardhat';
import fs from "fs";

const privateKey =  fs.readFileSync(".env").toString().trim();

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "matic",
  networks: {
    hardhat: {
    },
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [privateKey]
    }
  },
  solidity: {
    version: "0.7.1",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./src/Backend/Contracts",
    tests: "./src/Backend/test",
    cache: "./src/Backend/cache",
    artifacts: "./src/Backend/Contracts/artifacts"
  },
  mocha: {
    timeout: 20000
  }
};
