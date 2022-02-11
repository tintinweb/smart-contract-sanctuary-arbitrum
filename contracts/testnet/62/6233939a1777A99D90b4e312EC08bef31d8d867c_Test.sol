/**
 *Submitted for verification at arbiscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Test {
    constructor() {}
    function get() external view returns(bytes32) {
        return bytes32(uint256(uint160(bytes20(msg.sender))));
    }
}