/**
 *Submitted for verification at Arbiscan.io on 2023-10-31
*/

// Sources flattened with hardhat v2.17.2 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @chainlink/contracts-ccip/src/v0.8/ccip/libraries/[email protected]

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

// End consumer library.
library Client {
  struct EVMTokenAmount {
    address token; // token address on the local chain.
    uint256 amount; // Amount of tokens.
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source.
    uint64 sourceChainSelector; // Source chain selector.
    bytes sender; // abi.decode(sender) if coming from an EVM chain.
    bytes data; // payload sent in original message.
    EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
  }

  // If extraArgs is empty bytes, the default is 200k gas limit and strict = false.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // extraArgs will evolve to support new features
  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR BETA TESTING
    bool strict; // See strict sequencing details below.
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}


// File @chainlink/contracts-ccip/src/v0.8/ccip/interfaces/[email protected]

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
  /// @notice Called by the Router to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution.
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the OffRampRouter
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}


// File @chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/utils/introspection/[email protected]

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
    * @dev Returns true if this contract implements the interface defined by
    * `interfaceId`. See the corresponding
    * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    * to learn more about how these ids are created.
    *
    * This function call must use less than 30 000 gas.
    */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @chainlink/contracts-ccip/src/v0.8/ccip/applications/[email protected]

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
  address internal i_router;

  constructor(address router) {
    if (router == address(0)) revert InvalidRouter(address(0));
    i_router = router;
  }

  /// @notice IERC165 supports an interfaceId
  /// @param interfaceId The interfaceId to check
  /// @return true if the interfaceId is supported
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  /// @inheritdoc IAny2EVMMessageReceiver
  function ccipReceive(Client.Any2EVMMessage calldata message) external virtual override onlyRouter {
    _ccipReceive(message);
  }

  /// @notice Override this function in your implementation.
  /// @param message Any2EVMMessage
  function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;

  /////////////////////////////////////////////////////////////////////
  // Plumbing
  /////////////////////////////////////////////////////////////////////

  /// @notice Return the current router
  /// @return i_router address
  function getRouter() public view returns (address) {
    return address(i_router);
  }

  error InvalidRouter(address router);

  /// @dev only calls from the set router are accepted.
  modifier onlyRouter() {
    if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
    _;
  }
}


// File @chainlink/contracts-ccip/src/v0.8/ccip/interfaces/[email protected]

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainSelector The chain to check.
  /// @return supported is true if it is supported, false if not.
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chainSelector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns guaranteed execution fee for the specified message
  /// delivery to destination chain
  /// @dev returns 0 fee on invalid message.
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}


// File @openzeppelin/contracts/access/[email protected]

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts/utils/[email protected]

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/utils/introspection/[email protected]

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}


// File @openzeppelin/contracts/access/[email protected]

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File @openzeppelin/contracts/access/[email protected]

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interface/IERC1271.sol

interface IERC1271 {
  // bytes4(keccak256("isValidSignature(bytes32,bytes)")
  // bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}


// File contracts/interface/IKlasterGatewayWallet.sol

interface IKlasterGatewayWallet {

    function execute(
        address destination,
        uint256 value,
        bytes memory data
    ) external returns (bool, address);

    function executeWithData(
        address destination,
        uint256 value,
        bytes memory data,
        bytes32 extraData
    ) external returns (bool, address);

}


// File contracts/gateway/KlasterGatewayWallet.sol

contract KlasterGatewayWallet is Ownable, IERC1271, IKlasterGatewayWallet {

    address public klasterGatewaySingleton;

    mapping (bytes32 => bool) public signatures;

    constructor(address _owner) {
        klasterGatewaySingleton = msg.sender;
        _transferOwnership(_owner);
    }

    function executeWithData(
        address destination,
        uint256 value,
        bytes memory data,
        bytes32 extraData
    ) external returns (bool, address) {
        if (destination == address(0)) { // contract deployment
            if (extraData == "") { // deploy using create()
                return (true, _performCreate(value, data));
            } else { // deploy using create2()
                return (true, _performCreate2(value, data, extraData));
            }
        } else { // transaction execution (use extra data as contract wallet signature as per ERC-1271)
            if (extraData != "") { signatures[extraData] = true; }
            return execute(destination, value, data);
        }
    }

    function execute(
        address destination,
        uint256 value,
        bytes memory data
    ) public returns (bool, address) {
        require(
            msg.sender == klasterGatewaySingleton || msg.sender == owner(),
            "Not an owner!"
        );
        bool result;
        uint dataLength = data.length;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return (result, address(0));
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue) {
        if (signatures[_hash]) {
            magicValue = 0x1626ba7e; // ERC1271: valid signature = bytes4(keccak256("isValidSignature(bytes32,bytes)")
        }
    }

    function _performCreate(
        uint256 value,
        bytes memory deploymentData
    ) internal returns (address newContract) {
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            newContract := create(value, add(deploymentData, 0x20), mload(deploymentData))
        }
        /* solhint-enable no-inline-assembly */
        require(newContract != address(0), "Could not deploy contract");
    }

