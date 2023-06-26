/**
 *Submitted for verification at Arbiscan on 2023-06-26
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
    mapping(address => bool) private _participated;
    address public creator;
    bool public mintingEnabled;
    uint256 public mintStartTime;
    uint256 public mintEndTime;
    uint256 public constant mintAmount = 500000 * (10 ** uint256(decimals)); // 500,000 tokens

    constructor() {
        creator = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Only the creator can call this function.");
        _;
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

        uint256 taxAmount = amount * 2 / 100; // Calculate 2% tax
        uint256 transferAmount = amount - taxAmount;

        _balances[msg.sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[address(this)] += taxAmount;

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, address(this), taxAmount);

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
        require(!_blacklist[recipient], "Recipient is in the blacklist and cannot receive.");
        require(_whitelist[sender] || _whitelist[recipient], "Transfer not allowed.");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function addBlacklist(address account) public onlyCreator {
        _blacklist[account] = true;
    }

    function removeBlacklist(address account) public onlyCreator {
        _blacklist[account] = false;
    }

    function addWhitelist(address account) public onlyCreator {
        _whitelist[account] = true;
    }

    function removeWhitelist(address account) public onlyCreator {
        _whitelist[account] = false;
    }

    function enableMint(uint256 duration) public onlyCreator {
        require(!mintingEnabled, "Minting is already enabled.");
        mintingEnabled = true;
        mintStartTime = block.timestamp;
        mintEndTime = block.timestamp + duration;
    }

    function disableMint() public onlyCreator {
        require(mintingEnabled, "Minting is not enabled.");
        mintingEnabled = false;
    }

    function mint() public payable {
        require(mintingEnabled, "Minting is not enabled.");
        require(msg.value == 0.001 ether, "Please send exactly 0.001 ETH to mint.");
        require(!_participated[msg.sender], "You have already participated in minting.");
        require(!_blacklist[msg.sender], "You are in the blacklist and cannot mint.");
        require(_remainingSupply >= mintAmount, "Minting amount exceeds remaining supply");
        require(address(this).balance >= mintAmount, "Contract balance is insufficient for minting");

        _participated[msg.sender] = true;

        _balances[address(this)] -= mintAmount;
        _balances[msg.sender] += mintAmount;
        _remainingSupply -= mintAmount;

        emit Transfer(address(this), msg.sender, mintAmount);
    }

    function extractBalance() public onlyCreator {
        require(address(this).balance > 0, "Contract balance is zero.");
        payable(creator).transfer(address(this).balance);
    }
}