// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HelloWorld {
    string private _message;

    constructor(string memory _initialMessage) {
        _message = _initialMessage;
    }

    function message() external view returns (string memory) {
        return _message;
    }
}