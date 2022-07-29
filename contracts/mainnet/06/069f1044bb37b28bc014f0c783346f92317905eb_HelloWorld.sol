/**
 *Submitted for verification at Arbiscan on 2022-07-29
*/

// SPDX-License-Identifier: MIT
// My First Smart Contract 
pragma solidity 0.8.8;
contract HelloWorld {
    function get()public pure returns (string memory){
        return 'Hello Contracts';
    }
}