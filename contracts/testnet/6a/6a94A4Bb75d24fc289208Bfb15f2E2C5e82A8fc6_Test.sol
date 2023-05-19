/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
contract Test {

    int256 public a;

    function getA() view public returns(int256){
        return a;
    }

    function setA() public{
        a += 1;
    }

}