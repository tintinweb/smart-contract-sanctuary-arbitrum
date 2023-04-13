/**
 *Submitted for verification at Arbiscan on 2023-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WagerManager {
    address public owner;
    address public participant1;
    address public participant2;
    address public judge;
    uint256 public wagerAmount;
    bool public participant1Deposited;
    bool public participant2Deposited;

    mapping(address => uint256) public outcomes;
    uint256 public finalOutcome;
    bool public emergencyWithdrawalApproved;
    bool public judgeFeeClaimed;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function deposit(address _judge, uint256 _wagerAmount) external payable {
        require(participant1 == address(0) || participant2 == address(0) || msg.sender == participant1 || msg.sender == participant2, "Only participants can deposit");
        require(judge == address(0) || judge == _judge, "Judge must be the same for both participants");
        require(wagerAmount == 0 || wagerAmount == _wagerAmount, "Wager amount must be the same for both participants");
        require(msg.value == _wagerAmount, "Incorrect deposit amount");

        if (judge == address(0)) {
            judge = _judge;
        }

        if (wagerAmount == 0) {
            wagerAmount = _wagerAmount;
        }

        if (participant1 == address(0)) {
            participant1 = msg.sender;
            participant1Deposited = true;
        } else if (participant2 == address(0) && msg.sender != participant1) {
            participant2 = msg.sender;
            participant2Deposited = true;
        } else if (msg.sender == participant1) {
            require(!participant1Deposited, "Participant1 already deposited");
            participant1Deposited = true;
        } else {
            require(!participant2Deposited, "Participant2 already deposited");
            participant2Deposited = true;
        }
    }

    function isDeposited(address participant) external view returns (bool) {
        if (participant == participant1) {
            return participant1Deposited;
        } else if (participant == participant2) {
            return participant2Deposited;
        } else {
            return false;
        }
    }

    function submitOutcome(uint256 outcome) external {
        require(msg.sender == participant1 || msg.sender == participant2, "Only participants can submit outcomes");
        outcomes[msg.sender] = outcome;
        
        if (outcomes[participant1] != 0 && outcomes[participant1] == outcomes[participant2]) {
            finalOutcome = outcomes[participant1];
            judgeFeeClaimed = false; // Reset judge fee claim status
        }
    }

    function judgeDecision(uint256 outcome) external {
        require(msg.sender == judge, "Only judge can decide");
        require(outcomes[participant1] != 0 && outcomes[participant2] != 0, "Both participants must submit their outcomes");
        require(outcomes[participant1] != outcomes[participant2], "Judge can only decide when participants have different outcomes");
        finalOutcome = outcome;
        judgeFeeClaimed = false; // Reset judge fee claim status
    }

    function claim() external {
        require(finalOutcome != 0, "Outcome not agreed upon");
        uint256 halfAmount = address(this).balance / 2;

        if (finalOutcome == 1 && msg.sender == participant1) {
                    payable(participant1).transfer(halfAmount * 2);
    } else if (finalOutcome == 2 && msg.sender == participant2) {
        payable(participant2).transfer(halfAmount * 2);
    } else {
        revert("Not a valid claim");
    }
}

    function claimJudgeFee() external {
        require(msg.sender == judge, "Only judge can claim the fee");
        require(finalOutcome != 0, "Outcome not agreed upon");
        require(!judgeFeeClaimed, "Judge fee already claimed");
        uint256 judgeFee = (address(this).balance * 5) / 100;
        payable(judge).transfer(judgeFee);
        judgeFeeClaimed = true;
    }

    function approveEmergencyWithdrawal() external {
        require(msg.sender == judge, "Only judge can approve emergency withdrawal");
        emergencyWithdrawalApproved = true;
    }

    function emergencyWithdraw() external onlyOwner {
        require(emergencyWithdrawalApproved, "Emergency withdrawal not approved by judge");
        payable(owner).transfer(address(this).balance);
    }

    function resetContract() external onlyOwner {
        require(finalOutcome != 0 || emergencyWithdrawalApproved, "Contract can only be reset after the outcome is agreed upon or emergency withdrawal is approved");

        participant1 = address(0);
        participant2 = address(0);
        participant1Deposited = false;
        participant2Deposited = false;
        judge = address(0);
        wagerAmount = 0;

        outcomes[participant1] = 0;
        outcomes[participant2] = 0;
        finalOutcome = 0;
        emergencyWithdrawalApproved = false;
        judgeFeeClaimed = false;
    }

    function refundParticipants() external {
        require(msg.sender == judge, "Only judge can refund");
        require(participant1Deposited || participant2Deposited, "At least one participant must have deposited");
        require(outcomes[participant1] != outcomes[participant2] || !participant1Deposited || !participant2Deposited, "Refund only allowed when outcomes are different or only one participant has deposited");

        if (participant1Deposited && !participant2Deposited) {
            uint256 refundAmount1 = address(this).balance;
            payable(participant1).transfer(refundAmount1);
        } else if (!participant1Deposited && participant2Deposited) {
            uint256 refundAmount2 = address(this).balance;
            payable(participant2).transfer(refundAmount2);
        } else {
            uint256 refundAmount = address(this).balance / 2;
            payable(participant1).transfer(refundAmount);
            payable(participant2).transfer(refundAmount);
        }
    }

    }