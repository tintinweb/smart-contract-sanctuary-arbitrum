/**
 *Submitted for verification at Arbiscan on 2023-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract simpleCounter {
    uint public count;

    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to increment count by 1
    function plus() public {
        count += 1;
    }

    // Function to decrement count by 1
    function minus() public {
        // This function will fail if count = 0
        count -= 1;
    }
}