// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Test {
    uint256 public count;

    constructor() {}

    function increaseCount(uint256 increase) external {
        uint256 isIncrease = increase;
        count = count + isIncrease;
    }
}