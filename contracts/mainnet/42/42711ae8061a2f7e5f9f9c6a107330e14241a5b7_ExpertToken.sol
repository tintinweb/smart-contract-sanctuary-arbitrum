/**
 *Submitted for verification at Arbiscan.io on 2024-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ExpertToken {
    mapping(address => uint256) public balances;
    address public owner;
    uint256 public totalSupply = 645_000_000_000_000_000_000_000_000_000; // Total supply 645 trillion tokens
    uint256 public burnRate = 5; // Rate of burn in percentage
    uint256 public mintRate = 2; // Rate of minting in percentage
    uint256 public buybackAmount = 100_000_000_000_000_000_000_000; // Amount for buyback in token units

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply; // Assign initial total supply to contract owner
    }

    function transfer(address _to, uint256 _amount) public {
        require(_to != address(0), "Invalid address");
        require(_amount > 0 && _amount <= balances[msg.sender], "Invalid amount");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    function burn(uint256 _amount) public onlyOwner {
        require(_amount > 0 && _amount <= balances[msg.sender], "Invalid amount to burn");
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
    }

    function mint(uint256 _amount) public onlyOwner {
        uint256 mintAmount = (_amount * mintRate) / 100;
        totalSupply += mintAmount;
        balances[msg.sender] += mintAmount;
    }

    function buyback() public onlyOwner {
        require(buybackAmount <= balances[msg.sender], "Insufficient balance for buyback");
        totalSupply -= buybackAmount;
        balances[msg.sender] -= buybackAmount;
    }

    function deposit() public payable {
        require(msg.value > 0, "Invalid deposit amount");
        balances[msg.sender] += msg.value;
    }

    function withdrawAll() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
}