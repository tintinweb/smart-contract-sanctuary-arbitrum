/**
 *Submitted for verification at Arbiscan on 2023-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


contract W3WLPLock {
    uint256 public TimeNow;


    constructor() {
        WithdrawLP();
    }

  function WithdrawLP() public {
        TimeNow = block.timestamp;
  }


}