/**
 *Submitted for verification at Arbiscan.io on 2023-12-11
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @chainlink/contracts/src/v0.8/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

// 
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}


// File @chainlink/contracts/src/v0.8/[email protected]

// 
pragma solidity ^0.8.0;


abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}


// File @openzeppelin/contracts/access/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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

// 
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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

// 
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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

// 
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


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

// 
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

// 
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}


// File @chainlink/contracts/src/v0.8/[email protected]

// 
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}


// File contracts/chance/pokerBaccarat/PokerCard.sol

// 
pragma solidity ^0.8.0;

abstract contract PokerCard {
    // uint8 rank 2-14
    // uint8 suit 0-3
    function getPoker(uint8 number) public pure returns (uint8 /* rank */, uint8 /* suit */) {
        require(number >= 8 && number <= 59, "getPoker error");
        return (number / 4, number % 4);
    }
}


// File contracts/chance/pokerBaccarat/PokerRecognizer.sol

// 
pragma solidity ^0.8.0;
contract PokerRecognizer is PokerCard {
    // 0: high card
    // 1: one pair
    // 2: two pair
    // 3: three of a kind
    // 4: straight
    // 5: flush
    // 6: full house
    // 7: four of a kind
    // 8: straight flush
    // 9: royal flush
    struct Recognizer {
        uint8[7] flush; // 2-14,,0
        uint8[7] rankCard7; // 2-14
        uint8[5] rankCard5; // 2-14
        uint8 level; // 0-9
    }

    function shuffle(
        uint256 currentRound,
        uint256 randomWord
    )
        external
        pure
        returns (
            uint8[2] memory holeOfBanker,
            uint8[2] memory holeOfPlayer,
            uint8[5] memory community,
            Recognizer memory bankerRecognizer,
            Recognizer memory playerRecognizer
        )
    {
        uint8[52] memory pokerList = [
            8,
            9,
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
            18,
            19,
            20,
            21,
            22,
            23,
            24,
            25,
            26,
            27,
            28,
            29,
            30,
            31,
            32,
            33,
            34,
            35,
            36,
            37,
            38,
            39,
            40,
            41,
            42,
            43,
            44,
            45,
            46,
            47,
            48,
            49,
            50,
            51,
            52,
            53,
            54,
            55,
            56,
            57,
            58,
            59
        ];
        for (uint8 i = 0; i < 52; ++i) {
            uint8 index = uint8(uint256(keccak256(abi.encodePacked(randomWord, i, currentRound))) % 52);
            (pokerList[i], pokerList[index]) = (pokerList[index], pokerList[i]);
        }
        holeOfBanker = [pokerList[1], pokerList[3]];
        holeOfPlayer = [pokerList[0], pokerList[2]];
        community = [pokerList[5], pokerList[6], pokerList[7], pokerList[9], pokerList[11]];
        bankerRecognizer = generatePokerRecognizer(holeOfBanker, community);
        playerRecognizer = generatePokerRecognizer(holeOfPlayer, community);
    }

    function generatePokerRecognizer(
        uint8[2] memory hole,
        uint8[5] memory community
    ) public pure returns (Recognizer memory recognizer) {
        uint8[7] memory rankList;
        uint8[7] memory suitList;
        (rankList, suitList) = mergeAndSort(hole, community);

        // Process 5,8,9
        recognizer = findFlush(rankList, suitList);
        if (recognizer.level == 5) {
            recognizer = findStraightFlush(recognizer);
            return recognizer;
        }

        // fix rankCount
        uint8[15] memory rankCount;
        for (uint8 i = 0; i < 7; ++i) {
            ++rankCount[recognizer.rankCard7[i]];
        }

        // Process 6,7
        recognizer = findFourOfAKindAndFullHouse(recognizer, rankCount);
        if (recognizer.level > 5) {
            return recognizer;
        }

        // Process 4
        recognizer = findStraight(recognizer, rankCount);
        if (recognizer.level == 4) {
            return recognizer;
        }

        // Process 0,1,2,3
        recognizer = findOthers(recognizer, rankCount);
    }

    function findFlush(
        uint8[7] memory rankList,
        uint8[7] memory suitList
    ) private pure returns (Recognizer memory recognizer) {
        uint8[4] memory suitCount;
        recognizer.rankCard7 = rankList;
        for (uint8 i = 0; i < 7; ++i) {
            ++suitCount[suitList[i]];
        }

        for (uint8 i = 0; i < 4; ++i) {
            if (suitCount[i] >= 5) {
                recognizer.level = 5;
                uint8 k;
                for (uint8 j = 0; j < 7; ++j) {
                    if (suitList[j] == i) {
                        recognizer.flush[k] = rankList[j];
                        if (k < 5) {
                            recognizer.rankCard5[k] = rankList[j];
                        }
                        ++k;
                    }
                }
                break;
            }
        }
    }

    function findStraightFlush(Recognizer memory recognizer_) private pure returns (Recognizer memory recognizer) {
        recognizer = recognizer_;
        uint8 count;
        uint8[15] memory rankCount;
        for (uint8 i = 0; i < 7; ++i) {
            ++rankCount[recognizer.flush[i]];
        }
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] != 0) {
                ++count;
            } else {
                count = 0;
            }
            if (count == 5) {
                recognizer.rankCard5[4] = i;
                recognizer.rankCard5[3] = i + 1;
                recognizer.rankCard5[2] = i + 2;
                recognizer.rankCard5[1] = i + 3;
                recognizer.rankCard5[0] = i + 4;
                if (recognizer.rankCard5[0] == 14) {
                    recognizer.level = 9;
                } else {
                    recognizer.level = 8;
                }
                return recognizer;
            }
        }

        // find 5432A
        if (rankCount[5] == 1 && rankCount[4] == 1 && rankCount[3] == 1 && rankCount[2] == 1 && rankCount[14] == 1) {
            recognizer.level = 8;
            recognizer.rankCard5 = [5, 4, 3, 2, 14];
        }
    }

    function findFourOfAKindAndFullHouse(
        Recognizer memory recognizer_,
        uint8[15] memory rankCount
    ) private pure returns (Recognizer memory recognizer) {
        recognizer = recognizer_;
        // find four of a kind
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] == 4) {
                recognizer.rankCard5[0] = i;
                recognizer.rankCard5[1] = i;
                recognizer.rankCard5[2] = i;
                recognizer.rankCard5[3] = i;
                for (uint8 j = 0; j < 7; ++j) {
                    if (recognizer.rankCard7[j] != i) {
                        recognizer.rankCard5[4] = recognizer.rankCard7[j];
                        recognizer.level = 7;
                        return recognizer;
                    }
                }
            }
        }

        // find full house
        uint8[2] memory tmp;
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] == 3) {
                if (tmp[0] == 0) {
                    tmp[0] = i;
                } else if (tmp[1] == 0) {
                    tmp[1] = i;
                    break;
                }
            }

            if (rankCount[i] == 2 && tmp[1] == 0) {
                tmp[1] = i;
            }
        }

        if (tmp[0] > 0 && tmp[1] > 0) {
            recognizer.rankCard5[0] = tmp[0];
            recognizer.rankCard5[1] = tmp[0];
            recognizer.rankCard5[2] = tmp[0];
            recognizer.rankCard5[3] = tmp[1];
            recognizer.rankCard5[4] = tmp[1];
            recognizer.level = 6;
            return recognizer;
        }
    }

    function findStraight(
        Recognizer memory recognizer_,
        uint8[15] memory rankCount
    ) private pure returns (Recognizer memory recognizer) {
        recognizer = recognizer_;
        uint8 count;
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] != 0) {
                ++count;
            } else {
                count = 0;
            }
            if (count == 5) {
                recognizer.rankCard5[4] = i;
                recognizer.rankCard5[3] = i + 1;
                recognizer.rankCard5[2] = i + 2;
                recognizer.rankCard5[1] = i + 3;
                recognizer.rankCard5[0] = i + 4;
                recognizer.level = 4;
                return recognizer;
            }
        }

        // find 5432A
        if (rankCount[5] != 0 && rankCount[4] != 0 && rankCount[3] != 0 && rankCount[2] != 0 && rankCount[14] != 0) {
            recognizer.level = 4;
            recognizer.rankCard5 = [5, 4, 3, 2, 14];
        }
    }

    function findOthers(
        Recognizer memory recognizer_,
        uint8[15] memory rankCount
    ) private pure returns (Recognizer memory recognizer) {
        recognizer = recognizer_;
        // find three of a kind
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] == 3) {
                recognizer.rankCard5[0] = i;
                recognizer.rankCard5[1] = i;
                recognizer.rankCard5[2] = i;
                for (uint8 j = 0; j < 7; ++j) {
                    if (recognizer.rankCard7[j] != i) {
                        if (recognizer.rankCard5[3] == 0) {
                            recognizer.rankCard5[3] = recognizer.rankCard7[j];
                        } else {
                            recognizer.rankCard5[4] = recognizer.rankCard7[j];
                            recognizer.level = 3;
                            return recognizer;
                        }
                    }
                }
            }
        }

        // find two pair
        uint8[2] memory tmp;
        for (uint8 i = 14; i > 1; --i) {
            if (rankCount[i] == 2) {
                if (tmp[0] == 0) {
                    tmp[0] = i;
                    recognizer.rankCard5[0] = i;
                    recognizer.rankCard5[1] = i;
                } else {
                    tmp[1] = i;
                    recognizer.rankCard5[2] = i;
                    recognizer.rankCard5[3] = i;
                    for (uint8 j = 0; j < 7; ++j) {
                        if (recognizer.rankCard7[j] != tmp[0] && recognizer.rankCard7[j] != tmp[1]) {
                            recognizer.rankCard5[4] = recognizer.rankCard7[j];
                            recognizer.level = 2;
                            return recognizer;
                        }
                    }
                }
            }
        }

        if (tmp[0] != 0) {
            // find one pair
            for (uint8 j = 0; j < 7; ++j) {
                if (recognizer.rankCard7[j] != tmp[0]) {
                    if (recognizer.rankCard5[2] == 0) {
                        recognizer.rankCard5[2] = recognizer.rankCard7[j];
                    } else if (recognizer.rankCard5[3] == 0) {
                        recognizer.rankCard5[3] = recognizer.rankCard7[j];
                    } else if (recognizer.rankCard5[4] == 0) {
                        recognizer.rankCard5[4] = recognizer.rankCard7[j];
                        recognizer.level = 1;
                        return recognizer;
                    }
                }
            }
        } else {
            // find high card
            for (uint8 j = 0; j < 5; ++j) {
                recognizer.rankCard5[j] = recognizer.rankCard7[j];
            }
            // default recognizer.level is 0
        }
    }

    function mergeAndSort(
        uint8[2] memory hole,
        uint8[5] memory community
    ) private pure returns (uint8[7] memory rankList, uint8[7] memory suitList) {
        uint8[7] memory sortedCards;
        sortedCards[0] = hole[0];
        sortedCards[1] = hole[1];
        sortedCards[2] = community[0];
        sortedCards[3] = community[1];
        sortedCards[4] = community[2];
        sortedCards[5] = community[3];
        sortedCards[6] = community[4];

        // Sorting the merged array in descending order
        for (uint256 i = 0; i < 7; ++i) {
            for (uint256 j = i + 1; j < 7; ++j) {
                if (sortedCards[i] < sortedCards[j]) {
                    (sortedCards[i], sortedCards[j]) = (sortedCards[j], sortedCards[i]);
                }
            }
            (rankList[i], suitList[i]) = getPoker(sortedCards[i]);
        }
    }
}


