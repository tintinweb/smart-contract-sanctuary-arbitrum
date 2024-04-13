// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library BytesCheck {
    /// @notice check if the first digit of the hexadecimal value starts with `0x0`
    function checkFirstDigit0x0(uint8 x) public pure returns (bool) {
        uint8 y = uint8(x & 0xF0);
        uint8 z = y >> 4;
        return (z == 0x0);
    }

    /// @notice check if the first digit of the hexadecimal value starts with `0x1`
    function checkFirstDigit0x1(uint8 x) public pure returns (bool) {
        uint8 y = uint8(x & 0xF0);
        uint8 z = y >> 4;
        return (z == 0x1);
    }

    /// @notice check if the first digit of the hexadecimal value starts with `0x2`
    function checkFirstDigit0x2(uint8 x) public pure returns (bool) {
        uint8 y = uint8(x & 0xF0);
        uint8 z = y >> 4;
        return (z == 0x2);
    }

    /// @notice check if the first digit of the hexadecimal value starts with `0x3`
    function checkFirstDigit0x3(uint8 x) public pure returns (bool) {
        uint8 y = uint8(x & 0xF0);
        uint8 z = y >> 4;
        return (z == 0x3);
    }
}