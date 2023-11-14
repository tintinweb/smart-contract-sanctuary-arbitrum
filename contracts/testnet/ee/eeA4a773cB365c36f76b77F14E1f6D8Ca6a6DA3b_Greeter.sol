/**
 *Submitted for verification at Arbiscan.io on 2023-11-08
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: UNLICENSED

contract Greeter {
    /* define variable greeting of the type string */
    string greeting;
    address owner;

    /* this runs when the contract is executed */
    constructor(string memory _greeting) {
        greeting = _greeting;
        owner = msg.sender;
    }

    function newGreeting(string memory _greeting) public {
        require(msg.sender == owner, "You're not an owner");
        greeting = _greeting;
    }

    /* main function */
    function greet() public view returns (string memory) {
        return greeting;
    }
}