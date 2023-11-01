// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract MyContract {
    event MyEvent(address indexed from, uint256 value);

    function triggerEvent(uint256 _value) public {
        emit MyEvent(msg.sender, _value);
    }
}