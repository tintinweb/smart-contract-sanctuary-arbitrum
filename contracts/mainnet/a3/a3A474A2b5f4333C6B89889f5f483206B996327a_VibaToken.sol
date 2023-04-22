/**
 *Submitted for verification at Arbiscan on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VibaToken {
    address public owner;
    string public name;
    string public symbol;
    uint8 public _decimals;
    uint public _totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    address public taxiAddress;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        owner = msg.sender;
        name = "VIBA Token";
        symbol = "VBT";
        _decimals = 9;
        _totalSupply = 1000000 * 10 ** _decimals;
        balanceOf[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function setTaxiAddress(address _taxiAddress) public {
        require(msg.sender == owner, "Only the owner can set the taxi address");
        taxiAddress = _taxiAddress;
    }

    function transfer(address to, uint value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        if (taxiAddress != address(0)) {
            uint tax = value * 2 / 100;
            balanceOf[taxiAddress] += tax;
            emit Transfer(msg.sender, taxiAddress, tax);
        }
        return true;
    }

    function approve(address spender, uint value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        if (taxiAddress != address(0)) {
            uint tax = value * 2 / 100;
            balanceOf[taxiAddress] += tax;
            emit Transfer(from, taxiAddress, tax);
        }
        return true;
    }
}