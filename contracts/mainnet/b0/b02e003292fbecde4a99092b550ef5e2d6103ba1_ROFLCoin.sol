/**
 *Submitted for verification at Arbiscan on 2023-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ROFLCoin {
    string public name = "ROFLCoin";
    string public symbol = "ROFL";
    uint8 public decimals = 18;
    uint256 public totalSupply = 4206899999999999 * 10 ** decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 public taxRate = 1; // 0.1% tax rate on transfers

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");

        uint256 taxAmount = _value * taxRate / 10000;
        uint256 transferAmount = _value - taxAmount;

        balances[msg.sender] -= _value;
        balances[_to] += transferAmount;
        balances[owner] += taxAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, owner, taxAmount);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");
        require(allowed[_from][msg.sender] >= _value, "Not authorized");

        uint256 taxAmount = _value * taxRate / 10000;
        uint256 transferAmount = _value - taxAmount;

        balances[_from] -= _value;
        balances[_to] += transferAmount;
        balances[owner] += taxAmount;

        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, owner, taxAmount);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function setTaxRate(uint256 _taxRate) public {
        require(_taxRate < 100, "Tax rate must be less than 1%"); // Limit tax rate to 1%
        taxRate = _taxRate;
    }
}