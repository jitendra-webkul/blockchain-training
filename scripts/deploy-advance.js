const { ethers, upgrades } = require('hardhat');

async function main () {
    const NFTAdvance = await ethers.getContractFactory('NFTAdvance');
    const nftAdvance = await upgrades.deployProxy(NFTAdvance);
    
    await nftAdvance.deployed();

    console.log('NFT Advance Contract Deployed To:', nftAdvance.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });