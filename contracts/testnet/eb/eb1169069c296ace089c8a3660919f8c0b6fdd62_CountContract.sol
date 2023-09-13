/**
 *Submitted for verification at Arbiscan.io on 2023-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CountContract {
    uint256 public count;

    constructor() {
        count = 0;
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function increment() public {
        count++;
    }
}