// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract HelloSphinx {
    uint8 public number;

    constructor(uint8 _number) {
        number = _number;
    }

    function increment() public {
        number += 1;
    }
}