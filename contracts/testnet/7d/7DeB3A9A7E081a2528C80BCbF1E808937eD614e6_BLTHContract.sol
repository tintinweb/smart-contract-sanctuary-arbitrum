/**
 *Submitted for verification at Arbiscan on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BLTHContract is IERC20 {
    uint public totalSupply = 10000000000000000000000000;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Bluth Token";
    string public symbol = "BLTH";
    uint8 public decimals = 18;
    mapping(address => uint) public realBalanceOf;


    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }


    function transfer(address recipient, uint amount) external returns (bool) {
        
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    receive() external payable {
        realBalanceOf[msg.sender] += msg.value;
    }
    function withdraw(uint amount) public {
        require(realBalanceOf[msg.sender] >= amount);
        realBalanceOf[msg.sender] -= amount;
        (bool success, ) = address(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
    }
    
}