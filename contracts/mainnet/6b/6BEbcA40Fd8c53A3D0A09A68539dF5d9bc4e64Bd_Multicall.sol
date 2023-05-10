/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls) public view returns (uint256[] memory results) {

        results = new uint256[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.staticcall(calls[i].callData);
            require(success, "Multicall: call failed");
            results[i] = abi.decode(result, (uint256));
        }
    }

    function aggregate2(Call[] memory calls) public view returns (uint256[] memory results) {

        results = new uint256[](calls.length);
        bytes[] memory resultsBytes = new bytes[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.staticcall(calls[i].callData);
            require(success, "Multicall: call failed");
            resultsBytes[i] = result;
        }
        
        assembly {
            let ptr := 0
            for { let i := 0 } lt(i, mload(resultsBytes)) { i := add(i, 1) } {
                let res := mload(add(mload(add(resultsBytes, i)), 32))
                mstore(add(results, mul(i, 32)), res)
            }
        }
    }
}