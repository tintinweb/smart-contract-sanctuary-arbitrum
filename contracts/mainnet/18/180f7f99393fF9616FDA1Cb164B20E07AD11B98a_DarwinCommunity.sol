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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import {IDarwinCommunity} from "./interface/IDarwinCommunity.sol";
import {IStakedDarwin} from "./interface/IStakedDarwin.sol";
import {IDarwinStaking} from "./interface/IDarwinStaking.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IDarwin {
    function bulkTransfer(address[] calldata recipients, uint256[] calldata amounts) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function stakedDarwin() external view returns(IStakedDarwin);
}

contract DarwinCommunity is IDarwinCommunity, AccessControl, ReentrancyGuard {

    // roles
    bytes32 public constant OWNER = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN = keccak256("ADMIN_ROLE");
    bytes32 public constant SENIOR_PROPOSER = keccak256("SENIOR_PROPOSER_ROLE");
    bytes32 public constant PROPOSER = keccak256("PROPOSER_ROLE");
    bytes32[4] private _roles = [PROPOSER,SENIOR_PROPOSER,ADMIN,OWNER];

    /// @notice 1. Mapping to ensure execute() is called by 2 admins before actually executing the proposal
    mapping(uint256 => mapping(address => bool)) private _calledExecute;
    /// @notice 2. Mapping to ensure execute() is called by 2 admins before actually executing the proposal
    mapping(uint256 => uint256) private _calls;
    /// @notice Community Fund Candidates
    mapping(uint256 => CommunityFundCandidate) private _communityFundCandidates;
    /// @notice Active Community Fund Candidates
    uint256[] private _activeCommunityFundCandidateIds;
    /// @notice Vote Receipts
    mapping(uint256 => mapping(address => Receipt)) private _voteReceipts;
    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) private _proposals;
    /// @notice Restricted proposal actions, only senior proposers can create proposals with these signature
    mapping(uint256 => bool) private _restrictedProposalActionSignature;

    uint public constant VOTE_LOCK_PERIOD = 365 days;
    uint public constant CALLS_TO_EXECUTE = 2;

    uint256 public lastCommunityFundCandidateId;
    uint256 public lastProposalId;
    uint256 public minDarwinTransferToAccess;
    uint256 public proposalMinVotesCountForAction;
    uint256 public proposalMaxOperations;
    uint256 public minVotingDelay;
    uint256 public minVotingPeriod;
    uint256 public maxVotingPeriod;
    uint256 public gracePeriod;

    IDarwin public darwin;
    IStakedDarwin public stakedDarwin;
    IDarwinStaking public staking;

    constructor(address _kieran) {
        _grantRole(OWNER, msg.sender);
        _grantRole(OWNER, _kieran); // Team Lead
        _grantRole(OWNER, 0x0Dd936acE5DF9Dc03891F9CD8a9bac74BF835407); // TRYPTO
    }

    modifier isProposalIdValid(uint256 _id) {
        require(_id > 0 && _id <= lastProposalId, "DC::isProposalIdValid invalid id");
        _;
    }

    modifier onlyDarwinCommunity() {
        require(_msgSender() == address(this), "DC::onlyDarwinCommunity: only DarwinCommunity can access");
        _;
    }

    /// @notice Overrides AccessControl's hasRole to allow more important roles to act like they also have less important roles' permissions
    function hasRole(bytes32 _role, address _addr) public view override returns(bool) {
        bool passed = false;
        for (uint i = 0; i < _roles.length; i++) {
            if (!passed && _role == _roles[i]) {
                passed = true;
            }
            if (passed && super.hasRole(_roles[i], _addr)) {
                return true;
            }
        }
        return false;
    }

    function init(address _darwin, address[] memory fundAddress, string[] memory initialFundProposalStrings, string[] memory restrictedProposalSignatures) external onlyRole(OWNER) {
        require(address(_darwin) != address(0), "DC::init: ZERO_ADDRESS");
        require(address(darwin) == address(0), "DC::init: already initialized");
        require(fundAddress.length == initialFundProposalStrings.length, "DC::init: invalid lengths");

        darwin = IDarwin(_darwin);
        stakedDarwin = darwin.stakedDarwin();
        staking = IDarwinStaking(stakedDarwin.darwinStaking());

        proposalMaxOperations = 1;
        minVotingDelay = 24 hours;
        minVotingPeriod = 24 hours;
        maxVotingPeriod = 1 weeks;
        gracePeriod = 72 hours;
        proposalMinVotesCountForAction = 1000;

        minDarwinTransferToAccess = 1e18; // 1 darwin

        for (uint256 i = 0; i < restrictedProposalSignatures.length; i++) {
            uint256 signature = uint256(keccak256(bytes(restrictedProposalSignatures[i])));
            _restrictedProposalActionSignature[signature] = true;
        }

        for (uint256 i = 0; i < initialFundProposalStrings.length; i++) {
            uint256 id = lastCommunityFundCandidateId + 1;

            _communityFundCandidates[id] = CommunityFundCandidate({
                id: id,
                valueAddress: fundAddress[i],
                isActive: true
            });

            emit NewFundCandidate(id, fundAddress[i], initialFundProposalStrings[i]);

            _activeCommunityFundCandidateIds.push(id);
            lastCommunityFundCandidateId = id;
        }
    }

    function setDarwinAddress(address _darwin) external onlyDarwinCommunity {
        require(_darwin != address(0), "DC:setDarwinAddress:: zero address");
        darwin = IDarwin(_darwin);
    }

    function _randomBoolean() private view returns (bool) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 2 > 0;
    }

    function deactivateFundCandidate(uint256 _id) external onlyDarwinCommunity {
        require(_communityFundCandidates[_id].isActive, "DC::deactivateFundCandidate: not active");

        _communityFundCandidates[_id].isActive = false;

        for (uint256 i = 0; i < _activeCommunityFundCandidateIds.length; i++) {
            if (_activeCommunityFundCandidateIds[i] == _id) {
                _activeCommunityFundCandidateIds[i] = _activeCommunityFundCandidateIds[
                    _activeCommunityFundCandidateIds.length - 1
                ];
                _activeCommunityFundCandidateIds.pop();
                break;
            }
        }

        emit FundCandidateDeactivated(_id);
    }

    function newFundCandidate(address valueAddress, string calldata proposal) public onlyDarwinCommunity {
        require(valueAddress != address(0), "DC:newFundCandidate:: zero address");

        uint256 id = lastCommunityFundCandidateId + 1;

        _communityFundCandidates[id] = CommunityFundCandidate({ id: id, valueAddress: valueAddress, isActive: true });

        _activeCommunityFundCandidateIds.push(id);
        lastCommunityFundCandidateId = id;

        emit NewFundCandidate(id, valueAddress, proposal);
    }

    function _getCommunityTokens(
        uint256[] memory candidates,
        uint256[] memory votes,
        uint256 totalVoteCount,
        uint256 tokensToDistribute
    )
        private
        view
        returns (
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        address[] memory allTokenRecepients = new address[](candidates.length);
        uint256[] memory allTokenDistribution = new uint256[](candidates.length);
        uint256 validRecepientsCount = 0;

        bool[] memory isValid = new bool[](candidates.length);

        uint256 _totalVoteCount = 0;

        for (uint256 i = 0; i < candidates.length; ) {
            allTokenRecepients[i] = _communityFundCandidates[candidates[i]].valueAddress;
            allTokenDistribution[i] = (tokensToDistribute * votes[i]) / totalVoteCount;

            if (
                allTokenRecepients[i] != address(0) &&
                allTokenRecepients[i] != address(this) &&
                allTokenDistribution[i] > 0
            ) {
                validRecepientsCount += 1;
                isValid[i] = true;
            } else {
                isValid[i] = false;
            }

            _totalVoteCount += votes[i];

            unchecked {
                i++;
            }
        }

        address[] memory _recepients = new address[](validRecepientsCount);
        uint256[] memory _tokens = new uint256[](validRecepientsCount);

        uint256 index = 0;

        for (uint256 i = 0; i < candidates.length; ) {
            if (isValid[i]) {
                _recepients[i] = allTokenRecepients[i];
                _tokens[i] = allTokenDistribution[i];

                unchecked {
                    index++;
                }
            }

            unchecked {
                i++;
            }
        }

        return (allTokenDistribution, _recepients, _tokens);
    }

    function distributeCommunityFund(
        uint256 fundWeek,
        uint256[] calldata candidates,
        uint256[] calldata votes,
        uint256 totalVoteCount,
        uint256 tokensToDistribute
    ) external onlyRole(OWNER) {
        require(candidates.length == votes.length, "DC::distributeCommunityFund: candidates and votes length mismatch");
        require(candidates.length > 0, "DC::distributeCommunityFund: empty candidates");

        uint256 communityTokens = darwin.balanceOf(address(this));

        require(communityTokens >= tokensToDistribute, "DC::distributeCommunityFund: not enough tokens");

        (
            uint256[] memory allTokenDistribution,
            address[] memory recipientsToTransfer,
            uint256[] memory tokenAmountToTransfer
        ) = _getCommunityTokens(candidates, votes, totalVoteCount, tokensToDistribute);

        darwin.bulkTransfer(recipientsToTransfer, tokenAmountToTransfer);

        emit CommunityFundDistributed(fundWeek, candidates, allTokenDistribution);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory title,
        string memory description,
        string memory other,
        uint256 endTime
    ) external onlyRole(PROPOSER) returns (uint256) {
        require(darwin.transferFrom(msg.sender, address(this), minDarwinTransferToAccess), "DC::propose: not enough $DARWIN in wallet");

        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "DC::propose: proposal function information arity mismatch"
        );

        require(targets.length <= proposalMaxOperations, "DC::propose: too many actions");

        {
            uint256 earliestEndTime = block.timestamp + minVotingDelay + minVotingPeriod;
            uint256 furthestEndDate = block.timestamp + minVotingDelay + maxVotingPeriod;

            require(endTime >= earliestEndTime, "DC::propose: too early end time");
            require(endTime <= furthestEndDate, "DC::propose: too late end time");
        }

        uint256 startTime = block.timestamp + minVotingDelay;

        uint256 proposalId = lastProposalId + 1;

        for (uint256 i = 0; i < signatures.length; i++) {
            uint256 signature = uint256(keccak256(bytes(signatures[i])));

            if (_restrictedProposalActionSignature[signature]) {
                require(hasRole(SENIOR_PROPOSER, msg.sender), "DC::propose: proposal signature restricted");
            }
        }

        Proposal memory newProposal = Proposal({
            id: proposalId,
            proposer: msg.sender,
            targets: targets,
            values: values,
            darwinAmount: minDarwinTransferToAccess,
            signatures: signatures,
            calldatas: calldatas,
            startTime: startTime,
            endTime: endTime,
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false
        });

        lastProposalId = proposalId;
        _proposals[newProposal.id] = newProposal;

        emit ProposalCreated(newProposal.id, msg.sender, startTime, endTime, title, description, other);
        return newProposal.id;
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view isProposalIdValid(proposalId) returns (ProposalState) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        } else if (proposal.forVotes < proposal.againstVotes) {
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.endTime + gracePeriod) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint256 proposalId) external isProposalIdValid(proposalId) {
        require(state(proposalId) != ProposalState.Executed, "DC::cancel: cannot cancel executed proposal");

        Proposal storage proposal = _proposals[proposalId];

        require(_msgSender() == proposal.proposer || hasRole(ADMIN, _msgSender()), "DC::cancel: cannot cancel proposal");

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param inSupport The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(
        uint256 proposalId,
        bool inSupport
    ) external {
        uint sBalance = stakedDarwin.balanceOf(msg.sender);
        require(minDarwinTransferToAccess <= sBalance, "DC::castVote: not enough StakedDarwin to vote");
        require(staking.getUserInfo(msg.sender).lockEnd >= _proposals[proposalId].endTime, "DC::castVote: the staking locking period ends before the proposal end time");

        _castVoteInternal(_msgSender(), proposalId, sBalance, inSupport);
        emit VoteCast(_msgSender(), proposalId, inSupport);
    }

    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param inSupport The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function _castVoteInternal(
        address voter,
        uint256 proposalId,
        uint256 darwinAmount,
        bool inSupport
    ) private {
        require(state(proposalId) == ProposalState.Active, "DC::castVoteInternal: voting is closed");

        Receipt storage receipt = _voteReceipts[proposalId][voter];
        Proposal storage proposal = _proposals[proposalId];

        require(receipt.hasVoted == false, "DC::castVoteInternal: voter already voted");

        receipt.hasVoted = true;
        receipt.inSupport = inSupport;
        receipt.darwinAmount = darwinAmount;

        if (inSupport) {
            proposal.forVotes += (darwinAmount / 1e18);
        } else {
            proposal.againstVotes += (darwinAmount / 1e18);
        }
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     * NOTE: to execute a proposal, 2 different ADMINs have to call this. If it is called for the first time, it will just bump the counter by 1 and return without executing.
     */
    function execute(uint256 proposalId) external payable onlyRole(ADMIN) {

        { // ensuring execute() is called by 2 admins before actually executing the proposal
            require(!_calledExecute[proposalId][msg.sender], "DC::execute: caller already voted for execution");
            _calledExecute[proposalId][msg.sender] = true;
            _calls[proposalId]++;
            if (_calls[proposalId] < CALLS_TO_EXECUTE) {
                emit ProposalFirstCallExecuted(proposalId);
                return;
            }
        }

        Proposal storage proposal = _proposals[proposalId];

        require(
            state(proposalId) == ProposalState.Queued,
            "DC::execute: proposal can only be executed if it is queued"
        );

        require(
            proposal.forVotes + proposal.againstVotes >= proposalMinVotesCountForAction,
            "DC::execute: not enough votes received"
        );

        proposal.executed = true;

        if (
            proposal.forVotes != proposal.againstVotes ||
            (proposal.forVotes == proposal.againstVotes && _randomBoolean())
        ) {
            for (uint256 i = 0; i < proposal.targets.length; i++) {
                _executeTransaction(
                    proposal.id,
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i]
                );
            }
        }

        emit ProposalExecuted(proposalId);
    }

    function _executeTransaction(
        uint256 id,
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) private {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data));

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returndata) = target.call{ value: value }(callData);

        require(success, _extractRevertReason(returndata));

        emit ExecuteTransaction(id, txHash, target, value, signature, data);
    }

    function _extractRevertReason(bytes memory revertData) internal pure returns (string memory reason) {
        uint256 length = revertData.length;
        if (length < 68) return "";
        uint256 t;
        assembly {
            revertData := add(revertData, 4)
            t := mload(revertData) // Save the content of the length slot
            mstore(revertData, sub(length, 4)) // Set proper length
        }
        reason = abi.decode(revertData, (string));
        assembly {
            mstore(revertData, t) // Restore the content of the length slot
        }
    }

    function setProposalMaxOperations(uint256 count) external onlyDarwinCommunity {
        proposalMaxOperations = count;
    }

    function setMinVotingDelay(uint256 delay) external onlyDarwinCommunity {
        minVotingDelay = delay;
    }

    function setMinVotingPeriod(uint256 value) external onlyDarwinCommunity {
        minVotingPeriod = value;
    }

    function setMaxVotingPeriod(uint256 value) external onlyDarwinCommunity {
        maxVotingPeriod = value;
    }

    function setGracePeriod(uint256 value) external onlyDarwinCommunity {
        gracePeriod = value;
    }

    function setProposalMinVotesCountForAction(uint256 count) external onlyDarwinCommunity {
        proposalMinVotesCountForAction = count;
    }

    function setOwner(address _account, bool _hasRole) external onlyDarwinCommunity {
        if (_hasRole) {
            _grantRole(OWNER, _account);
        } else {
            _revokeRole(OWNER, _account);
        }
    }

    function setAdmin(address _account, bool _hasRole) external onlyDarwinCommunity {
        if (_hasRole) {
            _grantRole(ADMIN, _account);
        } else {
            _revokeRole(ADMIN, _account);
        }
    }

    function setSeniorProposer(address _account, bool _hasRole) external onlyDarwinCommunity {
        if (_hasRole) {
            _grantRole(SENIOR_PROPOSER, _account);
        } else {
            _revokeRole(SENIOR_PROPOSER, _account);
        }
    }

    function setProposer(address _account, bool _hasRole) external onlyDarwinCommunity {
        if (_hasRole) {
            _grantRole(PROPOSER, _account);
        } else {
            _revokeRole(PROPOSER, _account);
        }
    }

    function getActiveFundCandidates() external view returns (CommunityFundCandidate[] memory) {
        CommunityFundCandidate[] memory candidates = new CommunityFundCandidate[](
            _activeCommunityFundCandidateIds.length
        );
        for (uint256 i = 0; i < _activeCommunityFundCandidateIds.length; i++) {
            candidates[i] = _communityFundCandidates[_activeCommunityFundCandidateIds[i]];
        }
        return candidates;
    }

    function getActiveFundDandidateIds() external view returns (uint256[] memory) {
        return _activeCommunityFundCandidateIds;
    }

    function getProposal(uint256 id) external view isProposalIdValid(id) returns (Proposal memory) {
        return _proposals[id];
    }

    function getVoteReceipt(uint256 id) external view isProposalIdValid(id) returns (DarwinCommunity.Receipt memory) {
        return _voteReceipts[id][_msgSender()];
    }

    function isProposalSignatureRestricted(string calldata signature) external view returns (bool) {
        return _restrictedProposalActionSignature[uint256(keccak256(bytes(signature)))];
    }
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

