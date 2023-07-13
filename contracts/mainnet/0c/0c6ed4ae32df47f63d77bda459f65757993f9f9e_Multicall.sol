/**
 *Submitted for verification at Arbiscan on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multicall {
    /// Insufficient value for call (0xcf479181)
    /// @param balance current balance
    /// @param value value for call
    error InsufficientBalance(uint256 balance, uint256 value);
    /// Call reverted (0xbb206ea1)
    /// @param index call index
    /// @param data call raw revert reason
    error Revert(uint256 index, bytes data);

    enum Op {
        Call,
        DelegateCall
    }

    struct Call {
        Op op;
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
    ) external payable returns (uint256 gasUsed, Result[] memory results) {
        gasUsed = gasleft();
        results = new Result[](calls.length);
        for (uint i; i < calls.length; i++) {
            Call calldata call = calls[i];
            Result memory result = results[i];
            uint256 balance = address(this).balance;
            if (balance < call.value) {
                revert InsufficientBalance(balance, call.value);
            }
            if (call.op == Op.Call) {
                (result.success, result.data) = call.to.call{value: call.value}(
                    call.data
                );
            } else if (call.op == Op.DelegateCall) {
                (result.success, result.data) = call.to.delegatecall(call.data);
            }
            if (call.required && !result.success) {
                revert Revert(i, result.data);
            }
        }
        gasUsed -= gasleft();
    }
}