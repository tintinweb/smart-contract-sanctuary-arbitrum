/**
 *Submitted for verification at Arbiscan on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSale {
    address payable public owner;
    Token public tokenContract;
    uint256 public tokensSold;
    uint256 constant tokenPrice = 0.001 ether;

    event Sell(address _buyer, uint256 _amount);

    constructor(address _tokenContract) {
        owner = payable(msg.sender);
        tokenContract = Token(_tokenContract);
    }

    function buyTokens() public payable {
        uint256 amount = msg.value / tokenPrice;
        require(tokenContract.transfer(msg.sender, amount), "Failed to transfer tokens to buyer");
        tokensSold += amount;
        emit Sell(msg.sender, amount);
    }

    function endSale() public {
        require(msg.sender == owner, "Only the owner can end the sale");
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))), "Failed to transfer remaining tokens to owner");
        selfdestruct(owner);
    }
}