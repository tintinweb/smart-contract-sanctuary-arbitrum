// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import {TablelandPolicy} from "../TablelandPolicy.sol";

/**
 * @dev Interface of a TablelandTables compliant contract.
 */
interface ITablelandTables {
    /**
     * The caller is not authorized.
     */
    error Unauthorized();

    /**
     * RunSQL was called with a query length greater than maximum allowed.
     */
    error MaxQuerySizeExceeded(uint256 querySize, uint256 maxQuerySize);

    /**
     * @dev Emitted when `owner` creates a new table.
     *
     * owner - the to-be owner of the table
     * tableId - the table id of the new table
     * statement - the SQL statement used to create the table
     */
    event CreateTable(address owner, uint256 tableId, string statement);

    /**
     * @dev Emitted when a table is transferred from `from` to `to`.
     *
     * Not emmitted when a table is created.
     * Also emitted after a table has been burned.
     *
     * from - the address that transfered the table
     * to - the address that received the table
     * tableId - the table id that was transferred
     */
    event TransferTable(address from, address to, uint256 tableId);

    /**
     * @dev Emitted when `caller` runs a SQL statement.
     *
     * caller - the address that is running the SQL statement
     * isOwner - whether or not the caller is the table owner
     * tableId - the id of the target table
     * statement - the SQL statement to run
     * policy - an object describing how `caller` can interact with the table (see {TablelandPolicy})
     */
    event RunSQL(
        address caller,
        bool isOwner,
        uint256 tableId,
        string statement,
        TablelandPolicy policy
    );

    /**
     * @dev Emitted when a table's controller is set.
     *
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     */
    event SetController(uint256 tableId, address controller);

    /**
     * @dev Struct containing parameters needed to run a mutating sql statement
     *
     * tableId - the id of the target table
     * statement - the SQL statement to run
     *           - the statement type can be any of INSERT, UPDATE, DELETE, GRANT, REVOKE
     *
     */
    struct Statement {
        uint256 tableId;
        string statement;
    }

    /**
     * @dev Creates a new table owned by `owner` using `statement` and returns its `tableId`.
     *
     * owner - the to-be owner of the new table
     * statement - the SQL statement used to create the table
     *           - the statement type must be CREATE
     *
     * Requirements:
     *
     * - contract must be unpaused
     */
    function create(
        address owner,
        string memory statement
    ) external payable returns (uint256);

    /**
     * @dev Creates multiple new tables owned by `owner` using `statements` and returns array of `tableId`s.
     *
     * owner - the to-be owner of the new table
     * statements - the SQL statements used to create the tables
     *            - each statement type must be CREATE
     *
     * Requirements:
     *
     * - contract must be unpaused
     */
    function create(
        address owner,
        string[] calldata statements
    ) external payable returns (uint256[] memory);

    /**
     * @dev Runs a mutating SQL statement for `caller` using `statement`.
     *
     * caller - the address that is running the SQL statement
     * tableId - the id of the target table
     * statement - the SQL statement to run
     *           - the statement type can be any of INSERT, UPDATE, DELETE, GRANT, REVOKE
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller`
     * - `tableId` must exist and be the table being mutated
     * - `caller` must be authorized by the table controller
     * - `statement` must be less than or equal to 35000 bytes
     */
    function mutate(
        address caller,
        uint256 tableId,
        string calldata statement
    ) external payable;

    /**
     * @dev Runs an array of mutating SQL statements for `caller`
     *
     * caller - the address that is running the SQL statement
     * statements - an array of structs containing the id of the target table and coresponding statement
     *            - the statement type can be any of INSERT, UPDATE, DELETE, GRANT, REVOKE
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller`
     * - `tableId` must be the table being muated in each struct's statement
     * - `caller` must be authorized by the table controller if the statement is mutating
     * - each struct inside `statements` must have a `tableId` that corresponds to table being mutated
     * - each struct inside `statements` must have a `statement` that is less than or equal to 35000 bytes after normalization
     */
    function mutate(
        address caller,
        ITablelandTables.Statement[] calldata statements
    ) external payable;

