/**
 *Submitted for verification at Arbiscan on 2023-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IERC20 {
    function totalSupply() external pure returns (uint256);
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
    uint256 private constant _totalSupply = 10000000000 * (10 ** uint256(decimals)); // 100 billion tokens
    uint256 private _remainingSupply = _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklist;
    mapping(address => bool) private _whitelist;
    address public creator;
    bool public mintingEnabled;
    uint256 public mintStartTime;
    uint256 public mintEndTime;
    uint256 public constant mintAmount = 1000000 * (10 ** uint256(decimals)); // 1 million tokens

    constructor() {
        creator = 0x65b8376A836Da53757cA7e4B8810add3Fd78AC4c;
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
        require(!_blacklist[recipient], "Recipient is in the blacklist and cannot receive.");
        require(_whitelist[msg.sender] || _whitelist[recipient], "Transfer not allowed.");

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
        require(!_blacklist[recipient], "Recipient is in the blacklist and cannot receive.");
        require(amount <= _balances[sender], "ERC20: transfer amount exceeds balance");
        require(amount <= _allowances[sender][msg.sender], "ERC20: transfer amount exceeds allowance");
        require(_whitelist[sender] || _whitelist[recipient], "Transfer not allowed.");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function enableMint() public {
        require(msg.sender == creator, "Only the creator can enable minting.");
        require(!mintingEnabled, "Minting is already enabled.");
        mintingEnabled = true;
        mintStartTime = block.timestamp;
        mintEndTime = block.timestamp + 30 days;
    }

    function mint() public {
        require(mintingEnabled, "Minting is not enabled.");
        require(block.timestamp >= mintStartTime && block.timestamp <= mintEndTime, "Minting is only allowed within the specified timeframe.");
        require(_remainingSupply >= mintAmount, "Insufficient remaining supply for minting.");

        _balances[msg.sender] += mintAmount;
        _remainingSupply -= mintAmount;
        emit Transfer(address(0), msg.sender, mintAmount);
    }

    // Additional functions and modifiers can be added as needed
}