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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IBribeVault} from "./interfaces/IBribeVault.sol";
import {Common} from "./libraries/Common.sol";
import {Errors} from "./libraries/Errors.sol";

contract BribeMarket is AccessControl, ReentrancyGuard {
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    uint256 public constant MAX_PERIODS = 10;
    uint256 public constant MAX_PERIOD_DURATION = 30 days;

    // Name (identifier) of the market, also used for rewardIdentifiers
    // Immutable after initialization
    string public PROTOCOL;

    // Address of the bribeVault
    // Immutable after initialization
    address public BRIBE_VAULT;

    // Maximum number of periods
    uint256 public maxPeriods;

    // Period duration
    uint256 public periodDuration;

    // Whitelisted bribe tokens
    address[] private _allWhitelistedTokens;

    // Blacklisted voters
    address[] private _allBlacklistedVoters;

    // Arbitrary bytes mapped to deadlines
    mapping(bytes32 => uint256) public proposalDeadlines;

    // Tracks whitelisted tokens
    mapping(address => uint256) public indexOfWhitelistedToken;

    // Tracks blacklisted voters
    mapping(address => uint256) public indexOfBlacklistedVoter;

    bool private _initialized;

    event Initialize(
        address bribeVault,
        address admin,
        string protocol,
        uint256 maxPeriods,
        uint256 periodDuration
    );
    event GrantTeamRole(address teamMember);
    event RevokeTeamRole(address teamMember);
    event SetProposals(bytes32[] proposals, uint256 indexed deadline);
    event SetProposalsById(
        uint256 indexed proposalIndex,
        bytes32[] proposals,
        uint256 indexed deadline
    );
    event SetProposalsByAddress(bytes32[] proposals, uint256 indexed deadline);
    event AddWhitelistedTokens(address[] tokens);
    event RemoveWhitelistedTokens(address[] tokens);
    event SetMaxPeriods(uint256 maxPeriods);
    event SetPeriodDuration(uint256 periodDuration);
    event AddBlacklistedVoters(address[] voters);
    event RemoveBlacklistedVoters(address[] voters);

    modifier onlyAuthorized() {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(TEAM_ROLE, msg.sender)
        ) revert Errors.NotAuthorized();
        _;
    }

    modifier onlyInitializer() {
        if (_initialized) revert Errors.AlreadyInitialized();
        _;
        _initialized = true;
    }

    /**
        @notice Initialize the contract
        @param  _bribeVault  Bribe vault address
        @param  _admin       Admin address
        @param  _protocol    Protocol name
        @param  _maxPeriods  Maximum number of periods
        @param  _periodDuration  Period duration
     */
    function initialize(
        address _bribeVault,
        address _admin,
        string calldata _protocol,
        uint256 _maxPeriods,
        uint256 _periodDuration
    ) external onlyInitializer {
        if (_bribeVault == address(0)) revert Errors.InvalidAddress();
        if (bytes(_protocol).length == 0) revert Errors.InvalidProtocol();
        if (_maxPeriods == 0 || _maxPeriods > MAX_PERIODS)
            revert Errors.InvalidMaxPeriod();
        if (_periodDuration == 0 || _periodDuration > MAX_PERIOD_DURATION)
            revert Errors.InvalidPeriodDuration();

        BRIBE_VAULT = _bribeVault;
        PROTOCOL = _protocol;
        maxPeriods = _maxPeriods;
        periodDuration = _periodDuration;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        emit Initialize(
            _bribeVault,
            _admin,
            _protocol,
            _maxPeriods,
            _periodDuration
        );
    }

    /**
        @notice Set multiple proposals with arbitrary bytes data as identifiers under the same deadline
        @param  _identifiers  bytes[]  identifiers
        @param  _deadline     uint256  Proposal deadline
     */
    function setProposals(
        bytes[] calldata _identifiers,
        uint256 _deadline
    ) external onlyAuthorized {
        uint256 identifiersLen = _identifiers.length;
        if (identifiersLen == 0) revert Errors.InvalidAddress();
        if (_deadline < block.timestamp) revert Errors.InvalidDeadline();

        bytes32[] memory proposalIds = new bytes32[](identifiersLen);

        uint256 i;
        do {
            if (_identifiers[i].length == 0) revert Errors.InvalidIdentifier();

            proposalIds[i] = keccak256(abi.encodePacked(_identifiers[i]));

            _setProposal(proposalIds[i], _deadline);

            ++i;
        } while (i < identifiersLen);

        emit SetProposals(proposalIds, _deadline);
    }

    /**
        @notice Set proposals based on the index of the proposal and the number of choices
        @param  _proposalIndex  uint256  Proposal index
        @param  _choiceCount    uint256  Number of choices to be voted for
        @param  _deadline       uint256  Proposal deadline
     */
    function setProposalsById(
        uint256 _proposalIndex,
        uint256 _choiceCount,
        uint256 _deadline
    ) external onlyAuthorized {
        if (_choiceCount == 0) revert Errors.InvalidChoiceCount();
        if (_deadline < block.timestamp) revert Errors.InvalidDeadline();

        bytes32[] memory proposalIds = new bytes32[](_choiceCount);

        uint256 i;
        do {
            proposalIds[i] = keccak256(abi.encodePacked(_proposalIndex, i));

            _setProposal(proposalIds[i], _deadline);

            ++i;
        } while (i < _choiceCount);

        emit SetProposalsById(_proposalIndex, proposalIds, _deadline);
    }

    /**
        @notice Set multiple proposals for many addresses under the same deadline
        @param  _addresses  address[]  addresses (eg. gauge addresses)
        @param  _deadline   uint256    Proposal deadline
     */
    function setProposalsByAddress(
        address[] calldata _addresses,
        uint256 _deadline
    ) external onlyAuthorized {
        uint256 addressesLen = _addresses.length;
        if (addressesLen == 0) revert Errors.InvalidAddress();
        if (_deadline < block.timestamp) revert Errors.InvalidDeadline();

        bytes32[] memory proposalIds = new bytes32[](addressesLen);

        uint256 i;
        do {
            if (_addresses[i] == address(0)) revert Errors.InvalidAddress();

            proposalIds[i] = keccak256(abi.encodePacked(_addresses[i]));

            _setProposal(proposalIds[i], _deadline);

            ++i;
        } while (i < addressesLen);

        emit SetProposalsByAddress(proposalIds, _deadline);
    }

    /**
        @notice Grant the team role to an address
        @param  _teamMember  address  Address to grant the teamMember role
     */
    function grantTeamRole(
        address _teamMember
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_teamMember == address(0)) revert Errors.InvalidAddress();
        _grantRole(TEAM_ROLE, _teamMember);

        emit GrantTeamRole(_teamMember);
    }

    /**
        @notice Revoke the team role from an address
        @param  _teamMember  address  Address to revoke the teamMember role
     */
    function revokeTeamRole(
        address _teamMember
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!hasRole(TEAM_ROLE, _teamMember)) revert Errors.NotTeamMember();
        _revokeRole(TEAM_ROLE, _teamMember);

        emit RevokeTeamRole(_teamMember);
    }

    /**
        @notice Set maximum periods for submitting bribes ahead of time
        @param  _periods  uint256  Maximum periods
     */
    function setMaxPeriods(
        uint256 _periods
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_periods == 0 || _periods > MAX_PERIODS)
            revert Errors.InvalidMaxPeriod();

        maxPeriods = _periods;

        emit SetMaxPeriods(_periods);
    }

    /**
        @notice Set period duration per voting round
        @param  _periodDuration  uint256  Period duration
     */
    function setPeriodDuration(
        uint256 _periodDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_periodDuration == 0 || _periodDuration > MAX_PERIOD_DURATION)
            revert Errors.InvalidPeriodDuration();

        periodDuration = _periodDuration;

        emit SetPeriodDuration(_periodDuration);
    }

    /**
        @notice Add whitelisted tokens
        @param  _tokens  address[]  Tokens to add to whitelist
     */
    function addWhitelistedTokens(
        address[] calldata _tokens
    ) external onlyAuthorized {
        uint256 tLen = _tokens.length;
        for (uint256 i; i < tLen; ) {
            if (_tokens[i] == address(0)) revert Errors.InvalidAddress();
            if (_tokens[i] == BRIBE_VAULT)
                revert Errors.NoWhitelistBribeVault();
            if (isWhitelistedToken(_tokens[i]))
                revert Errors.TokenWhitelisted();

            // Perform creation op for the unordered key set
            _allWhitelistedTokens.push(_tokens[i]);
            indexOfWhitelistedToken[_tokens[i]] =
                _allWhitelistedTokens.length -
                1;

            unchecked {
                ++i;
            }
        }

        emit AddWhitelistedTokens(_tokens);
    }

    /**
        @notice Remove whitelisted tokens
        @param  _tokens  address[]  Tokens to remove from whitelist
     */
    function removeWhitelistedTokens(
        address[] calldata _tokens
    ) external onlyAuthorized {
        uint256 tLen = _tokens.length;
        for (uint256 i; i < tLen; ) {
            if (!isWhitelistedToken(_tokens[i]))
                revert Errors.TokenNotWhitelisted();

            // Perform deletion op for the unordered key set
            // by swapping the affected row to the end/tail of the list
            uint256 index = indexOfWhitelistedToken[_tokens[i]];
            address tail = _allWhitelistedTokens[
                _allWhitelistedTokens.length - 1
            ];

            _allWhitelistedTokens[index] = tail;
            indexOfWhitelistedToken[tail] = index;

            delete indexOfWhitelistedToken[_tokens[i]];
            _allWhitelistedTokens.pop();

            unchecked {
                ++i;
            }
        }

        emit RemoveWhitelistedTokens(_tokens);
    }

    /**
        @notice Add blacklisted voters
        @param  _voters  address[]  Voters to add to blacklist
     */
    function addBlacklistedVoters(
        address[] calldata _voters
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 vLen = _voters.length;
        for (uint256 i; i < vLen; ) {
            if (_voters[i] == address(0)) revert Errors.InvalidAddress();
            if (isBlacklistedVoter(_voters[i]))
                revert Errors.VoterBlacklisted();

            _allBlacklistedVoters.push(_voters[i]);
            indexOfBlacklistedVoter[_voters[i]] =
                _allBlacklistedVoters.length -
                1;

            unchecked {
                ++i;
            }
        }

        emit AddBlacklistedVoters(_voters);
    }

    /**
        @notice Remove blacklisted voters
        @param  _voters  address[]  Voters to remove from blacklist
     */
    function removeBlacklistedVoters(
        address[] calldata _voters
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 vLen = _voters.length;
        for (uint256 i; i < vLen; ) {
            if (!isBlacklistedVoter(_voters[i]))
                revert Errors.VoterNotBlacklisted();

            // Perform deletion op for the unordered key set
            // by swapping the affected row to the end/tail of the list
            uint256 index = indexOfBlacklistedVoter[_voters[i]];
            address tail = _allBlacklistedVoters[
                _allBlacklistedVoters.length - 1
            ];

            _allBlacklistedVoters[index] = tail;
            indexOfBlacklistedVoter[tail] = index;

            delete indexOfBlacklistedVoter[_voters[i]];
            _allBlacklistedVoters.pop();

            unchecked {
                ++i;
            }
        }

        emit RemoveBlacklistedVoters(_voters);
    }

    /**
        @notice Deposit bribe for a proposal (ERC20 tokens only)
        @param  _proposal          bytes32  Proposal
        @param  _token             address  Token
        @param  _amount            uint256  Token amount
        @param  _maxTokensPerVote  uint256  Max amount of token per vote
        @param  _periods           uint256  Number of periods the bribe will be valid
     */
    function depositBribe(
        bytes32 _proposal,
        address _token,
        uint256 _amount,
        uint256 _maxTokensPerVote,
        uint256 _periods
    ) external nonReentrant {
        _depositBribe(
            _proposal,
            _token,
            _amount,
            _maxTokensPerVote,
            _periods,
            0,
            ""
        );
    }

    /**
        @notice Deposit bribe for a proposal (ERC20 tokens only) using permit
        @param  _proposal          bytes32  Proposal
        @param  _token             address  Token
        @param  _amount            uint256  Token amount
        @param  _maxTokensPerVote  uint256  Max amount of token per vote
        @param  _periods           uint256  Number of periods the bribe will be valid
        @param  _permitDeadline    uint256  Deadline for permit signature
        @param  _signature         bytes    Permit signature
     */
    function depositBribeWithPermit(
        bytes32 _proposal,
        address _token,
        uint256 _amount,
        uint256 _maxTokensPerVote,
        uint256 _periods,
        uint256 _permitDeadline,
        bytes memory _signature
    ) external nonReentrant {
        _depositBribe(
            _proposal,
            _token,
            _amount,
            _maxTokensPerVote,
            _periods,
            _permitDeadline,
            _signature
        );
    }

    /**
        @notice Return the list of currently whitelisted token addresses
     */
    function getWhitelistedTokens() external view returns (address[] memory) {
        return _allWhitelistedTokens;
    }

    /**
        @notice Return the list of currently blacklisted voter addresses
     */
    function getBlacklistedVoters() external view returns (address[] memory) {
        return _allBlacklistedVoters;
    }

    /**
        @notice Get bribe from BribeVault
        @param  _proposal          bytes32  Proposal
        @param  _proposalDeadline  uint256  Proposal deadline
        @param  _token             address  Token
        @return bribeToken         address  Token address
        @return bribeAmount        address  Token amount
     */
    function getBribe(
        bytes32 _proposal,
        uint256 _proposalDeadline,
        address _token
    ) external view returns (address bribeToken, uint256 bribeAmount) {
        (bribeToken, bribeAmount) = IBribeVault(BRIBE_VAULT).getBribe(
            keccak256(
                abi.encodePacked(
                    address(this),
                    _proposal,
                    _proposalDeadline,
                    _token
                )
            )
        );
    }

    /**
        @notice Return whether the specified token is whitelisted
        @param  _token  address Token address to be checked
     */
    function isWhitelistedToken(address _token) public view returns (bool) {
        if (_allWhitelistedTokens.length == 0) {
            return false;
        }

        return
            indexOfWhitelistedToken[_token] != 0 ||
            _allWhitelistedTokens[0] == _token;
    }

    /**
        @notice Return whether the specified address is blacklisted
        @param  _voter  address Voter address to be checked
     */
    function isBlacklistedVoter(address _voter) public view returns (bool) {
        if (_allBlacklistedVoters.length == 0) {
            return false;
        }

        return
            indexOfBlacklistedVoter[_voter] != 0 ||
            _allBlacklistedVoters[0] == _voter;
    }

    /**
        @notice Deposit bribe for a proposal (ERC20 tokens only) with optional permit parameters
        @param  _proposal          bytes32  Proposal
        @param  _token             address  Token
        @param  _amount            uint256  Token amount
        @param  _maxTokensPerVote  uint256  Max amount of token per vote
        @param  _periods           uint256  Number of periods the bribe will be valid
        @param  _permitDeadline    uint256  Deadline for permit signature
        @param  _signature         bytes    Permit signature
     */
    function _depositBribe(
        bytes32 _proposal,
        address _token,
        uint256 _amount,
        uint256 _maxTokensPerVote,
        uint256 _periods,
        uint256 _permitDeadline,
        bytes memory _signature
    ) internal {
        uint256 proposalDeadline = proposalDeadlines[_proposal];
        if (proposalDeadline < block.timestamp) revert Errors.DeadlinePassed();
        if (_periods == 0 || _periods > maxPeriods)
            revert Errors.InvalidPeriod();
        if (_token == address(0)) revert Errors.InvalidAddress();
        if (!isWhitelistedToken(_token)) revert Errors.TokenNotWhitelisted();
        if (_amount == 0) revert Errors.InvalidAmount();

        IBribeVault(BRIBE_VAULT).depositBribe(
            Common.DepositBribeParams({
                proposal: _proposal,
                token: _token,
                briber: msg.sender,
                amount: _amount,
                maxTokensPerVote: _maxTokensPerVote,
                periods: _periods,
                periodDuration: periodDuration,
                proposalDeadline: proposalDeadline,
                permitDeadline: _permitDeadline,
                signature: _signature
            })
        );
    }

    /**
        @notice Set a single proposal
        @param  _proposal  bytes32  Proposal
        @param  _deadline  uint256  Proposal deadline
     */
    function _setProposal(bytes32 _proposal, uint256 _deadline) internal {
        proposalDeadlines[_proposal] = _deadline;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../libraries/Common.sol";

interface IBribeVault {
    /**
        @notice Deposit bribe (ERC20 only)
        @param  _depositParams  DepositBribeParams  Deposit data
     */
    function depositBribe(
        Common.DepositBribeParams calldata _depositParams
    ) external;

    /**
        @notice Get bribe information based on the specified identifier
        @param  _bribeIdentifier  bytes32  The specified bribe identifier
     */
    function getBribe(
        bytes32 _bribeIdentifier
    ) external view returns (address token, uint256 amount);

    /**
        @notice Transfer fees to fee recipient and bribes to distributor and update rewards metadata
        @param  _rewardIdentifiers  bytes32[]  List of rewardIdentifiers
     */
    function transferBribes(bytes32[] calldata _rewardIdentifiers) external;

    /**
        @notice Grant the depositor role to an address
        @param  _depositor  address  Address to grant the depositor role
     */
    function grantDepositorRole(address _depositor) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Common {
    /**
     * @param identifier  bytes32  Identifier of the distribution
     * @param token       address  Address of the token to distribute
     * @param merkleRoot  bytes32  Merkle root of the distribution
     * @param proof       bytes32  Proof of the distribution
     */
    struct Distribution {
        bytes32 identifier;
        address token;
        bytes32 merkleRoot;
        bytes32 proof;
    }

    /**
     * @param proposal          bytes32  Proposal to bribe
     * @param token             address  Token to bribe with
     * @param briber            address  Address of the briber
     * @param amount            uint256  Amount of tokens to bribe with
     * @param maxTokensPerVote  uint256  Maximum amount of tokens to use per vote
     * @param periods           uint256  Number of periods to bribe for
     * @param periodDuration    uint256  Duration of each period
     * @param proposalDeadline  uint256  Deadline for the proposal
     * @param permitDeadline    uint256  Deadline for the permit2 signature
     * @param signature         bytes    Permit2 signature
     */
    struct DepositBribeParams {
        bytes32 proposal;
        address token;
        address briber;
        uint256 amount;
        uint256 maxTokensPerVote;
        uint256 periods;
        uint256 periodDuration;
        uint256 proposalDeadline;
        uint256 permitDeadline;
        bytes signature;
    }

    /**
     * @param rwIdentifier      bytes32    Identifier for claiming reward
     * @param fromToken         address    Address of token to swap from
     * @param toToken           address    Address of token to swap to
     * @param fromAmount        uint256    Amount of fromToken to swap
     * @param toAmount          uint256    Amount of toToken to receive
     * @param deadline          uint256    Timestamp until which swap may be fulfilled
     * @param callees           address[]  Array of addresses to call (DEX addresses)
     * @param callLengths       uint256[]  Index of the beginning of each call in exchangeData
     * @param values            uint256[]  Array of encoded values for each call in exchangeData
     * @param exchangeData      bytes      Calldata to execute on callees
     * @param rwMerkleProof     bytes32[]  Merkle proof for the reward claim
     */
    struct ClaimAndSwapData {
        bytes32 rwIdentifier;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 deadline;
        address[] callees;
        uint256[] callLengths;
        uint256[] values;
        bytes exchangeData;
        bytes32[] rwMerkleProof;
    }

    /**
     * @param identifier   bytes32    Identifier for claiming reward
     * @param account      address    Address of the account to claim for
     * @param amount       uint256    Amount of tokens to claim
     * @param merkleProof  bytes32[]  Merkle proof for the reward claim
     */
    struct Claim {
        bytes32 identifier;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Errors {
    /**
     * @notice max period 0 or greater than MAX_PERIODS
     */
    error InvalidMaxPeriod();

    /**
     * @notice period duration 0 or greater than MAX_PERIOD_DURATION
     */
    error InvalidPeriodDuration();

    /**
     * @notice address provided is not a contract
     */
    error NotAContract();

    /**
     * @notice not authorized
     */
    error NotAuthorized();

    /**
     * @notice contract already initialized
     */
    error AlreadyInitialized();

    /**
     * @notice address(0)
     */
    error InvalidAddress();

    /**
     * @notice empty bytes identifier
     */
    error InvalidIdentifier();

    /**
     * @notice invalid protocol name
     */
    error InvalidProtocol();

    /**
     * @notice invalid number of choices
     */
    error InvalidChoiceCount();

    /**
     * @notice invalid input amount
     */
    error InvalidAmount();

    /**
     * @notice not team member
     */
    error NotTeamMember();

    /**
     * @notice cannot whitelist BRIBE_VAULT
     */
    error NoWhitelistBribeVault();

    /**
     * @notice token already whitelisted
     */
    error TokenWhitelisted();

    /**
     * @notice token not whitelisted
     */
    error TokenNotWhitelisted();

    /**
     * @notice voter already blacklisted
     */
    error VoterBlacklisted();

    /**
     * @notice voter not blacklisted
     */
    error VoterNotBlacklisted();

    /**
     * @notice deadline has passed
     */
    error DeadlinePassed();

    /**
     * @notice invalid period
     */
    error InvalidPeriod();

    /**
     * @notice invalid deadline
     */
    error InvalidDeadline();

    /**
     * @notice invalid max fee
     */
    error InvalidMaxFee();

    /**
     * @notice invalid fee
     */
    error InvalidFee();

    /**
     * @notice invalid fee recipient
     */
    error InvalidFeeRecipient();

    /**
     * @notice invalid distributor
     */
    error InvalidDistributor();

    /**
     * @notice invalid briber
     */
    error InvalidBriber();

    /**
     * @notice address does not have DEPOSITOR_ROLE
     */
    error NotDepositor();

    /**
     * @notice no array given
     */
    error InvalidArray();

    /**
     * @notice invalid reward identifier
     */
    error InvalidRewardIdentifier();

    /**
     * @notice bribe has already been transferred
     */
    error BribeAlreadyTransferred();

    /**
     * @notice distribution does not exist
     */
    error InvalidDistribution();

    /**
     * @notice invalid merkle root
     */
    error InvalidMerkleRoot();

    /**
     * @notice token is address(0)
     */
    error InvalidToken();

    /**
     * @notice claim does not exist
     */
    error InvalidClaim();

    /**
     * @notice reward is not yet active for claiming
     */
    error RewardInactive();

    /**
     * @notice timer duration is invalid
     */
    error InvalidTimerDuration();

    /**
     * @notice merkle proof is invalid
     */
    error InvalidProof();

    /**
     * @notice ETH transfer failed
     */
    error ETHTransferFailed();

    /**
     * @notice Invalid operator address
     */
    error InvalidOperator();

    /**
     * @notice call to TokenTransferProxy contract
     */
    error TokenTransferProxyCall();

    /**
     * @notice calling TransferFrom
     */
    error TransferFromCall();

    /**
     * @notice external call failed
     */
    error ExternalCallFailure();

    /**
     * @notice returned tokens too few
     */
    error InsufficientReturn();

    /**
     * @notice swapDeadline expired
     */
    error DeadlineBreach();

    /**
     * @notice expected tokens returned are 0
     */
    error ZeroExpectedReturns();

    /**
     * @notice arrays in SwapData.exchangeData have wrong lengths
     */
    error ExchangeDataArrayMismatch();
}