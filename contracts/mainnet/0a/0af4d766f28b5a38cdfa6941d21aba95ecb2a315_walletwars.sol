/**
 *Submitted for verification at Arbiscan.io on 2023-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract walletwars {
    struct Match {
        address player1;
        address player2;
        uint256 betAmount1;
        uint256 betAmount2;
    }

    address public owner;
    address public jackpotWallet; // Address for the jackpot wallet

    uint256 public constant DEVELOPER_FEE_PERCENT = 8;
    uint256 public constant JACKPOT_FEE_PERCENT = 2;

    Match[] public matches;

    constructor() {
        owner = msg.sender;
    }

    // Function to set the jackpot wallet address
    function setJackpotWallet(address _jackpotWallet) external {
        require(msg.sender == owner, "Only owner can set the jackpot wallet");
        jackpotWallet = _jackpotWallet;
    }

    function createOrJoinMatch() public payable {
        require(msg.value > 0, "Bet amount must be greater than 0");
        handleMatch(msg.sender, msg.value);
    }

    // receive function to automatically handle ETH sent to the contract
    receive() external payable {
        require(msg.value > 0, "Bet amount must be greater than 0");
        handleMatch(msg.sender, msg.value);
    }

    function handleMatch(address sender, uint256 value) private {
        bool matchFound = false;
        for(uint i = 0; i < matches.length; i++) {
            if (matches[i].player2 == address(0)) {
                matches[i].player2 = sender;
                matches[i].betAmount2 = value;
                finalizeMatch(i);
                matchFound = true;
                break;
            }
        }

        if (!matchFound) {
            Match memory newMatch = Match({
                player1: sender,
                player2: address(0),
                betAmount1: value,
                betAmount2: 0
            });
            matches.push(newMatch);
        }
    }

    function finalizeMatch(uint index) internal {
        Match storage activeMatch = matches[index];

        require(activeMatch.player2 != address(0), "Match is not ready");

        if (activeMatch.betAmount1 > activeMatch.betAmount2) {
            uint256 winningAmount = calculatePrize(activeMatch.betAmount1, activeMatch.betAmount2);
            payable(activeMatch.player1).transfer(winningAmount);
        } else if (activeMatch.betAmount2 > activeMatch.betAmount1) {
            uint256 winningAmount = calculatePrize(activeMatch.betAmount2, activeMatch.betAmount1);
            payable(activeMatch.player2).transfer(winningAmount);
        } else {
            // In case of a tie, refund the full bet amounts
            payable(activeMatch.player1).transfer(activeMatch.betAmount1);
            payable(activeMatch.player2).transfer(activeMatch.betAmount2);
        }

        delete matches[index];
    }

    function calculatePrize(uint256 winnerBet, uint256 loserBet) private returns(uint256) {
        uint256 winningAmount = winnerBet + loserBet;
        uint256 totalFee = calculateTotalFee(winnerBet); // Fee is calculated only on the winner's bet
        collectFees(totalFee);

        return winningAmount - totalFee;
    }

    function calculateTotalFee(uint256 amount) private pure returns(uint256) {
        return (amount * (DEVELOPER_FEE_PERCENT + JACKPOT_FEE_PERCENT)) / 100;
    }

    function collectFees(uint256 totalFee) private {
        uint256 developerFee = (totalFee * DEVELOPER_FEE_PERCENT) / (DEVELOPER_FEE_PERCENT + JACKPOT_FEE_PERCENT);
        uint256 jackpotFee = totalFee - developerFee;

        payable(owner).transfer(developerFee);
        payable(jackpotWallet).transfer(jackpotFee); // Transfer jackpot fee to the jackpot wallet
    }

    // Additional functions for jackpot and owner management could be added here
}