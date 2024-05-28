/**
 *Submitted for verification at Arbiscan.io on 2024-05-28
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// lib/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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

// lib/openzeppelin-contracts/contracts/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

// lib/openzeppelin-contracts-upgradeable/contracts/access/IAccessControlUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// lib/openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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

// src/access/Roles.sol

/**
 * @dev Grants permission to:
 * - acts as a default admin for other roles,
 * - can whitelist an action with action manager,
 * - can manage asset group registry.
 *
 * Is granted to the deployer of the SpoolAccessControl contract.
 *
 * Equals to the DEFAULT_ADMIN_ROLE of the OpenZeppelin AccessControl.
 */
bytes32 constant ROLE_SPOOL_ADMIN = 0x00;

/**
 * @dev Grants permission to integrate a new smart vault into the Spool ecosystem.
 *
 * Should be granted to smart vault factory contracts.
 */
bytes32 constant ROLE_SMART_VAULT_INTEGRATOR = keccak256("SMART_VAULT_INTEGRATOR");

/**
 * @dev Grants permission to
 * - manage rewards on smart vaults,
 * - manage roles on smart vaults,
 * - redeem for another user of a smart vault.
 */
bytes32 constant ROLE_SMART_VAULT_ADMIN = keccak256("SMART_VAULT_ADMIN");

/**
 * @dev Grants permission to manage allowlists with AllowlistGuard for a smart vault.
 *
 * Should be granted to whoever is in charge of maintaining allowlists with AllowlistGuard for a smart vault.
 */
bytes32 constant ROLE_GUARD_ALLOWLIST_MANAGER = keccak256("GUARD_ALLOWLIST_MANAGER");

/**
 * @dev Grants permission to manage assets on master wallet.
 *
 * Should be granted to:
 * - the SmartVaultManager contract,
 * - the StrategyRegistry contract,
 * - the DepositManager contract,
 * - the WithdrawalManager contract.
 */
bytes32 constant ROLE_MASTER_WALLET_MANAGER = keccak256("MASTER_WALLET_MANAGER");

/**
 * @dev Marks a contract as a smart vault manager.
 *
 * Should be granted to:
 * - the SmartVaultManager contract,
 * - the DepositManager contract.
 */
bytes32 constant ROLE_SMART_VAULT_MANAGER = keccak256("SMART_VAULT_MANAGER");

/**
 * @dev Marks a contract as a strategy registry.
 *
 * Should be granted to the StrategyRegistry contract.
 */
bytes32 constant ROLE_STRATEGY_REGISTRY = keccak256("STRATEGY_REGISTRY");

/**
 * @dev Grants permission to act as a risk provider.
 *
 * Should be granted to whoever is allowed to provide risk scores.
 */
bytes32 constant ROLE_RISK_PROVIDER = keccak256("RISK_PROVIDER");

/**
 * @dev Grants permission to act as an allocation provider.
 *
 * Should be granted to contracts that are allowed to calculate allocations.
 */
bytes32 constant ROLE_ALLOCATION_PROVIDER = keccak256("ALLOCATION_PROVIDER");

/**
 * @dev Grants permission to pause the system.
 */
bytes32 constant ROLE_PAUSER = keccak256("SYSTEM_PAUSER");

/**
 * @dev Grants permission to unpause the system.
 */
bytes32 constant ROLE_UNPAUSER = keccak256("SYSTEM_UNPAUSER");

/**
 * @dev Grants permission to manage rewards payment pool.
 */
bytes32 constant ROLE_REWARD_POOL_ADMIN = keccak256("REWARD_POOL_ADMIN");

/**
 * @dev Grants permission to reallocate smart vaults.
 */
bytes32 constant ROLE_REALLOCATOR = keccak256("REALLOCATOR");

/**
 * @dev Grants permission to be used as a strategy.
 */
bytes32 constant ROLE_STRATEGY = keccak256("STRATEGY");

/**
 * @dev Grants permission to manually set strategy apy.
 */
bytes32 constant ROLE_STRATEGY_APY_SETTER = keccak256("STRATEGY_APY_SETTER");

/**
 * @dev Grants permission to manage role ROLE_STRATEGY.
 */
bytes32 constant ADMIN_ROLE_STRATEGY = keccak256("ADMIN_STRATEGY");

/**
 * @dev Grants permission vault admins to allow redeem on behalf of other users.
 */
bytes32 constant ROLE_SMART_VAULT_ALLOW_REDEEM = keccak256("SMART_VAULT_ALLOW_REDEEM");

/**
 * @dev Grants permission to manage role ROLE_SMART_VAULT_ALLOW_REDEEM.
 */
bytes32 constant ADMIN_ROLE_SMART_VAULT_ALLOW_REDEEM = keccak256("ADMIN_SMART_VAULT_ALLOW_REDEEM");

/**
 * @dev Grants permission to run do hard work.
 */
bytes32 constant ROLE_DO_HARD_WORKER = keccak256("DO_HARD_WORKER");

/**
 * @dev Grants permission to immediately withdraw assets in case of emergency.
 */
bytes32 constant ROLE_EMERGENCY_WITHDRAWAL_EXECUTOR = keccak256("EMERGENCY_WITHDRAWAL_EXECUTOR");

/**
 * @dev Grants permission to swap with swapper.
 *
 * Should be granted to the DepositSwap contract.
 */
bytes32 constant ROLE_SWAPPER = keccak256("SWAPPER");

// src/external/interfaces/strategies/arbitrum/compound/v3/IComet.sol

library CometStructs {
    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
        uint8 _reserved;
    }

    struct TotalsBasic {
        uint64 baseSupplyIndex;
        uint64 baseBorrowIndex;
        uint64 trackingSupplyIndex;
        uint64 trackingBorrowIndex;
        uint104 totalSupplyBase;
        uint104 totalBorrowBase;
        uint40 lastAccrualTime;
        uint8 pauseFlags;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    struct RewardOwed {
        address token;
        uint256 owed;
    }

    struct TotalsCollateral {
        uint128 totalSupplyAsset;
        uint128 _reserved;
    }
}

interface IComet {
    function accrueAccount(address) external;
    function balanceOf(address) external view returns (uint256);
    function baseScale() external view returns (uint256);
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;

    function getSupplyRate(uint256 utilization) external view returns (uint256);
    function getBorrowRate(uint256 utilization) external view returns (uint256);

    function getAssetInfoByAddress(address asset) external view returns (CometStructs.AssetInfo memory);
    function getAssetInfo(uint8 i) external view returns (CometStructs.AssetInfo memory);

    function getCollateralReserves(address asset) external view returns (uint256);

    function getPrice(address priceFeed) external view returns (uint128);

    function userBasic(address) external view returns (CometStructs.UserBasic memory);
    function totalsBasic() external view returns (CometStructs.TotalsBasic memory);
    function userCollateral(address, address) external view returns (CometStructs.UserCollateral memory);

    function baseTokenPriceFeed() external view returns (address);

    function numAssets() external view returns (uint8);

    function getUtilization() external view returns (uint256);

    function baseTrackingSupplySpeed() external view returns (uint256);
    function baseTrackingBorrowSpeed() external view returns (uint256);

    function totalSupply() external view returns (uint256);
    function totalBorrow() external view returns (uint256);

    function baseIndexScale() external pure returns (uint64);

    function totalsCollateral(address asset) external view returns (CometStructs.TotalsCollateral memory);

    function baseMinForRewards() external view returns (uint256);
    function baseToken() external view returns (address);
}

// src/interfaces/CommonErrors.sol

/**
 * @notice Used when an array has invalid length.
 */
error InvalidArrayLength();

/**
 * @notice Used when group of smart vaults or strategies do not have same asset group.
 */
error NotSameAssetGroup();

/**
 * @notice Used when configuring an address with a zero address.
 */
error ConfigurationAddressZero();

/**
 * @notice Used when constructor or intializer parameters are invalid.
 */
error InvalidConfiguration();

/**
 * @notice Used when fetched exchange rate is out of slippage range.
 */
error ExchangeRateOutOfSlippages();

/**
 * @notice Used when an invalid strategy is provided.
 * @param address_ Address of the invalid strategy.
 */
error InvalidStrategy(address address_);

/**
 * @notice Used when doing low-level call on an address that is not a contract.
 * @param address_ Address of the contract
 */
error AddressNotContract(address address_);

/**
 * @notice Used when invoking an only view execution and tx.origin is not address zero.
 * @param address_ Address of the tx.origin
 */
error OnlyViewExecution(address address_);

// src/interfaces/Constants.sol

/// @dev Number of seconds in an average year.
uint256 constant SECONDS_IN_YEAR = 31_556_926;

/// @dev Number of seconds in an average year.
int256 constant SECONDS_IN_YEAR_INT = 31_556_926;

/// @dev Represents 100%.
uint256 constant FULL_PERCENT = 100_00;

/// @dev Represents 100%.
int256 constant FULL_PERCENT_INT = 100_00;

/// @dev Represents 100% for yield.
int256 constant YIELD_FULL_PERCENT_INT = 10 ** 12;

/// @dev Represents 100% for yield.
uint256 constant YIELD_FULL_PERCENT = uint256(YIELD_FULL_PERCENT_INT);

/// @dev Maximal management fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant MANAGEMENT_FEE_MAX = 5_00;

/// @dev Maximal deposit fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant DEPOSIT_FEE_MAX = 5_00;

/// @dev Maximal smart vault performance fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant SV_PERFORMANCE_FEE_MAX = 20_00;

