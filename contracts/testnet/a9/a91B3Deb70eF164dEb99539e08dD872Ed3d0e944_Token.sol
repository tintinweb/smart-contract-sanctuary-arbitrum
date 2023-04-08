// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;

// This is the main building block for smart contracts.
contract Token {
    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    string private test;
    string public publicTest;

    function setTest(string memory _test) public {
        test = _test;
    }

    function setPublicTest(string memory _test) public {
        publicTest = _test;
    }
}