/**
 *Submitted for verification at Arbiscan on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract CS {
    // 合约代码...
}
pragma solidity ^0.8.0;contract CESHI {
    string public name = "CESHI";
    string public symbol = "CS";
    uint256 public totalSupply = 10000000 * 10 ** 18; // 代币总量为一千万
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    uint256 public taxRate = 2; // 买卖税为2%

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = 0x06077446AdF4bFe7A641Fb671F3898a6Bdf1a239;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        uint256 taxAmount = (value * taxRate) / 100;
        uint256 netAmount = value - taxAmount;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += netAmount;
        balanceOf[owner] += taxAmount;

        emit Transfer(msg.sender, to, netAmount);
        emit Transfer(msg.sender, owner, taxAmount);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");

        uint256 taxAmount = (value * taxRate) / 100;
        uint256 netAmount = value - taxAmount;

        balanceOf[from] -= value;
        balanceOf[to] += netAmount;
        balanceOf[owner] += taxAmount;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, netAmount);
        emit Transfer(from, owner, taxAmount);

        return true;
    }
}