/**
 *Submitted for verification at Arbiscan on 2022-05-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract RevertHelp {

    function dataSolot(uint data) public {
        revert("ECDSA: invalid signature");
        data;
    }
}