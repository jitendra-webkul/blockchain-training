const util = require('util')

describe('NFTSimple', function() {
	it('Should create and execute nft sales', async function() {
		const NFTSimple = await ethers.getContractFactory('NFTSimple')
		const nftSimple = await upgrades.deployProxy(NFTSimple)
		await nftSimple.deployed()

		// Retrieve signers
		const [admin, newAdmin, buyer] = await ethers.getSigners();


		// Mint NFT with token id 1
		let transaction1 = await nftSimple.safeMint(admin.address, 1, '')

		receipt = await transaction1.wait();

		console.log("Token ID : " + receipt.events[0].args["tokenId"].toNumber())

		console.log(util.inspect(receipt, false, null, true))


		//Transfer ownership of contract to newAdmin
		let transaction2 = await nftSimple.transferOwnership(newAdmin.address)

		receipt = await transaction2.wait();

		console.log("Transfer Ownership of Contract to New Admin : " + util.inspect(receipt, false, null, true))


		//Grant approval to be owner of contract
		let transaction3 = await nftSimple.setApprovalForAll(newAdmin.address, true)

		receipt = await transaction3.wait();

		console.log("Approval Granter : " + util.inspect(receipt, false, null, true))


		// Mint NFT with token id 2
		let transaction4 = await nftSimple.connect(newAdmin).safeMint(newAdmin.address, 2, '')

		receipt = await transaction4.wait();

		console.log("Token ID : " + receipt.events[0].args["tokenId"].toNumber())

		console.log(util.inspect(receipt, false, null, true))


		// Transfer NFT with token id 1
		let transaction5 = await nftSimple.connect(newAdmin).transferFrom(admin.address, buyer.address, 1)

		receipt = await transaction5.wait();

		console.log("Token Transferred : " + util.inspect(receipt, false, null, true))
	})
})


describe('NFT1155', function() {
	it('Should create and execute nft sales', async function() {
		const NFT1155 = await ethers.getContractFactory('NFT1155')
		const nft1155 = await upgrades.deployProxy(NFT1155)
		await nft1155.deployed()


		// Retrieve signers
		const [admin, newAdmin, buyer] = await ethers.getSigners();


		// Mint NFT with token id 4
		let transaction1 = await nft1155.mint(admin.address, 4, 0, [])

		receipt = await transaction1.wait();

		console.log("Token ID : " + receipt.events[0].args["id"].toNumber())

		console.log(util.inspect(receipt, false, null, true))


		//Transfer ownership of contract to newAdmin
		let transaction2 = await nft1155.transferOwnership(newAdmin.address)

		receipt = await transaction2.wait();

		console.log("Transfer Ownership of Contract to New Admin : " + util.inspect(receipt, false, null, true))

		
		//Grant approval to be owner of contract
		let transaction3 = await nft1155.setApprovalForAll(newAdmin.address, true)

		receipt = await transaction3.wait();

		console.log("Approval Granter : " + util.inspect(receipt, false, null, true))

		
		// Mint NFT with token id 5
		let transaction4 = await nft1155.connect(newAdmin).mint(newAdmin.address, 5, 0, [])

		receipt = await transaction4.wait();

		console.log("Token ID : " + receipt.events[0].args["id"].toNumber())

		console.log(util.inspect(receipt, false, null, true))


		// Transfer NFT with token id 4
		let transaction5 = await nft1155.connect(newAdmin).safeTransferFrom(admin.address, buyer.address, 4, 0, [])

		receipt = await transaction5.wait();

		console.log("Token Transferred : " + util.inspect(receipt, false, null, true))
	})
})