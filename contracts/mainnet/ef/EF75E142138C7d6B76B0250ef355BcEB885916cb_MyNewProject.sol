// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract MyNewProject {
    // The total supply of tokens
    uint256 public totalSupply;
    
    // Mapping to keep track of each address's balance
    mapping (address => uint256) public balances;

    // Event that gets emitted whenever tokens are transferred
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor(uint256 _initialSupply) {
        // The deployer of the contract gets the initial supply
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    // Function to transfer tokens from one address to another
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Function to check the balance of a specific address
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}