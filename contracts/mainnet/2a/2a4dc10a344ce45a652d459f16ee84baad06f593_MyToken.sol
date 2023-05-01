/**
 *Submitted for verification at Arbiscan on 2023-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//BurnV1 

contract MyToken {
    string public name = "BurnV1";
    string public symbol = "BR1";
    uint8 public decimals = 18;
    uint256 private totalSupply = 1000000000 * 10**18;
    uint256 private txCount = 0;
    uint256 private burnAmount = totalSupply / 10000; // 0.01% of total supply
    address private owner;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Cannot transfer to zero address");
        require(amount <= balances[msg.sender], "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        
        txCount++;
        if (txCount % 5 == 0) {
            _burn(burnAmount);
        }
        
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowances[tokenOwner][spender];
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Cannot transfer to zero address");
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");
        
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        
        txCount++;
        if (txCount % 5 == 0) {
            _burn(burnAmount);
        }
        
        return true;
    }
    
    function _burn(uint256 amount) internal {
        require(amount <= balances[owner], "Insufficient balance to burn");
        balances[owner] -= amount;
        totalSupply -= amount;
        emit Burn(owner, amount);
    }
    
    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}