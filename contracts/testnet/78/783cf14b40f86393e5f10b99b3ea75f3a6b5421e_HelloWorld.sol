/**
 *Submitted for verification at Arbiscan on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    event Log(address indexed sender, string message);

    uint256 number;

    function getNumber() public view returns (uint256) {
        return number;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function get() external pure returns (string memory greeting) {
        return greeting = "Hello, world!";
    }
}