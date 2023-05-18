/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GongdeCoin {
    string public name = "Gongde Coin";
    string public symbol = "GDC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * (10 ** uint256(decimals));

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(!frozenAccount[msg.sender], "Account frozen");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Invalid address");

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        require(!frozenAccount[from], "Account frozen");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid address");

        totalSupply += value;
        balanceOf[to] += value;
        emit Mint(to, value);
        emit Transfer(address(0), to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function freezeAccount(address account) public {
        require(account != address(0), "Invalid address");
        require(!frozenAccount[account], "Account already frozen");

        frozenAccount[account] = true;
        emit AccountFrozen(account);
    }

    function unfreezeAccount(address account) public {
        require(account != address(0), "Invalid address");
        require(frozenAccount[account], "Account not frozen");

        frozenAccount[account] = false;
        emit AccountUnfrozen(account);
    }
}