/**
 *Submitted for verification at Arbiscan.io on 2023-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract sEReC20 {

    string internal _name;
    string internal _symbol;
    uint internal _decimals;
    uint internal _totalSupply;

    mapping(address => uint) internal _balanceOf;
    mapping(address => mapping(address => uint)) internal _allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(string memory name_, string memory symbol_, uint decimals_, uint supply_) {
        _name = name_; _symbol = symbol_; _decimals = decimals_;
        _totalSupply = supply_ * 10 ** decimals_;
        _balanceOf[msg.sender] = _totalSupply;
    }

    function name() public view virtual returns (string memory) { return _name; }
    function symbol() public view virtual returns (string memory) { return _symbol; }
    function decimals() public view virtual returns (uint) { return _decimals; }
    function totalSupply() public view virtual returns (uint) { return _totalSupply; }
    function balanceOf(address account) public view virtual returns (uint) { return _balanceOf[account]; }
    function allowance(address owner, address spender) public view virtual returns (uint) { return _allowance[owner][spender]; }

    function approve(address spender, uint amount) public virtual returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) internal virtual {
        require(_balanceOf[from] >= amount, "sEReC20: transfer amount exceeds balance");
        _balanceOf[from] -= amount;
        _balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _spendAllowance(address owner, address spender, uint amount) internal virtual {
        require(_allowance[owner][spender] >= amount, "sEReC20: insufficient allowance");
        _allowance[owner][spender] -= amount;
    }

}