    /**
     * @dev Sets the controller for a table. Controller can be an EOA or contract address.
     *
     * When a table is created, it's controller is set to the zero address, which means that the
     * contract will not enforce write access control. In this situation, validators will not accept
     * transactions from non-owners unless explicitly granted access with "GRANT" SQL statements.
     *
     * When a controller address is set for a table, validators assume write access control is
     * handled at the contract level, and will accept all transactions.
     *
     * You can unset a controller address for a table by setting it back to the zero address.
     * This will cause validators to revert back to honoring owner and GRANT/REVOKE based write access control.
     *
     * caller - the address that is setting the controller
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function setController(
        address caller,
        uint256 tableId,
        address controller
    ) external;

    /**
     * @dev Returns the controller for a table.
     *
     * tableId - the id of the target table
     */
    function getController(uint256 tableId) external returns (address);

    /**
     * @dev Locks the controller for a table _forever_. Controller can be an EOA or contract address.
     *
     * Although not very useful, it is possible to lock a table controller that is set to the zero address.
     *
     * caller - the address that is locking the controller
     * tableId - the id of the target table
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function lockController(address caller, uint256 tableId) external;

    /**
     * @dev Sets the contract base URI.
     *
     * baseURI - the new base URI
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setBaseURI(string memory baseURI) external;

    /**
     * @dev Pauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be unpaused
     */
    function pause() external;

