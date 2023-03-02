/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

contract EthBalance {
    function check(address addy) public view returns(uint256) {
        return addy.balance;
    }
}