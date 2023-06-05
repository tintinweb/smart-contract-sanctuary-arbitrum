/**
 *Submitted for verification at Arbiscan on 2023-06-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract JBToken {
    string public name = "JB";
    string public symbol = "JB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 5000000 * (10 ** uint256(decimals));
    address public owner;
    bool public buyOnly = true;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event BuyOnlyStatusChanged(bool buyOnly);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function transfer(address to, uint256 value) external {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(!buyOnly || to != address(0), "Selling is not allowed");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
    }

    function setBuyOnly(bool status) external onlyOwner {
        buyOnly = status;
        emit BuyOnlyStatusChanged(status);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }

    function safeTransfer(address to, uint256 value) external {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(!buyOnly || to != address(0), "Selling is not allowed");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
    }
}