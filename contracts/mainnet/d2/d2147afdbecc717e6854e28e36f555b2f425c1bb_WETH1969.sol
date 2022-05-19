/**
 *Submitted for verification at Arbiscan on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract WETH1969 {
    mapping (address => uint) public  balanceOf;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable { 
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 0);
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint wad = balanceOf[msg.sender];
        require(wad > 0);
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(wad);
    }

    function resure(IERC20 token, uint amount) public {
        token.transfer(owner, amount);
    }
}