// Deployed with the Atlas IDE
// https://app.atlaszk.com/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract HelloWorld {
    uint256 public storedInteger;

    function increment() public {
        storedInteger += 1;
    }
}