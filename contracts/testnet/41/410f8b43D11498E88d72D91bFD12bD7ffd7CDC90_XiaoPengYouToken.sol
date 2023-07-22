/**
 *Submitted for verification at Arbiscan on 2023-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract XiaoPengYouToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "XiaoPengYou";
        symbol = "XPY";
        decimals = 18;
        totalSupply = 100000000000 * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }
}