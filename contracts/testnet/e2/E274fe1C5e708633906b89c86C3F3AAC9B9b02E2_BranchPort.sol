// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
///
/// @dev Note:
/// This implementation does NOT auto-initialize the owner to `msg.sender`.
/// You MUST call the `_initializeOwner` in the constructor / initializer.
///
/// While the ownable portion follows
/// [EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
/// the nomenclature for the 2-step ownership handover may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    /// Override to return a different value if needed.
    /// Made internal to conserve bytecode. Wrap it in a public function if needed.
    function _ownershipHandoverValidFor() internal view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + _ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, 0x6f5e8818) // `NoHandoverRequest()`.
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for DoS protection.
/// - For ERC20s, this implementation won't check that a token has code,
///   responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.
    //
    // The regular variants:
    // - Forwards all remaining gas to the target.
    // - Reverts if the target reverts.
    // - Reverts if the current contract has insufficient balance.
    //
    // The force variants:
    // - Forwards with an optional gas stipend
    //   (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).
    // - If the target reverts, or if the gas stipend is exhausted,
    //   creates a temporary contract to force send the ETH via `SELFDESTRUCT`.
    //   Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.
    // - Reverts if the current contract has insufficient balance.
    //
    // The try variants:
    // - Forwards with a mandatory gas stipend.
    // - Instead of reverting, returns whether the transfer succeeded.

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`.
    function safeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer all the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function trySafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, 0x23b872dd) // `transferFrom(address,address,uint256)`.
            amount := mload(0x60) // The `amount` is already at 0x60. We'll need to return it.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, to) // Store the `to` argument.
            amount := mload(0x34) // The `amount` is already at 0x34. We'll need to return it.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, 0x00, 0x00)) // Reset the approval.
                mstore(0x34, amount) // Store back the original `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "lib/solady/src/auth/Ownable.sol";
import {SafeTransferLib} from "lib/solady/src/utils/SafeTransferLib.sol";

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

import {BridgeAgentConstants} from "./interfaces/BridgeAgentConstants.sol";
import {IBranchPort} from "./interfaces/IBranchPort.sol";
import {IPortStrategy} from "./interfaces/IPortStrategy.sol";

import {AddressCodeSize} from "./lib/AddressCodeSize.sol";

import {ERC20hToken} from "./token/ERC20hToken.sol";

