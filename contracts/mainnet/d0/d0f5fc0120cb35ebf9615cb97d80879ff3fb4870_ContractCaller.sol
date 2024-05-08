/**
 *Submitted for verification at Arbiscan.io on 2024-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractCaller {
    function getBalanceOf(address who) public view returns (uint256) {
        return address(who).balance;
    }

}