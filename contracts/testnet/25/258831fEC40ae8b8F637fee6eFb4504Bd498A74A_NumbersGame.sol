/**
 *Submitted for verification at Arbiscan on 2023-07-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract NumbersGame {
    uint number = 42;

    function setNewNumber(uint newNumber) external {
        number = newNumber;
    }

    function letsSeeYourNumber() external view returns (uint256) {
        return number;
    }
}