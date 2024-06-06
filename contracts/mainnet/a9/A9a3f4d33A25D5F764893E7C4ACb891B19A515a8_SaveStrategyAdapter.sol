// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SaveStrategyAdapter {
    event SavedStrategy(address[] adapters, bytes[] data);
    event SavedDraft(address[] adapters, bytes[] data);

    error MISMATCH_LENGTH();

    function saveStrategy(address[] calldata adapters, bytes[] calldata data) external {
        // Ensure the lengths of the arrays are equal to avoid mismatches
        if (adapters.length != data.length) revert MISMATCH_LENGTH();

        emit SavedStrategy(adapters, data);
    }

    function saveDraft(address[] calldata adapters, bytes[] calldata data) external {
        // Ensure the lengths of the arrays are equal to avoid mismatches
        if (adapters.length != data.length) revert MISMATCH_LENGTH();

        emit SavedDraft(adapters, data);
    }
}