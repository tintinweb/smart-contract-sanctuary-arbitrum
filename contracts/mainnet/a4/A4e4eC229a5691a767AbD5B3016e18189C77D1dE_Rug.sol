/**
 *Submitted for verification at Arbiscan on 2023-04-23
*/

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

contract Rug is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public transactionTax;
    address public owner;

    constructor() {
        name = "Rug Token";
        symbol = "RUG";
        decimals = 18;
        _totalSupply = 1000000 * 10 ** uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        transactionTax = 1;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = amount * transactionTax / 100;
        uint256 amountAfterTax = amount - taxAmount;
        _transfer(msg.sender, recipient, amountAfterTax);
        if (taxAmount > 0) {
            _transfer(msg.sender, owner, taxAmount);
        }
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = amount * transactionTax / 100;
        uint256 amountAfterTax = amount - taxAmount;
        _transfer(sender, recipient, amountAfterTax);
        if (taxAmount > 0) {
            _transfer(sender, owner, taxAmount);
        }
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function setTransactionTax(uint256 tax) public {
        require(msg.sender == owner, "Only the contract owner can set the transaction tax.");
        require(tax <= 10, "Transaction tax cannot exceed 10%.");
        transactionTax = tax;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address.");
        require(recipient != address(0), "Transfer to the zero address.");
        require(amount > 0, "Transfer amount must be greater than zero.");
        require(_balances[sender] >= amount, "Insufficient balance.");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address.");
        require(spender != address(0), "Approve to the zero address.");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}