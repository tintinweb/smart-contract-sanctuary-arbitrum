/**
 *Submitted for verification at Arbiscan on 2023-07-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Variables {
    address owner = 0x56A72a677b5Bfd1ad6e4323327d71bc6B8525C4D;
    uint balance = 123 * 1e6;
    int fee = -456;
    bool isLong = true;
    string name = "FSBC";

    uint private _fee = 123_000_000;

    /// @notice maxiumum amount of fee
    /// @dev automatically creates a getter
    uint public maxFee = 999_000_000;
}