/**
 *Submitted for verification at Arbiscan on 2023-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MomsFriendsSun is IERC20 {
string public name = "MomsFriendsSun";
string public symbol = "MFS";
uint256 private _totalSupply = 100000000 * 10**18;
uint8 public decimals = 18;

mapping(address => uint256) private _balances;
mapping(address => mapping(address => uint256)) private _allowances;

address public marketingWallet = 0xfd4eB9ea79925fb4fb0A94a6fAa116247ACd11bd;
uint256 public marketingFee = 10;

constructor() {
    _balances[msg.sender] = _totalSupply;
}

function totalSupply() external view override returns (uint256) {
    return _totalSupply;
}

function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
}

function transfer(address to, uint256 amount) public override returns (bool) {
    require(_balances[msg.sender] >= amount, "Insufficient balance");
    _transfer(msg.sender, to, amount);
    return true;
}

function _transfer(address from, address to, uint256 amount) internal {
    require(from != address(0), "Cannot transfer from zero address");
    require(to != address(0), "Cannot transfer to zero address");

    uint256 marketingAmount = (amount * marketingFee) / 100;
    uint256 transferAmount = amount - marketingAmount;

    _balances[from] -= amount;
    _balances[to] += transferAmount;
    _balances[marketingWallet] += marketingAmount;

    emit Transfer(from, to, transferAmount);
    emit Transfer(from, marketingWallet, marketingAmount);
}

function approve(address spender, uint256 amount) public override returns (bool) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
}

function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
}

function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
    require(_balances[from] >= amount, "Insufficient balance");
    require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
    _allowances[from][msg.sender] -= amount;
    _transfer(from, to, amount);
    return true;
}
}