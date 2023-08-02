/**
 *Submitted for verification at Arbiscan on 2023-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTube {
    string public name = "NFTube";
    string public symbol = "NFTT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * 10**uint256(decimals); // Total Supply: 100,000,000 NFTT (100 million)

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() { 
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