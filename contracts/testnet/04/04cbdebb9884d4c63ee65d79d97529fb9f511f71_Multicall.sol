/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }

    function Aggregate(bool requireSuccess, Call[] memory calls)
        public returns (Result[] memory returnData)
    {
        returnData = new Result[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.call(calls[i].callData);

            if (requireSuccess) {
                require(success, "Multicall aggregate: call failed");
            }

            returnData[i] = Result(success, result);
        }
        return returnData;
    }

}