// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract Test {
    uint256 public value;
    mapping(address => bool) callers;

    function setValue(uint256 _value) public {
        value = _value;
    }

    function tryThing() public {
        callers[msg.sender] = true;
    }
}