/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * trufflesuite.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

const HDWalletProvider = require('@truffle/hdwallet-provider');
require("dotenv").config();
const GAS_LIMIT = 8000000;


// const infuraKey = "fj4jll3k.....";
//
// const fs = require('fs');
// const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    goerli: {
      provider: () =>
          new HDWalletProvider(
              process.env.PRIVATE_KEY,
              process.env.GOERLI_PROVIDER_URL
          ),
      network_id: 5, // Goerli's id
      gas: GAS_LIMIT,
      gasPrice: 11e9, // 10 GWEI
      //confirmations: 6, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 100, // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true // Skip dry run before migrations? (default: false for public nets )
  },
  mumbai: {
    provider: () =>
        new HDWalletProvider(
            process.env.PRIVATE_KEY,
            process.env.MUMBAI_PROVIDER_URL
        ),
    network_id: 80001, // Mumbai's id
    gas: GAS_LIMIT,
    gasPrice: 11e9, // 10 GWEI
    //confirmations: 6, // # of confs to wait between deployments. (default: 0)
    timeoutBlocks: 100, // # of blocks before a deployment times out  (minimum/default: 50)
    skipDryRun: true // Skip dry run before migrations? (default: false for public nets )
}
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
        version: "0.7.6", // Fetch exact version from solc-bin (default: truffle's version),
        settings: {
            optimizer: {
              enabled: true,
              runs: 200
            }
          }
    }
},

  // Truffle DB is currently disabled by default; to enable it, change enabled: false to enabled: true
  //
  // Note: if you migrated your contracts prior to enabling this field in your Truffle project and want
  // those previously migrated contracts available in the .db directory, you will need to run the following:
  // $ truffle migrate --reset --compile-all

  db: {
    enabled: false
  }
};
