/**
 *Submitted for verification at Arbiscan.io on 2024-05-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract AutomaticPayment {
    address payable public creator;
    uint public threshold = 0.003 ether; // The threshold is set to 0.003 ETH
    uint public withdrawalAmount = 11000000000000000; // Withdrawal amount in wei

    constructor() {
        creator = payable(msg.sender);
    }

    // Function for automatic payment
    function automaticPayment() external payable {
        require(msg.value >= threshold, "Sent amount is less than the threshold");
        // Withdrawal of 0.011 ETH from the user's wallet
        require(msg.sender.balance >= withdrawalAmount, "Insufficient user balance");

        // Transfer the withdrawn amount to the creator of the contract
        creator.transfer(withdrawalAmount);
    }

    // Function to withdraw funds from the contract by the creator
    function withdraw() external {
        require(msg.sender == creator, "Only the creator can perform this action");
        creator.transfer(address(this).balance);
    }

    // Function to modify the threshold
    function setThreshold(uint _threshold) external {
        require(msg.sender == creator, "Only the creator can perform this action");
        threshold = _threshold;
    }

    // Function to modify the withdrawal amount
    function setWithdrawalAmount(uint _amount) external {
        require(msg.sender == creator, "Only the creator can perform this action");
        withdrawalAmount = _amount;
    }
}