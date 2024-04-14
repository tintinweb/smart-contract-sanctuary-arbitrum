/**
 *Submitted for verification at Arbiscan.io on 2024-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.19;

contract TestGasPrice {
    uint256 public lastGasPrice;

    function testGasPrice() external {
        lastGasPrice = tx.gasprice;
    }
}