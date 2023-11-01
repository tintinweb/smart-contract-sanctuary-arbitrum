// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract Earndrop {
    string public statement;

    constructor() {
        statement = "hey there test";
    }

    function getStatement() public view returns (string memory) {
        return statement;
    }
}