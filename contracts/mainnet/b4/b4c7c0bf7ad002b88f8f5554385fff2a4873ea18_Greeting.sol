/**
 *Submitted for verification at Arbiscan on 2022-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Greeting {
    string public name;
    string public gretingPrefix = "Hello ";

    constructor(string memory initialName) {
        name = initialName;
    }

    function setName(string memory newName) public {
        name = newName;
    }

    function getGreeting() public view returns (string memory) {
        return string(abi.encodePacked(gretingPrefix, name));
    }
}