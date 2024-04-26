/**
 *Submitted for verification at Arbiscan.io on 2024-04-26
*/

// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

/// @notice Onchain library for prompt engineering.
contract Prompts {
    event Written(string topic);

    address constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    mapping(string topic => string prompt) public prompts;

    function write(string calldata topic, string calldata prompt) public {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), 0x00) }
        }
        prompts[topic] = prompt;
        emit Written(topic);
    }
}