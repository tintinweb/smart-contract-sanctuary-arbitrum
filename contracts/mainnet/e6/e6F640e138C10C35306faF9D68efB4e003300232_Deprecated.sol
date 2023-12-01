/**
 *Submitted for verification at Arbiscan.io on 2023-11-27
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Deprecated {
    fallback() external payable {
        revert("Contract Deprecated");
    }
}