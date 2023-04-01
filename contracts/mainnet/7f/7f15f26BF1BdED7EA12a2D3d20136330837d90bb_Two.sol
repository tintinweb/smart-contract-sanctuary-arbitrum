/**
 *Submitted for verification at Arbiscan on 2023-03-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Two {
    uint256 public value;

    function setValue(uint256 newValue) public returns (bool) {
        uint256 gasUsed = gasleft();
        require(gasUsed >= 30000, "Insufficient gas");
        value = newValue;
        return true;
    }
}