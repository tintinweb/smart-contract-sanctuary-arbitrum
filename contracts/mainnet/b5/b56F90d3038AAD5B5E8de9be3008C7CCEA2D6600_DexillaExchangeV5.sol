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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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



pragma solidity ^0.8.0;

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// License-Identifier: GPL-2.0-or-later
abstract contract Multicall {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint i; i < data.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/token/IERC20Permit2.sol";
import "../interfaces/token/IERC20PermitAllowed.sol";

abstract contract SelfPermit {
    function selfPermit(address token, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public payable {
        IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function selfPermit2(address token, uint value, uint deadline, bytes calldata signature) public payable {
        IERC20Permit2(token).permit2(msg.sender, address(this), value, deadline, signature);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.19;

import "./interfaces/token/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./abstract/Multicall.sol";
import "./abstract/SelfPermit.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DexillaExchangeV5 is AccessControl, ReentrancyGuard, Multicall, SelfPermit {
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");

    uint public tradeFee = 10; // 0.1%
    uint public totalBaseFee = 0;
    uint public totalQuoteFee = 0;

    uint8 private immutable BASE_TOKEN_DECIMALS;
    uint8 private immutable QUOTE_TOKEN_DECIMALS;

    address public immutable baseToken;
    address public immutable quoteToken; // should be a USD token
    address public immutable weth;

    mapping(address => mapping(uint => uint)) public bids; // owner, price, quantity
    mapping(address => mapping(uint => uint)) public asks; // owner, price, quantity

    bool public pausedTrading = false;

    uint private _counter;

    // Event emitted when an order is created.
    event OrderCreated(address indexed maker, uint8 side, uint price, uint quantity);

    // Event emitted when an order is executed.
    event OrderExecuted(address indexed maker, address indexed taker, uint8 side, uint price, uint quantity, uint fee);

    // Event emitted when the size of an order is adjusted.
    event OrderSizeAdjusted(address indexed maker, uint8 side, uint price, uint quantity);

    // Event emitted when an order is canceled.
    event OrderCanceled(address indexed maker, uint8 side, uint price, uint quantity);

    // Event emitted when accumulated fees are withdrawn.
    event FeeWithdrawn(address indexed owner, uint baseFee, uint quoteFee);

    // Event emitted when the trade fee is adjusted.
    event TradeFeeAdjusted(uint tradeFee);

    // Event emitted when trading is paused or resumed.
    event TradingPaused(bool oldPauseTrading, bool newPauseTrading);

    modifier resetCounter() {
        // Using this modifier to deal native token transfer when using multi order execution
        _;
        _counter = 0;
    }

    modifier whenNotPausedTrading() {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!pausedTrading, "Trading is paused");
        _;
    }

    /**
     * @notice Contract constructor.
     * @param _baseToken The address of the base token used for trading.
     * @param _quoteToken The address of the quote token used for trading.
     * @param _weth The address of the WETH (Wrapped Ether) token.
     * @param feeCollector The address of the fee collector.
     * @param _tradeFee The trade fee amount.
     * @dev This constructor is used to initialize the contract with the specified parameters.
     */
    constructor(address _baseToken, address _quoteToken, address _weth, address feeCollector, uint _tradeFee) {
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        weth = _weth;
        tradeFee = _tradeFee;
        BASE_TOKEN_DECIMALS = IERC20(baseToken).decimals();
        QUOTE_TOKEN_DECIMALS = IERC20(quoteToken).decimals();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FEE_COLLECTOR_ROLE, feeCollector);
    }

    /**
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param quantity The quantity of the order.
     * @dev This function is used to create an order. It takes the side, price, and quantity as parameters.
     * @notice DO NOT PASS msg.value MORE THAN THE ACTUAL NEEDED AMOUNT, IT WILL BE LOST FOREVER.
     */
    function createOrder(uint8 side, uint price, uint quantity) public payable nonReentrant whenNotPausedTrading {
        _createOrder(side, price, quantity);
    }

    /**
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param quantity The quantity of the order.
     * @param allowance The allowance granted by the user to spend their tokens.
     * @param deadline The deadline for the permit signature.
     * @param v The recovery byte of the permit signature.
     * @param r The R part of the permit signature.
     * @param s The S part of the permit signature.
     * @dev This function is used to create an order with a permit, which allows spending the user's tokens.
     * @notice DO NOT PASS msg.value MORE THAN THE ACTUAL NEEDED AMOUNT, IT WILL BE LOST FOREVER.
     */
    function createOrderWithPermit(
        uint8 side,
        uint price,
        uint quantity,
        uint allowance,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant whenNotPausedTrading {
        selfPermit(baseToken, allowance, deadline, v, r, s);
        _createOrder(side, price, quantity);
    }

    /**
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param quantity The quantity of the order.
     * @param allowance The allowance granted by the user to spend their tokens.
     * @param deadline The deadline for the permit signature.
     * @param signature The signature containing the permit data.
     * @dev This function is used to create an order with a permit, which allows spending the user's tokens.
     * @notice DO NOT PASS msg.value MORE THAN THE ACTUAL NEEDED AMOUNT, IT WILL BE LOST FOREVER.
     */
    function createOrderWithPermit2(
        uint8 side,
        uint price,
        uint quantity,
        uint allowance,
        uint deadline,
        bytes calldata signature
    ) external payable nonReentrant whenNotPausedTrading {
        selfPermit2(baseToken, allowance, deadline, signature);
        _createOrder(side, price, quantity);
    }

    /**
     * @param makers The array of maker addresses involved in the order.
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param quantity The quantity of the order.
     * @dev This function is used to execute an order. It takes an array of maker addresses,
     * @notice DO NOT PASS msg.value MORE THAN THE ACTUAL NEEDED AMOUNT, IT WILL BE LOST FOREVER.
     */
    function executeOrder(
        address[] memory makers,
        uint8 side,
        uint price,
        uint quantity
    ) public payable nonReentrant whenNotPausedTrading {
        _executeOrder(makers, side, price, quantity);
    }

    /**
     * @param makers The array of maker addresses involved in the order.
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param quantity The quantity of the order.
     * @param allowance The allowance granted by the user to spend their tokens.
     * @param deadline The deadline for the permit signature.
     * @param v The recovery byte of the permit signature.
     * @param r The R part of the permit signature.
     * @param s The S part of the permit signature.
     * @dev This function is used to execute an order with a permit, which allows spending the user's tokens.
     * @notice DO NOT PASS msg.value MORE THAN THE ACTUAL NEEDED AMOUNT, IT WILL BE LOST FOREVER.
     */
    function executeOrderWithPermit(
        address[] memory makers,
        uint8 side,
        uint price,
        uint quantity,
        uint allowance,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant whenNotPausedTrading {
        if (side == 0) {
            selfPermit(quoteToken, allowance, deadline, v, r, s);
        } else {
            selfPermit(baseToken, allowance, deadline, v, r, s);
        }
        _executeOrder(makers, side, price, quantity);
    }

    /**
     * @param makers The array of maker addresses involved in the order.
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param quantity The quantity of the order.
     * @param allowance The allowance granted by the user to spend their tokens.
     * @param deadline The deadline for the permit signature.
     * @param signature The signature containing the permit data.
     * @dev This function is used to execute an order with a permit, which allows spending the user's tokens.
     * @notice DO NOT PASS msg.value MORE THAN THE ACTUAL NEEDED AMOUNT, IT WILL BE LOST FOREVER.
     */
    function executeOrderWithPermit2(
        address[] memory makers,
        uint8 side,
        uint price,
        uint quantity,
        uint allowance,
        uint deadline,
        bytes calldata signature
    ) public payable nonReentrant whenNotPausedTrading {
        if (side == 0) {
            selfPermit2(quoteToken, allowance, deadline, signature);
        } else {
            selfPermit2(baseToken, allowance, deadline, signature);
        }
        _executeOrder(makers, side, price, quantity);
    }

    /**
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param desiredQuantity The desired quantity to adjust the order to.
     * @dev This function is used to adjust the size of an existing order. It takes the side, price,
     * @notice DO NOT PASS msg.value MORE THAN THE ACTUAL NEEDED AMOUNT, IT WILL BE LOST FOREVER.
     */
    function adjustOrderSize(
        uint8 side,
        uint price,
        uint desiredQuantity
    ) public payable nonReentrant whenNotPausedTrading {
        _adjustOrderSize(side, price, desiredQuantity);
    }

    /**
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @dev This function is used to cancel an existing order. It takes the side and price as parameters.
     */
    function cancelOrder(uint8 side, uint price) public nonReentrant {
        require(side < 2, "Invalid side");

        uint quantity;
        if (side == 0) {
            quantity = bids[msg.sender][price];
            require(quantity > 0, "No bid found");
            delete bids[msg.sender][price];
            uint _quantity = _multiply(quantity, BASE_TOKEN_DECIMALS, price, QUOTE_TOKEN_DECIMALS);
            _transfer(quoteToken, msg.sender, _quantity);
        } else {
            quantity = asks[msg.sender][price];
            require(quantity > 0, "No ask found");
            delete asks[msg.sender][price];
            _transfer(baseToken, msg.sender, quantity);
        }

        emit OrderCanceled(msg.sender, side, price, quantity);
    }

    /**
     * @param newTradeFee The new trade fee to be set.
     * @dev This function is used by the default admin role to adjust the trade fee.
     */
    function adjustTradeFee(uint16 newTradeFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newTradeFee <= 1000, "Invalid trade fee");
        tradeFee = newTradeFee;

        emit TradeFeeAdjusted(newTradeFee);
    }

    /**
     * @dev This function is used by the fee collector role to withdraw accumulated fees.
     */
    function withdrawFee() external onlyRole(FEE_COLLECTOR_ROLE) {
        _transfer(baseToken, msg.sender, totalBaseFee);
        _transfer(quoteToken, msg.sender, totalQuoteFee);
        emit FeeWithdrawn(msg.sender, totalBaseFee, totalQuoteFee);
        totalBaseFee = 0;
        totalQuoteFee = 0;
    }

    /**
     * @param state The new state to set for trading (true for paused, false for resumed).
     * @dev This function is used by the default admin role to set the pause state for trading.
     */
    function setPauseTrading(bool state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool oldState = pausedTrading;
        pausedTrading = state;

        emit TradingPaused(oldState, state);
    }

    /**
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param quantity The quantity of the order.
     * @dev The 'resetCounter' modifier resets counters after executed.
     */
    function _createOrder(uint8 side, uint price, uint quantity) private resetCounter {
        require(side < 2, "Invalid side");
        require(price > 0, "Invalid price");

        if (side == 0) {
            uint quoteAmount = _multiply(quantity, BASE_TOKEN_DECIMALS, price, QUOTE_TOKEN_DECIMALS);
            _transferFrom(quoteToken, msg.sender, address(this), quoteAmount); // transfer quote token to this contract
            bids[msg.sender][price] += quantity;
        } else {
            _transferFrom(baseToken, msg.sender, address(this), quantity); // transfer base token to this contract
            asks[msg.sender][price] += quantity;
        }

        emit OrderCreated(msg.sender, side, price, quantity);
    }

    /**
     * @param makers The array of maker addresses involved in the order.
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param quantity The quantity of the order.
     * @dev The 'resetCounter' modifier resets counters after executed.
     */
    function _executeOrder(address[] memory makers, uint8 side, uint price, uint quantity) private resetCounter {
        require(side < 2, "Invalid side");

        uint remainningQuantity = quantity;
        for (uint i; i < makers.length; ++i) {
            require(makers[i] != address(0), "Invalid maker");
            if (side == 0) {
                uint makerQuantity = asks[makers[i]][price];
                if (makerQuantity == 0) continue;
                uint transferQuantity;
                if (makerQuantity >= remainningQuantity) {
                    transferQuantity = remainningQuantity;
                    remainningQuantity = 0;
                } else {
                    transferQuantity = makerQuantity;
                    remainningQuantity = remainningQuantity - makerQuantity;
                }
                uint makerTransferQuantity = _multiply(
                    transferQuantity,
                    BASE_TOKEN_DECIMALS,
                    price,
                    QUOTE_TOKEN_DECIMALS
                );
                _transferFrom(quoteToken, msg.sender, makers[i], makerTransferQuantity); // transfer qoute token from taker to maker
                uint fee = (transferQuantity * tradeFee) / 10000;
                totalBaseFee += fee;
                uint remainningToTaker = transferQuantity - fee;
                _transfer(baseToken, msg.sender, remainningToTaker); // transfer base token from contract to maker
                asks[makers[i]][price] -= transferQuantity;
                if (asks[makers[i]][price] == 0) {
                    delete asks[makers[i]][price];
                    emit OrderCanceled(makers[i], side ^ 1, price, transferQuantity);
                }
                emit OrderExecuted(makers[i], msg.sender, side, price, transferQuantity, fee);
            } else {
                uint makerQuantity = bids[makers[i]][price];
                if (makerQuantity == 0) {
                    if (msg.value == 0) continue;
                    revert("No ask found");
                }
                uint transferQuantity;
                if (makerQuantity >= remainningQuantity) {
                    transferQuantity = remainningQuantity;
                    remainningQuantity = 0;
                } else {
                    transferQuantity = makerQuantity;
                    remainningQuantity = remainningQuantity - makerQuantity;
                }
                _transferFrom(baseToken, msg.sender, makers[i], transferQuantity); // transfer base from taker to maker
                uint quantityWithoutFee = _multiply(transferQuantity, BASE_TOKEN_DECIMALS, price, QUOTE_TOKEN_DECIMALS);
                uint fee = (quantityWithoutFee * tradeFee) / 10000;
                totalQuoteFee += fee;
                uint remainningToTaker = quantityWithoutFee - fee;
                _transfer(quoteToken, msg.sender, remainningToTaker); // transfer usd from contract to taker
                bids[makers[i]][price] -= transferQuantity;
                if (bids[makers[i]][price] == 0) {
                    delete bids[makers[i]][price];
                    emit OrderCanceled(makers[i], side ^ 1, price, transferQuantity);
                }
                emit OrderExecuted(makers[i], msg.sender, side, price, transferQuantity, fee);
            }
            if (remainningQuantity == 0) break;
        }
    }

    /**
     * @param side The side of the order (0 for buy, 1 for sell).
     * @param price The price of the order.
     * @param desiredQuantity The desired quantity to adjust the order to.
     * @dev This function assumes that the order exists and is valid. It does not perform any checks on the order's validity.
     */
    function _adjustOrderSize(uint8 side, uint price, uint desiredQuantity) private resetCounter {
        require(side < 2, "Invalid side");
        require(desiredQuantity > 0, "Invalid amount");

        uint oldQuantity;
        if (side == 0) {
            oldQuantity = bids[msg.sender][price];
            require(oldQuantity > 0, "Order does not exist");
            if (oldQuantity > desiredQuantity) {
                uint _quantity = _multiply(
                    oldQuantity - desiredQuantity,
                    BASE_TOKEN_DECIMALS,
                    price,
                    QUOTE_TOKEN_DECIMALS
                );
                _transfer(quoteToken, msg.sender, _quantity);
            } else if (oldQuantity < desiredQuantity) {
                uint _quantity = _multiply(
                    desiredQuantity - oldQuantity,
                    BASE_TOKEN_DECIMALS,
                    price,
                    QUOTE_TOKEN_DECIMALS
                );
                _transferFrom(quoteToken, msg.sender, address(this), _quantity); // transfer quote token to this contract
            }
            bids[msg.sender][price] = desiredQuantity;
        } else {
            oldQuantity = asks[msg.sender][price];
            require(oldQuantity > 0, "Order does not exist");
            if (oldQuantity > desiredQuantity) {
                _transfer(baseToken, msg.sender, oldQuantity - desiredQuantity);
            } else if (oldQuantity < desiredQuantity) {
                _transferFrom(baseToken, msg.sender, address(this), desiredQuantity - oldQuantity); // transfer base token to this contract
            }
            asks[msg.sender][price] = desiredQuantity;
        }

        emit OrderSizeAdjusted(msg.sender, side, price, desiredQuantity);
    }

    /**
     * @notice This function is used to multiply two numbers with decimal precision.
     * @param x The first number to multiply.
     * @param xDecimals The number of decimal places in the first number.
     * @param y The second number to multiply.
     * @param yDecimals The number of decimal places in the second number.
     * @return The product of the two numbers with proper decimal precision.
     */
    function _multiply(uint x, uint8 xDecimals, uint y, uint8 yDecimals) private pure returns (uint) {
        uint prod = x * y;
        uint8 prodDecimals = xDecimals + yDecimals;
        if (prodDecimals < yDecimals) {
            return prod * (10 ** (yDecimals - prodDecimals));
        } else if (prodDecimals > yDecimals) {
            return prod / (10 ** (prodDecimals - yDecimals));
        } else {
            return prod;
        }
    }

    /**
     * @notice This function is used to transfer tokens from the contract to a specified address.
     * @param token The address of the token to transfer.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function _transfer(address token, address to, uint amount) private {
        require(amount > 0, "Zero amount");
        if (token == weth) {
            IWETH(weth).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
    }

    /**
     * @notice Internal function to transfer tokens from a specified address to another address.
     * @param token The address of the token to transfer.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function _transferFrom(address token, address from, address to, uint amount) private {
        require(amount > 0, "Zero amount");
        if (msg.value > 0) {
            _counter += amount;
            require(_counter <= msg.value, "Incorrect amount");
            if (token == weth) {
                IWETH(weth).deposit{value: amount}();
                if (to != address(this)) {
                    IWETH(weth).withdraw(amount);
                    TransferHelper.safeTransferETH(to, amount);
                }
            } else {
                revert("Invalid token");
            }
        } else {
            TransferHelper.safeTransferFrom(token, from, to, amount);
        }
    }

    /**
     *@notice Fallback function to receive Ether.
     *@dev This function is called when the contract receives Ether.
     */
    receive() external payable {
        require(msg.sender == weth, "Invalid sender");
    }

    /**
     * @notice This type of fallback function is triggered when a transaction is sent to the contract with no data
     * or when the transaction data doesn't match any existing function signatures.
     */
    fallback() external {
        revert();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.5.0;

import "./IERC20Base.sol";

interface IERC20 is IERC20Base {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.5.0;

interface IERC20Base {
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transfer(address to, uint amount) external returns (bool);

    function transferFrom(address from, address to, uint amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.5.0;

import "./IERC20.sol";

interface IERC20Permit is IERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function nonces(address owner) external view returns (uint);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.5.0;

import "./IERC20Permit.sol";

interface IERC20Permit2 is IERC20Permit {
    function permit2(address owner, address spender, uint amount, uint deadline, bytes calldata signature) external;
}

// SPDX-License-Identifier: MIT



pragma solidity >=0.5.0;

/// @title Interface for permit
/// @notice Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice Approve the spender to spend some tokens via the holder signature
    /// @dev This is the permit interface used by DAI and CHAI
    /// @param holder The address of the token holder, the token owner
    /// @param spender The address of the token spender
    /// @param nonce The holder's nonce, increases at each call to permit
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev The ETH transfer has failed.
error ETHTransferFailed();

/// @dev The ERC20 `transferFrom` has failed.
error TransferFromFailed();

/// @dev The ERC20 `transfer` has failed.
error TransferFailed();

/// @dev The ERC20 `approve` has failed.
error ApproveFailed();

/// @dev Helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true / false.
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ApproveFailed();
        }
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFailed();
        }
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert TransferFromFailed();
        }
    }

    function safeTransferETH(address to, uint value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: value}("");

        if (!success) {
            revert ETHTransferFailed();
        }
    }
}