/// @title Branch Port - Omnichain Token Management Contract
/// @author MaiaDAO
contract BranchPort is Ownable, IBranchPort, BridgeAgentConstants {
    using SafeTransferLib for address;
    using AddressCodeSize for address;

    /*///////////////////////////////////////////////////////////////
                        CORE ROUTER STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Local Core Branch Router Address.
    address public coreBranchRouterAddress;

    /*///////////////////////////////////////////////////////////////
                        BRIDGE AGENT STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Mapping from Underlying Address to isUnderlying (bool).
    mapping(address bridgeAgent => bool isActiveBridgeAgent) public isBridgeAgent;

    /// @notice Branch Routers deployed in branch chain.
    address[] public bridgeAgents;

    /*///////////////////////////////////////////////////////////////
                    BRIDGE AGENT FACTORIES STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Mapping from Underlying Address to isUnderlying (bool).
    mapping(address bridgeAgentFactory => bool isActiveBridgeAgentFactory) public isBridgeAgentFactory;

    /*///////////////////////////////////////////////////////////////
                        STRATEGY TOKENS STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Returns true if Strategy Token Address is active for usage in Port Strategies.
    mapping(address token => bool allowsStrategies) public isStrategyToken;

    /// @notice Returns a given token's total debt incurred by Port Strategies.
    mapping(address token => uint256 debt) public getStrategyTokenDebt;

    /// @notice Returns the minimum ratio of a given Strategy Token the Port should hold.
    mapping(address token => uint256 minimumReserveRatio) public getMinimumTokenReserveRatio;

    /*///////////////////////////////////////////////////////////////
                        PORT STRATEGIES STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Returns true if Port Strategy is allowed to manage a given Strategy Token.
    mapping(address strategy => mapping(address token => bool isActiveStrategy)) public isPortStrategy;

    /// @notice The amount of Strategy Token debt a given Port Strategy has.
    mapping(address strategy => mapping(address token => uint256 debt)) public getPortStrategyTokenDebt;

    /// @notice The last time a given Port Strategy managed a given Strategy Token.
    mapping(address strategy => mapping(address token => uint256 lastManaged)) public lastManaged;

    /// @notice The reserves ratio limit a given Port Strategy must wait before managing a Strategy Token.
    mapping(address strategy => mapping(address token => uint256 reserveRatioManagementLimit)) public
        strategyReserveRatioManagementLimit;

    /// @notice The time limit a given Port Strategy must wait before managing a Strategy Token.
    mapping(address strategy => mapping(address token => uint256 dailyLimitAmount)) public strategyDailyLimitAmount;

    /// @notice The amount of a Strategy Token a given Port Strategy can manage.
    mapping(address strategy => mapping(address token => uint256 dailyLimitRemaining)) public
        strategyDailyLimitRemaining;

    /*///////////////////////////////////////////////////////////////
                            REENTRANCY STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Reentrancy lock guard state.
    uint256 internal _unlocked = 1;

    /*///////////////////////////////////////////////////////////////
                            CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    uint256 internal constant DIVISIONER = 1e4;
    uint256 internal constant MIN_RESERVE_RATIO = 7e3;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for the Branch Port Contract.
     *   @param _owner Address of the Owner.
     */
    constructor(address _owner) {
        require(_owner != address(0), "Owner is zero address");
        _initializeOwner(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                        FALLBACK FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                        INITIALIZATION FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Branch Port.
     *   @param _coreBranchRouter Address of the Core Branch Router.
     *   @param _bridgeAgentFactory Address of the Bridge Agent Factory.
     */
    function initialize(address _coreBranchRouter, address _bridgeAgentFactory) external virtual onlyOwner {
        require(_coreBranchRouter != address(0), "CoreBranchRouter is zero address");
        require(_bridgeAgentFactory != address(0), "BridgeAgentFactory is zero address");
        renounceOwnership();

        coreBranchRouterAddress = _coreBranchRouter;
        isBridgeAgentFactory[_bridgeAgentFactory] = true;
    }

    /*///////////////////////////////////////////////////////////////
                        PORT STRATEGY FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchPort
    function manage(address _token, uint256 _amount) external override requiresPortStrategy(_token) {
        // Cache Strategy Token Global Debt
        uint256 _strategyTokenDebt = getStrategyTokenDebt[_token];
        uint256 _portStrategyTokenDebt = getPortStrategyTokenDebt[msg.sender][_token];

        // Check if request would surpass the tokens minimum reserves
        // Check if request would surpass the Port Strategy's reserve ratio management limit
        _enforceReservesLimit(_token, _amount, _strategyTokenDebt, _portStrategyTokenDebt);

        // Check if request would surpass the Port Strategy's daily limit
        _enforceTimeLimit(_token, _amount);

        // Update Strategy Token Global Debt
        getStrategyTokenDebt[_token] = _strategyTokenDebt + _amount;
        // Update Port Strategy Token Debt
        getPortStrategyTokenDebt[msg.sender][_token] = _portStrategyTokenDebt + _amount;

        // Transfer tokens to Port Strategy for management
        _token.safeTransfer(msg.sender, _amount);

        // Emit DebtCreated event
        emit DebtCreated(msg.sender, _token, _amount);
    }

    /// @inheritdoc IBranchPort
    function replenishReserves(address _token, uint256 _amount) external override lock {
        // Update Port Strategy Token Debt. Will underflow if not enough debt to repay.
        getPortStrategyTokenDebt[msg.sender][_token] -= _amount;

        // Update Strategy Token Global Debt. Will underflow if not enough debt to repay.
        getStrategyTokenDebt[_token] -= _amount;

        // Get current balance of _token
        uint256 currBalance = ERC20(_token).balanceOf(address(this));

        // Withdraw tokens from startegy
        IPortStrategy(msg.sender).withdraw(address(this), _token, _amount);

        // Check if _token balance has increased by _amount
        require(ERC20(_token).balanceOf(address(this)) - currBalance == _amount, "Port Strategy Withdraw Failed");

        // Emit DebtRepaid event
        emit DebtRepaid(msg.sender, _token, _amount);
    }

    /// @inheritdoc IBranchPort
    function replenishReserves(address _strategy, address _token) external override lock {
        // Cache Strategy Token Global Debt
        uint256 strategyTokenDebt = getStrategyTokenDebt[_token];

        // Get current balance of _token
        uint256 currBalance = ERC20(_token).balanceOf(address(this));

        // Get reserves lacking
        uint256 reservesLacking = _reservesLacking(_token, currBalance, strategyTokenDebt);

        // Cache Port Strategy Token Debt
        uint256 portStrategyTokenDebt = getPortStrategyTokenDebt[_strategy][_token];

        // Calculate amount to withdraw. The lesser of reserves lacking or Strategy Token Global Debt.
        uint256 amountToWithdraw = portStrategyTokenDebt < reservesLacking ? portStrategyTokenDebt : reservesLacking;

        // Update Port Strategy Token Debt
        getPortStrategyTokenDebt[_strategy][_token] = portStrategyTokenDebt - amountToWithdraw;
        // Update Strategy Token Global Debt
        getStrategyTokenDebt[_token] = strategyTokenDebt - amountToWithdraw;

        // Withdraw tokens from startegy
        IPortStrategy(_strategy).withdraw(address(this), _token, amountToWithdraw);

        // Check if _token balance has increased by _amount
        require(
            ERC20(_token).balanceOf(address(this)) - currBalance == amountToWithdraw, "Port Strategy Withdraw Failed"
        );

        // Emit DebtRepaid event
        emit DebtRepaid(_strategy, _token, amountToWithdraw);
    }

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchPort
    function withdraw(address _recipient, address _underlyingAddress, uint256 _deposit)
        public
        virtual
        override
        lock
        requiresBridgeAgent
    {
        _underlyingAddress.safeTransfer(_recipient, _deposit);
    }

    /// @inheritdoc IBranchPort
    function bridgeIn(address _recipient, address _localAddress, uint256 _amount)
        external
        override
        requiresBridgeAgent
    {
        _bridgeIn(_recipient, _localAddress, _amount);
    }

    /// @inheritdoc IBranchPort
    function bridgeInMultiple(
        address _recipient,
        address[] memory _localAddresses,
        address[] memory _underlyingAddresses,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) external override requiresBridgeAgent {
        // Cache Length
        uint256 length = _localAddresses.length;

        // Loop through token inputs
        for (uint256 i = 0; i < length;) {
            // Check if hTokens are being bridged in
            if (_amounts[i] - _deposits[i] > 0) {
                unchecked {
                    _bridgeIn(_recipient, _localAddresses[i], _amounts[i] - _deposits[i]);
                }
            }

            // Check if underlying tokens are being cleared
            if (_deposits[i] > 0) {
                withdraw(_recipient, _underlyingAddresses[i], _deposits[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IBranchPort
    function bridgeOut(
        address _depositor,
        address _localAddress,
        address _underlyingAddress,
        uint256 _amount,
        uint256 _deposit
    ) external override lock requiresBridgeAgent {
        _bridgeOut(_depositor, _localAddress, _underlyingAddress, _amount, _deposit);
    }

    /// @inheritdoc IBranchPort
    function bridgeOutMultiple(
        address _depositor,
        address[] memory _localAddresses,
        address[] memory _underlyingAddresses,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) external override lock requiresBridgeAgent {
        // Cache Length
        uint256 length = _localAddresses.length;

        // Sanity Check input arrays
        if (length > MAX_TOKENS_LENGTH) revert InvalidInputArrays();
        if (length != _underlyingAddresses.length) revert InvalidInputArrays();
        if (_underlyingAddresses.length != _amounts.length) revert InvalidInputArrays();
        if (_amounts.length != _deposits.length) revert InvalidInputArrays();

        // Loop through token inputs and bridge out
        for (uint256 i = 0; i < length;) {
            _bridgeOut(_depositor, _localAddresses[i], _underlyingAddresses[i], _amounts[i], _deposits[i]);

            unchecked {
                i++;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                    BRIDGE AGENT FACTORIES FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchPort
    function addBridgeAgent(address _bridgeAgent) external override requiresBridgeAgentFactory {
        if (isBridgeAgent[_bridgeAgent]) revert AlreadyAddedBridgeAgent();

        isBridgeAgent[_bridgeAgent] = true;
        bridgeAgents.push(_bridgeAgent);
    }

    /*///////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchPort
    function toggleBridgeAgentFactory(address _newBridgeAgentFactory) external override requiresCoreRouter {
        // Invert Bridge Agent Factory status
        isBridgeAgentFactory[_newBridgeAgentFactory] = !isBridgeAgentFactory[_newBridgeAgentFactory];

        emit BridgeAgentFactoryToggled(_newBridgeAgentFactory);
    }

    /// @inheritdoc IBranchPort
    function toggleStrategyToken(address _token, uint256 _minimumReservesRatio) external override requiresCoreRouter {
        // Check if token is already a strategy token
        if (isStrategyToken[_token]) {
            // If already added as a strategy token, remove it
            isStrategyToken[_token] = false;

            // Set minimumReservesRatio to 100% so all strategies can be forced to repay
            _setStrategyTokenMinimumReservesRatio(_token, DIVISIONER);

            // If not added as a strategy token
        } else {
            // Add token as a strategy token
            isStrategyToken[_token] = true;

            // Set minimumReservesRatio to _minimumReservesRatio
            _setStrategyTokenMinimumReservesRatio(_token, _minimumReservesRatio);
        }
    }

    /// @inheritdoc IBranchPort
    function updateStrategyToken(address _token, uint256 _minimumReservesRatio) external override requiresCoreRouter {
        // Check if token is already a strategy token
        if (!isStrategyToken[_token]) revert UnrecognizedStrategyToken();

        _setStrategyTokenMinimumReservesRatio(_token, _minimumReservesRatio);
    }

    function _setStrategyTokenMinimumReservesRatio(address _token, uint256 _minimumReservesRatio) internal {
        // Check if minimumReservesRatio is less or equal to 100%
        if (_minimumReservesRatio > DIVISIONER) {
            revert InvalidMinimumReservesRatio();
        }
        // Check if minimumReservesRatio is greater than or equal to 70%
        if (_minimumReservesRatio < MIN_RESERVE_RATIO) {
            revert InvalidMinimumReservesRatio();
        }

        // Set the Strategy Token's Minimum Reserves Ratio
        getMinimumTokenReserveRatio[_token] = _minimumReservesRatio;

        emit StrategyTokenUpdated(_token, _minimumReservesRatio);
    }

    /// @inheritdoc IBranchPort
    function togglePortStrategy(
        address _portStrategy,
        address _token,
        uint256 _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    ) external override requiresCoreRouter {
        // Check if token is already a strategy token
        if (isPortStrategy[_portStrategy][_token]) {
            // If already added as a strategy token, remove it
            isPortStrategy[_portStrategy][_token] = false;

            // Set minimumReservesRatio to 100% so all strategies can be forced to repay
            _setPortStrategySettings(_portStrategy, _token, 0, DIVISIONER);

            // If not added as a strategy token
        } else {
            if (!isStrategyToken[_token]) revert UnrecognizedStrategyToken();

            // Add token as a strategy token
            isPortStrategy[_portStrategy][_token] = true;

            // Set minimumReservesRatio to _minimumReservesRatio
            _setPortStrategySettings(_portStrategy, _token, _dailyManagementLimit, _reserveRatioManagementLimit);
        }
    }

    /// @inheritdoc IBranchPort
    function updatePortStrategy(
        address _portStrategy,
        address _token,
        uint256 _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    ) external override requiresCoreRouter {
        if (!isStrategyToken[_token]) revert UnrecognizedStrategyToken();
        if (!isPortStrategy[_portStrategy][_token]) revert UnrecognizedPortStrategy();

        _setPortStrategySettings(_portStrategy, _token, _dailyManagementLimit, _reserveRatioManagementLimit);
    }

    function _setPortStrategySettings(
        address _portStrategy,
        address _token,
        uint256 _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    ) internal {
        // Check if minimumReservesRatio is less or equal to 100%
        if (_reserveRatioManagementLimit > DIVISIONER) {
            revert InvalidMinimumReservesRatio();
        }
        // Check if minimumReservesRatio is greater than or equal to 70%
        if (_reserveRatioManagementLimit < MIN_RESERVE_RATIO) {
            revert InvalidMinimumReservesRatio();
        }

        // Set the Strategy Token's Minimum Reserves Ratio
        strategyDailyLimitAmount[_portStrategy][_token] = _dailyManagementLimit;
        // Set the Strategy Token's Maximum Reserves Ratio Management Limit
        strategyReserveRatioManagementLimit[_portStrategy][_token] = _reserveRatioManagementLimit;

        emit PortStrategyUpdated(_portStrategy, _token, _dailyManagementLimit, _reserveRatioManagementLimit);
    }

    /// @inheritdoc IBranchPort
    function setCoreBranchRouter(address _coreBranchRouter, address _coreBranchBridgeAgent)
        external
        override
        requiresCoreRouter
    {
        require(_coreBranchRouter != address(0), "New CoreRouter address is zero");
        require(_coreBranchBridgeAgent != address(0), "New Bridge Agent address is zero");
        coreBranchRouterAddress = _coreBranchRouter;
        isBridgeAgent[_coreBranchBridgeAgent] = true;
        bridgeAgents.push(_coreBranchBridgeAgent);

        emit CoreBranchSet(_coreBranchRouter, _coreBranchBridgeAgent);
    }

    /// @inheritdoc IBranchPort
    function sweep(address _recipient) external override requiresCoreRouter {
        // Safe Transfer All ETH
        _recipient.safeTransferAllETH();
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to check if a Port Strategy has reached its reserves management limit.
     *  @param _token Address of a given Strategy Token.
     *  @param _amount Amount of tokens to be bridged in.
     *  @param _strategyTokenDebt Total token debt incurred by a given Port Token.
     *  @param _portStrategyTokenDebt Total token debt incurred by a given Port Strategy for a Token.
     */
    function _enforceReservesLimit(
        address _token,
        uint256 _amount,
        uint256 _strategyTokenDebt,
        uint256 _portStrategyTokenDebt
    ) internal view {
        uint256 currBalance = ERC20(_token).balanceOf(address(this));
        uint256 totalTokenBalance = currBalance + _strategyTokenDebt;

        // Check if request would surpass the tokens minimum reserves
        if ((_amount + _minimumReserves(_token, totalTokenBalance)) > currBalance) {
            revert InsufficientReserves();
        }

        // Check if request would surpass the Port Strategy's reserve ratio management limit
        if ((_amount + _portStrategyTokenDebt) > _strategyReserveManagementLimit(_token, totalTokenBalance)) {
            revert ExceedsReserveRatioManagementLimit();
        }
    }

    /**
     * @notice Returns amount of Strategy Tokens needed to reach minimum reserves
     *  @param _token Address of a given Strategy Token.
     *  @param _currBalance Current balance of a given Strategy Token.
     *  @param _strategyTokenDebt Total token debt incurred by Port Strategies.
     *  @return uint256 excess reserves
     */
    function _reservesLacking(address _token, uint256 _currBalance, uint256 _strategyTokenDebt)
        internal
        view
        returns (uint256)
    {
        uint256 minReserves = _minimumReserves(_token, _currBalance + _strategyTokenDebt);

        unchecked {
            return _currBalance < minReserves ? minReserves - _currBalance : 0;
        }
    }

    /**
     * @notice Internal function to return the minimum amount of reserves of a given Strategy Token the Port should hold.
     *   @param _token Address of a given Strategy Token.
     *   @param _totalTokenBalance Total balance of a given Strategy Token.
     *   @return uint256 minimum reserves
     */
    function _minimumReserves(address _token, uint256 _totalTokenBalance) internal view returns (uint256) {
        return (_totalTokenBalance * getMinimumTokenReserveRatio[_token]) / DIVISIONER;
    }

    /**
     * @notice Internal function to return the maximum amount of reserves management limit.
     *   @param _token address being managed.
     *   @param _totalTokenBalance Total balance of a given Strategy Token.
     *   @return uint256 Maximum reserves amount management limit
     */
    function _strategyReserveManagementLimit(address _token, uint256 _totalTokenBalance)
        internal
        view
        returns (uint256)
    {
        return
            (_totalTokenBalance * (DIVISIONER - strategyReserveRatioManagementLimit[msg.sender][_token])) / DIVISIONER;
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to check and update the Port Strategy's daily management limit.
     *   @param _token address being managed.
     *   @param _amount of token being requested.
     */
    function _enforceTimeLimit(address _token, uint256 _amount) internal {
        uint256 dailyLimit = strategyDailyLimitRemaining[msg.sender][_token];
        if (block.timestamp - lastManaged[msg.sender][_token] >= 1 days) {
            dailyLimit = strategyDailyLimitAmount[msg.sender][_token];
            unchecked {
                lastManaged[msg.sender][_token] = (block.timestamp / 1 days) * 1 days;
            }
        }
        strategyDailyLimitRemaining[msg.sender][_token] = dailyLimit - _amount;
    }

    /**
     * @notice Internal function to bridge in hTokens.
     *   @param _recipient address of the recipient.
     *   @param _localAddress address of the hToken.
     *   @param _amount amount of hTokens to bridge in.
     */
    function _bridgeIn(address _recipient, address _localAddress, uint256 _amount) internal virtual {
        ERC20hToken(_localAddress).mint(_recipient, _amount);
    }

    /**
     * @notice Internal function to bridge out hTokens and underlying tokens.
     *   @param _depositor address of the depositor.
     *   @param _localAddress address of the hToken.
     *   @param _underlyingAddress address of the underlying token.
     *   @param _amount total amount of tokens to bridge out.
     *   @param _deposit amount of underlying tokens to bridge out.
     */
    function _bridgeOut(
        address _depositor,
        address _localAddress,
        address _underlyingAddress,
        uint256 _amount,
        uint256 _deposit
    ) internal virtual {
        // Check if hTokens are being bridged out
        if (_amount - _deposit > 0) {
            unchecked {
                ERC20hToken(_localAddress).burn(_depositor, _amount - _deposit);
            }
        }

        // Check if underlying tokens are being bridged out
        if (_deposit > 0) {
            // Check if underlying address is a contract
            if (_underlyingAddress.isEOA()) revert InvalidUnderlyingAddress();

            _underlyingAddress.safeTransferFrom(_depositor, address(this), _deposit);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Modifier that verifies msg sender is the Branch Chain's Core Root Router.
    modifier requiresCoreRouter() {
        if (msg.sender != coreBranchRouterAddress) revert UnrecognizedCore();
        _;
    }

    /// @notice Modifier that verifies msg sender is an active Bridge Agent.
    modifier requiresBridgeAgent() {
        if (!isBridgeAgent[msg.sender]) revert UnrecognizedBridgeAgent();
        _;
    }

    /// @notice Modifier that verifies msg sender is an active Bridge Agent Factory.
    modifier requiresBridgeAgentFactory() {
        if (!isBridgeAgentFactory[msg.sender]) revert UnrecognizedBridgeAgentFactory();
        _;
    }

    /// @notice Modifier that require msg sender to be an active Port Strategy
    modifier requiresPortStrategy(address _token) {
        if (!isStrategyToken[_token]) revert UnrecognizedStrategyToken();
        if (!isPortStrategy[msg.sender][_token]) revert UnrecognizedPortStrategy();
        _;
    }

    /// @notice Modifier for a simple re-entrancy check.
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  Bridge Agent Constants Contract
 * @author MaiaDAO
 * @notice Constants for use in Bridge Agent and Bridge Agent Executor contracts.
 * @dev    Used for encoding / decoding of the cross-chain messages and state management.
 */
contract BridgeAgentConstants {
    /*///////////////////////////////////////////////////////////////
             SETTLEMENT / DEPOSIT EXECUTION STATUS CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Indicates that a settlement or deposit is ready to be executed.
    uint8 internal constant STATUS_READY = 0;

    /// @notice Indicates that a settlement or deposit has been executed.
    uint8 internal constant STATUS_DONE = 1;

    /// @notice Indicates that a settlement or deposit has failed and can only be retrieved.
    uint8 internal constant STATUS_RETRIEVE = 2;

    /*///////////////////////////////////////////////////////////////
               SETTLEMENT / DEPOSIT REDEEM STATUS CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Indicates that the request for settlement or deposit was successful.
    uint8 internal constant STATUS_SUCCESS = 0;

    /// @notice Indicates that the request for settlement or deposit has failed.
    uint8 internal constant STATUS_FAILED = 1;

    /*///////////////////////////////////////////////////////////////
                      DEPOSIT SIGNATURE CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Indicates that the deposit has been signed.
    uint8 internal constant SIGNED_DEPOSIT = 1;

    /// @notice Indicates that the deposit has not been signed.
    uint8 internal constant UNSIGNED_DEPOSIT = 0;

    /*///////////////////////////////////////////////////////////////
            PAYLOAD ENCODING / DECODING POSITIONAL CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Defines the position in bytes where the payload starts after the flag byte.
    ///         Also used to offset number of assets in the payload.
    uint256 internal constant PARAMS_START = 1;

    /// @notice Defines the position in bytes where the signed payload starts after the flag byte and user address.
    uint256 internal constant PARAMS_START_SIGNED = 21;

    /// @notice Defines the position in bytes where token-related information starts, after flag byte and nonce.
    uint256 internal constant PARAMS_TKN_START = 5;

    /// @notice Defines the position in bytes where signed token-related information starts.
    /// @dev    After flag byte, user and nonce.
    uint256 internal constant PARAMS_TKN_START_SIGNED = 25;

    /// @notice Size in bytes for standard Ethereum types / slot size (like uint256).
    uint256 internal constant PARAMS_ENTRY_SIZE = 32;

    /// @notice Size in bytes for an Ethereum address.
    uint256 internal constant PARAMS_ADDRESS_SIZE = 20;

    /// @notice Size in bytes for a single set of packed token-related parameters (hToken, token, amount, deposit).
    uint256 internal constant PARAMS_TKN_SET_SIZE = 109;

    /// @notice Size in bytes for an entry of multiple-token-related parameters, taking padding into account.
    /// @dev    (hToken, token, amount, deposit)
    uint256 internal constant PARAMS_TKN_SET_SIZE_MULTIPLE = 128;

    /// @notice Offset in bytes to mark the end of the standard (deposit related) parameters in the payload.
    uint256 internal constant PARAMS_END_OFFSET = 6;

    /// @notice Offset in bytes to mark the end of the standard (deposit related) signed parameters in the payload.
    uint256 internal constant PARAMS_END_SIGNED_OFFSET = 26;

    /// @notice Offset in bytes to mark the end of the standard (settlement related) parameters in the payload.
    uint256 internal constant PARAMS_SETTLEMENT_OFFSET = 129;

    /*///////////////////////////////////////////////////////////////
                DEPOSIT / SETTLEMENT LIMITATION CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Maximum length of tokens allowed for deposit or settlement.
    uint256 internal constant MAX_TOKENS_LENGTH = 255;

    /*///////////////////////////////////////////////////////////////
                    MINIMUM EXECUTION GAS CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Minimum gas required to safely fail execution.
    uint256 internal constant BASE_EXECUTION_FAILED_GAS = 15_000;

    /// @notice Minimum gas required for a fallback request.
    uint256 internal constant BASE_FALLBACK_GAS = 140_000;

    //--------------------BRANCH: Deposit------------------------------

    /// @notice Minimum gas required for a callOut request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_GAS = 100_000;

    /// @notice Minimum gas required for a callOutDepositSingle request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_DEPOSIT_SINGLE_GAS = 150_000;

    /// @notice Minimum gas required for a callOutDepositMultiple request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_DEPOSIT_MULTIPLE_GAS = 200_000;

    /// @notice Minimum gas required for a callOut request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_SIGNED_GAS = 100_000;

    /// @notice Minimum gas required for a callOutDepositSingle request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_SINGLE_GAS = 150_000;

    /// @notice Minimum gas required for a callOutDepositMultiple request.
    uint256 internal constant BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_MULTIPLE_GAS = 200_000;

    //---------------------ROOT: Settlement----------------------------

    /// @notice Minimum gas required for a callOut request.
    uint256 internal constant ROOT_BASE_CALL_OUT_GAS = 100_000;

    /// @notice Minimum gas required for a callOutDepositSingle request.
    uint256 internal constant ROOT_BASE_CALL_OUT_SETTLEMENT_SINGLE_GAS = 150_000;

    /// @notice Minimum gas required for a callOutDepositMultiple request.
    uint256 internal constant ROOT_BASE_CALL_OUT_SETTLEMENT_MULTIPLE_GAS = 200_000;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title  Branch Port - Omnichain Token Management Contract
 * @author MaiaDAO
 * @notice Ulyses `Port` implementation for Branch Chain deployment. This contract is used to manage the deposit and
 *         withdrawal of underlying assets from the Branch Chain in response to Branch Bridge Agent requests.
 *         Manages Bridge Agents and their factories as well as the chain's strategies and their tokens.
 */
interface IBranchPort {
    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns true if the address is a Bridge Agent.
     *   @param _bridgeAgent Bridge Agent address.
     *   @return bool .
     */
    function isBridgeAgent(address _bridgeAgent) external view returns (bool);

    /**
     * @notice Returns true if the address is a Strategy Token.
     *   @param _token token address.
     *   @return bool.
     */
    function isStrategyToken(address _token) external view returns (bool);

    /**
     * @notice Returns true if the address is a Port Strategy.
     *   @param _strategy strategy address.
     *   @param _token token address.
     *   @return bool.
     */
    function isPortStrategy(address _strategy, address _token) external view returns (bool);

    /**
     * @notice Returns true if the address is a Bridge Agent Factory.
     *   @param _bridgeAgentFactory Bridge Agent Factory address.
     *   @return bool.
     */
    function isBridgeAgentFactory(address _bridgeAgentFactory) external view returns (bool);

    /*///////////////////////////////////////////////////////////////
                          PORT STRATEGY MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows active Port Strategy addresses to withdraw assets.
     *  @param _token token address.
     *  @param _amount amount of tokens.
     */
    function manage(address _token, uint256 _amount) external;

    /**
     * @notice allow strategy address to repay borrowed reserves with reserves.
     *  @param _amount amount of tokens to repay.
     *  @param _token address of the token to repay.
     *  @dev must be called by the port strategy itself.
     */
    function replenishReserves(address _token, uint256 _amount) external;

    /**
     * @notice allow anyone to request repayment of a strategy's reserves if Port is under minimum reserves ratio.
     *  @param _strategy address of the strategy to repay.
     *  @param _token address of the token to repay.
     *  @dev can be called by anyone to ensure availability of service.
     */
    function replenishReserves(address _strategy, address _token) external;

    /*///////////////////////////////////////////////////////////////
                          hTOKEN MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to withdraw underlying / native token amount from Port to Branch Bridge Agent.
     *   @param _recipient address of the underlying token receiver.
     *   @param _underlyingAddress underlying token address.
     *   @param _amount amount of tokens.
     *   @dev must be called by the bridge agent itself. Matches the burning of global hTokens in root chain.
     */
    function withdraw(address _recipient, address _underlyingAddress, uint256 _amount) external;

    /**
     * @notice Function to mint hToken amount to Branch Bridge Agent.
     *   @param _recipient address of the hToken receiver.
     *   @param _localAddress hToken address.
     *   @param _amount amount of hTokens.
     *   @dev must be called by the bridge agent itself. Matches the storage of global hTokens in root port.
     */
    function bridgeIn(address _recipient, address _localAddress, uint256 _amount) external;

    /**
     * @notice Function to withdraw underlying / native tokens and mint local hTokens to Branch Bridge Agent.
     *   @param _recipient address of the token receiver.
     *   @param _localAddresses local hToken addresses.
     *   @param _underlyingAddresses underlying token addresses.
     *   @param _amounts total amount of tokens.
     *   @param _deposits amount of underlying tokens.
     */
    function bridgeInMultiple(
        address _recipient,
        address[] memory _localAddresses,
        address[] memory _underlyingAddresses,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) external;

    /**
     * @notice Function to deposit underlying / native tokens in Port and burn hTokens.
     *   @param _depositor address of the token depositor.
     *   @param _localAddress local hToken addresses.
     *   @param _underlyingAddress underlying token addresses.
     *   @param _amount total amount of tokens.
     *   @param _deposit amount of underlying tokens.
     */
    function bridgeOut(
        address _depositor,
        address _localAddress,
        address _underlyingAddress,
        uint256 _amount,
        uint256 _deposit
    ) external;

    /**
     * @notice Setter function to decrease local hToken supply.
     *   @param _depositor address of the token depositor.
     *   @param _localAddresses local hToken addresses.
     *   @param _underlyingAddresses underlying token addresses.
     *   @param _amounts total amount of tokens.
     *   @param _deposits amount of underlying tokens.
     */
    function bridgeOutMultiple(
        address _depositor,
        address[] memory _localAddresses,
        address[] memory _underlyingAddresses,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) external;

    /*///////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a new bridge agent address to the branch port.
     *   @param _bridgeAgent address of the bridge agent to add to the Port
     */
    function addBridgeAgent(address _bridgeAgent) external;

    /**
     * @notice Toggle a given bridge agent factory. If it's active, it will de-activate it and vice-versa.
     *   @param _bridgeAgentFactory address of the bridge agent factory to add to the Port
     */
    function toggleBridgeAgentFactory(address _bridgeAgentFactory) external;

    /**
     * @notice Toggle a given strategy token. If it's active, it will de-activate it and vice-versa.
     * @param _token address of the token to add to the Strategy Tokens
     * @param _minimumReservesRatio minimum reserves ratio for the token
     * @dev Must be between 7000 and 10000 (70% and 100%). Can be any value if the token is being de-activated.
     */
    function toggleStrategyToken(address _token, uint256 _minimumReservesRatio) external;

    /**
     * @notice Update an active strategy token's minimum reserves ratio. If it is not active, it will revert.
     * @param _token address of the token to add to the Strategy Tokens
     * @param _minimumReservesRatio minimum reserves ratio for the token
     * @dev Must be between 7000 and 10000 (70% and 100%). Can be any value if the token is being de-activated.
     */
    function updateStrategyToken(address _token, uint256 _minimumReservesRatio) external;

    /**
     * @notice Add or Remove a Port Strategy.
     * @param _portStrategy Address of the Port Strategy to be added for use in Branch strategies.
     * @param _underlyingToken Address of the underlying token to be added for use in Branch strategies.
     * @param _dailyManagementLimit Daily management limit of the given token for the Port Strategy.
     * @param _reserveRatioManagementLimit Total reserves management limit of the given token for the Port Strategy.
     * @dev Must be between 7000 and 10000 (70% and 100%). Can be any value if the token is being de-activated.
     */
    function togglePortStrategy(
        address _portStrategy,
        address _underlyingToken,
        uint256 _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    ) external;

    /**
     * @notice Updates a Port Strategy.
     * @param _portStrategy Address of the Port Strategy to be added for use in Branch strategies.
     * @param _underlyingToken Address of the underlying token to be added for use in Branch strategies.
     * @param _dailyManagementLimit Daily management limit of the given token for the Port Strategy.
     * @param _reserveRatioManagementLimit Total reserves management limit of the given token for the Port Strategy.
     * @dev Must be between 7000 and 10000 (70% and 100%). Can be any value if the token is being de-activated.
     */
    function updatePortStrategy(
        address _portStrategy,
        address _underlyingToken,
        uint256 _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    ) external;

    /**
     * @notice Sets the core branch router and bridge agent for the branch port.
     *   @param _coreBranchRouter address of the new core branch router
     *   @param _coreBranchBridgeAgent address of the new core branch bridge agent
     */
    function setCoreBranchRouter(address _coreBranchRouter, address _coreBranchBridgeAgent) external;

    /**
     * @notice Allows governance to claim any native tokens accumulated from failed transactions.
     *  @param _recipient address to transfer ETH to.
     */
    function sweep(address _recipient) external;

    /*///////////////////////////////////////////////////////////////
                            EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when a Port Strategy manages more reserves increasing its debt for a given token.
    event DebtCreated(address indexed _strategy, address indexed _token, uint256 _amount);
    /// @notice Event emitted when a Port Strategy replenishes reserves decreasing its debt for a given token.
    event DebtRepaid(address indexed _strategy, address indexed _token, uint256 _amount);

    /// @notice Event emitted when Strategy Token has its details updated.
    event StrategyTokenUpdated(address indexed _token, uint256 indexed _minimumReservesRatio);

    /// @notice Event emitted when a Port Strategy has its details updated.
    event PortStrategyUpdated(
        address indexed _portStrategy,
        address indexed _token,
        uint256 indexed _dailyManagementLimit,
        uint256 _reserveRatioManagementLimit
    );

    /// @notice Event emitted when a Branch Bridge Agent Factory is toggled on or off.
    event BridgeAgentFactoryToggled(address indexed _bridgeAgentFactory);

    /// @notice Event emitted when a Bridge Agent is toggled on or off.
    event BridgeAgentToggled(address indexed _bridgeAgent);

    /// @notice Event emitted when a Core Branch Router and Bridge Agent are set.
    event CoreBranchSet(address indexed _coreBranchRouter, address indexed _coreBranchBridgeAgent);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Error emitted when Bridge Agent is already added.
    error AlreadyAddedBridgeAgent();

    /// @notice Error emitted when Port Strategy request would exceed the Branch Port's minimum reserves.
    error InsufficientReserves();

    /// @notice Error emitted when Port Strategy request would exceed it's reserve ratio management limit.
    error ExceedsReserveRatioManagementLimit();

    /// @notice Error emitted when minimum reserves ratio is set too low.
    error InvalidMinimumReservesRatio();
    /// @notice Error emitted when token deposit arrays have different lengths.
    error InvalidInputArrays();
    /// @notice Error emitted when an invalid underlying token address is provided.
    error InvalidUnderlyingAddress();

    /// @notice Error emitted when caller is not the Core Branch Router.
    error UnrecognizedCore();
    /// @notice Error emitted when caller is not an active Branch Bridge Agent.
    error UnrecognizedBridgeAgent();
    /// @notice Error emitted when caller is not an active Branch Bridge Agent Factory.
    error UnrecognizedBridgeAgentFactory();
    /// @notice Error emitted when caller is not an active Port Strategy.
    error UnrecognizedPortStrategy();
    /// @notice Error emitted when caller is not an active Strategy Token.
    error UnrecognizedStrategyToken();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  ERC20 hToken Branch Contract
 * @author MaiaDAO.
 * @notice ERC20 hToken contract deployed with the Ulysses Omnichain Liquidity System.
 *         ERC20 representation of a token deposited in a  Branch Chain's Port.
 * @dev    If this is a root hToken, this asset is minted / burned in reflection of it's origin Branch Port balance.
 *         Should not be burned being stored in Root Port instead if Branch hToken mint is requested.
 */
interface IERC20hToken {
    /*///////////////////////////////////////////////////////////////
                                ERC20 LOGIC
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to mint tokens.
     * @param account Address of the account to receive the tokens.
     * @param amount Amount of tokens to be minted.
     */
    function mint(address account, uint256 amount) external;

    /**
     * @notice Function to burn tokens.
     * @param account Address of the account to burn the tokens from.
     * @param amount Amount of tokens to be burned.
     */
    function burn(address account, uint256 amount) external;

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Error thrown when the Port Address is the zero address.
    error InvalidPortAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title  Port Strategy Interface
 * @author MaiaDAO
 * @notice Interface to be implemented by Brach Port Strategy contracts
 *         allowlisted by the chain's Branch Port to manage a limited amount
 *         of one or more Strategy Tokens.
 */
interface IPortStrategy {
    /*///////////////////////////////////////////////////////////////
                          TOKEN MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to withdraw underlying/native token amount back into Branch Port.
     *   @param _recipient hToken receiver.
     *   @param _token native token address.
     *   @param _amount amount of tokens.
     */
    function withdraw(address _recipient, address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  Address Code Size Library
 * @notice Library for checking the size of a contract's code.
 * @dev    Used for checking if an address is a contract or an EOA.
 */
library AddressCodeSize {
    /*///////////////////////////////////////////////////////////////
                   PAYLOAD DECODING POSITIONAL CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly ("memory-safe") {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function isEOA(address addr) internal view returns (bool) {
        uint256 size;
        assembly ("memory-safe") {
            size := extcodesize(addr)
        }
        return size == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "lib/solady/src/auth/Ownable.sol";

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

import {IERC20hToken} from "../interfaces/IERC20hToken.sol";

/// @title ERC20 hToken Contract
/// @author MaiaDAO
contract ERC20hToken is ERC20, Ownable, IERC20hToken {
    /**
     * @notice Constructor for the ERC20hToken branch or root Contract.
     *   @param _localPortAddress Address of the local Branch or Root Port Contract.
     *   @param _name Name of the Token.
     *   @param _symbol Symbol of the Token.
     *   @param _decimals Decimals of the Token.
     */
    constructor(address _localPortAddress, string memory _name, string memory _symbol, uint8 _decimals)
        ERC20(_name, _symbol, _decimals)
    {
        if (_localPortAddress == address(0)) revert InvalidPortAddress();
        _initializeOwner(_localPortAddress);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC20 LOGIC
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC20hToken
    function mint(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    /// @inheritdoc IERC20hToken
    function burn(address account, uint256 amount) public override onlyOwner {
        _burn(account, amount);
    }
}