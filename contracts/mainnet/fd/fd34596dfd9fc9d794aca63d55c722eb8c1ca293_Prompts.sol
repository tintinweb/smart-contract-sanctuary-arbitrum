/**
 *Submitted for verification at Arbiscan.io on 2024-04-25
*/

// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

/// @notice Onchain library for prompt engineering.
contract Prompts {
    event Written(string topic);

    mapping(string topic => string prompt) public prompts;

    function write(string calldata topic, string calldata prompt) public {
        prompts[topic] = prompt;
        emit Written(topic);
    }
}