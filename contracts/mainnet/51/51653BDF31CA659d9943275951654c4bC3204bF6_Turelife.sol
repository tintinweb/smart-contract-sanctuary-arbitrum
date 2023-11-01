// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.7;

contract Turelife {
    bool private state;

    constructor(bool _state) {
        state = _state;
    }

    function getState() public view returns (bool) {
        return state;
    }

    function setState(bool _state) public {
        state = _state;
    }
}