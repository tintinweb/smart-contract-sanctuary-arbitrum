/**
 *Submitted for verification at Arbiscan on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 private data;

    function set(uint256 value) public {
        data = value;
    }

    function get() public view returns (uint256) {
        return data;
    }
}