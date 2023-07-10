/**
 *Submitted for verification at Arbiscan on 2023-07-10
*/

// SPDX-License-Identifier: MIT
/*
Twitter:https://twitter.com/ARB_BabyDoge3
TG:https://t.me/BABY_DOGE_3_ARB
*/
pragma solidity ^0.8.0;


interface IERC20 {
// Returns the total supply of tokens
    function totalSupply() external view returns (uint256);
// Returns the token balance of the specified account
    function balanceOf(address account) external view returns (uint256);
// Transfers a specified amount of tokens to the recipient
    function transfer(address recipient, uint256 amount) external returns (bool);
// Returns the remaining number of tokens that the spender is allowed to spend on behalf of the owner
    function allowance(address owner, address spender) external view returns (uint256);
// Approves the specified spender to transfer a specified amount of tokens from the owner's account   
    function approve(address spender, uint256 amount) external returns (bool);
// Transfers a specified amount of tokens from the sender's account to the recipient
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
// Event emitted when tokens are transferred from one address to another
    event Transfer(address indexed from, address indexed to, uint256 value);
// Event emitted when the approval of a spender is set by the owner
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BABYDOGE3 is IERC20 {
    string public constant name = "BABYDOGE3.0";
    string public constant symbol = "BABYDOGE3.0";
    uint8 public constant decimals = 16;
    uint256 private constant totalTokenSupply = 100000000000 * 10**uint256(decimals);
    uint256 private constant taxPercentage = 3;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private blacklist;
    bool private taxEnabled;
    address private owner;
/*
    Token name
    Token symbol
    Number of decimal places for token
    Total supply of tokens
    Percentage of tax for token transactions
    Balances of token holders
    Allowances for token transfers
    Addresses that are not allowed to interact with the token
    Status of tax (enabled/disabled)
    Address of the contract owner
*/
    constructor() {
        balances[msg.sender] = totalTokenSupply;
        owner = msg.sender;
        taxEnabled = false;
        emit Transfer(address(0), msg.sender, totalTokenSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address is not allowed.");
        require(amount > 0, "Transfer amount must be greater than zero.");
        require(balances[msg.sender] >= amount, "Insufficient balance.");

        if (blacklist[msg.sender]) {
            // Implement action for blacklisted sender
            // For example, revert the transfer or apply penalties
            revert("Transfer is not allowed for blacklisted sender.");
        }

        uint256 transferAmount = amount;
        uint256 taxAmount = 0;

        if (taxEnabled) {
            taxAmount = amount * taxPercentage / 100;
            transferAmount = amount - taxAmount;
        }

        balances[msg.sender] -= amount;
        balances[recipient] += transferAmount;
        balances[owner] += taxAmount;

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, owner, taxAmount);

        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "Approval to the zero address is not allowed.");
        
        allowances[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address is not allowed.");
        require(amount > 0, "Transfer amount must be greater than zero.");
        require(balances[sender] >= amount, "Insufficient balance.");
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance.");

        if (blacklist[sender]) {
            // Implement action for blacklisted sender
            // For example, revert the transfer or apply penalties
            revert("Transfer is not allowed for blacklisted sender.");
        }

        uint256 transferAmount = amount;
        uint256 taxAmount = 0;

        if (taxEnabled) {
            taxAmount = amount * taxPercentage / 100;
            transferAmount = amount - taxAmount;
        }

        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[owner] += taxAmount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, owner, taxAmount);

        return true;
    }

    function addToBlacklist(address account) external onlyOwner {
        require(account != address(0), "Invalid account address.");
        blacklist[account] = true;
    }

    function removeFromBlacklist(address account) external onlyOwner {
        require(account != address(0), "Invalid account address.");
        blacklist[account] = false;
    }

    function enableTax() external onlyOwner {
        taxEnabled = true;
    }

    function disableTax() external onlyOwner {
        taxEnabled = false;
    }

    function relinquishOwnership() external onlyOwner {
        owner = address(0);
    }
}