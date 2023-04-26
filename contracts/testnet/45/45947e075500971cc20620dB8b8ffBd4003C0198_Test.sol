/**
 *Submitted for verification at Arbiscan on 2023-04-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

contract Test {
    event Num(uint256);

    constructor() {
    }

    function test() public {
        emit Num(tx.gasprice);
    }
}