// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.7;

contract ArrayExample {
    uint[] public numbers;

    function addNumber(uint _number) public {
        numbers.push(_number);
    }

    function getNumber(uint _index) public view returns (uint) {
        return numbers[_index];
    }
}