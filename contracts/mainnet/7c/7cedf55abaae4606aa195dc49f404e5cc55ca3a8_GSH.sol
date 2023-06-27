/**
 *Submitted for verification at Arbiscan on 2023-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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

contract GSH is IERC20 {
    string public constant name = "GSH";
    string public constant symbol = "GSH";
    uint8 public constant decimals = 18;
    uint256 private constant _totalSupply = 100000000000 * (10 ** uint256(decimals)); // 100 billion tokens
    uint256 private _remainingSupply = _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklist;
    address public creator;
    bool public mintingEnabled;
    uint256 public constant maxMintAmount = 1000000 * (10 ** uint256(decimals)); // 1 million tokens
    bool public mintingStarted;

    constructor() {
        creator = msg.sender;
        _balances[creator] = _totalSupply;
        emit Transfer(address(0), creator, _totalSupply);
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_blacklist[msg.sender], "You are in the blacklist and cannot transfer.");
        require(amount <= _balances[msg.sender], "ERC20: transfer amount exceeds balance");

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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_blacklist[sender], "Sender is in the blacklist and cannot transfer.");
        require(amount <= _balances[sender], "ERC20: transfer amount exceeds balance");
        require(amount <= _allowances[sender][msg.sender], "ERC20: transfer amount exceeds allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function addBlacklist(address account) public {
        require(msg.sender == creator, "Only the creator can add accounts to the blacklist.");
        _blacklist[account] = true;
    }
    
    function removeBlacklist(address account) public {
        require(msg.sender == creator, "Only the creator can remove accounts from the blacklist.");
        _blacklist[account] = false;
    }
    
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }
    
    function enableMint() public {
        require(msg.sender == creator, "Only the creator can enable minting.");
        require(!mintingEnabled, "Minting is already enabled.");
        
        mintingEnabled = true;
        mintingStarted = true;
    }
    
    function disableMint() public {
        require(msg.sender == creator, "Only the creator can disable minting.");
        require(mintingEnabled, "Minting is not enabled.");
        
        mintingEnabled = false;
    }
    
    function mint() public {
        require(msg.sender == creator, "Only the creator can mint tokens.");
        require(mintingStarted, "Minting has not started yet.");
        require(mintingEnabled, "Minting is not enabled.");
        require(_balances[creator] >= maxMintAmount, "Mint amount exceeds creator's balance.");

        _balances[creator] -= maxMintAmount;
        _balances[msg.sender] += maxMintAmount;
        emit Transfer(creator, msg.sender, maxMintAmount);
    }
    
    function renounceOwnership() public {
        require(msg.sender == creator, "Only the creator can renounce ownership.");
        creator = address(0);
    }
}