    function _performCreate2(
        uint256 value,
        bytes memory deploymentData,
        bytes32 salt
    ) internal returns (address newContract) {
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            newContract := create2(value, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        /* solhint-enable no-inline-assembly */
        require(newContract != address(0), "Could not deploy contract");
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}

}


// File contracts/interface/IKlasterGatewaySingleton.sol

interface IKlasterGatewaySingleton {

    /************************** EVENTS **************************/

    // Event emitted when a new gateway wallet instance has been deployed.
    event WalletDeploy(
        address indexed owner,
        address gatewayWallet
    );
    
    // Event emitted when a message is sent to another chain.
    event SendRTC(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        address indexed caller, // Wallet initiating the RTC
        uint64 destinationChainSelector, // The chain selector of the destination chain.
        uint64 execChainSelector, // The chain selector of the execution chain.
        address targetContract, // Remote contract to execute on dest chain
        bytes32 extraData, // Message hash used for ERC-1271 or salt used for create2
        address feeToken, // the token address used to pay CCIP fees.
        uint256 ccipfees, // The fees paid for sending the CCIP message.
        uint256 totalFees // Total fees (ccip + platform fee)
    );

    // Event emitted when a message is received from another chain.
    event ReceiveRTC(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed sourceChainSelector, // The chain selector of the destination chain.
        address caller, // Wallet initiating the RTC.
        address targetContract, // Remote contract to execute on dest chain,
        bytes32 extraData // Message hash used for ERC-1271 or salt used for create2
    );

    // Event emitted when any gateway wallet action gets executed
    event Execute(
        address indexed caller,
        address indexed gatewayWallet,
        address indexed destination,
        bool status,
        address contractDeployed,
        bytes32 extraData
    );

    /************************** WRITE **************************/

    function deploy(string memory salt) external returns (address);

    function batchExecute(
        uint64[][] memory execChainSelectors,
        string[] memory salt,
        address[] memory destination,
        uint256[] memory value,
        bytes[] memory data,
        uint256[] memory gasLimit,
        bytes32[] memory extraData
    ) external payable returns (bool[] memory, address[] memory, bytes32[] memory);

    function execute(
        uint64[] memory execChainSelectors,
        string memory salt,
        address destination,
        uint value,
        bytes memory data,
        uint256 gasLimit,
        bytes32 extraData
    ) external payable returns (bool, address, bytes32);

    /************************** READ **************************/

    function getDeployedWallets(address owner) external view returns (address[] memory);
    
    function calculateBatchExecuteFee(
        address caller,
        uint64[][] memory execChainSelectors,
        string[] memory salt,
        address[] memory destination,
        uint256[] memory value,
        bytes[] memory data,
        uint256[] memory gasLimit,
        bytes32[] memory extraData
    ) external view returns (uint256);

    function calculateExecuteFee(
        address caller,
        uint64[] memory execChainSelectors,
        string memory salt,
        address destination,
        uint value,
        bytes memory data,
        uint256 gasLimit,
        bytes32 extraData
    ) external view returns (uint256);

    function calculateAddress(address owner, string memory salt) external view returns (address);

