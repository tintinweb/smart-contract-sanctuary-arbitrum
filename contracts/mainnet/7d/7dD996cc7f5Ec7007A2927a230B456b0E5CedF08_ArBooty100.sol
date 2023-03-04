// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ArBooty100 {
    uint256 public value;

    constructor(uint256 _value) {
        value = _value;
    }

    function setValue(uint256 _value) public {
        value = _value;
    }
}