/**
 *Submitted for verification at Arbiscan on 2023-07-31
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

contract ePONG is IERC20 {
    string public constant name = "ePONG";
    string public constant symbol = "ePONG";
    uint8 public constant decimals = 6;
    uint256 private _totalSupply = 9000000000 * (10**6);
    // X maximum tokens per transfer from X * (10 ** 6)
    uint256 private _transferLimit = 20 * (10 ** 6);
    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _limitSetter = 0x7Ede7716Fe0B79b24977A1cD3b7531af158f35d8; 
   
    constructor() {
       _balances[msg.sender] = _totalSupply;
    } 

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_balances[msg.sender] >= amount && amount > 0, "Transfer failed");
        require(amount <= _transferLimit, "Exceeded transfer limit");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

       function setTransferLimit(uint256 limit) public {
        require(msg.sender == _limitSetter, "Unauthorized"); // Only the limit setter can call this function
        _transferLimit = limit;
    }

    function getTransferLimit() public view returns (uint256) {
        return _transferLimit;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Approve failed");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Not enough allowance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}