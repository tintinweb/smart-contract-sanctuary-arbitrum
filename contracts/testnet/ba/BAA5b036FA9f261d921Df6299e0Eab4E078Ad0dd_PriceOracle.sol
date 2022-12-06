// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PriceFeed {
    uint public price;

    constructor(uint _price) {
        price = _price;
    }

    function setPrice(uint _price) public {
        price = _price;
    }

    function getPrice() public view returns(uint) {
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceFeed.sol";

contract PriceOracle {
    mapping(address => address) public feeds;
    mapping(address => uint) public extraDecimals;

    function setFeed(address _token, address _feed, uint _extraDecimals) public {
        feeds[_token] = _feed;
        extraDecimals[_token] = _extraDecimals;
    }

    function getFeed(address _token) public view returns (address) {
        return feeds[_token];
    }

    function getPrice(address _token) public view returns(uint) {
        return PriceFeed(feeds[_token]).getPrice() * (10 ** extraDecimals[_token]);
    }
}