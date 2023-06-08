/**
 *Submitted for verification at Arbiscan on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for the basic ERC20 functions
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

// Interface for additional ERC20 metadata functions
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SafeMath library to prevent overflow and underflow
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}

contract DDindex is IERC20, IERC20Metadata {
    using SafeMath for uint256;

    string private _name = "DDindex";
    string private _symbol = "DDI";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 500000000 ether;
    address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Modifier to restrict certain functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function.");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // Returns the name of the token
    function name() public view override returns (string memory) {
        return _name;
    }

    // Returns the symbol of the token
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    // Returns the number of decimals used for token representation
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // Returns the total supply of tokens
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the balance of a specific address
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Transfers tokens from the sender to a specified recipient
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // Returns the remaining allowance of a spender for a specific owner
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approves the spender to spend a certain amount of tokens on behalf of the owner
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Transfers tokens from a sender to a recipient on behalf of the owner
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // Increases the spender's allowance by a certain amount
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    // Decreases the spender's allowance by a certain amount
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    // Burns a specific amount of tokens from the caller's balance
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // Burns a specific amount of tokens from the specified account's balance
    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }

    // Renounces ownership of the contract
    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }

    // Internal function to transfer tokens from one address to another
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    // Internal function to approve a spender to spend a certain amount of tokens on behalf of an owner
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Internal function to burn a specific amount of tokens from a given account
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}