/// @dev Maximal ecosystem fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant ECOSYSTEM_FEE_MAX = 20_00;

/// @dev Maximal treasury fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant TREASURY_FEE_MAX = 10_00;

/// @dev Maximal risk score a strategy can be assigned.
uint8 constant MAX_RISK_SCORE = 10_0;

/// @dev Minimal risk score a strategy can be assigned.
uint8 constant MIN_RISK_SCORE = 1;

/// @dev Maximal value for risk tolerance a smart vautl can have.
int8 constant MAX_RISK_TOLERANCE = 10;

/// @dev Minimal value for risk tolerance a smart vault can have.
int8 constant MIN_RISK_TOLERANCE = -10;

/// @dev If set as risk provider, system will return fixed risk score values
address constant STATIC_RISK_PROVIDER = address(0xaaa);

/// @dev Fixed values to use if risk provider is set to STATIC_RISK_PROVIDER
uint8 constant STATIC_RISK_SCORE = 1;

/// @dev Maximal value of deposit NFT ID.
uint256 constant MAXIMAL_DEPOSIT_ID = 2 ** 255;

/// @dev Maximal value of withdrawal NFT ID.
uint256 constant MAXIMAL_WITHDRAWAL_ID = 2 ** 256 - 1;

/// @dev How many shares will be minted with a NFT
uint256 constant NFT_MINTED_SHARES = 10 ** 6;

/// @dev Each smart vault can have up to STRATEGY_COUNT_CAP strategies.
uint256 constant STRATEGY_COUNT_CAP = 16;

/// @dev Maximal DHW base yield. Expressed in terms of FULL_PERCENT.
uint256 constant MAX_DHW_BASE_YIELD_LIMIT = 10_00;

/// @dev Smart vault and strategy share multiplier at first deposit.
uint256 constant INITIAL_SHARE_MULTIPLIER = 1000;

/// @dev Strategy initial locked shares. These shares will never be unlocked.
uint256 constant INITIAL_LOCKED_SHARES = 10 ** 12;

/// @dev Strategy initial locked shares address.
address constant INITIAL_LOCKED_SHARES_ADDRESS = address(0xdead);

/// @dev Maximum number of guards a smart vault can be configured with
uint256 constant MAX_GUARD_COUNT = 10;

/// @dev Maximum number of actions a smart vault can be configured with
uint256 constant MAX_ACTION_COUNT = 10;

/// @dev ID of null asset group. Should not be used by any strategy or smart vault.
uint256 constant NULL_ASSET_GROUP_ID = 0;

// src/interfaces/ISwapper.sol

/* ========== STRUCTS ========== */

/**
 * @notice Information needed to make a swap of assets.
 * @custom:member swapTarget Contract executing the swap.
 * @custom:member token Token to be swapped.
 * @custom:member swapCallData Calldata describing the swap itself.
 */
struct SwapInfo {
    address swapTarget;
    address token;
    bytes swapCallData;
}

/* ========== ERRORS ========== */

/**
 * @notice Used when trying to do a swap via an exchange that is not allowed to execute a swap.
 * @param exchange Exchange used.
 */
error ExchangeNotAllowed(address exchange);

/**
 * @notice Used when trying to execute a swap but are not authorized.
 * @param caller Caller of the swap method.
 */
error NotSwapper(address caller);

/* ========== INTERFACES ========== */

interface ISwapper {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when the exchange allowlist is updated.
     * @param exchange Exchange that was updated.
     * @param isAllowed Whether the exchange is allowed to be used in a swap or not after the update.
     */
    event ExchangeAllowlistUpdated(address indexed exchange, bool isAllowed);

    event Swapped(
        address indexed receiver, address[] tokensIn, address[] tokensOut, uint256[] amountsIn, uint256[] amountsOut
    );

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Performs a swap of tokens with external contracts.
     * - deposit tokens into the swapper contract
     * - swapper will swap tokens based on swap info provided
     * - swapper will return unswapped tokens to the receiver
     * @param tokensIn Addresses of tokens available for the swap.
     * @param swapInfo Information needed to perform the swap.
     * @param tokensOut Addresses of tokens to swap to.
     * @param receiver Receiver of unswapped tokens.
     * @return amountsOut Amounts of `tokensOut` sent from the swapper to the receiver.
     */
    function swap(
        address[] calldata tokensIn,
        SwapInfo[] calldata swapInfo,
        address[] calldata tokensOut,
        address receiver
    ) external returns (uint256[] memory amountsOut);

    /**
     * @notice Updates list of exchanges that can be used in a swap.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SPOOL_ADMIN
     *   - exchanges and allowed arrays need to be of same length
     * @param exchanges Addresses of exchanges.
     * @param allowed Whether an exchange is allowed to be used in a swap.
     */
    function updateExchangeAllowlist(address[] calldata exchanges, bool[] calldata allowed) external;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Checks if an exchange is allowed to be used in a swap.
     * @param exchange Exchange to check.
     * @return isAllowed True if the exchange is allowed to be used in a swap, false otherwise.
     */
    function isExchangeAllowed(address exchange) external view returns (bool isAllowed);
}

// src/interfaces/IUsdPriceFeedManager.sol

/// @dev Number of decimals used for USD values.
uint256 constant USD_DECIMALS = 18;

/**
 * @notice Emitted when asset is invalid.
 * @param asset Invalid asset.
 */
error InvalidAsset(address asset);

/**
 * @notice Emitted when price returned by price aggregator is negative or zero.
 * @param price Actual price returned by price aggregator.
 */
error NonPositivePrice(int256 price);

/**
 * @notice Emitted when pricing data returned by price aggregator is not from the current
 * round or the round hasn't finished.
 */
error StalePriceData();

interface IUsdPriceFeedManager {
    /**
     * @notice Gets number of decimals for an asset.
     * @param asset Address of the asset.
     * @return assetDecimals Number of decimals for the asset.
     */
    function assetDecimals(address asset) external view returns (uint256 assetDecimals);

    /**
     * @notice Gets number of decimals for USD.
     * @return usdDecimals Number of decimals for USD.
     */
    function usdDecimals() external view returns (uint256 usdDecimals);

    /**
     * @notice Calculates asset value in USD using current price.
     * @param asset Address of asset.
     * @param assetAmount Amount of asset in asset decimals.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsd(address asset, uint256 assetAmount) external view returns (uint256 usdValue);

    /**
     * @notice Calculates USD value in asset using current price.
     * @param asset Address of asset.
     * @param usdAmount Amount of USD in USD decimals.
     * @return assetValue Value in asset in asset decimals.
     */
    function usdToAsset(address asset, uint256 usdAmount) external view returns (uint256 assetValue);

    /**
     * @notice Calculates asset value in USD using provided price.
     * @param asset Address of asset.
     * @param assetAmount Amount of asset in asset decimals.
     * @param price Price of asset in USD.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsdCustomPrice(address asset, uint256 assetAmount, uint256 price)
        external
        view
        returns (uint256 usdValue);

    /**
     * @notice Calculates assets value in USD using provided prices.
     * @param assets Addresses of assets.
     * @param assetAmounts Amounts of assets in asset decimals.
     * @param prices Prices of asset in USD.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsdCustomPriceBulk(
        address[] calldata assets,
        uint256[] calldata assetAmounts,
        uint256[] calldata prices
    ) external view returns (uint256 usdValue);

    /**
     * @notice Calculates USD value in asset using provided price.
     * @param asset Address of asset.
     * @param usdAmount Amount of USD in USD decimals.
     * @param price Price of asset in USD.
     * @return assetValue Value in asset in asset decimals.
     */
    function usdToAssetCustomPrice(address asset, uint256 usdAmount, uint256 price)
        external
        view
        returns (uint256 assetValue);
}

// src/libraries/uint16a16Lib.sol

type uint16a16 is uint256;

/**
 * @notice This library enables packing of sixteen uint16 elements into one uint256 word.
 */
