/**
 *Submitted for verification at Arbiscan.io on 2023-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


contract ExampleContract {
  struct ResolveTradeParams {
        uint256 queueId;
        bytes[] priceUpdateData;
        bytes32[] priceIds;
    }

    function f1(
        bytes32[] memory priceId
    ) public pure returns (uint256) {
      return 0;
    }
     function f2(
        bytes[] memory priceUpdateData
    ) public pure returns (uint256) {
      return 0;
    }
     function f3(
      ResolveTradeParams[] calldata params
    ) public pure returns (uint256) {
      return 0;
    }
     function f4(
        ResolveTradeParams calldata params
    ) public pure returns (uint256) {
      return 0;
    }
    function f5(
        ResolveTradeParams calldata params
    ) public payable  returns (uint256) {
      return 0;
    }
    function f6() public payable  returns (uint256) {
      return 0;
    }
}