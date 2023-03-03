/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract BullMastiffInu {
    string public name = "BullMastiffInu";
    string public symbol = "BMI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * 10**uint256(decimals);

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    address public owner;
    uint256 public burnPercent = 1;
    uint256 public taxPercent = 7;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");

        uint256 burnAmount = amount * burnPercent / 100;
        uint256 taxAmount = amount * taxPercent / 100;
        uint256 transferAmount = amount - burnAmount - taxAmount;

        balances[msg.sender] -= amount;
        balances[recipient] += transferAmount;
        balances[owner] += taxAmount;

        totalSupply -= burnAmount;

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, address(0), burnAmount);
        emit Transfer(msg.sender, owner, taxAmount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

        uint256 burnAmount = amount * burnPercent / 100;
        uint256 taxAmount = amount * taxPercent / 100;
        uint256 transferAmount = amount - burnAmount - taxAmount;

        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[owner] += taxAmount;

        totalSupply -= burnAmount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(0), burnAmount);
        emit Transfer(sender, owner, taxAmount);

        return true;
    }

    function allowance(address account, address spender) public view returns (uint256) {
        return allowances[account][spender];
    }
}