/**
 *Submitted for verification at Arbiscan on 2022-04-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract numbercontract {

    uint256 public number;

    constructor() {
        number = 0;
    }

    function add() public returns(bool){
        number++;
        return true;
    }

    function get() public view returns(uint256) {
        return number;
    }
}