// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

interface PETGPTNFT {
    function ownerOf(uint tokenId) external view returns (address);

    function safeTransferFrom(address from, address to, uint tokenId) external payable;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function royaltyInfo(uint _tokenId, uint _salePrice) external view returns (address, uint);

    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);
}

contract PETGPTMarket721A is Ownable {
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

    function getOfferBid(address petgptNFTAddress, uint tokenId) public view returns (OfferBid memory)  {
        Offer memory offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
        Bid memory bid = tokenBids[petgptNFTAddress][tokenId];
        return OfferBid(tokenId, PETGPTNFT(petgptNFTAddress).ownerOf(tokenId), offer.seller, offer.price, bid.bidder, bid.price);
    }

    modifier checkStartEnd(uint start, uint end){
        require(start != 0 && end != 0 && end >= start);
        _;
    }
    function getOfferBids(address petgptNFTAddress, uint start, uint end) public view checkStartEnd(start, end) returns (OfferBid[] memory offerBids)  {
        uint end1 = end + 1;
        offerBids = new OfferBid[](end1 - start);
        uint index;
        PETGPTNFT petgptNFT = PETGPTNFT(petgptNFTAddress);
        for (uint tokenId = start; tokenId < end1; tokenId++) {
            Offer memory offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
            Bid memory bid = tokenBids[petgptNFTAddress][tokenId];
            TokenOwnership memory tokenOwnership = petgptNFT.explicitOwnershipOf(tokenId);
            address addr = tokenOwnership.addr;
            offerBids[index++] = OfferBid(tokenId, (addr == address(0) || tokenOwnership.burned) ? address(0) : addr, offer.seller, offer.price, bid.bidder, bid.price);
        }
        return offerBids;
    }

    mapping(address => mapping(address => mapping(uint => uint))) private userBidsIndex;
    mapping(address => mapping(address => OfferBid[])) private userBids;

    function getUserBids(address petgptNFTAddress, address user, uint start, uint end) public view checkStartEnd(start, end) returns (OfferBid[] memory offerBids)  {
        start = start - 1;
        uint userBidsLength = userBids[petgptNFTAddress][user].length;
        if (start < userBidsLength) {
            end = end - 1;
            uint end1 = end < userBidsLength ? (end + 1) : userBidsLength;
            offerBids = new OfferBid[](end1 - start);
            uint index;
            for (uint i = start; i < end1; i++) {
                offerBids[index++] = userBids[petgptNFTAddress][user][i];
            }
        }
        return offerBids;
    }

    function getOwnerOf(address petgptNFTAddress, uint start, uint end) public view checkStartEnd(start, end) returns (address[] memory owners)  {
        uint end1 = end + 1;
        owners = new address[](end1 - start);
        uint index;
        PETGPTNFT petgptNFT = PETGPTNFT(petgptNFTAddress);
        for (uint tokenId = start; tokenId < end1; tokenId++) {
            TokenOwnership memory tokenOwnership = petgptNFT.explicitOwnershipOf(tokenId);
            address addr = tokenOwnership.addr;
            owners[index++] = (addr == address(0) || tokenOwnership.burned) ? address(0) : addr;
        }
        return owners;
    }

    mapping(address => bool) public NFTAddressIsAccept;

    event SetIsAccept(address petgptNFTAddress, bool isAccept);

    function setIsAccept(address petgptNFTAddress, bool isAccept) public onlyOwner {
        if (!isAccept && NFTAddressIsBid[petgptNFTAddress]) {
            setIsBid(petgptNFTAddress, false);
        }
        NFTAddressIsAccept[petgptNFTAddress] = isAccept;
        emit SetIsAccept(petgptNFTAddress, isAccept);
    }
    modifier checkIsAccept(address petgptNFTAddress){
        require(NFTAddressIsAccept[petgptNFTAddress], 'This address is not allowed to use this contract');
        _;
    }

    event PayableToReceiver(address petgptNFTAddress, address receiver, uint amount);
    event TransactionToken(address petgptNFTAddress, address from, address to, uint tokenId, uint price, bool isBid);

    mapping(address => bool) public NFTAddressIsRoyalty;

    event SetIsRoyalty(address petgptNFTAddress, bool isRoyalty);

    function setIsRoyalty(address petgptNFTAddress, bool isRoyalty) public onlyOwner checkIsAccept(petgptNFTAddress) {
        NFTAddressIsRoyalty[petgptNFTAddress] = isRoyalty;
        emit SetIsRoyalty(petgptNFTAddress, isRoyalty);
    }

    function transferToken(address petgptNFTAddress, uint tokenId, uint price, address to, bool isBid) private {
        require(to != address(0), 'Cannot transfer to the zero address');
        uint royaltyAmount;
        PETGPTNFT petgptNFT = PETGPTNFT(petgptNFTAddress);
        if (NFTAddressIsRoyalty[petgptNFTAddress]) {
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

    function offerTokenForSale(address petgptNFTAddress, uint tokenId, uint price) public checkIsAccept(petgptNFTAddress) checkOwnerOfAndApproved(petgptNFTAddress, msg.sender, tokenId) {
        address seller = msg.sender;
        uint bidPrice = tokenBids[petgptNFTAddress][tokenId].price;
        bool priceEQ0 = price == 0;
        require(priceEQ0 || bidPrice == 0 || price > bidPrice, 'Same or higher bid already available, can choose to accept');
        Offer memory offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
        require(priceEQ0 || seller != offer.seller || price != offer.price, 'Cannot set the same price');
        tokenOfferedForSale[petgptNFTAddress][tokenId] = Offer(seller, price);
        emit OfferTokenForSale(petgptNFTAddress, tokenId, seller, price);
    }

    function buyToken(address petgptNFTAddress, uint tokenId) payable public checkIsAccept(petgptNFTAddress) checkOwnerOfAndApproved(petgptNFTAddress, tokenOfferedForSale[petgptNFTAddress][tokenId].seller, tokenId) {
        address buyer = msg.sender;
        Offer memory offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
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

    mapping(address => bool) public NFTAddressIsBid;

    event SetIsBid(address petgptNFTAddress, bool isBid);

    function setIsBid(address petgptNFTAddress, bool isBid) public onlyOwner checkIsAccept(petgptNFTAddress) {
        NFTAddressIsBid[petgptNFTAddress] = isBid;
        emit SetIsBid(petgptNFTAddress, isBid);
    }

    function removeUserBids(address petgptNFTAddress, uint tokenId, address bidder) private {
        uint userBidsLength = userBids[petgptNFTAddress][bidder].length;
        uint tokenIndex = userBidsIndex[petgptNFTAddress][bidder][tokenId];
        bool tokenIndexHas = tokenIndex + 1 <= userBidsLength;
        if (tokenIndexHas) {
            OfferBid memory lastOfferBid = userBids[petgptNFTAddress][bidder][userBidsLength - 1];
            userBids[petgptNFTAddress][bidder][tokenIndex] = lastOfferBid;
            userBidsIndex[petgptNFTAddress][bidder][lastOfferBid.tokenId] = tokenIndex;
            delete userBidsIndex[petgptNFTAddress][bidder][tokenId];
            userBids[petgptNFTAddress][bidder].pop();
        }
    }

    function setUserBids(address petgptNFTAddress, uint tokenId, address userBidsOwner, address offerSeller, uint tokenOfferedForSalePrice, address currentBidder) private {
        address bidder = msg.sender;
        uint price = msg.value;
        uint userBidsLength = userBids[petgptNFTAddress][bidder].length;
        uint tokenIndex = userBidsIndex[petgptNFTAddress][bidder][tokenId];
        bool isCurrentBidderHandle = (bidder == currentBidder) && (tokenIndex + 1 <= userBidsLength);
        if (isCurrentBidderHandle && price == 0) {
            removeUserBids(petgptNFTAddress, tokenId, bidder);
        } else {
            OfferBid memory userBidsOfferBid = OfferBid(tokenId, userBidsOwner, offerSeller, tokenOfferedForSalePrice, bidder, price);
            if (isCurrentBidderHandle) {
                userBids[petgptNFTAddress][bidder][tokenIndex] = userBidsOfferBid;
            } else {
                removeUserBids(petgptNFTAddress, tokenId, currentBidder);
                userBidsIndex[petgptNFTAddress][bidder][tokenId] = userBidsLength;
                userBids[petgptNFTAddress][bidder].push(userBidsOfferBid);
            }
        }
    }

    function enterBidForToken(address petgptNFTAddress, uint tokenId) payable public {
        uint price = msg.value;
        bool priceIsZero = price == 0;
        require(priceIsZero || NFTAddressIsBid[petgptNFTAddress], 'This address does not allow bid');
        address bidder = msg.sender;
        Bid memory bid = tokenBids[petgptNFTAddress][tokenId];
        address currentBidder = bid.bidder;
        uint currentPrice = bid.price;
        bool isCurrentBidder = bidder == currentBidder;
        Offer memory offer = tokenOfferedForSale[petgptNFTAddress][tokenId];
        uint tokenOfferedForSalePrice = offer.price;
        address offerSeller = offer.seller;
        address userBidsOwner = offerSeller;
        if (!(priceIsZero && isCurrentBidder)) {
            address ownerOfTokenId = PETGPTNFT(petgptNFTAddress).ownerOf(tokenId);
            require(bidder != ownerOfTokenId, 'You can not buy your own token');
            require(ownerOfTokenId != offerSeller || tokenOfferedForSalePrice == 0 || price < tokenOfferedForSalePrice, 'Same or lower price already available, can choose to buy');
            userBidsOwner = ownerOfTokenId;
        }
        require(isCurrentBidder || price > currentPrice, 'Same or higher bid already available');
        require(!isCurrentBidder || price != currentPrice, 'Cannot set the same bid');
        tokenBids[petgptNFTAddress][tokenId] = Bid(bidder, price);
        setUserBids(petgptNFTAddress, tokenId, userBidsOwner, offerSeller, tokenOfferedForSalePrice, currentBidder);
        emit EnterBidForToken(petgptNFTAddress, tokenId, bidder, price);
        if (currentBidder != address(0) && currentPrice > 0)
            payable(currentBidder).transfer(currentPrice);
    }

    function acceptBidForToken(address petgptNFTAddress, uint tokenId, uint minPrice) public checkOwnerOfAndApproved(petgptNFTAddress, msg.sender, tokenId) {
        require(NFTAddressIsBid[petgptNFTAddress], 'This address does not allow bid');
        Bid memory bid = tokenBids[petgptNFTAddress][tokenId];
        uint price = bid.price;
        require(price > 0, 'This token has not be bid');
        require(price >= minPrice, 'This current bid is lower than the minimum expectation price');
        address bidder = bid.bidder;
        transferToken(petgptNFTAddress, tokenId, price, bidder, true);
        tokenBids[petgptNFTAddress][tokenId] = Bid(address(0), 0);
        removeUserBids(petgptNFTAddress, tokenId, bidder);
    }
}