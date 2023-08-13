// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "Ownable.sol";

interface PETGPTNFT {

    function totalSupply() external view returns (uint);
    function ownerOf(uint tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint tokenId) external payable;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function royaltyInfo(uint _tokenId, uint _salePrice) external view returns (address, uint);
}

contract PETGPTMarket is Ownable {
    
    modifier checkOwnerOfAndApproved(address petgptNFTAddress, address seller, uint tokenId){
        PETGPTNFT petgptNFT = PETGPTNFT(petgptNFTAddress);
        require(petgptNFT.ownerOf(tokenId) == seller, 'The token owner is not the seller');
        require(petgptNFT.isApprovedForAll(seller, address(this)), 'Not yet approved');
        _;
    }

    struct Offer {
        address seller;
        uint price;
    }
    mapping(address => mapping(uint => Offer)) public tokenOfferedForSale;

    struct Bid {
        address bidder;
        uint price;
    }
    mapping(address => mapping(uint => Bid)) public tokenBids;

    struct OfferBid {
        uint tokenId;
        address owner;
        address seller;
        uint offerPrice;
        address bidder;
        uint bidPrice;
    }

    function getOfferBid(address petgptNFTAddress, uint tokenId) public view returns (OfferBid memory offerBid)  {

        Offer storage offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
        Bid storage bid = tokenBids[petgptNFTAddress][tokenId];
        offerBid = OfferBid(tokenId, PETGPTNFT(petgptNFTAddress).ownerOf(tokenId), offer.seller, offer.price, bid.bidder, bid.price);
        return offerBid;
    }

    function getOfferBids(address petgptNFTAddress, uint page, uint size) public view returns (OfferBid[] memory)  {
        OfferBid[] memory offerBids = new OfferBid[](size);
        uint index;
        for (uint i = (page - 1) * size; i < page * size; i++) {
            uint tokenId = i + 1;
            Offer storage offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
            Bid storage bid = tokenBids[petgptNFTAddress][tokenId];
            offerBids[index++] = OfferBid(tokenId, PETGPTNFT(petgptNFTAddress).ownerOf(tokenId), offer.seller, offer.price, bid.bidder, bid.price);
        }
        return offerBids;
    }

    function getOwnerOf(address petgptNFTAddress, uint page, uint size) public view returns (address[] memory)  {
        address[] memory owners = new address[](size);
        uint index;
        PETGPTNFT petgptNFT = PETGPTNFT(petgptNFTAddress);
        for (uint i = (page - 1) * size; i < page * size; i++) {
            uint tokenId = i + 1;
            owners[index++] = petgptNFT.ownerOf(tokenId);
        }
        return owners;
    }


    event PayableToReceiver(address petgptNFTAddress, address receiver, uint amount);
    event TransactionToken(address petgptNFTAddress, address from, address to, uint tokenId, uint price, bool isBid);

    mapping(address => bool) public isRoyalty;

    function setIsRoyalty(address petgptNFTAddress, bool isRoyalty_) public onlyOwner {
        isRoyalty[petgptNFTAddress] = isRoyalty_;
    }

    function transferToken(address petgptNFTAddress, uint tokenId, uint price, address to, bool isBid) private {
        require(to != address(0), 'Cannot transfer to the zero address');
        uint royaltyAmount;
        PETGPTNFT petgptNFT = PETGPTNFT(petgptNFTAddress);
        if (isRoyalty[petgptNFTAddress]) {
            address receiver;
            (receiver, royaltyAmount) = petgptNFT.royaltyInfo(tokenId, price);
            if (royaltyAmount > 0) {
                payable(receiver).transfer(royaltyAmount);
                emit PayableToReceiver(petgptNFTAddress, receiver, royaltyAmount);
            }
        }
        address ownerOfToken = petgptNFT.ownerOf(tokenId);
        uint ownerOfTokenAmount = price - royaltyAmount;
        if (ownerOfTokenAmount > 0)
            payable(ownerOfToken).transfer(ownerOfTokenAmount);
        petgptNFT.safeTransferFrom(ownerOfToken, to, tokenId);
        emit TransactionToken(petgptNFTAddress, ownerOfToken, to, tokenId, price, isBid);
        if (tokenOfferedForSale[petgptNFTAddress][tokenId].price > 0)
            tokenOfferedForSale[petgptNFTAddress][tokenId] = Offer(address(0), 0);
    }

    event OfferTokenForSale(address petgptNFTAddress, uint tokenId, address offer, uint price);

    function offerTokenForSale(address petgptNFTAddress, uint tokenId, uint price) public checkOwnerOfAndApproved(petgptNFTAddress, msg.sender, tokenId) {
        address seller = msg.sender;
        Bid storage bid = tokenBids[petgptNFTAddress][tokenId];
        uint bidPrice = bid.price;
        bool priceEQ0 = price == 0;
        require(priceEQ0 || bidPrice == 0 || price > bidPrice, 'Same or higher bid already available, can choose to accept');
        Offer storage offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
        require(priceEQ0 || seller != offer.seller || price != offer.price, 'Cannot set the same price');
        tokenOfferedForSale[petgptNFTAddress][tokenId] = Offer(seller, price);
        emit OfferTokenForSale(petgptNFTAddress, tokenId, seller, price);
    }
    function buyToken(address petgptNFTAddress, uint tokenId) payable public checkOwnerOfAndApproved(petgptNFTAddress, tokenOfferedForSale[petgptNFTAddress][tokenId].seller, tokenId) {
        address buyer = msg.sender;
        Offer storage offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
        require(buyer != offer.seller, 'You can not buy your own token');
        uint price = offer.price;
        require(price > 0, 'This token is not on sale');
        uint value = msg.value;
        require(value >= price, 'Insufficient payment amount');
        if (value > price)
            payable(buyer).transfer(value - price);
        transferToken(petgptNFTAddress, tokenId, price, buyer, false);
    }

    event EnterBidForToken(address petgptNFTAddress, uint tokenId, address bidder, uint price);

    function enterBidForToken(address petgptNFTAddress, uint tokenId) payable public {
        address bidder = msg.sender;
        Bid storage bid = tokenBids[petgptNFTAddress][tokenId];
        address currentBidder = bid.bidder;
        uint price = msg.value;
        uint currentPrice = bid.price;
        PETGPTNFT petgptNFT = PETGPTNFT(petgptNFTAddress);
        address ownerOfTokenId = petgptNFT.ownerOf(tokenId);
        require(bidder != ownerOfTokenId, 'You can not buy your own token');
        Offer storage offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
        uint tokenOfferedForSalePrice = offer.price;
        require(ownerOfTokenId != offer.seller || tokenOfferedForSalePrice == 0 || price < tokenOfferedForSalePrice, 'Same or lower price already available, can choose to buy');
        require(bidder == currentBidder || price > currentPrice, 'Same or higher bid already available');
        require(bidder != currentBidder || price != currentPrice, 'Cannot set the same bid');
        tokenBids[petgptNFTAddress][tokenId] = Bid(bidder, price);
        emit EnterBidForToken(petgptNFTAddress, tokenId, bidder, price);
        if (currentBidder != address(0) && currentPrice > 0)
            payable(currentBidder).transfer(currentPrice);
    }
    function acceptBidForToken(address petgptNFTAddress, uint tokenId, uint minPrice) public checkOwnerOfAndApproved(petgptNFTAddress, msg.sender, tokenId) {
        Bid storage bid = tokenBids[petgptNFTAddress][tokenId];
        uint price = bid.price;
        require(price > 0, 'This token has not be bid');
        require(price >= minPrice, 'This current bid is lower than the minimum expectation price');
        transferToken(petgptNFTAddress, tokenId, price, bid.bidder, true);
        if (tokenBids[petgptNFTAddress][tokenId].price > 0)
            tokenBids[petgptNFTAddress][tokenId] = Bid(address(0), 0);
    }
}