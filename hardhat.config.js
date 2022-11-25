require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');

module.exports = {
    defaultNetwork: "hardhat",
    
    solidity: {
        version: "0.8.4",

        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },

    networks: {
        hardhat: {
            chainId: 1337
        },

        goerli: {
            url: 'wss://eth-goerli.g.alchemy.com/v2/P6uTj-8SmVw8rr3a68hLAyxx4wrRrNso',
            accounts: ['']
        }
    }
}