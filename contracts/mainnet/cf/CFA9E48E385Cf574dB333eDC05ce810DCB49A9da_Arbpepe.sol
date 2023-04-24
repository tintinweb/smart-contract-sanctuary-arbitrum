/**
 *Submitted for verification at Arbiscan on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Arbpepe {
    string public name = "Arbpepe";
    string public symbol = "AIPEPE";
    uint256 public totalSupply = 1000000000000 ether;
    uint8 public decimals = 18;
    uint256 public constant DIVIDER = 20;

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

        // Apply 5% dividend to the transfer amount
        uint256 dividend = (value * 5) / DIVIDER;
        balanceOf[owner] += dividend;

        emit Transfer(msg.sender, to, value);
        emit Transfer(msg.sender, owner, dividend);
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

        // Apply 5% dividend to the transfer amount
        uint256 dividend = (value * 5) / DIVIDER;
        balanceOf[owner] += dividend;

        emit Transfer(from, to, value);
        emit Transfer(from, owner, dividend);
        return true;
    }

    function burn(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        // Apply 1% burn to the burn amount
        uint256 burnAmount = (value * 1) / DIVIDER;

        balanceOf[msg.sender] -= value;
        totalSupply -= burnAmount;

        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), burnAmount);
        return true;
    }

    function lock(bool value) public returns (bool success) {
        isLocked[msg.sender] = value;

        emit Lock(msg.sender, value);
        return true;
    }
}