/**
 *Submitted for verification at Arbiscan on 2022-08-30
*/

// SPDX-License-Identifier: MIT
// NOTE: These contracts have a critical bug.
// DO NOT USE THIS IN PRODUCTION
pragma solidity 0.8.11;



contract Inc{

    uint256 public balance;

    event Increment();

    function incrementBalance() payable public {
        emit Increment();
        balance += msg.value;
    }

}