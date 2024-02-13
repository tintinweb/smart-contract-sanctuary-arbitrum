/**
 *Submitted for verification at Arbiscan.io on 2024-02-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Spread {

    function spread(address[] calldata addresses) public payable {

        uint256 value = msg.value / addresses.length;
        uint256 i;

        for (i = 0; i < addresses.length - 1; i++) {
            addresses[i].call{value: value};
        }
        
        addresses[i].call{value: value};
    }

}