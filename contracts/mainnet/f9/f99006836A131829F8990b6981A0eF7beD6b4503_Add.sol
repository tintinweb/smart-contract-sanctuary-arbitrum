// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.7;

contract Add {
    function adunare(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 sum = a + b;
        return sum;
    }
}