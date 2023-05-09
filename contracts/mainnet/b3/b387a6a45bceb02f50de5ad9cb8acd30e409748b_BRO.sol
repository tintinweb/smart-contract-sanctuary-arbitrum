/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BRO {
    string public constant name = "brother";
    string public constant symbol = "BRO";
    uint8 public constant decimals = 0;
    uint256 public constant totalSupply = 1e11;
    address payable public owner;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    constructor() {
        owner = payable(msg.sender);
        balances[msg.sender] = totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balances[msg.sender], "ERC20: transfer amount exceeds balance");
        uint256 fee = amount / 5; // 20% fee
        balances[msg.sender] -= amount;
        balances[owner] += fee;
        balances[recipient] += amount - fee;
        emit Transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, owner, fee);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balances[sender], "ERC20: transfer amount exceeds balance");
        require(amount <= allowances[sender][msg.sender], "ERC20: transfer amount exceeds allowance");
        uint256 fee = amount / 5; // 20% fee
        balances[sender] -= amount;
        balances[owner] += fee;
        balances[recipient] += amount - fee;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, owner, fee);
        return true;
    }

    function burn(uint256 amount) public onlyOwner {
        require(amount <= balances[msg.sender], "ERC20: burn amount exceeds balance");
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}