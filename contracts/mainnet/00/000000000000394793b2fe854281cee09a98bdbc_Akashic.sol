/**
 *Submitted for verification at Arbiscan.io on 2024-04-11
*/

// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

/// @notice Onchain library for governed string pairing.
contract Akashic {
    event Written(string topic);

    address constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    mapping(string topic => string about) public read;

    function write(string calldata topic, string calldata about) public {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), 0x00) }
        }
        read[topic] = about;
        emit Written(topic);
    }
}