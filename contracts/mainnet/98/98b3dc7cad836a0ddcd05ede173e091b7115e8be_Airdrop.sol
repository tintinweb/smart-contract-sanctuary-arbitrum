// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./rekt.sol"; // Import your token contract here

contract Airdrop {
    address public owner;  // The owner of the contract
    address public tokenAddress;  // Address of the ERC-20 token contract
    uint256 public airdropAmount;  // Airdrop amount for each recipient
    
    event AirdropSent(address indexed recipient, uint256 amount);

    constructor(address _tokenAddress, uint256 _initialAirdropAmount) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        airdropAmount = _initialAirdropAmount;
    }

    // Function to set or update the airdrop amount
    function setAirdropAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Airdrop amount must be greater than 0");
        airdropAmount = newAmount;
    }

    // Function to perform the airdrop to a list of recipients
    function distributeTokens(address[] calldata recipients) external onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            
            require(airdropAmount > 0, "Invalid airdrop amount");
            require(token.transfer(recipient, airdropAmount), "Token transfer failed");
            emit AirdropSent(recipient, airdropAmount);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}