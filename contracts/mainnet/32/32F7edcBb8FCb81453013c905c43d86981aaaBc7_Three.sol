/**
 *Submitted for verification at Arbiscan on 2023-03-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Three {
    uint256 public value;

    function setValue(uint256 newValue) public returns (bool) {
        require(
            msg.sender == tx.origin,
            "Transaction must be initiated externally"
        );
        require(gasleft() >= 30000, "Insufficient gas");
        value = newValue;
        return true;
    }
}