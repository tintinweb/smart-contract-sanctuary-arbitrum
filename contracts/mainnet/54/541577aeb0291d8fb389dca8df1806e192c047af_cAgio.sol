/**
 *Submitted for verification at Arbiscan.io on 2024-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract cAgio {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _whitelist;
    address private _owner;

    string public name = "Covered Agio Token";
    string public symbol = "cAGIO";
    uint8 public decimals = 18;
    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event WhitelistStatusChanged(address indexed account, bool isWhitelisted);
    event Mint(address indexed to, uint256 amount);

    constructor(uint256 initialSupply) {
        _owner = msg.sender;
        _totalSupply = initialSupply * 10**uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    modifier onlyWhitelistedOrOwner() {
        require(_whitelist[msg.sender] || msg.sender == _owner, "Caller is not whitelisted or owner");
        _;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function mint(address to, uint256 amount) external onlyWhitelistedOrOwner {
        require(to != address(0), "Mint to the zero address");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _balances[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function addToWhitelist(address account) external onlyOwner {
        _whitelist[account] = true;
        emit WhitelistStatusChanged(account, true);
    }

    function removeFromWhitelist(address account) external onlyOwner {
        _whitelist[account] = false;
        emit WhitelistStatusChanged(account, false);
    }

    function isWhitelisted(address account) external view returns (bool) {
        return _whitelist[account];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Insufficient balance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}