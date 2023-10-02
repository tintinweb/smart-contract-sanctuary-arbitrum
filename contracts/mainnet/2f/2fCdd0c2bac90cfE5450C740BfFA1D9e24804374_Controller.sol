// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IFundManagerVault.sol";
import "./interfaces/IRescaleTickBoundaryCalculator.sol";
import "./interfaces/IController.sol";
import "./interfaces/IControllerEvent.sol";
import "./interfaces/IStrategyInfo.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IStrategySetter.sol";
import "./libraries/constants/Constants.sol";
import "./libraries/LiquidityNftHelper.sol";
import "./libraries/ParameterVerificationHelper.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @dev verified, private contract
/// @dev only owner or operator/backend callable
contract Controller is AccessControl, IControllerEvent, IController {
    using SafeMath for uint256;

    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    mapping(address => int24) public tickSpreadUpper; // strategy => tickSpreadUpper
    mapping(address => int24) public tickSpreadLower; // strategy => tickSpreadLower
    mapping(address => int24) public tickGapUpper; // strategy => tickGapUpper
    mapping(address => int24) public tickGapLower; // strategy => tickGapLower
    mapping(address => int24) public tickBoundaryOffset; // strategy => tickBoundaryOffset
    mapping(address => int24) public rescaleTickBoundaryOffset; // strategy => rescaleTickBoundaryOffset
    mapping(address => int24) public lastRescaleTick; // strategy => lastRescaleTick

    constructor(address _executor) {
        // set deployer as EXECUTOR_ROLE roleAdmin
        _setRoleAdmin(EXECUTOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // set EXECUTOR_ROLE memebers
        _setupRole(EXECUTOR_ROLE, _executor);
    }

    /// @dev backend get function support
    function isNftWithinRange(
        address _strategyContract
    ) public view returns (bool isWithinRange) {
        uint256 liquidityNftId = IStrategyInfo(_strategyContract)
            .liquidityNftId();

        require(
            liquidityNftId != 0,
            "not allow calling when liquidityNftId is 0"
        );

        (isWithinRange, ) = LiquidityNftHelper
            .verifyCurrentPriceInLiquidityNftRange(
                liquidityNftId,
                Constants.UNISWAP_V3_FACTORY_ADDRESS,
                Constants.NONFUNGIBLE_POSITION_MANAGER_ADDRESS
            );
    }

    function getEarningFlag(
        address _strategyContract
    ) public view returns (bool isEarningFlag) {
        return IStrategyInfo(_strategyContract).isEarning();
    }

    function getRescalingFlag(
        address _strategyContract
    ) public view returns (bool isRescalingFlag) {
        uint256 liquidityNftId = IStrategyInfo(_strategyContract)
            .liquidityNftId();

        if (liquidityNftId == 0) {
            return true;
        } else {
            return false;
        }
    }

    function getRemainingEarnCountDown(
        address _strategyContract
    ) public view returns (uint256 remainingEarn) {
        bool isEarningFlag = getEarningFlag(_strategyContract);
        if (isEarningFlag == false) {
            return 0;
        }

        uint256 userListLength = IStrategyInfo(_strategyContract)
            .getAllUsersInUserList()
            .length;
        uint256 earnLoopStartIndex = IStrategyInfo(_strategyContract)
            .earnLoopStartIndex();

        uint256 remainingUserNumber = userListLength.sub(earnLoopStartIndex);
        uint256 earnLoopSegmentSize = IStrategyInfo(_strategyContract)
            .earnLoopSegmentSize();

        (uint256 quotient, uint256 remainder) = calculateQuotientAndRemainder(
            remainingUserNumber,
            earnLoopSegmentSize
        );

        return remainder > 0 ? (quotient.add(1)) : quotient;
    }

    function calculateQuotientAndRemainder(
        uint256 dividend,
        uint256 divisor
    ) internal pure returns (uint256 quotient, uint256 remainder) {
        quotient = dividend.div(divisor);
        remainder = dividend.mod(divisor);
    }

    function getAllFundManagers(
        address _fundManagerVaultContract
    ) public view returns (IFundManagerVault.FundManager[4] memory) {
        return
            IFundManagerVault(_fundManagerVaultContract).getAllFundManagers();
    }

    /// @dev transactionDeadlineDuration setter
    function setTransactionDeadlineDuration(
        address _strategyContract,
        uint256 _transactionDeadlineDuration
    ) public onlyRole(EXECUTOR_ROLE) {
        IStrategySetter(_strategyContract).setTransactionDeadlineDuration(
            _transactionDeadlineDuration
        );

        emit SetTransactionDeadlineDuration(
            _strategyContract,
            msg.sender,
            _transactionDeadlineDuration
        );
    }

    /// @dev tickSpreadUpper setter
    function setTickSpreadUpper(
        address _strategyContract,
        int24 _tickSpreadUpper
    ) public onlyRole(EXECUTOR_ROLE) {
        // parameter verification
        ParameterVerificationHelper.verifyGreaterThanOrEqualToZero(
            _tickSpreadUpper
        );

        // update tickSpreadUpper
        tickSpreadUpper[_strategyContract] = _tickSpreadUpper;

        // emit SetTickSpreadUpper event
        emit SetTickSpreadUpper(
            _strategyContract,
            msg.sender,
            _tickSpreadUpper
        );
    }

    /// @dev tickSpreadLower setter
    function setTickSpreadLower(
        address _strategyContract,
        int24 _tickSpreadLower
    ) public onlyRole(EXECUTOR_ROLE) {
        // parameter verification
        ParameterVerificationHelper.verifyGreaterThanOrEqualToZero(
            _tickSpreadLower
        );

        // update tickSpreadLower
        tickSpreadLower[_strategyContract] = _tickSpreadLower;

        // emit SetTickSpreadLower event
        emit SetTickSpreadLower(
            _strategyContract,
            msg.sender,
            _tickSpreadLower
        );
    }

    /// @dev tickGapUpper setter
    function setTickGapUpper(
        address _strategyContract,
        int24 _tickGapUpper
    ) public onlyRole(EXECUTOR_ROLE) {
        // parameter verification
        ParameterVerificationHelper.verifyGreaterThanOne(_tickGapUpper);

        // update tickGapUpper
        tickGapUpper[_strategyContract] = _tickGapUpper;

        // emit SetTickGapUpper event
        emit SetTickGapUpper(_strategyContract, msg.sender, _tickGapUpper);
    }

    /// @dev tickGapLower setter
    function setTickGapLower(
        address _strategyContract,
        int24 _tickGapLower
    ) public onlyRole(EXECUTOR_ROLE) {
        // parameter verification
        ParameterVerificationHelper.verifyGreaterThanOne(_tickGapLower);

        // update tickGapLower
        tickGapLower[_strategyContract] = _tickGapLower;

        // emit SetTickGapLower event
        emit SetTickGapLower(_strategyContract, msg.sender, _tickGapLower);
    }

    /// @dev buyBackToken setter
    function setBuyBackToken(
        address _strategyContract,
        address _buyBackToken
    ) public onlyRole(EXECUTOR_ROLE) {
        IStrategySetter(_strategyContract).setBuyBackToken(_buyBackToken);

        emit SetBuyBackToken(_strategyContract, msg.sender, _buyBackToken);
    }

    /// @dev buyBackNumerator setter
    function setBuyBackNumerator(
        address _strategyContract,
        uint24 _buyBackNumerator
    ) public onlyRole(EXECUTOR_ROLE) {
        IStrategySetter(_strategyContract).setBuyBackNumerator(
            _buyBackNumerator
        );

        emit SetBuyBackNumerator(
            _strategyContract,
            msg.sender,
            _buyBackNumerator
        );
    }

    /// @dev fundManagerVault setter
    function setFundManagerVaultByIndex(
        address _strategyContract,
        uint256 _index,
        address _fundManagerVaultAddress,
        uint24 _fundManagerProfitVaultNumerator
    ) public onlyRole(EXECUTOR_ROLE) {
        IStrategySetter(_strategyContract).setFundManagerVaultByIndex(
            _index,
            _fundManagerVaultAddress,
            _fundManagerProfitVaultNumerator
        );

        emit SetFundManagerVaultByIndex(
            _strategyContract,
            msg.sender,
            _index,
            _fundManagerVaultAddress,
            _fundManagerProfitVaultNumerator
        );
    }

    /// @dev fundManager setter
    function setFundManagerByIndex(
        address _fundManagerVaultContract,
        uint256 _index,
        address _fundManagerAddress,
        uint24 _fundManagerProfitNumerator
    ) public onlyRole(EXECUTOR_ROLE) {
        IFundManagerVault(_fundManagerVaultContract).setFundManagerByIndex(
            _index,
            _fundManagerAddress,
            _fundManagerProfitNumerator
        );

        emit SetFundManagerByIndex(
            _fundManagerVaultContract,
            msg.sender,
            _index,
            _fundManagerAddress,
            _fundManagerProfitNumerator
        );
    }

    /// @dev earnLoopSegmentSize setter
    function setEarnLoopSegmentSize(
        address _strategyContract,
        uint256 _earnLoopSegmentSize
    ) public onlyRole(EXECUTOR_ROLE) {
        IStrategySetter(_strategyContract).setEarnLoopSegmentSize(
            _earnLoopSegmentSize
        );

        emit SetEarnLoopSegmentSize(
            _strategyContract,
            msg.sender,
            _earnLoopSegmentSize
        );
    }

    /// @dev tickBoundaryOffset setter
    function setTickBoundaryOffset(
        address _strategyContract,
        int24 _tickBoundaryOffset
    ) public onlyRole(EXECUTOR_ROLE) {
        // parameter verification
        ParameterVerificationHelper.verifyGreaterThanOrEqualToZero(
            _tickBoundaryOffset
        );

        // update tickBoundaryOffset
        tickBoundaryOffset[_strategyContract] = _tickBoundaryOffset;

        // emit SetTickBoundaryOffset event
        emit SetTickBoundaryOffset(
            _strategyContract,
            msg.sender,
            _tickBoundaryOffset
        );
    }

    /// @dev rescaleTickBoundaryOffset setter
    function setRescaleTickBoundaryOffset(
        address _strategyContract,
        int24 _rescaleTickBoundaryOffset
    ) public onlyRole(EXECUTOR_ROLE) {
        // parameter verification
        ParameterVerificationHelper.verifyGreaterThanOrEqualToZero(
            _rescaleTickBoundaryOffset
        );

        // update rescaleTickBoundaryOffset
        rescaleTickBoundaryOffset[
            _strategyContract
        ] = _rescaleTickBoundaryOffset;

        // emit SetRescaleTickBoundaryOffset event
        emit SetRescaleTickBoundaryOffset(
            _strategyContract,
            msg.sender,
            _rescaleTickBoundaryOffset
        );
    }

    /// @dev earn related
    function collectRewards(
        address _strategyContract
    ) public onlyRole(EXECUTOR_ROLE) {
        IStrategy(_strategyContract).collectRewards();

        emit CollectRewards(
            _strategyContract,
            msg.sender,
            IStrategyInfo(_strategyContract).liquidityNftId(),
            IStrategyInfo(_strategyContract).rewardToken0Amount(),
            IStrategyInfo(_strategyContract).rewardToken1Amount(),
            IStrategyInfo(_strategyContract).rewardWbtcAmount()
        );
    }

    function earnPreparation(
        address _strategyContract,
        uint256 _minimumToken0SwapOutAmount,
        uint256 _minimumToken1SwapOutAmount,
        uint256 _minimumBuybackSwapOutAmount
    ) public onlyRole(EXECUTOR_ROLE) {
        IStrategy(_strategyContract).earnPreparation(
            _minimumToken0SwapOutAmount,
            _minimumToken1SwapOutAmount,
            _minimumBuybackSwapOutAmount
        );
        require(getEarningFlag(_strategyContract) == true, "earn prep error");

        emit EarnPreparation(
            _strategyContract,
            msg.sender,
            IStrategyInfo(_strategyContract).liquidityNftId(),
            IStrategyInfo(_strategyContract).rewardWbtcAmount(),
            getRemainingEarnCountDown(_strategyContract)
        );
    }

    function earn(address _strategyContract) public onlyRole(EXECUTOR_ROLE) {
        IStrategy(_strategyContract).earn();

        emit Earn(
            _strategyContract,
            msg.sender,
            IStrategyInfo(_strategyContract).liquidityNftId(),
            getRemainingEarnCountDown(_strategyContract)
        );
    }

    function earnPreparation(
        address _fundManagerVaultContract
    ) public onlyRole(EXECUTOR_ROLE) {
        distribute(_fundManagerVaultContract);
    }

    function allocate(
        address _fundManagerVaultContract
    ) public onlyRole(EXECUTOR_ROLE) {
        distribute(_fundManagerVaultContract);
    }

    function distribute(address _fundManagerVaultContract) private {
        uint256 wbtcBeforeTx = IFundManagerVault(_fundManagerVaultContract)
            .getWbtcBalance();

        IFundManagerVault(_fundManagerVaultContract).allocate();

        uint256 wbtcAfterTx = IFundManagerVault(_fundManagerVaultContract)
            .getWbtcBalance();

        emit Allocate(
            _fundManagerVaultContract,
            msg.sender,
            wbtcBeforeTx.sub(wbtcAfterTx),
            wbtcAfterTx
        );
    }

    /// @dev rescale related
    function rescale(
        address _strategyContract,
        address _rescaleTickBoundaryCalculatorContract,
        bool _wasInRange
    ) public onlyRole(EXECUTOR_ROLE) {
        (
            bool allowRescale,
            int24 newTickUpper,
            int24 newTickLower
        ) = IRescaleTickBoundaryCalculator(
                _rescaleTickBoundaryCalculatorContract
            ).verifyAndGetNewRescaleTickBoundary(
                    _wasInRange,
                    lastRescaleTick[_strategyContract],
                    _strategyContract,
                    address(this)
                );
        require(allowRescale, "current condition not allow rescale");

        triggerRescaleStartEvent(_strategyContract, _wasInRange);

        (int24 currentTick, , ) = LiquidityNftHelper.getTickInfo(
            IStrategyInfo(_strategyContract).liquidityNftId(),
            Constants.UNISWAP_V3_FACTORY_ADDRESS,
            Constants.NONFUNGIBLE_POSITION_MANAGER_ADDRESS
        );

        IStrategy(_strategyContract).rescale(newTickUpper, newTickLower);

        lastRescaleTick[_strategyContract] = currentTick;

        triggerRescaleEndEvent(_strategyContract, newTickUpper, newTickLower);
    }

    function triggerRescaleStartEvent(
        address _strategyContract,
        bool _wasInRange
    ) internal {
        (
            int24 currentTick,
            int24 originalTickLower,
            int24 originalTickUpper
        ) = LiquidityNftHelper.getTickInfo(
                IStrategyInfo(_strategyContract).liquidityNftId(),
                Constants.UNISWAP_V3_FACTORY_ADDRESS,
                Constants.NONFUNGIBLE_POSITION_MANAGER_ADDRESS
            );

        emit RescaleStart(
            _strategyContract,
            msg.sender,
            _wasInRange,
            IStrategyInfo(_strategyContract).tickSpacing(),
            tickGapUpper[_strategyContract],
            tickGapLower[_strategyContract],
            tickBoundaryOffset[_strategyContract],
            lastRescaleTick[_strategyContract],
            currentTick,
            originalTickUpper,
            originalTickLower
        );
    }

    function triggerRescaleEndEvent(
        address _strategyContract,
        int24 newTickUpper,
        int24 newTickLower
    ) internal {
        (int24 currentTick, , ) = LiquidityNftHelper.getTickInfo(
            IStrategyInfo(_strategyContract).liquidityNftId(),
            Constants.UNISWAP_V3_FACTORY_ADDRESS,
            Constants.NONFUNGIBLE_POSITION_MANAGER_ADDRESS
        );

        emit RescaleEnd(
            _strategyContract,
            msg.sender,
            IStrategyInfo(_strategyContract).dustToken0Amount(),
            IStrategyInfo(_strategyContract).dustToken1Amount(),
            IStrategyInfo(_strategyContract).tickSpacing(),
            currentTick,
            tickSpreadUpper[_strategyContract],
            tickSpreadLower[_strategyContract],
            rescaleTickBoundaryOffset[_strategyContract],
            newTickUpper,
            newTickLower
        );
    }

    /// @dev deposit dust token related
    function depositDustToken(
        address _strategyContract,
        bool _depositDustToken0
    ) public onlyRole(EXECUTOR_ROLE) {
        (
            uint256 increasedToken0Amount,
            uint256 increasedToken1Amount
        ) = IStrategy(_strategyContract).depositDustToken(_depositDustToken0);

        emit DepositDustToken(
            _strategyContract,
            msg.sender,
            IStrategyInfo(_strategyContract).liquidityNftId(),
            _depositDustToken0,
            increasedToken0Amount,
            increasedToken1Amount,
            IStrategyInfo(_strategyContract).dustToken0Amount(),
            IStrategyInfo(_strategyContract).dustToken1Amount()
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Querier {
    function decimals() external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IController {
    function tickSpreadUpper(
        address strategyAddress
    ) external view returns (int24);

    function tickSpreadLower(
        address strategyAddress
    ) external view returns (int24);

    function tickGapUpper(
        address strategyAddress
    ) external view returns (int24);

    function tickGapLower(
        address strategyAddress
    ) external view returns (int24);

    function tickBoundaryOffset(
        address strategyAddress
    ) external view returns (int24);

    function rescaleTickBoundaryOffset(
        address strategyAddress
    ) external view returns (int24);

    function lastRescaleTick(
        address strategyAddress
    ) external view returns (int24);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IControllerEvent {
    event SetTransactionDeadlineDuration(
        address indexed strategyContract,
        address indexed executorAddress,
        uint256 transactionDeadlineDuration
    );

    event SetTickSpreadUpper(
        address indexed strategyContract,
        address indexed executorAddress,
        int24 tickSpreadUpper
    );

    event SetTickSpreadLower(
        address indexed strategyContract,
        address indexed executorAddress,
        int24 tickSpreadLower
    );

    event SetTickGapUpper(
        address indexed strategyContract,
        address indexed executorAddress,
        int24 tickGapUpper
    );

    event SetTickGapLower(
        address indexed strategyContract,
        address indexed executorAddress,
        int24 tickGapLower
    );

    event SetBuyBackToken(
        address indexed strategyContract,
        address indexed executorAddress,
        address buyBackToken
    );

    event SetBuyBackNumerator(
        address indexed strategyContract,
        address indexed executorAddress,
        uint24 buyBackNumerator
    );

    event SetFundManagerVaultByIndex(
        address indexed strategyContract,
        address indexed executorAddress,
        uint256 index,
        address fundManagerVaultAddress,
        uint24 fundManagerProfitVaultNumerator
    );

    event SetFundManagerByIndex(
        address indexed fundManagerVaultAddress,
        address indexed executorAddress,
        uint256 index,
        address fundManagerAddress,
        uint24 fundManagerProfitNumerator
    );

    event SetEarnLoopSegmentSize(
        address indexed strategyContract,
        address indexed executorAddress,
        uint256 earnLoopSegmentSize
    );

    event SetTickBoundaryOffset(
        address indexed strategyContract,
        address indexed executorAddress,
        int24 tickBoundaryOffset
    );

    event SetRescaleTickBoundaryOffset(
        address indexed strategyContract,
        address indexed executorAddress,
        int24 rescaleTickBoundaryOffset
    );

    event CollectRewards(
        address indexed strategyContract,
        address indexed executorAddress,
        uint256 indexed liquidityNftId,
        uint256 rewardToken0Amount,
        uint256 rewardToken1Amount,
        uint256 rewardWbtcAmount
    );

    event EarnPreparation(
        address indexed strategyContract,
        address indexed executorAddress,
        uint256 indexed liquidityNftId,
        uint256 rewardWbtcAmount,
        uint256 remainingEarnCountDown
    );

    event Earn(
        address indexed strategyContract,
        address indexed executorAddress,
        uint256 indexed liquidityNftId,
        uint256 remainingEarnCountDown
    );

    event Allocate(
        address indexed fundManagerVaultAddress,
        address indexed executorAddress,
        uint256 allocatedWbtcAmount,
        uint256 remainingWbtcAmount
    );

    event RescaleStart(
        address indexed strategyContract,
        address indexed executorAddress,
        bool wasInRange,
        int24 tickSpacing,
        int24 tickGapUpper,
        int24 tickGapLower,
        int24 tickBoundaryOffset,
        int24 lastRescaleTick,
        int24 thisRescaleTick,
        int24 originalTickUpper,
        int24 originalTickLower
    );

    event RescaleEnd(
        address indexed strategyContract,
        address indexed executorAddress,
        uint256 dustToken0Amount,
        uint256 dustToken1Amount,
        int24 tickSpacing,
        int24 thisRescaleTick,
        int24 tickSpreadUpper,
        int24 tickSpreadLower,
        int24 rescaleTickBoundaryOffset,
        int24 newTickUpper,
        int24 newTickLower
    );

    event DepositDustToken(
        address indexed strategyContract,
        address indexed executorAddress,
        uint256 indexed liquidityNftId,
        bool depositDustToken0,
        uint256 increasedToken0Amount,
        uint256 increasedToken1Amount,
        uint256 dustToken0Amount,
        uint256 dustToken1Amount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFundManagerVault {
    struct FundManager {
        address fundManagerAddress;
        uint256 fundManagerProfitNumerator;
    }

    function getWbtcBalance() external view returns (uint256);

    function getAllFundManagers() external view returns (FundManager[4] memory);

    function setFundManagerByIndex(
        uint256 index,
        address fundManagerAddress,
        uint24 fundManagerProfitNumerator
    ) external;

    function allocate() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRescaleTickBoundaryCalculator {
    function verifyAndGetNewRescaleTickBoundary(
        bool wasInRange,
        int24 lastRescaleTick,
        address strategyAddress,
        address controllerAddress
    )
        external
        view
        returns (bool allowRescale, int24 newTickUpper, int24 newTickLower);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrategy {
    function depositLiquidity(
        bool isETH,
        address userAddress,
        address inputToken,
        uint256 inputAmount,
        uint256 swapInAmount,
        uint256 minimumSwapOutAmount
    )
        external
        payable
        returns (
            uint256 increasedToken0Amount,
            uint256 increasedToken1Amount,
            uint256 sendBackToken0Amount,
            uint256 sendBackToken1Amount
        );

    function withdrawLiquidity(
        address userAddress,
        uint256 withdrawShares
    )
        external
        returns (
            uint256 userReceivedToken0Amount,
            uint256 userReceivedToken1Amount
        );

    function collectRewards() external;

    function earnPreparation(
        uint256 minimumToken0SwapOutAmount,
        uint256 minimumToken1SwapOutAmount,
        uint256 minimumBuybackSwapOutAmount
    ) external;

    function earn() external;

    function claimReward(address userAddress) external;

    function rescale(int24 newTickUpper, int24 newTickLower) external;

    function depositDustToken(
        bool depositDustToken0
    )
        external
        returns (uint256 increasedToken0Amount, uint256 increasedToken1Amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrategyInfo {
    /// @dev Uniswap-Transaction-related Variable
    function transactionDeadlineDuration() external view returns (uint256);

    /// @dev get Liquidity-NFT-related Variable
    function liquidityNftId() external view returns (uint256);

    function tickSpacing() external view returns (int24);

    /// @dev get Pool-related Variable
    function poolAddress() external view returns (address);

    function poolFee() external view returns (uint24);

    function token0Address() external view returns (address);

    function token1Address() external view returns (address);

    /// @dev get Tracker-Token-related Variable
    function trackerTokenAddress() external view returns (address);

    /// @dev get User-Management-related Variable
    function isInUserList(address userAddress) external view returns (bool);

    function userIndex(address userAddress) external view returns (uint256);

    function getAllUsersInUserList() external view returns (address[] memory);

    /// @dev get User-Share-Management-related Variable
    function userShare(address userAddress) external view returns (uint256);

    function totalUserShare() external view returns (uint256);

    /// @dev get Reward-Management-related Variable
    function rewardToken0Amount() external view returns (uint256);

    function rewardToken1Amount() external view returns (uint256);

    function rewardWbtcAmount() external view returns (uint256);

    /// @dev get User-Reward-Management-related Variable
    function userWbtcReward(
        address userAddress
    ) external view returns (uint256);

    function totalUserWbtcReward() external view returns (uint256);

    /// @dev get Buyback-related Variable
    function buyBackToken() external view returns (address);

    function buyBackNumerator() external view returns (uint24);

    /// @dev get Fund-Manager-related Variable
    struct FundManagerVault {
        address fundManagerVaultAddress;
        uint256 fundManagerProfitVaultNumerator;
    }

    function getAllFundManagerVaults()
        external
        view
        returns (FundManagerVault[3] memory);

    /// @dev get Earn-Loop-Control-related Variable
    function earnLoopSegmentSize() external view returns (uint256);

    function earnLoopDistributedAmount() external view returns (uint256);

    function earnLoopStartIndex() external view returns (uint256);

    function isEarning() external view returns (bool);

    /// @dev get Rescale-related Variable
    function dustToken0Amount() external view returns (uint256);

    function dustToken1Amount() external view returns (uint256);

    /// @dev get Constant Variable
    function getBuyBackDenominator() external pure returns (uint24);

    function getFundManagerProfitVaultDenominator()
        external
        pure
        returns (uint24);

    function getFarmAddress() external pure returns (address);

    function getControllerAddress() external pure returns (address);

    function getSwapAmountCalculatorAddress() external pure returns (address);

    function getZapAddress() external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrategySetter {
    function setTransactionDeadlineDuration(
        uint256 _transactionDeadlineDuration
    ) external;

    function setBuyBackToken(address _buyBackToken) external;

    function setBuyBackNumerator(uint24 _buyBackNumerator) external;

    function setFundManagerVaultByIndex(
        uint256 index,
        address _fundManagerVaultAddress,
        uint24 _fundManagerProfitVaultNumerator
    ) external;

    function setEarnLoopSegmentSize(uint256 _earnLoopSegmentSize) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface INonfungiblePositionManager {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    )
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IUniswapV3Pool {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Constants {
    /// @dev ArbiturmOne & Goerli uniswap V3
    address public constant UNISWAP_V3_FACTORY_ADDRESS =
        address(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address public constant NONFUNGIBLE_POSITION_MANAGER_ADDRESS =
        address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address public constant SWAP_ROUTER_ADDRESS =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @dev ArbiturmOne token address
    address public constant WETH_ADDRESS =
        address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public constant ARB_ADDRESS =
        address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address public constant WBTC_ADDRESS =
        address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    address public constant USDC_ADDRESS =
        address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    address public constant USDCE_ADDRESS =
        address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address public constant USDT_ADDRESS =
        address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    address public constant RDNT_ADDRESS =
        address(0x3082CC23568eA640225c2467653dB90e9250AaA0);
    address public constant LINK_ADDRESS =
        address(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4);

    /// @dev black hole address
    address public constant BLACK_HOLE_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/uniswapV3/INonfungiblePositionManager.sol";
import "./uniswapV3/TickMath.sol";
import "./PoolHelper.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LiquidityNftHelper {
    using SafeMath for uint256;

    function getLiquidityAmountByNftId(
        uint256 liquidityNftId,
        address nonfungiblePositionManagerAddress
    ) internal view returns (uint128 liquidity) {
        (, , , , , , , liquidity, , , , ) = INonfungiblePositionManager(
            nonfungiblePositionManagerAddress
        ).positions(liquidityNftId);
    }

    function getPoolInfoByLiquidityNft(
        uint256 liquidityNftId,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    )
        internal
        view
        returns (
            address poolAddress,
            int24 tick,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        )
    {
        (
            address token0,
            address token1,
            uint24 poolFee,
            ,
            ,
            ,

        ) = getLiquidityNftPositionsInfo(
                liquidityNftId,
                nonfungiblePositionManagerAddress
            );
        poolAddress = PoolHelper.getPoolAddress(
            uniswapV3FactoryAddress,
            token0,
            token1,
            poolFee
        );
        (, , , tick, sqrtPriceX96, decimal0, decimal1) = PoolHelper.getPoolInfo(
            poolAddress
        );
    }

    function getLiquidityNftPositionsInfo(
        uint256 liquidityNftId,
        address nonfungiblePositionManagerAddress
    )
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 poolFee,
            int24 tickLower,
            int24 tickUpper,
            uint160 sqrtRatioAX96,
            uint160 sqrtRatioBX96
        )
    {
        (
            ,
            ,
            token0,
            token1,
            poolFee,
            tickLower,
            tickUpper,
            ,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(nonfungiblePositionManagerAddress)
            .positions(liquidityNftId);
        sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    }

    /// @dev formula explanation
    /*
    [Original formula (without decimal precision)]
    tickUpper -> sqrtRatioBX96
    tickLower -> sqrtRatioAX96
    tick      -> sqrtPriceX96
    (token1 * (10^decimal1)) / (token0 * (10^decimal0)) = 
        (sqrtPriceX96 * sqrtRatioBX96 * (sqrtPriceX96 - sqrtRatioAX96))
            / ((2^192) * (sqrtRatioBX96 - sqrtPriceX96))
    
    [Formula with decimal precision & decimal adjustment]
    liquidityRatioWithDecimalAdj = liquidityRatio * (10^decimalPrecision)
        = (sqrtPriceX96 * (10^decimalPrecision) / (2^96))
            * (sqrtPriceBX96 * (10^decimalPrecision) / (2^96))
            * (sqrtPriceX96 - sqrtRatioAX96)
            / ((sqrtRatioBX96 - sqrtPriceX96) * (10^(decimalPrecision + decimal1 - decimal0)))
    */
    function getInRangeLiquidityRatioWithDecimals(
        uint256 liquidityNftId,
        uint256 decimalPrecision,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    ) internal view returns (uint256 liquidityRatioWithDecimals) {
        // get sqrtPrice of tickUpper, tick, tickLower
        (
            ,
            ,
            ,
            ,
            ,
            uint160 sqrtRatioAX96,
            uint160 sqrtRatioBX96
        ) = getLiquidityNftPositionsInfo(
                liquidityNftId,
                nonfungiblePositionManagerAddress
            );
        (
            ,
            ,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        ) = getPoolInfoByLiquidityNft(
                liquidityNftId,
                uniswapV3FactoryAddress,
                nonfungiblePositionManagerAddress
            );

        // when decimalPrecision is 18,
        // calculation restriction: 79228162514264337594 <= sqrtPriceX96 <= type(uint160).max
        uint256 scaledPriceX96 = uint256(sqrtPriceX96)
            .mul(10 ** decimalPrecision)
            .div(2 ** 96);
        uint256 scaledPriceBX96 = uint256(sqrtRatioBX96)
            .mul(10 ** decimalPrecision)
            .div(2 ** 96);

        uint256 decimalAdj = decimalPrecision.add(decimal1).sub(decimal0);
        uint256 preLiquidityRatioWithDecimals = scaledPriceX96
            .mul(scaledPriceBX96)
            .div(10 ** decimalAdj);

        liquidityRatioWithDecimals = preLiquidityRatioWithDecimals
            .mul(uint256(sqrtPriceX96).sub(sqrtRatioAX96))
            .div(uint256(sqrtRatioBX96).sub(sqrtPriceX96));
    }

    function verifyInputTokenIsLiquidityNftTokenPair(
        uint256 liquidityNftId,
        address inputToken,
        address nonfungiblePositionManagerAddress
    ) internal view {
        (
            address token0,
            address token1,
            ,
            ,
            ,
            ,

        ) = getLiquidityNftPositionsInfo(
                liquidityNftId,
                nonfungiblePositionManagerAddress
            );
        require(
            inputToken == token0 || inputToken == token1,
            "inputToken not in token pair"
        );
    }

    function verifyCurrentPriceInLiquidityNftRange(
        uint256 liquidityNftId,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    ) internal view returns (bool isInRange, address liquidity0Token) {
        (, int24 tick, , , ) = getPoolInfoByLiquidityNft(
            liquidityNftId,
            uniswapV3FactoryAddress,
            nonfungiblePositionManagerAddress
        );
        (
            address token0,
            address token1,
            ,
            int24 tickLower,
            int24 tickUpper,
            ,

        ) = getLiquidityNftPositionsInfo(
                liquidityNftId,
                nonfungiblePositionManagerAddress
            );

        // tick out of range, tick <= tickLower left token0
        if (tick <= tickLower) {
            return (false, token0);

            // tick in range, tickLower < tick < tickUpper
        } else if (tick < tickUpper) {
            return (true, address(0));

            // tick out of range, tick >= tickUpper left token1
        } else {
            return (false, token1);
        }
    }

    function getTickInfo(
        uint256 liquidityNftId,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    ) internal view returns (int24 tick, int24 tickLower, int24 tickUpper) {
        (, tick, , , ) = getPoolInfoByLiquidityNft(
            liquidityNftId,
            uniswapV3FactoryAddress,
            nonfungiblePositionManagerAddress
        );
        (, , , tickLower, tickUpper, , ) = getLiquidityNftPositionsInfo(
            liquidityNftId,
            nonfungiblePositionManagerAddress
        );
    }

    function verifyNoDuplicateTickAndTickLower(
        uint256 liquidityNftId,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    ) internal view {
        (int24 tick, int24 tickLower, ) = getTickInfo(
            liquidityNftId,
            uniswapV3FactoryAddress,
            nonfungiblePositionManagerAddress
        );

        require(tickLower != tick, "tickLower == tick");
    }

    // for general condition (except tickSpacing 1 condition)
    function calculateInitTickBoundary(
        address poolAddress,
        int24 tickSpread,
        int24 tickSpacing
    ) internal view returns (int24 tickLower, int24 tickUpper) {
        require(tickSpacing != 1, "tickSpacing == 1");

        // Get current tick
        (, , , int24 currentTick, , , ) = PoolHelper.getPoolInfo(poolAddress);

        // Calculate the floor tick value
        int24 tickFloor = floorTick(currentTick, tickSpacing);

        // Calculate the tickLower & tickToTickLower value
        tickLower = tickFloor - tickSpacing * tickSpread;
        int24 tickToTickLower = currentTick - tickLower;

        // Calculate the tickUpper & tickUpperToTick value
        tickUpper = floorTick((currentTick + tickToTickLower), tickSpacing);
        int24 tickUpperToTick = tickUpper - currentTick;

        // Check
        // if the tickSpacing is greater than 1
        // and
        // if the (tickToTickLower - tickUpperToTick) is greater than or equal to (tickSpacing / 2)
        if (
            tickSpacing > 1 &&
            (tickToTickLower - tickUpperToTick) >= (tickSpacing / 2)
        ) {
            // Increment the tickUpper by the tickSpacing
            tickUpper += tickSpacing;
        }
    }

    function floorTick(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (int24) {
        int24 baseFloor = tick / tickSpacing;

        if (tick < 0 && tick % tickSpacing != 0) {
            return (baseFloor - 1) * tickSpacing;
        }
        return baseFloor * tickSpacing;
    }

    function ceilingTick(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (int24) {
        int24 baseFloor = tick / tickSpacing;

        if (tick > 0 && tick % tickSpacing != 0) {
            return (baseFloor + 1) * tickSpacing;
        }
        return baseFloor * tickSpacing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ParameterVerificationHelper {
    function verifyNotZeroAddress(address inputAddress) internal pure {
        require(inputAddress != address(0), "input zero address");
    }

    function verifyGreaterThanZero(uint256 inputNumber) internal pure {
        require(inputNumber > 0, "input 0");
    }

    function verifyGreaterThanZero(int24 inputNumber) internal pure {
        require(inputNumber > 0, "input 0");
    }

    function verifyGreaterThanOne(int24 inputNumber) internal pure {
        require(inputNumber > 1, "input <= 1");
    }

    function verifyGreaterThanOrEqualToZero(int24 inputNumber) internal pure {
        require(inputNumber >= 0, "input less than 0");
    }

    function verifyPairTokensHaveWeth(
        address token0Address,
        address token1Address,
        address wethAddress
    ) internal pure {
        require(
            token0Address == wethAddress || token1Address == wethAddress,
            "pair token not have WETH"
        );
    }

    function verifyMsgValueEqualsInputAmount(
        uint256 inputAmount
    ) internal view {
        require(msg.value == inputAmount, "msg.value != inputAmount");
    }

    function verifyPairTokensHaveInputToken(
        address token0Address,
        address token1Address,
        address inputToken
    ) internal pure {
        require(
            token0Address == inputToken || token1Address == inputToken,
            "pair token not have inputToken"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/external/IERC20Querier.sol";
import "../interfaces/uniswapV3/IUniswapV3Factory.sol";
import "../interfaces/uniswapV3/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library PoolHelper {
    using SafeMath for uint256;

    function getPoolAddress(
        address uniswapV3FactoryAddress,
        address tokenA,
        address tokenB,
        uint24 poolFee
    ) internal view returns (address poolAddress) {
        return
            IUniswapV3Factory(uniswapV3FactoryAddress).getPool(
                tokenA,
                tokenB,
                poolFee
            );
    }

    function getPoolInfo(
        address poolAddress
    )
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 poolFee,
            int24 tick,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        )
    {
        (sqrtPriceX96, tick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();
        token0 = IUniswapV3Pool(poolAddress).token0();
        token1 = IUniswapV3Pool(poolAddress).token1();
        poolFee = IUniswapV3Pool(poolAddress).fee();
        decimal0 = IERC20Querier(token0).decimals();
        decimal1 = IERC20Querier(token1).decimals();
    }

    /// @dev formula explanation
    /*
    [Original formula (without decimal precision)]
    (token1 * (10^decimal1)) / (token0 * (10^decimal0)) = (sqrtPriceX96 / (2^96))^2   
    tokenPrice = token1/token0 = (sqrtPriceX96 / (2^96))^2 * (10^decimal0) / (10^decimal1)

    [Formula with decimal precision & decimal adjustment]
    tokenPriceWithDecimalAdj = tokenPrice * (10^decimalPrecision)
        = (sqrtPriceX96 * (10^decimalPrecision) / (2^96))^2 
            / 10^(decimalPrecision + decimal1 - decimal0)
    */
    function getTokenPriceWithDecimalsByPool(
        address poolAddress,
        uint256 decimalPrecision
    ) internal view returns (uint256 tokenPriceWithDecimals) {
        (
            ,
            ,
            ,
            ,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        ) = getPoolInfo(poolAddress);

        // when decimalPrecision is 18,
        // calculation restriction: 79228162514264337594 <= sqrtPriceX96 <= type(uint160).max
        uint256 scaledPriceX96 = uint256(sqrtPriceX96)
            .mul(10 ** decimalPrecision)
            .div(2 ** 96);
        uint256 tokenPriceWithoutDecimalAdj = scaledPriceX96.mul(
            scaledPriceX96
        );
        uint256 decimalAdj = decimalPrecision.add(decimal1).sub(decimal0);
        uint256 result = tokenPriceWithoutDecimalAdj.div(10 ** decimalAdj);
        require(result > 0, "token price too small");
        tokenPriceWithDecimals = result;
    }

    function getTokenDecimalAdjustment(
        address token
    ) internal view returns (uint256 decimalAdjustment) {
        uint256 tokenDecimalStandard = 18;
        uint256 decimal = IERC20Querier(token).decimals();
        return tokenDecimalStandard.sub(decimal);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(
        int24 tick
    ) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }
}