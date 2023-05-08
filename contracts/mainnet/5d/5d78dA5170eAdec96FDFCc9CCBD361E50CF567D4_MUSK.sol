/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MUSK {
    string public name = "MUSK";
    string public symbol = "MUSK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1_000_000_000_000 * 10**uint256(decimals);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public blackHoleAddress;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function setBlackHoleAddress(address _blackHoleAddress) external {
        require(blackHoleAddress == address(0), "Black hole address has already been set");
        blackHoleAddress = _blackHoleAddress;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, allowance[from][msg.sender] - value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(value > 0, "Transfer value must be greater than zero");
        require(balanceOf[from] >= value, "Insufficient balance");

        uint256 burnAmount = value / 100; // 1% of the transfer amount will be burned
        uint256 transferAmount = value - burnAmount;

        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[blackHoleAddress] += burnAmount;

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, blackHoleAddress, burnAmount);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}