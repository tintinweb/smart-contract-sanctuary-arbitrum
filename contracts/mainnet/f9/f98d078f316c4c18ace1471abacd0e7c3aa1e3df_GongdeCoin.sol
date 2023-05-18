/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GongdeCoin {
    string public name = "Gongde Coin";
    string public symbol = "GDC";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor() {
        totalSupply = 10000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Not allowed to transfer");
        require(to != address(0), "Invalid address");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);

        return true;
    }

    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public returns (bool) {
        require(recipients.length == amounts.length, "Invalid batch transfer");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            totalAmount += amounts[i];
        }

        require(balanceOf[msg.sender] >= totalAmount, "Insufficient balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            address to = recipients[i];
            uint256 amount = amounts[i];

            balanceOf[msg.sender] -= amount;
            balanceOf[to] += amount;

            emit Transfer(msg.sender, to, amount);
        }

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function burn(uint256 value) public {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        totalSupply -= value;

        emit Burn(msg.sender, value);
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}