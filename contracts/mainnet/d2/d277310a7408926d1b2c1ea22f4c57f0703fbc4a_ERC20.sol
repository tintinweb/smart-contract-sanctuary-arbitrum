// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    address public owner;

    // @dev 合约部署时设置名称、符号和所有者
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        owner = msg.sender;  // 设置合约的部署者为所有者
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) public override returns (bool) {
        require(spender != address(0), "Approve to zero address");

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");

        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external onlyOwner {
        require(amount > 0, "Mint amount must be greater than zero");

        uint mintAmount = amount * 10 ** uint(decimals);  // 考虑小数位数
        balanceOf[msg.sender] += mintAmount;
        totalSupply += mintAmount;
        emit Transfer(address(0), msg.sender, mintAmount);
    }

    function burn(uint amount) external {
        require(amount > 0, "Burn amount must be greater than zero");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance to burn");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}