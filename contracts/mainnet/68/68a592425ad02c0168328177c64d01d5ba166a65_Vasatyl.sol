/**
 *Submitted for verification at Arbiscan.io on 2024-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for IERC20 standard
interface ERC20  {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
}

// SafeMath library
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

// Implement ERC20  with SafeMath
contract Vasatyl is ERC20  {
    using SafeMath for uint256;

    string public name = "Vasatyl";
    string public symbol = "VSTL";
    uint8 public decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    address private _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply * 10**uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // BEP-20 functions
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, SafeMath.sub(_allowances[sender][msg.sender], amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _burn(account, amount);
        _approve(account, msg.sender, SafeMath.sub(_allowances[account][msg.sender], amount, "Burn amount exceeds allowance"));
    }

    // Internal functions
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        _balances[sender] = SafeMath.sub(_balances[sender], amount, "Transfer amount exceeds balance");
        _balances[recipient] = SafeMath.add(_balances[recipient], amount);

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");
        require(amount > 0, "Burn amount must be greater than zero");

        _balances[account] = SafeMath.sub(_balances[account], amount, "Burn amount exceeds balance");
        _totalSupply = SafeMath.sub(_totalSupply, amount, "Burn amount exceeds total supply");

        emit Transfer(account, address(0), amount);
        emit Burn(account, amount);
    }
}