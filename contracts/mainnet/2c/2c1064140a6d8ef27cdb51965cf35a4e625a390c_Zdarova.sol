/**
 *Submitted for verification at Arbiscan on 2023-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Zdarova {
    // Event declaration
    // Up to 3 parameters can be indexed.
    // Indexed parameters helps you filter the logs by the indexed parameter
    event Log(address indexed sender, string message);
    event AnotherLog();

    function test() public {
        emit Log(msg.sender, "Zdarova Mir!");
        emit Log(msg.sender, "Zdarova EVM!");
        emit AnotherLog();
    }
}