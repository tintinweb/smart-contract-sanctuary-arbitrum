// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    internal
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeTransferLib} from "lib/solady/src/utils/SafeTransferLib.sol";

import {ExcessivelySafeCall} from "lib/ExcessivelySafeCall.sol";

import {BridgeAgentConstants} from "./interfaces/BridgeAgentConstants.sol";
import {
    Deposit,
    DepositInput,
    DepositMultipleInput,
    GasParams,
    IBranchBridgeAgent,
    ILayerZeroReceiver,
    SettlementMultipleParams
} from "./interfaces/IBranchBridgeAgent.sol";
import {IBranchPort as IPort} from "./interfaces/IBranchPort.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";

import {DecodeBridgeInMultipleParams} from "./lib/DecodeBridgeInMultipleParams.sol";

import {BranchBridgeAgentExecutor, DeployBranchBridgeAgentExecutor} from "./BranchBridgeAgentExecutor.sol";

/// @title Library for Branch Bridge Agent Deployment
library DeployBranchBridgeAgent {
    function deploy(
        uint16 _rootChainId,
        uint16 _localChainId,
        address _rootBridgeAgentAddress,
        address _lzEndpointAddress,
        address _localRouterAddress,
        address _localPortAddress
    ) external returns (BranchBridgeAgent) {
        return new BranchBridgeAgent(
            _rootChainId,
            _localChainId,
            _rootBridgeAgentAddress,
            _lzEndpointAddress,
            _localRouterAddress,
            _localPortAddress
        );
    }
}