library uint16a16Lib {
    /// @notice Number of bits per stored element.
    uint256 constant bits = 16;

    /// @notice Maximal number of elements stored.
    uint256 constant elements = 16;

    // must ensure that bits * elements <= 256

    /// @notice Range covered by stored element.
    uint256 constant range = 1 << bits;

    /// @notice Maximal value of stored element.
    uint256 constant max = range - 1;

    /**
     * @notice Gets element from packed array.
     * @param va Packed array.
     * @param index Index of element to get.
     * @return element Element of va stored in index index.
     */
    function get(uint16a16 va, uint256 index) internal pure returns (uint256) {
        require(index < elements);
        return (uint16a16.unwrap(va) >> (bits * index)) & max;
    }

    /**
     * @notice Sets element to packed array.
     * @param va Packed array.
     * @param index Index under which to store the element
     * @param ev Element to store.
     * @return va Packed array with stored element.
     */
    function set(uint16a16 va, uint256 index, uint256 ev) internal pure returns (uint16a16) {
        require(index < elements);
        require(ev < range);
        index *= bits;
        return uint16a16.wrap((uint16a16.unwrap(va) & ~(max << index)) | (ev << index));
    }

    /**
     * @notice Sets elements to packed array.
     * Elements are stored continuously from index 0 onwards.
     * @param va Packed array.
     * @param ev Elements to store.
     * @return va Packed array with stored elements.
     */
    function set(uint16a16 va, uint256[] memory ev) internal pure returns (uint16a16) {
        for (uint256 i; i < ev.length; ++i) {
            va = set(va, i, ev[i]);
        }

        return va;
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// src/external/interfaces/strategies/arbitrum/compound/v3/IRewards.sol

interface IRewards {
    function getRewardOwed(address comet, address account) external returns (CometStructs.RewardOwed memory);
    function claim(address comet, address src, bool shouldAccrue) external;
}

// src/interfaces/IAssetGroupRegistry.sol

/* ========== ERRORS ========== */

/**
 * @notice Used when invalid ID for asset group is provided.
 * @param assetGroupId Invalid ID for asset group.
 */
error InvalidAssetGroup(uint256 assetGroupId);

/**
 * @notice Used when no assets are provided for an asset group.
 */
error NoAssetsProvided();

/**
 * @notice Used when token is not allowed to be used as an asset.
 * @param token Address of the token that is not allowed.
 */
error TokenNotAllowed(address token);

/**
 * @notice Used when asset group already exists.
 * @param assetGroupId ID of the already existing asset group.
 */
error AssetGroupAlreadyExists(uint256 assetGroupId);

/**
 * @notice Used when given array is unsorted.
 */
error UnsortedArray();

/* ========== INTERFACES ========== */

interface IAssetGroupRegistry {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when token is allowed to be used as an asset.
     * @param token Address of newly allowed token.
     */
    event TokenAllowed(address indexed token);

    /**
     * @notice Emitted when asset group is registered.
     * @param assetGroupId ID of the newly registered asset group.
     */
    event AssetGroupRegistered(uint256 indexed assetGroupId);

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Checks if token is allowed to be used as an asset.
     * @param token Address of token to check.
     * @return isAllowed True if token is allowed, false otherwise.
     */
    function isTokenAllowed(address token) external view returns (bool isAllowed);

    /**
     * @notice Gets number of registered asset groups.
     * @return count Number of registered asset groups.
     */
    function numberOfAssetGroups() external view returns (uint256 count);

    /**
     * @notice Gets asset group by its ID.
     * @dev Requirements:
     * - must provide a valid ID for the asset group
     * @return assets Array of assets in the asset group.
     */
    function listAssetGroup(uint256 assetGroupId) external view returns (address[] memory assets);

    /**
     * @notice Gets asset group length.
     * @dev Requirements:
     * - must provide a valid ID for the asset group
     * @return length
     */
    function assetGroupLength(uint256 assetGroupId) external view returns (uint256 length);

    /**
     * @notice Validates that provided ID represents an asset group.
     * @dev Function reverts when ID does not represent an asset group.
     * @param assetGroupId ID to validate.
     */
    function validateAssetGroup(uint256 assetGroupId) external view;

    /**
     * @notice Checks if asset group composed of assets already exists.
     * Will revert if provided assets cannot form an asset group.
     * @param assets Assets composing the asset group.
     * @return Asset group ID if such asset group exists, 0 otherwise.
     */
    function checkAssetGroupExists(address[] calldata assets) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Allows a token to be used as an asset.
     * @dev Requirements:
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param token Address of token to be allowed.
     */
    function allowToken(address token) external;

    /**
     * @notice Allows tokens to be used as assets.
     * @dev Requirements:
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param tokens Addresses of tokens to be allowed.
     */
    function allowTokenBatch(address[] calldata tokens) external;

    /**
     * @notice Registers a new asset group.
     * @dev Requirements:
     * - must provide at least one asset
     * - all assets must be allowed
     * - assets must be sorted
     * - such asset group should not exist yet
     * - can only be called by the ROLE_SPOOL_ADMIN
     * @param assets Array of assets in the asset group.
     * @return id Sequential ID assigned to the asset group.
     */
    function registerAssetGroup(address[] calldata assets) external returns (uint256 id);
}

// src/interfaces/IMasterWallet.sol

interface IMasterWallet {
    /**
     * @notice Transfers amount of token to the recipient.
     * @dev Requirements:
     * - caller must have role ROLE_MASTER_WALLET_MANAGER
     * @param token Token to transfer.
     * @param recipient Target of the transfer.
     * @param amount Amount to transfer.
     */
    function transfer(IERC20 token, address recipient, uint256 amount) external;
}

// src/interfaces/ISpoolAccessControl.sol

/**
 * @notice Used when an account is missing a required role.
 * @param role Required role.
 * @param account Account missing the required role.
 */
error MissingRole(bytes32 role, address account);

/**
 * @notice Used when interacting with Spool when the system is paused.
 */
error SystemPaused();

/**
 * @notice Used when setting smart vault owner
 */
error SmartVaultOwnerAlreadySet(address smartVault);

/**
 * @notice Used when a contract tries to enter in a non-reentrant state.
 */
error ReentrantCall();

/**
 * @notice Used when a contract tries to call in a non-reentrant function and doesn't have the correct role.
 */
error NoReentrantRole();

interface ISpoolAccessControl is IAccessControlUpgradeable {
    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets owner of a smart vault.
     * @param smartVault Smart vault.
     * @return owner Owner of the smart vault.
     */
    function smartVaultOwner(address smartVault) external view returns (address owner);

    /**
     * @notice Looks if an account has a role for a smart vault.
     * @param smartVault Address of the smart vault.
     * @param role Role to look for.
     * @param account Account to check.
     * @return hasRole True if account has the role for the smart vault, false otherwise.
     */
    function hasSmartVaultRole(address smartVault, bytes32 role, address account)
        external
        view
        returns (bool hasRole);

    /**
     * @notice Checks if an account is either Spool admin or admin for a smart vault.
     * @dev The function reverts if account is neither.
     * @param smartVault Address of the smart vault.
     * @param account to check.
     */
    function checkIsAdminOrVaultAdmin(address smartVault, address account) external view;

    /**
     * @notice Checks if system is paused or not.
     * @return isPaused True if system is paused, false otherwise.
     */
    function paused() external view returns (bool isPaused);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Pauses the whole system.
     * @dev Requirements:
     * - caller must have role ROLE_PAUSER
     */
    function pause() external;

    /**
     * @notice Unpauses the whole system.
     * @dev Requirements:
     * - caller must have role ROLE_UNPAUSER
     */
    function unpause() external;

    /**
     * @notice Grants role to an account for a smart vault.
     * @dev Requirements:
     * - caller must have either role ROLE_SPOOL_ADMIN or role ROLE_SMART_VAULT_ADMIN for the smart vault
     * @param smartVault Address of the smart vault.
     * @param role Role to grant.
     * @param account Account to grant the role to.
     */
    function grantSmartVaultRole(address smartVault, bytes32 role, address account) external;

    /**
     * @notice Revokes role from an account for a smart vault.
     * @dev Requirements:
     * - caller must have either role ROLE_SPOOL_ADMIN or role ROLE_SMART_VAULT_ADMIN for the smart vault
     * @param smartVault Address of the smart vault.
     * @param role Role to revoke.
     * @param account Account to revoke the role from.
     */
    function revokeSmartVaultRole(address smartVault, bytes32 role, address account) external;

    /**
     * @notice Renounce role for a smart vault.
     * @param smartVault Address of the smart vault.
     * @param role Role to renounce.
     */
    function renounceSmartVaultRole(address smartVault, bytes32 role) external;

    /**
     * @notice Grant ownership to smart vault and assigns admin role.
     * @dev Ownership can only be granted once and it should be done at vault creation time.
     * @param smartVault Address of the smart vault.
     * @param owner address to which grant ownership to
     */
    function grantSmartVaultOwnership(address smartVault, address owner) external;

    /**
     * @notice Checks and reverts if a system has already entered in the non-reentrant state.
     */
    function checkNonReentrant() external view;

    /**
     * @notice Sets the entered flag to true when entering for the first time.
     * @dev Reverts if a system has already entered before.
     */
    function nonReentrantBefore() external;

    /**
     * @notice Resets the entered flag after the call is finished.
     */
    function nonReentrantAfter() external;

    /**
     * @notice Emitted when ownership of a smart vault is granted to an address
     * @param smartVault Smart vault address
     * @param address_ Address of the new smart vault owner
     */
    event SmartVaultOwnershipGranted(address indexed smartVault, address indexed address_);

    /**
     * @notice Smart vault specific role was granted
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account to which the role was granted
     */
    event SmartVaultRoleGranted(address indexed smartVault, bytes32 indexed role, address indexed account);

    /**
     * @notice Smart vault specific role was revoked
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account for which the role was revoked
     */
    event SmartVaultRoleRevoked(address indexed smartVault, bytes32 indexed role, address indexed account);

    /**
     * @notice Smart vault specific role was renounced
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account that renounced the role
     */
    event SmartVaultRoleRenounced(address indexed smartVault, bytes32 indexed role, address indexed account);
}

// lib/openzeppelin-contracts-upgradeable/contracts/utils/ContextUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// src/access/SpoolAccessControllable.sol

/**
 * @notice Account access role verification middleware
 */
abstract contract SpoolAccessControllable {
    /* ========== CONSTANTS ========== */

    /**
     * @dev Spool access control manager.
     */
    ISpoolAccessControl internal immutable _accessControl;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param accessControl_ Spool access control manager.
     */
    constructor(ISpoolAccessControl accessControl_) {
        if (address(accessControl_) == address(0)) revert ConfigurationAddressZero();

        _accessControl = accessControl_;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Reverts if an account is missing a role.\
     * @param role Role to check for.
     * @param account Account to check.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_accessControl.hasRole(role, account)) {
            revert MissingRole(role, account);
        }
    }

    /**
     * @dev Revert if an account is missing a role for a smartVault.
     * @param smartVault Address of the smart vault.
     * @param role Role to check for.
     * @param account Account to check.
     */
    function _checkSmartVaultRole(address smartVault, bytes32 role, address account) internal view {
        if (!_accessControl.hasSmartVaultRole(smartVault, role, account)) {
            revert MissingRole(role, account);
        }
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (_accessControl.paused()) {
            revert SystemPaused();
        }
    }

    function _checkNonReentrant() internal view {
        _accessControl.checkNonReentrant();
    }

    function _nonReentrantBefore() internal {
        _accessControl.nonReentrantBefore();
    }

    function _nonReentrantAfter() internal {
        _accessControl.nonReentrantAfter();
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Only allows accounts with granted role.
     * @dev Reverts when the account fails check.
     * @param role Role to check for.
     * @param account Account to check.
     */
    modifier onlyRole(bytes32 role, address account) {
        _checkRole(role, account);
        _;
    }

    /**
     * @notice Only allows accounts with granted role for a smart vault.
     * @dev Reverts when the account fails check.
     * @param smartVault Address of the smart vault.
     * @param role Role to check for.
     * @param account Account to check.
     */
    modifier onlySmartVaultRole(address smartVault, bytes32 role, address account) {
        _checkSmartVaultRole(smartVault, role, account);
        _;
    }

    /**
     * @notice Only allows accounts that are Spool admins or admins of a smart vault.
     * @dev Reverts when the account fails check.
     * @param smartVault Address of the smart vault.
     * @param account Account to check.
     */
    modifier onlyAdminOrVaultAdmin(address smartVault, address account) {
        _accessControl.checkIsAdminOrVaultAdmin(smartVault, account);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, or other contracts using this modifier.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev Check if a system has already entered in the non-reentrant state.
     */
    modifier checkNonReentrant() {
        _checkNonReentrant();
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// src/interfaces/IStrategy.sol

/**
 * @notice Struct holding information how to swap the assets.
 * @custom:member slippage minumum output amount
 * @custom:member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path
}

/**
 * @notice Parameters for calling do hard work on strategy.
 * @custom:member swapInfo Information for swapping assets before depositing into the protocol.
 * @custom:member swapInfo Information for swapping rewards before depositing them back into the protocol.
 * @custom:member slippages Slippages used to constrain depositing and withdrawing from the protocol.
 * @custom:member assetGroup Asset group of the strategy.
 * @custom:member exchangeRates Exchange rates for assets.
 * @custom:member withdrawnShares Strategy shares withdrawn by smart vault.
 * @custom:member masterWallet Master wallet.
 * @custom:member priceFeedManager Price feed manager.
 * @custom:member baseYield Base yield value, manual input for specific strategies.
 * @custom:member platformFees Platform fees info.
 */
struct StrategyDhwParameterBag {
    SwapInfo[] swapInfo;
    SwapInfo[] compoundSwapInfo;
    uint256[] slippages;
    address[] assetGroup;
    uint256[] exchangeRates;
    uint256 withdrawnShares;
    address masterWallet;
    IUsdPriceFeedManager priceFeedManager;
    int256 baseYield;
    PlatformFees platformFees;
}

/**
 * @notice Information about results of the do hard work.
 * @custom:member sharesMinted Amount of strategy shares minted.
 * @custom:member assetsWithdrawn Amount of assets withdrawn.
 * @custom:member yieldPercentage Yield percentage from the previous DHW.
 * @custom:member valueAtDhw Value of the strategy at the end of DHW.
 * @custom:member totalSstsAtDhw Total SSTs at the end of DHW.
 */
struct DhwInfo {
    uint256 sharesMinted;
    uint256[] assetsWithdrawn;
    int256 yieldPercentage;
    uint256 valueAtDhw;
    uint256 totalSstsAtDhw;
}

/**
 * @notice Used when ghost strategy is called.
 */
error IsGhostStrategy();

/**
 * @notice Used when user is not allowed to redeem fast.
 * @param user User that tried to redeem fast.
 */
error NotFastRedeemer(address user);

/**
 * @notice Used when asset group ID is not correctly initialized.
 */
error InvalidAssetGroupIdInitialization();

interface IStrategy is IERC20Upgradeable {
    /* ========== EVENTS ========== */

    event Deposited(
        uint256 mintedShares, uint256 usdWorthDeposited, uint256[] assetsBeforeSwap, uint256[] assetsDeposited
    );

    event Withdrawn(uint256 withdrawnShares, uint256 usdWorthWithdrawn, uint256[] withdrawnAssets);

    event PlatformFeesCollected(address indexed strategy, uint256 sharesMinted);

    event Slippages(bool isDeposit, uint256 slippage, bytes data);

    event BeforeDepositCheckSlippages(uint256[] amounts);

    event BeforeRedeemalCheckSlippages(uint256 ssts);

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets strategy name.
     * @return name Name of the strategy.
     */
    function strategyName() external view returns (string memory name);

    /**
     * @notice Gets required ratio between underlying assets.
     * @return ratio Required asset ratio for the strategy.
     */
    function assetRatio() external view returns (uint256[] memory ratio);

    /**
     * @notice Gets asset group used by the strategy.
     * @return id ID of the asset group.
     */
    function assetGroupId() external view returns (uint256 id);

    /**
     * @notice Gets underlying assets for the strategy.
     * @return assets Addresses of the underlying assets.
     */
    function assets() external view returns (address[] memory assets);

    /**
     * @notice Gets underlying asset amounts for the strategy.
     * @return amounts Amounts of the underlying assets.
     */
    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Performs slippages check before depositing.
     * @param amounts Amounts to be deposited.
     * @param slippages Slippages to check against.
     */
    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) external;

    /**
     * @dev Performs slippages check before redeemal.
     * @param ssts Amount of strategy tokens to be redeemed.
     * @param slippages Slippages to check against.
     */
    function beforeRedeemalCheck(uint256 ssts, uint256[] calldata slippages) external;

    /**
     * @notice Does hard work:
     * - compounds rewards
     * - deposits into the protocol
     * - withdraws from the protocol
     * @dev Requirements:
     * - caller must have role ROLE_STRATEGY_REGISTRY
     * @param dhwParams Parameters for the do hard work.
     * @return info Information about do the performed hard work.
     */
    function doHardWork(StrategyDhwParameterBag calldata dhwParams) external returns (DhwInfo memory info);

    /**
     * @notice Claims strategy shares after do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault claiming shares.
     * @param amount Amount of strategy shares to claim.
     */
    function claimShares(address smartVault, uint256 amount) external;

    /**
     * @notice Releases shares back to strategy.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault releasing shares.
     * @param amount Amount of strategy shares to release.
     */
    function releaseShares(address smartVault, uint256 amount) external;

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @dev Requirements:
     * - caller must have either role ROLE_SMART_VAULT_MANAGER or role ROLE_STRATEGY_REGISTRY
     * @param shares Amount of shares to redeem.
     * @param masterWallet Address of the master wallet.
     * @param assetGroup Asset group of the strategy.
     * @param slippages Slippages to guard redeeming.
     * @return assetsWithdrawn Amount of assets withdrawn.
     */
    function redeemFast(
        uint256 shares,
        address masterWallet,
        address[] calldata assetGroup,
        uint256[] calldata slippages
    ) external returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @param shares Amount of shares to redeem.
     * @param redeemer Address of he redeemer, owner of SSTs.
     * @param assetGroup Asset group of the strategy.
     * @param slippages Slippages to guard redeeming.
     * @return assetsWithdrawn Amount of assets withdrawn.
     */
    function redeemShares(uint256 shares, address redeemer, address[] calldata assetGroup, uint256[] calldata slippages)
        external
        returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Instantly deposits into the protocol.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param assetGroup Asset group of the strategy.
     * @param exchangeRates Asset to USD exchange rates.
     * @param priceFeedManager Price feed manager contract.
     * @param slippages Slippages to guard depositing.
     * @param swapInfo Information for swapping assets before depositing into the protocol.
     * @return sstsMinted Amount of SSTs minted.
     */
    function depositFast(
        address[] calldata assetGroup,
        uint256[] calldata exchangeRates,
        IUsdPriceFeedManager priceFeedManager,
        uint256[] calldata slippages,
        SwapInfo[] calldata swapInfo
    ) external returns (uint256 sstsMinted);

    /**
     * @notice Instantly withdraws assets, bypassing shares mechanism.
     * Transfers withdrawn assets to the emergency withdrawal wallet.
     * @dev Requirements:
     * - caller must have role ROLE_STRATEGY_REGISTRY
     * @param slippages Slippages to guard redeeming.
     * @param recipient Recipient address
     */
    function emergencyWithdraw(uint256[] calldata slippages, address recipient) external;

    /**
     * @notice Gets USD worth of the strategy.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param exchangeRates Asset to USD exchange rates.
     * @param priceFeedManager Price feed manager contract.
     */
    function getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        external
        returns (uint256 usdWorth);

    /**
     * @notice Gets protocol rewards.
     * @dev Requirements:
     * - can only be called in view-execution mode.
     * @return tokens Addresses of reward tokens.
     * @return amounts Amount of reward tokens available.
     */
    function getProtocolRewards() external returns (address[] memory tokens, uint256[] memory amounts);
}

// src/interfaces/IStrategyRegistry.sol

/* ========== ERRORS ========== */

/**
 * @notice Used when trying to register an already registered strategy.
 * @param address_ Address of already registered strategy.
 */
error StrategyAlreadyRegistered(address address_);

/**
 * @notice Used when DHW was not run yet for a strategy index.
 * @param strategy Address of the strategy.
 * @param strategyIndex Index of the strategy.
 */
error DhwNotRunYetForIndex(address strategy, uint256 strategyIndex);

/**
 * @notice Used when provided token list is invalid.
 */
error InvalidTokenList();

/**
 * @notice Used when ghost strategy is used.
 */
error GhostStrategyUsed();

/**
 * @notice Used when syncing vault that is already fully synced.
 */
error NothingToSync();

/**
 * @notice Used when system tries to configure a too large ecosystem fee.
 * @param ecosystemFeePct Requested ecosystem fee.
 */
error EcosystemFeeTooLarge(uint256 ecosystemFeePct);

/**
 * @notice Used when system tries to configure a too large treasury fee.
 * @param treasuryFeePct Requested treasury fee.
 */
error TreasuryFeeTooLarge(uint256 treasuryFeePct);

/**
 * @notice Used when user tries to re-add a strategy that was previously removed from the system.
 * @param strategy Strategy address
 */
error StrategyPreviouslyRemoved(address strategy);

/**
 * @notice Represents change of state for a strategy during a DHW.
 * @custom:member exchangeRates Exchange rates between assets and USD.
 * @custom:member assetsDeposited Amount of assets deposited into the strategy.
 * @custom:member sharesMinted Amount of strategy shares minted.
 * @custom:member totalSSTs Amount of strategy shares at the end of the DHW.
 * @custom:member totalStrategyValue Total strategy value at the end of the DHW.
 * @custom:member dhwYields DHW yield percentage from the previous DHW.
 */
struct StrategyAtIndex {
    uint256[] exchangeRates;
    uint256[] assetsDeposited;
    uint256 sharesMinted;
    uint256 totalSSTs;
    uint256 totalStrategyValue;
    int256 dhwYields;
}

/**
 * @notice Parameters for calling do hard work.
 * @custom:member strategies Strategies to do-hard-worked upon, grouped by their asset group.
 * @custom:member swapInfo Information for swapping assets before depositing into protocol. SwapInfo[] per each strategy.
 * @custom:member compoundSwapInfo Information for swapping rewards before depositing them back into the protocol. SwapInfo[] per each strategy.
 * @custom:member strategySlippages Slippages used to constrain depositing into and withdrawing from the protocol. uint256[] per strategy.
 * @custom:member baseYields Base yield percentage the strategy created in the DHW period (applicable only for some strategies).
 * @custom:member tokens List of all asset tokens involved in the do hard work.
 * @custom:member exchangeRateSlippages Slippages used to constrain exchange rates for asset tokens. uint256[2] for each token.
 * @custom:member validUntil Sets the maximum timestamp the user is willing to wait to start executing 'do hard work'.
 */
struct DoHardWorkParameterBag {
    address[][] strategies;
    SwapInfo[][][] swapInfo;
    SwapInfo[][][] compoundSwapInfo;
    uint256[][][] strategySlippages;
    int256[][] baseYields;
    address[] tokens;
    uint256[2][] exchangeRateSlippages;
    uint256 validUntil;
}

/**
 * @notice Parameters for calling redeem fast.
 * @custom:member strategies Addresses of strategies.
 * @custom:member strategyShares Amount of shares to redeem.
 * @custom:member assetGroup Asset group of the smart vault.
 * @custom:member slippages Slippages to guard withdrawal.
 */
struct RedeemFastParameterBag {
    address[] strategies;
    uint256[] strategyShares;
    address[] assetGroup;
    uint256[][] withdrawalSlippages;
}

/**
 * @notice Group of platform fees.
 * @custom:member ecosystemFeeReciever Receiver of the ecosystem fees.
 * @custom:member ecosystemFeePct Ecosystem fees. Expressed in FULL_PERCENT.
 * @custom:member treasuryFeeReciever Receiver of the treasury fees.
 * @custom:member treasuryFeePct Treasury fees. Expressed in FULL_PERCENT.
 */
struct PlatformFees {
    address ecosystemFeeReceiver;
    uint96 ecosystemFeePct;
    address treasuryFeeReceiver;
    uint96 treasuryFeePct;
}

/* ========== INTERFACES ========== */

interface IStrategyRegistry {
    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns address of emergency withdrawal wallet.
     * @return emergencyWithdrawalWallet Address of the emergency withdrawal wallet.
     */
    function emergencyWithdrawalWallet() external view returns (address emergencyWithdrawalWallet);

    /**
     * @notice Returns current do-hard-work indexes for strategies.
     * @param strategies Strategies.
     * @return dhwIndexes Current do-hard-work indexes for strategies.
     */
    function currentIndex(address[] calldata strategies) external view returns (uint256[] memory dhwIndexes);

    /**
     * @notice Returns current strategy APYs.
     * @param strategies Strategies.
     */
    function strategyAPYs(address[] calldata strategies) external view returns (int256[] memory apys);

    /**
     * @notice Returns assets deposited into a do-hard-work index for a strategy.
     * @param strategy Strategy.
     * @param dhwIndex Do-hard-work index.
     * @return assets Assets deposited into the do-hard-work index for the strategy.
     */
    function depositedAssets(address strategy, uint256 dhwIndex) external view returns (uint256[] memory assets);

    /**
     * @notice Returns shares redeemed in a do-hard-work index for a strategy.
     * @param strategy Strategy.
     * @param dhwIndex Do-hard-work index.
     * @return shares Shares redeemed in a do-hard-work index for the strategy.
     */
    function sharesRedeemed(address strategy, uint256 dhwIndex) external view returns (uint256 shares);

    /**
     * @notice Gets timestamps when do-hard-works were performed.
     * @param strategies Strategies.
     * @param dhwIndexes Do-hard-work indexes.
     * @return timestamps Timestamp for each pair of strategies and do-hard-work indexes.
     */
    function dhwTimestamps(address[] calldata strategies, uint16a16 dhwIndexes)
        external
        view
        returns (uint256[] memory timestamps);

    function getDhwYield(address[] calldata strategies, uint16a16 dhwIndexes)
        external
        view
        returns (int256[] memory yields);

    /**
     * @notice Returns state of strategies at do-hard-work indexes.
     * @param strategies Strategies.
     * @param dhwIndexes Do-hard-work indexes.
     * @return states State of each strategy at corresponding do-hard-work index.
     */
    function strategyAtIndexBatch(address[] calldata strategies, uint16a16 dhwIndexes, uint256 assetGroupLength)
        external
        view
        returns (StrategyAtIndex[] memory states);

    /**
     * @notice Gets required asset ratio for strategy at last DHW.
     * @param strategy Address of the strategy.
     * @return assetRatio Asset ratio.
     */
    function assetRatioAtLastDhw(address strategy) external view returns (uint256[] memory assetRatio);

    /**
     * @notice Gets set platform fees.
     * @return fees Set platform fees.
     */
    function platformFees() external view returns (PlatformFees memory fees);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Registers a strategy into the system.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param strategy Address of strategy to register.
     * @param apy Apy of the strategy at the time of the registration.
     */
    function registerStrategy(address strategy, int256 apy) external;

    /**
     * @notice Removes strategy from the system.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategy Strategy to remove.
     */
    function removeStrategy(address strategy) external;

    /**
     * @notice Sets ecosystem fee.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param ecosystemFeePct Ecosystem fee to set. Expressed in terms of FULL_PERCENT.
     */
    function setEcosystemFee(uint96 ecosystemFeePct) external;

    /**
     * @notice Sets receiver of the ecosystem fees.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param ecosystemFeeReceiver Receiver to set.
     */
    function setEcosystemFeeReceiver(address ecosystemFeeReceiver) external;

    /**
     * @notice Sets treasury fee.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param treasuryFeePct Treasury fee to set. Expressed in terms of FULL_PERCENT.
     */
    function setTreasuryFee(uint96 treasuryFeePct) external;

    /**
     * @notice Sets treasury fee receiver.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param treasuryFeeReceiver Receiver to set.
     */
    function setTreasuryFeeReceiver(address treasuryFeeReceiver) external;

    /**
     * @notice Does hard work on multiple strategies.
     * @dev Requirements:
     * - caller must have role ROLE_DO_HARD_WORKER
     * @param dhwParams Parameters for do hard work.
     */
    function doHardWork(DoHardWorkParameterBag calldata dhwParams) external;

    /**
     * @notice Adds deposits to strategies to be processed at next do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategies Strategies to which to add deposit.
     * @param amounts Amounts of assets to add to each strategy.
     * @return strategyIndexes Current do-hard-work indexes for the strategies.
     */
    function addDeposits(address[] calldata strategies, uint256[][] calldata amounts)
        external
        returns (uint16a16 strategyIndexes);

    /**
     * @notice Adds withdrawals to strategies to be processed at next do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategies Strategies to which to add withdrawal.
     * @param strategyShares Amounts of strategy shares to add to each strategy.
     * @return strategyIndexes Current do-hard-work indexes for the strategies.
     */
    function addWithdrawals(address[] calldata strategies, uint256[] calldata strategyShares)
        external
        returns (uint16a16 strategyIndexes);

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param redeemFastParams Parameters for fast redeem.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFast(RedeemFastParameterBag calldata redeemFastParams)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Claims withdrawals from the strategies.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * - DHWs must be run for withdrawal indexes.
     * @param strategies Addresses if strategies from which to claim withdrawal.
     * @param dhwIndexes Indexes of strategies when withdrawal was made.
     * @param strategyShares Amount of strategy shares that was withdrawn.
     * @return assetsWithdrawn Amount of assets withdrawn from strategies.
     */
    function claimWithdrawals(address[] calldata strategies, uint16a16 dhwIndexes, uint256[] calldata strategyShares)
        external
        returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Redeems strategy shares.
     * Used by recipients of platform fees.
     * @param strategies Strategies from which to redeem.
     * @param shares Amount of shares to redeem from each strategy.
     * @param withdrawalSlippages Slippages to guard redeemal process.
     */
    function redeemStrategyShares(
        address[] calldata strategies,
        uint256[] calldata shares,
        uint256[][] calldata withdrawalSlippages
    ) external;

    /**
     * @notice Strategy was registered
     * @param strategy Strategy address
     */
    event StrategyRegistered(address indexed strategy);

    /**
     * @notice Strategy was removed
     * @param strategy Strategy address
     */
    event StrategyRemoved(address indexed strategy);

    /**
     * @notice Strategy DHW was executed
     * @param strategy Strategy address
     * @param dhwIndex DHW index
     * @param dhwInfo DHW info
     */
    event StrategyDhw(address indexed strategy, uint256 dhwIndex, DhwInfo dhwInfo);

    /**
     * @notice Ecosystem fee configuration was changed
     * @param feePct Fee percentage value
     */
    event EcosystemFeeSet(uint256 feePct);

    /**
     * @notice Ecosystem fee receiver was changed
     * @param ecosystemFeeReceiver Receiver address
     */
    event EcosystemFeeReceiverSet(address indexed ecosystemFeeReceiver);

    /**
     * @notice Treasury fee configuration was changed
     * @param feePct Fee percentage value
     */
    event TreasuryFeeSet(uint256 feePct);

    /**
     * @notice Treasury fee receiver was changed
     * @param treasuryFeeReceiver Receiver address
     */
    event TreasuryFeeReceiverSet(address indexed treasuryFeeReceiver);

    /**
     * @notice Emergency withdrawal wallet changed
     * @param wallet Emergency withdrawal wallet address
     */
    event EmergencyWithdrawalWalletSet(address indexed wallet);

    /**
     * @notice Strategy shares have been redeemed
     * @param strategy Strategy address
     * @param owner Address that owns the shares
     * @param recipient Address that received the withdrawn funds
     * @param shares Amount of shares that were redeemed
     * @param assetsWithdrawn Amounts of withdrawn assets
     */
    event StrategySharesRedeemed(
        address indexed strategy,
        address indexed owner,
        address indexed recipient,
        uint256 shares,
        uint256[] assetsWithdrawn
    );

    /**
     * @notice Strategy shares were fast redeemed
     * @param strategy Strategy address
     * @param shares Amount of shares redeemed
     * @param assetsWithdrawn Amounts of withdrawn assets
     */
    event StrategySharesFastRedeemed(address indexed strategy, uint256 shares, uint256[] assetsWithdrawn);

    /**
     * @notice Strategy APY value was updated
     * @param strategy Strategy address
     * @param apy New APY value
     */
    event StrategyApyUpdated(address indexed strategy, int256 apy);
}

interface IEmergencyWithdrawal {
    /**
     * @notice Emitted when a strategy is emergency withdrawn from.
     * @param strategy Strategy that was emergency withdrawn from.
     */
    event StrategyEmergencyWithdrawn(address indexed strategy);

    /**
     * @notice Set a new address that will receive assets withdrawn if emergency withdrawal is executed.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param wallet Address to set as the emergency withdrawal wallet.
     */
    function setEmergencyWithdrawalWallet(address wallet) external;

    /**
     * @notice Instantly withdraws assets from a strategy, bypassing shares mechanism.
     * @dev Requirements:
     * - caller must have role ROLE_EMERGENCY_WITHDRAWAL_EXECUTOR
     * @param strategies Addresses of strategies.
     * @param withdrawalSlippages Slippages to guard withdrawal.
     * @param removeStrategies Whether to remove strategies from the system after withdrawal.
     */
    function emergencyWithdraw(
        address[] calldata strategies,
        uint256[][] calldata withdrawalSlippages,
        bool removeStrategies
    ) external;
}

// src/strategies/Strategy.sol

/**
 * @notice Used when initial locked strategy shares are already minted and strategy usd value is zero.
 */
error StrategyWorthIsZero();

abstract contract Strategy is ERC20Upgradeable, SpoolAccessControllable, IStrategy {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IAssetGroupRegistry internal immutable _assetGroupRegistry;

    /// @notice Name of the strategy
    string private _strategyName;

    /// @dev ID of the asset group used by the strategy.
    uint256 private immutable _assetGroupId;
    /// @dev ID of the asset group used by the strategy.
    uint256 private _assetGroupIdStorage;
    // Only one of the above can be set. Use the `assetGroupId` function to read
    // the correct one.

    constructor(IAssetGroupRegistry assetGroupRegistry_, ISpoolAccessControl accessControl_, uint256 assetGroupId_)
        SpoolAccessControllable(accessControl_)
    {
        if (address(assetGroupRegistry_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        _assetGroupRegistry = assetGroupRegistry_;
        _assetGroupId = assetGroupId_;
    }

    function __Strategy_init(string memory strategyName_, uint256 assetGroupId_) internal onlyInitializing {
        if (bytes(strategyName_).length == 0) revert InvalidConfiguration();

        // asset group ID needs to be set exactly once,
        // either in constructor or initializer
        if (_assetGroupId == NULL_ASSET_GROUP_ID) {
            if (assetGroupId_ == NULL_ASSET_GROUP_ID) {
                revert InvalidAssetGroupIdInitialization();
            }
            _assetGroupIdStorage = assetGroupId_;
        } else {
            if (assetGroupId_ != NULL_ASSET_GROUP_ID) {
                revert InvalidAssetGroupIdInitialization();
            }
        }
        _assetGroupRegistry.validateAssetGroup(assetGroupId());

        _strategyName = strategyName_;

        __ERC20_init("Strategy Share Token", "SST");
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function assetGroupId() public view returns (uint256) {
        return _assetGroupId > 0 ? _assetGroupId : _assetGroupIdStorage;
    }

    function assets() public view returns (address[] memory) {
        return _assetGroupRegistry.listAssetGroup(assetGroupId());
    }

    function assetRatio() external view virtual returns (uint256[] memory);

    function strategyName() external view returns (string memory) {
        return _strategyName;
    }

    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) public virtual;

    function beforeRedeemalCheck(uint256 ssts, uint256[] calldata slippages) public virtual;

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    function doHardWork(StrategyDhwParameterBag calldata dhwParams) external returns (DhwInfo memory dhwInfo) {
        _checkRole(ROLE_STRATEGY_REGISTRY, msg.sender);

        bool depositNeeded;
        uint256[] memory assetsToDeposit = new uint256[](dhwParams.assetGroup.length);
        unchecked {
            for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                assetsToDeposit[i] = IERC20(dhwParams.assetGroup[i]).balanceOf(address(this));

                if (assetsToDeposit[i] > 0) {
                    depositNeeded = true;
                }
            }
        }

        beforeDepositCheck(assetsToDeposit, dhwParams.slippages);
        beforeRedeemalCheck(dhwParams.withdrawnShares, dhwParams.slippages);

        // usdWorth[0]: usd worth before deposit / withdrawal
        // usdWorth[1]: usd worth after deposit / withdrawal
        uint256[2] memory usdWorth;

        // Compound and get USD value.
        {
            dhwInfo.yieldPercentage = _getYieldPercentage(dhwParams.baseYield);
            int256 compoundYield = _compound(dhwParams.assetGroup, dhwParams.compoundSwapInfo, dhwParams.slippages);
            dhwInfo.yieldPercentage += compoundYield + compoundYield * dhwInfo.yieldPercentage / YIELD_FULL_PERCENT_INT;
        }

        // collect fees, mint SVTs relative to the yield generated
        _collectPlatformFees(dhwInfo.yieldPercentage, dhwParams.platformFees);

        usdWorth[0] = _getUsdWorth(dhwParams.exchangeRates, dhwParams.priceFeedManager);

        uint256 matchedShares;
        uint256 depositShareEquivalent;
        uint256 mintedShares;
        uint256 withdrawnShares = dhwParams.withdrawnShares;

        // Calculate deposit share equivalent.
        if (depositNeeded) {
            uint256 valueToDeposit = dhwParams.priceFeedManager.assetToUsdCustomPriceBulk(
                dhwParams.assetGroup, assetsToDeposit, dhwParams.exchangeRates
            );

            if (totalSupply() < INITIAL_LOCKED_SHARES) {
                depositShareEquivalent = INITIAL_SHARE_MULTIPLIER * valueToDeposit;
            } else if (usdWorth[0] > 0) {
                depositShareEquivalent = totalSupply() * valueToDeposit / usdWorth[0];
            } else {
                revert StrategyWorthIsZero();
            }

            // Match withdrawals and deposits by taking smaller value as matched shares.
            if (depositShareEquivalent < withdrawnShares) {
                matchedShares = depositShareEquivalent;
            } else {
                matchedShares = withdrawnShares;
            }
        }

        uint256[] memory withdrawnAssets = new uint256[](dhwParams.assetGroup.length);
        bool withdrawn;
        if (depositShareEquivalent > withdrawnShares) {
            // Deposit is needed.

            // - match if needed
            if (matchedShares > 0) {
                unchecked {
                    for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                        withdrawnAssets[i] = assetsToDeposit[i] * matchedShares / depositShareEquivalent;
                        assetsToDeposit[i] -= withdrawnAssets[i];
                    }
                }
                withdrawn = true;
            }

            // - swap assets
            uint256[] memory assetsIn = new uint256[](assetsToDeposit.length);
            if (dhwParams.swapInfo.length > 0) {
                _swapAssets(dhwParams.assetGroup, assetsToDeposit, dhwParams.swapInfo);
                for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                    assetsIn[i] = assetsToDeposit[i];
                    assetsToDeposit[i] = IERC20(dhwParams.assetGroup[i]).balanceOf(address(this)) - withdrawnAssets[i];
                }
            } else {
                for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                    assetsIn[i] = assetsToDeposit[i];
                }
            }

            // - deposit assets into the protocol
            _depositToProtocol(dhwParams.assetGroup, assetsToDeposit, dhwParams.slippages);
            usdWorth[1] = _getUsdWorth(dhwParams.exchangeRates, dhwParams.priceFeedManager);

            // - mint SSTs
            mintedShares = _mintStrategyShares(usdWorth[0], usdWorth[1]);

            emit Deposited(mintedShares, usdWorth[1] - usdWorth[0], assetsIn, assetsToDeposit);

            mintedShares += matchedShares;
        } else if (withdrawnShares > depositShareEquivalent) {
            // Withdrawal is needed.

            // - match if needed
            if (matchedShares > 0) {
                unchecked {
                    withdrawnShares -= matchedShares;
                    mintedShares = matchedShares;
                }
            }

            // - redeem shares from protocol
            _redeemFromProtocol(dhwParams.assetGroup, withdrawnShares, dhwParams.slippages);
            _burn(address(this), withdrawnShares);
            withdrawn = true;

            // - figure out how much was withdrawn
            usdWorth[1] = _getUsdWorth(dhwParams.exchangeRates, dhwParams.priceFeedManager);
            unchecked {
                for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                    withdrawnAssets[i] = IERC20(dhwParams.assetGroup[i]).balanceOf(address(this));
                }
            }

            emit Withdrawn(withdrawnShares, usdWorth[1], withdrawnAssets);
        } else {
            // Neither withdrawal nor deposit is needed.

            // - match if needed
            if (matchedShares > 0) {
                mintedShares = withdrawnShares;
                unchecked {
                    for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                        withdrawnAssets[i] = assetsToDeposit[i];
                    }
                }
                withdrawn = true;
            }

            usdWorth[1] = usdWorth[0];
        }

        // Transfer withdrawn assets to master wallet if needed.
        if (withdrawn) {
            unchecked {
                for (uint256 i; i < dhwParams.assetGroup.length; ++i) {
                    IERC20(dhwParams.assetGroup[i]).safeTransfer(dhwParams.masterWallet, withdrawnAssets[i]);
                }
            }
        }

        dhwInfo.sharesMinted = mintedShares;
        dhwInfo.assetsWithdrawn = withdrawnAssets;
        dhwInfo.valueAtDhw = usdWorth[1];
        dhwInfo.totalSstsAtDhw = totalSupply();
    }

    function redeemFast(
        uint256 shares,
        address masterWallet,
        address[] calldata assetGroup,
        uint256[] calldata slippages
    ) external returns (uint256[] memory) {
        if (
            !_accessControl.hasRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
                && !_accessControl.hasRole(ROLE_STRATEGY_REGISTRY, msg.sender)
        ) {
            revert NotFastRedeemer(msg.sender);
        }

        return _redeemShares(shares, address(this), masterWallet, assetGroup, slippages);
    }

    function redeemShares(uint256 shares, address redeemer, address[] calldata assetGroup, uint256[] calldata slippages)
        external
        returns (uint256[] memory)
    {
        _checkRole(ROLE_STRATEGY_REGISTRY, msg.sender);

        return _redeemShares(shares, redeemer, redeemer, assetGroup, slippages);
    }

    /// @dev is only called when reallocating
    function depositFast(
        address[] calldata assetGroup,
        uint256[] calldata exchangeRates,
        IUsdPriceFeedManager priceFeedManager,
        uint256[] calldata slippages,
        SwapInfo[] calldata swapInfo
    ) external onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender) returns (uint256) {
        // get amount of assets available to deposit
        uint256[] memory assetsToDeposit = new uint256[](assetGroup.length);
        for (uint256 i; i < assetGroup.length; ++i) {
            assetsToDeposit[i] = IERC20(assetGroup[i]).balanceOf(address(this));
        }

        // swap assets
        _swapAssets(assetGroup, assetsToDeposit, swapInfo);
        uint256[] memory assetsDeposited = new uint256[](assetGroup.length);
        for (uint256 i; i < assetGroup.length; ++i) {
            assetsDeposited[i] = IERC20(assetGroup[i]).balanceOf(address(this));
        }

        // deposit assets
        uint256 usdWorth0 = _getUsdWorth(exchangeRates, priceFeedManager);
        _depositToProtocol(assetGroup, assetsDeposited, slippages);
        uint256 usdWorth1 = _getUsdWorth(exchangeRates, priceFeedManager);

        // mint SSTs
        uint256 sstsToMint = _mintStrategyShares(usdWorth0, usdWorth1);

        emit Deposited(sstsToMint, usdWorth1 - usdWorth0, assetsToDeposit, assetsDeposited);

        return sstsToMint;
    }

    function claimShares(address smartVault, uint256 amount) external onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender) {
        _transfer(address(this), smartVault, amount);
    }

    function releaseShares(address smartVault, uint256 amount)
        external
        onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
    {
        _transfer(smartVault, address(this), amount);
    }

    function emergencyWithdraw(uint256[] calldata slippages, address recipient)
        external
        onlyRole(ROLE_STRATEGY_REGISTRY, msg.sender)
    {
        _emergencyWithdrawImpl(slippages, recipient);
    }

    function getProtocolRewards() external onlyViewExecution returns (address[] memory, uint256[] memory) {
        return _getProtocolRewardsInternal();
    }

    function getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        external
        onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender)
        returns (uint256)
    {
        return _getUsdWorth(exchangeRates, priceFeedManager);
    }

    /* ========== PRIVATE/INTERNAL FUNCTIONS ========== */

    function _mintStrategyShares(uint256 usdWorthBefore, uint256 usdWorthAfter)
        private
        returns (uint256 mintedShares)
    {
        uint256 totalSupply_ = totalSupply();

        if (totalSupply_ < INITIAL_LOCKED_SHARES) {
            // multiply with usd worth after deposit as there are no other owned shares
            mintedShares = usdWorthAfter * INITIAL_SHARE_MULTIPLIER;

            unchecked {
                uint256 lockedSharesLeftToMint = INITIAL_LOCKED_SHARES - totalSupply_;

                if (mintedShares < lockedSharesLeftToMint) {
                    lockedSharesLeftToMint = mintedShares;
                }

                mintedShares -= lockedSharesLeftToMint;

                _mint(INITIAL_LOCKED_SHARES_ADDRESS, lockedSharesLeftToMint);
            }
        } else if (usdWorthBefore > 0) {
            mintedShares = (usdWorthAfter - usdWorthBefore) * totalSupply_ / usdWorthBefore;
        } else {
            revert StrategyWorthIsZero();
        }

        _mint(address(this), mintedShares);
    }

    function _redeemShares(
        uint256 shares,
        address shareOwner,
        address recipient,
        address[] calldata assetGroup,
        uint256[] calldata slippages
    ) internal virtual returns (uint256[] memory) {
        // redeem shares from protocol
        uint256[] memory assetsWithdrawn = _redeemFromProtocolAndReturnAssets(assetGroup, shares, slippages);
        _burn(shareOwner, shares);

        // transfer assets to recipient (master wallet in case of redeemFast)
        unchecked {
            for (uint256 i; i < assetGroup.length; ++i) {
                IERC20(assetGroup[i]).safeTransfer(recipient, assetsWithdrawn[i]);
            }
        }

        return assetsWithdrawn;
    }

    /**
     * @notice Calculate and mint platform performance fees based on the yield generated.
     * @param yieldPct Yield generated since previous DHW. Full percent is `YIELD_FULL_PERCENT`.
     * @param platformFees Platform fees info, containing information of the sice and recipient of the fees (SSTs).
     * @return sharesMinted Returns newly minted shares representing the platform performance fees.
     */
    function _collectPlatformFees(int256 yieldPct, PlatformFees calldata platformFees)
        internal
        virtual
        returns (uint256 sharesMinted)
    {
        if (yieldPct > 0) {
            uint256 uint256YieldPct = uint256(yieldPct);

            uint256 yieldPctUsersPlusOne = uint256YieldPct
                * (FULL_PERCENT - platformFees.ecosystemFeePct - platformFees.treasuryFeePct)
                + FULL_PERCENT * YIELD_FULL_PERCENT;
            uint256 totalSupplyTimesYieldPct = totalSupply() * uint256YieldPct;

            // mint new ecosystem fee SSTs
            uint256 newEcosystemFeeSsts = totalSupplyTimesYieldPct * platformFees.ecosystemFeePct / yieldPctUsersPlusOne;
            _mint(platformFees.ecosystemFeeReceiver, newEcosystemFeeSsts);

            // mint new treasury fee SSTs
            uint256 newTreasuryFeeSsts = totalSupplyTimesYieldPct * platformFees.treasuryFeePct / yieldPctUsersPlusOne;
            _mint(platformFees.treasuryFeeReceiver, newTreasuryFeeSsts);

            unchecked {
                sharesMinted = newEcosystemFeeSsts + newTreasuryFeeSsts;
            }

            emit PlatformFeesCollected(address(this), sharesMinted);
        }
    }

    function _redeemFromProtocolAndReturnAssets(address[] calldata tokens, uint256 ssts, uint256[] calldata slippages)
        internal
        virtual
        returns (uint256[] memory withdrawnAssets)
    {
        withdrawnAssets = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            withdrawnAssets[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        _redeemFromProtocol(tokens, ssts, slippages);

        for (uint256 i; i < tokens.length; ++i) {
            withdrawnAssets[i] = IERC20(tokens[i]).balanceOf(address(this)) - withdrawnAssets[i];
        }
    }

    function _calculateYieldPercentage(uint256 previousValue, uint256 currentValue)
        internal
        pure
        returns (int256 yieldPercentage)
    {
        if (currentValue > previousValue) {
            yieldPercentage = int256((currentValue - previousValue) * YIELD_FULL_PERCENT / previousValue);
        } else if (previousValue > currentValue) {
            yieldPercentage = -int256((previousValue - currentValue) * YIELD_FULL_PERCENT / previousValue);
        }
    }

    function _resetAndApprove(IERC20 token, address spender, uint256 amount) internal {
        _resetAllowance(token, spender);
        token.safeApprove(spender, amount);
    }

    function _resetAllowance(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
    }

    function _isViewExecution() internal view returns (bool) {
        return tx.origin == address(0);
    }

    function _compound(address[] calldata tokens, SwapInfo[] calldata compoundSwapInfo, uint256[] calldata slippages)
        internal
        virtual
        returns (int256 compoundYield);

    function _getYieldPercentage(int256 manualYield) internal virtual returns (int256);

    /**
     * @dev Swaps assets.
     * @param tokens Addresses of tokens to swap.
     * @param toSwap Available amounts to swap.
     * @param swapInfo Information on how to swap.
     */
    function _swapAssets(address[] memory tokens, uint256[] memory toSwap, SwapInfo[] calldata swapInfo)
        internal
        virtual;

    /**
     * @dev Deposits assets into the underlying protocol.
     * @param tokens Addresses of asset tokens.
     * @param amounts Amounts to deposit.
     * @param slippages Slippages to guard depositing.
     */
    function _depositToProtocol(address[] calldata tokens, uint256[] memory amounts, uint256[] calldata slippages)
        internal
        virtual;

    /**
     * @dev Redeems shares from the undelying protocol.
     * @param tokens Addresses of asset tokens.
     * @param ssts Amount of strategy tokens to redeem.
     * @param slippages Slippages to guard redeemal.
     */
    function _redeemFromProtocol(address[] calldata tokens, uint256 ssts, uint256[] calldata slippages)
        internal
        virtual;

    function _emergencyWithdrawImpl(uint256[] calldata slippages, address recipient) internal virtual;

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        virtual
        returns (uint256);

    /**
     * @dev Gets protocol rewards.
     * @return tokens Addresses of reward tokens.
     * @return amounts Amount of each reward token.
     */
    function _getProtocolRewardsInternal()
        internal
        virtual
        returns (address[] memory tokens, uint256[] memory amounts);

    /* ========== MODIFIERS ========== */

    modifier onlyViewExecution() {
        require(_isViewExecution());
        _;
    }
}