    function calculateCreate2Address(
        address owner,
        string memory salt,
        bytes memory byteCode,
        bytes32 create2Salt
    ) external view returns (address);

}


// File contracts/interface/IOwnable.sol

interface IOwnable {
    function owner() external view returns (address);
}


// File contracts/gateway/KlasterGatewaySingleton.sol

contract KlasterGatewaySingleton is IKlasterGatewaySingleton, CCIPReceiver, AccessControl {

    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant HARVEST_MANAGER_ROLE = keccak256("HARVEST_MANAGER_ROLE");
    bytes32 public constant CCIP_MANAGER_ROLE = keccak256("CCIP_MANAGER_ROLE");

    uint256 public feePercentage; // percentage fee on top of the ccip fees (modifiable by the owner)
    uint64 public thisChainSelector; // current chain selector
    uint64 public relayerChainSelector; // relayer chain selector (sepolia for testnet, eth for mainnet)
    
    mapping (address => bool) public deployed;
    mapping (address => uint64) public controllingChains; // gateway wallet => controlling chain id
    mapping (address => string) public salts; // gateway wallet => salt
    mapping (address => address[]) public instances; // user => gateway wallet[]

    constructor(
        address _sourceRouter,
        uint64 _thisChainSelector,
        uint64 _relayerChainSelector,
        address _roleManager,
        address _ccipManager,
        address _harvestManager,
        address _feeManager,
        uint256 _feePercentage
    ) CCIPReceiver(_sourceRouter) {
        thisChainSelector = _thisChainSelector;
        relayerChainSelector = _relayerChainSelector;
        feePercentage = _feePercentage;
        _grantRole(DEFAULT_ADMIN_ROLE, _roleManager);
        _grantRole(FEE_MANAGER_ROLE, _feeManager);
        _grantRole(HARVEST_MANAGER_ROLE, _harvestManager);
        _grantRole(CCIP_MANAGER_ROLE, _ccipManager);

        // sanity checks
        require(
            _relayerChainSelector == _thisChainSelector ||
            IRouterClient(getRouter()).isChainSupported(relayerChainSelector),
            "Invalid relayer chain configuration."
        );
        require(_feeManager != address(0), "Fee manager is 0x0");
        require(_ccipManager != address(0), "CCIP manager is 0x0");
    }

    function deploy(string memory salt) public override returns (address) {
       return _deploy(msg.sender, salt, thisChainSelector);
    }

    /***
     * FEE_MANAGER FUNCTIONS (SENSITIVE)
     * 
     * Append only. Cant break anything or shut down the service.
     * KlasterGatewayWallet wallets will always work and in that sense it's permissionless.
     * The only two things a fee manager can affect and change post deployment are:
     *     1) Update platform fee - CAPPED TO 100% of the CCIP fee (!)
     *     2) Withdraw platform fee earnings
     */
    function updateFee(uint256 _feePercentage) external {
        require(hasRole(FEE_MANAGER_ROLE, msg.sender), "Caller is not a fee manager.");
        require(_feePercentage <= 100, "Platform fee is capped to 100% of the CCIP fee.");
        feePercentage = _feePercentage;
    }

    function withdraw(uint256 amount) external {
        require(hasRole(HARVEST_MANAGER_ROLE, msg.sender), "Caller is not a harvest manager.");
        payable(msg.sender).transfer(amount);
    }

    /***
     * CCIP_MANAGER FUNCTIONS (SENSITIVE)
     * 
     * CCIP manager is the only address that can update the router addresses.
     * This is a temporary role to be used only once. Chainlink's CCIP team is going to deploy
     * new router addresses after the GA launch, and this function will be used to store the new
     * router address and replace the old ones. After the update is complete, CCIP manager will renounce
     * its role.
     */
    function updateRouter(address _newRouterAddress) external {
        require(hasRole(CCIP_MANAGER_ROLE, msg.sender), "Caller is not a ccip manager.");
        i_router = _newRouterAddress;
    }

    /************ PUBLIC WRITE FUNCTIONS ************/

    function batchExecute(
        uint64[][] memory execChainSelectors,
        string[] memory salt,
        address[] memory destination,
        uint256[] memory value,
        bytes[] memory data,
        uint256[] memory gasLimit,
        bytes32[] memory extraData
    ) external payable override returns (bool[] memory success, address[] memory contractDeployed, bytes32[] memory messageId) {
        success = new bool[](execChainSelectors.length);
        contractDeployed = new address[](execChainSelectors.length);
        messageId = new bytes32[](execChainSelectors.length);
        for (uint256 i = 0; i < execChainSelectors.length; i++) {
            (success[i], contractDeployed[i], messageId[i]) = execute(
                execChainSelectors[i],
                salt[i],
                destination[i],
                value[i],
                data[i],
                gasLimit[i],
                extraData[i]
            );
        }
    }

    function execute(
        uint64[] memory execChainSelectors,
        string memory salt,
        address destination,
        uint256 value,
        bytes memory data,
        uint256 gasLimit,
        bytes32 extraData
    ) public payable override returns (bool success, address contractDeployed, bytes32 messageId) {
        
        if (destination != address(0) && extraData != "") { // if executing contract call (destination != 0) and extra data exists, then verify if the extra data is a valid signature
            require(
                IERC1271(msg.sender).isValidSignature(
                    extraData,
                    ""
                ) == 0x1626ba7e, // ERC1271: valid signature = bytes4(keccak256("isValidSignature(bytes32,bytes)")
                "Invalid signature."
            );
        }

        for (uint256 i = 0; i < execChainSelectors.length; i++) {
            (success, contractDeployed, messageId) = _execute(
                ExecutionData(
                    msg.sender,
                    thisChainSelector,
                    execChainSelectors[i],
                    salt,
                    destination,
                    value,
                    data,
                    gasLimit,
                    extraData,
                    true
                )
            );
        }
    }

    /************ PUBLIC READ FUNCTIONS ************/

    function getDeployedWallets(address owner) external view override returns (address[] memory) {
        return instances[owner];
    }

    function calculateBatchExecuteFee(
        address caller,
        uint64[][] memory execChainSelectors,
        string[] memory salt,
        address[] memory destination,
        uint256[] memory value,
        bytes[] memory data,
        uint256[] memory gasLimit,
        bytes32[] memory extraData
    ) external view override returns (uint256 totalFee) {
        for (uint256 i = 0; i < execChainSelectors.length; i++) {
            totalFee += calculateExecuteFee(
                caller,
                execChainSelectors[i],
                salt[i],
                destination[i],
                value[i],
                data[i],
                gasLimit[i],
                extraData[i]
            );
        }
    }

    function calculateExecuteFee(
        address caller,
        uint64[] memory execChainSelectors,
        string memory salt,
        address destination,
        uint256 value,
        bytes memory data,
        uint256 gasLimit,
        bytes32 extraData
    ) public view override returns (uint256 totalFee) {
        for (uint256 i = 0; i < execChainSelectors.length; i++) {
            uint64 execChainSelector = execChainSelectors[i];
            if (execChainSelector != thisChainSelector) {
                // Get available lane    
                uint64 destChainSelector = _getDestChainSelector(execChainSelector);
        
                // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
                Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
                    address(this),
                    abi.encode(caller, thisChainSelector, execChainSelector, salt, destination, value, data, gasLimit, extraData),
                    address(0),
                    gasLimit
                );

                (, uint256 fee) = _getFees(destChainSelector, execChainSelector, evm2AnyMessage);
                totalFee += fee;
            }
        }
    }

