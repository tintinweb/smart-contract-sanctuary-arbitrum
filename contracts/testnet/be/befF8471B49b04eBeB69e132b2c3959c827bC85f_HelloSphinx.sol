// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract HelloSphinx {
    uint8 public number;
    address public contractOne;

    constructor(uint8 _number, address _contractOne) {
        number = _number;
        contractOne = _contractOne;
    }

    function increment() public {
        number += 1;
    }
}