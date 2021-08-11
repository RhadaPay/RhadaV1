import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import '@typechain/hardhat';

require("dotenv").config();

import 'hardhat-deploy';

import { HardhatUserConfig } from "hardhat/config";


const config: HardhatUserConfig =  {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    mumbai: {
      url: process.env.MUMBAI_RPC,
      chainId: 80001,
      accounts: [ process.env.PRIVATE_KEY as string, process.env.PRIVATE_KEY2 as string ]
    }
  },
  solidity: {
    version: "0.7.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1
      }
    }
  },
  paths: {
    sources: "./Contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  },
  namedAccounts: {
    deployer: 0,
    buyer: 0,
    seller: 1,
    host: {
      "mumbai": '0xEB796bdb90fFA0f28255275e16936D25d3418603'
    },
    cfa: {
      "mumbai": '0x49e565Ed1bdc17F3d220f72DF0857C26FA83F873'
    },
    acceptedToken: {
      "mumbai": '0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f'
    },
    oracle: {
      "mumbai": '0xD71352a10Ca84d3DF6602c3943F3825e13F655D0'
    }
  },
};

export default config;