    /**
     * @dev Unpauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be paused
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

/**
 * @dev Object defining how a table can be accessed.
 */
struct TablelandPolicy {
    // Whether or not the table should allow SQL INSERT statements.
    bool allowInsert;
    // Whether or not the table should allow SQL UPDATE statements.
    bool allowUpdate;
    // Whether or not the table should allow SQL DELETE statements.
    bool allowDelete;
    // A conditional clause used with SQL UPDATE and DELETE statements.
    // For example, a value of "foo > 0" will concatenate all SQL UPDATE
    // and/or DELETE statements with "WHERE foo > 0".
    // This can be useful for limiting how a table can be modified.
    // Use {Policies-joinClauses} to include more than one condition.
    string whereClause;
    // A conditional clause used with SQL INSERT statements.
    // For example, a value of "foo > 0" will concatenate all SQL INSERT
    // statements with a check on the incoming data, i.e., "CHECK (foo > 0)".
    // This can be useful for limiting how table data ban be added.
    // Use {Policies-joinClauses} to include more than one condition.
    string withCheck;
    // A list of SQL column names that can be updated.
    string[] updatableColumns;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Library of helpers for generating SQL statements from common parameters.
 */
library SQLHelpers {
    /**
     * @dev Generates a properly formatted table name from a prefix and table id.
     *
     * prefix - the user generated table prefix as a string
     * tableId - the Tableland generated tableId as a uint256
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toNameFromId(
        string memory prefix,
        uint256 tableId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    prefix,
                    "_",
                    Strings.toString(block.chainid),
                    "_",
                    Strings.toString(tableId)
                )
            );
    }

    /**
     * @dev Generates a CREATE statement based on a desired schema and table prefix.
     *
     * schema - a comma seperated string indicating the desired prefix. Example: "int id, text name"
     * prefix - the user generated table prefix as a string
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toCreateFromSchema(
        string memory schema,
        string memory prefix
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "CREATE TABLE ",
                    prefix,
                    "_",
                    Strings.toString(block.chainid),
                    "(",
                    schema,
                    ")"
                )
            );
    }

    /**
     * @dev Generates an INSERT statement based on table prefix, tableId, columns, and values.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * columns - a string encoded ordered list of columns that will be updated. Example: "name, age".
     * values - a string encoded ordered list of values that will be inserted wrapped in parentheses. Example: "'jerry', 24". Values order must match column order.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toInsert(
        string memory prefix,
        uint256 tableId,
        string memory columns,
        string memory values
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        return
            string(
                abi.encodePacked(
                    "INSERT INTO ",
                    name,
                    "(",
                    columns,
                    ")VALUES(",
                    values,
                    ")"
                )
            );
    }

    /**
     * @dev Generates an INSERT statement based on table prefix, tableId, columns, and values.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * columns - a string encoded ordered list of columns that will be updated. Example: "name, age".
     * values - an array where each item is a string encoded ordered list of values.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toBatchInsert(
        string memory prefix,
        uint256 tableId,
        string memory columns,
        string[] memory values
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        string memory insert = string(
            abi.encodePacked("INSERT INTO ", name, "(", columns, ")VALUES")
        );
        for (uint256 i = 0; i < values.length; i++) {
            if (i == 0) {
                insert = string(abi.encodePacked(insert, "(", values[i], ")"));
            } else {
                insert = string(abi.encodePacked(insert, ",(", values[i], ")"));
            }
        }
        return insert;
    }

    /**
     * @dev Generates an Update statement based on table prefix, tableId, setters, and filters.
     *
     * prefix - the user generated table prefix as a string
     * tableId - the Tableland generated tableId as a uint256
     * setters - a string encoded set of updates. Example: "name='tom', age=26"
     * filters - a string encoded list of filters or "" for no filters. Example: "id<2 and name!='jerry'"
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toUpdate(
        string memory prefix,
        uint256 tableId,
        string memory setters,
        string memory filters
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        string memory filter = "";
        if (bytes(filters).length > 0) {
            filter = string(abi.encodePacked(" WHERE ", filters));
        }
        return
            string(abi.encodePacked("UPDATE ", name, " SET ", setters, filter));
    }

    /**
     * @dev Generates a Delete statement based on table prefix, tableId, and filters.
     *
     * prefix - the user generated table prefix as a string.
     * tableId - the Tableland generated tableId as a uint256.
     * filters - a string encoded list of filters. Example: "id<2 and name!='jerry'".
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function toDelete(
        string memory prefix,
        uint256 tableId,
        string memory filters
    ) internal view returns (string memory) {
        string memory name = toNameFromId(prefix, tableId);
        return
            string(abi.encodePacked("DELETE FROM ", name, " WHERE ", filters));
    }

    /**
     * @dev Add single quotes around a string value
     *
     * input - any input value.
     *
     */
    function quote(string memory input) internal pure returns (string memory) {
        return string(abi.encodePacked("'", input, "'"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import {ITablelandTables} from "../interfaces/ITablelandTables.sol";

/**
 * @dev Helper library for getting an instance of ITablelandTables for the currently executing EVM chain.
 */
library TablelandDeployments {
    /**
     * Current chain does not have a TablelandTables deployment.
     */
    error ChainNotSupported(uint256 chainid);

    // TablelandTables address on Ethereum.
    address internal constant MAINNET =
        0x012969f7e3439a9B04025b5a049EB9BAD82A8C12;
    // TablelandTables address on Ethereum.
    address internal constant HOMESTEAD = MAINNET;
    // TablelandTables address on Optimism.
    address internal constant OPTIMISM =
        0xfad44BF5B843dE943a09D4f3E84949A11d3aa3e6;
    // TablelandTables address on Arbitrum One.
    address internal constant ARBITRUM =
        0x9aBd75E8640871A5a20d3B4eE6330a04c962aFfd;
    // TablelandTables address on Arbitrum Nova.
    address internal constant ARBITRUM_NOVA =
        0x1A22854c5b1642760a827f20137a67930AE108d2;
    // TablelandTables address on Polygon.
    address internal constant MATIC =
        0x5c4e6A9e5C1e1BF445A062006faF19EA6c49aFeA;
    // TablelandTables address on Filecoin.
    address internal constant FILECOIN =
        0x59EF8Bf2d6c102B4c42AEf9189e1a9F0ABfD652d;

    // TablelandTables address on Ethereum Sepolia.
    address internal constant SEPOLIA =
        0xc50C62498448ACc8dBdE43DA77f8D5D2E2c7597D;
    // TablelandTables address on Optimism Goerli.
    address internal constant OPTIMISM_GOERLI =
        0xC72E8a7Be04f2469f8C2dB3F1BdF69A7D516aBbA;
    // TablelandTables address on Arbitrum Goerli.
    address internal constant ARBITRUM_GOERLI =
        0x033f69e8d119205089Ab15D340F5b797732f646b;
    // TablelandTables address on Polygon Mumbai.
    address internal constant MATICMUM =
        0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68;
    // TablelandTables address on Filecoin Calibration.
    address internal constant FILECOIN_CALIBRATION =
        0x030BCf3D50cad04c2e57391B12740982A9308621;

    // TablelandTables address on for use with https://github.com/tablelandnetwork/local-tableland.
    address internal constant LOCAL_TABLELAND =
        0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

    /**
     * @dev Returns an interface to Tableland for the currently executing EVM chain.
     *
     * The selection order is meant to reduce gas on more expensive chains.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function get() internal view returns (ITablelandTables) {
        if (block.chainid == 1) {
            return ITablelandTables(MAINNET);
        } else if (block.chainid == 10) {
            return ITablelandTables(OPTIMISM);
        } else if (block.chainid == 42161) {
            return ITablelandTables(ARBITRUM);
        } else if (block.chainid == 42170) {
            return ITablelandTables(ARBITRUM_NOVA);
        } else if (block.chainid == 137) {
            return ITablelandTables(MATIC);
        } else if (block.chainid == 314) {
            return ITablelandTables(FILECOIN);
        } else if (block.chainid == 11155111) {
            return ITablelandTables(SEPOLIA);
        } else if (block.chainid == 420) {
            return ITablelandTables(OPTIMISM_GOERLI);
        } else if (block.chainid == 421613) {
            return ITablelandTables(ARBITRUM_GOERLI);
        } else if (block.chainid == 80001) {
            return ITablelandTables(MATICMUM);
        } else if (block.chainid == 314159) {
            return ITablelandTables(FILECOIN_CALIBRATION);
        } else if (block.chainid == 31337) {
            return ITablelandTables(LOCAL_TABLELAND);
        } else {
            revert ChainNotSupported(block.chainid);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10 <0.9.0;

interface IVotingRegistry {
    /// @dev Emitted when a proposal is created.
    event ProposalCreated(uint256 proposalId);

    /// @dev The different voting systems supported
    enum VotingSystem {
        Weighted
    }

    /// @dev Struct that holds information about a proposal.
    struct Proposal {
        uint256 startBlockNumber;
        uint256 endBlockNumber;
        uint256 voterReward;
        string name;
        VotingSystem votingSystem;
        bool rewardsDistributed;
    }

    /// @notice Create a new proposal
    ///
    /// @param name             The name of the proposal
    /// @param descriptionCid   An IPFS CID to a markdown document with proposal details
    /// @param votingSystem     The voting system to use for the proposal
    /// @param voterReward      The reputation reward amount voters get for voting
    /// @param startBlockNumber The block number when the proposal voting starts
    /// @param endBlockNumber   The block number when the proposal voting ends
    /// @param options          A list of options for the proposal
    function createProposal(
        string calldata name,
        string calldata descriptionCid,
        VotingSystem votingSystem,
        uint256 voterReward,
        uint256 startBlockNumber,
        uint256 endBlockNumber,
        string[] calldata options
    ) external returns (uint256 proposalId);

    /// @notice Get a proposal
    function proposal(
        uint256 proposalId
    ) external view returns (Proposal memory);

    /// @notice Cast a vote for a proposal. Reverts if the proposal hasn't opened yet or if it has ended.
    ///
    /// The arguments `options` and `weights` have different requirements depending on the
    /// VotingSystem used for the proposal:
    ///
    /// Weighted: Spread votes over multiple options.
    /// - options: should contain the options that the user wants to vote for
    /// - weights: should contain the same number of elements as `options`. the value at index
    /// n in `weights` is the weight assigned to the option at index `n`. the sum of all weights
    /// must be 100.
    /// - comments: should contain the same number of elements as `options`.
    ///
    /// @param proposalId The proposal id
    /// @param options    Depends on the voting system
    /// @param weights    Depends on the voting system
    /// @param comments   Comments for `options`
    function vote(
        uint256 proposalId,
        uint256[] calldata options,
        uint256[] calldata weights,
        string[] memory comments
    ) external;

    /// @notice Distribute rewards to voters for a proposal. Reverts if the proposal hasn't ended. Can only be called once.
    ///
    /// @param proposalId The proposal id.
    function distributeVoterRewards(uint256 proposalId) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10 <0.9.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {TablelandDeployments} from "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import {ITablelandTables} from "@tableland/evm/contracts/interfaces/ITablelandTables.sol";
import {IVotingRegistry} from "./IVotingRegistry.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";

/// @title An implementation of IVotingRegistry that records proposals, options, votes and voter rewards in tableland tables.
contract VotingRegistry is AccessControl, IVotingRegistry {
    /// @dev keccak256("VOTING_ADMIN_ROLE")
    bytes32 public constant VOTING_ADMIN_ROLE =
        0x26e5e0c1d827967646b29471a0f5eef941c85bdbb97c194dc3fa6291a994a148;

    /// @dev Struct that holds information about a Tableland table
    struct TableInfo {
        uint256 id;
        string name;
    }

    TableInfo private _proposalsTable;
    TableInfo private _ftSnapshotTable;
    TableInfo private _votesTable;
    TableInfo private _optionsTable;
    TableInfo private _pilotSessionsTable;
    TableInfo private _ftRewardsTable;

    /// @dev The next proposal ID to be created.
    uint256 private _proposalCounter;

    /// @dev Mapping from proposal ID to proposal details.
    mapping(uint256 => Proposal) private _proposals;

    // =============================
    //        CONSTRUCTOR
    // =============================

    constructor(
        TableInfo memory proposalsTable,
        TableInfo memory ftSnapshotTable,
        TableInfo memory votesTable,
        TableInfo memory optionsTable,
        TableInfo memory pilotSessionsTable,
        TableInfo memory ftRewardsTable,
        uint256 startingProposalId
    ) {
        _proposalsTable = proposalsTable;
        _ftSnapshotTable = ftSnapshotTable;
        _votesTable = votesTable;
        _optionsTable = optionsTable;
        _pilotSessionsTable = pilotSessionsTable;
        _ftRewardsTable = ftRewardsTable;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VOTING_ADMIN_ROLE, msg.sender);

        _proposalCounter = startingProposalId;
    }

    // =============================
    //        IVOTINGREGISTRY
    // =============================

    /// @dev Creates a new proposal.
    /// Creating a new proposal will:
    /// 1) Insert a new row in the proposals table
    /// 2) Insert options in the options table
    /// 3) Snapshot all voting power
    /// 4) Insert the 'cross product' of all eligible voter addresses
    ///    and options.
    /// @inheritdoc IVotingRegistry
    function createProposal(
        string calldata name,
        string calldata descriptionCid,
        VotingSystem votingSystem,
        uint256 voterFtReward,
        uint256 startBlockNumber,
        uint256 endBlockNumber,
        string[] calldata options
    ) external onlyRole(VOTING_ADMIN_ROLE) returns (uint256 proposalId) {
        // We only support Weighted voting right now
        require(
            votingSystem == VotingSystem.Weighted,
            "Unsupported voting system"
        );

        proposalId = _proposalCounter++;

        string memory proposalIdString = Strings.toString(proposalId);

        _insertProposal(
            proposalIdString,
            name,
            descriptionCid,
            votingSystem,
            voterFtReward,
            startBlockNumber,
            endBlockNumber
        );
        _insertOptions(proposalIdString, options);
        _snapshotVotingPower(proposalIdString);
        _insertEligibleVotes(proposalIdString, options);

        _proposals[proposalId] = Proposal(
            startBlockNumber,
            endBlockNumber,
            voterFtReward,
            name,
            votingSystem,
            false
        );

        emit ProposalCreated(proposalId);

        return proposalId;
    }

    /// @inheritdoc IVotingRegistry
    function proposal(
        uint256 proposalId
    ) external view returns (Proposal memory) {
        return _proposals[proposalId];
    }

    /// @notice Cast a vote for a proposal. Will revert if the proposal hasn't opened yet or if it has ended.
    /// The vote will only be recorded if you are eligible to vote.
    ///
    /// @inheritdoc IVotingRegistry
    function vote(
        uint256 proposalId,
        uint256[] calldata options,
        uint256[] calldata weights,
        string[] memory comments
    ) external {
        Proposal memory proposal_ = _proposals[proposalId];

        // We only support Weighted voting right now
        require(
            proposal_.votingSystem == VotingSystem.Weighted,
            "Unsupported voting system"
        );

        // Check that proposal is active
        require(
            block.number >= proposal_.startBlockNumber,
            "Vote has not started"
        );
        require(block.number <= proposal_.endBlockNumber, "Vote has ended");

        // Check that options & weights & comments match, and weight sum == 100
        require(
            options.length == weights.length,
            "Mismatched options and weights length"
        );
        require(
            weights.length == comments.length,
            "Mismatched options and commentslength"
        );
        uint256 weightSum;
        uint256 i;
        for (; i < weights.length; ) {
            weightSum += weights[i];
            unchecked {
                ++i;
            }
        }
        require(weightSum == 100, "Incorrect weights");

        // Builds a query like:
        //
        // ```
        // UPDATE votes
        // SET weight = CASE option_id
        //                  WHEN X1 THEN Y1
        //                  WHEN X2 THEN Y2
        //                  ELSE 0
        //              END
        // WHERE lower(address) = lower(msg.sender);
        // ```
        string memory updateStatement = string.concat(
            "UPDATE ",
            _votesTable.name,
            " SET weight = CASE option_id"
        );

        uint256 votes = weights.length;
        i = 0;
        unchecked {
            for (; i < votes; ) {
                updateStatement = string.concat(
                    updateStatement,
                    " WHEN ",
                    Strings.toString(options[i]),
                    " THEN ",
                    Strings.toString(weights[i])
                );
                ++i;
            }
        }

        updateStatement = string.concat(
            updateStatement,
            " ELSE 0 END, comment = CASE option_id"
        );

        i = 0;
        unchecked {
            for (; i < votes; ) {
                updateStatement = string.concat(
                    updateStatement,
                    " WHEN ",
                    Strings.toString(options[i]),
                    " THEN ",
                    SQLHelpers.quote(comments[i])
                );
                ++i;
            }
        }

        updateStatement = string.concat(
            updateStatement,
            " ELSE null END WHERE lower(address) = lower('",
            Strings.toHexString(uint256(uint160(msg.sender)), 20),
            "') AND proposal_id = ",
            Strings.toString(proposalId)
        );

        // Submit vote
        TablelandDeployments.get().mutate(
            address(this),
            _votesTable.id,
            updateStatement
        );
    }

    /// @inheritdoc IVotingRegistry
    function distributeVoterRewards(uint256 proposalId) external {
        Proposal memory proposal_ = _proposals[proposalId];

        require(
            block.number > proposal_.endBlockNumber,
            "Vote has not ended yet"
        );

        require(!proposal_.rewardsDistributed, "Rewards have been distributed");

        _proposals[proposalId].rewardsDistributed = true;

        // Builds a query like:
        //
        // ```
        // INSERT INTO ft_rewards (block_num, recipient, reason, amount, vote_id)
        // SELECT DISTINCT
        //   BLOCK_NUM(),
        //   address,
        //   'participated in vote',
        //   amount,
        //   proposal_id
        // FROM votes WHERE weight > 0 and proposal_id = ?
        // ```
        string memory insert = string.concat(
            "INSERT INTO ",
            _ftRewardsTable.name,
            " (block_num, recipient, reason, amount, proposal_id)",
            " SELECT DISTINCT BLOCK_NUM(), ",
            "address, 'Voted on proposal', ",
            Strings.toString(proposal_.voterReward),
            ", proposal_id FROM ",
            _votesTable.name,
            " WHERE weight > 0 AND proposal_id = ",
            Strings.toString(proposalId)
        );

        TablelandDeployments.get().mutate(
            address(this),
            _ftRewardsTable.id,
            insert
        );
    }

    // =============================
    //        INTERNAL
    // =============================

    /// @dev Inserts a proposal into the proposals table.
    function _insertProposal(
        string memory proposalIdString,
        string memory name,
        string memory descriptionCid,
        VotingSystem votingSystem,
        uint256 voterFtReward,
        uint256 startBlockNumber,
        uint256 endBlockNumber
    ) internal {
        string memory insert = string.concat(
            "INSERT INTO ",
            _proposalsTable.name,
            " (id, name, description_cid, voting_system, voter_ft_reward, created_at, start_block, end_block) VALUES (",
            proposalIdString,
            ", ",
            SQLHelpers.quote(name),
            ", ",
            SQLHelpers.quote(descriptionCid),
            ", ",
            Strings.toString(uint(votingSystem)),
            ", ",
            Strings.toString(voterFtReward),
            ", ",
            Strings.toString(block.number),
            ", ",
            Strings.toString(startBlockNumber),
            ", ",
            Strings.toString(endBlockNumber),
            ")"
        );
        TablelandDeployments.get().mutate(
            address(this),
            _proposalsTable.id,
            insert
        );
    }

    /// @dev Inserts `options` into the options table for the given `proposalId`.
    function _insertOptions(
        string memory proposalId,
        string[] calldata options
    ) internal {
        string memory insert = string.concat(
            "INSERT INTO ",
            _optionsTable.name,
            " (proposal_id, id, description) VALUES"
        );

        uint256 length = options.length;
        string memory prefix;
        uint256 i;
        for (; i < length; ) {
            if (i == 0) {
                prefix = "(";
            } else {
                prefix = ",(";
            }

            insert = string.concat(
                insert,
                prefix,
                proposalId,
                ",",
                Strings.toString(i + 1),
                ",",
                SQLHelpers.quote(options[i]),
                ")"
            );

            unchecked {
                ++i;
            }
        }

        TablelandDeployments.get().mutate(
            address(this),
            _optionsTable.id,
            insert
        );
    }

    /// @dev Stores a snapshot of the all current ft balances in the snapshot table with the given `proposalId`.
    function _snapshotVotingPower(string memory proposalId) internal {
        string memory snapshotPilotSessionFt = string.concat(
            "INSERT INTO ",
            _ftSnapshotTable.name,
            " (address, ft, proposal_id) ",
            "SELECT owner, SUM(COALESCE(end_time, BLOCK_NUM()) - start_time), ",
            proposalId,
            " FROM ",
            _pilotSessionsTable.name,
            " GROUP BY owner"
        );

        string memory snapshotFtRewards = string.concat(
            "INSERT INTO ",
            _ftSnapshotTable.name,
            " (address, ft, proposal_id) ",
            "SELECT recipient, amount, ",
            proposalId,
            " FROM ",
            _ftRewardsTable.name,
            " ON CONFLICT (address, proposal_id) ",
            "DO UPDATE SET ft = ",
            _ftSnapshotTable.name,
            ".ft + excluded.ft"
        );

        ITablelandTables.Statement[]
            memory stmnts = new ITablelandTables.Statement[](2);
        stmnts[0] = ITablelandTables.Statement(
            _ftSnapshotTable.id,
            snapshotPilotSessionFt
        );
        stmnts[1] = ITablelandTables.Statement(
            _ftSnapshotTable.id,
            snapshotFtRewards
        );
        TablelandDeployments.get().mutate(address(this), stmnts);
    }

    /// @dev Inserts the cross product of `options` and all eligible voting addresses
    /// from the ft snapshot table for the given `proposalId`.
    function _insertEligibleVotes(
        string memory proposalId,
        string[] calldata options
    ) internal {
        uint256 length = options.length;
        ITablelandTables.Statement[]
            memory stmnts = new ITablelandTables.Statement[](length);

        uint256 i;
        unchecked {
            for (; i < length; ) {
                string memory insert = string.concat(
                    "INSERT INTO ",
                    _votesTable.name,
                    " (address, proposal_id, option_id, weight) ",
                    "SELECT DISTINCT address, ",
                    proposalId,
                    ", ",
                    Strings.toString(i + 1),
                    ", 0 FROM ",
                    _ftSnapshotTable.name
                );

                stmnts[i++] = ITablelandTables.Statement(
                    _votesTable.id,
                    insert
                );
            }
        }

        TablelandDeployments.get().mutate(address(this), stmnts);
    }
}