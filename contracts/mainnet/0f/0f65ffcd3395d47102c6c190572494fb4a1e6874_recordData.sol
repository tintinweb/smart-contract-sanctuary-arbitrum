/**
 *Submitted for verification at Arbiscan.io on 2024-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract recordData {
    string private storedData;

    // set value
    function set(string memory x) public {
        storedData = x;
    }

    // get value
    function get() public view returns (string memory) {
        return storedData;
    }
}