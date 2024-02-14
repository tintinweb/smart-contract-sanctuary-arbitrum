/**
 *Submitted for verification at Arbiscan.io on 2024-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    address public owner;
    mapping(address => uint256) public allowances;
    
    constructor() {
        owner = msg.sender;
    }
    
    function approve(address _spender, uint256 _amount) external returns (bool) {
        require(_spender != address(0), "Invalid spender address");
        require(msg.sender != _spender, "Cannot approve yourself");
        
        allowances[msg.sender] = _amount;
        
        return true;
    }
}