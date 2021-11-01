require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
//require('hardhat-gas-reporter');

const config = require('./.private.json');
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 256
      }
    }
  },
  networks: {
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${config.alchemy.mainnet.apiKey}`,
      accounts: [config.account.mainnet.key, config.account.mainnet.userA, config.account.mainnet.userB],
      gas: 6e6,
      gasPrice: 1e9,
      timeout: 2000000000
    },
    ropsten: {
      url: `https://eth-ropsten.alchemyapi.io/v2/${config.alchemy.ropsten.apiKey}`,
      accounts: [config.account.ropsten.key, config.account.ropsten.userA, config.account.ropsten.userB],
      gas: 6e6,
      initialBaseFeePerGas: 1e9,
      timeout: 2000000000
    },
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${config.alchemy.rinkeby.apiKey}`,
      accounts: [config.account.rinkeby.key, config.account.rinkeby.userA, config.account.rinkeby.userB],
      gas: 6e6,
      initialBaseFeePerGas: 1e9,
      timeout: 2000000000
    },
    kovan: {
      url: `https://eth-kovan.alchemyapi.io/v2/${config.alchemy.kovan.apiKey}`,
      accounts: [config.account.kovan.key, config.account.kovan.userA, config.account.kovan.userB],
      gasPrice:1e9,
      timeout: 2000000000
    },
    hardhat: {
      gas: 6000000,
      initialBaseFeePerGas: 0,
      gasPrice: 0
    }
  },
  mocha: {
    timeout: 200000000
  },
  // gasReporter: {
  //   currency: 'CHF',
  //   gasPrice: 1
  // }
};

