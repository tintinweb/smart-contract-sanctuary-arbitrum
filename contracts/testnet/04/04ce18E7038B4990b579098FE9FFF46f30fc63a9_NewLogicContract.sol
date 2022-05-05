/**
 *Submitted for verification at Arbiscan on 2022-04-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract NewLogicContract {
    uint256 public a = 100;
    uint256 public b = 10;

    function getA() external view returns(uint256){
        return a;
    }

    function getB() external view returns(uint256){
        return b;
    }
}