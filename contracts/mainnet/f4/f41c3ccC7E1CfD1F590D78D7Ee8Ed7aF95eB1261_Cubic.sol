// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.7;

contract Cubic {
    function calculateCubic(uint256 num) public pure returns (uint256) {
        return num * num * num;
    }
}