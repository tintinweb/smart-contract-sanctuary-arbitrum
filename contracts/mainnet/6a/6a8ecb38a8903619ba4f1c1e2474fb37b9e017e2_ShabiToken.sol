/**
 *Submitted for verification at Arbiscan on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShabiToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "shabi";
        symbol = "SHABI";
        totalSupply = 10000000000000000000000000000; // 10,000,000,000,000 * 10^18
        decimals = 18;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
}