    function calculateAddress(address owner, string memory salt) public view override returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), keccak256(abi.encodePacked(owner, salt)), keccak256(_getBytecode(owner))
            )
        );
        return address(uint160(uint(hash)));
    }

    function calculateCreate2Address(
        address owner,
        string memory salt,
        bytes memory byteCode,
        bytes32 create2Salt
    ) external view override returns (address) {
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                calculateAddress(owner, salt),
                create2Salt,
                keccak256(byteCode)
            )
        );
        return address(uint160(uint256(hash_)));
    }

    /************ INTERNAL FUNCTIONS ************/
    
    struct ExecutionData {
        address caller;
        uint64 sourceChainSelector;
        uint64 execChainSelector;
        string salt;
        address destination;
        uint256 value;
        bytes data;
        uint256 gasLimit;
        bytes32 extraData;
        bool feeEnabled;
    }
    function _execute(
        ExecutionData memory execData
    ) internal returns (bool success, address contractDeployed, bytes32 messageId) {
        if (execData.execChainSelector == thisChainSelector) { // execute on this chain
            (success, contractDeployed) = _executeOnWallet(
                execData.sourceChainSelector,
                execData.caller,
                execData.salt,
                execData.destination,
                execData.value,
                execData.data,
                execData.extraData
            );
        } else { // remote execution on target chain via CCIP

            // Get available lane  
            uint64 destChainSelector = _getDestChainSelector(execData.execChainSelector);

            // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
            Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
                address(this),
                abi.encode(
                    execData.caller,
                    execData.sourceChainSelector,
                    execData.execChainSelector,
                    execData.salt,
                    execData.destination,
                    execData.value,
                    execData.data,
                    execData.gasLimit,
                    execData.extraData
                ),
                address(0),
                execData.gasLimit
            );

            (uint256 ccipFees, uint256 totalFee) = _getFees(
                destChainSelector,
                execData.execChainSelector,
                evm2AnyMessage
            );

            // Take into account platform fee
            if (execData.feeEnabled) {
                require(msg.value >= totalFee, "Ether amount too low. Send more ether to execute call.");
            }
            
            success = true;
            messageId = IRouterClient(getRouter()).ccipSend{value: ccipFees}(
                destChainSelector,
                evm2AnyMessage
            );

            emit SendRTC(
                    messageId,
                    execData.caller,
                    destChainSelector,
                    execData.execChainSelector,
                    execData.destination,
                    execData.extraData,
                    address(0),
                    ccipFees,
                    totalFee
            );
        }
    }

    // executes given action on the callers gateway wallet
    function _executeOnWallet(
        uint64 sourceChainSelector,
        address caller,
        string memory salt,
        address destination,
        uint256 value,
        bytes memory data,
        bytes32 extraData
    ) internal returns (bool status, address contractDeployed) {
        address walletInstanceAddress = calculateAddress(caller, salt);
        if (!deployed[walletInstanceAddress]) {
            _deploy(caller, salt, sourceChainSelector);
        } else {
            require(
                sourceChainSelector == controllingChains[walletInstanceAddress],
                "Can only execute from controlling chain."
            );
        }
        
        IKlasterGatewayWallet walletInstance = IKlasterGatewayWallet(walletInstanceAddress);
        
        require(IOwnable(walletInstanceAddress).owner() == caller, "Not an owner!");
        (status, contractDeployed) = walletInstance.executeWithData(destination, value, data, extraData);
        
        emit Execute(caller, walletInstanceAddress, destination, status, contractDeployed, extraData);
    }

    // deploys new gateway wallet for given owner and salt
    function _deploy(
        address owner,
        string memory salt,
        uint64 sourceChainSelector
    ) private returns (address walletInstance) {
        require(!deployed[calculateAddress(owner, salt)], "Already deployed! Use different salt!");
        
        bytes memory bytecode = _getBytecode(owner);
        bytes32 calculatedSalt = keccak256(abi.encodePacked(owner, salt));
        assembly {
            walletInstance := create2(0, add(bytecode, 32), mload(bytecode), calculatedSalt)
        }
        deployed[walletInstance] = true;
        salts[walletInstance] = salt;
        controllingChains[walletInstance] = sourceChainSelector;
        instances[owner].push(walletInstance);
        
        emit WalletDeploy(owner, walletInstance);
    }

    // get the bytecode of the contract KlasterGatewayWallet with encoded constructor
    function _getBytecode(address owner) private pure returns (bytes memory) {
        bytes memory bytecode = type(KlasterGatewayWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(owner));
    }

    // @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for sending arbitrary bytes cross chain.
    /// @param _receiver The address of the receiver.
    /// @param _message The bytes data to be sent.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @param _gasLimit Gas limit.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address _receiver,
        bytes memory _message,
        address _feeTokenAddress,
        uint256 _gasLimit
    ) internal pure returns (Client.EVM2AnyMessage memory) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: _message, // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: _gasLimit, strict: false})
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
        return evm2AnyMessage;
    }

    /// handle received execution message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    )
        internal
        override
    {
        require(
            abi.decode(any2EvmMessage.sender, (address)) == address(this),
            "Only official KlasterGatewaySingleton can send CCIP messages."
        );

        (
            address caller,
            uint64 sourceChainSelector,
            uint64 execChainSelector,
            string memory salt,
            address destination,
            uint256 value,
            bytes memory data,
            uint256 gasLimit,
            bytes32 extraData
        ) = abi.decode(
            any2EvmMessage.data,
            (
                address,
                uint64,
                uint64,
                string,
                address,
                uint256,
                bytes,
                uint256,
                bytes32
            )
        );

        _execute(
            ExecutionData(
                caller,
                sourceChainSelector,
                execChainSelector,
                salt,
                destination,
                value,
                data,
                gasLimit,
                extraData,
                false
            )
        );

        emit ReceiveRTC(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            caller,
            destination,
            extraData
        );
    }

    function _getFees(
        uint64 destChainSelector,
        uint64 execChainSelector,
        Client.EVM2AnyMessage memory message
    ) internal view returns (uint256 ccipFee, uint256 totalFee) {
        // Multiply fees by 2 if not a direct lane
        uint256 laneMultiplier = (destChainSelector == execChainSelector) ? 1 : 2;
        ccipFee = IRouterClient(getRouter()).getFee(destChainSelector, message);
        totalFee = (ccipFee + (ccipFee * feePercentage / 100)) * laneMultiplier;
    }

    function _directLaneExists(uint64 execChainSelector) internal view returns (bool) {
        return IRouterClient(getRouter()).isChainSupported(execChainSelector);
    }
    
    function _getDestChainSelector(uint64 execChainSelector) internal view returns (uint64 selector) {
        selector = _directLaneExists(execChainSelector) ? execChainSelector : relayerChainSelector;
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}

    /// ERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(CCIPReceiver, AccessControl) returns (bool) {
        return CCIPReceiver.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}