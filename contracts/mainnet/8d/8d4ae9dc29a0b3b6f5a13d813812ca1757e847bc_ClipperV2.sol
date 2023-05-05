/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract claimer {
    constructor () {
        assembly {
            function R(ptr, s, size) {
                if iszero(s) { 
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize()) 
                }
                if gt(size, 0) {
                    returndatacopy(ptr, 0, size)
                }
            }

            let p := mload(0x40)

            mstore(p, 0x84bc8c4800000000000000000000000000000000000000000000000000000000)
            let success := call(gas(), 0x5692Df6FB6Fa5C93e16454dc25E6b471F8FEba9E, 0, p, 0x04, 0, 0)
            R(p, success, 0x00)

            mstore(p, 0x70a0823100000000000000000000000000000000000000000000000000000000) 
            mstore(add(p, 0x04), address())
            success := staticcall(gas(), 0x5692Df6FB6Fa5C93e16454dc25E6b471F8FEba9E, p, 0x24, 0, 0)
            R(p, success, 0x20)

            let b := mload(p)

            mstore(p, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(p, 0x04), origin())
            mstore(add(p, 0x24), b)
            success := call(gas(), 0x5692Df6FB6Fa5C93e16454dc25E6b471F8FEba9E, 0, p, 0x44, 0, 0)
            R(p, success, 0x00)
        }
    }
}

contract ClipperV2 {
    function batchMint(uint count) external {
        for (uint i = 0; i < count;) {
            new claimer();
            unchecked {
                i++;
            }
        }

    }
}