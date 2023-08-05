/**
 *Submitted for verification at Arbiscan on 2023-08-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


contract TestMath {
    uint256 public constant MAX_UINT256 = type(uint256).max;
    uint256 public current;

    function testAdd(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function testSub(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b;
    }
    function testMul(uint256 a, uint256 b) public pure returns (uint256) {
        return a * b;
    }
    function testDiv(uint256 a, uint256 b) public pure returns (uint256) {
        return a / b;
    }
    function testMod(uint256 a, uint256 b) public pure returns (uint256) {
        return a % b;
    }
    function breaking() public view returns (uint256) {
        return current - MAX_UINT256;
    }
}