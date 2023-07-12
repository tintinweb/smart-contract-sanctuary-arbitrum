// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library LiquidationParse {
    function tokenValueParse(uint256 data) public pure returns (address token, uint256 value) {
        token = address(uint160(data >> 96));
        value = data & 0xffffffffffffffffffffffff;
    }
}