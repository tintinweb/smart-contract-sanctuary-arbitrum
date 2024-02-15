// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title AccessController for the Index
 * @author Velvet.Capital
 * @notice This contract is used to specify and grant different roles
 * @dev Functionalities included:
 *      1. Checks if an address has role
 *      2. Grant different roles to addresses
 */

pragma solidity 0.8.16;

import {AccessControl} from "@openzeppelin/contracts-4.8.2/access/AccessControl.sol";

import {ITokenRegistry} from "../registry/ITokenRegistry.sol";
import {ErrorLibrary} from "../library/ErrorLibrary.sol";

import {FunctionParameters} from "../FunctionParameters.sol";

contract AccessController is AccessControl {
  bytes32 public constant INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");
  bytes32 public constant SUPER_ADMIN = keccak256("SUPER_ADMIN");
  bytes32 public constant WHITELIST_MANAGER_ADMIN = keccak256("WHITELIST_MANAGER_ADMIN");
  bytes32 public constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
  bytes32 public constant WHITELIST_MANAGER = keccak256("WHITELIST_MANAGER");
  bytes32 public constant ASSET_MANAGER_ADMIN = keccak256("ASSET_MANAGER_ADMIN");
  bytes32 public constant REBALANCER_CONTRACT = keccak256("REBALANCER_CONTRACT");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  modifier onlyAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
      revert ErrorLibrary.CallerNotAdmin();
    }
    _;
  }

  /**
   * @notice This function is used to grant a specific role to an address
   * @param role The specific role that has to be assigned
   * @param account The account that is to get the role
   */
  function setupRole(bytes32 role, address account) public onlyAdmin {
    _setupRole(role, account);
  }

  /**
   * @notice This function is invoked while creation of a new fund and is used to specify its different components and their roles
   * @param setupData Contains the input params for the function
   */
  function setUpRoles(FunctionParameters.AccessSetup memory setupData) public onlyAdmin {
    _setupRole(INDEX_MANAGER_ROLE, setupData._index);

    _setupRole(INDEX_MANAGER_ROLE, setupData._offChainIndexSwap);

    _setupRole(SUPER_ADMIN, setupData._portfolioCreator);

    _setRoleAdmin(WHITELIST_MANAGER_ADMIN, SUPER_ADMIN);

    _setRoleAdmin(ASSET_MANAGER_ADMIN, SUPER_ADMIN);

    _setRoleAdmin(ASSET_MANAGER_ROLE, ASSET_MANAGER_ADMIN);

    _setRoleAdmin(WHITELIST_MANAGER, WHITELIST_MANAGER_ADMIN);

    _setupRole(WHITELIST_MANAGER_ADMIN, setupData._portfolioCreator);
    _setupRole(WHITELIST_MANAGER, setupData._portfolioCreator);

    _setupRole(ASSET_MANAGER_ADMIN, setupData._portfolioCreator);
    _setupRole(ASSET_MANAGER_ROLE, setupData._portfolioCreator);

    _setupRole(INDEX_MANAGER_ROLE, setupData._rebalancing);
    _setupRole(REBALANCER_CONTRACT, setupData._rebalancing);

    _setupRole(INDEX_MANAGER_ROLE, setupData._offChainRebalancing);
    _setupRole(REBALANCER_CONTRACT, setupData._offChainRebalancing);

    _setupRole(INDEX_MANAGER_ROLE, setupData._rebalanceAggregator);
    _setupRole(REBALANCER_CONTRACT, setupData._rebalanceAggregator);

    _setupRole(MINTER_ROLE, setupData._feeModule);
    _setupRole(MINTER_ROLE, setupData._offChainIndexSwap);
  }
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexManager for a particular Index
 * @author Velvet.Capital
 * @notice This contract is used for transferring funds form vault to contract and vice versa 
           and swap tokens to and fro from BNB
 * @dev This contract includes functionalities:
 *      1. Deposit tokens to vault
 *      2. Withdraw tokens from vault
 *      3. Swap BNB for tokens
 *      4. Swap tokens for BNB
 */

pragma solidity 0.8.16;

import {IIndexSwap} from "../core/IIndexSwap.sol";

import {FunctionParameters} from "../FunctionParameters.sol";
import {IHandler} from "../handler/IHandler.sol";
import {ExchangeData} from "../handler/ExternalSwapHandler/Helper/ExchangeData.sol";

interface IExchange {
  function init(address _accessController, address _safe, address _oracle, address _tokenRegistry) external;

  /**
   * @return Checks if token is WETH
   */
  function isWETH(address _token, address _protocol) external view returns (bool);

  function _pullFromVault(address t, uint256 amount, address to) external;

  function _pullFromVaultRewards(address token, uint256 amount, address to) external;

  /**
   * @notice The function swaps ETH to a specific token
   * @param inputData includes the input parmas
   */
  function swapETHToToken(FunctionParameters.SwapETHToTokenPublicData calldata inputData) external payable;

  /**
   * @notice The function swaps a specific token to ETH
   * @dev Requires the tokens to be send to this contract address before swapping
   * @param inputData includes the input parmas
   * @return swapResult The outcome amount in ETH afer swapping
   */
  function _swapTokenToETH(
    FunctionParameters.SwapTokenToETHData calldata inputData
  ) external returns (uint256[] calldata);

  /**
   * @notice The function swaps a specific token to ETH
   * @dev Requires the tokens to be send to this contract address before swapping
   * @param inputData includes the input parmas
   * @return swapResult The outcome amount in ETH afer swapping
   */
  function _swapTokenToToken(FunctionParameters.SwapTokenToTokenData memory inputData) external returns (uint256);

  function _swapTokenToTokens(
    FunctionParameters.SwapTokenToTokensData memory inputData,uint256 balanceBefore
  ) external payable returns (uint256 investedAmountAfterSlippage);

  function _swapTokenToTokensOffChain(
    ExchangeData.InputData memory inputData,
    IIndexSwap index,
    uint256[] calldata _lpSlippage,
    address[] memory _tokens,
    uint256[] calldata _buyAmount,
    uint256 balanceBefore,
    address _toUser
  ) external returns (uint256 investedAmountAfterSlippage);

  function swapOffChainTokens(
    ExchangeData.IndexOperationData memory inputdata
  ) external returns (uint256 balanceInUSD, uint256 underlyingIndex);

  function claimTokens(IIndexSwap _index, address[] calldata _tokens) external;

