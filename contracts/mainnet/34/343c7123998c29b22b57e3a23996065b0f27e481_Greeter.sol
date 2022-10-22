/**
 *Submitted for verification at Arbiscan on 2022-10-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;


contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }
    
    function Hello() public view returns (string memory) {
        return "Hello World";
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}