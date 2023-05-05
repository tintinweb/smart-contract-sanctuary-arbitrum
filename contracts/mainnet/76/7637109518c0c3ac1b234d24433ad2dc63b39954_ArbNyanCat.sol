// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint balance);
    function allowance(address owner, address spender) external view returns (uint remaining);
    function transfer(address recipient, uint amount) external returns (bool success);
    function approve(address spender, uint amount) external returns (bool success);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ArbNyanCat is ERC20Interface, Ownable {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address private constant MARKETING_ADDRESS = 0x28321e0fa158D075d9433a185Be6e8a724EAf558;

    uint256 private constant BURN_TAX = 2;
    uint256 private constant MARKETING_TAX = 3;

    constructor() {
        symbol = "NYAN";
        name = "Nyan Cat";
        decimals = 18;
        _totalSupply = 100000000000000000000000000000;
        balances[0x8A453755F7d5C43E6f9ae0B625Bd8b55CA2EC897] = _totalSupply;
        emit Transfer(address(0), 0x8A453755F7d5C43E6f9ae0B625Bd8b55CA2EC897, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint balance) {
        return balances[account];
    }

    function transfer(address recipient, uint amount) public returns (bool success) {
        uint256 burnAmount = (amount * BURN_TAX) / 100;
        uint256 marketingAmount = (amount * MARKETING_TAX) / 100;
        uint256 netAmount = amount - burnAmount - marketingAmount;

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[recipient] = balances[recipient] + netAmount;
        balances[BURN_ADDRESS] = balances[BURN_ADDRESS] + burnAmount;
        balances[MARKETING_ADDRESS] = balances[MARKETING_ADDRESS] + marketingAmount;

        emit Transfer(msg.sender, recipient, netAmount);
        emit Transfer(msg.sender, BURN_ADDRESS, burnAmount);
        emit Transfer(msg.sender, MARKETING_ADDRESS, marketingAmount);

        return true;
    }

    function approve(address spender, uint amount) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns (bool success) {
        uint256 burnAmount = (amount * BURN_TAX) / 100;
        uint256 marketingAmount = (amount * MARKETING_TAX) / 100;
        uint256 netAmount = amount - burnAmount - marketingAmount;

        balances[sender] = balances[sender] - amount;
        allowed[sender][msg.sender] = allowed[sender][msg.sender] - amount;
        balances[recipient] = balances[recipient] + netAmount;
        balances[BURN_ADDRESS] = balances[BURN_ADDRESS] + burnAmount;
        balances[MARKETING_ADDRESS] = balances[MARKETING_ADDRESS] + marketingAmount;

        emit Transfer(sender, recipient, netAmount);
        emit Transfer(sender, BURN_ADDRESS, burnAmount);
        emit Transfer(sender, MARKETING_ADDRESS, marketingAmount);

        return true;
    }

    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }
}