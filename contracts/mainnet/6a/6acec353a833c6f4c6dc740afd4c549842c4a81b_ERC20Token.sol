/**
 *Submitted for verification at Arbiscan on 2023-07-15
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

contract ERC20Token is IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 private _decimals;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _claimedUsers;
    uint256 private _maxClaimAmount;
    uint256 private _maxClaimUsers;
    uint256 private _claimedCount;
    mapping(address => uint256) private _userTransactionCount;
    string private _logoURI;

    address private _deployerWallet;

    constructor() {
        _name = "zkBLUEORDINALSLABS";
        _symbol = "zkBOL";
        _totalSupply = 23000000 * (10**18); // 23 million tokens
        _decimals = 18;
        _maxClaimAmount = 2070 * (10**18); // Each address can claim up to 2070 tokens
        _maxClaimUsers = 10000;

        // Transfer 10% supply to the deployer's wallet
        uint256 deployerAmount = (_totalSupply * 10) / 100;
        _balances[msg.sender] = deployerAmount;
        emit Transfer(address(0), msg.sender, deployerAmount);
        _deployerWallet = msg.sender;

        // Transfer 90% supply to the contract
        uint256 contractAmount = (_totalSupply * 90) / 100;
        _balances[address(this)] = contractAmount;
        emit Transfer(address(0), address(this), contractAmount);

        // Set IPFS logo URI
        _logoURI = "ipfs://QmT8bsPPuCFaHKTpooa9w4fup8nBc48KtvW2TQgn3g5TB6";
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount <= _balances[msg.sender], "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
return true;
}

function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
}

function approve(address spender, uint256 amount) public override returns (bool) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
}

function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    require(amount <= _balances[sender], "Insufficient balance");
    require(amount <= _allowances[sender][msg.sender], "Insufficient allowance");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][msg.sender] -= amount;
    emit Transfer(sender, recipient, amount);
    return true;
}

function claim() public returns (bool) {
    require(!_claimedUsers[msg.sender], "User has already claimed");
    require(_claimedCount < _maxClaimUsers, "All tokens have been claimed");
    require(_userTransactionCount[msg.sender] >= 3, "User must have at least 3 transactions on the network");
    require(msg.sender != _deployerWallet, "Claiming from deployer's wallet is not allowed");

    _claimedUsers[msg.sender] = true;
    _claimedCount++;

    uint256 airdropAmount = 0;
    if (_claimedCount <= 10000) {
        airdropAmount = _maxClaimAmount;
    } else if (_claimedCount == _maxClaimUsers) {
        airdropAmount = _totalSupply - (_maxClaimAmount * _maxClaimUsers);
    }

    require(airdropAmount > 0, "Insufficient tokens in the contract");

    _balances[address(this)] -= airdropAmount;
    _balances[msg.sender] += airdropAmount;
    emit Transfer(address(this), msg.sender, airdropAmount);
    return true;
}

function incrementTransactionCount() public {
    _userTransactionCount[msg.sender]++;
}

function logoURI() public view returns (string memory) {
    return _logoURI;
}
}