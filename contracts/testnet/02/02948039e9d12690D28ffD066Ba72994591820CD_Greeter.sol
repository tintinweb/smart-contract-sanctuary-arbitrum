/**
 *Submitted for verification at Arbiscan on 2023-03-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        // console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        // console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }
}