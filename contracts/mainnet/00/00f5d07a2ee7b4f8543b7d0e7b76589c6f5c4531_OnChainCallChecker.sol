/**
 *Submitted for verification at Arbiscan.io on 2024-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract OnChainCallChecker {
    address public sOrigin;
    address public sCaller;
    uint256 public sBaseFee;
    uint256 public sGasPrice;
    uint256 public sGasLimit;
    uint256 public sGas;
    address public sCoinbase; 

    function write() public {
        assembly {
            sstore(sOrigin.slot, origin())
            sstore(sCaller.slot, caller())
            sstore(sBaseFee.slot, basefee())
            sstore(sGasPrice.slot, gasprice())
            sstore(sGasLimit.slot, gaslimit())
            sstore(sGas.slot, gas())
            sstore(sCoinbase.slot, coinbase())
        }
    }

    function paramsWithGasCheck() public view returns (address a0, address a1, uint256 b0, uint256 b1, uint256 b2, uint256 b3, address b4) {
        assembly {
            let gasToBurn := add(100000, gaslimit())
            if iszero(gt(gas(), gasToBurn)) { invalid() }
            a0 := origin()
            a1 := caller()
            b0 := basefee()
            b1 := gasprice()
            b2 := gaslimit()
            b3 := gas()
            b4 := coinbase()
        }
    }

    function params() public view returns (address a0, address a1, uint256 b0, uint256 b1, uint256 b2, uint256 b3, address b4) {
        assembly {
            a0 := origin()
            a1 := caller()
            b0 := basefee()
            b1 := gasprice()
            b2 := gaslimit()
            b3 := gas()
            b4 := coinbase()
        }
    }
}