interface IDarwinCommunity {

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Queued,
        Expired,
        Executed
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        bool hasVoted;
        bool inSupport;
        uint256 darwinAmount;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 darwinAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool canceled;
        bool executed;
    }

    struct CommunityFundCandidate {
        uint256 id;
        address valueAddress;
        bool isActive;
    }

    struct LockInfo {
        uint darwinAmount;
        uint lockEnd;
    }

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool inSupport);
    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 indexed id);
    /// @notice An event emitted when a proposal has been executed
    event ProposalExecuted(uint256 indexed id);
    /// @notice An event emitted when a proposal has been called 1 time for execution
    event ProposalFirstCallExecuted(uint256 indexed id);
    /// @notice An event emitted when a user withdraws the StakedDarwin they previously locked in to cast votes
    event Withdraw(address indexed user, uint256 indexed darwinAmount);
    event ActiveFundCandidateRemoved(uint256 indexed id);
    event ActiveFundCandidateAdded(uint256 indexed id);
    event NewFundCandidate(uint256 indexed id, address valueAddress, string proposal);
    event FundCandidateDeactivated(uint256 indexed id);
    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        uint256 startTime,
        uint256 endTime,
        string title,
        string description,
        string other
    );
    event ExecuteTransaction(
        uint256 indexed id,
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data
    );
    event CommunityFundDistributed(uint256 fundWeek, uint256[] candidates, uint256[] tokens);

    function setDarwinAddress(address account) external;
}

pragma solidity ^0.8.14;

interface IDarwinStaking {

    struct UserInfo {
        uint lastClaimTimestamp;
        uint lockStart;
        uint lockEnd;
        uint boost; // (1, 5, 10, 25, 50)
        address nft;
        uint tokenId;
    }

    event Stake(address indexed user, uint indexed amount);
    event Withdraw(address indexed user, uint indexed amount, uint indexed rewards);

    event StakeEvoture(address indexed user, uint indexed evotureTokenId, uint indexed multiplier);
    event WithdrawEvoture(address indexed user, uint indexed evotureTokenId);

    function getUserInfo(address _user) external view returns (UserInfo memory);
}

pragma solidity ^0.8.14;

interface IStakedDarwin {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns(string calldata);
    function symbol() external pure returns(string calldata);
    function decimals() external pure returns(uint8);

    function darwinStaking() external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address user) external view returns (uint);

    function mint(address to, uint value) external;
    function burn(address from, uint value) external;

    function setDarwinStaking(address _darwinStaking) external;
}