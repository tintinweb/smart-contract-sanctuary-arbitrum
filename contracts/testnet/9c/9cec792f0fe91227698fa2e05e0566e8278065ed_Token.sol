/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    address public burnAddress;
    address public treasuryWallet;
    
    uint256 public constant PERCENTAGE_FACTOR = 100;
    uint256 public constant HOLDER_PERCENTAGE = 3;
    uint256 public constant BURN_PERCENTAGE = 1;
    uint256 public constant TREASURY_PERCENTAGE = 2;
    
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address _burnAddress, address _treasuryWallet) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        burnAddress = _burnAddress;
        treasuryWallet = _treasuryWallet;
        balanceOf[msg.sender] = _totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        balanceOf[msg.sender] -= _value;
        uint256 holderPercentage = (_value * HOLDER_PERCENTAGE) / PERCENTAGE_FACTOR; // alokasi 3% ke holder
        uint256 burnPercentage = (_value * BURN_PERCENTAGE) / PERCENTAGE_FACTOR; // alokasi 1% ke burn address
        uint256 treasuryPercentage = (_value * TREASURY_PERCENTAGE) / PERCENTAGE_FACTOR; // alokasi 2% ke treasury wallet
        balanceOf[_to] += holderPercentage;
        balanceOf[burnAddress] += burnPercentage;
        balanceOf[treasuryWallet] += treasuryPercentage;
        totalSupply -= burnPercentage;
        emit Transfer(msg.sender, _to, holderPercentage);
        emit Transfer(msg.sender, burnAddress, burnPercentage);
        emit Transfer(msg.sender, treasuryWallet, treasuryPercentage);
        return true;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}