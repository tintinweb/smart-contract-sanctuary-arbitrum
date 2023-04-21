/**
 *Submitted for verification at Arbiscan on 2023-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mimi {
    string public name = "Mimi";
    string public symbol = "MIMI";
    uint256 public totalSupply = 1000000000000000; // 1 trillion tokens
    uint8 public decimals = 9;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public taxFee = 4;
    address public teamWallet;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        teamWallet = msg.sender; // set team wallet to contract deployer
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        uint256 taxAmount = value * taxFee / 100;
        uint256 transferAmount = value - taxAmount;
        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[teamWallet] += taxAmount;
        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, teamWallet, taxAmount);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");
        uint256 taxAmount = value * taxFee / 100;
        uint256 transferAmount = value - taxAmount;
        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[teamWallet] += taxAmount;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, transferAmount);
        emit Transfer(from, teamWallet, taxAmount);
        emit Approval(from, msg.sender, allowance[from][msg.sender]);
        return true;
    }
}