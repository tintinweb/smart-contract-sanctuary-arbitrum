// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.7;

contract Equation {
    function evaluateLinearEquation(int256 m, int256 x, int256 c) public pure returns (int256 y) {
        y = m*x + c;
    }
}