/**
 *Submitted for verification at Arbiscan on 2022-11-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract BalanceFetcher {

    function fetch (address _address) external view returns (uint) {
        return _address.balance;
    }

}