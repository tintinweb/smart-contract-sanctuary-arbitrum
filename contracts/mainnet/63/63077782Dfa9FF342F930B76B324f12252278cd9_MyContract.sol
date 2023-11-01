// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.7;

contract MyContract {
    function greet(string memory name) public pure returns (string memory) {
        return string(abi.encodePacked("Hello, ", name));
    }
}