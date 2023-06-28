/**
 *Submitted for verification at Arbiscan on 2023-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multicall {
    /// Insufficient value for call
    /// @param balance current balance
    /// @param value value for call
    error InsufficientBalance(uint256 balance, uint256 value);
    /// Call reverted
    /// @param index call index
    /// @param data call raw revert reason
    error Revert(uint256 index, bytes data);

    struct Call {
        bool required;
        address to;
        uint256 value;
        bytes data;
    }

    struct Result {
        bool success;
        bytes data;
    }

    function multicall(
        Call[] calldata calls
    ) external payable returns (Result[] memory results) {
        results = new Result[](calls.length);
        for (uint i; i < calls.length; i++) {
            Call calldata call = calls[i];
            Result memory result = results[i];
            uint256 balance = address(this).balance;
            if (balance < call.value) {
                revert InsufficientBalance(balance, call.value);
            }
            (result.success, result.data) = call.to.call{value: call.value}(
                call.data
            );
            if (call.required && !result.success) {
                revert Revert(i, result.data);
            }
        }
    }
}