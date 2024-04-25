/**
 *Submitted for verification at Arbiscan.io on 2024-04-25
*/

// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

/// @notice Onchain registry library for large language models.
contract Models {
    event Registered(string model, bytes32 hash);

    mapping(string model => bytes32 hash) public models;

    function register(string calldata model, bytes32 hash) public {
        emit Registered(model, models[model] = hash);
    }
}