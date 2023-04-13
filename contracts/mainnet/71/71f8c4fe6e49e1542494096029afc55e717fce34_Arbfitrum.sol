/**
 *Submitted for verification at Arbiscan on 2023-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Arbfitrum {
    string public name = "Arbfitrum";
    string public symbol = "ARBF";
    uint256 public totalSupply = 100000000 ether;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isLocked;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Lock(address indexed owner, bool locked);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(isLocked[msg.sender] == false, "Account is locked");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        require(spender != address(0), "Invalid address");

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        require(isLocked[from] == false, "Account is locked");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        totalSupply -= value;

        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function lock(bool value) public returns (bool success) {
        isLocked[msg.sender] = value;

        emit Lock(msg.sender, value);
        return true;
    }
}