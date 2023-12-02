/**
 *Submitted for verification at Arbiscan.io on 2023-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract VotingContract {
    address public owner;
    uint256 public fixedFee;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(uint256 _fixedFee) {
        owner = msg.sender;
        fixedFee = _fixedFee;
    }

    function setFixedFee(uint256 _newFee) external onlyOwner {
        fixedFee = _newFee;
    }

    function vote(uint256 _guessedDate) external payable {
        require(msg.value >= fixedFee, "Incorrect fee");      
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero");

        payable(owner).transfer(balance);
    }

    receive() external payable {
        // Handle incoming Ether if necessary
    }
}