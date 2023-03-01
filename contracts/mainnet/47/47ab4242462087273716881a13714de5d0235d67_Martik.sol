/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

//SPDX-License-Identifier: MIT

//Site:             https://martik.site/
//Telegram EUA:     https://t.me/martik_en
//Telegram  BR:     https://t.me/martik_pt
//Twitter:          https://twitter.com/martik_crypto

//Smart Contract rede Bep20: 0x116526135380E28836C6080f1997645d5A807FAE
pragma solidity ^0.8.7;

contract Martik {
    string private _name = "Martik";
    string private _symbol = "MTK";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 0;

    address private _owner;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) _minters;

    uint256 public totalTax = 1000;
    uint256 public Fee1 = 500;
    uint256 public Fee2 = 500;
    uint256 public feeDenominator = 10000;

    address public Fee1Receiver;
    address public Fee2Receiver;

    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            "Ownable: only owner can call this function"
        );
        _;
    }
    modifier onlyMinter() {
        require(_minters[msg.sender], "Only minter can call this function");
        _;
    }

    constructor() payable {
        _owner = msg.sender;
        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;

        Fee1Receiver = _owner;
        Fee2Receiver = _owner;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function allowance(address holder, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function setMintable(address minter, bool _mintable) public onlyOwner {
        _minters[minter] = _mintable;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setFee1Receiver(address _Fee1Receiver) external onlyOwner {
        Fee1Receiver = _Fee1Receiver;
    }

    function setFee2FeeReceiver(address _Fee2FeeReceiver) external onlyOwner {
        Fee2Receiver = _Fee2FeeReceiver;
    }

    function namount(uint256 amount, uint256 fee)
        public
        view
        returns (uint256)
    {
        return (amount * fee) / feeDenominator;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(
            _allowances[sender][msg.sender] >= amount,
            "You cannot spend that much on this account"
        );
        _allowances[sender][msg.sender] =
            _allowances[sender][msg.sender] -
            amount;
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        uint256 amountWithFee = amount;
        if (
            _isExcludedFromFee[sender] || _isExcludedFromFee[recipient]
        ) {} else {
            amountWithFee = amount - namount(amount, totalTax);
            uint256 Fee1Amount = namount(amount, Fee1);
            uint256 Fee2Amount = namount(amount, Fee2);
            _txTransfer(sender, Fee1Receiver, Fee1Amount);
            _txTransfer(sender, Fee2Receiver, Fee2Amount);
        }
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amountWithFee;
        emit Transfer(sender, recipient, amountWithFee);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(_balances[sender] >= amount, "insuficient balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address account, uint256 amount) external onlyMinter {
        require(account != address(0), "Cannot mint to zero address");

        _totalSupply = _totalSupply + (amount);
        _balances[account] = _balances[account] + amount;
        require(_totalSupply <= 1000 * (10**18), "Cannot mint more");
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= _balances[account]);
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _txTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function setFees(uint256 _Fee1, uint256 _Fee2) external onlyOwner {
        require(_Fee1 > 0);
        require(_Fee2 > 0);

        uint256 value = 100;
        require(namount(value, _Fee1 + _Fee2) <= 10, "MAX TAX IS 10%"); //max tax is 24%
        Fee1 = _Fee1;
        Fee2 = _Fee2;

        totalTax = _Fee1 + _Fee2;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}