  function oracle() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexSwap for the Index
 * @author Velvet.Capital
 * @notice This contract is used by the user to invest and withdraw from the index
 * @dev This contract includes functionalities:
 *      1. Invest in the particular fund
 *      2. Withdraw from the fund
 */

pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IIndexSwap {
  function vault() external view returns (address);

  function feeModule() external view returns (address);

  function exchange() external view returns (address);

  function tokenRegistry() external view returns (address);

  function accessController() external view returns (address);

  function paused() external view returns (bool);

  function TOTAL_WEIGHT() external view returns (uint256);

  function iAssetManagerConfig() external view returns (address);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  /**
   * @dev Token record data structure
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param index index of address in tokens array
   */
  struct Record {
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint8 index;
  }

  /** @dev Emitted when public trades are enabled. */
  event LOG_PUBLIC_SWAP_ENABLED();

  function init(FunctionParameters.IndexSwapInitData calldata initData) external;

  /**
   * @dev Sets up the initial assets for the pool.
   * @param tokens Underlying tokens to initialize the pool with
   * @param denorms Initial denormalized weights for the tokens
   */
  function initToken(address[] calldata tokens, uint96[] calldata denorms) external;

  // For Minting Shares
  function mintShares(address _to, uint256 _amount) external;

  //For Burning Shares
  function burnShares(address _to, uint256 _amount) external;

  /**
     * @notice The function swaps BNB into the portfolio tokens after a user makes an investment
     * @dev The output of the swap is converted into USD to get the actual amount after slippage to calculate 
            the index token amount to mint
     * @dev (tokenBalance, vaultBalance) has to be calculated before swapping for the _mintShareAmount function 
            because during the swap the amount will change but the index token balance is still the same 
            (before minting)
     */
  function investInFund(uint256[] calldata _slippage, address _swapHandler) external payable;

  /**
     * @notice The function swaps the amount of portfolio tokens represented by the amount of index token back to 
               BNB and returns it to the user and burns the amount of index token being withdrawn
     * @param tokenAmount The index token amount the user wants to withdraw from the fund
     */
  function withdrawFund(uint256 tokenAmount, uint256[] calldata _slippage) external;

  /**
    @notice The function will pause the InvestInFund() and Withdrawal() called by the rebalancing contract.
    @param _state The state is bool value which needs to input by the Index Manager.
    */
  function setPaused(bool _state) external;

  function setRedeemed(bool _state) external;

  /**
    @notice The function will set lastRebalanced time called by the rebalancing contract.
    @param _time The time is block.timestamp, the moment when rebalance is done
  */
  function setLastRebalance(uint256 _time) external;

  /**
    @notice The function returns lastRebalanced time
  */
  function getLastRebalance() external view returns (uint256);

  /**
    @notice The function returns lastPaused time
  */
  function getLastPaused() external view returns (uint256);

  /**
   * @notice The function updates the record struct including the denorm information
   * @dev The token list is passed so the function can be called with current or updated token list
   * @param tokens The updated token list of the portfolio
   * @param denorms The new weights for for the portfolio
   */
  function updateRecords(address[] memory tokens, uint96[] memory denorms) external;

  /**
   * @notice This function update records with new tokenlist and weights
   * @param tokens Array of the tokens to be updated
   * @param _denorms Array of the updated denorm values
   */
  function updateTokenListAndRecords(address[] calldata tokens, uint96[] calldata _denorms) external;

  function getRedeemed() external view returns (bool);

  function getTokens() external view returns (address[] memory);

  function getRecord(address _token) external view returns (Record memory);

  function updateTokenList(address[] memory tokens) external;

  function deleteRecord(address t) external;

  function oracle() external view returns (address);

  function lastInvestmentTime(address owner) external view returns (uint256);

  function checkCoolDownPeriod(address _user) external view;

  function mintTokenAndSetCooldown(address _to, uint256 _mintAmount) external returns (uint256);

  function burnWithdraw(address _to, uint256 _mintAmount) external returns (uint256 exitFee);

  function setFlags(bool _pauseState, bool _redeemState) external;

  function reentrancyGuardEntered() external returns (bool);

  function nonReentrantBefore() external;

  function nonReentrantAfter() external;
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexSwapLibrary for a particular Index
 * @author Velvet.Capital
 * @notice This contract is used for all the calculations and also get token balance in vault
 * @dev This contract includes functionalities:
 *      1. Get tokens balance in the vault
 *      2. Calculate the swap amount needed while performing different operation
 */

pragma solidity 0.8.16;

import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/interfaces/IERC20Upgradeable.sol";

import {IPriceOracle} from "../oracle/IPriceOracle.sol";
import {IIndexSwap} from "./IIndexSwap.sol";
import {IAssetManagerConfig} from "../registry/IAssetManagerConfig.sol";
import {ITokenRegistry} from "../registry/ITokenRegistry.sol";

import {ISwapHandler} from "../handler/ISwapHandler.sol";
import {IExternalSwapHandler} from "../handler/IExternalSwapHandler.sol";
import {IFeeModule} from "../fee/IFeeModule.sol";

import {IExchange} from "./IExchange.sol";
import {IHandler, FunctionParameters} from "../handler/IHandler.sol";

import {ErrorLibrary} from "../library/ErrorLibrary.sol";

import {IWETH} from "../interfaces/IWETH.sol";

library IndexSwapLibrary {
  /**
     * @notice The function calculates the balance of each token in the vault and converts them to USD and 
               the sum of those values which represents the total vault value in USD
     * @return tokenXBalance A list of the value of each token in the portfolio in USD
     * @return vaultValue The total vault value in USD
     */
  function getTokenAndVaultBalance(
    IIndexSwap _index,
    address[] memory _tokens
  ) internal returns (uint256[] memory, uint256) {
    uint256[] memory tokenBalanceInUSD = new uint256[](_tokens.length);
    uint256 vaultBalance;
    ITokenRegistry registry = ITokenRegistry(_index.tokenRegistry());
    address vault = _index.vault();
    if (_index.totalSupply() > 0) {
      for (uint256 i = 0; i < _tokens.length; i++) {
        address _token = _tokens[i];
        IHandler handler = IHandler(registry.getTokenInformation(_token).handler);
        tokenBalanceInUSD[i] = handler.getTokenBalanceUSD(vault, _token);
        vaultBalance = vaultBalance + tokenBalanceInUSD[i];
      }
      return (tokenBalanceInUSD, vaultBalance);
    } else {
      return (new uint256[](0), 0);
    }
  }

  /**
   * @notice The function calculates the amount in BNB to swap from BNB to each token
   * @dev The amount for each token has to be calculated to ensure the ratio (weight in the portfolio) stays constant
   * @param tokenAmount The amount a user invests into the portfolio
   * @param tokenBalanceInUSD The balanace of each token in the portfolio converted to USD
   * @param vaultBalance The total vault value of all tokens converted to USD
   * @return A list of amounts that are being swapped into the portfolio tokens
   */
  function calculateSwapAmounts(
    IIndexSwap _index,
    uint256 tokenAmount,
    uint256[] memory tokenBalanceInUSD,
    uint256 vaultBalance,
    address[] memory _tokens
  ) internal view returns (uint256[] memory) {
    uint256[] memory amount = new uint256[](_tokens.length);
    if (_index.totalSupply() > 0) {
      for (uint256 i = 0; i < _tokens.length; i++) {
        uint256 balance = tokenBalanceInUSD[i];
        if (balance * tokenAmount < vaultBalance) revert ErrorLibrary.IncorrectInvestmentTokenAmount();
        amount[i] = (balance * tokenAmount) / vaultBalance;
      }
    }
    return amount;
  }

  /**
   * @notice This function transfers the token to swap handler and makes the token to token swap happen
   */
  function transferAndSwapTokenToToken(
    address tokenIn,
    ISwapHandler swapHandler,
    uint256 swapValue,
    uint256 slippage,
    address tokenOut,
    address to,
    bool isEnabled
  ) external returns (uint256 swapResult) {
    TransferHelper.safeTransfer(address(tokenIn), address(swapHandler), swapValue);
    swapResult = swapHandler.swapTokenToTokens(swapValue, slippage, tokenIn, tokenOut, to, isEnabled);
  }

  /**
   * @notice This function transfers the token to swap handler and makes the token to ETH (native BNB) swap happen
   */
  function transferAndSwapTokenToETH(
    address tokenIn,
    ISwapHandler swapHandler,
    uint256 swapValue,
    uint256 slippage,
    address to,
    bool isEnabled
  ) external returns (uint256 swapResult) {
    TransferHelper.safeTransfer(address(tokenIn), address(swapHandler), swapValue);
    swapResult = swapHandler.swapTokensToETH(swapValue, slippage, tokenIn, to, isEnabled);
  }

  /**
   * @notice This function calls the _pullFromVault() function of the IndexSwapLibrary
   */
  function pullFromVault(IExchange _exchange, address _token, uint256 _amount, address _to) external {
    _exchange._pullFromVault(_token, _amount, _to);
  }

  /**
   * @notice This function returns the token balance of the particular contract address
   * @param _token Token whose balance has to be found
   * @param _contract Address of the contract whose token balance is to be retrieved
   * @param _WETH Weth (native) token address
   * @return currentBalance Returns the current token balance of the passed contract address
   */
  function checkBalance(
    address _token,
    address _contract,
    address _WETH
  ) external view returns (uint256 currentBalance) {
    if (_token != _WETH) {
      currentBalance = IERC20Upgradeable(_token).balanceOf(_contract);
      // TransferHelper.safeApprove(_token, address(this), currentBalance);
    } else {
      currentBalance = _contract.balance;
    }
  }

  /**
     * @notice The function calculates the amount of index tokens the user can buy/mint with the invested amount.
     * @param _amount The invested amount after swapping ETH into portfolio tokens converted to USD to avoid 
                      slippage errors
     * @param sumPrice The total value in the vault converted to USD
     * @return Returns the amount of index tokens to be minted.
     */
  function _mintShareAmount(
    uint256 _amount,
    uint256 sumPrice,
    uint256 _indexTokenSupply
  ) external pure returns (uint256) {
    return (_amount * _indexTokenSupply) / sumPrice;
  }

  /**
   * @notice This function helps in multi-asset withdrawal from a portfolio
   */
  function withdrawMultiAssetORWithdrawToken(
    address _tokenRegistry,
    address _exchange,
    address _token,
    uint256 _tokenBalance
  ) external {
    if (_token == ITokenRegistry(_tokenRegistry).getETH()) {
      IExchange(_exchange)._pullFromVault(_token, _tokenBalance, address(this));
      IWETH(ITokenRegistry(_tokenRegistry).getETH()).withdraw(_tokenBalance);
      (bool success, ) = payable(msg.sender).call{value: _tokenBalance}("");
      if (!success) revert ErrorLibrary.ETHTransferFailed();
    } else {
      IExchange(_exchange)._pullFromVault(_token, _tokenBalance, msg.sender);
    }
  }

  /**
   * @notice This function puts some checks before an investment operation
   */
  function beforeInvestment(
    IIndexSwap _index,
    uint256 _slippageLength,
    uint256 _lpSlippageLength,
    address _to
  ) external {
    IAssetManagerConfig _assetManagerConfig = IAssetManagerConfig(_index.iAssetManagerConfig());
    address[] memory _tokens = _index.getTokens();
    if (!(_assetManagerConfig.publicPortfolio() || _assetManagerConfig.whitelistedUsers(_to))) {
      revert ErrorLibrary.UserNotAllowedToInvest();
    }
    if (ITokenRegistry(_index.tokenRegistry()).getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (_slippageLength != _tokens.length || _lpSlippageLength != _tokens.length) {
      revert ErrorLibrary.InvalidSlippageLength();
    }
    if (_tokens.length == 0) {
      revert ErrorLibrary.NotInitialized();
    }
  }

  /**
   * @notice This function pulls from the vault, sends the tokens to the handler and then redeems it via the handler
   */
  function _pullAndRedeem(
    IExchange _exchange,
    address _token,
    address _to,
    uint256 _amount,
    uint256 _lpSlippage,
    bool isPrimary,
    IHandler _handler
  ) internal {
    if (!isPrimary) {
      _exchange._pullFromVault(_token, _amount, address(_handler));
      _handler.redeem(
        FunctionParameters.RedeemData(_amount, _lpSlippage, _to, _token, _exchange.isWETH(_token, address(_handler)))
      );
    } else {
      _exchange._pullFromVault(_token, _amount, _to);
    }
  }

  /**
   * @notice This function returns the rate of the Index token based on the Vault  and token balance
   */
  function getIndexTokenRate(IIndexSwap _index) external returns (uint256) {
    (, uint256 totalVaultBalance) = getTokenAndVaultBalance(_index, _index.getTokens());
    uint256 _totalSupply = _index.totalSupply();
    if (_totalSupply > 0 && totalVaultBalance > 0) {
      return (totalVaultBalance * (10 ** 18)) / _totalSupply;
    }
    return 10 ** 18;
  }

  /**
   * @notice This function calculates the swap amount for off-chain operations
   */
  function calculateSwapAmountsOffChain(IIndexSwap _index, uint256 tokenAmount) external returns (uint256[] memory) {
    uint256 vaultBalance;
    address[] memory _tokens = _index.getTokens();
    uint256 len = _tokens.length;
    uint256[] memory amount = new uint256[](len);
    uint256[] memory tokenBalanceInUSD = new uint256[](len);
    (tokenBalanceInUSD, vaultBalance) = getTokenAndVaultBalance(_index, _tokens);
    if (_index.totalSupply() == 0) {
      for (uint256 i = 0; i < len; i++) {
        uint256 _denorm = _index.getRecord(_tokens[i]).denorm;
        amount[i] = (tokenAmount * _denorm) / 10_000;
      }
    } else {
      for (uint256 i = 0; i < len; i++) {
        uint256 balance = tokenBalanceInUSD[i];
        if (balance * tokenAmount < vaultBalance) revert ErrorLibrary.IncorrectInvestmentTokenAmount();
        amount[i] = (balance * tokenAmount) / vaultBalance;
      }
    }
    return (amount);
  }

  /**
   * @notice This function applies checks from the asset manager config and token registry side before redeeming
   */
  function beforeRedeemCheck(IIndexSwap _index, uint256 _tokenAmount, address _token, bool _status) external {
    if (_status) {
      revert ErrorLibrary.TokenAlreadyRedeemed();
    }
    if (_tokenAmount > _index.balanceOf(msg.sender)) {
      revert ErrorLibrary.CallerNotHavingGivenTokenAmount();
    }
    address registry = _index.tokenRegistry();
    if (ITokenRegistry(registry).getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (
      !IAssetManagerConfig(_index.iAssetManagerConfig()).isTokenPermitted(_token) &&
      _token != ITokenRegistry(registry).getETH()
    ) {
      revert ErrorLibrary.InvalidToken();
    }
  }

  /**
   * @notice This function applies checks before withdrawal
   */
  function beforeWithdrawCheck(
    uint256 _slippage,
    uint256 _lpSlippage,
    address token,
    address owner,
    IIndexSwap index,
    uint256 tokenAmount
  ) external {
    ITokenRegistry registry = ITokenRegistry(index.tokenRegistry());
    address[] memory _tokens = index.getTokens();
    if (registry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }

    if (!IAssetManagerConfig(index.iAssetManagerConfig()).isTokenPermitted(token) && token != registry.getETH()) {
      revert ErrorLibrary.InvalidToken();
    }

    if (tokenAmount > index.balanceOf(owner)) {
      revert ErrorLibrary.CallerNotHavingGivenTokenAmount();
    }
    if (_slippage != _tokens.length || _lpSlippage != _tokens.length) {
      revert ErrorLibrary.InvalidSlippageLength();
    }
  }

  /**
   * @notice This function checks if the investment value is correct or not
   */
  function _checkInvestmentValue(uint256 _tokenAmount, IAssetManagerConfig _assetManagerConfig) external view {
    uint256 max = _assetManagerConfig.MAX_INVESTMENTAMOUNT();
    uint256 min = _assetManagerConfig.MIN_INVESTMENTAMOUNT();
    if (!(_tokenAmount <= max && _tokenAmount >= min)) {
      revert ErrorLibrary.WrongInvestmentAmount({minInvestment: max, maxInvestment: min});
    }
  }

  /**
   * @notice This function adds sanity check to the fee value as well as the _to address
   */
  function mintAndBurnCheck(
    uint256 _fee,
    address _to,
    address _tokenRegistry,
    address _assetManagerConfig
  ) external returns (bool) {
    return (_fee > 0 &&
      !(_to == IAssetManagerConfig(_assetManagerConfig).assetManagerTreasury() ||
        _to == ITokenRegistry(_tokenRegistry).velvetTreasury()));
  }

  /**
   * @notice This function checks if the token is permitted or not and if the token balance is optimum or not
   */
  function _checkPermissionAndBalance(
    address _token,
    uint256 _tokenAmount,
    IAssetManagerConfig _config,
    address _to
  ) external {
    if (!_config.isTokenPermitted(_token)) {
      revert ErrorLibrary.InvalidToken();
    }
    if (IERC20Upgradeable(_token).balanceOf(_to) < _tokenAmount) {
      revert ErrorLibrary.LowBalance();
    }
  }

  /**
   * @notice This function takes care of the checks required before init of the index
   */
  function _beforeInitCheck(IIndexSwap index, address token, uint96 denorm) external {
    IAssetManagerConfig config = IAssetManagerConfig(index.iAssetManagerConfig());
    if ((config.whitelistTokens() && !config.whitelistedToken(token))) {
      revert ErrorLibrary.TokenNotWhitelisted();
    }
    if (denorm <= 0) {
      revert ErrorLibrary.InvalidDenorms();
    }
    if (token == address(0)) {
      revert ErrorLibrary.InvalidTokenAddress();
    }
    if (!(ITokenRegistry(index.tokenRegistry()).isEnabled(token))) {
      revert ErrorLibrary.TokenNotApproved();
    }
  }

  /**
   * @notice The function converts the given token amount into USD
   * @param t The base token being converted to USD
   * @param amount The amount to convert to USD
   * @return amountInUSD The converted USD amount
   */
  function _getTokenAmountInUSD(
    address _oracle,
    address t,
    uint256 amount
  ) external view returns (uint256 amountInUSD) {
    amountInUSD = IPriceOracle(_oracle).getPriceTokenUSD18Decimals(t, amount);
  }

  /**
   * @notice The function calculates the balance of a specific token in the vault
   * @return tokenBalance of the specific token
   */
  function getTokenBalance(IIndexSwap _index, address t) external view returns (uint256 tokenBalance) {
    IHandler handler = IHandler(ITokenRegistry(_index.tokenRegistry()).getTokenInformation(t).handler);
    tokenBalance = handler.getTokenBalance(_index.vault(), t);
  }

  /**
   * @notice This function checks if the token is primary and also if the external swap handler is valid
   */
  function checkPrimaryAndHandler(ITokenRegistry registry, address[] calldata tokens, address handler) external view {
    if (!(registry.isExternalSwapHandler(handler))) {
      revert ErrorLibrary.OffHandlerNotValid();
    }
    for (uint i = 0; i < tokens.length; i++) {
      if (!registry.getTokenInformation(tokens[i]).primary) {
        revert ErrorLibrary.NotPrimaryToken();
      }
    }
  }

  /**
   * @notice This function makes the necessary checks before an off-chain withdrawal
   */
  function beforeWithdrawOffChain(bool status, ITokenRegistry tokenRegistry, address handler) external {
    if (tokenRegistry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }

    if (!status) {
      revert ErrorLibrary.TokensNotRedeemed();
    }
    if (!(tokenRegistry.isExternalSwapHandler(handler))) {
      revert ErrorLibrary.OffHandlerNotValid();
    }
  }

  /**
   * @notice This function charges the fees from the index via the Fee Module
   */
  function chargeFees(IIndexSwap index, IFeeModule feeModule) external returns (uint256 vaultBalance) {
    (, vaultBalance) = getTokenAndVaultBalance(index, index.getTokens());
    feeModule.chargeFeesFromIndex(vaultBalance);
  }

  /**
   * @notice This function gets the underlying balances of the input token
   */
  function getUnderlyingBalances(
    address _token,
    IHandler _handler,
    address _contract
  ) external view returns (uint256[] memory) {
    address[] memory underlying = _handler.getUnderlying(_token);
    uint256[] memory balances = new uint256[](underlying.length);
    for (uint256 i = 0; i < underlying.length; i++) {
      balances[i] = IERC20Upgradeable(underlying[i]).balanceOf(_contract);
    }
    return balances;
  }

  /// @notice Calculate lockup cooldown applied to the investor after pool deposit
  /// @param _currentUserBalance Investor's current pool tokens balance
  /// @param _mintedLiquidity Liquidity to be minted to investor after pool deposit
  /// @param _currentCooldownTime New cooldown lockup time
  /// @param _oldCooldownTime Last cooldown lockup time applied to investor
  /// @param _lastDepositTimestamp Timestamp when last pool deposit happened
  /// @return cooldown New lockup cooldown to be applied to investor address
  function calculateCooldownPeriod(
    uint256 _currentUserBalance,
    uint256 _mintedLiquidity,
    uint256 _currentCooldownTime,
    uint256 _oldCooldownTime,
    uint256 _lastDepositTimestamp
  ) external view returns (uint256 cooldown) {
    // Get timestamp when current cooldown ends
    uint256 prevCooldownEnd = _lastDepositTimestamp + _oldCooldownTime;
    // Current exit remaining cooldown
    uint256 prevCooldownRemaining = prevCooldownEnd < block.timestamp ? 0 : prevCooldownEnd - block.timestamp;
    // If it's first deposit with zero liquidity, no cooldown should be applied
    if (_currentUserBalance == 0 && _mintedLiquidity == 0) {
      cooldown = 0;
      // If it's first deposit, new cooldown should be applied
    } else if (_currentUserBalance == 0) {
      cooldown = _currentCooldownTime;
      // If zero liquidity or new cooldown reduces remaining cooldown, apply remaining
    } else if (_mintedLiquidity == 0 || _currentCooldownTime < prevCooldownRemaining) {
      cooldown = prevCooldownRemaining;
      // For the rest cases calculate cooldown based on current balance and liquidity minted
    } else {
      // If the user already owns liquidity, the additional lockup should be in proportion to their existing liquidity.
      // Aggregate additional and remaining cooldowns
      uint256 balanceBeforeMint = _currentUserBalance - _mintedLiquidity;
      uint256 averageCooldown = (_mintedLiquidity * _currentCooldownTime + balanceBeforeMint * prevCooldownRemaining) /
        _currentUserBalance;
      // Resulting value is capped at new cooldown time (shouldn't be bigger) and falls back to one second in case of zero
      cooldown = averageCooldown > _currentCooldownTime ? _currentCooldownTime : averageCooldown != 0
        ? averageCooldown
        : 1;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface IFeeModule {
  function chargeFeesFromIndex(uint256 _vaultBalance) external;

  function init(
    address _indexSwap,
    address _assetManagerConfig,
    address _tokenRegistry,
    address _accessController
  ) external;

  function chargeFees() external;

  function chargeEntryFee(uint256 _mintAmount, uint256 _fee) external returns (uint256);

  function chargeExitFee(uint256 _mintAmount, uint256 _fee) external returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library FunctionParameters {
  /**
   * @notice Struct having the init data for a new IndexFactory creation
   * @param _indexSwapLibrary Address of the base IndexSwapLibrary
   * @param _baseIndexSwapAddress Address of the base IndexSwap
   * @param _baseRebalancingAddres Address of the base Rebalancing module
   * @param _baseOffChainRebalancingAddress Address of the base Offchain-Rebalance module
   * @param _baseRebalanceAggregatorAddress Address of the base Rebalance Aggregator module
   * @param _baseExchangeHandlerAddress Address of the base Exchange Handler
   * @param _baseAssetManagerConfigAddress Address of the baes AssetManager Config address
   * @param _baseOffChainIndexSwapAddress Address of the base Offchain-IndexSwap module
   * @param _feeModuleImplementationAddress Address of the base Fee Module implementation
   * @param _baseVelvetGnosisSafeModuleAddress Address of the base Gnosis-Safe module
   * @param _gnosisSingleton Address of the Gnosis Singleton
   * @param _gnosisFallbackLibrary Address of the Gnosis Fallback Library
   * @param _gnosisMultisendLibrary Address of the Gnosis Multisend Library
   * @param _gnosisSafeProxyFactory Address of the Gnosis Safe Proxy Factory
   * @param _priceOracle Address of the base Price Oracle to be used
   * @param _tokenRegistry Address of the Token Registry to be used
   * @param _velvetProtocolFee Fee cut that is being charged (eg: 25% of the fees)
   */
  struct IndexFactoryInitData {
    address _indexSwapLibrary;
    address _baseIndexSwapAddress;
    address _baseRebalancingAddres;
    address _baseOffChainRebalancingAddress;
    address _baseRebalanceAggregatorAddress;
    address _baseExchangeHandlerAddress;
    address _baseAssetManagerConfigAddress;
    address _baseOffChainIndexSwapAddress;
    address _feeModuleImplementationAddress;
    address _baseVelvetGnosisSafeModuleAddress;
    address _gnosisSingleton;
    address _gnosisFallbackLibrary;
    address _gnosisMultisendLibrary;
    address _gnosisSafeProxyFactory;
    address _priceOracle;
    address _tokenRegistry;
  }

  /**
   * @notice Data passed from the Factory for the init of IndexSwap module
   * @param _name Name of the Index Fund
   * @param _symbol Symbol to represent the Index Fund
   * @param _vault Address of the Vault associated with that Index Fund
   * @param _module Address of the Safe module  associated with that Index Fund
   * @param _oracle Address of the Price Oracle associated with that Index Fund
   * @param _accessController Address of the Access Controller associated with that Index Fund
   * @param _tokenRegistry Address of the Token Registry associated with that Index Fund
   * @param _exchange Address of the Exchange Handler associated with that Index Fund
   * @param _iAssetManagerConfig Address of the Asset Manager Config associated with that Index Fund
   * @param _feeModule Address of the Fee Module associated with that Index Fund
   */
  struct IndexSwapInitData {
    string _name;
    string _symbol;
    address _vault;
    address _module;
    address _oracle;
    address _accessController;
    address _tokenRegistry;
    address _exchange;
    address _iAssetManagerConfig;
    address _feeModule;
  }

  /**
   * @notice Struct used to pass data when a Token is swapped to ETH (native token) using the swap handler
   * @param _token Address of the token being swapped
   * @param _to Receiver address that is receiving the swapped result
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _swapAmount Amount of tokens to be swapped
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   */
  struct SwapTokenToETHData {
    address _token;
    address _to;
    address _swapHandler;
    uint256 _swapAmount;
    uint256 _slippage;
    uint256 _lpSlippage;
  }

  /**
   * @notice Struct used to pass data when ETH (native token) is swapped to some other Token using the swap handler
   * @param _token Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   * @param _swapAmount Amount of tokens that is to be swapped
   */
  struct SwapETHToTokenData {
    address _token;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _slippage;
    uint256 _lpSlippage;
    uint256 _swapAmount;
  }

  /**
   * @notice Struct used to pass data when ETH (native token) is swapped to some other Token using the swap handler
   * @param _token Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   */
  struct SwapETHToTokenPublicData {
    address _token;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _slippage;
    uint256 _lpSlippage;
  }

  /**
   * @notice Struct used to pass data when a Token is swapped to another token using the swap handler
   * @param _tokenIn Address of the token being swapped from
   * @param _tokenOut Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _swapAmount Amount of tokens that is to be swapped
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   * @param _isInvesting Boolean parameter indicating if the swap is being done during investment or withdrawal
   */
  struct SwapTokenToTokenData {
    address _tokenIn;
    address _tokenOut;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _swapAmount;
    uint256 _slippage;
    uint256 _lpSlippage;
    bool _isInvesting;
  }

  /**
   * @notice Struct having data for the swap of one token to another based on the input
   * @param _index Address of the IndexSwap associated with the swap tokens
   * @param _inputToken Address of the token being swapped from
   * @param _swapHandler Address of the swap handler being used
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _tokenAmount Investment amount that is being distributed into all the portfolio tokens
   * @param _totalSupply Total supply of the Index tokens
   * @param amount The swap amount (in case totalSupply != 0) value calculated from the IndexSwapLibrary
   * @param _slippage Slippage for providing the liquidity
   * @param _lpSlippage LP Slippage for providing the liquidity
   */
  struct SwapTokenToTokensData {
    address _index;
    address _inputToken;
    address _swapHandler;
    address _toUser;
    uint256 _tokenAmount;
    uint256 _totalSupply;
    uint256[] amount;
    uint256[] _slippage;
    uint256[] _lpSlippage;
  }

  /**
   * @notice Struct having the Offchain Investment data used for multiple functions
   * @param _offChainHandler Address of the off-chain handler being used
   * @param _buyAmount Array of amounts representing the distribution to all portfolio tokens; sum of this amount is the total investment amount
   * @param _buySwapData Array including the calldata which is required for the external swap handlers to swap ("buy") the portfolio tokens
   */
  struct ZeroExData {
    address _offChainHandler;
    uint256[] _buyAmount;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having the init data for a new Index Fund creation using the Factory
   * @param _assetManagerTreasury Address of the Asset Manager Treasury to be associated with the fund
   * @param _whitelistedTokens Array of tokens which limits the use of only those addresses as portfolio tokens in the fund
   * @param maxIndexInvestmentAmount Maximum Investment amount for the fund
   * @param maxIndexInvestmentAmount Minimum Investment amount for the fund
   * @param _managementFee Management fee (streaming fee) that the asset manager will receive for managing the fund
   * @param _performanceFee Fee that the asset manager will receive for managing the fund and if the portfolio performance well
   * @param _entryFee Entry fee for investing into the fund
   * @param _exitFee Exit fee for withdrawal from the fund
   * @param _public Boolean parameter for is the fund eligible for public investment or only some whitelist users can invest
   * @param _transferable Boolean parameter for is the Index tokens from the fund transferable or not
   * @param _transferableToPublic Boolean parameter for is the Index tokens from the fund transferable to public or only to whitelisted users
   * @param _whitelistTokens Boolean parameter which specifies if the asset manager can only choose portfolio tokens from the whitelisted array or not
   * @param name Name of the fund
   * @param symbol Symbol associated with the fund
   */
  struct IndexCreationInitData {
    address _assetManagerTreasury;
    address[] _whitelistedTokens;
    uint256 maxIndexInvestmentAmount;
    uint256 minIndexInvestmentAmount;
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    bool _public;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
    string name;
    string symbol;
  }

  /**
   * @notice Struct having data for the Enable Rebalance (1st transaction) during ZeroEx's `Update Weight` call
   * @param _lpSlippage Array of LP Slippage values passed to the function
   * @param _newWeights Array of new weights for the rebalance
   */
  struct EnableRebalanceData {
    uint256[] _lpSlippage;
    uint96[] _newWeights;
  }

  /**
   * @notice Struct having data for the init of Asset Manager Config
   * @param _managementFee Management fee (streaming fee) that the asset manager will receive for managing the fund
   * @param _performanceFee Fee that the asset manager will receive for managing the fund and if the portfolio performance well
   * @param _entryFee Entry fee associated with the config
   * @param _exitFee Exit fee associated with the config
   * @param _minInvestmentAmount Minimum investment amount specified as per the config
   * @param _maxInvestmentAmount Maximum investment amount specified as per the config
   * @param _tokenRegistry Address of the Token Registry associated with the config
   * @param _accessController Address of the Access Controller associated with the config
   * @param _assetManagerTreasury Address of the Asset Manager Treasury account
   * @param _whitelistTokens Boolean parameter which specifies if the asset manager can only choose portfolio tokens from the whitelisted array or not
   * @param _publicPortfolio Boolean parameter for is the portfolio eligible for public investment or not
   * @param _transferable Boolean parameter for is the Index tokens from the fund transferable to public or not
   * @param _transferableToPublic Boolean parameter for is the Index tokens from the fund transferable to public or not
   * @param _whitelistTokens Boolean parameter for is the token whitelisting enabled for the fund or not
   */
  struct AssetManagerConfigInitData {
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    uint256 _minInvestmentAmount;
    uint256 _maxInvestmentAmount;
    address _tokenRegistry;
    address _accessController;
    address _assetManagerTreasury;
    address[] _whitelistedTokens;
    bool _publicPortfolio;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
  }

  /**
   * @notice Struct with data passed during the withdrawal from the Index Fund
   * @param _slippage Array of Slippage values passed for the withdrawal
   * @param _lpSlippage Array of LP Slippage values passed for the withdrawal
   * @param tokenAmount Amount of the Index Tokens that is to be withdrawn
   * @param _swapHandler Address of the swap handler being used for the withdrawal process
   * @param _token Address of the token being withdrawn to (must be a primary token)
   * @param isMultiAsset Boolean parameter for is the withdrawal being done in portfolio tokens (multi-token) or in the native token
   */
  struct WithdrawFund {
    uint256[] _slippage;
    uint256[] _lpSlippage;
    uint256 tokenAmount;
    address _swapHandler;
    address _token;
    bool isMultiAsset;
  }

  /**
   * @notice Struct with data passed during the investment into the Index Fund
   * @param _slippage Array of Slippage values passed for the investment
   * @param _lpSlippage Array of LP Slippage values passed for the deposit into LP protocols
   * @param _tokenAmount Amount of token being invested
   * @param _to Address that would receive the index tokens post successful investment
   * @param _swapHandler Address of the swap handler being used for the investment process
   * @param _token Address of the token being made investment in
   */
  struct InvestFund {
    uint256[] _slippage;
    uint256[] _lpSlippage;
    uint256 _tokenAmount;
    address _swapHandler;
    address _token;
  }

  /**
   * @notice Struct passed with values for the updation of tokens via the Rebalancing module
   * @param tokens Array of the new tokens that is to be updated to 
   * @param _swapHandler Address of the swap handler being used for the token update
   * @param denorms Denorms of the new tokens
   * @param _slippageSell Slippage allowed for the sale of tokens
   * @param _slippageBuy Slippage allowed for the purchase of tokens
   * @param _lpSlippageSell LP Slippage allowed for the sale of tokens
   * @param _lpSlippageBuy LP Slippage allowed for the purchase of tokens
   */
  struct UpdateTokens {
    address[] tokens;
    address _swapHandler;
    uint96[] denorms;
    uint256[] _slippageSell;
    uint256[] _slippageBuy;
    uint256[] _lpSlippageSell;
    uint256[] _lpSlippageBuy;
  }

  /**
   * @notice Struct having data for the redeem of tokens using the handlers for different protocols
   * @param _amount Amount of protocol tokens to be redeemed using the handler
   * @param _lpSlippage LP Slippage allowed for the redeem process
   * @param _to Address that would receive the redeemed tokens
   * @param _yieldAsset Address of the protocol token that is being redeemed against
   * @param isWETH Boolean parameter for is the redeem being done for WETH (native token) or not
   */
  struct RedeemData {
    uint256 _amount;
    uint256 _lpSlippage;
    address _to;
    address _yieldAsset;
    bool isWETH;
  }

  /**
   * @notice Struct having data for the setup of different roles during an Index Fund creation
   * @param _exchangeHandler Addresss of the Exchange handler for the fund
   * @param _index Address of the IndexSwap for the fund
   * @param _tokenRegistry Address of the Token Registry for the fund
   * @param _portfolioCreator Address of the account creating/deploying the portfolio
   * @param _rebalancing Address of the Rebalancing module for the fund
   * @param _offChainRebalancing Address of the Offchain-Rebalancing module for the fund
   * @param _rebalanceAggregator Address of the Rebalance Aggregator for the fund
   * @param _feeModule Address of the Fee Module for the fund
   * @param _offChainIndexSwap Address of the OffChain-IndexSwap for the fund
   */
  struct AccessSetup {
    address _exchangeHandler;
    address _index;
    address _tokenRegistry;
    address _portfolioCreator;
    address _rebalancing;
    address _offChainRebalancing;
    address _rebalanceAggregator;
    address _feeModule;
    address _offChainIndexSwap;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IHandler} from "./../../IHandler.sol";
import {IIndexSwap} from "./../../../core/IIndexSwap.sol";

contract ExchangeData {
  /**
   * @notice Struct having data for the swap and deposit using the Meta Aggregator
   * @param sellAmount Amount of token being swapped
   * @param _lpSlippage LP Slippage value allowed for the swap
   * @param sellTokenAddress Address of the token being swapped from
   * @param buyTokenAddress Address of the token being swapped to
   * @param swapHandler Address of the swaphandler being used for the swap
   * @param portfolioToken Portfolio token for the deposit
   * @param callData Encoded data associated with the swap
   */
  struct ExSwapData {
    uint256[] sellAmount;
    uint256 _lpSlippage;
    address[] sellTokenAddress;
    address[] buyTokenAddress;
    address swapHandler;
    address portfolioToken;
    bytes[] callData;
  }

  /**
   * @notice Struct having data for the offchain investment values
   * @param buyAmount Amount to be invested
   * @param _buyToken Address of the token to be invested in
   * @param sellTokenAddress Address of the token in which the investment is being made
   * @param offChainHandler Address of the offchain handler being used
   * @param _buySwapData Encoded data for the investment
   */
  struct ZeroExData {
    uint256[] buyAmount;
    address[] _buyToken;
    address sellTokenAddress;
    address _offChainHandler;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having data for the offchain withdrawal values
   * @param sellAmount Amount of token to be withd
   * @param sellTokenAddress Address of the token being swapped from
   * @param offChainHandler Address of the offchain handler being used
   * @param buySwapData Encoded data for the withdrawal
   */
  struct ZeroExWithdraw {
    uint256[] sellAmount;
    address[] sellTokenAddress;
    address offChainHandler;
    bytes[] buySwapData;
  }

  /**
   * @notice Struct having data for pulling tokens and redeeming during withdrawal
   * @param tokenAmount Amount of token to be pulled and redeemed
   * @param _lpSlippage LP Slippage amount allowed for the operation
   * @param token Address of the token being pulled and redeemed
   */
  struct RedeemData {
    uint256 tokenAmount;
    uint256[] _lpSlippage;
    address token;
  }

  /**
   * @notice Struct having data for `IndexOperationsData` struct and also other functions like `SwapAndCalculate`
   * @param buyAmount Amount of the token to be purchased
   * @param sellTokenAddress Address of the token being swapped from
   * @param _offChainHanlder Address of the offchain handler being used
   * @param _buySwapData Encoded data for the swap
   */
  struct InputData {
    uint256[] buyAmount;
    address sellTokenAddress;
    address _offChainHandler;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having data for the `swapOffChainTokens` function from the Exchange handler
   * @param inputData Struct having different input params
   * @param index IndexSwap instance of the current fund
   * @param indexValue Value of the IndexSwap whose inforamtion has to be obtained
   * @param balance Token balance passed during the offchain swap
   * @param _lpSlippage Amount of LP Slippage allowed for the swap
   * @param _buyAmount Amount of token being swapped to
   * @param _token Portoflio token to be invested in
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   */
  struct IndexOperationData {
    ExchangeData.InputData inputData;
    IIndexSwap index;
    uint256 indexValue;
    uint256 _lpSlippage;
    uint256 _buyAmount;
    address _token;
    address _toUser;
  }

  /**
   * @notice Struct having data for the offchain withdrawal
   * @param sellAmount Amount of token being withdrawn
   * @param userAmount Amount of sell token that the user is holding
   * @param sellTokenAddress Address of the token being swapped from
   * @param offChainHandler Address of the offchain handler being used
   * @param buyToken Address of the token being swapped to
   * @param swapData Enocoded swap data for the withdraw
   */
  struct withdrawData {
    uint256 sellAmount;
    uint256 userAmount;
    address sellTokenAddress;
    address offChainHandler;
    address buyToken;
    bytes swapData;
  }

  /**
   * @notice Struct having data for the swap of tokens using the offchain handler
   * @param sellAmount Amount of token being swapped
   * @param sellTokenAddress Address of the token being swapped from
   * @param buyTokenAddress Address of the token being swapped to
   * @param swapHandler Address of the offchain swaphandler being used
   * @param callData Encoded calldata for the swap
   */
  struct MetaSwapData {
    uint256 sellAmount;
    address sellTokenAddress;
    address buyTokenAddress;
    address swapHandler;
    bytes callData;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {ExchangeData} from "../handler/ExternalSwapHandler/Helper/ExchangeData.sol";

interface IExternalSwapHandler {
  function swap(
    address sellTokenAddress,
    address buyTokenAddress,
    uint sellAmount,
    bytes memory callData,
    address _to
  ) external payable;

  function setAllowance(address _token, address _spender, uint _sellAmount) external;
}

// SPDX-License-Identifier: BUSL-1.1

// lend token
// redeem token
// claim token
// get token balance
// get underlying balance

pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IHandler {
  function deposit(address, uint256[] memory, uint256, address, address) external payable returns (uint256);

  function redeem(FunctionParameters.RedeemData calldata inputData) external;

  function getTokenBalance(address, address) external view returns (uint256);

  function getUnderlyingBalance(address, address) external returns (uint256[] memory);

  function getUnderlying(address) external view returns (address[] memory);

  function getRouterAddress() external view returns (address);

  function encodeData(address t, uint256 _amount) external returns (bytes memory);

  function getClaimTokenCalldata(address _alpacaToken, address _holder) external returns (bytes memory, address);

  function getTokenBalanceUSD(address _tokenHolder, address t) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface ISwapHandler {
  function getETH() external view returns (address);

  function getSwapAddress(uint256 _swapAmount, address _t) external view returns (address);

  function swapTokensToETH(uint256 _swapAmount, uint256 _slippage, address _t, address _to, bool isEnabled) external returns (uint256);

  function swapETHToTokens(uint256 _slippage, address _t, address _to) external payable returns (uint256);

  function swapTokenToTokens(
    uint256 _swapAmount,
    uint256 _slippage,
    address _tokenIn,
    address _tokenOut,
    address _to,
    bool isEnabled
  ) external returns (uint256 swapResult);

  function getPathForETH(address crypto) external view returns (address[] memory);

  function getPathForToken(address token) external view returns (address[] memory);

  function getSlippage(
    uint256 _amount,
    uint256 _slippage,
    address[] memory path
  ) external view returns (uint256 minAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

/**
 * @title ErrorLibrary
 * @author Velvet.Capital
 * @notice This is a library contract including custom defined errors
 */

library ErrorLibrary {
  error ContractPaused();
  /// @notice Thrown when caller is not rebalancer contract
  error CallerNotRebalancerContract();
  /// @notice Thrown when caller is not asset manager
  error CallerNotAssetManager();
  /// @notice Thrown when caller is not asset manager
  error CallerNotSuperAdmin();
  /// @notice Thrown when caller is not whitelist manager
  error CallerNotWhitelistManager();
  /// @notice Thrown when length of slippage array is not equal to tokens array
  error InvalidSlippageLength();
  /// @notice Thrown when length of tokens array is zero
  error InvalidLength();
  /// @notice Thrown when token is not permitted
  error TokenNotPermitted();
  /// @notice Thrown when user is not allowed to invest
  error UserNotAllowedToInvest();
  /// @notice Thrown when index token in not initialized
  error NotInitialized();
  /// @notice Thrown when investment amount is greater than or less than the set range
  error WrongInvestmentAmount(uint256 minInvestment, uint256 maxInvestment);
  /// @notice Thrown when swap amount is greater than BNB balance of the contract
  error NotEnoughBNB();
  /// @notice Thrown when the total sum of weights is not equal to 10000
  error InvalidWeights(uint256 totalWeight);
  /// @notice Thrown when balance is below set velvet min investment amount
  error BalanceCantBeBelowVelvetMinInvestAmount(uint256 minVelvetInvestment);
  /// @notice Thrown when caller is not holding underlying token amount being swapped
  error CallerNotHavingGivenTokenAmount();
  /// @notice Thrown when length of denorms array is not equal to tokens array
  error InvalidInitInput();
  /// @notice Thrown when the tokens are already initialized
  error AlreadyInitialized();
  /// @notice Thrown when the token is not whitelisted
  error TokenNotWhitelisted();
  /// @notice Thrown when denorms array length is zero
  error InvalidDenorms();
  /// @notice Thrown when token address being passed is zero
  error InvalidTokenAddress();
  /// @notice Thrown when token is not permitted
  error InvalidToken();
  /// @notice Thrown when token is not approved
  error TokenNotApproved();
  /// @notice Thrown when transfer is prohibited
  error Transferprohibited();
  /// @notice Thrown when transaction caller balance is below than token amount being invested
  error LowBalance();
  /// @notice Thrown when address is already approved
  error AddressAlreadyApproved();
  /// @notice Thrown when swap handler is not enabled inside token registry
  error SwapHandlerNotEnabled();
  /// @notice Thrown when swap amount is zero
  error ZeroBalanceAmount();
  /// @notice Thrown when caller is not index manager
  error CallerNotIndexManager();
  /// @notice Thrown when caller is not fee module contract
  error CallerNotFeeModule();
  /// @notice Thrown when lp balance is zero
  error LpBalanceZero();
  /// @notice Thrown when desired swap amount is greater than token balance of this contract
  error InvalidAmount();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInAlpacaProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountMustBeEqualToValue();
  /// @notice Thrown when the mint function returned 0 for success & 1 for failure
  error MintProcessFailed();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInApeSwap();
  /// @notice Thrown when the redeeming was success(0) or failure(1)
  error RedeemingCTokenFailed();
  /// @notice Thrown when native BNB is sent for any vault other than mooVenusBNB
  error PleaseDepositUnderlyingToken();
  /// @notice Thrown when redeem amount is greater than tokenBalance of protocol
  error NotEnoughBalanceInBeefyProtocol();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInBeefy();
  /// @notice Thrown when the deposit amount of underlying token A is more than contract balance
  error InsufficientTokenABalance();
  /// @notice Thrown when the deposit amount of underlying token B is more than contract balance
  error InsufficientTokenBBalance();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInBiSwapProtocol();
  //Not enough funds
  error InsufficientFunds(uint256 available, uint256 required);
  //Not enough eth for protocol fee
  error InsufficientFeeFunds(uint256 available, uint256 required);
  //Order success but amount 0
  error ZeroTokensSwapped();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInLiqeeProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountMustBeEqualToValuePassed();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInPancakeProtocol();
  /// @notice Thrown when Pid passed is not equal to Pid stored in Pid map
  error InvalidPID();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error InsufficientBalance();
  /// @notice Thrown when the redeem function returns 1 for fail & 0 for success
  error RedeemingFailed();
  /// @notice Thrown when the token passed in getUnderlying is not cToken
  error NotcToken();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInWombatProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountNotEqualToPassedValue();
  /// @notice Thrown when slippage value passed is greater than 100
  error SlippageCannotBeGreaterThan100();
  /// @notice Thrown when tokens are already staked
  error TokensStaked();
  /// @notice Thrown when contract is not paused
  error ContractNotPaused();
  /// @notice Thrown when offchain handler is not valid
  error OffHandlerNotValid();
  /// @notice Thrown when offchain handler is not enabled
  error OffHandlerNotEnabled();
  /// @notice Thrown when swapHandler is not enabled
  error SwaphandlerNotEnabled();
  /// @notice Thrown when account other than asset manager calls
  error OnlyAssetManagerCanCall();
  /// @notice Thrown when already redeemed
  error AlreadyRedeemed();
  /// @notice Thrown when contract is not paused
  error NotPaused();
  /// @notice Thrown when token is not index token
  error TokenNotIndexToken();
  /// @notice Thrown when swaphandler is invalid
  error SwapHandlerNotValid();
  /// @notice Thrown when token that will be bought is invalid
  error BuyTokenAddressNotValid();
  /// @notice Thrown when not redeemed
  error NotRedeemed();
  /// @notice Thrown when caller is not asset manager
  error CallerIsNotAssetManager();
  /// @notice Thrown when account other than asset manager is trying to pause
  error OnlyAssetManagerCanCallUnpause();
  /// @notice Thrown when trying to redeem token that is not staked
  error TokensNotStaked();
  /// @notice Thrown when account other than asset manager is trying to revert or unpause
  error FifteenMinutesNotExcedeed();
  /// @notice Thrown when swapping weight is zero
  error WeightNotGreaterThan0();
  /// @notice Thrown when dividing by zero
  error DivBy0Sumweight();
  /// @notice Thrown when lengths of array are not equal
  error LengthsDontMatch();
  /// @notice Thrown when contract is not paused
  error ContractIsNotPaused();
  /// @notice Thrown when set time period is not over
  error TimePeriodNotOver();
  /// @notice Thrown when trying to set any fee greater than max allowed fee
  error InvalidFee();
  /// @notice Thrown when zero address is passed for treasury
  error ZeroAddressTreasury();
  /// @notice Thrown when assetManagerFee or performaceFee is set zero
  error ZeroFee();
  /// @notice Thrown when trying to enable an already enabled handler
  error HandlerAlreadyEnabled();
  /// @notice Thrown when trying to disable an already disabled handler
  error HandlerAlreadyDisabled();
  /// @notice Thrown when zero is passed as address for oracle address
  error InvalidOracleAddress();
  /// @notice Thrown when zero is passed as address for handler address
  error InvalidHandlerAddress();
  /// @notice Thrown when token is not in price oracle
  error TokenNotInPriceOracle();
  /// @notice Thrown when address is not approved
  error AddressNotApproved();
  /// @notice Thrown when minInvest amount passed is less than minInvest amount set
  error InvalidMinInvestmentAmount();
  /// @notice Thrown when maxInvest amount passed is greater than minInvest amount set
  error InvalidMaxInvestmentAmount();
  /// @notice Thrown when zero address is being passed
  error InvalidAddress();
  /// @notice Thrown when caller is not the owner
  error CallerNotOwner();
  /// @notice Thrown when out asset address is zero
  error InvalidOutAsset();
  /// @notice Thrown when protocol is not paused
  error ProtocolNotPaused();
  /// @notice Thrown when protocol is paused
  error ProtocolIsPaused();
  /// @notice Thrown when proxy implementation is wrong
  error ImplementationNotCorrect();
  /// @notice Thrown when caller is not offChain contract
  error CallerNotOffChainContract();
  /// @notice Thrown when user has already redeemed tokens
  error TokenAlreadyRedeemed();
  /// @notice Thrown when user has not redeemed tokens
  error TokensNotRedeemed();
  /// @notice Thrown when user has entered wrong amount
  error InvalidSellAmount();
  /// @notice Thrown when trasnfer fails
  error WithdrawTransferFailed();
  /// @notice Thrown when caller is not having minter role
  error CallerNotMinter();
  /// @notice Thrown when caller is not handler contract
  error CallerNotHandlerContract();
  /// @notice Thrown when token is not enabled
  error TokenNotEnabled();
  /// @notice Thrown when index creation is paused
  error IndexCreationIsPause();
  /// @notice Thrown denorm value sent is zero
  error ZeroDenormValue();
  /// @notice Thrown when asset manager is trying to input token which already exist
  error TokenAlreadyExist();
  /// @notice Thrown when cool down period is not passed
  error CoolDownPeriodNotPassed();
  /// @notice Thrown When Buy And Sell Token Are Same
  error BuyAndSellTokenAreSame();
  /// @notice Throws arrow when token is not a reward token
  error NotRewardToken();
  /// @notice Throws arrow when MetaAggregator Swap Failed
  error SwapFailed();
  /// @notice Throws arrow when Token is Not  Primary
  error NotPrimaryToken();
  /// @notice Throws when the setup is failed in gnosis
  error ModuleNotInitialised();
  /// @notice Throws when threshold is more than owner length
  error InvalidThresholdLength();
  /// @notice Throws when no owner address is passed while fund creation
  error NoOwnerPassed();
  /// @notice Throws when length of underlying token is greater than 1
  error InvalidTokenLength();
  /// @notice Throws when already an operation is taking place and another operation is called
  error AlreadyOngoingOperation();
  /// @notice Throws when wrong function is executed for revert offchain fund
  error InvalidExecution();
  /// @notice Throws when Final value after investment is zero
  error ZeroFinalInvestmentValue();
  /// @notice Throws when token amount after swap / token amount to be minted comes out as zero
  error ZeroTokenAmount();
  /// @notice Throws eth transfer failed
  error ETHTransferFailed();
  /// @notice Thorws when the caller does not have a default admin role
  error CallerNotAdmin();
  /// @notice Throws when buyAmount is not correct in offchainIndexSwap
  error InvalidBuyValues();
  /// @notice Throws when token is not primary
  error TokenNotPrimary();
  /// @notice Throws when tokenOut during withdraw is not permitted in the asset manager config
  error _tokenOutNotPermitted();
  /// @notice Throws when token balance is too small to be included in index
  error BalanceTooSmall();
  /// @notice Throws when a public fund is tried to made transferable only to whitelisted addresses
  error PublicFundToWhitelistedNotAllowed();
  /// @notice Throws when list input by user is invalid (meta aggregator)
  error InvalidInputTokenList();
  /// @notice Generic call failed error
  error CallFailed();
  /// @notice Generic transfer failed error
  error TransferFailed();
  /// @notice Throws when handler underlying token is not ETH
  error TokenNotETH();  
   /// @notice Thrown when the token passed in getUnderlying is not vToken
  error NotVToken();
  /// @notice Throws when incorrect token amount is encountered during offchain/onchain investment
  error IncorrectInvestmentTokenAmount();
  /// @notice Throws when final invested amount after slippage is 0
  error ZeroInvestedAmountAfterSlippage();
  /// @notice Throws when the slippage trying to be set is in incorrect range
  error IncorrectSlippageRange();
  /// @notice Throws when invalid LP slippage is passed
  error InvalidLPSlippage();
  /// @notice Throws when invalid slippage for swapping is passed
  error InvalidSlippage();
  /// @notice Throws when msg.value is less than the amount passed into the handler
  error WrongNativeValuePassed();
  /// @notice Throws when there is an overflow during muldiv full math operation
  error FULLDIV_OVERFLOW();
  /// @notice Throws when the oracle price is not updated under set timeout
  error PriceOracleExpired();
  /// @notice Throws when the oracle price is returned 0
  error PriceOracleInvalid();
  /// @notice Throws when the initToken or updateTokenList function of IndexSwap is having more tokens than set by the Registry
  error TokenCountOutOfLimit(uint256 limit);
  /// @notice Throws when the array lenghts don't match for adding price feed or enabling tokens
  error IncorrectArrayLength();
  /// @notice Common Reentrancy error for IndexSwap and IndexSwapOffChain
  error ReentrancyGuardReentrantCall();
  /// @notice Throws when user calls updateFees function before proposing a new fee
  error NoNewFeeSet();
  /// @notice Throws when wrong asset is supplied to the Compound v3 Protocol
  error WrongAssetBeingSupplied();
  /// @notice Throws when wrong asset is being withdrawn from the Compound v3 Protocol
  error WrongAssetBeingWithdrawn();
  /// @notice Throws when sequencer is down
  error SequencerIsDown();
  /// @notice Throws when sequencer threshold is not crossed
  error SequencerThresholdNotCrossed();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IPriceOracle {
  function WETH() external returns(address);

  function _addFeed(address base, address quote, AggregatorV2V3Interface aggregator) external;

  function decimals(address base, address quote) external view returns (uint8);

  function latestRoundData(address base, address quote) external view returns (int256);

  function getUsdEthPrice(uint256 amountIn) external view returns (uint256 amountOut);

  function getEthUsdPrice(uint256 amountIn) external view returns (uint256 amountOut);

  function getPrice(address base, address quote) external view returns (int256);

  function getPriceForAmount(address token, uint256 amount, bool ethPath) external view returns (uint256 amountOut);

  function getPriceForTokenAmount(
    address tokenIn,
    address tokenOut,
    uint256 amount
  ) external view returns (uint256 amountOut);

  function getPriceTokenUSD18Decimals(address _base, uint256 amountIn) external view returns (uint256 amountOut);

  function getPriceForOneTokenInUSD(address _base) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;
import {IIndexSwap} from "../core/IIndexSwap.sol";
import {IExchange} from "../core/IExchange.sol";
import {IndexSwapLibrary, IAssetManagerConfig, ITokenRegistry, ErrorLibrary} from "../core/IndexSwapLibrary.sol";
import {IHandler, FunctionParameters} from "../handler/IHandler.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/interfaces/IERC20Upgradeable.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IExternalSwapHandler} from "../handler/IExternalSwapHandler.sol";

library RebalanceLibrary {
  /**
   * @notice The function evaluates new denorms after updating the token list
   * @param tokens The new portfolio tokens
   * @param denorms The new token weights for the updated token list
   * @return A list of updated denorms for the new token list
   */
  function evaluateNewDenorms(
    IIndexSwap index,
    address[] memory tokens,
    uint96[] memory denorms
  ) public view returns (uint256[] memory) {
    address[] memory token = index.getTokens();
    uint256[] memory newDenorms = new uint256[](token.length);
    for (uint256 i = 0; i < token.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        if (token[i] == tokens[j]) {
          newDenorms[i] = denorms[j];
          break;
        }
      }
    }
    return newDenorms;
  }

  function getSwapAmount(
    IIndexSwap index,
    address _token,
    uint256 _amountA,
    uint256 _amountB
  ) external view returns (uint256 amount) {
    uint256 tokenBalance = IndexSwapLibrary.getTokenBalance(index, _token);
    amount = (tokenBalance * _amountA) / _amountB;
  }

  function getAmountToSwap(
    IIndexSwap index,
    address _token,
    uint256 newWeight,
    uint256 oldWeight
  ) external view returns (uint256 amount) {
    uint256 tokenBalance = IndexSwapLibrary.getTokenBalance(index, _token);

    uint256 weightDiff = oldWeight - newWeight;
    uint256 swapAmount = (tokenBalance * weightDiff) / oldWeight;
    return swapAmount;
  }

  /**
   * @notice The function updates record for the metaAggregatorSwap
   * @param index Index address whose tokens weight needs to be found
   * @param tokens Array of token addresses passed to the function
   * @return Array of the current weights returned
   */

  function getCurrentWeights(
    IIndexSwap index,
    address[] calldata tokens,
    uint256 _vaultBalance
  ) external returns (uint96[] memory) {
    uint96[] memory oldWeights = new uint96[](tokens.length);

    uint256[] memory tokenBalanceInUSD = new uint256[](tokens.length);

    (tokenBalanceInUSD, ) = IndexSwapLibrary.getTokenAndVaultBalance(index, tokens);

    for (uint256 i = 0; i < tokens.length; i++) {
      oldWeights[i] = uint96(
        (_vaultBalance == 0) ? _vaultBalance : (tokenBalanceInUSD[i] * index.TOTAL_WEIGHT()) / _vaultBalance
      );
    }
    return oldWeights;
  }

  function getRebalanceSwapData(
    uint256[] calldata newWeights,
    IIndexSwap index
  ) external returns (address[] memory, uint256[] memory) {
    address[] memory tokens = index.getTokens();
    address[] memory sellTokens = new address[](tokens.length);
    uint256[] memory swapAmounts = new uint256[](tokens.length);
    uint256 vaultBalance;

    uint256[] memory tokenBalanceInUSD = new uint256[](tokens.length);

    (tokenBalanceInUSD, vaultBalance) = IndexSwapLibrary.getTokenAndVaultBalance(index, tokens);
    for (uint256 i = 0; i < tokens.length; i++) {
      address _token = tokens[i];
      uint256 oldWeight = (vaultBalance == 0)
        ? vaultBalance
        : (tokenBalanceInUSD[i] * index.TOTAL_WEIGHT()) / vaultBalance;
      uint256 _newWeight = newWeights[i];
      if (_newWeight < oldWeight) {
        uint256 tokenBalance = IndexSwapLibrary.getTokenBalance(index, _token);
        uint256 weightDiff = oldWeight - _newWeight;
        swapAmounts[i] = (tokenBalance * weightDiff) / oldWeight;
        sellTokens[i] = _token;
      }
    }
    return (sellTokens, swapAmounts);
  }

  function getUpdateTokenData(
    IIndexSwap index,
    address[] calldata newTokens,
    uint96[] calldata newWeights
  ) external view returns (address[] memory, uint256[] memory) {
    address[] memory tokens = index.getTokens();
    uint256[] memory newDenorms = evaluateNewDenorms(index, newTokens, newWeights);
    uint256[] memory swapAmounts = new uint256[](tokens.length);
    address[] memory tokenSell = new address[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      if (newDenorms[i] == 0) {
        swapAmounts[i] = IndexSwapLibrary.getTokenBalance(index, tokens[i]);
        tokenSell[i] = tokens[i];
      }
    }
    return (tokenSell, swapAmounts);
  }

  function getUpdateWeightTokenData(
    IIndexSwap index,
    address[] calldata newTokens,
    uint96[] calldata newWeights
  ) external returns (address[] memory, uint256[] memory) {
    address[] memory sellTokens = new address[](newTokens.length);
    uint256[] memory sellAmount = new uint256[](newTokens.length);
    uint256 vaultBalance;
    uint256[] memory tokenBalanceInUSD = new uint256[](newTokens.length);
    (, vaultBalance) = IndexSwapLibrary.getTokenAndVaultBalance(index, index.getTokens());
    (tokenBalanceInUSD, ) = IndexSwapLibrary.getTokenAndVaultBalance(index, newTokens);  
    for (uint256 i = 0; i < newTokens.length; i++) {
      uint256 oldWeight = (vaultBalance == 0)
        ? vaultBalance
        : (tokenBalanceInUSD[i] * index.TOTAL_WEIGHT()) / vaultBalance;
      if (newWeights[i] < oldWeight) {
        uint256 tokenBalance = IndexSwapLibrary.getTokenBalance(index, newTokens[i]);
        uint256 weightDiff = oldWeight - newWeights[i];
        sellAmount[i] = (tokenBalance * weightDiff) / oldWeight;
        sellTokens[i] = newTokens[i];
      }
    }
    return (sellTokens, sellAmount);
  }

  function getNewTokens(address[] calldata tokens, address portfolioToken) external pure returns (address[] memory) {
    address[] memory newTokens = new address[](tokens.length + 1);
    for (uint i = 0; i < tokens.length; i++) {
      if (tokens[i] == portfolioToken) {
        return tokens;
      }
      newTokens[i] = tokens[i];
    }
    newTokens[tokens.length] = portfolioToken;
    return newTokens;
  }

  /**
   * @notice The function updates record for the metaAggregatorSwap
   * @param index Index address whose record needs to be updated
   * @param _tokens Array of all tokens of the index
   * @param portfolioToken The portfolio token which needs to be updated
   */
  function setRecord(IIndexSwap index, address[] memory _tokens, address portfolioToken) external {
    uint96[] memory oldWeights = new uint96[](_tokens.length);

    uint256[] memory tokenBalanceInUSD = new uint256[](_tokens.length);
    uint256 vaultBalance;
    uint256 bTokenIndex;
    uint256 count;

    if (index.totalSupply() > 0) {
      (tokenBalanceInUSD, vaultBalance) = IndexSwapLibrary.getTokenAndVaultBalance(IIndexSwap(index), _tokens);

      uint256 sum;

      for (uint256 i = 0; i < _tokens.length; i++) {
        oldWeights[i] = uint96((tokenBalanceInUSD[i] * index.TOTAL_WEIGHT()) / vaultBalance);
        sum += oldWeights[i];
        if (oldWeights[i] != 0) {
          count++;
        }
        if (_tokens[i] == portfolioToken) {
          bTokenIndex = i;
          if (oldWeights[i] == 0) {
            count++;
          }
        }
      }

      if (sum != index.TOTAL_WEIGHT()) {
        uint256 diff = index.TOTAL_WEIGHT() - sum;
        oldWeights[bTokenIndex] = oldWeights[bTokenIndex] + uint96(diff);
      }

      if (oldWeights[bTokenIndex] == 0) {
        revert ErrorLibrary.BalanceTooSmall();
      }
      uint256 j;

      address[] memory tempTokens = new address[](count);
      uint96[] memory tempWeights = new uint96[](count);

      for (uint256 i = 0; i < _tokens.length; i++) {
        if (oldWeights[i] != 0) {
          tempTokens[j] = _tokens[i];
          tempWeights[j] = oldWeights[i];
          j++;
        } else {
          index.deleteRecord(_tokens[i]);
        }
      }

      index.updateTokenListAndRecords(tempTokens, tempWeights);

      index.setRedeemed(false);
      index.setPaused(false);
    }
  }

  function updateTokensCheck(address tokenRegistry, address assetManagerConfig, address _token) external {
    if (!(ITokenRegistry(tokenRegistry).isEnabled(_token))) {
      revert ErrorLibrary.TokenNotApproved();
    }

    if (
      !(!IAssetManagerConfig(assetManagerConfig).whitelistTokens() ||
        IAssetManagerConfig(assetManagerConfig).whitelistedToken(_token))
    ) {
      revert ErrorLibrary.TokenNotWhitelisted();
    }
  }

  /**
   * @notice This function gets the underlying balances of the input token
   * @param _token Address of the token whose underlying balance is to be calculated
   * @param _handler Address of the handler of the token passed
   * @param _contract Address of the contract whose underlying balance is to be calculated
   * @return Array of underlying balances for the passed tokens
   */
  function getUnderlyingBalances(
    address _token,
    IHandler _handler,
    address _contract
  ) external view returns (uint256[] memory) {
    address[] memory underlying = _handler.getUnderlying(_token);
    uint256[] memory balances = new uint256[](underlying.length);
    for (uint256 i = 0; i < underlying.length; i++) {
      balances[i] = IERC20Upgradeable(underlying[i]).balanceOf(_contract);
    }
    return balances;
  }

  function checkPrimary(IIndexSwap index, address[] calldata tokens) external view {
    for (uint i = 0; i < tokens.length; i++) {
      if (!ITokenRegistry(index.tokenRegistry()).getTokenInformation(tokens[i]).primary) {
        revert ErrorLibrary.NotPrimaryToken();
      }
    }
  }

  function beforeExternalRebalance(IIndexSwap index, ITokenRegistry tokenRegistry,address offchainHandler) external {
    if (!(index.paused())) {
      revert ErrorLibrary.ContractNotPaused();
    }
    if (!index.getRedeemed()) {
      revert ErrorLibrary.TokensStaked();
    }
    if (tokenRegistry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (!tokenRegistry.isExternalSwapHandler(offchainHandler)) {
      revert ErrorLibrary.OffHandlerNotEnabled();
    }
  }

  function beforeExternalSell(IIndexSwap index, ITokenRegistry tokenRegistry, address handler) external view {
    if (!(tokenRegistry.isExternalSwapHandler(handler))) {
      revert ErrorLibrary.OffHandlerNotValid();
    }
    if (!index.getRedeemed()) {
      revert ErrorLibrary.TokensStaked();
    }
  }

  function beforePullAndRedeem(IIndexSwap index, IAssetManagerConfig config, address token) external {
    if (!(index.paused())) {
      revert ErrorLibrary.ContractNotPaused();
    }
    if (!(!config.whitelistTokens() || config.whitelistedToken(token))) {
      revert ErrorLibrary.TokenNotWhitelisted();
    }
  }

  function getOldWeights(IIndexSwap index, address[] calldata tokens) external view returns (uint96[] memory) {
    uint96[] memory oldWeight = new uint96[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      oldWeight[i] = index.getRecord(tokens[i]).denorm;
    }
    return oldWeight;
  }

  function beforeRevertCheck(IIndexSwap index) external view {
    if (!(index.paused())) {
      revert ErrorLibrary.ContractNotPaused();
    }
    if (!index.getRedeemed()) {
      revert ErrorLibrary.TokensStaked();
    }
  }

  function getEthBalance(
    address _eth,
    address[] memory _underlying,
    uint256[] calldata _amount
  ) external returns (uint256, uint256) {
    if (_underlying[0] == _eth) {
      IWETH(_eth).withdraw(_amount[0]);
      return (_amount[0], 1);
    }
    IWETH(_eth).withdraw(_amount[1]);
    return (_amount[1], 0);
  }

  function validateEnableRebalance(IIndexSwap _index, ITokenRegistry _registry, bool isRedeemed) external {
    if (_registry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (_index.paused()) {
      revert ErrorLibrary.ContractPaused();
    }
    if (isRedeemed) {
      revert ErrorLibrary.AlreadyOngoingOperation();
    }
  }

  function validateUpdateRecord(
    address[] memory _newTokens,
    IAssetManagerConfig config,
    ITokenRegistry registry
  ) external {
    for (uint256 i = 0; i < _newTokens.length; i++) {
      if ((config.whitelistTokens() && !config.whitelistedToken(_newTokens[i]))) {
        revert ErrorLibrary.TokenNotWhitelisted();
      }
      if (!registry.isEnabled(_newTokens[i])) {
        revert ErrorLibrary.InvalidToken();
      }
    }
  }

  /**
   * @notice This function is used to validate that user input token address is same as underlying token address
   */
  function verifyAddress(
    address[] memory _redeemedTokensUnderlying,
    address[] memory _portfolioTokenUnderlying,
    address[] memory _sellTokens,
    address[] memory _buyTokens
  ) external pure {
    uint256 _maxLength = _redeemedTokensUnderlying.length > _portfolioTokenUnderlying.length
      ? _redeemedTokensUnderlying.length
      : _portfolioTokenUnderlying.length;

    if (_sellTokens.length != _buyTokens.length || _sellTokens.length != _maxLength) {
      revert ErrorLibrary.InvalidTokenLength();
    }
    _checkUnderlyingCounter(_redeemedTokensUnderlying, _sellTokens, _maxLength);
    _checkUnderlyingCounter(_portfolioTokenUnderlying, _buyTokens, _maxLength);
  }

  /**
   * @notice This function checks for the number of underlying tokens present
   */
  function _checkUnderlyingCounter(
    address[] memory _tokensUnderlying,
    address[] memory _userInputToken,
    uint256 _maxLength
  ) internal pure {
    uint tokenCounter;
    for (uint i = 0; i < _tokensUnderlying.length; i++) {
      for (uint j = 0; j < _maxLength; j++) {
        if (_tokensUnderlying[i] == _userInputToken[j]) {
          tokenCounter++;
        }
      }
    }
    if (tokenCounter != _maxLength) {
      revert ErrorLibrary.InvalidInputTokenList();
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title Rebalancing for a particular Index
 * @author Velvet.Capital
 * @notice This contract is used by asset manager to update weights, update tokens and call pause function.
 * @dev This contract includes functionalities:
 *      1. Pause the IndexSwap contract
 *      2. Update the token list
 *      3. Update the token weight
 */

pragma solidity 0.8.16;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/security/ReentrancyGuardUpgradeable.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable-4.3.2/access/OwnableUpgradeable.sol";
import {IndexSwapLibrary} from "../core/IndexSwapLibrary.sol";
import {IExchange} from "../core/IExchange.sol";

import {IWETH} from "../interfaces/IWETH.sol";

import {IIndexSwap} from "../core/IIndexSwap.sol";
import {AccessController} from "../access/AccessController.sol";

import {IPriceOracle} from "../oracle/IPriceOracle.sol";

import {ITokenRegistry} from "../registry/ITokenRegistry.sol";
import {IAssetManagerConfig} from "../registry/IAssetManagerConfig.sol";

import {RebalanceLibrary} from "./RebalanceLibrary.sol";
import {ErrorLibrary} from "../library/ErrorLibrary.sol";
import {FunctionParameters} from "../FunctionParameters.sol";
import {IHandler} from "../handler/IHandler.sol";

contract Rebalancing is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
  IIndexSwap internal index;
  AccessController internal accessController;
  ITokenRegistry internal tokenRegistry;
  IAssetManagerConfig internal assetManagerConfig;
  IExchange internal exchange;
  address internal _vault;

  IPriceOracle internal oracle;

  event UpdatedWeights(uint96[] newDenorms);
  event UpdatedTokens(address[] newTokens, uint96[] newDenorms);
  event SetPause(bool indexed state);

  constructor() {
    _disableInitializers();
  }

  /**
   * @notice This function is used to initialise the Rebalance module while deployment
   */
  function init(address _index, address _accessController) external initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    if (_index == address(0) || _accessController == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    index = IIndexSwap(_index);
    accessController = AccessController(_accessController);
    tokenRegistry = ITokenRegistry(index.tokenRegistry());
    exchange = IExchange(index.exchange());
    oracle = IPriceOracle(index.oracle());
    assetManagerConfig = IAssetManagerConfig(index.iAssetManagerConfig());
    _vault = index.vault();
  }

  modifier onlyAssetManager() {
    if (!(_checkRole("ASSET_MANAGER_ROLE", msg.sender))) {
      revert ErrorLibrary.CallerIsNotAssetManager();
    }
    _;
  }

  /**
    @notice The function will pause the InvestInFund() and Withdrawal().
    @param _state The state is bool value which needs to input by the Index Manager.
    */
  function setPause(bool _state) external virtual nonReentrant {
    address user = msg.sender;
    if (_state) {
      if (!(_checkRole("ASSET_MANAGER_ROLE", user))) {
        revert ErrorLibrary.OnlyAssetManagerCanCallUnpause();
      }
      _setPaused(_state);
    } else {
      if (getRedeemed()) {
        revert ErrorLibrary.TokensNotStaked();
      }
      uint256 _lastPaused = index.getLastPaused();
      if (getTimeStamp() >= (_lastPaused + 15 minutes)) {
        _setPaused(_state);
      } else {
        if (!(_checkRole("ASSET_MANAGER_ROLE", user))) {
          revert ErrorLibrary.FifteenMinutesNotExcedeed();
        }
        _setPaused(_state);
      }
    }
    emit SetPause(_state);
  }

  /**
   * @notice The function sells the excessive token amount of each token considering the new weights
   * @param _oldWeights The current token allocation in the portfolio
   * @param _newWeights The new token allocation the portfolio should be rebalanced to
   * @param _slippage Array of the slippage values passed
   * @param _lpSlippage Array of the lp slippage values passed
   * @return sumWeightsToSwap Returns the weight of tokens that have to be swapped to rebalance the portfolio (buy)
   */
  function sellTokens(
    uint256[] memory _oldWeights,
    uint256[] memory _newWeights,
    uint256[] calldata _slippage,
    uint256[] calldata _lpSlippage,
    address _swapHandler
  ) internal virtual returns (uint256 sumWeightsToSwap) {
    // sell - swap to BNB
    address[] memory tokens = getTokens();
    for (uint256 i = 0; i < tokens.length; i++) {
      if (_newWeights[i] < _oldWeights[i]) {
        uint256 tokenBalance = getTokenBalance(tokens[i]);

        uint256 weightDiff = _oldWeights[i] - _newWeights[i];
        uint256 swapAmount = (tokenBalance * weightDiff) / _oldWeights[i];
        _pullAndSwap(tokens[i], swapAmount, address(this), _slippage[i], _lpSlippage[i], _swapHandler);
      } else if (_newWeights[i] > _oldWeights[i]) {
        uint256 diff = _newWeights[i] - _oldWeights[i];
        sumWeightsToSwap = sumWeightsToSwap + diff;
      }
    }
  }

  /**
   * @notice The function swaps the sold BNB into tokens that haven't reached the new weight
   * @param _oldWeights The current token allocation in the portfolio
   * @param _newWeights The new token allocation the portfolio should be rebalanced to
   * @param sumWeightsToSwap Value of Sum Weight passed to the function
   * @param _slippage Array of the slippage values passed
   * @param _lpSlippage Array of the lp slippage values passed
   * @param _swapHandler Address of the associated swap handler
   */
  function buyTokens(
    uint256[] memory _oldWeights,
    uint256[] memory _newWeights,
    uint256 sumWeightsToSwap,
    uint256[] calldata _slippage,
    uint256[] calldata _lpSlippage,
    address _swapHandler
  ) internal virtual {
    uint256 totalBNBAmount = address(this).balance;
    address[] memory tokens = getTokens();
    if (sumWeightsToSwap == 0) {
      revert ErrorLibrary.DivBy0Sumweight();
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      if (_newWeights[i] > _oldWeights[i]) {
        uint256 weightToSwap = _newWeights[i] - _oldWeights[i];
        uint256 swapAmount = (totalBNBAmount * weightToSwap) / sumWeightsToSwap;
        exchange.swapETHToToken{value: swapAmount}(
          FunctionParameters.SwapETHToTokenPublicData(
            tokens[i],
            _vault,
            _swapHandler,
            _vault,
            _slippage[i],
            _lpSlippage[i]
          )
        );
      }
    }
  }

  /**
   * @notice The function rebalances the token weights in the portfolio
   * @param _slippage Array of the slippage values passed
   * @param _lpSlippage Array of the lp slippage values passed
   * @param _swapHandler Address of the associated swap handler
   */
  function rebalance(
    uint256[] calldata _slippage,
    uint256[] calldata _lpSlippage,
    address _swapHandler
  ) internal virtual {
    if (index.totalSupply() <= 0) {
      revert ErrorLibrary.InvalidAmount();
    }
    uint256 vaultBalance;
    address[] memory tokens = getTokens();
    uint256[] memory newWeights = new uint256[](tokens.length);
    uint256[] memory oldWeights = new uint256[](tokens.length);
    uint256[] memory tokenBalanceInUSD = new uint256[](tokens.length);

    (tokenBalanceInUSD, vaultBalance) = IndexSwapLibrary.getTokenAndVaultBalance(IIndexSwap(index), tokens);

    uint256 contractBalanceInUSD = oracle.getEthUsdPrice(address(this).balance);
    vaultBalance = vaultBalance + contractBalanceInUSD;

    for (uint256 i = 0; i < tokens.length; i++) {
      oldWeights[i] = (tokenBalanceInUSD[i] * index.TOTAL_WEIGHT()) / vaultBalance;
      newWeights[i] = uint256(getDenorm(tokens[i]));
    }

    uint256 sumWeightsToSwap = sellTokens(oldWeights, newWeights, _slippage, _lpSlippage, _swapHandler);
    buyTokens(oldWeights, newWeights, sumWeightsToSwap, _slippage, _lpSlippage, _swapHandler);

    index.setLastRebalance(getTimeStamp());
    index.setRedeemed(false);
  }

  /**
   * @notice The function updates the token weights and rebalances the portfolio to the new weights
   * @param denorms The new token weights of the portfolio
   * @param _slippage Array of the slippage values passed
   * @param _lpSlippage Array of the lp slippage values passed
   * @param _swapHandler Address of the associated swap handler
   */
  function updateWeights(
    uint96[] calldata denorms,
    uint256[] calldata _slippage,
    uint256[] calldata _lpSlippage,
    address _swapHandler
  ) external virtual nonReentrant onlyAssetManager {
    address[] memory tokens = getTokens();
    validateUpdate(_swapHandler);
    if (denorms.length != tokens.length) {
      revert ErrorLibrary.LengthsDontMatch();
    }
    if (tokens.length != _slippage.length || tokens.length != _lpSlippage.length) {
      revert ErrorLibrary.InvalidSlippageLength();
    }
    index.updateRecords(tokens, denorms);
    rebalance(_slippage, _lpSlippage, _swapHandler);
    emit UpdatedWeights(denorms);
  }

  /**
   * @notice The function rebalances the portfolio to the updated tokens with the updated weights
   * @param inputData The input calldata passed to the function
   */
  function updateTokens(
    FunctionParameters.UpdateTokens calldata inputData
  ) external virtual nonReentrant onlyAssetManager {
    address[] memory _tokens = getTokens();
    validateUpdate(inputData._swapHandler);
    if (
      _tokens.length != inputData._slippageSell.length ||
      inputData.tokens.length != inputData._slippageBuy.length ||
      _tokens.length != inputData._lpSlippageSell.length ||
      inputData.tokens.length != inputData._lpSlippageBuy.length
    ) {
      revert ErrorLibrary.InvalidSlippageLength();
    }
    for (uint256 i = 0; i < inputData.tokens.length; i++) {
      RebalanceLibrary.updateTokensCheck(address(tokenRegistry), address(assetManagerConfig), inputData.tokens[i]);
    }

    uint256[] memory newDenorms = RebalanceLibrary.evaluateNewDenorms(index, inputData.tokens, inputData.denorms);

    if (index.totalSupply() > 0) {
      // sell - swap to BNB
      for (uint256 i = 0; i < _tokens.length; i++) {
        address _token = _tokens[i];
        if (newDenorms[i] == 0) {
          uint256 tokenBalance = getTokenBalance(_token);
          _pullAndSwap(
            _token,
            tokenBalance,
            address(this),
            inputData._slippageSell[i],
            inputData._lpSlippageSell[i],
            inputData._swapHandler
          );
        }
        index.deleteRecord(_token);
      }
    }

    index.updateTokenListAndRecords(inputData.tokens, inputData.denorms);
    rebalance(inputData._slippageBuy, inputData._lpSlippageBuy, inputData._swapHandler);

    emit UpdatedTokens(inputData.tokens, inputData.denorms);
  }

  /**
   * @notice This function returns the given token balance of the vault
   * @param _token Address of the token whose balance is to be calculated
   * @return Token balance of the index returned
   */
  function getTokenBalance(address _token) public view virtual returns (uint256) {
    return IndexSwapLibrary.getTokenBalance(index, _token);
  }

  /**
   * @notice This function swaps token using the swapHandler
   * @param _token Address of the token which has to be pulled from the vault and swapped
   * @param _amount Amount of the token to be pulled and swapped
   * @param _to Address that would receive the pulled and swapped tokens (Exchange Handler)
   * @param _slippage Array of the slippage values passed
   * @param _lpSlippage Array of the lp slippage values passed
   * @param _swapHandler Address of the associated swap handler
   */
  function _pullAndSwap(
    address _token,
    uint256 _amount,
    address _to,
    uint256 _slippage,
    uint256 _lpSlippage,
    address _swapHandler
  ) internal virtual {
    exchange._pullFromVault(_token, _amount, address(exchange));
    exchange._swapTokenToETH(
      FunctionParameters.SwapTokenToETHData(_token, _to, _swapHandler, _amount, _slippage, _lpSlippage)
    );
  }

  /**
   * @notice This function swaps reward token to index token
   * @param rewardToken address of reward token to swap
   * @param swapHandler address fo swaphandler
   * @param buyToken address of buyToken token
   * @param amount amount of reward token to swap
   * @param slippage amount of slippage
   * @param _lpSlippage amount of lpSlippage
   */
  function swapRewardToken(
    address rewardToken,
    address swapHandler,
    address buyToken,
    uint256 amount,
    uint256 slippage,
    uint256 _lpSlippage
  ) external nonReentrant onlyAssetManager {
    validateUpdate(swapHandler);
    if (!tokenRegistry.isRewardToken(rewardToken)) {
      revert ErrorLibrary.NotRewardToken();
    }
    if (getDenorm(buyToken) == 0) {
      revert ErrorLibrary.TokenNotIndexToken();
    }
    _swapRewardToken(rewardToken, swapHandler, buyToken, amount, slippage, _lpSlippage);
  }

  /**
   * @notice This internal function is helper function of swapRewardToken
   * @param rewardToken address of reward token to swap
   * @param swapHandler address fo swaphandler
   * @param buyToken address of buyToken token
   * @param amount amount of reward token to swap
   * @param slippage amount of slippage
   * @param _lpSlippage amount of lpSlippage
   */
  function _swapRewardToken(
    address rewardToken,
    address swapHandler,
    address buyToken,
    uint256 amount,
    uint256 slippage,
    uint256 _lpSlippage
  ) internal {
    IHandler handler = IHandler(tokenRegistry.getTokenInformation(buyToken).handler);
    uint balanceBefore = handler.getTokenBalance(_vault, buyToken);
    exchange._pullFromVaultRewards(rewardToken, amount, address(exchange));
    exchange._swapTokenToToken(
      FunctionParameters.SwapTokenToTokenData(
        rewardToken,
        buyToken,
        _vault,
        swapHandler,
        _vault,
        amount,
        slippage,
        _lpSlippage,
        true
      )
    );
    uint balanceAfter = handler.getTokenBalance(_vault, buyToken);
    if (balanceAfter - balanceBefore == 0) {
      revert ErrorLibrary.SwapFailed();
    }
  }

  function _setPaused(bool _state) internal {
    index.setPaused(_state);
  }

  /**
   * @notice This function validate states before updating tokens and weights
   * @param _swapHandler Address of the swap handler to be used for validation
   */
  function validateUpdate(address _swapHandler) internal {
    if (tokenRegistry.getProtocolState() == true) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (!(tokenRegistry.isSwapHandlerEnabled(_swapHandler))) {
      revert ErrorLibrary.SwapHandlerNotEnabled();
    }
    if (getRedeemed()) revert ErrorLibrary.AlreadyOngoingOperation();
  }

  /**
   * @notice This function returns if the tokens have been redeemed or not
   */
  function getRedeemed() internal view returns (bool) {
    return index.getRedeemed();
  }

  /**
   * @notice This internal function check for role
   * @param _role Role to be checked
   * @param user User address who is checked for the role
   * @return Boolean parameter for is the user having the specific role
   */
  function _checkRole(bytes memory _role, address user) internal view returns (bool) {
    return accessController.hasRole(keccak256(_role), user);
  }

  /**
   * @notice The function is used to get tokens from index
   * @return Array of token returned
   */
  function getTokens() internal view returns (address[] memory) {
    return index.getTokens();
  }

  /**
   * @notice The function is used to get denorm of particular token
   * @param _token Address of the token whose denorm is to be retreived
   * @return Denorm value for the token
   */
  function getDenorm(address _token) internal view returns (uint96) {
    return index.getRecord(_token).denorm;
  }

  /**
   * @notice This function returns timeStamp
   */
  function getTimeStamp() internal view returns (uint256) {
    return block.timestamp;
  }

  // important to receive ETH
  receive() external payable {}

  /**
   * @notice Authorizes upgrade for this contract
   * @param newImplementation Address of the new implementation
   */
  function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IAssetManagerConfig {
  function init(FunctionParameters.AssetManagerConfigInitData calldata initData) external;

  function managementFee() external view returns (uint256);

  function performanceFee() external view returns (uint256);

  function entryFee() external view returns (uint256);

  function exitFee() external view returns (uint256);

  function MAX_INVESTMENTAMOUNT() external view returns (uint256);

  function MIN_INVESTMENTAMOUNT() external view returns (uint256);

  function assetManagerTreasury() external returns (address);

  function whitelistedToken(address) external returns (bool);

  function whitelistedUsers(address) external returns (bool);

  function publicPortfolio() external returns (bool);

  function transferable() external returns (bool);

  function transferableToPublic() external returns (bool);

  function whitelistTokens() external returns (bool);

  function setPermittedTokens(address[] calldata _newTokens) external;

  function deletePermittedTokens(address[] calldata _newTokens) external;

  function isTokenPermitted(address _token) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface ITokenRegistry {
  struct TokenRecord {
    bool primary;
    bool enabled;
    address handler;
    address[] rewardTokens;
  }

  function enableToken(address _oracle, address _token) external;

  function isEnabled(address _token) external view returns (bool);

  function isSwapHandlerEnabled(address swapHandler) external view returns (bool);

  function isOffChainHandlerEnabled(address offChainHandler) external view returns (bool);

  function disableToken(address _token) external;

  function checkNonDerivative(address handler) external view returns (bool);

  function getTokenInformation(address) external view returns (TokenRecord memory);

  function enableExternalSwapHandler(address swapHandler) external;

  function disableExternalSwapHandler(address swapHandler) external;

  function isExternalSwapHandler(address swapHandler) external view returns (bool);

  function isRewardToken(address) external view returns (bool);

  function velvetTreasury() external returns (address);

  function IndexOperationHandler() external returns (address);

  function WETH() external returns (address);

  function protocolFee() external returns (uint256);

  function protocolFeeBottomConstraint() external returns (uint256);

  function maxManagementFee() external returns (uint256);

  function maxPerformanceFee() external returns (uint256);

  function maxEntryFee() external returns (uint256);

  function maxExitFee() external returns (uint256);

  function exceptedRangeDecimal() external view returns(uint256);

  function MIN_VELVET_INVESTMENTAMOUNT() external returns (uint256);

  function MAX_VELVET_INVESTMENTAMOUNT() external returns (uint256);

  function enablePermittedTokens(address[] calldata _newTokens) external;

  function setIndexCreationState(bool _state) external;

  function setProtocolPause(bool _state) external;

  function setExceptedRangeDecimal(uint256 _newRange) external ;

  function getProtocolState() external returns (bool);

  function disablePermittedTokens(address[] calldata _tokens) external;

  function isPermitted(address _token) external returns (bool);

  function getETH() external view returns (address);

  function COOLDOWN_PERIOD() external view returns (uint256);

  function setMaxAssetLimit(uint256) external;

  function getMaxAssetLimit() external view returns (uint256);
}