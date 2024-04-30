/**
 *Submitted for verification at Arbiscan.io on 2024-04-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

contract Wkh {
    string public name = "WKH";
    string public symbol = "WKH";
    uint8 public decaimals = 6;
    uint public totalSupply = 10000000;
    address public owner;
    mapping(address => uint256) public balanceOfMap;
    mapping(address => mapping(address => uint256)) internal allowanceMap;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        owner = msg.sender;
        balanceOfMap[msg.sender] = totalSupply;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balanceOfMap[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        balanceOfMap[msg.sender] -= amount;
        balanceOfMap[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = balanceOfMap[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowanceMap[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        remaining = allowanceMap[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowanceMap[_from][msg.sender] > _value, "allowance remaining < value");
        require(balanceOfMap[_from] > _value, "balanceOf remaining < value");
        allowanceMap[_from][msg.sender] -= _value;
        balanceOfMap[_from] -= _value;
        balanceOfMap[_to] += _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

}