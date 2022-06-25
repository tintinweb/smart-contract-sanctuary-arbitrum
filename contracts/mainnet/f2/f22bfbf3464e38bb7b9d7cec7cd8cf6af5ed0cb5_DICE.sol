/**
 *Submitted for verification at Arbiscan on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract DICE {
    mapping (address => uint) public dices;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable { 
        revert();
    }

    function save() public {
        dices[msg.sender] = block.number;
    }

    function update() public {
        uint bn = dices[msg.sender];
        dices[msg.sender] = bn + block.number;
    }

    function rescure(IERC20 token, uint amount) public {
        token.transfer(owner, amount);
    }
}