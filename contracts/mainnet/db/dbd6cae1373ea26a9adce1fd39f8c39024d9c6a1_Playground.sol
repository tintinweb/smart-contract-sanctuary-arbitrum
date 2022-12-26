// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Playground {
    uint256 public stateNum;

    constructor() {}

    function callFunc() external {
        stateNum++;
    }
}