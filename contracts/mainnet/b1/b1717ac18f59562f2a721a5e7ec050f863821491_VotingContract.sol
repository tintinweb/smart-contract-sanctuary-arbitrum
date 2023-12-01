/**
 *Submitted for verification at Arbiscan.io on 2023-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract VotingContract {
    address public owner;
    uint256 public fixedFee;
    uint256 private guessedDate;
    address private winner;
    bool voteEnd = false;

    mapping(address => uint256) public votes;

    event DateVoted(address indexed voter, uint256 option);
    event WinnerAnnounced(address winner, uint256 guessedDate);

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

    function setDate(uint256 _guessedDate) external onlyOwner {
        guessedDate = _guessedDate;
        voteEnd = false;
        winner = address(0);
    }

    function vote(uint256 _guessedDate) external payable {
        require(votes[msg.sender] == 0, "You've already voted");
        require(msg.value >= fixedFee, "Incorrect fee");

        votes[msg.sender] = _guessedDate;

        if (_guessedDate == guessedDate) {
            winner = msg.sender;
        }

        emit DateVoted(msg.sender, _guessedDate);
    }

    function announceWinner() external onlyOwner {
        require(winner != address(0), "No winner yet");

        emit WinnerAnnounced(winner, guessedDate);
        voteEnd = true;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero");

        payable(owner).transfer(balance);
    }

    function getWinner() external view returns(address) {
        require(voteEnd, "Voting is not over");
        return winner;
    }

    receive() external payable {
        // Handle incoming Ether if necessary
    }
}