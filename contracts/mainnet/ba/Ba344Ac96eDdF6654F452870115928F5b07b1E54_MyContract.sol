// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.6;

contract MyContract {
    uint256 public myNumber;

    function setMyNumber(uint256 _myNumber) public {
        myNumber = _myNumber;
    }
}