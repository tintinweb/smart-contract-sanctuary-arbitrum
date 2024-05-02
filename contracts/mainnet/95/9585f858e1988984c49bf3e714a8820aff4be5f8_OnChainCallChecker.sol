/**
 *Submitted for verification at Arbiscan.io on 2024-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract OnChainCallChecker {
    function paramsWithGasCheck() public view returns (address a0, address a1, uint256 b0, uint256 b1, uint256 b2, uint256 b3) {
        assembly {
            let gasToBurn := add(100000, gaslimit())
            if iszero(gt(gas(), gasToBurn)) { invalid() }
            a0 := origin()
            a1 := caller()
            b0 := gasprice()
            b1 := gaslimit()
            b2 := gas()
            b3 := coinbase()
        }
    }

    function params() public view returns (address a0, address a1, uint256 b0, uint256 b1, uint256 b2, uint256 b3) {
        assembly {
            a0 := origin()
            a1 := caller()
            b0 := gasprice()
            b1 := gaslimit()
            b2 := gas()
            b3 := coinbase()
        }
    }
}