// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "hardhat/console.sol";

contract NFTAdvance is ERC721URIStorageUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIds;

    address payable contractOwner;

    uint256 listingPrice;

    struct Bid {
        address payable bidderAddress;
        uint256 price;
        uint256 bidAt;
    }

    struct Item {
        uint256 tokenId;
        address payable creator;
        address payable owner;
        string listingType;
        uint256 price;
        uint256 startingPrice;
        uint256 reservePrice;
        uint256 starting;
        uint256 ending;
        Bid[] bids;
    }

    mapping(uint256 => Item) private idToItem;

    event ItemCreated (
        Item item
    );

    event ItemListed (
        Item item
    );

    event BidPlaced (
        Item item
    );

    event AuctionCancelled (
        Item item
    );

    event AuctionSettled (
        Item item
    );

    function initialize() initializer public {
        __ERC721_init("Bagisto NFT Marketplace", "Bagisto");

        __ReentrancyGuard_init();

        contractOwner = payable(msg.sender);

        listingPrice = 0.025 ether;
    }

    function mintNFT(
        string memory tokenURI
    ) public returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        idToItem[newTokenId].tokenId = newTokenId;
        idToItem[newTokenId].creator = payable(msg.sender);
        idToItem[newTokenId].owner = payable(msg.sender);

        emit ItemCreated(idToItem[newTokenId]);
        
        return newTokenId;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Sets the listing price of the contract */
    function setListingPrice(
        uint256 price
    ) public returns (uint256) {
        require(msg.sender == address(this), "Only contract owner can set the listing price.");

        return listingPrice = price;
    }
    
    /* Places an item for sale on the marketplace */
    function listForFixedPrice(
        uint256 tokenId,
        string memory tokenURI,
        uint256 price,
        uint256 starting,
        uint256 ending
    ) public payable nonReentrant returns (uint) {
        if (tokenId == 0) {
            tokenId = mintNFT(tokenURI);
        }
        
        Item storage item = idToItem[tokenId];

        require(item.owner == msg.sender, "ERC721: transfer caller is not owner nor approved");

        require(! _haveBids(item), "Settle the previous auction first.");

        _resetAuction(item);

        require(price > 0, "Price must be greater than zero.");

        require(msg.value == listingPrice, "Price must be equal to listing price");

        item.listingType = 'fixed';
        item.price = price;
        item.starting = starting;
        item.ending = ending;

        emit ItemListed(idToItem[tokenId]);
        
        return tokenId;
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function buyNFT(
        uint256 tokenId
    ) public payable nonReentrant {
        Item storage item = idToItem[tokenId];

        require(_isSaleOn(item), "Item is not for sale yet.");

        require(item.price > 0, "Item is not listed for sale yet");

        require(msg.value == item.price, "Please submit the asking price in order to complete the purchase");

        require(ownerOf(tokenId) == item.owner, "From address must be token owner");

        item.owner.transfer(msg.value);

        _transfer(item.owner, msg.sender, tokenId);

        item.owner = payable(msg.sender);
        item.starting = 0;
        item.ending = 0;

        payable(contractOwner).transfer(listingPrice);
    }
    
    /* Places an item for sale on the marketplace */
    function listForAuction(
        uint256 tokenId,
        string memory tokenURI,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 starting,
        uint256 ending
    ) public payable nonReentrant returns (uint) {
        if (tokenId == 0) {
            tokenId = mintNFT(tokenURI);
        }

        Item storage item = idToItem[tokenId];

        require(item.owner == msg.sender, "ERC721: transfer caller is not owner nor approved");

        require(! _haveBids(item), "Settle the previous auction first.");

        // require((ending - starting) >= 1 minutes, "Duration must be at least 1 minute.");

        require(startingPrice > 0, "Price must be greater than zero.");

        require(msg.value == listingPrice, "Price must be equal to listing price");

        _resetAuction(item);

        item.listingType = 'auction';
        item.startingPrice = startingPrice;
        item.reservePrice = reservePrice;
        item.starting = starting;
        item.ending = ending;

        emit ItemListed(item);
        
        return tokenId;
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function placeBid(
        uint256 tokenId
    ) public payable nonReentrant {
        Item storage item = idToItem[tokenId];

        require(msg.sender != item.owner, "Owner cannot bid on own NFT");

        require(_isSaleOn(item), "NFT is not on auction.");

        if (item.bids.length > 0) {
            Bid memory highestBid = _highestBid(item);

            require(msg.value > highestBid.price, "There already is a higher bid.");
        }

        item.bids.push(Bid(
            payable(msg.sender),
            msg.value,
            block.timestamp
        ));

        emit BidPlaced(item);
    }
    
    function withdrawBid(
        uint256 tokenId
    ) external {

        Item storage item = idToItem[tokenId];

        Bid memory highestBid = _highestBid(item);

        require(msg.sender == highestBid.bidderAddress, "Cannot withdraw funds");

        highestBid.bidderAddress.transfer(highestBid.price);
        
        item.bids.pop();
    }

    /* Settle auction */
    /* Transfers ownership of the item, as well as funds between parties */
    function settleAuction(
        uint256 tokenId
    ) public payable nonReentrant {
        Item storage item = idToItem[tokenId];

        require(item.owner == msg.sender, "ERC721: transfer caller is not owner nor approved");

        require(_isSaleEnded(item), "Auction is not ended yet.");

        require(_haveBids(item), "There are no bids to settle.");

        Bid memory awarder = _highestBid(item);

        if (awarder.price >= item.reservePrice) {
            for (uint256 i = 0; i < item.bids.length - 1; i++) {
                Bid memory bid = item.bids[i];

                bid.bidderAddress.transfer(bid.price);
            }
            
            item.owner.transfer(awarder.price);

            _transfer(idToItem[tokenId].owner, awarder.bidderAddress, tokenId);

            idToItem[tokenId].owner = awarder.bidderAddress;

            payable(contractOwner).transfer(listingPrice);
        } else {
            for (uint256 i = 0; i < item.bids.length; i++) {
                Bid memory bid = item.bids[i];

                bid.bidderAddress.transfer(bid.price);
            }
        }

        _resetAuction(item);

        emit AuctionSettled(item);
    }

    // Cancels an auction that hasn't been won yet.
    function cancelAuction(
        uint256 tokenId
    ) public payable nonReentrant {
        Item storage item = idToItem[tokenId];

        require(item.owner == msg.sender, "ERC721: transfer caller is not owner nor approved");

        require(! _isSaleEnded(item), "Auction has already been ended.");

        require(! _haveBids(item), "Auction can not be canceled because auction already have bids.");

        _resetAuction(item);

        emit AuctionCancelled(item);
    }

    /* Returns the highest bid */
    function _haveBids(
        Item storage item
    ) internal view returns (bool) {
        return item.bids.length > 0;
    }

    /* Returns the highest bid */
    function _highestBid(
        Item storage item
    ) internal view returns (Bid memory) {
        Bid memory highestBid = item.bids[item.bids.length - 1];

        return highestBid;
    }

    //Returns true if Auction is started.
    function _isSaleStarted(
        Item storage item
    ) internal view returns (bool) {
        return item.starting == 0 ? true : block.timestamp > item.starting;
    }

    //Returns true if Auction is ended.
    function _isSaleEnded(
        Item storage item
    ) internal view returns (bool) {
        return item.ending == 0 ? true : block.timestamp > item.ending;
    }

    //Returns true if the NFT is on auction.
    function _isSaleOn(
        Item storage item
    ) internal view returns (bool) {
        if (item.starting == 0) {
            return item.ending == 0 ? true : block.timestamp < item.ending;
        } else if (item.ending == 0) {
            return item.starting == 0 ? true : block.timestamp > item.starting;
        }

        return block.timestamp > item.starting && block.timestamp < item.ending;
    }

    //Reset item auction
    function _resetAuction(
        Item storage item
    ) internal {
        item.listingType = 'fixed';
        item.startingPrice = 0;
        item.reservePrice = 0;
        item.starting = 0;
        item.ending = 0;

        delete item.bids;
    }

    /* Returns onlyl items that a user has purchased */
    function fetchMyNFTs() public view returns (Item[] memory) {
        uint totalItemCount = _tokenIds.current();

        uint itemCount = 0;

        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        Item[] memory items = new Item[](itemCount);

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToItem[i + 1].owner == msg.sender) {
                uint currentId = i + 1;

                Item storage currentItem = idToItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    /* Returns only items a user has created */
    function fetchCreatedNFTs() public view returns (Item[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToItem[i + 1].creator == msg.sender) {
                itemCount += 1;
            }
        }

        Item[] memory items = new Item[](itemCount);

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToItem[i + 1].creator == msg.sender) {
                uint currentId = i + 1;

                Item storage currentItem = idToItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }
}