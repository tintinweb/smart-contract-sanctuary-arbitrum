/**
 *Submitted for verification at Arbiscan.io on 2024-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isAllowedToSell;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address owner_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        _owner = owner_;
        _balances[owner_] = totalSupply_;
        _isExcludedFromFee[owner_] = true;
        _isAllowedToSell[owner_] = false; // 
        emit Transfer(address(0), owner_, totalSupply_);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAllowedToSell() {
        require(_isAllowedToSell[msg.sender], "Seller: caller is not allowed to sell");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - (subtractedValue)
        );
        return true;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function allowToSell(address account) external onlyOwner {
        _isAllowedToSell[account] = true;
    }

    function disallowToSell(address account) external onlyOwner {
        _isAllowedToSell[account] = false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "Transfer: transfer from the zero address");
        require(recipient != address(0), "Transfer: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            _balances[sender] >= amount,
            "Transfer: transfer amount exceeds balance"
        );

        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            // 扣除交易手续费等逻辑
            // 这里略去具体实现
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "Approval: approve from the zero address");
        require(spender != address(0), "Approval: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}