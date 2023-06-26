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
    uint256 constant maxTokensPerBuyer = 10000;
    mapping(address => bool) public hasParticipated;

    event Mint(address _buyer, uint256 _amount);
    event SaleEnded(uint256 _totalTokensSold);

    constructor(address _tokenContract) {
        owner = payable(msg.sender);
        tokenContract = Token(_tokenContract);
    }

    function mintTokens() public payable {
        require(!hasParticipated[msg.sender], "Already participated");
        require(msg.value == tokenPrice, "Invalid amount of Ether");
        require(tokenContract.mint(msg.sender, maxTokensPerBuyer), "Failed to mint tokens");
        tokensSold += maxTokensPerBuyer;
        hasParticipated[msg.sender] = true;
        emit Mint(msg.sender, maxTokensPerBuyer);
    }

    function endSale() public {
        require(msg.sender == owner, "Only the owner can end the sale");
        require(tokenContract.mint(owner, tokenContract.balanceOf(address(this))), "Failed to mint remaining tokens to owner");
        emit SaleEnded(tokensSold);
        selfdestruct(owner);
    }
    
    function withdrawContractBalance() public {
        require(msg.sender == owner, "Only the owner can withdraw contract balance");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract balance is zero");
        owner.transfer(contractBalance);
    }
}