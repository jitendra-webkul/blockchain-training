const { ethers, upgrades } = require('hardhat');

async function main () {
    const NFTSimple = await ethers.getContractFactory('NFTSimple');
    const nftSimple = await upgrades.deployProxy(NFTSimple);
    
    await nftSimple.deployed();

    console.log('NFT Simple Contract Deployed To:', nftSimple.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });