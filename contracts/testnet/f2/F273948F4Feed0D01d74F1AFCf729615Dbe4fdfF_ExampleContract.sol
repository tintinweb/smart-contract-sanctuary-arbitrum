/**
 *Submitted for verification at Arbiscan.io on 2023-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


contract ExampleContract {
  uint256 public a;
  struct ResolveTradeParams {
        uint256 queueId;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
    }

    function f1(
        bytes32[] memory priceId
    ) public returns (uint256) {
      a = 10;
      return 0;
    }
     function f2(
        bytes[] memory priceUpdateData
    ) public returns (uint256) {
      a = 10;
      return 0;
    }
     function f3(
      ResolveTradeParams[] calldata params
    ) public returns (uint256) {
      a = 10;
      return 0;
    }
     function f4(
        ResolveTradeParams calldata params
    ) public returns (uint256) {
      a = 10;
      return 0;
    }
    function f5(
        ResolveTradeParams calldata params
    ) public payable  returns (uint256) {
      a = 10;
      return 0;
    }
    function f6() public payable  returns (uint256) {
      a = 10;
      return 0;
    }
}