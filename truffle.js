require('babel-register') 

var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "replace pitch sea step south oppose coconut vast fun coffee menu summer approve fly sign";

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"),
      network_id: 3
    }
  }
};