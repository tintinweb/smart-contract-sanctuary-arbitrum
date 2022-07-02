/**
 *Submitted for verification at Arbiscan on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Wormhole {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable { 
        revert();
    }

    function rescure(IERC20 token, uint amount) public {
        token.transfer(owner, amount);
    }

    function wriggle(address payable _recipient) public payable {
        require(_recipient != address(0));
        uint _a = msg.value;
        _recipient.transfer(_a);
    }
}