/// @title Branch Bridge Agent Contract
/// @author MaiaDAO
contract BranchBridgeAgent is IBranchBridgeAgent, BridgeAgentConstants {
    using ExcessivelySafeCall for address;
    using SafeTransferLib for address;
    using DecodeBridgeInMultipleParams for bytes;

    /*///////////////////////////////////////////////////////////////
                         BRIDGE AGENT STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Chain Id for Root Chain where liquidity is virtualized(e.g. 4).
    uint16 public immutable rootChainId;

    /// @notice Chain Id for Local Chain.
    uint16 public immutable localChainId;

    /// @notice Address for Bridge Agent who processes requests submitted for the Root Router Address
    ///         where cross-chain requests are executed in the Root Chain.
    address public immutable rootBridgeAgentAddress;

    /// @notice Layer Zero messaging layer path for Root Bridge Agent Address where cross-chain requests
    ///         are sent to the Root Chain Router.
    bytes private rootBridgeAgentPath;

    /// @notice Local Layerzero Endpoint Address where cross-chain requests are sent to the Root Chain Router.
    address public immutable lzEndpointAddress;

    /// @notice Address for Local Router used for custom actions for different hApps.
    address public immutable localRouterAddress;

    /// @notice Address for Local Port Address
    ///         where funds deposited from this chain are kept, managed and supplied to different Port Strategies.
    address public immutable localPortAddress;

    /// @notice Address for Bridge Agent Executor used for executing cross-chain requests.
    address public immutable bridgeAgentExecutorAddress;

    /*///////////////////////////////////////////////////////////////
                            DEPOSITS STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Deposit nonce used for identifying the transaction.
    uint32 public depositNonce;

    /// @notice Mapping from Pending deposits hash to Deposit Struct.
    mapping(uint256 depositNonce => Deposit depositInfo) public getDeposit;

    /*///////////////////////////////////////////////////////////////
                        SETTLEMENT EXECUTION STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice If true, the bridge agent has already served a request with this nonce from a given chain.
    mapping(uint256 settlementNonce => uint256 state) public executionState;

    /*///////////////////////////////////////////////////////////////
                           REENTRANCY STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Re-entrancy lock modifier state.
    uint256 internal _unlocked = 1;

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Branch Bridge Agent.
     * @param _rootChainId Chain Id for Root Chain where liquidity is virtualized and assets are managed.
     * @param _localChainId Chain Id for Local Chain.
     * @param _rootBridgeAgentAddress Address for Bridge Agent who processes requests sent to and from the Root Chain.
     * @param _lzEndpointAddress Local Layerzero Endpoint Address where cross-chain requests are sent to the Root Chain Router.
     * @param _localRouterAddress Address for Local Router used for custom actions for different Omnichain dApps.
     * @param _localPortAddress Address for Local Port Address where funds deposited from this chain are kept, managed
     *                          and supplied to different Port Strategies.
     */
    constructor(
        uint16 _rootChainId,
        uint16 _localChainId,
        address _rootBridgeAgentAddress,
        address _lzEndpointAddress,
        address _localRouterAddress,
        address _localPortAddress
    ) {
        if (_rootBridgeAgentAddress == address(0)) revert InvalidRootBridgeAgentAddress();
        if (_localPortAddress == address(0)) revert InvalidBranchPortAddress();
        if (_lzEndpointAddress == address(0)) if (_rootChainId != _localChainId) revert InvalidEndpointAddress();

        localChainId = _localChainId;
        rootChainId = _rootChainId;
        rootBridgeAgentAddress = _rootBridgeAgentAddress;
        lzEndpointAddress = _lzEndpointAddress;
        // Can be zero address
        localRouterAddress = _localRouterAddress;
        localPortAddress = _localPortAddress;
        bridgeAgentExecutorAddress = DeployBranchBridgeAgentExecutor.deploy(_localRouterAddress);
        depositNonce = 1;

        rootBridgeAgentPath = abi.encodePacked(_rootBridgeAgentAddress, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                        FALLBACK FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function getDepositEntry(uint32 _depositNonce) external view override returns (Deposit memory) {
        return getDeposit[_depositNonce];
    }

    /*///////////////////////////////////////////////////////////////
                    USER / BRANCH ROUTER EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function callOut(address payable _depositOwnerAndGasRefundee, bytes calldata _params, GasParams calldata _gParams)
        external
        payable
        override
        lock
        requiresRouter
    {
        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(bytes1(0x01), depositNonce++, _params);

        //Perform Call
        _performCall(_depositOwnerAndGasRefundee, payload, _gParams, BRANCH_BASE_CALL_OUT_GAS);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutAndBridge(
        address payable _depositOwnerAndGasRefundee,
        bytes calldata _params,
        DepositInput memory _dParams,
        GasParams calldata _gParams
    ) external payable override lock requiresRouter {
        //Cache Deposit Nonce
        uint32 _depositNonce = depositNonce;

        //Create Deposit and Send Cross-Chain request
        _createDeposit(
            false,
            _depositNonce,
            _depositOwnerAndGasRefundee,
            _dParams.hToken,
            _dParams.token,
            _dParams.amount,
            _dParams.deposit
        );

        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(
            bytes1(0x02), _depositNonce, _dParams.hToken, _dParams.token, _dParams.amount, _dParams.deposit, _params
        );

        //Perform Call
        _performCall(_depositOwnerAndGasRefundee, payload, _gParams, BRANCH_BASE_CALL_OUT_DEPOSIT_SINGLE_GAS);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutAndBridgeMultiple(
        address payable _depositOwnerAndGasRefundee,
        bytes calldata _params,
        DepositMultipleInput memory _dParams,
        GasParams calldata _gParams
    ) external payable override lock requiresRouter {
        //Cache Deposit Nonce
        uint32 _depositNonce = depositNonce;

        //Create Deposit and Send Cross-Chain request
        _createDepositMultiple(
            false,
            _depositNonce,
            _depositOwnerAndGasRefundee,
            _dParams.hTokens,
            _dParams.tokens,
            _dParams.amounts,
            _dParams.deposits
        );

        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(
            bytes1(0x03),
            uint8(_dParams.hTokens.length),
            _depositNonce,
            _dParams.hTokens,
            _dParams.tokens,
            _dParams.amounts,
            _dParams.deposits,
            _params
        );

        //Perform Call
        _performCall(_depositOwnerAndGasRefundee, payload, _gParams, BRANCH_BASE_CALL_OUT_DEPOSIT_MULTIPLE_GAS);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutSigned(bytes calldata _params, GasParams calldata _gParams) external payable override lock {
        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(bytes1(0x04), msg.sender, depositNonce++, _params);

        //Perform Signed Call without deposit
        _performCall(payable(msg.sender), payload, _gParams, BRANCH_BASE_CALL_OUT_SIGNED_GAS);
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutSignedAndBridge(
        bytes calldata _params,
        DepositInput memory _dParams,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override lock {
        //Cache Deposit Nonce
        uint32 _depositNonce = depositNonce;

        //Create Deposit and Send Cross-Chain request
        _createDeposit(
            true, _depositNonce, msg.sender, _dParams.hToken, _dParams.token, _dParams.amount, _dParams.deposit
        );

        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(
            _hasFallbackToggled ? bytes1(0x85) : bytes1(0x05),
            msg.sender,
            _depositNonce,
            _dParams.hToken,
            _dParams.token,
            _dParams.amount,
            _dParams.deposit,
            _params
        );

        //Perform Call
        _performCall(
            payable(msg.sender),
            payload,
            _gParams,
            _hasFallbackToggled
                ? BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_SINGLE_GAS + BASE_FALLBACK_GAS
                : BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_SINGLE_GAS
        );
    }

    /// @inheritdoc IBranchBridgeAgent
    function callOutSignedAndBridgeMultiple(
        bytes calldata _params,
        DepositMultipleInput memory _dParams,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override lock {
        // Cache Deposit Nonce
        uint32 _depositNonce = depositNonce;

        // Create a Deposit and Send Cross-Chain request
        _createDepositMultiple(
            true, _depositNonce, msg.sender, _dParams.hTokens, _dParams.tokens, _dParams.amounts, _dParams.deposits
        );

        // Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(
            _hasFallbackToggled ? bytes1(0x86) : bytes1(0x06),
            msg.sender,
            uint8(_dParams.hTokens.length),
            _depositNonce,
            _dParams.hTokens,
            _dParams.tokens,
            _dParams.amounts,
            _dParams.deposits,
            _params
        );

        //Perform Call
        _performCall(
            payable(msg.sender),
            payload,
            _gParams,
            _hasFallbackToggled
                ? BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_MULTIPLE_GAS + BASE_FALLBACK_GAS
                : BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_MULTIPLE_GAS
        );
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function retryDeposit(address _owner, uint32 _depositNonce, bytes calldata _params, GasParams calldata _gParams)
        external
        payable
        override
        lock
        requiresRouter
    {
        // Get Settlement Reference
        Deposit storage deposit = getDeposit[_depositNonce];

        // Check if deposit is not signed
        if (deposit.isSigned == SIGNED_DEPOSIT) revert NotDepositOwner();

        // Check if deposit belongs to message sender
        if (deposit.owner != _owner) revert NotDepositOwner();

        // Check if deposit is not failed and in redeem mode
        if (deposit.status == STATUS_FAILED) revert DepositAlreadyRetrieved();

        // Pack data for deposit single
        if (uint8(deposit.hTokens.length) == 1) {
            // Encode Data for cross-chain call.
            bytes memory payload = abi.encodePacked(
                bytes1(0x02),
                _depositNonce,
                deposit.hTokens[0],
                deposit.tokens[0],
                deposit.amounts[0],
                deposit.deposits[0],
                _params
            );

            // Validate and perform call
            _retryDeposit(payload, _gParams, BRANCH_BASE_CALL_OUT_DEPOSIT_SINGLE_GAS);

            // Pack data for deposit multiple
        } else if (uint8(deposit.hTokens.length) > 1) {
            // Encode Data for cross-chain call.
            bytes memory payload = abi.encodePacked(
                bytes1(0x03),
                uint8(deposit.hTokens.length),
                _depositNonce,
                deposit.hTokens,
                deposit.tokens,
                deposit.amounts,
                deposit.deposits,
                _params
            );

            // Validate and perform call
            _retryDeposit(payload, _gParams, BRANCH_BASE_CALL_OUT_DEPOSIT_MULTIPLE_GAS);
        }
    }

    /// @inheritdoc IBranchBridgeAgent
    function retryDepositSigned(
        uint32 _depositNonce,
        bytes calldata _params,
        GasParams calldata _gParams,
        bool _hasFallbackToggled
    ) external payable override lock {
        // Get Settlement Reference
        Deposit storage deposit = getDeposit[_depositNonce];

        // Check if deposit is signed
        if (deposit.isSigned == UNSIGNED_DEPOSIT) revert NotDepositOwner();

        // Check if deposit belongs to message sender
        if (deposit.owner != msg.sender) revert NotDepositOwner();

        // Check if deposit is not failed and in redeem mode
        if (deposit.status == STATUS_FAILED) revert DepositRedeemUnavailable();

        // Pack data for deposit single
        if (uint8(deposit.hTokens.length) == 1) {
            // Encode Data for cross-chain call.
            bytes memory payload = abi.encodePacked(
                _hasFallbackToggled ? bytes1(0x85) : bytes1(0x05),
                msg.sender,
                _depositNonce,
                deposit.hTokens[0],
                deposit.tokens[0],
                deposit.amounts[0],
                deposit.deposits[0],
                _params
            );

            // Validate and perform call
            _retryDeposit(
                payload,
                _gParams,
                _hasFallbackToggled
                    ? BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_SINGLE_GAS + BASE_FALLBACK_GAS
                    : BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_SINGLE_GAS
            );

            // Pack data for deposit multiple
        } else if (uint8(deposit.hTokens.length) > 1) {
            // Encode Data for cross-chain call.
            bytes memory payload = abi.encodePacked(
                _hasFallbackToggled ? bytes1(0x86) : bytes1(0x06),
                msg.sender,
                uint8(deposit.hTokens.length),
                _depositNonce,
                deposit.hTokens,
                deposit.tokens,
                deposit.amounts,
                deposit.deposits,
                _params
            );

            // Validate and perform call
            _retryDeposit(
                payload,
                _gParams,
                _hasFallbackToggled
                    ? BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_MULTIPLE_GAS + BASE_FALLBACK_GAS
                    : BRANCH_BASE_CALL_OUT_SIGNED_DEPOSIT_MULTIPLE_GAS
            );
        }
    }

    /// @inheritdoc IBranchBridgeAgent
    function retrieveDeposit(uint32 _depositNonce, GasParams calldata _gParams) external payable override lock {
        // Check if the deposit belongs to the message sender
        if (getDeposit[_depositNonce].owner != msg.sender) revert NotDepositOwner();

        // Check if deposit is not already failed and in redeem mode.
        if (getDeposit[_depositNonce].status == STATUS_FAILED) revert DepositAlreadyRetrieved();

        //Encode Data for cross-chain call.
        bytes memory payload = abi.encodePacked(bytes1(0x08), msg.sender, _depositNonce);

        //Update State and Perform Call
        _performCall(payable(msg.sender), payload, _gParams, BRANCH_BASE_CALL_OUT_GAS);
    }

    /// @inheritdoc IBranchBridgeAgent
    function redeemDeposit(uint32 _depositNonce, address _recipient) external override lock {
        // Get storage reference
        Deposit storage deposit = getDeposit[_depositNonce];

        // Check Deposit
        if (deposit.status == STATUS_SUCCESS) revert DepositRedeemUnavailable();
        if (deposit.owner == address(0)) revert DepositRedeemUnavailable();
        if (deposit.owner != msg.sender) revert NotDepositOwner();

        // Zero out owner
        deposit.owner = address(0);

        // Transfer token to depositor / user
        for (uint256 i = 0; i < deposit.tokens.length;) {
            //Increment tokens clearance counter if address is zero
            if (deposit.hTokens[i] != address(0)) {
                _clearToken(_recipient, deposit.hTokens[i], deposit.tokens[i], deposit.amounts[i], deposit.deposits[i]);
            }

            unchecked {
                ++i;
            }
        }

        // Delete Failed Deposit Token Info
        delete getDeposit[_depositNonce];
    }

    /// @inheritdoc IBranchBridgeAgent
    function redeemDeposit(uint32 _depositNonce, address _recipient, address _localTokenAddress)
        external
        override
        lock
    {
        // Check localTokenAddress not zero
        if (_localTokenAddress == address(0)) revert InvalidLocalAddress();

        // Get storage reference
        Deposit storage deposit = getDeposit[_depositNonce];

        // Check Deposit
        if (deposit.status == STATUS_SUCCESS) revert DepositRedeemUnavailable();
        if (deposit.owner == address(0)) revert DepositRedeemUnavailable();
        if (deposit.owner != msg.sender) revert NotDepositOwner();

        // Clearance counter
        uint256 tokensCleared;

        // Cache Length
        uint256 length = deposit.tokens.length;

        // Transfer token to depositor / user
        for (uint256 i = 0; i < length;) {
            // Check if hToken is the same as localTokenAddress
            if (deposit.hTokens[i] == _localTokenAddress) {
                // Clear Tokens back to user
                _clearToken(_recipient, deposit.hTokens[i], deposit.tokens[i], deposit.amounts[i], deposit.deposits[i]);

                // Remove Token Related Info from Deposit Storage
                delete deposit.hTokens[i];
                delete deposit.tokens[i];
                delete deposit.amounts[i];
                delete deposit.deposits[i];
            }

            //Increment tokens clearance counter if address is zero
            if (deposit.hTokens[i] == address(0)) {
                unchecked {
                    ++tokensCleared;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Check if all tokens have been cleared and Delete Failed Deposit Token Info
        if (tokensCleared == length) delete getDeposit[_depositNonce];
    }

    /*///////////////////////////////////////////////////////////////
                    SETTLEMENT EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function retrySettlement(
        uint32 _settlementNonce,
        bytes calldata _params,
        GasParams[2] calldata _gParams,
        bool _hasFallbackToggled
    ) external payable virtual override lock {
        // Encode Retry Settlement Params
        bytes memory params = abi.encode(_settlementNonce, msg.sender, _params, _gParams[1]);

        // Prepare payload for cross-chain call.
        bytes memory payload = abi.encodePacked(_hasFallbackToggled ? bytes1(0x87) : bytes1(0x07), params);

        // Perform Call
        _performCall(payable(msg.sender), payload, _gParams[0], BRANCH_BASE_CALL_OUT_GAS);
    }

    /*///////////////////////////////////////////////////////////////
                TOKEN MANAGEMENT EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBranchBridgeAgent
    function bridgeIn(address _recipient, address _hToken, address _token, uint256 _amount, uint256 _deposit)
        external
        override
        requiresAgentExecutor
    {
        _clearToken(_recipient, _hToken, _token, _amount, _deposit);
    }

    /// @inheritdoc IBranchBridgeAgent
    function bridgeInMultiple(address _recipient, SettlementMultipleParams calldata _sParams)
        external
        override
        requiresAgentExecutor
    {
        IPort(localPortAddress).bridgeInMultiple(
            _recipient, _sParams.hTokens, _sParams.tokens, _sParams.amounts, _sParams.deposits
        );
    }

    /*///////////////////////////////////////////////////////////////
                    LAYER ZERO EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc ILayerZeroReceiver
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64, bytes calldata _payload)
        public
        payable
        override
        returns (bool success)
    {
        // Perform Excessively Safe Call
        (success,) = address(this).excessivelySafeCall(
            gasleft() - BASE_EXECUTION_FAILED_GAS,
            0,
            abi.encodeWithSelector(this.lzReceiveNonBlocking.selector, msg.sender, _srcChainId, _srcAddress, _payload)
        );

        // Check if call was successful if not send any native tokens to rootPort
        if (!success) localPortAddress.safeTransferAllETH();
    }

    /// @inheritdoc ILayerZeroReceiver
    function lzReceiveNonBlocking(
        address _endpoint,
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) public payable override requiresEndpoint(_srcChainId, _endpoint, _srcAddress) {
        //Save Action Flag
        bytes1 flag = _payload[0];

        // Save settlement nonce
        uint32 nonce;

        // DEPOSIT FLAG: 1 (No settlement)
        if (flag == 0x01) {
            // Get Settlement Nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED]));

            //Check if tx has already been executed
            if (executionState[nonce] != STATUS_READY) revert AlreadyExecutedTransaction();

            // Try to execute the remote request
            // Flag 0 - BranchBridgeAgentExecutor(bridgeAgentExecutorAddress).executeNoSettlement(_payload)
            _execute(nonce, abi.encodeWithSelector(BranchBridgeAgentExecutor.executeNoSettlement.selector, _payload));

            // DEPOSIT FLAG: 2 (Single Asset Settlement)
        } else if (flag & 0x7F == 0x02) {
            // Parse recipient
            address payable recipient = payable(address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED]))));

            // Parse Settlement Nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED]));

            // Check if tx has already been executed
            if (executionState[nonce] != STATUS_READY) revert AlreadyExecutedTransaction();

            // Try to execute the remote request
            // Flag 1 - BranchBridgeAgentExecutor(bridgeAgentExecutorAddress).executeWithSettlement(recipient, _payload)
            _execute(
                flag == 0x82,
                nonce,
                recipient,
                abi.encodeWithSelector(BranchBridgeAgentExecutor.executeWithSettlement.selector, recipient, _payload)
            );

            // DEPOSIT FLAG: 3 (Multiple Settlement)
        } else if (flag & 0x7F == 0x03) {
            // Parse recipient
            address payable recipient = payable(address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED]))));

            // Parse deposit nonce
            nonce = uint32(bytes4(_payload[22:26]));

            //Check if tx has already been executed
            if (executionState[nonce] != STATUS_READY) revert AlreadyExecutedTransaction();

            // Try to execute remote request
            // Flag 2 - BranchBridgeAgentExecutor(bridgeAgentExecutorAddress).executeWithSettlementMultiple(recipient, _payload)
            _execute(
                flag == 0x83,
                nonce,
                recipient,
                abi.encodeWithSelector(
                    BranchBridgeAgentExecutor.executeWithSettlementMultiple.selector, recipient, _payload
                )
            );

            // DEPOSIT FLAG: 4 (Retrieve Settlement)
        } else if (flag == 0x04) {
            // Parse recipient
            address payable recipient = payable(address(uint160(bytes20(_payload[PARAMS_START:PARAMS_START_SIGNED]))));

            // Get nonce
            nonce = uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED]));

            // Check if settlement is in retrieve mode
            if (executionState[nonce] == STATUS_DONE) {
                revert AlreadyExecutedTransaction();
            } else {
                // Set settlement to retrieve mode, if not already set.
                if (executionState[nonce] == STATUS_READY) executionState[nonce] = STATUS_RETRIEVE;
                // Trigger fallback/Retry failed fallback
                _performFallbackCall(recipient, nonce);
            }

            // DEPOSIT FLAG: 5 (Fallback)
        } else if (flag == 0x05) {
            // Get nonce
            nonce = uint32(bytes4(_payload[PARAMS_START:PARAMS_TKN_START]));

            // Reopen Deposit for redemption
            getDeposit[nonce].status = STATUS_FAILED;

            // Emit Fallback Event
            emit LogFallback(nonce);

            // Return to prevent unnecessary logic/emits
            return;

            // Unrecognized Function Selector
        } else {
            revert UnknownFlag();
        }

        // Emit Execution Event
        emit LogExecute(nonce);
    }

    /// @inheritdoc ILayerZeroReceiver
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external {
        // Anyone can call this function to force resume a receive and unblock the messaging layer channel.
        ILayerZeroEndpoint(lzEndpointAddress).forceResumeReceive(_srcChainId, _srcAddress);
    }

    /*///////////////////////////////////////////////////////////////
                    SETTLEMENT EXECUTION INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function requests execution from Branch Bridge Agent Executor Contract.
     *   @param _settlementNonce Identifier for nonce being executed.
     *   @param _calldata Calldata to be executed by the Branch Bridge Agent Executor Contract.
     */
    function _execute(uint256 _settlementNonce, bytes memory _calldata) private {
        // Update tx state as executed
        executionState[_settlementNonce] = STATUS_DONE;

        // Try to execute the remote request
        (bool success,) = bridgeAgentExecutorAddress.call{value: address(this).balance}(_calldata);

        //  No fallback is requested revert allowing for settlement retry.
        if (!success) revert ExecutionFailure();
    }

    function _execute(bool _hasFallbackToggled, uint32 _settlementNonce, address _gasRefundee, bytes memory _calldata)
        private
    {
        // Update tx state as executed
        executionState[_settlementNonce] = STATUS_DONE;

        if (_hasFallbackToggled) {
            // Try to execute the remote request
            /// @dev If fallback is requested, subtract 50k gas to allow for fallback call.
            (bool success,) = bridgeAgentExecutorAddress.call{
                gas: gasleft() - BASE_FALLBACK_GAS,
                value: address(this).balance
            }(_calldata);

            // Update tx state if execution failed
            if (!success) {
                // Update tx state as retrieve only
                executionState[_settlementNonce] = STATUS_RETRIEVE;
                // Perform the fallback call
                _performFallbackCall(payable(_gasRefundee), _settlementNonce);
            }
        } else {
            // Try to execute the remote request
            (bool success,) = bridgeAgentExecutorAddress.call{value: address(this).balance}(_calldata);

            // If no fallback is requested revert allowing for settlement retry.
            if (!success) revert ExecutionFailure();
        }
    }

    /*///////////////////////////////////////////////////////////////
                    LAYER ZERO INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to encode the Adapter Params for LayerZero Endpoint.
     *   @dev The minimum gas required for cross-chain call is added to the requested gasLimit.
     *   @param _gParams LayerZero gas information. (_gasLimit,_remoteBranchExecutionGas,_nativeTokenRecipientOnDstChain)
     *   @param _baseExecutionGas Minimum gas required for cross-chain call.
     *   @param _callee Address of the contract to be called on the destination chain.
     *   @return Gas limit for cross-chain call.
     */
    function _encodeAdapterParams(GasParams calldata _gParams, uint256 _baseExecutionGas, address _callee)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            uint16(2), _gParams.gasLimit + _baseExecutionGas, _gParams.remoteBranchExecutionGas, _callee
        );
    }

    /**
     * @notice Internal function performs the call to LayerZero messaging layer Endpoint for cross-chain messaging.
     *   @param _gasRefundee address to refund excess gas to.
     *   @param _payload params for root bridge agent execution.
     *   @param _gParams LayerZero gas information. (_gasLimit,_remoteBranchExecutionGas,_nativeTokenRecipientOnDstChain)
     *   @param _baseExecutionGas Minimum gas required for cross-chain call.
     */
    function _performCall(
        address payable _gasRefundee,
        bytes memory _payload,
        GasParams calldata _gParams,
        uint256 _baseExecutionGas
    ) internal virtual {
        // Sends message to LayerZero messaging layer
        ILayerZeroEndpoint(lzEndpointAddress).send{value: msg.value}(
            rootChainId,
            rootBridgeAgentPath,
            _payload,
            payable(_gasRefundee),
            address(0),
            _encodeAdapterParams(_gParams, _baseExecutionGas, rootBridgeAgentAddress)
        );
    }

    /**
     * @notice Internal function performs the call to Layerzero Endpoint Contract for cross-chain messaging.
     *   @param _gasRefundee address to refund excess gas to.
     *   @param _settlementNonce root settlement nonce to fallback.
     */
    function _performFallbackCall(address payable _gasRefundee, uint32 _settlementNonce) internal virtual {
        // Sends message to LayerZero messaging layer
        ILayerZeroEndpoint(lzEndpointAddress).send{value: address(this).balance}(
            rootChainId,
            rootBridgeAgentPath,
            abi.encodePacked(bytes1(0x09), _settlementNonce),
            _gasRefundee,
            address(0),
            abi.encodePacked(uint16(1), uint256(100_000))
        );
    }

    /*///////////////////////////////////////////////////////////////
                LOCAL USER DEPOSIT INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to move assets from branch chain to root omnichain environment.
     *         Naive assets are deposited and hTokens are bridgedOut.
     *   @param _depositNonce Identifier for user deposit.
     *   @param _depositOwner owner address of the deposit.
     *   @param _hToken Local Input hToken Address.
     *   @param _token Native/Underlying Token Address.
     *   @param _amount Amount of Local hTokens deposited for trade.
     *   @param _deposit Amount of native tokens deposited for trade.
     *
     */
    function _createDeposit(
        bool isSigned,
        uint32 _depositNonce,
        address _depositOwner,
        address _hToken,
        address _token,
        uint256 _amount,
        uint256 _deposit
    ) internal {
        // Update Deposit Nonce
        depositNonce = _depositNonce + 1;

        // Deposit / Lock Tokens into Port
        IPort(localPortAddress).bridgeOut(msg.sender, _hToken, _token, _amount, _deposit);

        // Cast to Dynamic
        address[] memory addressArray = new address[](1);
        uint256[] memory uintArray = new uint256[](1);

        // Save deposit to storage
        Deposit storage deposit = getDeposit[_depositNonce];
        deposit.owner = _depositOwner;

        addressArray[0] = _hToken;
        deposit.hTokens = addressArray;

        addressArray[0] = _token;
        deposit.tokens = addressArray;

        uintArray[0] = _amount;
        deposit.amounts = uintArray;

        uintArray[0] = _deposit;
        deposit.deposits = uintArray;

        if (isSigned) deposit.isSigned = SIGNED_DEPOSIT;
    }

    /**
     * @dev Internal function to move assets from branch chain to root omnichain environment.
     *      Naive assets are deposited and hTokens are bridgedOut.
     *   @param _depositNonce Identifier for user deposit.
     *   @param _depositOwner owner address of the deposit.
     *   @param _hTokens Local Input hToken Address.
     *   @param _tokens Native/Underlying Token Address.
     *   @param _amounts Amount of Local hTokens deposited for trade.
     *   @param _deposits  Amount of native tokens deposited for trade.
     *
     */
    function _createDepositMultiple(
        bool isSigned,
        uint32 _depositNonce,
        address _depositOwner,
        address[] memory _hTokens,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _deposits
    ) internal {
        // Validate Input
        if (_hTokens.length > MAX_TOKENS_LENGTH) revert InvalidInput();
        if (_hTokens.length != _tokens.length) revert InvalidInput();
        if (_tokens.length != _amounts.length) revert InvalidInput();
        if (_amounts.length != _deposits.length) revert InvalidInput();

        // Update Deposit Nonce
        depositNonce = _depositNonce + 1;

        // Deposit / Lock Tokens into Port
        IPort(localPortAddress).bridgeOutMultiple(msg.sender, _hTokens, _tokens, _amounts, _deposits);

        // Update State
        Deposit storage deposit = getDeposit[_depositNonce];
        deposit.owner = _depositOwner;
        deposit.hTokens = _hTokens;
        deposit.tokens = _tokens;
        deposit.amounts = _amounts;
        deposit.deposits = _deposits;

        if (isSigned) deposit.isSigned = SIGNED_DEPOSIT;
    }

    /**
     * @notice Internal function for validating and retrying a deposit.
     *   @param _payload Payload for cross-chain call.
     *   @param _gParams Gas parameters for cross-chain call.
     *   @param _minGas Minimum gas required for cross-chain call.
     */
    function _retryDeposit(bytes memory _payload, GasParams calldata _gParams, uint256 _minGas) internal {
        // Check if payload is empty
        if (_payload.length == 0) revert DepositRetryUnavailableUseCallout();

        // Perform Call
        _performCall(payable(msg.sender), _payload, _gParams, _minGas);
    }

    /*///////////////////////////////////////////////////////////////
                REMOTE USER DEPOSIT INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to request balance clearance from a Port to a given user.
     *   @param _recipient token receiver.
     *   @param _hToken  local hToken address to clear balance for.
     *   @param _token  native/underlying token address to clear balance for.
     *   @param _amount amounts of hToken to clear balance for.
     *   @param _deposit amount of native/underlying tokens to clear balance for.
     *
     */
    function _clearToken(address _recipient, address _hToken, address _token, uint256 _amount, uint256 _deposit)
        internal
    {
        if (_amount - _deposit > 0) {
            unchecked {
                IPort(localPortAddress).bridgeIn(_recipient, _hToken, _amount - _deposit);
            }
        }

        if (_deposit > 0) {
            IPort(localPortAddress).withdraw(_recipient, _token, _deposit);
        }
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Modifier for a simple re-entrancy check.
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    /// @notice Modifier verifies the caller is the Layerzero Enpoint or Local Branch Bridge Agent.
    modifier requiresEndpoint(uint16 _srcChainId, address _endpoint, bytes calldata _srcAddress) {
        _requiresEndpoint(_srcChainId, _endpoint, _srcAddress);
        _;
    }

    /// @notice Internal function for caller verification. To be overwritten in `ArbitrumBranchBridgeAgent'.
    function _requiresEndpoint(uint16 _srcChainId, address _endpoint, bytes calldata _srcAddress)
        internal
        view
        virtual
    {
        //Verify Endpoint
        if (msg.sender != address(this)) revert LayerZeroUnauthorizedEndpoint();
        if (_endpoint != lzEndpointAddress) if (_endpoint != address(0)) revert LayerZeroUnauthorizedEndpoint();

        //Verify Remote Caller
        if (_srcChainId != rootChainId) revert LayerZeroUnauthorizedCaller();
        if (_srcAddress.length != 40) revert LayerZeroUnauthorizedCaller();
        if (rootBridgeAgentAddress != address(uint160(bytes20(_srcAddress[:PARAMS_ADDRESS_SIZE])))) {
            revert LayerZeroUnauthorizedCaller();
        }
    }

    /// @notice Modifier that verifies caller is Branch Bridge Agent's Router.
    modifier requiresRouter() {
        if (localRouterAddress != address(0)) if (msg.sender != localRouterAddress) revert UnrecognizedRouter();
        _;
    }

    /// @notice Modifier that verifies caller is the Bridge Agent Executor.
    modifier requiresAgentExecutor() {
        if (msg.sender != bridgeAgentExecutorAddress) revert UnrecognizedBridgeAgentExecutor();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "lib/solady/src/auth/Ownable.sol";

import {SafeTransferLib} from "lib/solady/src/utils/SafeTransferLib.sol";

import {BridgeAgentConstants} from "./interfaces/BridgeAgentConstants.sol";
import {SettlementParams, SettlementMultipleParams} from "./interfaces/IBranchBridgeAgent.sol";
import {IBranchRouter as IRouter} from "./interfaces/IBranchRouter.sol";

import {DecodeBridgeInMultipleParams} from "./lib/DecodeBridgeInMultipleParams.sol";

import {BranchBridgeAgent} from "./BranchBridgeAgent.sol";

/// @title Library for Branch Bridge Agent Executor Deployment
library DeployBranchBridgeAgentExecutor {
    function deploy(address _branchRouter) external returns (address) {
        return address(new BranchBridgeAgentExecutor(_branchRouter));
    }
}

/**
 * @title  Branch Bridge Agent Executor Contract
 * @author MaiaDAO
 * @notice This contract is used for requesting token deposit clearance and executing transactions in response to
 *         requests from the root environment.
 * @dev    Execution is "sandboxed" meaning upon tx failure both token deposits and interactions with external
 *         contracts should be reverted and caught by the Branch Bridge Agent.
 */
contract BranchBridgeAgentExecutor is Ownable, BridgeAgentConstants {
    using SafeTransferLib for address;
    using DecodeBridgeInMultipleParams for bytes;

    /*///////////////////////////////////////////////////////////////
                                IMMUATABLES
    ///////////////////////////////////////////////////////////////*/

    /// @notice Router that is responsible for executing the cross-chain requests forwarded by this contract.
    IRouter public immutable branchRouter;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for Branch Bridge Agent Executor.
     * @param _branchRouter router that will execute the cross-chain requests forwarded by this contract.
     * @dev    Sets the owner of the contract to the Branch Bridge Agent that deploys it.
     */
    constructor(address _branchRouter) {
        branchRouter = IRouter(_branchRouter);
        _initializeOwner(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        EXECUTOR EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to execute a cross-chain request without any settlement.
     * @param _payload Data received from the messaging layer.
     * @dev SETTLEMENT FLAG: 1 (No settlement)
     */
    function executeNoSettlement(bytes calldata _payload) external payable onlyOwner {
        // Execute Calldata if there is code in the destination router
        branchRouter.executeNoSettlement{value: msg.value}(_payload[PARAMS_TKN_START_SIGNED:]);
    }

    /**
     * @notice Function to execute a cross-chain request with a single settlement.
     * @param _recipient Address of the recipient of the settlement.
     * @param _payload Data received from the messaging layer.
     * @dev Router is responsible for managing the msg.value either using it for more remote calls or sending to user.
     * @dev SETTLEMENT FLAG: 2 (Single Settlement)
     */
    function executeWithSettlement(address _recipient, bytes calldata _payload) external payable onlyOwner {
        // Clear Token / Execute Settlement
        SettlementParams memory sParams = SettlementParams({
            settlementNonce: uint32(bytes4(_payload[PARAMS_START_SIGNED:PARAMS_TKN_START_SIGNED])),
            recipient: _recipient,
            hToken: address(uint160(bytes20(_payload[PARAMS_TKN_START_SIGNED:45]))),
            token: address(uint160(bytes20(_payload[45:65]))),
            amount: uint256(bytes32(_payload[65:97])),
            deposit: uint256(bytes32(_payload[97:PARAMS_SETTLEMENT_OFFSET]))
        });

        // Bridge In Assets
        BranchBridgeAgent(payable(msg.sender)).bridgeIn(
            _recipient, sParams.hToken, sParams.token, sParams.amount, sParams.deposit
        );

        // Execute Calldata if there is any
        if (_payload.length > PARAMS_SETTLEMENT_OFFSET) {
            // Execute remote request
            branchRouter.executeSettlement{value: msg.value}(_payload[PARAMS_SETTLEMENT_OFFSET:], sParams);
        } else if (_recipient == address(branchRouter)) {
            // Execute remote request
            branchRouter.executeSettlement{value: msg.value}("", sParams);
        } else {
            // Send remaininig native / gas token to recipient
            _recipient.safeTransferETH(address(this).balance);
        }
    }

    /**
     * @notice Function to execute a cross-chain request with multiple settlements.
     * @param _recipient Address of the recipient of the settlement.
     * @param _payload Data received from the messaging layer.
     * @dev Router is responsible for managing the msg.value either using it for more remote calls or sending to user.
     * @dev SETTLEMENT FLAG: 3 (Multiple Settlements)
     */
    function executeWithSettlementMultiple(address _recipient, bytes calldata _payload) external payable onlyOwner {
        // Parse Values
        uint256 assetsOffset = uint8(bytes1(_payload[PARAMS_START_SIGNED])) * PARAMS_TKN_SET_SIZE_MULTIPLE;
        uint256 settlementEndOffset = PARAMS_END_SIGNED_OFFSET + assetsOffset;

        // Bridge In Assets and Save Deposit Params
        SettlementMultipleParams memory sParams =
            _bridgeInMultiple(_recipient, _payload[PARAMS_START_SIGNED:settlementEndOffset]);

        // Execute Calldata if there is any
        if (_payload.length > settlementEndOffset) {
            // Execute remote request
            branchRouter.executeSettlementMultiple{value: msg.value}(_payload[settlementEndOffset:], sParams);
        } else if (_recipient == address(branchRouter)) {
            // Execute remote request
            branchRouter.executeSettlementMultiple{value: msg.value}("", sParams);
        } else {
            // Send remaininig native / gas token to recipient
            _recipient.safeTransferETH(address(this).balance);
        }
    }

    /**
     * @notice Internal function to move assets from root omnichain environment to branch chain.
     *   @param _recipient Cross-Chain Settlement of Multiple Tokens Params.
     *   @param _sParams Cross-Chain Settlement of Multiple Tokens Params.
     *   @dev Since the input data payload is encodePacked we need to parse it:
     *     1. First byte is the number of assets to be bridged in. Equals length of all arrays.
     *     2. Next 4 bytes are the nonce of the deposit.
     *     3. Last 32 bytes after the token related information are the chain to bridge to.
     *     4. Token related information starts at index PARAMS_TKN_START is encoded as follows:
     *         1. N * 32 bytes for the hToken address.
     *         2. N * 32 bytes for the underlying token address.
     *         3. N * 32 bytes for the amount of tokens to be bridged in.
     *         4. N * 32 bytes for the amount of underlying tokens to be bridged in.
     *     5. Each of the 4 token related arrays are of length N and start at the following indexes:
     *         1. PARAMS_TKN_START [hToken address has no offset from token information start].
     *         2. PARAMS_TKN_START + (PARAMS_ADDRESS_SIZE * N)
     *         3. PARAMS_TKN_START + (PARAMS_AMT_OFFSET * N)
     *         4. PARAMS_TKN_START + (PARAMS_DEPOSIT_OFFSET * N)
     */
    function _bridgeInMultiple(address _recipient, bytes calldata _sParams)
        internal
        returns (SettlementMultipleParams memory sParams)
    {
        // Decode Params
        (
            uint8 numOfAssets,
            uint32 nonce,
            address[] memory hTokens,
            address[] memory tokens,
            uint256[] memory amounts,
            uint256[] memory deposits
        ) = _sParams.decodeBridgeMultipleInfo();

        // Save Deposit Multiple Params
        sParams = SettlementMultipleParams(numOfAssets, _recipient, nonce, hTokens, tokens, amounts, deposits);

        BranchBridgeAgent(payable(msg.sender)).bridgeInMultiple(_recipient, sParams);
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

/*///////////////////////////////////////////////////////////////
                            STRUCTS
//////////////////////////////////////////////////////////////*/

/// @notice Struct for storing the gas parameters for a cross-chain call.
/// @param gasLimit gas units allocated for a cross-chain call execution.
/// @param remoteBranchExecutionGas native token amount to request for destiantion branch usage.
struct GasParams {
    uint256 gasLimit;
    uint256 remoteBranchExecutionGas;
}

/// @notice Struct for storing information about a deposit in a Branch Bridge Agent's state.
/// @param status status of the deposit. Has 3 states - ready, done, retrieve.
/// @param isSigned indicates if the deposit has been signed allowing Virtual Account usage.
/// @param owner owner of the deposit.
/// @param hTokens array of local hTokens addresses.
/// @param tokens array of underlying token addresses.
/// @param amounts array of total deposited amounts.
/// @param deposits array of underlying token deposited amounts.
struct Deposit {
    uint8 status;
    uint88 isSigned;
    address owner;
    address[] hTokens;
    address[] tokens;
    uint256[] amounts;
    uint256[] deposits;
}

/// @notice Struct for inputting deposit information into a Branch Bridge Agent.
/// @param hToken local hToken address.
/// @param token underlying token address.
/// @param amount total amount to deposit.
/// @param deposit underlying token amount to deposit.
struct DepositInput {
    address hToken;
    address token;
    uint256 amount;
    uint256 deposit;
}

/// @notice Struct for inputting multiple asset deposit information into a Branch Bridge Agent.
/// @param hTokens array of local hTokens addresses.
/// @param tokens array of underlying token addresses.
/// @param amounts array of total amounts to deposit.
/// @param deposits array of underlying token amounts to deposit.
struct DepositMultipleInput {
    address[] hTokens;
    address[] tokens;
    uint256[] amounts;
    uint256[] deposits;
}

/// @notice Struct for encoding deposit information in a cross-chain message.
/// @param depositNonce deposit nonce.
/// @param hToken local hToken address.
/// @param token underlying token address.
/// @param amount total amount to deposit.
/// @param deposit underlying token amount to deposit.
struct DepositParams {
    uint32 depositNonce;
    address hToken;
    address token;
    uint256 amount;
    uint256 deposit;
}

/// @notice Struct for encoding multiple asset deposit information in a cross-chain message.
/// @param numberOfAssets number of assets to deposit.
/// @param depositNonce deposit nonce.
/// @param hTokens array of local hTokens addresses.
/// @param tokens array of underlying token addresses.
/// @param amounts array of total amounts to deposit.
/// @param deposits array of underlying token amounts to deposit.
struct DepositMultipleParams {
    uint8 numberOfAssets;
    uint32 depositNonce;
    address[] hTokens;
    address[] tokens;
    uint256[] amounts;
    uint256[] deposits;
}

/// @notice Struct for storing information about a settlement in a Root Bridge Agent's state.
/// @param dstChainId destination chain for interaction.
/// @param status status of the settlement.
/// @param owner owner of the settlement.
/// @param recipient recipient of the settlement.
/// @param hTokens array of global hTokens addresses.
/// @param tokens array of underlying token addresses.
/// @param amounts array of total settled amounts.
/// @param deposits array of underlying token settled amounts.
struct Settlement {
    uint16 dstChainId;
    uint80 status;
    address owner;
    address recipient;
    address[] hTokens;
    address[] tokens;
    uint256[] amounts;
    uint256[] deposits;
}

/// @notice Struct for inputting token settlement information into a Root Bridge Agent.
/// @param globalAddress global hToken address.
/// @param amount total amount to settle.
/// @param deposit underlying token amount to settle.
struct SettlementInput {
    address globalAddress;
    uint256 amount;
    uint256 deposit;
}

/// @notice Struct for inputting multiple asset settlement information into a Root Bridge Agent.
/// @param globalAddresses array of global hTokens addresses.
/// @param amounts array of total amounts to settle.
/// @param deposits array of underlying token amounts to settle.

struct SettlementMultipleInput {
    address[] globalAddresses;
    uint256[] amounts;
    uint256[] deposits;
}

/// @notice Struct for encoding settlement information in a cross-chain message.
/// @param settlementNonce settlement nonce.
/// @param recipient recipient of the settlement.
/// @param hToken destination local hToken address.
/// @param token destination underlying token address.
/// @param amount total amount to settle.
/// @param deposit underlying token amount to settle.
struct SettlementParams {
    uint32 settlementNonce;
    address recipient;
    address hToken;
    address token;
    uint256 amount;
    uint256 deposit;
}

/// @notice Struct for encoding multiple asset settlement information in a cross-chain message.
/// @param numberOfAssets number of assets to settle.
/// @param recipient recipient of the settlement.
/// @param settlementNonce settlement nonce.
/// @param hTokens array of destination local hTokens addresses.
/// @param tokens array of destination underlying token addresses.
/// @param amounts array of total amounts to settle.
/// @param deposits array of underlying token amounts to settle.
struct SettlementMultipleParams {
    uint8 numberOfAssets;
    address recipient;
    uint32 settlementNonce;
    address[] hTokens;
    address[] tokens;
    uint256[] amounts;
    uint256[] deposits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    GasParams,
    Deposit,
    DepositInput,
    DepositMultipleInput,
    DepositParams,
    DepositMultipleParams,
    SettlementParams,
    SettlementMultipleParams
} from "./BridgeAgentStructs.sol";
import {ILayerZeroReceiver} from "./ILayerZeroReceiver.sol";

/*///////////////////////////////////////////////////////////////
                            ENUMS
//////////////////////////////////////////////////////////////*/

/**
 * @title  Branch Bridge Agent Contract
 * @author MaiaDAO
 * @notice Contract for deployment in Branch Chains of Omnichain System, responsible for interfacing with
 *         Users and Routers acting as a middleman to access LayerZero cross-chain messaging and requesting/depositing
 *         assets in the Branch Chain's Ports.
 * @dev    Bridge Agents allow for the encapsulation of business logic as well as standardize cross-chain communication,
 *         allowing for the creation of custom Routers to perform actions in response to local / remote user requests.
 *         This contract is designed for deployment in the Branch Chains of the Ulysses Omnichain Liquidity System.
 *         The Branch Bridge Agent is responsible for sending/receiving requests to/from the LayerZero Messaging Layer
 *         for execution, as well as requests tokens clearances and tx execution to the `BranchBridgeAgentExecutor`.
 *         Remote execution is "sandboxed" within 2 different layers/nestings:
 *         - 1: Upon receiving a request from LayerZero Messaging Layer to avoid blocking future requests due to
 *              execution reversion, ensuring our app is Non-Blocking.
 *              (See https://github.com/LayerZero-Labs/solidity-examples/blob/8e62ebc886407aafc89dbd2a778e61b7c0a25ca0/contracts/lzApp/NonblockingLzApp.sol)
 *         - 2: The call to `BranchBridgeAgentExecutor` is in charge of requesting token deposits for each remote
 *              interaction as well as performing the Router calls, if any of the calls initiated by the Router lead
 *              to an invalid state change both the token deposit clearances as well as the external interactions
 *              will be reverted and caught by the `BranchBridgeAgent`.
 *
 *         **BRANCH BRIDGE AGENT SETTLEMENT FLAGs** Func IDs for calling these functions through the messaging layer
 *
 *         | ID   | DESCRIPTION                                                                                       |
 *         | ---- | ------------------------------------------------------------------------------------------------- |
 *         | 0x01 | Call to Branch without Settlement.                                                                |
 *         | 0x02 | Call to Branch with Settlement.                                                                   |
 *         | 0x03 | Call to Branch with Settlement of Multiple Tokens.                                                |
 *         | 0x04 | Call to `retrieveSettlement()`. (trigger `_fallback` for a settlement that has not been executed) |
 *         | 0x05 | Call to `_fallback()`. (reopens a deposit for asset redemption)                                   |
 *
 *         Encoding Scheme for different Root Bridge Agent Deposit Flags:
 *
 *           - ht = hToken
 *           - t = Token
 *           - A = Amount
 *           - D = Deposit
 *           - b = bytes
 *           - n = number of assets
 *
 *         | Flag   | Deposit Info                | Token Info              | DATA |
 *         | ------ | --------------------------- | ----------------------- | ---- |
 *         | 1 byte | 4-25 bytes                  | 104 or (128 * n) bytes  |      |
 *         |        |                             | hT - t - A - D          | ...  |
 *         | 0x1    | 20b(recipient) + 4b(nonce)  |          ---            | ...  |
 *         | 0x2    | 20b(recipient) + 4b(nonce)  | 20b + 20b + 32b + 32b   | ...  |
 *         | 0x3    | 1b(n) + 20b(recipient) + 4b | 32b + 32b + 32b + 32b   | ...  |
 *
 *         **Generic Contract Interaction Flow:**
 *         BridgeAgent.lzReceive() -> BridgeAgentExecutor.execute() -> Router.execute()
 *
 */
interface IBranchBridgeAgent is ILayerZeroReceiver {
    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice External function to return the Branch Chain's Local Port Address.
     * @return address of the Branch Chain's Local Port.
     */
    function localPortAddress() external view returns (address);

    /**
     * @notice External function to return the Branch Bridge Agent Executor Address.
     * @return address of the Branch Bridge Agent Executor.
     */
    function bridgeAgentExecutorAddress() external view returns (address);

    /**
     * @notice External function that returns a given deposit entry.
     *  @param depositNonce Identifier for user deposit.
     */
    function getDepositEntry(uint32 depositNonce) external view returns (Deposit memory);

    /*///////////////////////////////////////////////////////////////
                    USER AND BRANCH ROUTER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to perform a call to the Root Omnichain Router without token deposit.
     *  @param gasRefundee Address to return excess gas deposited in `msg.value` to.
     *  @param params enconded parameters to execute on the root chain router.
     *  @param gasParams gas parameters for the cross-chain call.
     *  @dev DEPOSIT ID: 1 (Call without deposit)
     */
    function callOut(address payable gasRefundee, bytes calldata params, GasParams calldata gasParams)
        external
        payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing a single asset.
     *  @param depositOwnerAndGasRefundee Deposit owner and address to return excess gas deposited in `msg.value` to.
     *  @param params enconded parameters to execute on the root chain router.
     *  @param depositParams additional token deposit parameters.
     *  @param gasParams gas parameters for the cross-chain call.
     *  @dev DEPOSIT ID: 2 (Call with single deposit)
     */
    function callOutAndBridge(
        address payable depositOwnerAndGasRefundee,
        bytes calldata params,
        DepositInput memory depositParams,
        GasParams calldata gasParams
    ) external payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing two or more assets.
     *  @param depositOwnerAndGasRefundee Deposit owner and address to return excess gas deposited in `msg.value` to.
     *  @param params enconded parameters to execute on the root chain router.
     *  @param depositParams additional token deposit parameters.
     *  @param gasParams gas parameters for the cross-chain call.
     *  @dev DEPOSIT ID: 3 (Call with multiple deposit)
     */
    function callOutAndBridgeMultiple(
        address payable depositOwnerAndGasRefundee,
        bytes calldata params,
        DepositMultipleInput memory depositParams,
        GasParams calldata gasParams
    ) external payable;

    /**
     * @notice Perform a call to the Root Omnichain Router without token deposit with msg.sender information.
     *  @dev msg.sender is gasRefundee in signed calls.
     *  @param params enconded parameters to execute on the root chain router.
     *  @param gasParams gas parameters for the cross-chain call.
     *  @dev DEPOSIT ID: 4 (Call without deposit and verified sender)
     */
    function callOutSigned(bytes calldata params, GasParams calldata gasParams) external payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing a single asset msg.sender.
     *  @dev msg.sender is depositOwnerAndGasRefundee in signed calls.
     *  @param params enconded parameters to execute on the root chain router.
     *  @param depositParams additional token deposit parameters.
     *  @param gasParams gas parameters for the cross-chain call.
     *  @param hasFallbackToggled flag to indicate if the fallback function was toggled.
     *  @dev DEPOSIT ID: 5 (Call with single deposit and verified sender)
     */
    function callOutSignedAndBridge(
        bytes calldata params,
        DepositInput memory depositParams,
        GasParams calldata gasParams,
        bool hasFallbackToggled
    ) external payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while
     *         depositing two or more assets with msg.sender.
     *  @dev msg.sender is depositOwnerAndGasRefundee in signed calls.
     *  @param params enconded parameters to execute on the root chain router.
     *  @param depositParams additional token deposit parameters.
     *  @param gasParams gas parameters for the cross-chain call.
     *  @param hasFallbackToggled flag to indicate if the fallback function was toggled.
     *  @dev DEPOSIT ID: 6 (Call with multiple deposit and verified sender)
     */
    function callOutSignedAndBridgeMultiple(
        bytes calldata params,
        DepositMultipleInput memory depositParams,
        GasParams calldata gasParams,
        bool hasFallbackToggled
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to perform a call to the Root Omnichain Environment
     *         retrying a failed non-signed deposit that hasn't been executed yet.
     *  @param owner address of the deposit owner.
     *  @param depositNonce Identifier for user deposit.
     *  @param params parameters to execute on the root chain router.
     *  @param gasParams gas parameters for the cross-chain call.
     */
    function retryDeposit(address owner, uint32 depositNonce, bytes calldata params, GasParams calldata gasParams)
        external
        payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Environment
     *         retrying a failed signed deposit that hasn't been executed yet.
     *  @param depositNonce Identifier for user deposit.
     *  @param params parameters to execute on the root chain router.
     *  @param gasParams gas parameters for the cross-chain call.
     *  @param hasFallbackToggled flag to indicate if the fallback function was toggled.
     */
    function retryDepositSigned(
        uint32 depositNonce,
        bytes calldata params,
        GasParams calldata gasParams,
        bool hasFallbackToggled
    ) external payable;

    /**
     * @notice External function to request tokens back to branch chain after failing omnichain environment interaction.
     *  @param depositNonce Identifier for user deposit to retrieve.
     *  @param gasParams gas parameters for the cross-chain call.
     *  @dev DEPOSIT ID: 8
     */
    function retrieveDeposit(uint32 depositNonce, GasParams calldata gasParams) external payable;

    /**
     * @notice External function to retry a failed Deposit entry on this branch chain.
     *  @param depositNonce Identifier for user deposit.
     *  @param recipient address to receive the redeemed tokens.
     */
    function redeemDeposit(uint32 depositNonce, address recipient) external;

    /**
     * @notice External function to retry a failed Deposit entry on this branch chain.
     *  @param depositNonce Identifier for user deposit.
     *  @param recipient address to receive the redeemed tokens.
     *  @param localTokenAddress address of the local token to redeem.
     */
    function redeemDeposit(uint32 depositNonce, address recipient, address localTokenAddress) external;

    /*///////////////////////////////////////////////////////////////
                    SETTLEMENT EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice External function to retry a failed Settlement entry on the root chain.
     *  @param settlementNonce Identifier for user settlement.
     *  @param params parameters to execute on the root chain router.
     *  @param gasParams gas parameters for the cross-chain call to root chain and for the settlement to branch.
     *  @param hasFallbackToggled flag to indicate if the fallback function should be toggled.
     *  @dev DEPOSIT ID: 7
     */
    function retrySettlement(
        uint32 settlementNonce,
        bytes calldata params,
        GasParams[2] calldata gasParams,
        bool hasFallbackToggled
    ) external payable;

    /*///////////////////////////////////////////////////////////////
                    TOKEN MANAGEMENT EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to request balance clearance from a Port to a given user.
     *  @param recipient token receiver.
     *  @param hToken  local hToken addresse to clear balance for.
     *  @param token  native / underlying token addresse to clear balance for.
     *  @param amount amounts of token to clear balance for.
     *  @param deposit amount of native / underlying tokens to clear balance for.
     */
    function bridgeIn(address recipient, address hToken, address token, uint256 amount, uint256 deposit) external;

    /**
     * @notice Function to request balance clearance from a Port to a given address.
     *  @param recipient token receiver.
     *  @param sParams encode packed multiple settlement info.
     */
    function bridgeInMultiple(address recipient, SettlementMultipleParams calldata sParams) external;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when a settlement nonce is executed successfully.
    event LogExecute(uint256 indexed nonce);

    /// @notice Event emitted when fallback is received for a failed deposit nonce.
    event LogFallback(uint256 indexed nonce);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Error emitted when the provided Root Bridge Agent Address is invalid.
    error InvalidRootBridgeAgentAddress();
    /// @notice Error emitted when the provided Branch Port Address is invalid.
    error InvalidBranchPortAddress();
    /// @notice Error emitted when the provided Layer Zero Endpoint Address is invalid.
    error InvalidEndpointAddress();

    /// @notice Error emitted when the Branch Bridge Agent does not recognize the action flag.
    error UnknownFlag();
    /// @notice Error emitted when a settlement nonce fails to execute and does not have fallback enabled.
    error ExecutionFailure();

    /// @notice Error emitted when a Layer Zero remote caller in not recognized as the Root Bridge Agent.
    error LayerZeroUnauthorizedCaller();
    /// @notice Error emitted when the caller is not the local Layer Zero Endpoint contract.
    error LayerZeroUnauthorizedEndpoint();

    /// @notice Error emitted when the settlement nonce has already been executed.
    error AlreadyExecutedTransaction();

    /// @notice Error emitted when the local hToken address is zero.
    error InvalidLocalAddress();
    /// @notice Error emitted when the deposit information is not valid.
    error InvalidInput();

    /// @notice Error emitted when caller is not the deposit owner.
    error NotDepositOwner();
    /// @notice Error emitted when the action of deposit nonce is not retryabable.
    error DepositRetryUnavailableUseCallout();
    /// @notice Error emitted when the deposit nonce is not in a redeemable state.
    error DepositRedeemUnavailable();
    /// @notice Error emitted when the deposit nonce is not in a retryable state.
    error DepositAlreadyRetrieved();

    /// @notice Error emitted when the caller is not the Branch Bridge Agent's Router
    error UnrecognizedRouter();
    /// @notice Error emitted when the caller is not the Branch Bridge Agent's Executors
    error UnrecognizedBridgeAgentExecutor();
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

import {
    GasParams,
    Deposit,
    DepositInput,
    DepositMultipleInput,
    SettlementParams,
    SettlementMultipleParams
} from "./IBranchBridgeAgent.sol";

/**
 * @title  BaseBranchRouter Contract
 * @author MaiaDAO
 * @notice Base Branch Contract for interfacing with Branch Bridge Agents.
 *         This contract for deployment in Branch Chains of the Ulysses Omnichain System,
 *         additional logic can be implemented to perform actions before sending cross-chain
 *         requests, as well as in response to requests from the Root Omnichain Environment.
 */
interface IBranchRouter {
    /*///////////////////////////////////////////////////////////////
                            VIEW / STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice External function to return the Branch Chain's Local Port Address.
    function localPortAddress() external view returns (address);

    /// @notice Address for local Branch Bridge Agent who processes requests and interacts with local port.
    function localBridgeAgentAddress() external view returns (address);

    /// @notice Local Bridge Agent Executor Address.
    function bridgeAgentExecutorAddress() external view returns (address);

    /// @notice External function that returns a given deposit entry.
    /// @param depositNonce Identifier for user deposit.
    function getDepositEntry(uint32 depositNonce) external view returns (Deposit memory);

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to perform a call to the Root Omnichain Router without token deposit.
     *   @param params enconded parameters to execute on the root chain.
     *   @param gParams gas parameters for the cross-chain call.
     *   @dev ACTION ID: 1 (Call without deposit)
     *
     */
    function callOut(bytes calldata params, GasParams calldata gParams) external payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing a single asset.
     *   @param params encoded parameters to execute on the root chain.
     *   @param dParams additional token deposit parameters.
     *   @param gParams gas parameters for the cross-chain call.
     *   @dev ACTION ID: 2 (Call with single deposit)
     *
     */
    function callOutAndBridge(bytes calldata params, DepositInput calldata dParams, GasParams calldata gParams)
        external
        payable;

    /**
     * @notice Function to perform a call to the Root Omnichain Router while depositing two or more assets.
     *   @param params encoded parameters to execute on the root chain.
     *   @param dParams additional token deposit parameters.
     *   @param gParams gas parameters for the cross-chain call.
     *   @dev ACTION ID: 3 (Call with multiple deposit)
     *
     */
    function callOutAndBridgeMultiple(
        bytes calldata params,
        DepositMultipleInput calldata dParams,
        GasParams calldata gParams
    ) external payable;

    /**
     * @notice Function to retry a deposit that has failed.
     *   @param _depositNonce Identifier for user deposit.
     *   @param _params encoded router parameters to execute on the root chain.
     *   @param _gParams gas parameters for the cross-chain call.
     */
    function retryDeposit(uint32 _depositNonce, bytes calldata _params, GasParams calldata _gParams) external payable;

    /*///////////////////////////////////////////////////////////////
                        LAYERZERO EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Function responsible of executing a branch router response.
     *   @param params data received from messaging layer.
     */
    function executeNoSettlement(bytes calldata params) external payable;

    /**
     * @dev Function responsible of executing a crosschain request without any deposit.
     *   @param params data received from messaging layer.
     *   @param sParams SettlementParams struct.
     */
    function executeSettlement(bytes calldata params, SettlementParams calldata sParams) external payable;

    /**
     * @dev Function responsible of executing a crosschain request which contains
     *      cross-chain deposit information attached.
     *   @param params data received from messaging layer.
     *   @param sParams SettlementParams struct containing deposit information.
     *
     */
    function executeSettlementMultiple(bytes calldata params, SettlementMultipleParams calldata sParams)
        external
        payable;

    /*///////////////////////////////////////////////////////////////
                             ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Error emitted when the Branch Router does not recognize the function ID.
    error UnrecognizedFunctionId();

    /// @notice Error emitted when caller is not the Branch Bridge Agent Executor.
    error UnrecognizedBridgeAgentExecutor();
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint256 _configType)
        external
        view
        returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    /*///////////////////////////////////////////////////////////////
                            LAYER ZERO FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice LayerZero endpoint will invoke this function to deliver the message on the destination
     *  @param _srcChainId the source endpoint identifier
     *  @param _srcAddress the source sending contract address from the source chain
     *  @param _nonce the ordered message nonce
     *  @param _payload the signed payload is the UA bytes has encoded to be sent
     */
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
        external
        payable
        returns (bool);

    /**
     * @notice External function to receive cross-chain messages from LayerZero Endpoint Contract without blocking.
     *  @param _endpoint address of the LayerZero Endpoint Contract.
     *  @param _srcAddress address path of the recipient + sender.
     *  @param _payload Calldata for function call.
     */
    function lzReceiveNonBlocking(
        address _endpoint,
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external payable;

    /**
     * @notice Only when the BridgeAgent needs to resume the message flow in blocking mode and clear the stored payload.
     *  @param _srcChainId the chainId of the source chain
     *  @param _srcAddress the contract address of the source contract at the source chain
     */
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  Decode Params Library
 * @notice Library for decoding Ulysses cross-chain messages.
 * @dev    Used for decoding of Ulysses cross-chain messages.
 */
library DecodeBridgeInMultipleParams {
    /*///////////////////////////////////////////////////////////////
                   PAYLOAD DECODING POSITIONAL CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    // Defines the position in bytes where the payload starts after the flag byte.
    // Also used to offset number of assets in the payload.
    uint256 internal constant PARAMS_START = 1;

    // Defines the position in bytes where token-related information starts, after flag byte and nonce.
    uint256 internal constant PARAMS_TKN_START = 5;

    // Size in bytes for standard Ethereum types / slot size (like uint256).
    uint256 internal constant PARAMS_ENTRY_SIZE = 32;

    // Offset in bytes from the start of a slot to the start of an address.
    // Considering Ethereum addresses are 20 bytes and fit within the 32 bytes slot.
    uint256 internal constant ADDRESS_END_OFFSET = 12;

    // Offset in bytes to reach the amount parameter after hToken and token addresses in the token-related info.
    uint256 internal constant PARAMS_AMT_OFFSET = 64;

    // Offset in bytes to reach the deposit parameter after hToken, token, and amount in the token-related info.
    uint256 internal constant PARAMS_DEPOSIT_OFFSET = 96;

    /*///////////////////////////////////////////////////////////////
                    PAYLOAD DECODING POSITIONAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function decodeBridgeMultipleInfo(bytes calldata _params)
        internal
        pure
        returns (
            uint8 numOfAssets,
            uint32 nonce,
            address[] memory hTokens,
            address[] memory tokens,
            uint256[] memory amounts,
            uint256[] memory deposits
        )
    {
        // Parse Parameters
        numOfAssets = uint8(bytes1(_params[0]));

        // Parse Nonce
        nonce = uint32(bytes4(_params[PARAMS_START:PARAMS_TKN_START]));

        // Initialize Arrays
        hTokens = new address[](numOfAssets);
        tokens = new address[](numOfAssets);
        amounts = new uint256[](numOfAssets);
        deposits = new uint256[](numOfAssets);

        for (uint256 i = 0; i < numOfAssets;) {
            // Cache offset
            uint256 currentIterationOffset = PARAMS_START + i;

            // Parse Params
            hTokens[i] = address(
                uint160(
                    bytes20(
                        bytes32(
                            _params[
                                PARAMS_TKN_START + (PARAMS_ENTRY_SIZE * i) + ADDRESS_END_OFFSET:
                                    PARAMS_TKN_START + (PARAMS_ENTRY_SIZE * currentIterationOffset)
                            ]
                        )
                    )
                )
            );

            tokens[i] = address(
                uint160(
                    bytes20(
                        bytes32(
                            _params[
                                PARAMS_TKN_START + PARAMS_ENTRY_SIZE * (i + numOfAssets) + ADDRESS_END_OFFSET:
                                    PARAMS_TKN_START + PARAMS_ENTRY_SIZE * (currentIterationOffset + numOfAssets)
                            ]
                        )
                    )
                )
            );

            amounts[i] = uint256(
                bytes32(
                    _params[
                        PARAMS_TKN_START + PARAMS_AMT_OFFSET * numOfAssets + PARAMS_ENTRY_SIZE * i:
                            PARAMS_TKN_START + PARAMS_AMT_OFFSET * numOfAssets + PARAMS_ENTRY_SIZE * currentIterationOffset
                    ]
                )
            );

            deposits[i] = uint256(
                bytes32(
                    _params[
                        PARAMS_TKN_START + PARAMS_DEPOSIT_OFFSET * numOfAssets + PARAMS_ENTRY_SIZE * i:
                            PARAMS_TKN_START + PARAMS_DEPOSIT_OFFSET * numOfAssets
                                + PARAMS_ENTRY_SIZE * currentIterationOffset
                    ]
                )
            );

            unchecked {
                ++i;
            }
        }
    }
}