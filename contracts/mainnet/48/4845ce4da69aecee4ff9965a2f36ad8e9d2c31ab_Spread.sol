/**
 *Submitted for verification at Arbiscan.io on 2024-02-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Spread {

    function spread(address[] calldata _to, uint256[] calldata value) public payable {

        uint256 i = 0;
        for (i = 0; i < _to.length; i++) {
            _to[i].call{value: value[i]};
        }
        
        uint256 balance = address(this).balance;
        if (balance > 0) msg.sender.call{value: balance};
    }

}