/**
 *Submitted for verification at Arbiscan.io on 2023-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IARBToken {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event RewardRequest(address indexed from, uint256 amount);
}

contract ARBToken is IARBToken {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    address private _owner;
    uint256 private _lastTransferTimestamp;
    bool private gameRulesComplianceRequired;
    uint256 private constant maxTotalSupply = 500000;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier noCooldown() {
        require(block.timestamp - _lastTransferTimestamp >= 0, "Transfer is still on cooldown");
        _;
    }

    constructor() {
        _name = "Point tokens";
        _symbol = "P";
        _decimals = 4;
        _totalSupply = 100000000000000;
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        _lastTransferTimestamp = 0;
        gameRulesComplianceRequired = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override noCooldown returns (bool) {
        _transfer(msg.sender, recipient, amount);
        _lastTransferTimestamp = block.timestamp;
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override noCooldown returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override noCooldown returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        _lastTransferTimestamp = block.timestamp;
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Transfer amount exceeds balance");

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

    // 设置游戏规则合规要求
    function setGameRulesComplianceRequired(bool complianceRequired) external onlyOwner {
        gameRulesComplianceRequired = complianceRequired;
    }

    // 新增一个函数，用于前端网站请求奖励发放
    function requestReward(address recipient, uint256 amount) external {
        require(gameRulesComplianceRequired == false || msg.sender == _owner, "Reward request must comply with game rules or be approved by Owner");

        // 检查是否满足发放条件（一小时后且总量未超过最大限制）
        require(block.timestamp - _lastTransferTimestamp >= 3600, "Reward can only be distributed after 1 hour");
        require(_totalSupply + amount <= maxTotalSupply, "Total supply limit exceeded");

        _transfer(_owner, recipient, amount);
        emit RewardRequest(recipient, amount);
    }

    // 增加一个函数，用于Owner同意奖励发放
    function approveRewardRequest(address recipient, uint256 amount) external onlyOwner {
        _transfer(_owner, recipient, amount);
    }
}