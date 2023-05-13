/**
 *Submitted for verification at Arbiscan on 2023-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MillionaireToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 16; // 小数位设置为16位

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public owner;
    bool public isContractActive;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractDeactivated();

    constructor() {
        name = "Millionaire";
        symbol = "MILL";
        totalSupply = 1000000000 * 10**uint256(decimals); // 10亿
        
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        isContractActive = true;
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }
    
    modifier onlyActiveContract() {
        require(isContractActive, "Contract is deactivated");
        _;
    }
    
    function transfer(address to, uint256 value) external onlyActiveContract returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        emit Transfer(msg.sender, to, value);
        
        return true;
    }

    function approve(address spender, uint256 value) external onlyActiveContract returns (bool) {
        allowance[msg.sender][spender] = value;
        
        emit Approval(msg.sender, spender, value);
        
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external onlyActiveContract returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Not allowed to transfer this amount");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        
        return true;
    }
    
    function mint(address to, uint256 value) external onlyOwner onlyActiveContract {
        require(totalSupply + value <= 10000000000 * 10**uint256(decimals), "Total supply exceeds limit"); // 增发时总供应量上限为 100 亿
        
        totalSupply += value;
        balanceOf[to] += value;
        
        emit Mint(to, value);
        emit Transfer(address(0), to, value);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    function deactivateContract() external onlyOwner {
        isContractActive = false;
        
        emit ContractDeactivated();
    }
}