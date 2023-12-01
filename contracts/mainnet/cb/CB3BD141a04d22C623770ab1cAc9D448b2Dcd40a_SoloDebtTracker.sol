/**
 *Submitted for verification at Arbiscan.io on 2023-11-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// SoloDebtTracker is used to manually track desired debt between the deployer
// and any desired other status. It lacks the complexity of the other trackers.

//@title SoloDebtTracker
//@author pavleprica
contract SoloDebtTracker {

    address private owner;

    // debt mapping us used to track the debts. The string value represents
    // the name of the debt. Recommended to add the currency to it. The uint is the amount of debt.
    mapping(string => uint) private debt;

    event DebtOpened(string debtName, uint debtAmount, uint timestamp);
    event DeptPayback(string debtName, uint debtAmount, uint timestamp);
    event DeptPaidInFull(string debtName, uint timestamp);

    constructor() {
        owner = msg.sender;
    }

    function openDebt(string memory debtName, uint debtAmount) public {
        assert(msg.sender == owner);

        require(debt[debtName] == 0, "Debt already exists");
        require(debtAmount > 0, "Debt amount must be greater than 0");

        debt[debtName] = debtAmount;
        emit DebtOpened(debtName, debtAmount, block.timestamp);
    }

    function payback(string memory debtName, uint debtAmount) public {
        assert(msg.sender == owner);

        require(debt[debtName] > 0, "Debt does not exist");
        require(debtAmount > 0, "Debt amount must be greater than 0");

        if (debt[debtName] < debtAmount) {
            debtAmount = debt[debtName];
        }

        debt[debtName] -= debtAmount;

        emit DeptPayback(debtName, debtAmount, block.timestamp);

        if (debt[debtName] == 0) {
            delete debt[debtName];
            emit DeptPaidInFull(debtName, block.timestamp);
        }
    }

}