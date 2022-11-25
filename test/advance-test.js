const util = require('util')

describe("NFTAdvance", function() {
	it("Should create and execute nft sales", async function() {
		const NFTAdvance = await ethers.getContractFactory("NFTAdvance");
		const nftAdvance = await NFTAdvance.deploy();

		await nftAdvance.deployed();

		let listingPrice = await nftAdvance.getListingPrice();await nftAdvance.listForFixedPrice(
			0,
			"https://www.example-1.com",
			ethers.utils.parseUnits('10', 'ether'),
			0,
			0,
			{ value: listingPrice.toString() }
		)

		await nftAdvance.listForFixedPrice(
			0,
			"https://www.example-1.com",
			ethers.utils.parseUnits('10', 'ether'),
			0,
			0,
			{ value: listingPrice.toString() }
		);

		let auctionStart = parseInt(Date.now() / 1000);

		let auctionEnd = auctionStart + 10;

		await nftAdvance.listForAuction(
			0,
			"https://www.example-2.com",
			ethers.utils.parseUnits('10', 'ether'),
			ethers.utils.parseUnits('15', 'ether'),
			auctionStart,
			auctionEnd,
			{ value: listingPrice.toString() }
		);


		const [adminAddress, buyerAddress1, buyerAddress2, buyerAddress3] = await ethers.getSigners();

		await nftAdvance.connect(buyerAddress1).buyNFT(1, { value: ethers.utils.parseUnits('10', 'ether')});

		await nftAdvance.connect(buyerAddress1).placeBid(2, { value: ethers.utils.parseUnits('11', 'ether')});

		await nftAdvance.connect(buyerAddress2).placeBid(2, { value: ethers.utils.parseUnits('12', 'ether')});

		await nftAdvance.connect(buyerAddress3).placeBid(2, { value: ethers.utils.parseUnits('13', 'ether')});

		await nftAdvance.connect(buyerAddress2).placeBid(2, { value: ethers.utils.parseUnits('15', 'ether')});

		items = await nftAdvance.fetchCreatedNFTs();

		items = await Promise.all(items.map(async item => {
			const tokenUri = await nftAdvance.tokenURI(item.tokenId)
			
			let formattedItem = {
				price: item.price.toString(),
				tokenId: item.tokenId.toString(),
				creator: item.creator,
				owner: item.owner,
				tokenUri,
				listingType: item.listingType,
				startingPrice: item.startingPrice.toString(),
				reservePrice: item.reservePrice.toString(),
				starting: item.starting.toString(),
				ending: item.ending.toString(),
				bids: await Promise.all(item.bids.map(async bid => {
					return {
						address: bid.bidderAddress,
						price: bid.price.toString(),
						bidAt: bid.bidAt.toString(),
					}
				}))
			}

			return formattedItem
		}));

		console.log('items: ', util.inspect(items, false, null, true));


		await new Promise(res => setTimeout(() => res(null), 10000));

		await nftAdvance.settleAuction(2);

		items = await nftAdvance.fetchCreatedNFTs();

		items = await Promise.all(items.map(async item => {
			const tokenUri = await nftAdvance.tokenURI(item.tokenId)
			
			let formattedItem = {
				price: item.price.toString(),
				tokenId: item.tokenId.toString(),
				creator: item.creator,
				owner: item.owner,
				tokenUri,
				listingType: item.listingType,
				startingPrice: item.startingPrice.toString(),
				reservePrice: item.reservePrice.toString(),
				starting: item.starting.toString(),
				ending: item.ending.toString(),
				bids: await Promise.all(item.bids.map(async bid => {
					return {
						address: bid.bidderAddress,
						price: bid.price.toString(),
						bidAt: bid.bidAt.toString(),
					}
				}))
			}

			return formattedItem;
		}));

		console.log('\n\nAfter Auction Settled:\n\n');

		console.log('items: ', util.inspect(items, false, null, true));


		let adminBalance = await ethers.provider.getBalance(adminAddress.address);
		let buyer1Balance = await ethers.provider.getBalance(buyerAddress1.address);
		let buyer2Balance = await ethers.provider.getBalance(buyerAddress2.address);
		let buyer3Balance = await ethers.provider.getBalance(buyerAddress3.address);

		console.log('\n\nFinal Account Balance:\n\n');

		console.log("Admin 1 (" + adminAddress.address + ") Balance: " + ethers.utils.formatEther(adminBalance));
		console.log("Buyer 1 (" + buyerAddress1.address + ") Balance: " + ethers.utils.formatEther(buyer1Balance));
		console.log("Buyer 2 (" + buyerAddress2.address + ") Balance: " + ethers.utils.formatEther(buyer2Balance));
		console.log("Buyer 3 (" + buyerAddress3.address + ") Balance: " + ethers.utils.formatEther(buyer3Balance));

		return;
	})
});