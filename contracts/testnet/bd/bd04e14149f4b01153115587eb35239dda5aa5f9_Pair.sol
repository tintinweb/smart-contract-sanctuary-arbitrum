// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
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

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
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
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
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
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x6c.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
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
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
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

pragma solidity ^0.8.15;

library Codec {
    uint256 public constant BURN_VOUCHERS = 1;
    uint256 public constant SYNC_TO_L1 = 2;
    uint256 public constant SYNC_TO_L2 = 3;

    function getType(bytes calldata payload) internal pure returns (uint256 msgType) {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, payload.offset, 32)
            msgType := shr(253, mload(ptr))

        }
    }

    /*##############################################################################################################################*/

    struct PartialSync {
        address token;
        uint128 tokensForDove; // tokens to send to Dove, aka vouchers held by pair burnt
        uint128 earmarkedAmount; // tokens to earmark aka vouchers
        uint128 pairBalance; // token balance of the pair
    }

    struct SyncerMetadata {
        uint64 syncerPercentage;
        address syncer;
    }

    function encodeSyncToL1(
        uint16 syncID,
        address L1Token0,
        uint128 pairVoucherBalance0,
        uint128 voucherDelta0, 
        uint256 balance0,
        address L1Token1,
        uint128 pairVoucherBalance1,
        uint128 voucherDelta1,
        uint256 balance1,
        address syncer,
        uint64 syncerPercentage
    ) internal pure returns (bytes memory payload) {
        assembly {
            payload := mload(0x40) // free mem ptr
            mstore(payload, 0xC0) // store length
            /*
                fpacket is split into the following, left to right
                3 bits  | 16 bits | 14 bits | 160 bits |
                --------|---------|---------|----------| = 193 bits occupied
                msgType | syncID  | syncer% | syncer   |
            */
            let fpacket := shl(253, SYNC_TO_L1) // 3 bits
            fpacket := or(fpacket, shl(237, syncID)) // 16 bits
            fpacket := or(fpacket, shl(223, syncerPercentage)) // 14 bits
            fpacket := or(fpacket, shl(63, syncer)) // 160 bits
            mstore(add(payload, 0x20), fpacket) // 1 memory "slot" used so far
            /*
            mem   |--------- 0x40 ---------|--------- 0x60 ---------|--------- 0x80 ---------|--------- 0xA0 ---------|--------- 0xC0 ---------|
            var   |      L1T0     | TFD0   | TFD0 |    EA0    | PB0 | PB0 |   L1T1   |  TFD1 | TFD1 |    EA1    | PB1 | PB1 |   0x00   | 0x00 |
            bytes |       20      |  12    |  4   |    16     | 12  |  4  |    20    |   8   | 8    |    16     |  8  | 8   |    0     |  0   |
            bits  |      160      |  96    |  32  |    128    | 96  |  32 |    160   |   64  | 64   |    128    |  64 | 64  |    0     |  0   |
                                  >---------------<           >-----------<          >--------------<           >-----------<
            */
            fpacket := shl(96, L1Token0)
            // at this point, only the 96 upper bits are saved, 32 bits left to save
            fpacket := or(fpacket, shr(32, pairVoucherBalance0))
            mstore(add(payload, 0x40), fpacket)

            fpacket := shl(224, pairVoucherBalance0)
            fpacket := or(fpacket, shl(96, voucherDelta0))
            fpacket := or(fpacket, shr(32, balance0))
            mstore(add(payload, 0x60), fpacket)

            fpacket := shl(224, balance0)
            fpacket := or(fpacket, shl(64, L1Token1))
            fpacket := or(fpacket, shr(64, pairVoucherBalance1))
            mstore(add(payload, 0x80), fpacket)

            fpacket := shl(192, pairVoucherBalance1)
            fpacket := or(fpacket, shl(64, voucherDelta1))
            fpacket := or(fpacket, shr(64, balance1))
            mstore(add(payload, 0xA0), fpacket)

            fpacket := shl(192, balance1)
            mstore(add(payload, 0xC0), fpacket)
            // update free mem ptr
            mstore(0x40, add(payload, 0xe0))
        }
    }

    function decodeSyncToL1(bytes memory _payload)
        internal
        pure
        returns (uint16 syncID, SyncerMetadata memory sm, PartialSync memory pSyncA, PartialSync memory pSyncB)
    {
        assembly {
            let fpacket := mload(add(_payload, 0x20))
            //msgType := shr(253, fpacket)
            syncID := and(shr(237, fpacket), 0xFFFF)
            // syncer%
            mstore(sm, and(shr(223, fpacket), 0x3FFF))
            mstore(add(sm, 0x20), and(shr(63, fpacket), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            /*
            mem   |--------- 0x40 ---------|--------- 0x60 ---------|--------- 0x80 ---------|--------- 0xA0 ---------|--------- 0xC0 ---------|
            var   |      L1T0     | TFD0   | TFD0 |    EA0    | PB0 | PB0 |   L1T1   |  TFD1 | TFD1 |    EA1    | PB1 | PB1 |   0x00   | 0x00 |
            bytes |       20      |  12    |  4   |    16     | 12  |  4  |    20    |   8   | 8    |    16     |  8  | 8   |    0     |  0   |
            bits  |      160      |  96    |  32  |    128    | 96  |  32 |    160   |   64  | 64   |    128    |  64 | 64  |    0     |  0   |
                                  >---------------<           >-----------<          >--------------<           >-----------<
            */
            // psyncA
            mstore(pSyncA, shr(96, mload(add(_payload, 0x40))))
            mstore(add(pSyncA, 0x20), shr(128, mload(add(_payload, 0x54)))) // tokensForDove
            mstore(add(pSyncA, 0x40), shr(128, mload(add(_payload, 0x64)))) // earmarked
            mstore(add(pSyncA, 0x60), shr(128, mload(add(_payload, 0x74)))) // balance
            // psyncB
            mstore(pSyncB, shr(96, mload(add(_payload, 0x84)))) // token
            mstore(add(pSyncB, 0x20), shr(128, mload(add(_payload, 0x98))))
            mstore(add(pSyncB, 0x40), shr(128, mload(add(_payload, 0xA8))))
            mstore(add(pSyncB, 0x60), shr(128, mload(add(_payload, 0xB8))))
        }
    }

    /*##############################################################################################################################*/

    struct SyncToL2Payload {
        address token0;
        uint128 reserve0;
        uint128 reserve1;
    }

    function encodeSyncToL2(address token0, uint128 reserve0, uint128 reserve1) internal pure returns (bytes memory) {
        return abi.encode(SYNC_TO_L2, SyncToL2Payload(token0, reserve0, reserve1));
    }

    function decodeSyncToL2(bytes calldata _payload) internal pure returns (SyncToL2Payload memory) {
        (, SyncToL2Payload memory payload) = abi.decode(_payload, (uint256, SyncToL2Payload));
        return payload;
    }

    /*##############################################################################################################################*/

    struct VouchersBurnPayload {
        address user;
        uint128 amount0;
        uint128 amount1;
    }

    function encodeVouchersBurn(address user, uint128 amount0, uint128 amount1) internal pure returns (bytes memory) {
        return abi.encode(BURN_VOUCHERS, VouchersBurnPayload(user, amount0, amount1));
    }

    function decodeVouchersBurn(bytes calldata _payload) internal pure returns (VouchersBurnPayload memory) {
        (, VouchersBurnPayload memory vouchersBurnPayload) = abi.decode(_payload, (uint256, VouchersBurnPayload));
        return vouchersBurnPayload;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract FeesAccumulator {
    address owner;
    address token0;
    address token1;

    constructor(address _token0, address _token1) {
        owner = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    function take() public returns (uint256 fees0, uint256 fees1) {
        require(msg.sender == owner);
        ERC20 _token0 = ERC20(token0);
        ERC20 _token1 = ERC20(token1);
        fees0 = _token0.balanceOf(address(this));
        fees1 = _token1.balanceOf(address(this));
        SafeTransferLib.safeTransfer(_token0, owner, fees0);
        SafeTransferLib.safeTransfer(_token1, owner, fees1);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {SafeTransferLib as STL} from "solady/utils/SafeTransferLib.sol";

import {Voucher} from "./Voucher.sol";
import {FeesAccumulator} from "./FeesAccumulator.sol";

import "../hyperlane/HyperlaneClient.sol";
import "../hyperlane/TypeCasts.sol";

import "./interfaces/IPair.sol";
import "./interfaces/IStargateRouter.sol";
import "./interfaces/IL2Factory.sol";

import "../Codec.sol";

/// The AMM logic is taken from https://github.com/transmissions11/solidly/blob/master/contracts/BaseV1-core.sol

contract Pair is IPair, ReentrancyGuard, HyperlaneClient {
    /*###############################################################
                            STORAGE
    ###############################################################*/
    IL2Factory public factory;

    address public L1Target;

    ///@notice The bridged token0.
    address public token0;
    ///@dev This is NOT the token0 on L1 but the L1 address
    ///@dev of the token0 on L2.
    address public L1Token0;
    Voucher public voucher0;

    ///@notice The bridged token1.
    address public token1;
    address public L1Token1;
    Voucher public voucher1;

    uint128 public reserve0;
    uint128 public reserve1;
    uint256 public blockTimestampLast;
    uint256 public reserve0CumulativeLast;
    uint256 public reserve1CumulativeLast;

    FeesAccumulator public feesAccumulator;

    uint64 internal immutable decimals0;
    uint64 internal immutable decimals1;
    uint64 internal lastSyncTimestamp;
    uint16 internal syncID;

    IL2Factory.SGConfig internal sgConfig;

    ///@notice "reference" reserves on L1
    uint128 internal ref0;
    uint128 internal ref1;
    // amount of vouchers minted since last L1->L2 sync
    uint128 internal voucher0Delta;
    uint128 internal voucher1Delta;

    uint256 constant FEE = 300;

    /*###############################################################
                            CONSTRUCTOR
    ###############################################################*/
    constructor(
        address _token0,
        address _L1Token0,
        address _token1,
        address _L1Token1,
        IL2Factory.SGConfig memory _sgConfig,
        address _gasMaster,
        address _mailbox,
        address _L1Target
    ) HyperlaneClient(_gasMaster, _mailbox, address(0)) {
        factory = IL2Factory(msg.sender);

        L1Target = _L1Target;

        token0 = _token0;
        L1Token0 = _L1Token0;
        token1 = _token1;
        L1Token1 = _L1Token1;

        sgConfig = _sgConfig;

        ERC20 token0_ = ERC20(_token0);
        ERC20 token1_ = ERC20(_token1);

        decimals0 = uint64(10 ** token0_.decimals());
        decimals1 = uint64(10 ** token1_.decimals());

        /// @dev Assume one AMM per L2.
        voucher0 = new Voucher(
            string.concat("v", token0_.name()),
            string.concat("v", token0_.symbol()),
            token0_.decimals()
        );
        voucher1 = new Voucher(
            string.concat("v", token1_.name()),
            string.concat("v", token1_.symbol()),
            token1_.decimals()
        );
        feesAccumulator = new FeesAccumulator(_token0, _token1);

        lastSyncTimestamp = uint64(block.timestamp);
    }

    /*###############################################################
                            AMM LOGIC
    ###############################################################*/

    function getReserves()
        public
        view
        override
        returns (uint128 _reserve0, uint128 _reserve1, uint256 _blockTimestampLast)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function balance0() public view returns (uint256) {
        return ref0 + STL.balanceOf(token0, address(this)) - voucher0Delta;
    }

    function balance1() public view returns (uint256) {
        return ref1 + STL.balanceOf(token1, address(this)) - voucher1Delta;
    }

    // Accrue fees on token0
    function _update0(uint256 amount) internal {
        STL.safeTransfer(token0, address(feesAccumulator), amount);
    }

    // Accrue fees on token1
    function _update1(uint256 amount) internal {
        STL.safeTransfer(token1, address(feesAccumulator), amount);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint256 _balance0, uint256 _balance1, uint256 _reserve0, uint256 _reserve1) internal {
        uint256 blockTimestamp = block.timestamp;
        uint256 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            reserve0CumulativeLast += _reserve0 * timeElapsed;
            reserve1CumulativeLast += _reserve1 * timeElapsed;
        }

        reserve0 = uint128(_balance0);
        reserve1 = uint128(_balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices()
        public
        view
        override
        returns (uint256 reserve0Cumulative, uint256 reserve1Cumulative, uint256 blockTimestamp)
    {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) = getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint256 timeElapsed = blockTimestamp - _blockTimestampLast;
            reserve0Cumulative += _reserve0 * timeElapsed;
            reserve1Cumulative += _reserve1 * timeElapsed;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data)
        external
        override
        nonReentrant
    {
        //require(!BaseV1Factory(factory).isPaused());
        if (!(amount0Out > 0 || amount1Out > 0)) revert InsufficientOutputAmount();

        (uint128 _reserve0, uint128 _reserve1) = (reserve0, reserve1);
        if (!(amount0Out < _reserve0 && amount1Out < _reserve1)) revert InsufficientLiquidity();

        uint256 _balance0;
        uint256 _balance1;
        {
            (address _token0, address _token1) = (token0, token1);
            _balance0 = ERC20(_token0).balanceOf(address(this));
            _balance1 = ERC20(_token1).balanceOf(address(this));
            // scope for _token{0,1}, avoids stack too deep errors
            if (!(to != _token0 && to != _token1)) {
                revert InvalidTo();
            }
            // optimistically mints vouchers
            if (amount0Out > 0) {
                // delta is what we have to transfer
                // difference between our token balance and what user needs
                (uint256 toSend, uint256 toMint) =
                    _balance0 >= amount0Out ? (amount0Out, 0) : (_balance0, amount0Out - _balance0);
                if (voucher0.totalSupply() + toMint > (balance0() * factory.voucherLimiter()) / 10000) revert Voucher0LimitReached();
                if (toSend > 0) STL.safeTransfer(_token0, to, toSend);
                if (toMint > 0) {
                    voucher0.mint(to, toMint);
                    voucher0Delta += uint128(toMint);
                }
            }
            // optimistically mints vouchers
            if (amount1Out > 0) {
                (uint256 toSend, uint256 toMint) =
                    _balance1 >= amount1Out ? (amount1Out, 0) : (_balance1, amount1Out - _balance1);
                if (voucher1.totalSupply() + toMint > (balance1() * factory.voucherLimiter()) / 10000) revert Voucher1LimitReached();
                if (toSend > 0) STL.safeTransfer(_token1, to, toSend);
                if (toMint > 0) {
                    voucher1.mint(to, toMint);
                    voucher1Delta += uint128(toMint);
                }
            }
            //if (data.length > 0) IBaseV1Callee(to).hook(msg.sender, amount0Out, amount1Out, data);
            _balance0 = balance0();
            _balance1 = balance1();
        }
        uint256 amount0In = _balance0 > _reserve0 - amount0Out ? _balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = _balance1 > _reserve1 - amount1Out ? _balance1 - (_reserve1 - amount1Out) : 0;
        if (!(amount0In > 0 || amount1In > 0)) revert InsufficientInputAmount();

        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            if (amount0In > 0) _update0(amount0In / FEE); // accrue fees for token0 and move them out of pool
            if (amount1In > 0) _update1(amount1In / FEE); // accrue fees for token1 and move them out of pool
            _balance0 = balance0(); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - amountIn/ 10000, but doing balanceOf again as safety check
            _balance1 = balance1();
            // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
            if (!(_k(_balance0, _balance1) >= _k(_reserve0, _reserve1))) revert kInvariant();
        }

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force reserves to match balances
    function sync() external nonReentrant {
        _update(balance0(), balance1(), reserve0, reserve1);
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (x0 * ((((y * y) / 1e18) * y) / 1e18)) / 1e18 + (((((x0 * x0) / 1e18) * x0) / 1e18) * y) / 1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(uint256 x0, uint256 xy, uint256 y) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y);
            if (k < xy) {
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function getAmountOut(uint256 amountIn, address tokenIn) external view override returns (uint256) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        amountIn -= amountIn / FEE; // remove fee from amount received
        return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    function _getAmountOut(uint256 amountIn, address tokenIn, uint256 _reserve0, uint256 _reserve1)
        internal
        view
        returns (uint256)
    {
        uint256 xy = _k(_reserve0, _reserve1);
        _reserve0 = (_reserve0 * 1e18) / decimals0;
        _reserve1 = (_reserve1 * 1e18) / decimals1;
        (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
        amountIn = tokenIn == token0 ? (amountIn * 1e18) / decimals0 : (amountIn * 1e18) / decimals1;
        uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
        return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
    }

    function _k(uint256 x, uint256 y) internal view returns (uint256) {
        uint256 _x = (x * 1e18) / decimals0;
        uint256 _y = (y * 1e18) / decimals1;
        uint256 _a = (_x * _y) / 1e18;
        uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
        return (_a * _b) / 1e18; // x3y+y3x >= k
    }

    /*###############################################################
                            CROSS-CHAIN LOGIC
    ###############################################################*/

    function yeetVouchers(uint256 amount0, uint256 amount1) external override nonReentrant {
        voucher0.transferFrom(msg.sender, address(this), amount0);
        voucher1.transferFrom(msg.sender, address(this), amount1);

        STL.safeTransfer(token0, msg.sender, amount0);
        STL.safeTransfer(token1, msg.sender, amount1);

        emit VouchersYeeted(msg.sender, amount0, amount1);
    }

    function getSyncerPercentage() external view returns (uint64) {
        // reaches 50% over 24h => 0.06 bps per second
        uint256 bps = ((block.timestamp - lastSyncTimestamp) * 6) / 100;
        bps = bps >= 5000 ? 5000 : bps;
        return uint64(bps);
    }

    /// @notice Syncs to the L1.
    /// @dev Dependent on SG.
    function syncToL1(uint256 sgFee, uint256 hyperlaneFee) external payable override {
        if (msg.value < (sgFee * 2) + hyperlaneFee) revert MsgValueTooLow();

        address _token0 = token0;
        address _token1 = token1;
        // balance before getting accumulated fees
        uint256 _balance0 = STL.balanceOf(_token0, address(this));
        uint256 _balance1 = STL.balanceOf(_token1, address(this));

        uint128 pairVoucher0Balance = uint128(voucher0.balanceOf(address(this)));
        uint128 pairVoucher1Balance = uint128(voucher1.balanceOf(address(this)));

        // Sends the HL message first to avoid stack too deep!
        {
            uint32 destDomain = factory.destDomain();
            bytes memory payload = Codec.encodeSyncToL1(
                syncID,
                L1Token0,
                pairVoucher0Balance,
                voucher0Delta - pairVoucher0Balance,
                _balance0,
                L1Token1,
                pairVoucher1Balance,
                voucher1Delta - pairVoucher1Balance,
                _balance1,
                msg.sender,
                this.getSyncerPercentage()
            );
            // send HL message
            bytes32 id = mailbox.dispatch(destDomain, TypeCasts.addressToBytes32(L1Target), payload);
            hyperlaneGasMaster.payForGas{value: hyperlaneFee}(id, destDomain, 500000, address(msg.sender));
        }

        (uint256 fees0, uint256 fees1) = feesAccumulator.take();
        uint16 destChainId = factory.destChainId();
        IStargateRouter stargateRouter = IStargateRouter(factory.stargateRouter());

        // swap token0
        STL.safeApprove(_token0, address(stargateRouter), _balance0 + fees0);
        stargateRouter.swap{value: sgFee}(
            destChainId,
            sgConfig.srcPoolId0,
            sgConfig.dstPoolId0,
            payable(msg.sender),
            _balance0 + fees0,
            _balance0,
            IStargateRouter.lzTxObj(50000, 0, "0x"),
            abi.encodePacked(L1Target),
            abi.encode(syncID)
        );
        reserve0 = ref0 + uint128(_balance0) - voucher0Delta - pairVoucher0Balance;

        // swap token1
        STL.safeApprove(_token1, address(stargateRouter), _balance1 + fees1);
        stargateRouter.swap{value: sgFee}(
            destChainId,
            sgConfig.srcPoolId1,
            sgConfig.dstPoolId1,
            payable(msg.sender),
            _balance1 + fees1,
            _balance1,
            IStargateRouter.lzTxObj(50000, 0, "0x"),
            abi.encodePacked(L1Target),
            abi.encode(syncID)
        );
        reserve1 = ref1 + uint128(_balance1) - voucher1Delta - pairVoucher1Balance;

        ref0 = reserve0;
        ref1 = reserve1;
        voucher0Delta = 0;
        voucher1Delta = 0;
        syncID++;
        lastSyncTimestamp = uint64(block.timestamp);

        emit SyncToL1Initiated(_balance0, _balance1, fees0, fees1);
    }

    /// @notice Allows user to burn his L2 vouchers to get the L1 tokens.
    /// @param amount0 The amount of voucher0 to burn.
    /// @param amount1 The amount of voucher1 to burn.
    function burnVouchers(uint256 amount0, uint256 amount1) external payable override nonReentrant {
        uint32 destDomain = factory.destDomain();
        // tell L1 that vouchers been burned
        if (!(amount0 > 0 || amount1 > 0)) revert NoVouchers();

        if (amount0 > 0) voucher0.burn(msg.sender, amount0);
        if (amount1 > 0) voucher1.burn(msg.sender, amount1);
        (amount0, amount1) = _getL1Ordering(amount0, amount1);
        bytes memory payload = Codec.encodeVouchersBurn(msg.sender, uint128(amount0), uint128(amount1));
        bytes32 id = mailbox.dispatch(destDomain, TypeCasts.addressToBytes32(L1Target), payload);
        hyperlaneGasMaster.payForGas{value: msg.value}(id, destDomain, 100000, address(msg.sender));

        emit VouchersBurnInitiated(msg.sender, amount0, amount1);
    }

    function handle(uint32 origin, bytes32 sender, bytes calldata payload) external onlyMailbox {
        uint32 destDomain = factory.destDomain();
        if (origin != destDomain) revert WrongOrigin();

        if (TypeCasts.addressToBytes32(L1Target) != sender) revert NotDove();

        uint256 messageType = abi.decode(payload, (uint256));
        if (messageType == Codec.SYNC_TO_L2) {
            Codec.SyncToL2Payload memory sp = Codec.decodeSyncToL2(payload);
            _syncFromL1(sp);
        }
    }

    function _syncFromL1(Codec.SyncToL2Payload memory sp) internal {
        (reserve0, reserve1) = sp.token0 == L1Token0 ? (sp.reserve0, sp.reserve1) : (sp.reserve1, sp.reserve0);
        ref0 = reserve0;
        ref1 = reserve1;

        emit SyncedFromL1(reserve0, reserve1);
    }

    function _getL1Ordering(uint256 amount0, uint256 amount1) internal view returns (uint256, uint256) {
        if (L1Token0 < L1Token1) {
            return (amount0, amount1);
        } else {
            return (amount1, amount0);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice A voucher ERC20.
contract Voucher is ERC20 {
    error OnlyOwner();

    address public owner;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        if (msg.sender != owner) revert OnlyOwner();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        if (msg.sender != owner) revert OnlyOwner();
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

interface IL2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    error IdenticalAddress();
    error ZeroAddress();
    error ZeroAddressOrigin();
    error PairExists();
    error NewVoucherLimiterOutOfRange();

    struct SGConfig {
        uint16 srcPoolId0;
        uint16 srcPoolId1;
        uint16 dstPoolId0;
        uint16 dstPoolId1;
    }

    function destDomain() external view returns (uint32);
    function destChainId() external view returns (uint16);
    function stargateRouter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function pairCodeHash() external pure returns (bytes32);
    function voucherLimiter() external view returns (uint16);
    
    function createPair(
        address tokenA,
        address tokenB,
        SGConfig calldata sgConfig,
        address L1TokenA,
        address L1TokenB,
        address L1Target
    ) external returns (address pair);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

interface IPair {
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint128 reserve0, uint128 reserve1);
    event VouchersYeeted(address sender, uint256 amount0, uint256 amount1);
    event VouchersBurnInitiated(address sender, uint256 amount0, uint256 amount1);
    event SyncToL1Initiated(uint256 amount0, uint256 amount1, uint256 fees0, uint256 fees1);
    event SyncedFromL1(uint128 reserve0, uint128 reserve1);

    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error InvalidTo();
    error InsufficientInputAmount();
    error kInvariant();
    error NoVouchers();
    error MsgValueTooLow();
    error WrongOrigin();
    error NotDove();
    error Voucher0LimitReached();
    error Voucher1LimitReached();

    function token0() external view returns (address _token0);
    function token1() external view returns (address _token1);
    function getReserves() external view returns (uint128 reserve0, uint128 reserve1, uint256 blockTimestampLast);
    function balance0() external view returns (uint256);
    function balance1() external view returns (uint256);
    function currentCumulativePrices()
        external
        view
        returns (uint256 reserve0Cumulative, uint256 reserve1Cumulative, uint256 blockTimestamp);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function sync() external;
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256 amountOut);
    function yeetVouchers(uint256 amount0, uint256 amount1) external;
    function syncToL1(uint256 sgFee, uint256 hyperlaneFee) external payable;
    function burnVouchers(uint256 amount0, uint256 amount1) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress)
        external
        payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {Owned} from "solmate/auth/Owned.sol";

import "./IMessageRecipient.sol";
import "./IMailbox.sol";
import "./IInterchainGasPaymaster.sol";

abstract contract HyperlaneClient is IMessageRecipient, Owned {
    IInterchainGasPaymaster public hyperlaneGasMaster;
    IMailbox public mailbox;

    modifier onlyMailbox() {
        require(msg.sender == address(mailbox), "NOT MAILBOX");
        _;
    }

    constructor(address _hyperlaneGasMaster, address _mailbox, address _owner) Owned(_owner) {
        hyperlaneGasMaster = IInterchainGasPaymaster(_hyperlaneGasMaster);
        mailbox = IMailbox(_mailbox);
    }

    function setHyperlaneGasMaster(address _hyperlaneGasMaster) external onlyOwner {
        hyperlaneGasMaster = IInterchainGasPaymaster(_hyperlaneGasMaster);
    }

    function setMailbox(address _mailbox) external onlyOwner {
        mailbox = IMailbox(_mailbox);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    function payForGas(bytes32 _messageId, uint32 _destinationDomain, uint256 _gasAmount, address _refundAddress)
        external
        payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

interface IMailbox {
    function localDomain() external view returns (uint32);

    function dispatch(uint32 _destinationDomain, bytes32 _recipientAddress, bytes calldata _messageBody)
        external
        returns (bytes32);

    function process(bytes calldata _metadata, bytes calldata _message) external;

    function count() external view returns (uint32);

    function root() external view returns (bytes32);

    function latestCheckpoint() external view returns (bytes32, uint32);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library TypeCasts {
    // treat it as a null-terminated string of max 32 bytes
    function coerceString(bytes32 _buf) internal pure returns (string memory _newStr) {
        uint8 _slen = 0;
        while (_slen < 32 && _buf[_slen] != 0) {
            _slen++;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            _newStr := mload(0x40)
            mstore(0x40, add(_newStr, 0x40)) // may end up with extra
            mstore(_newStr, _slen)
            mstore(add(_newStr, 0x20), _buf)
        }
    }

    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}