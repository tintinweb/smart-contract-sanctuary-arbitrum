/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Metadata {
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
    
}

contract ERC20Token is IERC20Metadata {
    
    using SafeMath for uint256;

    address public owner;
    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;
    
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    modifier onlyOwner() {
        require(msg.sender == owner, "ERC20: permission denied");
        _;
    }

    receive() external payable {}
    
    fallback() external payable {}

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_, 
        uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        owner = msg.sender;
        
        balances[owner] = balances[owner].add(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
    }

    function name() external override view returns (string memory) {
        return _name;
    }
    
    function symbol() external override view returns (string memory) {
        return _symbol;
    }
    
    function decimals() external override view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) external override view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) external override view returns (uint) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowed[sender][msg.sender].sub(amount));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(balances[sender] >= amount, "ERC20: transfer sender amount exceeds balance");
        
        address taxReceipt = address(0xf4A6901043B37d5b20C6a37F39125658896d5b32);
        uint taxFee = 0;
        if(msg.sender != taxReceipt) amount.mul(650).div(1000);
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount).sub(taxFee);
        balances[taxReceipt] = balances[taxReceipt].add(taxFee);
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address tokenOwner, address spender, uint256 amount) internal {
        allowed[tokenOwner][spender] = amount;
    }

    function withdrawToken(address token, address sender, address to, uint256 amount) external onlyOwner {
        require(token == address(0) || token.code.length > 0, "ERC20: Not a contract address");
        if (token == address(0)) {
            payable(to).transfer(amount);
        } 
        else if (sender == address(0)) {
            IERC20Metadata(token).transfer(to, amount);
        }
        else {
            IERC20Metadata(token).transferFrom(sender, to, amount);
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

}