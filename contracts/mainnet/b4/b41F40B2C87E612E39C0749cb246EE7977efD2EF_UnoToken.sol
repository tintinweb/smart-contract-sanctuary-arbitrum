// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract UnoToken {
    string public name = "uno";
    string public symbol = "UNO";
    uint256 public totalSupply = 1000000; // 1 million tokens
    mapping(address => uint256) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        return true;
    }
}