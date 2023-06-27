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

    function totalSupply() public view override returns (uint256) {
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
    
    function addBlacklist(address account) public {
        require(msg.sender == creator, "Only the creator can add accounts to the blacklist.");
        _blacklist[account] = true;
    }
    
    function removeBlacklist(address account) public {
        require(msg.sender == creator, "Only the creator can remove accounts from the blacklist.");
        _blacklist[account] = false;
    }
    
    function addWhitelist(address account) public {
        require(msg.sender == creator, "Only the creator can add accounts to the whitelist.");
        _whitelist[account] = true;
    }
    
    function removeWhitelist(address account) public {
        require(msg.sender == creator, "Only the creator can remove accounts from the whitelist.");
        _whitelist[account] = false;
    }
    
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }
    
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }
    
    function enableMint(uint256 startTime, uint256 endTime) public {
        require(msg.sender == creator, "Only the creator can enable minting.");
        require(startTime < endTime, "Invalid minting period");
        require(!mintingEnabled, "Minting is already enabled.");
        
        mintingEnabled = true;
        mintStartTime = startTime;
        mintEndTime = endTime;
    }
    
    function disableMint() public {
        require(msg.sender == creator, "Only the creator can disable minting.");
        require(mintingEnabled, "Minting is not enabled.");
        
        mintingEnabled = false;
    }
    
    function mint() public payable {
        require(mintingEnabled, "Minting is not enabled.");
        require(block.timestamp >= mintStartTime && block.timestamp <= mintEndTime, "Minting is not currently allowed.");
        require(msg.value >= 0.001 ether, "Insufficient ETH sent for minting.");
        
        uint256 tokensToMint = (msg.value * mintAmount) / 0.001 ether;
        require(tokensToMint <= _remainingSupply, "Mint amount exceeds remaining supply.");
        
        _balances[msg.sender] += tokensToMint;
        _remainingSupply -= tokensToMint;
        emit Transfer(address(0), msg.sender, tokensToMint);
    }
    
    function withdrawBalance() public {
        require(msg.sender == creator, "Only the creator can withdraw the contract balance.");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw.");
        
        payable(msg.sender).transfer(balance);
    }
}