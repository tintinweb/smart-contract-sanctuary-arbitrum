/**
 *Submitted for verification at Arbiscan on 2023-04-19
*/

// Solidity version
pragma solidity ^0.8.0;

// ERC20 interface
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

// Contract implementation
contract Aicheems is IERC20 {
    address public taxAddress;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor() {
        name = "Aicheems";
        symbol = "Aicheems";
        decimals = 18; // typical number of decimal places for Ethereum tokens
        _totalSupply = 100000000000000000000000000000;
        _balances[msg.sender] = _totalSupply;
        taxAddress = 0xa773A0e6c5c738b101ae54c1F164A38E3cc379Ba;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
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
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Insufficient balance");

        // Calculate 3% transaction fee
        uint256 fee = amount / 33; // 1/33 = 3%
        uint256 amountAfterFee = amount - fee;

        _balances[sender] -= amount;
        _balances[recipient] += amountAfterFee;
        _balances[taxAddress] += fee; // send fee to tax address

        emit Transfer(sender, recipient, amountAfterFee);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}