/**
 *Submitted for verification at Arbiscan on 2022-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Good {
    // Event declaration
    // Up to 3 parameters can be indexed.
    // Indexed parameters helps you filter the logs by the indexed parameter
    event Log(address indexed sender, string message);
    event AnotherLog();

    function test() public {
        emit Log(msg.sender, "Hello Zero!");
        emit Log(msg.sender, "Hello BTC!");
        emit AnotherLog();
    }
}