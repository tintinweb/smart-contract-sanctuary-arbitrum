/**
 *Submitted for verification at Arbiscan on 2022-07-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract tester {
    uint256 public gasPrice;

    function setGasPrice() external {
        gasPrice = tx.gasprice;
    }
}