// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract RelayReceiver {
    // --- Structs ---

    struct Call {
        address to;
        bytes data;
        uint256 value;
    }

    // --- Errors ---

    error CallFailed();
    error NativeTransferFailed();
    error Unauthorized();

    // --- Events ---

    event FundsForwardedWithData(bytes data);

    // --- Fields ---

    address private immutable SOLVER;

    // --- Constructor ---

    constructor(address solver) {
        SOLVER = solver;
    }

    // --- Public methods ---

    fallback() external payable {
        send(SOLVER, msg.value);
        emit FundsForwardedWithData(msg.data);
    }

    function forward(bytes calldata data) external payable {
        send(SOLVER, msg.value);
        emit FundsForwardedWithData(data);
    }

    // --- Restricted methods ---

    function makeCalls(Call[] calldata calls) external payable {
        if (msg.sender != SOLVER) {
            revert Unauthorized();
        }

        unchecked {
            uint256 length = calls.length;
            for (uint256 i; i < length; i++) {
                Call memory c = calls[i];

                (bool success, ) = c.to.call{value: c.value}(c.data);
                if (!success) {
                    revert CallFailed();
                }
            }
        }
    }

    // --- Internal methods ---

    function send(address to, uint256 value) internal {
        bool success;
        assembly {
            // Save gas by avoiding copying the return data to memory.
            // Provide at most 100k gas to the internal call, which is
            // more than enough to cover common use-cases of logic for
            // receiving native tokens (eg. SCW payable fallbacks).
            success := call(100000, to, value, 0, 0, 0, 0)
        }

        if (!success) {
            revert NativeTransferFailed();
        }
    }
}