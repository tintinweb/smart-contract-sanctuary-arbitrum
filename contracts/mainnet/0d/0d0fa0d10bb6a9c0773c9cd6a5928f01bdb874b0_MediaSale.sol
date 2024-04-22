/**
 *Submitted for verification at Arbiscan.io on 2024-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MediaSale {
    address payable public owner;
    uint256 public commissionRate = 10;

    event MediaSold(address from, address to, uint256 value);

    constructor() {
        owner = payable(msg.sender);
    }
    
    function buyMedia(address payable oldOwnerAddress) public payable {
        require(msg.value > 0, "Cannot buy for zero ETH");
        require(oldOwnerAddress != address(0), "Invalid old owner address");
        require(oldOwnerAddress != msg.sender, "Buyer cannot be the seller");

        uint256 commission = msg.value * commissionRate / 100;
        uint256 sellerPayment = msg.value - commission;

        owner.transfer(commission);
        oldOwnerAddress.transfer(sellerPayment);

        emit MediaSold(oldOwnerAddress, msg.sender, msg.value);
    }

    function setCommissionRate(uint256 newRate) public {
        require(msg.sender == owner, "Only the owner can set commission rate");
        commissionRate = newRate;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        owner.transfer(address(this).balance);
    }
}