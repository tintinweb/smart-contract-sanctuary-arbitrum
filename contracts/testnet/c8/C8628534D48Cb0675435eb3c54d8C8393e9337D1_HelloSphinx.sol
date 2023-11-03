// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract HelloSphinx {
    string public greeting;
    uint public number;

    constructor(string memory _greeting, uint _number) {
        greeting = _greeting;
        number = _number;
    }

    function add(uint256 _myNum) public {
        number += _myNum;
    }
  }