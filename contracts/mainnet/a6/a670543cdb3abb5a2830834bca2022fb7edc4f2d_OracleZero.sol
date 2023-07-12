// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract OracleZero {
    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestAnswer() external pure returns (int256) {
        return 0;
    }
}