// File contracts/Roles.sol

// 
pragma solidity >0.8.0;

contract Roles is AccessControl {
    error NotAuthorizedError(address sender);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(address _owner) {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    modifier onlyOwner() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotAuthorizedError(_msgSender());
        }
        _;
    }

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, _msgSender())) {
            revert NotAuthorizedError(_msgSender());
        }
        _;
    }
}


// File contracts/chance/pokerBaccarat/PokerBaccarat.sol

// 
pragma solidity ^0.8.0;
interface IGame {
    function startGame(
        address player,
        uint256 amount,
        uint256 tokenId,
        bytes memory gameArgs
    ) external payable returns (uint256);
}

interface IPrizePool {
    function recordBonus(address player, uint256 amount) external;
}

contract PokerBaccarat is AutomationCompatibleInterface, VRFConsumerBaseV2, Roles, IGame {
    enum Option {
        Pending,
        Banker,
        Player,
        Tie,
        Level01,
        Level2,
        Level345,
        Level6,
        Level789
    }

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }

    struct Info {
        uint256 endTime;
        Status status;
        Option winner1;
        Option winner2;
        uint8 levelOfBanker;
        uint8 levelOfPlayer;
        uint8[2] holeOfBanker;
        uint8[2] holeOfPlayer;
        uint8[5] community;
    }

    address public immutable platform;
    address public immutable prizePool;
    PokerRecognizer public pokerRecognizer;

    uint256 public minPrice = 2_000000;
    uint256 public maxPrice = 20000_000000;
    uint256[9] public bettingLimit = [
        0,
        1100_000000,
        1100_000000,
        520_000000,
        0,
        0,
        0,
        0,
        0
    ];
    uint256 public constant ODDS_UNIT = 100;
    uint16[9] public odds = [0, 195, 195, 1600, 0, 0, 0, 0, 0];
    uint256 public interval = 5 * 60;
    uint256 public internalSettleCount = 31;
    bool public automaticStart = true;
    bool public paused;

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public subscriptionId = 136;
    uint32 public callbackGasLimit = 2500000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    bytes32 public keyHash = 0x72d2b016bb5b62912afea355ebf33b91319f828738b111b723b78696b9847b63;

    uint256 public currentRound;

    //bettingList[round][option]
    mapping(uint256 => mapping(Option => address[])) public bettingList;
    //bettingRecord[round][option][player]
    mapping(uint256 => mapping(Option => mapping(address => uint256))) public bettingRecord;
    //totalBettingAmount[round][option]
    mapping(uint256 => mapping(Option => uint256)) public totalBettingAmount;
    //gameRecords[round]
    mapping(uint256 => Info) public gameRecords;
    //settlementRecord[round][option][index]
    mapping(uint256 => mapping(Option => mapping(uint256 => bool))) public settlementRecord;

    modifier onlyPlatform() {
        require(msg.sender == platform, "Not granted");
        _;
    }

    event EventBettingRecord(uint256 indexed round, address indexed player, uint8[] optionList, uint256[] amountList);
    event EventLaunchNewRound(uint256 indexed round);
    event EventGetResult(uint256 indexed requestId, uint256 indexed round);
    event EventDisplayResult(uint256 indexed requestId, uint256 indexed round, Option winner1, Option winner2);
    event EventSettle(uint256 indexed round, Option option, uint256 index);

    constructor(
        address _platform,
        address _prizePool,
        address _pokerRecognizer,
        address _vrfCoordinator
    ) Roles(_msgSender()) VRFConsumerBaseV2(_vrfCoordinator) {
        platform = _platform;
        prizePool = _prizePool;
        pokerRecognizer = PokerRecognizer(_pokerRecognizer);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator); // VRF
    }

    function setPokerRecognizer(address _pokerRecognizer) external onlyOwner {
        pokerRecognizer = PokerRecognizer(_pokerRecognizer);
    }

    function setPrice(uint256 minPrice_, uint256 maxPrice_) external onlyOwner {
        require(minPrice_ >= 1_000000 && maxPrice_ > minPrice_, "Invalid args");
        minPrice = minPrice_;
        maxPrice = maxPrice_;
    }

    function setBettingLimit(uint256 index, uint256 limit) external onlyOwner {
        require(index > 0 && index <= 8);
        bettingLimit[index] = limit;
    }

    function setOdds(uint256 index, uint16 odds_) external onlyOwner {
        if (index == 1) {
            require(odds_ > ODDS_UNIT && odds_ < 200, "Invalid odds"); //Banker
        } else if (index == 2) {
            require(odds_ > ODDS_UNIT && odds_ < 200, "Invalid odds"); //Player
        } else if (index == 3) {
            require(odds_ > ODDS_UNIT && odds_ <= 2600, "Invalid odds"); //Tie
        } else if (index == 4) {
            require(odds_ > ODDS_UNIT && odds_ <= 230, "Invalid odds"); //Level01
        } else if (index == 5) {
            require(odds_ > ODDS_UNIT && odds_ <= 310, "Invalid odds"); //Level2
        } else if (index == 6) {
            require(odds_ > ODDS_UNIT && odds_ <= 480, "Invalid odds"); //Level345
        } else if (index == 7) {
            require(odds_ > ODDS_UNIT && odds_ <= 2100, "Invalid odds"); //Level6
        } else if (index == 8) {
            require(odds_ > ODDS_UNIT && odds_ <= 26300, "Invalid odds"); //Level789
        } else {
            revert("Invalid index");
        }
        odds[index] = odds_;
    }

    function setInterval(uint256 interval_) external onlyOwner {
        require(interval_ >= 2 * 60, "Invalid args");
        interval = interval_;
    }

    function setInternalSettleCount(uint256 internalSettleCount_) external onlyOwner {
        require(internalSettleCount_ <= 41, "Invalid args");
        internalSettleCount = internalSettleCount_;
    }

    function setAutomaticStart(bool flag) external onlyOwner {
        automaticStart = flag;
    }

    function setPaused(bool flag) external onlyOwner {
        paused = flag;
    }

    function setChainLinkArgs(
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        bytes32 _keyHash
    ) external onlyOwner {
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
        keyHash = _keyHash;
    }

    function startGame(
        address player,
        uint256 amount,
        uint256 /* tokenId */,
        bytes calldata gameArgs
    ) external payable onlyPlatform returns (uint256 /** requestId **/) {
        (uint256 round, uint8[] memory optionList, uint256[] memory amountList) = abi.decode(
            gameArgs,
            (uint256, uint8[], uint256[])
        );
        require(block.timestamp < gameRecords[round].endTime, "Invalid timestamp");
        require(Status.Open == gameRecords[round].status, "Invalid round");

        uint256 length = optionList.length;
        require(length == amountList.length, "Invalid length");

        uint256 sum;
        for (uint256 i; i < length; ++i) {
            require(amountList[i] >= minPrice && amountList[i] <= maxPrice, "Invalid amount");
            sum += amountList[i];
        }
        require(amount == sum && amount > 0, "Invalid sum");

        for (uint256 i; i < length; ++i) {
            if (optionList[i] == uint8(Option.Banker)) {
                uint256 bankerTotal = totalBettingAmount[round][Option.Banker];
                uint256 playerTotal = totalBettingAmount[round][Option.Player];
                bankerTotal += amountList[i];
                require(
                    Math.max(bankerTotal, playerTotal) - Math.min(bankerTotal, playerTotal) <=
                        bettingLimit[optionList[i]],
                    "Betting limit"
                );
                totalBettingAmount[round][Option.Banker] = bankerTotal;
            } else if (optionList[i] == uint8(Option.Player)) {
                uint256 bankerTotal = totalBettingAmount[round][Option.Banker];
                uint256 playerTotal = totalBettingAmount[round][Option.Player];
                playerTotal += amountList[i];
                require(
                    Math.max(bankerTotal, playerTotal) - Math.min(bankerTotal, playerTotal) <=
                        bettingLimit[optionList[i]],
                    "Betting limit"
                );
                totalBettingAmount[round][Option.Player] = playerTotal;
            } else if (optionList[i] >= 3 && optionList[i] <= 8) {
                uint256 tmpAmount = totalBettingAmount[round][Option(optionList[i])];
                tmpAmount += amountList[i];
                require(tmpAmount <= bettingLimit[optionList[i]], "Betting limit");
                totalBettingAmount[round][Option(optionList[i])] = tmpAmount;
            } else {
                revert("Invalid option");
            }

            uint256 _amount = bettingRecord[round][Option(optionList[i])][player];
            if (_amount == 0) {
                bettingList[round][Option(optionList[i])].push(player);
            }
            _amount += amountList[i];
            bettingRecord[round][Option(optionList[i])][player] = _amount;
        }

        emit EventBettingRecord(round, player, optionList, amountList);
    }

    function launchNewRound() public {
        require(!paused, "paused");
        require((gameRecords[currentRound].status == Status.Claimable || (currentRound == 0)), "Not time to start");

        ++currentRound;
        Info memory info;
        info.endTime = block.timestamp + interval;
        info.status = Status.Open;
        gameRecords[currentRound] = info;

        emit EventLaunchNewRound(currentRound);
    }

    function getResult() public {
        uint256 _currentRound = currentRound;
        require(gameRecords[_currentRound].status == Status.Open, "Invalid status");
        require(block.timestamp > gameRecords[_currentRound].endTime, "Invalid timestamp");
        gameRecords[_currentRound].status = Status.Close;

        uint256 request = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        emit EventGetResult(request, _currentRound);
    }

    function settleWinner(uint256 round, Option winner, uint256 index) public {
        require(gameRecords[round].status == Status.Claimable, "Invalid round");
        require(gameRecords[round].winner1 == winner || gameRecords[round].winner2 == winner, "Invalid winner");
        require(!settlementRecord[round][winner][index], "Have settled");

        settlementRecord[round][winner][index] = true;
        uint256 cursor = Math.min(100 * (index + 1), bettingList[round][winner].length);
        uint16 _odds = odds[uint256(winner)];
        for (uint256 i = 100 * index; i < cursor; ++i) {
            address player = bettingList[round][winner][i];
            uint256 amount = bettingRecord[round][winner][player];
            amount = (amount * _odds) / ODDS_UNIT;

            IPrizePool(prizePool).recordBonus(player, amount);
        }

        emit EventSettle(round, winner, index);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 _currentRound = currentRound;

        PokerRecognizer.Recognizer memory bankerRecognizer;
        PokerRecognizer.Recognizer memory playerRecognizer;

        Info storage info = gameRecords[_currentRound];

        (info.holeOfBanker, info.holeOfPlayer, info.community, bankerRecognizer, playerRecognizer) = pokerRecognizer
            .shuffle(_currentRound, randomWords[0]);

        info.status = Status.Claimable;
        info.levelOfBanker = bankerRecognizer.level;
        info.levelOfPlayer = playerRecognizer.level;

        Option winner1;
        Option winner2;
        if (bankerRecognizer.level > playerRecognizer.level) {
            winner1 = Option.Banker;
        } else if (bankerRecognizer.level < playerRecognizer.level) {
            winner1 = Option.Player;
        } else {
            for (uint8 i = 0; i < 5; ++i) {
                if (bankerRecognizer.rankCard5[i] > playerRecognizer.rankCard5[i]) {
                    winner1 = Option.Banker;
                    break;
                } else if (bankerRecognizer.rankCard5[i] < playerRecognizer.rankCard5[i]) {
                    winner1 = Option.Player;
                    break;
                }
                if (i == 4) {
                    winner1 = Option.Tie;
                }
            }
        }

        uint256 maxLevel = Math.max(bankerRecognizer.level, playerRecognizer.level);

        if (maxLevel == 0 || maxLevel == 1) {
            winner2 = Option.Level01;
        } else if (maxLevel == 2) {
            winner2 = Option.Level2;
        } else if (maxLevel == 3 || maxLevel == 4 || maxLevel == 5) {
            winner2 = Option.Level345;
        } else if (maxLevel == 6) {
            winner2 = Option.Level6;
        } else if (maxLevel == 7 || maxLevel == 8 || maxLevel == 9) {
            winner2 = Option.Level789;
        }

        info.winner1 = winner1;
        info.winner2 = winner2;

        internalSettleWinner(_currentRound, winner1, winner2);

        if (!paused) {
            launchNewRound();
        }

        emit EventDisplayResult(requestId, _currentRound, winner1, winner2);
    }

    function internalSettleWinner(uint256 _currentRound, Option winner1, Option winner2) internal {
        uint256 winner1Count = bettingList[_currentRound][winner1].length;
        uint256 winner2Count = bettingList[_currentRound][winner2].length;
        if (winner1Count > 0 && winner1Count < internalSettleCount) {
            settleWinner(_currentRound, winner1, 0);
        }

        if (
            winner2Count > 0 &&
            (winner1Count + winner2Count < internalSettleCount ||
                (winner1Count >= internalSettleCount && winner2Count < internalSettleCount))
        ) {
            settleWinner(_currentRound, winner2, 0);
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        require(automaticStart, "Disable automatic");
        getResult();
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded =
            automaticStart &&
            gameRecords[currentRound].status == Status.Open &&
            block.timestamp > gameRecords[currentRound].endTime;
    }

    function viewBettingLimit() external view returns (uint256[9] memory) {
        return bettingLimit;
    }

    function viewOdds() external view returns (uint16[9] memory) {
        return odds;
    }

    function viewBetByAddress(uint256 round, address player) external view returns (uint256[9] memory betByAddress) {
        betByAddress[1] = bettingRecord[round][Option.Banker][player];
        betByAddress[2] = bettingRecord[round][Option.Player][player];
        betByAddress[3] = bettingRecord[round][Option.Tie][player];
        betByAddress[4] = bettingRecord[round][Option.Level01][player];
        betByAddress[5] = bettingRecord[round][Option.Level2][player];
        betByAddress[6] = bettingRecord[round][Option.Level345][player];
        betByAddress[7] = bettingRecord[round][Option.Level6][player];
        betByAddress[8] = bettingRecord[round][Option.Level789][player];
    }

    function viewGameRecords(
        uint256 round
    )
        external
        view
        returns (
            uint256 endTime,
            Status status,
            Option winner1,
            Option winner2,
            uint8 levelOfBanker,
            uint8 levelOfPlayer,
            uint8[2] memory holeOfBanker,
            uint8[2] memory holeOfPlayer,
            uint8[5] memory community,
            uint256[9] memory amountOfBet,
            uint256[9] memory count
        )
    {
        endTime = gameRecords[round].endTime;
        status = gameRecords[round].status;
        winner1 = gameRecords[round].winner1;
        winner2 = gameRecords[round].winner2;
        levelOfBanker = gameRecords[round].levelOfBanker;
        levelOfPlayer = gameRecords[round].levelOfPlayer;
        holeOfBanker = gameRecords[round].holeOfBanker;
        holeOfPlayer = gameRecords[round].holeOfPlayer;
        community = gameRecords[round].community;
        amountOfBet[1] = totalBettingAmount[round][Option.Banker];
        amountOfBet[2] = totalBettingAmount[round][Option.Player];
        amountOfBet[3] = totalBettingAmount[round][Option.Tie];
        amountOfBet[4] = totalBettingAmount[round][Option.Level01];
        amountOfBet[5] = totalBettingAmount[round][Option.Level2];
        amountOfBet[6] = totalBettingAmount[round][Option.Level345];
        amountOfBet[7] = totalBettingAmount[round][Option.Level6];
        amountOfBet[8] = totalBettingAmount[round][Option.Level789];
        count[1] = bettingList[round][Option.Banker].length;
        count[2] = bettingList[round][Option.Player].length;
        count[3] = bettingList[round][Option.Tie].length;
        count[4] = bettingList[round][Option.Level01].length;
        count[5] = bettingList[round][Option.Level2].length;
        count[6] = bettingList[round][Option.Level345].length;
        count[7] = bettingList[round][Option.Level6].length;
        count[8] = bettingList[round][Option.Level789].length;
    }

    function viewSettleResult(
        uint256 round
    ) external view returns (Option winner1, bool flag1, uint256 index1, Option winner2, bool flag2, uint256 index2) {
        winner1 = gameRecords[round].winner1;
        winner2 = gameRecords[round].winner2;
        (flag1, index1) = viewSettleResultByWinner(round, winner1);
        (flag2, index2) = viewSettleResultByWinner(round, winner2);
    }

    function viewSettleResultByWinner(uint256 round, Option winner) public view returns (bool, uint256) {
        if (gameRecords[round].status != Status.Claimable) {
            return (false, 404 * 10 ** 18);
        } else {
            uint256 cursor = (bettingList[round][winner].length + 99) / 100;
            for (uint256 index; index < cursor; ++index) {
                if (!settlementRecord[round][winner][index]) {
                    return (false, index);
                }
            }
        }
        return (true, 200 * 10 ** 18);
    }
}