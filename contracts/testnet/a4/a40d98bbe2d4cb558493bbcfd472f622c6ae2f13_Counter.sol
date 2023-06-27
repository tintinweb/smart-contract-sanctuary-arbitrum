// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Counter {
    uint256 private count;

    function increment() public {
        count++;
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}