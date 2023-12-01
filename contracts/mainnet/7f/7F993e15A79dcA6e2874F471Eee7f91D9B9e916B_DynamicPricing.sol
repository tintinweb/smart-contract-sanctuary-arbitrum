// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract DynamicPricing {
    uint256 public basePrice;
    uint256 public currentDemand;
    uint256 public currentSupply;

    constructor(uint256 _basePrice) {
        basePrice = _basePrice;
        currentDemand = 0;
        currentSupply = 0;
    }

    function updateDemand(uint256 _demand) public {
        currentDemand = _demand;
    }

    function updateSupply(uint256 _supply) public {
        currentSupply = _supply;
    }

    function getCurrentPrice() public view returns (uint256) {
        if (currentDemand > currentSupply) {
            return basePrice * (1 + ((currentDemand - currentSupply) / 100));
        } else {
            return basePrice;
        }
    }
}