/**
 *Submitted for verification at Arbiscan.io on 2024-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract McLaren {
    string public name = "McLaren Lu Warna Apa Bos?";
    string public symbol = "MCLAREN";
    uint256 public totalSupply = 2024 * 10 ** 0; // Total supply: 2024 McLaren Coin
    address public owner;
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(balanceOf[_to] + _value >= balanceOf[_to], "Integer overflow");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == owner, "Only owner can mint tokens");
        require(_to != address(0), "Invalid address");
        
        balanceOf[_to] += _value;
        totalSupply += _value;

        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
}