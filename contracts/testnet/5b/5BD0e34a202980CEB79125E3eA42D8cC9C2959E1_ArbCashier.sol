// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArbCashier {
    address public owner;
    address public cashier;
    address public betContract;

    string public name = "Locked Hilo";
    string public symbol = "lockedHILO";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;

    event Mint(address indexed user, uint256 amount);
    event Burn(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setBetContract(address _bet) public onlyOwner{
        betContract = _bet;
    }

    function setCashier(address newCashier) external onlyOwner {
        require(newCashier != address(0), "Cashier address must be valid.");
        cashier = newCashier;
    }

    function mint(address user, uint256 amount) external {
        require(msg.sender == cashier, "Only the cashier can mint tokens.");
        require(user != address(0), "User address must be valid.");

        _balances[user] += amount;
        totalSupply += amount;

        emit Mint(user, amount);
    }

    function burn(address user, uint256 amount) external {
        require(msg.sender == cashier || msg.sender == user);
        require(user != address(0), "User address must be valid.");
        require(_balances[user] >= amount, "User doees not have enough balance");
        /*
        Ensure underflow protection, just in case. Hard Forks may happen anytime and may affect
        Solidity, even if ^0.8.0 versions got under/over flow protection.
        A common example of hard fork which affected solidity logic was the one related to The DAO hack
        */
        _balances[user] -= amount;
        totalSupply -= amount;

        emit Burn(user, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(msg.sender == cashier || msg.sender == betContract || to == betContract);
        require(to != address(0), "Recipient address must be valid.");

        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
}