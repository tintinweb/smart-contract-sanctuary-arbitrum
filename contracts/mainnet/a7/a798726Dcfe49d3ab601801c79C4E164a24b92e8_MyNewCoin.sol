// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract MyNewCoin {
    // Mapping to store the balance of each address
    mapping (address => uint256) public balanceOf;

    // Name of the coin
    string public name;

    // Symbol of the coin
    string public symbol;

    // Total supply of the coin
    uint256 public totalSupply;

    // Event to notify when a transfer has taken place
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Initialize the contract
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    // Function to transfer coins from one address to another
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}