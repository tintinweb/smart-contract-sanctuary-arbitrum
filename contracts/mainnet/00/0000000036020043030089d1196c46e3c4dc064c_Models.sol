/**
 *Submitted for verification at Arbiscan.io on 2024-04-26
*/

// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.25;

/// @notice Onchain registry library for large language models.
contract Models {
    event Registered(string model, bytes32 hash);

    address constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    mapping(string model => bytes32 hash) public models;

    function register(string calldata model, bytes32 hash) public {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), 0x00) }
        }
        emit Registered(model, models[model] = hash);
    }
}