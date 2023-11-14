/**
 *Submitted for verification at Arbiscan.io on 2023-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WalletWars {
    string public constant NAME = "Wallet Wars";
    address public owner;
    uint256 public minimumEntryFee = 0.01 ether; // Minimum entry fee set to 0.01 ETH
    uint256 public constant developerFeePercentage = 8; // Developer's fee is 8% of the wager
    uint256 public constant jackpotFeePercentage = 2; // Jackpot fee is 2% of the wager
    address payable public developerWallet;
    address payable public jackpotWallet;

    struct Match {
        address payable player1;
        address payable player2;
        uint256 player1Bet;
        uint256 player2Bet;
        bool isActive;
    }

    mapping(uint256 => Match) public matches;
    uint256 public nextMatchId;

    // Events
    event PlayerRegistered(address indexed player, uint256 matchId);
    event MatchStarted(uint256 indexed matchId);
    event MatchEnded(uint256 indexed matchId, address indexed winner, uint256 winnings);

    // Constructor
    constructor(address payable _developerWallet, address payable _jackpotWallet) {
        owner = msg.sender;
        developerWallet = _developerWallet;
        jackpotWallet = _jackpotWallet;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function register() external payable {
        require(msg.value >= minimumEntryFee, "The sent amount is below the minimum entry amount.");
        uint256 matchId = nextMatchId++;

        uint256 developerFee = (msg.value * developerFeePercentage) / 100;
        uint256 jackpotFee = (msg.value * jackpotFeePercentage) / 100;
        developerWallet.transfer(developerFee);
        jackpotWallet.transfer(jackpotFee);

        uint256 betAmount = msg.value - developerFee - jackpotFee;
        matches[matchId] = Match({
            player1: payable(msg.sender),
            player2: payable(address(0)),
            player1Bet: betAmount,
            player2Bet: 0,
            isActive: false
        });

        emit PlayerRegistered(msg.sender, matchId);
    }

    function joinMatch(uint256 matchId) public payable {
        require(matchId < nextMatchId, "This match does not exist.");
        require(matches[matchId].player1 != address(0), "No such match found.");
        require(matches[matchId].player2 == address(0), "Match is already complete.");
        require(msg.value >= minimumEntryFee, "The sent amount is below the minimum entry amount.");

        Match storage match_ = matches[matchId];
        match_.player2 = payable(msg.sender);
        match_.player2Bet = msg.value - ((msg.value * developerFeePercentage) / 100) - ((msg.value * jackpotFeePercentage) / 100);
        match_.isActive = true;

        emit MatchStarted(matchId);

        executeMatch(matchId);
    }

    function executeMatch(uint256 matchId) private {
        Match storage match_ = matches[matchId];
        require(match_.isActive, "Match is not active.");

        if (match_.player1Bet > match_.player2Bet) {
            match_.player1.transfer(match_.player1Bet + match_.player2Bet);
            emit MatchEnded(matchId, match_.player1, match_.player1Bet + match_.player2Bet);
        } else if (match_.player2Bet > match_.player1Bet) {
            match_.player2.transfer(match_.player1Bet + match_.player2Bet);
            emit MatchEnded(matchId, match_.player2, match_.player1Bet + match_.player2Bet);
        } else {
            match_.player1.transfer(match_.player1Bet);
            match_.player2.transfer(match_.player2Bet);
            emit MatchEnded(matchId, address(0), 0);
        }

        delete matches[matchId];
    }

event FundsWithdrawn(address indexed recipient, uint256 amount);

    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        developerWallet.transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }

    receive() external payable {}
}