/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// SPDX-License-Identifier: MIT
// File: contracts/Choco.sol




pragma solidity ^0.8.0;

contract test {
    uint256 public a;
    constructor (uint256 _a)
    {
        a=_a;
    }

    function created() public view returns (uint256) {
        return a+5;
    }
}