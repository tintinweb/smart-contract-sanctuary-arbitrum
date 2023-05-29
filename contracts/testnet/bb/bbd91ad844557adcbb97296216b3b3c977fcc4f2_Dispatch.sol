/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

// SPDX-License-Identifier: GPL-3.0

  pragma solidity >=0.7.0 <0.9.0;

  contract Dispatch {
      fallback (bytes calldata _input) external payable returns (bytes memory _output)   {}
  }