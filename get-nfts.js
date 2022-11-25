// Installation: https://github.com/alchemyplatform/alchemy-web3

const { createAlchemyWeb3 } = require("@alch/alchemy-web3");

const util = require('util')

var init = async function () {
    // Using HTTPS
    const web3 = createAlchemyWeb3("https://eth-rinkeby.alchemyapi.io/v2/cfO6P-WEAlfdiQWPN6jLPwq0gfFP9f5a");

    // const nfts = await web3.alchemy.getNfts({owner: "0xec3Acf0ab88aeA4B60141ABc8dCb626c1c4FfC57"})
    const nfts = await web3.alchemy.getNfts({owner: "0xc805C99858EFfC2067E12Aba334f37DD0C98E9a4"})
    // const nfts = await web3.alchemy.getNfts({owner: "0xec3Acf0ab88aeA4B60141ABc8dCb626c1c4FfC57", contractAddresses: ["0x39ed051a1a3a1703b5e0557b122ec18365dbc184"]})

    console.log(util.inspect(nfts, false, null, true));
};

init();