// src/strategies/arbitrum/base/CompoundV3StrategyBase.sol

abstract contract CompoundV3StrategyBase is Strategy {
    using SafeERC20 for IERC20;

    /// @notice Swapper implementation
    ISwapper public immutable swapper;

    /// @notice COMP token
    /// @dev Reward token when participating in the Compound protocol.
    IERC20 public immutable comp;

    IRewards public immutable rewards;

    /// @notice Compound market
    IComet public cToken;

    /// @notice underlying pool token (USDC for aUSDC, USDC.e for aUSDC.e etc)
    address public underlying;

    /// @notice supply rate at the last DHW.
    uint256 private _lastBaseSupplyIndex;

    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        ISwapper swapper_,
        IERC20 comp_,
        IRewards rewards_
    ) Strategy(assetGroupRegistry_, accessControl_, NULL_ASSET_GROUP_ID) {
        if (address(swapper_) == address(0)) revert ConfigurationAddressZero();
        if (address(comp_) == address(0)) revert ConfigurationAddressZero();
        if (address(rewards_) == address(0)) revert ConfigurationAddressZero();

        swapper = swapper_;
        comp = comp_;
        rewards = rewards_;
    }

    function initialize(string memory strategyName_, uint256 assetGroupId_, IComet cToken_) external initializer {
        __Strategy_init(strategyName_, assetGroupId_);

        if (address(cToken_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        address[] memory tokens = assets();

        if (tokens.length != 1) {
            revert InvalidAssetGroup(assetGroupId());
        }

        underlying = cToken_.baseToken();

        cToken = cToken_;
        _lastBaseSupplyIndex = _baseSupplyIndexCurrent();
    }

    function assetRatio() external pure override returns (uint256[] memory) {
        uint256[] memory _assetRatio = new uint256[](1);
        _assetRatio[0] = 1;
        return _assetRatio;
    }

    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts) {
        amounts = new uint256[](1);
        amounts[0] = _getCTokenBalance();
    }

    function beforeDepositCheck(uint256[] memory, uint256[] calldata) public virtual override {}

    function beforeRedeemalCheck(uint256, uint256[] calldata) public virtual override {}

    function _depositToProtocol(address[] calldata, uint256[] memory amounts, uint256[] calldata)
        internal
        virtual
        override
    {
        _depositToProtocolInternal(amounts[0]);
    }

    /**
     * @notice Withdraw lp tokens from the Compound market
     */
    function _redeemFromProtocol(address[] calldata, uint256 ssts, uint256[] calldata) internal virtual override {
        if (ssts == 0) {
            return;
        }

        uint256 cTokenWithdrawAmount = (_getCTokenBalance() * ssts) / totalSupply();

        _redeemFromProtocolInternal(cTokenWithdrawAmount);
    }

    /**
     * @notice Nothing to swap as it's only one asset.
     */
    function _swapAssets(address[] memory, uint256[] memory, SwapInfo[] calldata) internal override {}

    function _compound(address[] calldata, SwapInfo[] calldata swapInfo, uint256[] calldata)
        internal
        override
        returns (int256 compoundedYieldPercentage)
    {
        if (swapInfo.length > 0) {
            uint256 compBalance = _getCompoundReward();

            if (compBalance > 0) {
                comp.safeTransfer(address(swapper), compBalance);
                address[] memory tokensIn = new address[](1);
                tokensIn[0] = address(comp);
                address[] memory tokensOut = new address[](1);
                tokensOut[0] = underlying;
                uint256 swappedAmount = swapper.swap(tokensIn, swapInfo, tokensOut, address(this))[0];

                if (swappedAmount > 0) {
                    uint256 cTokenBalanceBefore = _getCTokenBalance();
                    _depositToProtocolInternal(swappedAmount);

                    compoundedYieldPercentage = _calculateYieldPercentage(cTokenBalanceBefore, _getCTokenBalance());
                }
            }
        }
    }

    function _emergencyWithdrawImpl(uint256[] calldata, address recipient) internal override {
        _redeemFromProtocolInternal(_getCTokenBalance());

        IERC20 token = IERC20(underlying);

        token.safeTransfer(recipient, token.balanceOf(address(this)));
    }

    function _getYieldPercentage(int256) internal override returns (int256 baseYieldPercentage) {
        uint256 baseSupplyIndexCurrent = _baseSupplyIndexCurrent();

        baseYieldPercentage = _calculateYieldPercentage(_lastBaseSupplyIndex, baseSupplyIndexCurrent);
        _lastBaseSupplyIndex = baseSupplyIndexCurrent;
    }

    function _getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        internal
        view
        override
        returns (uint256 usdValue)
    {
        usdValue = priceFeedManager.assetToUsdCustomPrice(assets()[0], _getCTokenBalance(), exchangeRates[0]);
    }

    function _getProtocolRewardsInternal() internal virtual override returns (address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(comp);
        amounts[0] = _getCompoundReward();

        return (tokens, amounts);
    }

    function _depositToProtocolInternal(uint256 amount) private {
        if (amount > 0) {
            _resetAndApprove(IERC20(underlying), address(cToken), amount);

            cToken.supply(underlying, amount);
        }
    }

    function _redeemFromProtocolInternal(uint256 amount) private {
        if (amount > 0) {
            cToken.withdraw(underlying, amount);
        }
    }

    function _getCompoundReward() private returns (uint256) {
        rewards.claim({comet: address(cToken), src: address(this), shouldAccrue: true});

        return comp.balanceOf(address(this));
    }

    /// @notice accrueAccount only needed to bump baseSupplyIndex (via accrueInternal()) on the Comet contract.
    function _baseSupplyIndexCurrent() private returns (uint256) {
        cToken.accrueAccount(address(this));
        return cToken.totalsBasic().baseSupplyIndex;
    }

    function _getCTokenBalance() private view returns (uint256) {
        return cToken.balanceOf(address(this));
    }
}

// src/strategies/arbitrum/CompoundV3Strategy.sol

// one asset
// One reward (COMP)
// no slippages needed
// Same asset group token and underlying token on the Compound pool.
contract CompoundV3Strategy is CompoundV3StrategyBase {
    constructor(
        IAssetGroupRegistry assetGroupRegistry_,
        ISpoolAccessControl accessControl_,
        ISwapper swapper_,
        IERC20 comp_,
        IRewards rewards_
    ) CompoundV3StrategyBase(assetGroupRegistry_, accessControl_, swapper_, comp_, rewards_) {}
}