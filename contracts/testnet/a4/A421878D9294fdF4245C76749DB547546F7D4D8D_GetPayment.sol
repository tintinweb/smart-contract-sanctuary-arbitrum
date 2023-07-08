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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract IERC20Extented is IERC20 {
    function decimals() public view virtual returns (uint8);
}

/**
 * @title GetPayment Contract
 * @notice This contract receives payment for orders
 */

contract GetPayment is AccessControl {
    // error constants
    string constant DEFAULT_ADMIN_ERROR = "need DEFAULT_ADMIN_ROLE";
    string constant TOKEN_ADMIN_ERROR = "need TOKEN_ADMIN_ROLE";
    string constant ORDER_ADMIN_ERROR = "need ORDER_ADMIN_ROLE";
    string constant ORACLE_ADRESS_ERROR = "INVALID_ORACLE_ADDRESS";
    string constant TOKEN_ADRESS_ERROR = "INVALID_TOKEN_ADDRESS";
    string constant TOKEN_ADDED_ERROR = "TOKEN_ALREADY_ADDED";
    string constant TOKEN_NOT_ADDED_ERROR = "TOKEN_NOT_ADDED";
    string constant BAD_TOKEN_ERROR = "BAD_TOKEN_FOR_PRICE_CALCULATIONS";
    string constant ZERO_DECIMALS_ERROR = "INVALID_DECIMALS";
    string constant TIME_ERROR = "BAD_EXPIRATION_TIME";
    string constant AMOUNT_ERROR = "INVALID_AMOUNT";
    string constant BALANCE_ERROR = "BALANCE_IS_NOT_ENOUGH";
    string constant SEND_ERROR = "FAILED_TO_SEND";
    string constant NOT_OWNER_ERROR = "msg.sender_NOT_OWNER";
    string constant ORDER_EXISTS_ERROR = "ORDER_ALREADY_EXIST";
    string constant ORDER_FULFILL_ERROR = "ORDER_FULFILLED";
    string constant ORDER_NOT_EXISTS_ERROR = "ORDER_NOT_EXIST";
    string constant ORDER_EXPIRED_ERROR = "ORDER_EXPIRED";
    string constant NATIVE_TOKEN_ERROR = "NATIVE_NOT_VALID_METHOD";
    string constant NATIVE_ADDRESS_ERROR = "NATIVE_ORACLE_ADDRESS_NOT_SET";
    string constant NATIVE_DECIMALS_ERROR = "NATIVE_DECIMALS_NOT_SET";
    string constant PAYMENT_NATIVE_ERROR = "PAYMENT_IS_NATIVE";
    string constant PAYMENT_NOT_NATIVE_ERROR = "PAYMENT_IS_NOT_NATIVE";

    address public nativePriceOracleAddress;
    uint256 nativeTokenDecimals;
    // when native payment method available, user can place an order that pays for native tokens
    bool public isNativeTokenValidPaymentMethod;
    // mapping of ERC20 tokens available for payment
    mapping(address => address) public paymentTokenPriceOracleAddress;
    // order expiration time
    uint256 public expirationTimeSeconds;

    enum OrderStatus {
        NOT_EXISTS,
        EXISTS,
        FULFILLED
    }
    struct Order {
        address owner;
        uint256 amountUSD;
        address paymentToken;
        uint256 amountToken;
        uint256 initializedAt;
        uint256 expiresAt;
        bool isPaymentNative;
        OrderStatus status;
    }
    mapping(bytes32 => Order) orders;

    bytes32 public constant TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");
    bytes32 public constant ORDER_ADMIN_ROLE = keccak256("ORDER_ADMIN_ROLE");

    event OrderFulfilledERC20(
        address indexed purchaser,
        bytes32 indexed orderId,
        uint256 indexed timestamp,
        uint256 amountUSD,
        address paymentTokenAddress,
        uint256 amountToken
    );

    event OrderFulfilledNative(
        address indexed purchaser,
        bytes32 indexed orderId,
        uint256 indexed timestamp,
        uint256 amountUSD,
        uint256 amountNative
    );

    /**
     * @dev common parameters are given through constructor.
     * @param _expirationTimeSeconds order expiration time in seconds
     **/
    constructor(uint256 _expirationTimeSeconds) {
        require(_expirationTimeSeconds > 0, TIME_ERROR);
        expirationTimeSeconds = _expirationTimeSeconds;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(TOKEN_ADMIN_ROLE, _msgSender());
        _setupRole(ORDER_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev calculate the price in ERC20 token for a given amount of usd
     * @param amountUSD price in usd. amountUSD  must be an integer, 1 amountUSD = 1 USD
     * @param tokenAddress address of ERC20 token
     */
    function calculatePriceERC20(uint256 amountUSD, address tokenAddress) public view returns (uint256) {
        address oracleAddress = paymentTokenPriceOracleAddress[tokenAddress];
        require(oracleAddress != address(0), BAD_TOKEN_ERROR);
        (, int answer, , , ) = AggregatorV3Interface(oracleAddress).latestRoundData();
        uint8 usdDecimals = AggregatorV3Interface(oracleAddress).decimals();
        uint8 tokenDecimals = IERC20Extented(tokenAddress).decimals();
        uint256 price = (amountUSD * (10 ** usdDecimals) * (10 ** tokenDecimals)) / uint256(answer);
        return price;
    }

    /**
     * @dev calculate the price in native token for a given amount of usd
     * @param amountUSD price in usd. amountUSD  must be an integer, 1 amountUSD = 1 USD
     */
    function calculatePriceNative(uint256 amountUSD) public view returns (uint256) {
        address oracleAddress = nativePriceOracleAddress;
        require(oracleAddress != address(0), BAD_TOKEN_ERROR);
        require(nativeTokenDecimals != 0, ZERO_DECIMALS_ERROR);
        (, int answer, , , ) = AggregatorV3Interface(oracleAddress).latestRoundData();
        uint8 usdDecimals = AggregatorV3Interface(oracleAddress).decimals();
        uint256 price = (amountUSD * (10 ** usdDecimals) * (10 ** nativeTokenDecimals)) / uint256(answer);
        return price;
    }

    /**
     * @dev set Chainlink price oracle address. Called only by TOKEN_ADMIN
     * @param oracleAddress  Chainlink price oracle address of NativeToken/USD pair
     */
    function setNativePriceOracleAddress(address oracleAddress) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(oracleAddress != address(0), ORACLE_ADRESS_ERROR);
        nativePriceOracleAddress = oracleAddress;
    }

    /**
     * @dev set decimals of native token. Called only by TOKEN_ADMIN
     * @param nativeDecimals decimals of native token
     */

    function setNativeTokenDecimals(uint8 nativeDecimals) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(nativeDecimals != 0, ZERO_DECIMALS_ERROR);
        nativeTokenDecimals = nativeDecimals;
    }

    /**
     * @dev set order expiration time. Called only by DEFAULT_ADMIN
     * @param _expirationTimeSeconds order expiration time in seconds
     */

    function setExpirationTimeSeconds(uint256 _expirationTimeSeconds) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), DEFAULT_ADMIN_ERROR);
        require(_expirationTimeSeconds > 0, TIME_ERROR);
        expirationTimeSeconds = _expirationTimeSeconds;
    }

    /**
     * @dev enable or disable the ability to pay for an order using native tokens. Called only by DEFAULT_ADMIN
     * @param isNativeValid boolean whether payment for the order with a native token is available
     */

    function setIsNativeTokenValidPaymentMethod(bool isNativeValid) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), DEFAULT_ADMIN_ERROR);
        isNativeTokenValidPaymentMethod = isNativeValid;
    }

    /**
     * @dev add a new payment ERC20 token. Called only by TOKEN_ADMIN
     * @param tokenAddress address of ERC20 token
     * @param oracleAddress Chainlink price oracle address of Token/USD pair
     */

    function addPaymentToken(address tokenAddress, address oracleAddress) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(tokenAddress != address(0), TOKEN_ADRESS_ERROR);
        require(oracleAddress != address(0), ORACLE_ADRESS_ERROR);
        require(paymentTokenPriceOracleAddress[tokenAddress] == address(0), TOKEN_ADDED_ERROR);
        paymentTokenPriceOracleAddress[tokenAddress] = oracleAddress;
    }

    /**
     * @dev change the oracle address of the payment token. Called only by TOKEN_ADMIN
     * @param tokenAddress address of ERC20 token
     * @param oracleAddress Chainlink price oracle address of Token/USD pair
     */

    function setPaymentTokenOracleAddress(address tokenAddress, address oracleAddress) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(tokenAddress != address(0), TOKEN_ADRESS_ERROR);
        require(oracleAddress != address(0), ORACLE_ADRESS_ERROR);
        require(paymentTokenPriceOracleAddress[tokenAddress] != address(0), TOKEN_NOT_ADDED_ERROR);
        paymentTokenPriceOracleAddress[tokenAddress] = oracleAddress;
    }

    /**
     * @dev remove payment token. Called only by TOKEN_ADMIN
     * @param tokenAddress address of ERC20 token
     */

    function removePaymentToken(address tokenAddress) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(tokenAddress != address(0), TOKEN_ADRESS_ERROR);
        paymentTokenPriceOracleAddress[tokenAddress] = address(0);
    }

    /**
     * @dev withdraw ERC20 token from the contract address to msgSender address. Called only by DEFAULT_ADMIN
     * @param tokenAddress address of ERC20 token
     * @param amount amount of tokens to withdraw
     */

    function withdrawERC20Tokens(address tokenAddress, uint256 amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), DEFAULT_ADMIN_ERROR);
        require(amount != 0, AMOUNT_ERROR);
        uint256 balance = IERC20Extented(tokenAddress).balanceOf(address(this));
        require(balance >= amount, BALANCE_ERROR);
        IERC20Extented(tokenAddress).transfer(_msgSender(), amount);
    }

    /**
     * @dev withdraw native token from the contract address to msgSender address. Called only by DEFAULT_ADMIN
     * @param amount amount of tokens to withdraw
     */

    function withdrawNative(uint256 amount) external payable {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), DEFAULT_ADMIN_ERROR);
        require(amount != 0, AMOUNT_ERROR);
        uint256 balance = address(this).balance;
        require(balance >= amount, BALANCE_ERROR);
        (bool sent, ) = payable(_msgSender()).call{value: amount}("");
        require(sent, SEND_ERROR);
    }

    /**
     * @dev place an order that pays for ERC20 tokens
     * @param orderId id of order
     * @param paymentToken the token that will be used to pay for the order
     * @param amountUSD price in usd. amountUSD  must be an integer, 1 amountUSD = 1 USD
     */
    function placeOrderERC20(bytes32 orderId, address paymentToken, uint256 amountUSD) external {
        require(!(isOrderPresented(orderId)), ORDER_EXISTS_ERROR);
        require(paymentTokenPriceOracleAddress[paymentToken] != address(0), TOKEN_ADRESS_ERROR);
        require(amountUSD > 0, AMOUNT_ERROR);
        uint256 timestamp = _now();
        orders[orderId] = Order(
            _msgSender(),
            amountUSD,
            paymentToken,
            calculatePriceERC20(amountUSD, paymentToken),
            timestamp,
            timestamp + expirationTimeSeconds,
            false,
            OrderStatus.EXISTS
        );
    }

    /**
     * @dev place an order that pays for native tokens
     * @param orderId id of order
     * @param amountUSD price in usd. amountUSD  must be an integer, 1 amountUSD = 1 USD
     */
    function placeOrderNative(bytes32 orderId, uint256 amountUSD) external {
        require(isNativeTokenValidPaymentMethod, NATIVE_TOKEN_ERROR);
        require(!(isOrderPresented(orderId)), ORDER_EXISTS_ERROR);
        require(nativePriceOracleAddress != address(0), NATIVE_ADDRESS_ERROR);
        require(nativeTokenDecimals != 0, NATIVE_DECIMALS_ERROR);
        require(amountUSD > 0, AMOUNT_ERROR);
        uint256 timestamp = _now();
        orders[orderId] = Order(
            _msgSender(),
            amountUSD,
            address(0),
            calculatePriceNative(amountUSD),
            timestamp,
            timestamp + expirationTimeSeconds,
            true,
            OrderStatus.EXISTS
        );
    }

    /**
     * @dev performs the execution of an order that is paid for by a ERC20 token
     * @param orderId id of order
     */

    function fulfillOrderERC20(bytes32 orderId) external {
        require(isOrderPresented(orderId), ORDER_NOT_EXISTS_ERROR);
        (
            address owner,
            uint256 amountUSD,
            address paymentToken,
            uint256 amountToken,
            ,
            uint256 expiresAt,
            bool isPaymentNative,
            OrderStatus status
        ) = getOrder(orderId);
        require(owner == _msgSender(), NOT_OWNER_ERROR);
        uint256 timestamp = _now();
        require(timestamp < expiresAt, ORDER_EXPIRED_ERROR);
        require(status == OrderStatus.EXISTS, ORDER_FULFILL_ERROR);
        require(!isPaymentNative, PAYMENT_NATIVE_ERROR);

        orders[orderId].status = OrderStatus.FULFILLED;

        IERC20Extented(paymentToken).transferFrom(owner, address(this), amountToken);
        emit OrderFulfilledERC20(owner, orderId, timestamp, amountUSD, paymentToken, amountToken);
    }

    /**
     * @dev performs the execution of an order that is paid for by a native token
     * @param orderId id of order
     */

    function fulfillOrderNative(bytes32 orderId) external payable {
        require(isOrderPresented(orderId), ORDER_NOT_EXISTS_ERROR);
        (address owner, uint256 amountUSD, , uint256 amountToken, , uint256 expiresAt, bool isPaymentNative, OrderStatus status) = getOrder(
            orderId
        );
        require(msg.value == amountToken, AMOUNT_ERROR);
        require(owner == _msgSender(), NOT_OWNER_ERROR);
        uint256 timestamp = _now();
        require(timestamp < expiresAt, ORDER_EXPIRED_ERROR);
        require(status == OrderStatus.EXISTS, ORDER_FULFILL_ERROR);
        require(isPaymentNative, PAYMENT_NOT_NATIVE_ERROR);

        orders[orderId].status = OrderStatus.FULFILLED;

        emit OrderFulfilledNative(owner, orderId, timestamp, amountUSD, amountToken);
    }

    /**
     * @dev gets a boolean value that is true if the order exists or has been fulfilled
     * @param orderId id of order
     */

    function isOrderPresented(bytes32 orderId) public view returns (bool) {
        return (orders[orderId].status == OrderStatus.EXISTS || orders[orderId].status == OrderStatus.FULFILLED);
    }

    /**
     * @dev gets a boolean value whether this token is available for order payment
     * @param paymentToken address of ERC20 token
     */

    function paymentTokenAvailable(address paymentToken) public view returns (bool) {
        return paymentTokenPriceOracleAddress[paymentToken] != address(0);
    }

    /**
     * @dev cancel not fulfilled order. Called only by ORDER_ADMIN
     * @param orderId id of order
     */

    function cancelOrder(bytes32 orderId) external {
        require(hasRole(ORDER_ADMIN_ROLE, _msgSender()), ORDER_ADMIN_ERROR);
        require(isOrderPresented(orderId), ORDER_NOT_EXISTS_ERROR);
        (, , , , , , , OrderStatus status) = getOrder(orderId);
        require(status != OrderStatus.FULFILLED, ORDER_FULFILL_ERROR);

        orders[orderId] = Order(address(0), 0, address(0), 0, 0, 0, false, OrderStatus.NOT_EXISTS);
    }

    /**
     * @dev get parameters of order
     * @param orderId id of order
     * @return owner the user who placed the order
     * @return amountUSD order price in usd
     * @return paymentToken the token that will be used to pay for the order
     * @return amountToken order price in payment token, this amount will be debited upon fulfill of the order
     * @return initializedAt the time the order was placed
     * @return expiresAt the time the order will expire
     * @return isPaymentNative payment will be in native tokens
     * @return status status of order
     */
    function getOrder(
        bytes32 orderId
    )
        public
        view
        returns (
            address owner,
            uint256 amountUSD,
            address paymentToken,
            uint256 amountToken,
            uint256 initializedAt,
            uint256 expiresAt,
            bool isPaymentNative,
            OrderStatus status
        )
    {
        Order memory _order = orders[orderId];
        owner = _order.owner;
        amountUSD = _order.amountUSD;
        paymentToken = _order.paymentToken;
        amountToken = _order.amountToken;
        initializedAt = _order.initializedAt;
        expiresAt = _order.expiresAt;
        isPaymentNative = _order.isPaymentNative;
        status = _order.status;
    }

    // Returns block.timestamp, overridable for test purposes.
    function _now() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}