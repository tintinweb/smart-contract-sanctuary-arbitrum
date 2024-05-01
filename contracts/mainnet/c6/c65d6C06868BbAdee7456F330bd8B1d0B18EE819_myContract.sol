// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract myContract {
    address payable owner;
    uint256 balance;

    event Withdraw(address indexed _from, uint256 _value);
    event SecurityUpdate(address indexed _from, uint256 _amount);

    constructor() {
        owner = payable(msg.sender);
        balance = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
        require(balance >= _amount, "Insufficient balance");
        balance -= _amount;
        owner.transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function securityUpdate(uint256 _amount) public payable onlyOwner {
        balance += _amount;
        emit SecurityUpdate(msg.sender, _amount);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }
}