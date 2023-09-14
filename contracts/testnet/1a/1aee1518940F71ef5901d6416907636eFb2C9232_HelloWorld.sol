// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract HelloWorld {
    string public message;

    constructor() {
        message = "Hello World!";
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}