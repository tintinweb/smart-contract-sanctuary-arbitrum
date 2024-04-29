/**
 *Submitted for verification at Arbiscan.io on 2024-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

contract Disperse {
    address payable public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function disperse(address[] memory _users, uint256[] memory _amounts) public payable onlyOwner {
        require(_users.length == _amounts.length, 'Same length');
        for (uint256 i = 0; i < _users.length; i++) {
            payable(_users[i]).transfer(_amounts[i]);
        }
    }

    function recoverETH() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}