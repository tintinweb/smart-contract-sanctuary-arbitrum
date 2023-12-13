// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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

pragma solidity 0.8.19;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "../../interfaces/IPlatformAdapter.sol";
import "../../interfaces/IAdapter.sol";
import "./interfaces/IGmxAdapter.sol";
import "./interfaces/IGmxOrderBook.sol";
import "./interfaces/IGmxReader.sol";
import "./interfaces/IGmxRouter.sol";
import "./interfaces/IGmxVault.sol";
import "../../interfaces/ITraderWallet.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


// import "hardhat/console.sol";

library GMXAdapter {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;

    address internal constant gmxRouter =
        0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;
    address internal constant gmxPositionRouter =
        0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868;
    IGmxVault internal constant gmxVault =
        IGmxVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    address internal constant gmxOrderBook =
        0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB;
    address internal constant gmxOrderBookReader =
        0xa27C20A7CF0e1C68C0460706bB674f98F362Bc21;
    address internal constant gmxReader =
        0x22199a49A999c351eF7927602CFB187ec3cae489;

    /// @notice The ratio denominator between traderWallet and usersVault
    uint256 private constant ratioDenominator = 1e18;

    /// @notice The slippage allowance for swap in the position
    uint256 public constant slippage = 1e17; // 10%    

    struct IncreaseOrderLocalVars {
        address[] path;
        uint256 amountIn;
        address indexToken;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
    }

    event CreateIncreasePosition(address sender, bytes32 requestKey);
    event CreateDecreasePosition(address sender, bytes32 requestKey);

    error AddressZero();
    error InsufficientEtherBalance();
    error InvalidOperationId();
    error CreateSwapOrderFail();
    error CreateIncreasePositionFail(string);
    error CreateDecreasePositionFail(string);
    error CreateIncreasePositionOrderFail(string);
    error CreateDecreasePositionOrderFail(string);
    error NotSupportedTokens(address, address);
    error TooManyOrders();

    /// @notice Gives approve to operate with gmxPositionRouter
    /// @dev Needs to be called from wallet and vault in initialization
    function __initApproveGmxPlugin() external {
        IGmxRouter(gmxRouter).approvePlugin(gmxPositionRouter);
        IGmxRouter(gmxRouter).approvePlugin(gmxOrderBook);
    }

    /// @notice Executes operation with external protocol
    /// @param ratio Scaling ratio to
    /// @param traderOperation Encoded operation data
    /// @return bool 'true' if the operation completed successfully
    function executeOperation(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        IAdapter.AdapterOperation memory traderOperation
    ) external returns (bool, uint256) {
        if (uint256(traderOperation.operationId) == 0) {
            return
                _increasePosition(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 1) {
            return
                _decreasePosition(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 2) {
            return
                _createIncreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 3) {
            return
                _updateIncreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 4) {
            return _cancelIncreaseOrder(isTraderWallet, traderOperation.data);
        } else if (traderOperation.operationId == 5) {
            return
                _createDecreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 6) {
            return
                _updateDecreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 7) {
            return _cancelDecreaseOrder(isTraderWallet, traderOperation.data);
        }
        revert InvalidOperationId();
    }

    /*
    @notice Opens new or increases the size of an existing position
    @param tradeData must contain parameters:
        path:       [collateralToken] or [tokenIn, collateralToken] if a swap is needed
        indexToken: the address of the token to long or short
        amountIn:   the amount of tokenIn to deposit as collateral
        minOut:     the min amount of collateralToken to swap for (can be zero if no swap is required)
        sizeDelta:  the USD value of the change in position size  (scaled 1e30)
        isLong:     whether to long or short position
        priceAllowedSlippage: allowed slippage for acceptable price; default 30(0.3%); range is [0, 500(5%)]

    Additional params for increasing position
        executionFee:   can be set to PositionRouter.minExecutionFee
        referralCode:   referral code for affiliate rewards and rebates
        callbackTarget: an optional callback contract (note: has gas limit)
        acceptablePrice: the USD value of the max (for longs) or min (for shorts) index price acceptable when executing
    @return bool - Returns 'true' if position was created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _increasePosition(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            address[] memory path,
            address indexToken,
            uint256 amountIn,
            uint256 minOut,
            uint256 sizeDelta,
            bool isLong,
            uint256 priceAllowedSlippage
        ) = abi.decode(
                tradeData,
                (address[], address, uint256, uint256, uint256, bool, uint256)
            );

        if (isTraderWallet) {
            {
                // only one check is enough
                address collateralToken = path[path.length - 1];
                if (
                    !_validateTradeTokens(
                        traderWallet,
                        collateralToken,
                        indexToken,
                        isLong
                    )
                ) {
                    revert NotSupportedTokens(collateralToken, indexToken);
                }
            }
            // calculate ratio for UserVault based on balances of tokenIn (path[0])
            uint256 traderBalance = IERC20Upgradeable(path[0]).balanceOf(traderWallet);
            uint256 vaultBalance = IERC20Upgradeable(path[0]).balanceOf(usersVault);
            ratio_ = vaultBalance.mulDiv(
                ratioDenominator,
                traderBalance,
                MathUpgradeable.Rounding.Down
            );
        } else {
            // scaling for Vault execution
            amountIn = (amountIn * ratio) / ratioDenominator;
            uint256 amountInAvailable = IERC20Upgradeable(path[0]).balanceOf(
                address(this)
            );
            if (amountInAvailable < amountIn) amountIn = amountInAvailable;
            sizeDelta = (sizeDelta * ratio) / ratioDenominator;
            minOut = (minOut * ratio) / (ratioDenominator + slippage); // decreased due to price impact
        }

        _checkUpdateAllowance(path[0], address(gmxRouter), amountIn);
        uint256 executionFee = IGmxPositionRouter(gmxPositionRouter)
            .minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        uint256 acceptablePrice;
        {
            uint256 refPrice;
            uint256 priceBasisPoints;
            uint256 priceBasisPointsDivisor = 10000;
            if (isLong) {
                refPrice = gmxVault.getMaxPrice(indexToken);
                priceBasisPoints = priceBasisPointsDivisor + priceAllowedSlippage;
            } else {
                refPrice = gmxVault.getMinPrice(indexToken);
                priceBasisPoints = priceBasisPointsDivisor - priceAllowedSlippage;
            }
            acceptablePrice = (refPrice * priceBasisPoints) / priceBasisPointsDivisor;
        }

        (bool success, bytes memory data) = gmxPositionRouter.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxPositionRouter.createIncreasePosition.selector,
                path,
                indexToken,
                amountIn,
                minOut,
                sizeDelta,
                isLong,
                acceptablePrice,
                executionFee,
                0, // referralCode
                address(0) // callbackTarget
            )
        );

        if (!success) {
            revert CreateIncreasePositionFail(_getRevertMsg(data));
        }
        emit CreateIncreasePosition(address(this), bytes32(data));
        return (true, ratio_);
    }

    /*
    @notice Closes or decreases an existing position
    @param tradeData must contain parameters:
        path:            [collateralToken] or [collateralToken, tokenOut] if a swap is needed
        indexToken:      the address of the token that was longed (or shorted)
        collateralDelta: the amount of collateral in USD value to withdraw (doesn't matter when position is completely closing)
        sizeDelta:       the USD value of the change in position size (scaled to 1e30)
        isLong:          whether the position is a long or short
        minOut:          the min output token amount (can be zero if no swap is required)
        priceAllowedSlippage: allowed slippage for acceptable price; default 30(0.3%); range is [0, 500(5%)]

    Additional params for increasing position
        receiver:       the address to receive the withdrawn tokens
        acceptablePrice: the USD value of the max (for longs) or min (for shorts) index price acceptable when executing
        executionFee:   can be set to PositionRouter.minExecutionFee
        withdrawETH:    only applicable if WETH will be withdrawn, the WETH will be unwrapped to ETH if this is set to true
        callbackTarget: an optional callback contract (note: has gas limit)
    @return bool - Returns 'true' if position was created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _decreasePosition(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            address[] memory path,
            address indexToken,
            uint256 collateralDelta,
            uint256 sizeDelta,
            bool isLong,
            uint256 minOut,
            uint256 priceAllowedSlippage
        ) = abi.decode(
                tradeData,
                (address[], address, uint256, uint256, bool, uint256, uint256)
            );
        uint256 executionFee = IGmxPositionRouter(gmxPositionRouter)
            .minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        if (isTraderWallet) {
            // calculate ratio for UserVault based on size of opened position
            uint256 traderSize = _getPosition(
                traderWallet,
                path[0],
                indexToken,
                isLong
            )[0];
            uint256 vaultSize = _getPosition(
                usersVault,
                path[0],
                indexToken,
                isLong
            )[0];
            ratio_ = vaultSize.mulDiv(
                ratioDenominator,
                traderSize,
                MathUpgradeable.Rounding.Up
            );
        } else {
            // scaling for Vault
            uint256[] memory vaultPosition = _getPosition(
                usersVault,
                path[0],
                indexToken,
                isLong
            );
            uint256 positionSize = vaultPosition[0];
            uint256 positionCollateral = vaultPosition[1];

            sizeDelta = (sizeDelta * ratio) / ratioDenominator; // most important for closing
            if (sizeDelta > positionSize) sizeDelta = positionSize;
            collateralDelta = (collateralDelta * ratio) / ratioDenominator;
            if (collateralDelta > positionCollateral)
                collateralDelta = positionCollateral;

            minOut = (minOut * ratio) / (ratioDenominator + slippage); // decreased due to price impact
        }

        uint256 acceptablePrice;
        {
            uint256 refPrice;
            uint256 priceBasisPoints;
            uint256 priceBasisPointsDivisor = 10000;
            if (isLong) {
                refPrice = gmxVault.getMinPrice(indexToken);
                priceBasisPoints = priceBasisPointsDivisor - priceAllowedSlippage;
            } else {
                refPrice = gmxVault.getMaxPrice(indexToken);
                priceBasisPoints = priceBasisPointsDivisor + priceAllowedSlippage;
            }
            acceptablePrice = (refPrice * priceBasisPoints) / priceBasisPointsDivisor;
        }

        (bool success, bytes memory data) = gmxPositionRouter.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxPositionRouter.createDecreasePosition.selector,
                path,
                indexToken,
                collateralDelta,
                sizeDelta,
                isLong,
                address(this), // receiver
                acceptablePrice,
                minOut,
                executionFee,
                false, // withdrawETH
                address(0) // callbackTarget
            )
        );

        if (!success) {
            revert CreateDecreasePositionFail(_getRevertMsg(data));
        }
        emit CreateDecreasePosition(address(this), bytes32(data));
        return (true, ratio_);
    }

    /// /// /// ///
    /// Orders
    /// /// /// ///

    /*
    @notice Creates new order to open or increase position
    @param tradeData must contain parameters:
        path:            [collateralToken] or [tokenIn, collateralToken] if a swap is needed
        amountIn:        the amount of tokenIn to deposit as collateral
        indexToken:      the address of the token to long or short
        minOut:          the min amount of collateralToken to swap for (can be zero if no swap is required)
        sizeDelta:       the USD value of the change in position size  (scaled 1e30)
        isLong:          whether to long or short position
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'false' for creating new Long order
            in terms of Short position:
                'true' for creating new Short order

    Additional params for increasing position
        collateralToken: the collateral token (must be path[path.length-1] )
        executionFee:   can be set to OrderBook.minExecutionFee
        shouldWrap:     true if 'tokenIn' is native and should be wrapped
    @return bool - Returns 'true' if order was successfully created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _createIncreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        IncreaseOrderLocalVars memory vars;
        (
            vars.path,
            vars.amountIn,
            vars.indexToken,
            vars.minOut,
            vars.sizeDelta,
            vars.isLong,
            vars.triggerPrice,
            vars.triggerAboveThreshold
        ) = abi.decode(
            tradeData,
            (address[], uint256, address, uint256, uint256, bool, uint256, bool)
        );
        uint256 executionFee = IGmxOrderBook(gmxOrderBook).minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        address collateralToken;
        if (vars.isLong) {
            collateralToken = vars.indexToken;
        } else {
            collateralToken = vars.path[vars.path.length - 1];
        }

        if (isTraderWallet) {
            // only one check is enough
            if (
                !_validateTradeTokens(
                    traderWallet,
                    collateralToken,
                    vars.indexToken,
                    vars.isLong
                )
            ) {
                revert NotSupportedTokens(collateralToken, vars.indexToken);
            }
            if (!_validateIncreaseOrder(traderWallet)) {
                revert TooManyOrders();
            }

            // calculate ratio for UserVault based on balances of tokenIn (path[0])
            uint256 traderBalance = IERC20Upgradeable(vars.path[0]).balanceOf(
                traderWallet
            );
            uint256 vaultBalance = IERC20Upgradeable(vars.path[0]).balanceOf(usersVault);
            ratio_ = vaultBalance.mulDiv(
                ratioDenominator,
                traderBalance,
                MathUpgradeable.Rounding.Up
            );
        } else {
            if (!_validateIncreaseOrder(usersVault)) {
                revert TooManyOrders();
            }
            // scaling for Vault execution
            vars.amountIn = (vars.amountIn * ratio) / ratioDenominator;
            uint256 amountInAvailable = IERC20Upgradeable(vars.path[0]).balanceOf(
                address(this)
            );
            if (amountInAvailable < vars.amountIn)
                vars.amountIn = amountInAvailable;
            vars.sizeDelta = (vars.sizeDelta * ratio) / ratioDenominator;
            vars.minOut = (vars.minOut * ratio) / (ratioDenominator + slippage); // decreased due to price impact
        }

        _checkUpdateAllowance(vars.path[0], address(gmxRouter), vars.amountIn);

        (bool success, bytes memory data) = gmxOrderBook.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxOrderBook.createIncreaseOrder.selector,
                vars.path,
                vars.amountIn,
                vars.indexToken,
                vars.minOut,
                vars.sizeDelta,
                collateralToken,
                vars.isLong,
                vars.triggerPrice,
                vars.triggerAboveThreshold,
                executionFee,
                false // 'shouldWrap'
            )
        );

        if (!success) {
            revert CreateIncreasePositionOrderFail(_getRevertMsg(data));
        }
        return (true, ratio_);
    }

    /*
    @notice Updates exist increase order
    @param tradeData must contain parameters:
        orderIndexes:   the array with Wallet and Vault indexes of the exist order indexes to update
                        [0, 1]: 0 - Wallet, 1 - Vault
        sizeDelta:       the USD value of the change in position size  (scaled 1e30)
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'false' for creating new Long order
            in terms of Short position:
                'true' for creating new Short order

    @return bool - Returns 'true' if order was successfully updated
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _updateIncreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            uint256[] memory orderIndexes,
            uint256 sizeDelta,
            uint256 triggerPrice,
            bool triggerAboveThreshold
        ) = abi.decode(tradeData, (uint256[], uint256, uint256, bool));

        uint256 orderIndex;

        if (isTraderWallet) {
            // calculate ratio for UserVault based on sizes of current orders
            IGmxOrderBook.IncreaseOrder memory walletOrder = _getIncreaseOrder(
                traderWallet,
                orderIndexes[0]
            );
            IGmxOrderBook.IncreaseOrder memory vaultOrder = _getIncreaseOrder(
                usersVault,
                orderIndexes[1]
            );
            ratio_ = vaultOrder.sizeDelta.mulDiv(
                ratioDenominator,
                walletOrder.sizeDelta,
                MathUpgradeable.Rounding.Down
            );

            orderIndex = orderIndexes[0]; // first for traderWallet, second for usersVault
        } else {
            // scaling for Vault execution
            sizeDelta = (sizeDelta * ratio) / ratioDenominator;
            orderIndex = orderIndexes[1]; // first for traderWallet, second for usersVault
        }

        IGmxOrderBook(gmxOrderBook).updateIncreaseOrder(
            orderIndex,
            sizeDelta,
            triggerPrice,
            triggerAboveThreshold
        );
        return (true, ratio_);
    }

    /*
    @notice Cancels exist increase order
    @param isTraderWallet The flag, 'true' if caller is TraderWallet (and it will calculate ratio for UsersVault)
    @param tradeData must contain parameters:
        orderIndexes:  the array with Wallet and Vault indexes of the exist orders to update
    @return bool - Returns 'true' if order was canceled
    @return ratio_ - Unused value
    */
    function _cancelIncreaseOrder(
        bool isTraderWallet,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        uint256[] memory orderIndexes = abi.decode(tradeData, (uint256[]));

        // default trader Wallet value
        uint256 orderIndex;
        if (isTraderWallet) {
            // value for Wallet
            orderIndex = orderIndexes[0];
        } else {
            // value for Vault
            orderIndex = orderIndexes[1];
        }

        IGmxOrderBook(gmxOrderBook).cancelIncreaseOrder(orderIndex);
        return (true, ratio_);
    }

    /*
    @notice Creates new order to close or decrease position
            Also can be used to create (partial) stop-loss or take-profit orders
    @param tradeData must contain parameters:
        indexToken:      the address of the token that was longed (or shorted)
        sizeDelta:       the USD value of the change in position size (scaled to 1e30)
        collateralToken: the collateral token address
        collateralDelta: the amount of collateral in USD value to withdraw (scaled to 1e30)
        isLong:          whether the position is a long or short
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for take-profit orders, 'false' for stop-loss orders
            in terms of Short position:
                'false' for take-profit orders', true' for stop-loss orders
    @return bool - Returns 'true' if order was successfully created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _createDecreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            address indexToken,
            uint256 sizeDelta,
            address collateralToken,
            uint256 collateralDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold
        ) = abi.decode(
                tradeData,
                (address, uint256, address, uint256, bool, uint256, bool)
            );

        // for decrease order gmx requires strict: 'msg.value > minExecutionFee'
        // thats why we need to add 1
        uint256 executionFee = IGmxOrderBook(gmxOrderBook).minExecutionFee() +
            1;
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        if (isTraderWallet) {
            // calculate ratio for UserVault based on size of opened position
            uint256 traderSize = _getPosition(
                traderWallet,
                collateralToken,
                indexToken,
                isLong
            )[0];
            uint256 vaultSize = _getPosition(
                usersVault,
                collateralToken,
                indexToken,
                isLong
            )[0];
            ratio_ = vaultSize.mulDiv(
                ratioDenominator,
                traderSize,
                MathUpgradeable.Rounding.Up
            );
        } else {
            // scaling for Vault
            uint256[] memory vaultPosition = _getPosition(
                usersVault,
                collateralToken,
                indexToken,
                isLong
            );
            uint256 positionSize = vaultPosition[0];
            uint256 positionCollateral = vaultPosition[1];

            // rounding Up and then check amounts
            sizeDelta = sizeDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            ); // value important for closing
            if (sizeDelta > positionSize) sizeDelta = positionSize;
            collateralDelta = collateralDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            );
            if (collateralDelta > positionCollateral)
                collateralDelta = positionCollateral;
        }

        (bool success, bytes memory data) = gmxOrderBook.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxOrderBook.createDecreaseOrder.selector,
                indexToken,
                sizeDelta,
                collateralToken,
                collateralDelta,
                isLong,
                triggerPrice,
                triggerAboveThreshold
            )
        );

        if (!success) {
            revert CreateDecreasePositionOrderFail(_getRevertMsg(data));
        }
        return (true, ratio_);
    }

    /*
    @notice Updates exist decrease order
    @param tradeData must contain parameters:
        orderIndexes:   the array with Wallet and Vault indexes of the exist order indexes to update
                        [0, 1]: 0 - Wallet, 1 - Vault
        collateralDelta: the amount of collateral in USD value to withdraw (scaled to 1e30)
        sizeDelta:       the USD value of the change in position size  (scaled 1e30)
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for take-profit orders, 'false' for stop-loss orders
            in terms of Short position:
                'false' for take-profit orders', true' for stop-loss orders

    @return bool - Returns 'true' if order was successfully updated
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _updateDecreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            uint256[] memory orderIndexes,
            uint256 collateralDelta,
            uint256 sizeDelta,
            uint256 triggerPrice,
            bool triggerAboveThreshold
        ) = abi.decode(tradeData, (uint256[], uint256, uint256, uint256, bool));

        uint256 orderIndex;

        if (isTraderWallet) {
            // calculate ratio for UserVault based on sizes of current orders
            IGmxOrderBook.DecreaseOrder memory walletOrder = _getDecreaseOrder(
                traderWallet,
                orderIndexes[0]
            );
            IGmxOrderBook.DecreaseOrder memory vaultOrder = _getDecreaseOrder(
                usersVault,
                orderIndexes[1]
            );
            ratio_ = vaultOrder.sizeDelta.mulDiv(
                ratioDenominator,
                walletOrder.sizeDelta,
                MathUpgradeable.Rounding.Up
            );

            orderIndex = orderIndexes[0]; // first for traderWallet, second for usersVault
        } else {
            // scaling for Vault execution
            // get current position
            IGmxOrderBook.DecreaseOrder memory vaultOrder = _getDecreaseOrder(
                usersVault,
                orderIndexes[1]
            );
            // rounding Up and then check amounts
            sizeDelta = sizeDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            ); // value important for closing
            if (sizeDelta > vaultOrder.sizeDelta)
                sizeDelta = vaultOrder.sizeDelta;
            collateralDelta = collateralDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            );
            if (collateralDelta > vaultOrder.collateralDelta)
                collateralDelta = vaultOrder.collateralDelta;

            orderIndex = orderIndexes[1]; // first for traderWallet, second for usersVault
        }

        IGmxOrderBook(gmxOrderBook).updateDecreaseOrder(
            orderIndex,
            collateralDelta,
            sizeDelta,
            triggerPrice,
            triggerAboveThreshold
        );
        return (true, ratio_);
    }

    /*
        @notice Cancels exist decrease order
        @param isTraderWallet The flag, 'true' if caller is TraderWallet (and it will calculate ratio for UsersVault)
        @param tradeData must contain parameters:
            orderIndexes:      the array with Wallet and Vault indexes of the exist orders to update
        @return bool - Returns 'true' if order was canceled
        @return ratio_ - Unused value
    */
    function _cancelDecreaseOrder(
        bool isTraderWallet,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        uint256[] memory orderIndexes = abi.decode(tradeData, (uint256[]));

        // default trader Wallet value
        uint256 orderIndex;
        if (isTraderWallet) {
            // value for Wallet
            orderIndex = orderIndexes[0];
        } else {
            // value for Vault
            orderIndex = orderIndexes[1];
        }

        IGmxOrderBook(gmxOrderBook).cancelDecreaseOrder(orderIndex);
        return (true, ratio_);
    }

    function _validateTradeTokens(
        address traderWallet,
        address collateralToken,
        address indexToken,
        bool isLong
    ) internal view returns (bool) {
        if (isLong) {
            address[] memory allowedTradeTokens = ITraderWallet(traderWallet)
                .getAllowedTradeTokens();
            uint256 length = allowedTradeTokens.length;
            for (uint256 i; i < length; ) {
                if (allowedTradeTokens[i] == indexToken) return true;
                unchecked {
                    ++i;
                }
            }
        } else {
            if (
                !ITraderWallet(traderWallet).gmxShortPairs(
                    collateralToken,
                    indexToken
                )
            ) {
                return false;
            }
            return true;
        }
        return false;
    }

    /// @dev account can't keep more than 10 orders because of expensive valuation
    ///      For gas saving check only oldest tenth order
    function _validateIncreaseOrder(
        address account
    ) internal view returns (bool) {
        uint256 latestIndex = IGmxOrderBook(gmxOrderBook).increaseOrdersIndex(
            account
        );
        if (latestIndex >= 10) {
            uint256 tenthIndex = latestIndex - 10;
            IGmxOrderBook.IncreaseOrder memory order = IGmxOrderBook(
                gmxOrderBook
            ).increaseOrders(account, tenthIndex);
            if (order.account != address(0)) {
                return false;
            }
        }
        return true;
    }

    /// @notice Updates allowance amount for token
    function _checkUpdateAllowance(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20Upgradeable(token).allowance(address(this), spender) < amount) {
            IERC20Upgradeable(token).forceApprove(spender, amount);
        }
    }

    /// @notice Helper function to track revers in call()
    function _getRevertMsg(
        bytes memory _returnData
    ) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _getPosition(
        address account,
        address collateralToken,
        address indexToken,
        bool isLong
    ) internal view returns (uint256[] memory) {
        address[] memory collaterals = new address[](1);
        collaterals[0] = collateralToken;
        address[] memory indexTokens = new address[](1);
        indexTokens[0] = indexToken;
        bool[] memory isLongs = new bool[](1);
        isLongs[0] = isLong;

        return
            IGmxReader(gmxReader).getPositions(
                address(gmxVault),
                account,
                collaterals,
                indexTokens,
                isLongs
            );
    }

    function _getIncreaseOrder(
        address account,
        uint256 index
    ) internal view returns (IGmxOrderBook.IncreaseOrder memory) {
        return IGmxOrderBook(gmxOrderBook).increaseOrders(account, index);
    }

    function _getDecreaseOrder(
        address account,
        uint256 index
    ) internal view returns (IGmxOrderBook.DecreaseOrder memory) {
        return IGmxOrderBook(gmxOrderBook).decreaseOrders(account, index);
    }

    function emergencyDecreasePosition(
        address[] calldata path,
        address indexToken,
        uint256 sizeDelta,
        bool isLong
    ) external {
        uint256 executionFee = IGmxPositionRouter(gmxPositionRouter)
            .minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();
        uint256 acceptablePrice;
        if (isLong) {
            acceptablePrice = gmxVault.getMinPrice(indexToken);
        } else {
            acceptablePrice = gmxVault.getMaxPrice(indexToken);
        }

        (bool success, bytes memory data) = gmxPositionRouter.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxPositionRouter.createDecreasePosition.selector,
                path,
                indexToken,
                0, // collateralDelta
                sizeDelta,
                isLong,
                address(this), // receiver
                acceptablePrice,
                0, // minOut
                executionFee,
                false, // withdrawETH
                address(0) // callbackTarget
            )
        );
        if (!success) {
            revert CreateDecreasePositionFail(_getRevertMsg(data));
        }
        emit CreateDecreasePosition(address(this), bytes32(data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxAdapter {
    /// @notice Swaps tokens along the route determined by the path
    /// @dev The input token is Vault's underlying
    /// @param path An array of token address to swap through
    /// @param amountIn The amount of input tokens
    /// @param minOut The minimum amount of output tokens that must be received
    /// @return boughtAmount Amount of the bought tokens
    function buy(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut
    ) external returns (uint256 boughtAmount);

    /// @notice Sells back part of  bought tokens along the route
    /// @dev The output token is Vault's underlying
    /// @param path An array of token address to swap through
    /// @param amountIn The amount of input tokens
    /// @param minOut The minimum amount of output tokens (vault't underlying) that must be received
    /// @return amount of the bought tokens
    function sell(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut
    ) external returns (uint256 amount);

    /// @notice Sells all specified tokens for Vault's underlying
    /// @dev Can be executed only by trader
    /// @param path An array of token address to swap through
    /// @param minOut The minimum amount of output tokens that must be received
    function close(
        address[] memory path,
        uint256 minOut
    ) external returns (uint256);

    /// @notice Sells all specified tokens for Vault's underlying
    /// @dev Can be executed by anyone with delay
    /// @param path An array of token address to swap through
    /// @param minOut The minimum amount of output tokens that must be received
    function forceClose(
        address[] memory path,
        uint256 minOut
    ) external returns (uint256);

    /// @notice Creates leverage long or short position order at GMX
    /// @dev Calls createIncreasePosition() in GMXPositionRouter
    function leveragePosition() external returns (uint256);

    /// @notice Create order for closing/decreasing position at GMX
    /// @dev Calls createDecreasePosition() in GMXPositionRouter
    function closePosition() external returns (uint256);

    /// @notice Create order for closing position at GMX
    /// @dev Calls createDecreasePosition() in GMXPositionRouter
    ///      Can be executed by any user
    /// @param positionId Position index for vault
    function forceClosePosition(uint256 positionId) external returns (uint256);

    /// @notice Returns data for open position
    // todo
    function getPosition(uint256) external view returns (uint256[] memory);

    struct AdapterOperation {
        uint8 operationId;
        bytes data;
    }

    /// @notice Checks if operations are allowed on adapter
    /// @param traderOperations Array of suggested trader operations
    /// @return Returns 'true' if operation is allowed on adapter
    function isOperationAllowed(
        AdapterOperation[] memory traderOperations
    ) external view returns (bool);

    /// @notice Executes array of trader operations
    /// @param traderOperations Array of trader operations
    /// @return Returns 'true' if all trades completed with success
    function executeOperation(
        AdapterOperation[] memory traderOperations
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxOrderBook {
    struct IncreaseOrder {
        address account;
        address purchaseToken;
        uint256 purchaseTokenAmount;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    struct DecreaseOrder {
        address account;
        address collateralToken;
        uint256 collateralDelta;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    function minExecutionFee() external view returns (uint256);

    function increaseOrdersIndex(
        address orderCreator
    ) external view returns (uint256);

    function increaseOrders(
        address orderCreator,
        uint256 index
    ) external view returns (IncreaseOrder memory);

    function decreaseOrdersIndex(
        address orderCreator
    ) external view returns (uint256);

    function decreaseOrders(
        address orderCreator,
        uint256 index
    ) external view returns (DecreaseOrder memory);

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function cancelSwapOrder(uint256 _orderIndex) external;

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    function executeDecreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function executeIncreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;
}

interface IGmxOrderBookReader {
    function getIncreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);

    function getDecreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);

    function getSwapOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxReader {
    function getMaxAmountIn(
        address _vault,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256);

    function getAmountOut(
        address _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256, uint256);

    function getPositions(
        address _vault,
        address _account,
        address[] memory _collateralTokens,
        address[] memory _indexTokens,
        bool[] memory _isLong
    ) external view returns (uint256[] memory);

    function getTokenBalances(
        address _account,
        address[] memory _tokens
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    function increasePositionRequests(
        bytes32 requestKey
    ) external view returns (IncreasePositionRequest memory);

    struct DecreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function decreasePositionRequests(
        bytes32 requestKey
    ) external view returns (DecreasePositionRequest memory);

    /// @notice Returns current account's increase position index
    function increasePositionsIndex(
        address account
    ) external view returns (uint256);

    /// @notice Returns current account's decrease position index
    function decreasePositionsIndex(
        address positionRequester
    ) external view returns (uint256);

    /// @notice Returns request key
    function getRequestKey(
        address account,
        uint256 index
    ) external view returns (bytes32);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external returns (bytes32);

    function cancelIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function cancelDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function minExecutionFee() external view returns (uint256);
}

interface IGmxRouter {
    function approvedPlugins(
        address user,
        address plugin
    ) external view returns (bool);

    function approvePlugin(address plugin) external;

    function denyPlugin(address plugin) external;

    function swap(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut,
        address receiver
    ) external;

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxVault {
    function whitelistedTokens(address token) external view returns (bool);

    function stableTokens(address token) external view returns (bool);

    function shortableTokens(address token) external view returns (bool);

    function getMaxPrice(address indexToken) external view returns (uint256);

    function getMinPrice(address indexToken) external view returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function isLeverageEnabled() external view returns (bool);

    function guaranteedUsd(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IAdapter {
    struct AdapterOperation {
        // id to identify what type of operation the adapter should do
        // this is a generic operation
        uint8 operationId;
        // signature of the funcion
        // abi.encodeWithSignature
        bytes data;
    }

    // receives the operation to perform in the adapter and the ratio to scale whatever needed
    // answers if the operation was successfull
    function executeOperation(
        bool,
        address,
        address,
        uint256,
        AdapterOperation memory
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBaseVault {
    function underlyingTokenAddress() external view returns (address);

    function contractsFactoryAddress() external view returns (address);

    function currentRound() external view returns (uint256);

    function afterRoundBalance() external view returns (uint256);

    function getGmxShortCollaterals() external view returns (address[] memory);

    function getGmxShortIndexTokens() external view returns (address[] memory);

    function getAllowedTradeTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IPlatformAdapter {
    struct TradeOperation {
        uint8 platformId;
        uint8 actionId;
        bytes data;
    }

    error InvalidOperation(uint8 platformId, uint8 actionId);

    function createTrade(
        TradeOperation memory tradeOperation
    ) external returns (bytes memory);

    function totalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {IBaseVault} from "./IBaseVault.sol";
import {IAdapter} from "./IAdapter.sol";

interface ITraderWallet is IBaseVault {
    function vaultAddress() external view returns (address);

    function traderAddress() external view returns (address);

    function cumulativePendingDeposits() external view returns (uint256);

    function cumulativePendingWithdrawals() external view returns (uint256);

    function lastRolloverTimestamp() external view returns (uint256);

    function gmxShortPairs(address, address) external view returns (bool);

    function gmxShortCollaterals(uint256) external view returns (address);

    function gmxShortIndexTokens(uint256) external view returns (address);

    function initialize(
        address underlyingTokenAddress,
        address traderAddress,
        address ownerAddress
    ) external;

    function setVaultAddress(address vaultAddress) external;

    function setTraderAddress(address traderAddress) external;

    function addGmxShortPairs(
        address[] calldata collateralTokens,
        address[] calldata indexTokens
    ) external;

    function addAllowedTradeTokens(address[] calldata tokens) external;

    function removeAllowedTradeToken(address token) external;

    function addProtocolToUse(uint256 protocolId) external;

    function removeProtocolToUse(uint256 protocolId) external;

    function traderDeposit(uint256 amount) external;

    function withdrawRequest(uint256 amount) external;

    function setAdapterAllowanceOnToken(
        uint256 protocolId,
        address tokenAddress,
        bool revoke
    ) external;

    function rollover() external;

    function executeOnProtocol(
        uint256 protocolId,
        IAdapter.AdapterOperation memory traderOperation,
        bool replicate
    ) external;

    function getAdapterAddressPerProtocol(
        uint256 protocolId
    ) external view returns (address);

    function isAllowedTradeToken(address token) external view returns (bool);

    function allowedTradeTokensLength() external view returns (uint256);

    function allowedTradeTokensAt(
        uint256 index
    ) external view returns (address);

    function isTraderSelectedProtocol(
        uint256 protocolId
    ) external view returns (bool);

    function traderSelectedProtocolIdsLength() external view returns (uint256);

    function traderSelectedProtocolIdsAt(
        uint256 index
    ) external view returns (uint256);

    function getTraderSelectedProtocolIds()
        external
        view
        returns (uint256[] memory);

    function getContractValuation() external view returns (uint256);
}