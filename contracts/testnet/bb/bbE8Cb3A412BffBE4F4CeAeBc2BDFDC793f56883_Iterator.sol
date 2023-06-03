/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Iterator {
    uint256 public iterator;
    event IteratorIncreased(uint256 iteratorValue);
    constructor() {
        iterator = 0;
    }

    function increaseIterator() public {
        iterator++;
        emit IteratorIncreased(iterator);
    }
}