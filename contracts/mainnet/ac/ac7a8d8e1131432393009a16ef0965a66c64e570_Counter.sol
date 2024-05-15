// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    function checkPush0() public pure returns (uint256 v) {
        assembly {
            v := 0
        }
    }
}