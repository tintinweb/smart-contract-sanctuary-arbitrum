/**
 *Submitted for verification at Arbiscan.io on 2023-11-10
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}