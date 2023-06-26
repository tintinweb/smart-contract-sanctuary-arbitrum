/**
 *Submitted for verification at Arbiscan on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Token {
    function mint(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSale {
    address payable public owner;
    Token public tokenContract;
    uint256 public tokensSold;
    uint256 constant tokenPrice = 0.001 ether;

    event Mint(address _buyer, uint256 _amount);

    constructor(address _tokenContract) {
        owner = payable(msg.sender);
        tokenContract = Token(_tokenContract);
    }

    function mintTokens(uint256 amount) public payable {
        require(msg.value == amount * tokenPrice, "Invalid amount of Ether");
        require(tokenContract.mint(msg.sender, amount), "Failed to mint tokens");
        tokensSold += amount;
        emit Mint(msg.sender, amount);
    }

    function endSale() public {
        require(msg.sender == owner, "Only the owner can end the sale");
        require(tokenContract.mint(owner, tokenContract.balanceOf(address(this))), "Failed to mint remaining tokens to owner");
        selfdestruct(owner);
    }
    
    function withdrawContractBalance() public {
        require(msg.sender == owner, "Only the owner can withdraw contract balance");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract balance is zero");
        owner.transfer(contractBalance);
    }
}