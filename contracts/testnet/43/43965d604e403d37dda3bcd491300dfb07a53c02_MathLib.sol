// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

library MathLib {

    function normalized(uint256 value, uint8 inDecimals, uint8 outDecimals) public pure returns (uint256) {
        if (inDecimals == outDecimals) {
            return value;
        }
        return value * 10 ** outDecimals / 10 ** inDecimals;
    }
}