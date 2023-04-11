// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IController {
    /* ========== EVENTS ========== */

    event TradePairAdded(address indexed tradePair);

    event LiquidityPoolAdded(address indexed liquidityPool);

    event LiquidityPoolAdapterAdded(address indexed liquidityPoolAdapter);

    event PriceFeedAdded(address indexed priceFeed);

    event UpdatableAdded(address indexed updatable);

    event TradePairRemoved(address indexed tradePair);

    event LiquidityPoolRemoved(address indexed liquidityPool);

    event LiquidityPoolAdapterRemoved(address indexed liquidityPoolAdapter);

    event PriceFeedRemoved(address indexed priceFeed);

    event UpdatableRemoved(address indexed updatable);

    event SignerAdded(address indexed signer);

    event SignerRemoved(address indexed signer);

    event OrderExecutorAdded(address indexed orderExecutor);

    event OrderExecutorRemoved(address indexed orderExecutor);

    event SetOrderRewardOfCollateral(address indexed collateral_, uint256 reward_);

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Is trade pair registered
    function isTradePair(address tradePair) external view returns (bool);

    /// @notice Is liquidity pool registered
    function isLiquidityPool(address liquidityPool) external view returns (bool);

    /// @notice Is liquidity pool adapter registered
    function isLiquidityPoolAdapter(address liquidityPoolAdapter) external view returns (bool);

    /// @notice Is price fee adapter registered
    function isPriceFeed(address priceFeed) external view returns (bool);

    /// @notice Is contract updatable
    function isUpdatable(address contractAddress) external view returns (bool);

    /// @notice Is Signer registered
    function isSigner(address signer) external view returns (bool);

    /// @notice Is order executor registered
    function isOrderExecutor(address orderExecutor) external view returns (bool);

    /// @notice Reverts if trade pair inactive
    function checkTradePairActive(address tradePair) external view;

    /// @notice Returns order reward for collateral token
    function orderRewardOfCollateral(address collateral) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Adds the trade pair to the registry
     */
    function addTradePair(address tradePair) external;

    /**
     * @notice Adds the liquidity pool to the registry
     */
    function addLiquidityPool(address liquidityPool) external;

    /**
     * @notice Adds the liquidity pool adapter to the registry
     */
    function addLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Adds the price feed to the registry
     */
    function addPriceFeed(address priceFeed) external;

    /**
     * @notice Adds updatable contract to the registry
     */
    function addUpdatable(address) external;

    /**
     * @notice Adds signer to the registry
     */
    function addSigner(address) external;

    /**
     * @notice Adds order executor to the registry
     */
    function addOrderExecutor(address) external;

    /**
     * @notice Removes the trade pair from the registry
     */
    function removeTradePair(address tradePair) external;

    /**
     * @notice Removes the liquidity pool from the registry
     */
    function removeLiquidityPool(address liquidityPool) external;

    /**
     * @notice Removes the liquidity pool adapter from the registry
     */
    function removeLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Removes the price feed from the registry
     */
    function removePriceFeed(address priceFeed) external;

    /**
     * @notice Removes updatable from the registry
     */
    function removeUpdatable(address) external;

    /**
     * @notice Removes signer from the registry
     */
    function removeSigner(address) external;

    /**
     * @notice Removes order executor from the registry
     */
    function removeOrderExecutor(address) external;

    /**
     * @notice Sets order reward for collateral token
     */
    function setOrderRewardOfCollateral(address, uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFeeManager {
    /* ========== EVENTS ============ */

    event ReferrerFeesPaid(address indexed referrer, address indexed asset, uint256 amount, address user);

    event WhiteLabelFeesPaid(address indexed whitelabel, address indexed asset, uint256 amount, address user);

    event UpdatedReferralFee(uint256 newReferrerFee);

    event UpdatedStakersFeeAddress(address stakersFeeAddress);

    event UpdatedDevFeeAddress(address devFeeAddress);

    event UpdatedInsuranceFundFeeAddress(address insuranceFundFeeAddress);

    event SetWhitelabelFee(address indexed whitelabelAddress, uint256 feeSize);

    event SetCustomReferralFee(address indexed referrer, uint256 feeSize);

    event SpreadFees(
        address asset,
        uint256 stakersFeeAmount,
        uint256 devFeeAmount,
        uint256 insuranceFundFeeAmount,
        uint256 liquidityPoolFeeAmount,
        address user
    );

    /* ========== CORE FUNCTIONS ========== */

    function depositOpenFees(address user, address asset, uint256 amount, address whitelabelAddress) external;

    function depositCloseFees(address user, address asset, uint256 amount, address whitelabelAddress) external;

    function depositBorrowFees(address asset, uint256 amount) external;

    /* ========== VIEW FUNCTIONS ========== */

    function calculateUserOpenFeeAmount(address user, uint256 amount) external view returns (uint256);

    function calculateUserOpenFeeAmount(address user, uint256 amount, uint256 leverage)
        external
        view
        returns (uint256);

    function calculateUserExtendToLeverageFeeAmount(
        address user,
        uint256 margin,
        uint256 volume,
        uint256 targetLeverage
    ) external view returns (uint256);

    function calculateUserCloseFeeAmount(address user, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct LiquidityPoolConfig {
    address poolAddress;
    uint96 percentage;
}

interface ILiquidityPoolAdapter {
    /* ========== EVENTS ========== */

    event PayedOutLoss(address indexed tradePair, uint256 loss);

    event DepositedProfit(address indexed tradePair, uint256 profit);

    event UpdatedMaxPayoutProportion(uint256 maxPayoutProportion);

    event UpdatedLiquidityPools(LiquidityPoolConfig[] liquidityPools);

    /* ========== CORE FUNCTIONS ========== */

    function requestLossPayout(uint256 profit) external returns (uint256);

    function depositProfit(uint256 profit) external;

    function depositFees(uint256 fee) external;

    /* ========== VIEW FUNCTIONS ========== */

    function availableLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IPriceFeed
 * @notice Gets the last and previous price of an asset from a price feed
 * @dev The price must be returned with 8 decimals, following the USD convention
 */
interface IPriceFeed {
    /* ========== VIEW FUNCTIONS ========== */

    function price() external view returns (int256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IPriceFeedAggregator.sol";

/**
 * @title IPriceFeedAdapter
 * @notice Provides a way to convert an asset amount to a collateral amount and vice versa
 * Needs two PriceFeedAggregators: One for asset and one for collateral
 */
interface IPriceFeedAdapter {
    function name() external view returns (string memory);

    /* ============ DECIMALS ============ */

    function collateralDecimals() external view returns (uint256);

    /* ============ ASSET - COLLATERAL CONVERSION ============ */

    function collateralToAssetMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToAssetMax(uint256 collateralAmount) external view returns (uint256);

    function assetToCollateralMin(uint256 assetAmount) external view returns (uint256);

    function assetToCollateralMax(uint256 assetAmount) external view returns (uint256);

    /* ============ USD Conversion ============ */

    function assetToUsdMin(uint256 assetAmount) external view returns (uint256);

    function assetToUsdMax(uint256 assetAmount) external view returns (uint256);

    function collateralToUsdMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToUsdMax(uint256 collateralAmount) external view returns (uint256);

    /* ============ PRICE ============ */

    function markPriceMin() external view returns (int256);

    function markPriceMax() external view returns (int256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IPriceFeed.sol";

/**
 * @title IPriceFeedAggregator
 * @notice Aggreates two or more price feeds into min and max prices
 */
interface IPriceFeedAggregator {
    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function minPrice() external view returns (int256);

    function maxPrice() external view returns (int256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addPriceFeed(IPriceFeed) external;

    function removePriceFeed(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IController.sol";
import "../interfaces/ITradePair.sol";
import "../interfaces/IUserManager.sol";

// =============================================================
//                           STRUCTS
// =============================================================

/**
 * @notice Parameters for opening a position
 * @custom:member tradePair The trade pair to open the position on
 * @custom:member margin The amount of margin to use for the position
 * @custom:member leverage The leverage to open the position with
 * @custom:member isShort Whether the position is a short position
 * @custom:member referrer The address of the referrer or zero
 * @custom:member whitelabelAddress The address of the whitelabel or zero
 */
struct OpenPositionParams {
    address tradePair;
    uint256 margin;
    uint256 leverage;
    bool isShort;
    address referrer;
    address whitelabelAddress;
}

/**
 * @notice Parameters for closing a position
 * @custom:member tradePair The trade pair to close the position on
 * @custom:member positionId The id of the position to close
 */
struct ClosePositionParams {
    address tradePair;
    uint256 positionId;
}

/**
 * @notice Parameters for partially closing a position
 * @custom:member tradePair The trade pair to add margin to
 * @custom:member positionId The id of the position to add margin to
 * @custom:member proportion the proportion of the position to close
 * @custom:member leaveLeverageFactor the leaveLeverage / takeProfit factor
 */
struct PartiallyClosePositionParams {
    address tradePair;
    uint256 positionId;
    uint256 proportion;
}

/**
 * @notice Parameters for removing margin from a position
 * @custom:member tradePair The trade pair to add margin to
 * @custom:member positionId The id of the position to add margin to
 * @custom:member removedMargin The amount of margin to remove
 */
struct RemoveMarginFromPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 removedMargin;
}

/**
 * @notice Parameters for adding margin to a position
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member addedMargin The amount of margin to add
 */
struct AddMarginToPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 addedMargin;
}

/**
 * @notice Parameters for extending a position
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member addedMargin The amount of margin to add
 * @custom:member addedLeverage The leverage used on the addedMargin
 */
struct ExtendPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 addedMargin;
    uint256 addedLeverage;
}

/**
 * @notice Parameters for extending a position to a target leverage
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member targetLeverage the target leverage to close to
 */
struct ExtendPositionToLeverageParams {
    address tradePair;
    uint256 positionId;
    uint256 targetLeverage;
}

/**
 * @notice Constraints to constraint the opening, alteration or closing of a position
 * @custom:member deadline The deadline for the transaction
 * @custom:member minPrice a minimum price for the transaction
 * @custom:member maxPrice a maximum price for the transaction
 */
struct Constraints {
    uint256 deadline;
    int256 minPrice;
    int256 maxPrice;
}

/**
 * @notice Parameters for opening a position
 * @custom:member params The parameters for opening a position
 * @custom:member constraints The constraints for opening a position
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct OpenPositionOrder {
    OpenPositionParams params;
    Constraints constraints;
    uint256 salt;
}

/**
 * @notice Parameters for closing a position
 * @custom:member params The parameters for closing a position
 * @custom:member constraints The constraints for closing a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ClosePositionOrder {
    ClosePositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for partially closing a position
 * @custom:member params The parameters for partially closing a position
 * @custom:member constraints The constraints for partially closing a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct PartiallyClosePositionOrder {
    PartiallyClosePositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for extending a position
 * @custom:member params The parameters for extending a position
 * @custom:member constraints The constraints for extending a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ExtendPositionOrder {
    ExtendPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for extending a position to leverage
 * @custom:member params The parameters for extending a position to leverage
 * @custom:member constraints The constraints for extending a position to leverage
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ExtendPositionToLeverageOrder {
    ExtendPositionToLeverageParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters foradding margin to a position
 * @custom:member params The parameters foradding margin to a position
 * @custom:member constraints The constraints foradding margin to a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct AddMarginToPositionOrder {
    AddMarginToPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for removing margin from a position
 * @custom:member params The parameters for removing margin from a position
 * @custom:member constraints The constraints for removing margin from a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct RemoveMarginFromPositionOrder {
    RemoveMarginFromPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice UpdateData for updatable contracts like the UnlimitedPriceFeed
 * @custom:member updatableContract The address of the updatable contract
 * @custom:member data The data to update the contract with
 */
struct UpdateData {
    address updatableContract;
    bytes data;
}

/**
 * @notice Struct to store tradePair and positionId together.
 * @custom:member tradePair the address of the tradePair
 * @custom:member positionId the positionId of the position
 */
struct TradeId {
    address tradePair;
    uint96 positionId;
}

interface ITradeManager {
    /* ========== EVENTS ========== */

    event PositionOpened(address indexed tradePair, uint256 indexed id);

    event PositionClosed(address indexed tradePair, uint256 indexed id);

    event PositionPartiallyClosed(address indexed tradePair, uint256 indexed id, uint256 proportion);

    event PositionLiquidated(address indexed tradePair, uint256 indexed id);

    event PositionExtended(address indexed tradePair, uint256 indexed id, uint256 addedMargin, uint256 addedLeverage);

    event PositionExtendedToLeverage(address indexed tradePair, uint256 indexed id, uint256 targetLeverage);

    event MarginAddedToPosition(address indexed tradePair, uint256 indexed id, uint256 addedMargin);

    event MarginRemovedFromPosition(address indexed tradePair, uint256 indexed id, uint256 removedMargin);

    /* ========== CORE FUNCTIONS - LIQUIDATIONS ========== */

    function liquidatePosition(address tradePair, uint256 positionId, UpdateData[] calldata updateData) external;

    function batchLiquidatePositions(
        address[] calldata tradePairs,
        uint256[][] calldata positionIds,
        bool allowRevert,
        UpdateData[] calldata updateData
    ) external returns (bool[][] memory didLiquidate);

    /* =========== VIEW FUNCTIONS ========== */

    function detailsOfPosition(address tradePair, uint256 positionId) external view returns (PositionDetails memory);

    function positionIsLiquidatable(address tradePair, uint256 positionId) external view returns (bool);

    function canLiquidatePositions(address[] calldata tradePairs, uint256[][] calldata positionIds)
        external
        view
        returns (bool[][] memory canLiquidate);

    function canLiquidatePositionsAtPrices(
        address[] calldata tradePairs_,
        uint256[][] calldata positionIds_,
        int256[] calldata prices_
    ) external view returns (bool[][] memory canLiquidate);

    function getCurrentFundingFeeRates(address tradePair) external view returns (int256, int256);

    function totalVolumeLimitOfTradePair(address tradePair_) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IFeeManager.sol";
import "./ILiquidityPoolAdapter.sol";
import "./IPriceFeedAdapter.sol";
import "./ITradeManager.sol";
import "./IUserManager.sol";

// =============================================================
//                           STRUCTS
// =============================================================

/**
 * @notice Struct with details of a position, returned by the detailsOfPosition function
 * @custom:member id the position id
 * @custom:member margin the margin of the position
 * @custom:member volume the entry volume of the position
 * @custom:member size the size of the position
 * @custom:member leverage the size of the position
 * @custom:member isShort bool if the position is short
 * @custom:member entryPrice The entry price of the position
 * @custom:member markPrice The (current) mark price of the position
 * @custom:member bankruptcyPrice the bankruptcy price of the position
 * @custom:member equity the current net equity of the position
 * @custom:member PnL the current net PnL of the position
 * @custom:member totalFeeAmount the totalFeeAmount of the position
 * @custom:member currentVolume the current volume of the position
 */
struct PositionDetails {
    uint256 id;
    uint256 margin;
    uint256 volume;
    uint256 assetAmount;
    uint256 leverage;
    bool isShort;
    int256 entryPrice;
    int256 liquidationPrice;
    int256 currentBorrowFeeAmount;
    int256 currentFundingFeeAmount;
}

/**
 * @notice Struct with a minimum and maximum price
 * @custom:member minPrice the minimum price
 * @custom:member maxPrice the maximum price
 */
struct PricePair {
    int256 minPrice;
    int256 maxPrice;
}

interface ITradePair {
    /* ========== ENUMS ========== */

    enum PositionAlterationType {
        partiallyClose,
        extend,
        extendToLeverage,
        removeMargin,
        addMargin
    }

    /* ========== EVENTS ========== */

    event OpenedPosition(address maker, uint256 id, uint256 margin, uint256 volume, uint256 size, bool isShort);

    event ClosedPosition(uint256 id, int256 closePrice);

    event LiquidatedPosition(uint256 indexed id, address indexed liquidator);

    event AlteredPosition(
        PositionAlterationType alterationType, uint256 id, uint256 netMargin, uint256 volume, uint256 size
    );

    event UpdatedFeesOfPosition(uint256 id, int256 totalFeeAmount, uint256 lastNetMargin);

    event DepositedOpenFees(address user, uint256 amount, uint256 positionId);

    event DepositedCloseFees(address user, uint256 amount, uint256 positionId);

    event FeeOvercollected(int256 amount);

    event PayedOutCollateral(address maker, uint256 amount, uint256 positionId);

    event LiquidityGapWarning(uint256 amount);

    event RealizedPnL(
        address indexed maker,
        uint256 indexed positionId,
        int256 realizedPnL,
        int256 realizedBorrowFeeAmount,
        int256 realizedFundingFeeAmount
    );

    event UpdatedFeeIntegrals(int256 borrowFeeIntegral, int256 longFundingFeeIntegral, int256 shortFundingFeeIntegral);

    event SetTotalVolumeLimit(uint256 totalVolumeLimit);

    event DepositedBorrowFees(uint256 amount);

    event RegisteredProtocolPnL(int256 protocolPnL, uint256 payout);

    event SetBorrowFeeRate(int256 borrowFeeRate);

    event SetMaxFundingFeeRate(int256 maxFundingFeeRate);

    event SetMaxExcessRatio(int256 maxExcessRatio);

    event SetLiquidatorReward(uint256 liquidatorReward);

    event SetMinLeverage(uint128 minLeverage);

    event SetMaxLeverage(uint128 maxLeverage);

    event SetMinMargin(uint256 minMargin);

    event SetVolumeLimit(uint256 volumeLimit);

    event SetFeeBufferFactor(int256 feeBufferFactor);

    event SetTotalAssetAmountLimit(uint256 totalAssetAmountLimit);

    event SetPriceFeedAdapter(address priceFeedAdapter);

    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function collateral() external view returns (IERC20);

    function detailsOfPosition(uint256 positionId) external view returns (PositionDetails memory);

    function priceFeedAdapter() external view returns (IPriceFeedAdapter);

    function liquidityPoolAdapter() external view returns (ILiquidityPoolAdapter);

    function userManager() external view returns (IUserManager);

    function feeManager() external view returns (IFeeManager);

    function tradeManager() external view returns (ITradeManager);

    function positionIsLiquidatable(uint256 positionId) external view returns (bool);

    function positionIsLiquidatableAtPrice(uint256 positionId, int256 price) external view returns (bool);

    function getCurrentFundingFeeRates() external view returns (int256, int256);

    function getCurrentPrices() external view returns (int256, int256);

    function positionIsShort(uint256) external view returns (bool);

    function collateralToPriceMultiplier() external view returns (uint256);

    /* ========== GENERATED VIEW FUNCTIONS ========== */

    function feeIntegral() external view returns (int256, int256, int256, int256, int256, int256, uint256);

    function liquidatorReward() external view returns (uint256);

    function maxLeverage() external view returns (uint128);

    function minLeverage() external view returns (uint128);

    function minMargin() external view returns (uint256);

    function volumeLimit() external view returns (uint256);

    function totalVolumeLimit() external view returns (uint256);

    function positionStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    function overcollectedFees() external view returns (int256);

    function feeBuffer() external view returns (int256, int256);

    function positionIdToWhiteLabel(uint256) external view returns (address);

    /* ========== CORE FUNCTIONS - POSITIONS ========== */

    function openPosition(address maker, uint256 margin, uint256 leverage, bool isShort, address whitelabelAddress)
        external
        returns (uint256 positionId);

    function closePosition(address maker, uint256 positionId) external;

    function addMarginToPosition(address maker, uint256 positionId, uint256 margin) external;

    function removeMarginFromPosition(address maker, uint256 positionId, uint256 removedMargin) external;

    function partiallyClosePosition(address maker, uint256 positionId, uint256 proportion) external;

    function extendPosition(address maker, uint256 positionId, uint256 addedMargin, uint256 addedLeverage) external;

    function extendPositionToLeverage(address maker, uint256 positionId, uint256 targetLeverage) external;

    function liquidatePosition(address liquidator, uint256 positionId) external;

    /* ========== CORE FUNCTIONS - FEES ========== */

    function syncPositionFees() external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initialize(
        string memory name,
        IERC20Metadata collateral,
        IPriceFeedAdapter priceFeedAdapter,
        ILiquidityPoolAdapter liquidityPoolAdapter
    ) external;

    function setBorrowFeeRate(int256 borrowFeeRate) external;

    function setMaxFundingFeeRate(int256 fee) external;

    function setMaxExcessRatio(int256 maxExcessRatio) external;

    function setLiquidatorReward(uint256 liquidatorReward) external;

    function setMinLeverage(uint128 minLeverage) external;

    function setMaxLeverage(uint128 maxLeverage) external;

    function setMinMargin(uint256 minMargin) external;

    function setVolumeLimit(uint256 volumeLimit) external;

    function setFeeBufferFactor(int256 feeBufferAmount) external;

    function setTotalVolumeLimit(uint256 totalVolumeLimit) external;

    function setPriceFeedAdapter(IPriceFeedAdapter priceFeedAdapter) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IUnlimitedOwner
 */
interface IUnlimitedOwner {
    function owner() external view returns (address);

    function isUnlimitedOwner(address) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/// @notice Enum for the different fee tiers
enum Tier {
    ZERO,
    ONE,
    TWO,
    THREE,
    FOUR,
    FIVE,
    SIX
}

interface IUserManager {
    /* ========== EVENTS ========== */

    event FeeSizeUpdated(uint256 indexed feeIndex, uint256 feeSize);

    event FeeVolumeUpdated(uint256 indexed feeIndex, uint256 feeVolume);

    event UserVolumeAdded(address indexed user, address indexed tradePair, uint256 volume);

    event UserManualTierUpdated(address indexed user, Tier tier, uint256 validUntil);

    event UserReferrerAdded(address indexed user, address referrer);

    /* =========== CORE FUNCTIONS =========== */

    function addUserVolume(address user, uint40 volume) external;

    function setUserReferrer(address user, address referrer) external;

    function setUserManualTier(address user, Tier tier, uint32 validUntil) external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setFeeVolumes(uint256[] calldata feeIndexes, uint32[] calldata feeVolumes) external;

    function setFeeSizes(uint256[] calldata feeIndexes, uint8[] calldata feeSizes) external;

    /* ========== VIEW FUNCTIONS ========== */

    function getUserFee(address user) external view returns (uint256);

    function getUserReferrer(address user) external view returns (address referrer);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./../shared/Constants.sol";

/* ========== STRUCTS ========== */
/**
 * @notice Struct to store the fee buffer for a given trade pair
 * @custom:member currentBufferAmount Currently buffered fee amount
 * @custom:member bufferFactor Buffer Factor nominated in BUFFER_MULTIPLIER
 */
struct FeeBuffer {
    int256 currentBufferAmount;
    int256 bufferFactor;
}

/**
 * @title FeeBuffer
 * @notice Stores and operates on the fee buffer. Calculates possible fee losses.
 * @dev This contract is a library and should be used by a contract that implements the ITradePair interface
 */
library FeeBufferLib {
    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice clears fee buffer for a given position. Either ´remainingBuffer´ is positive OR ´requestLoss´ is positive.
     * When ´remainingBuffer´ is positive, then ´remainingMargin´ could also be possible.
     * @param _margin the margin of the position
     * @param _borrowFeeAmount amount of borrow fee
     * @param _fundingFeeAmount amount of funding fee
     * @return remainingMargin the _margin of the position after clearing the buffer and paying fees
     * @return remainingBuffer remaining amount that needs to be transferred to the fee manager
     * @return requestLoss the amount of loss that needs to be requested from the liquidity pool
     */
    function clearBuffer(FeeBuffer storage _self, uint256 _margin, int256 _borrowFeeAmount, int256 _fundingFeeAmount)
        public
        returns (uint256 remainingMargin, uint256 remainingBuffer, uint256 requestLoss)
    {
        // calculate fee loss
        int256 buffered = _borrowFeeAmount * _self.bufferFactor / BUFFER_MULTIPLIER;
        int256 collected = _borrowFeeAmount - buffered;
        int256 overcollected = _borrowFeeAmount + _fundingFeeAmount - int256(_margin);
        int256 missing = overcollected - buffered;

        // Check if the buffer amount is big enough
        if (missing < 0) {
            // No overollection, no fees missing (close or liquidate bc. loss)
            if (-1 * missing > buffered) {
                remainingBuffer = uint256(buffered);

                remainingMargin = uint256(int256(_margin) - _fundingFeeAmount - (collected + int256(remainingBuffer)));
                // Buffer covers missing fees (early liquidation bc. fees)
            } else {
                remainingBuffer = uint256(-1 * missing);
            }
            // Buffer does not cover missing fees (late liquidation bc. fees)
        } else if (missing > 0) {
            // If fees are missing, request them as loss
            requestLoss = uint256(missing);
        }

        // update fee buffer
        _self.currentBufferAmount -= buffered;

        return (remainingMargin, remainingBuffer, requestLoss);
    }

    /**
     * @notice Takes buffer amount from the provided amount and returns reduced amount.
     * @param _amount the amount to take buffer from
     * @return amount the amount after taking buffer
     */
    function takeBufferFrom(FeeBuffer storage _self, uint256 _amount) public returns (uint256) {
        int256 newBufferAmount = int256(_amount) * _self.bufferFactor / BUFFER_MULTIPLIER;
        _self.currentBufferAmount += newBufferAmount;
        return _amount - uint256(newBufferAmount);
    }
}

using FeeBufferLib for FeeBuffer;

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./FundingFee.sol";
import "./../shared/Constants.sol";

/* ========== STRUCTS ========== */
/**
 * @notice Struct to store the fee integral values
 * @custom:member longFundingFeeIntegral long funding fee gets paid to short positions
 * @custom:member shortFundingFeeIntegral short funding fee gets paid to long positions
 * @custom:member fundingFeeRate max rate of funding fee
 * @custom:member maxExcessRatio max ratio of long to short positions at which funding fees are capped. Denominated in FEE_MULTIPLIER
 * @custom:member borrowFeeIntegral borrow fee gets paid to the liquidity pools
 * @custom:member borrowFeeRate Rate of borrow fee, measured in fee basis points (FEE_BPS_MULTIPLIER) per hour
 * @custom:member lastUpdatedAt last time fee integral was updated
 */
struct FeeIntegral {
    int256 longFundingFeeIntegral;
    int256 shortFundingFeeIntegral;
    int256 fundingFeeRate;
    int256 maxExcessRatio;
    int256 borrowFeeIntegral;
    int256 borrowFeeRate;
    uint256 lastUpdatedAt;
}

/**
 * @title FeeIntegral
 * @notice Provides data structures and functions for calculating the fee integrals
 * @dev This contract is a library and should be used by a contract that implements the ITradePair interface
 */
library FeeIntegralLib {
    using FeeIntegralLib for FeeIntegral;

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice update fee integrals
     * @dev Update needs to happen before volumes change.
     */
    function update(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume) external {
        // Update integrals for the period since last update
        uint256 elapsedTime = block.timestamp - _self.lastUpdatedAt;
        if (elapsedTime > 0) {
            _self._updateBorrowFeeIntegral();
            _self._updateFundingFeeIntegrals(longVolume, shortVolume);
        }
        _self.lastUpdatedAt = block.timestamp;
    }

    /**
     * @notice get current funding fee integrals
     * @param longVolume long position volume
     * @param shortVolume short position volume
     * @return longFundingFeeIntegral long funding fee integral
     * @return shortFundingFeeIntegral short funding fee integral
     */
    function getCurrentFundingFeeIntegrals(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume)
        external
        view
        returns (int256, int256)
    {
        (int256 elapsedLongIntegral, int256 elapsedShortIntegral) =
            _self._getElapsedFundingFeeIntegrals(longVolume, shortVolume);
        int256 longIntegral = _self.longFundingFeeIntegral + elapsedLongIntegral;
        int256 shortIntegral = _self.shortFundingFeeIntegral + elapsedShortIntegral;
        return (longIntegral, shortIntegral);
    }

    /**
     * @notice get current borrow fee integral
     * @dev calculated by stored integral + elapsed integral
     * @return borrowFeeIntegral current borrow fee integral
     */
    function getCurrentBorrowFeeIntegral(FeeIntegral storage _self) external view returns (int256) {
        return _self.borrowFeeIntegral + _self._getElapsedBorrowFeeIntegral();
    }

    /**
     * @notice get the borrow fee integral since last update
     * @return borrowFeeIntegral borrow fee integral since last update
     */
    function getElapsedBorrowFeeIntegral(FeeIntegral storage _self) external view returns (int256) {
        return _self._getElapsedBorrowFeeIntegral();
    }

    /**
     * @notice Calculates the current funding fee rates
     * @param longVolume long position volume
     * @param shortVolume short position volume
     * @return longFundingFeeRate long funding fee rate
     * @return shortFundingFeeRate short funding fee rate
     */
    function getCurrentFundingFeeRates(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume)
        external
        view
        returns (int256, int256)
    {
        return FundingFee.getFundingFeeRates({
            longVolume: longVolume,
            shortVolume: shortVolume,
            maxRatio: _self.maxExcessRatio,
            maxFeeRate: _self.fundingFeeRate
        });
    }

    /**
     * ========== INTERNAL FUNCTIONS ==========
     */

    /**
     * @notice update the integral of borrow fee calculated since last update
     */
    function _updateBorrowFeeIntegral(FeeIntegral storage _self) internal {
        _self.borrowFeeIntegral += _self._getElapsedBorrowFeeIntegral();
    }

    /**
     * @notice get the borrow fee integral since last update
     * @return borrowFeeIntegral borrow fee integral since last update
     */
    function _getElapsedBorrowFeeIntegral(FeeIntegral storage _self) internal view returns (int256) {
        uint256 elapsedTime = block.timestamp - _self.lastUpdatedAt;
        return (int256(elapsedTime) * _self.borrowFeeRate) / 1 hours;
    }

    /**
     * @notice update the integrals of funding fee calculated since last update
     * @dev the integrals can be negative, when one side pays the other.
     * longVolume and shortVolume can also be sizes, the ratio is important.
     * @param longVolume volume of long positions
     * @param shortVolume volume of short positions
     */
    function _updateFundingFeeIntegrals(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume) internal {
        (int256 elapsedLongIntegral, int256 elapsedShortIntegral) =
            _self._getElapsedFundingFeeIntegrals(longVolume, shortVolume);
        _self.longFundingFeeIntegral += elapsedLongIntegral;
        _self.shortFundingFeeIntegral += elapsedShortIntegral;
    }

    /**
     * @notice get the integral of funding fee calculated since last update
     * @dev the integrals can be negative, when one side pays the other.
     * longVolume and shortVolume can also be sizes, the ratio is important.
     * @param longVolume volume of long positions
     * @param shortVolume volume of short positions
     * @return elapsedLongIntegral integral of long funding fee
     * @return elapsedShortIntegral integral of short funding fee
     */
    function _getElapsedFundingFeeIntegrals(FeeIntegral storage _self, uint256 longVolume, uint256 shortVolume)
        internal
        view
        returns (int256, int256)
    {
        (int256 longFee, int256 shortFee) = FundingFee.getFundingFeeRates({
            longVolume: longVolume,
            shortVolume: shortVolume,
            maxRatio: _self.maxExcessRatio,
            maxFeeRate: _self.fundingFeeRate
        });
        uint256 elapsedTime = block.timestamp - _self.lastUpdatedAt;
        int256 longIntegral = (longFee * int256(elapsedTime)) / 1 hours;
        int256 shortIntegral = (shortFee * int256(elapsedTime)) / 1 hours;
        return (longIntegral, shortIntegral);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./../shared/Constants.sol";

/**
 * @title FundingFeeLib
 * @notice Library for calculating funding fees
 * @dev Funding fees are the "long pays short" fees. They are calculated based on the excess volume of long positions over short positions or vice-versa.
 * Funding fees are calculated using a curve function. The curve function resembles a logarithmic growth function, but is easier to calculate.
 */

library FundingFee {
    /* ========== CONSTANTS ========== */

    // For the readability of the maths functions, we define the constants below.
    // ONE is defined for readability.
    int256 constant ONE = FEE_MULTIPLIER;
    int256 constant TWO = 2 * ONE;
    // this is a percentage multiplier
    int256 constant PERCENT = ONE / 100;

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice calculates the fee rates for long and short positions.
     * @param longVolume the volume of long positions
     * @param shortVolume the volume of short positions
     * @param maxRatio the maximum ratio of excess volume to deficient volume. All excess volume above this ratio will be ignored.
     * @param maxFeeRate the maximum fee rate that can be charged.
     * @return longFeeRate (int256) the fee for long positions.
     * @return shortFeeRate (int256) the fee for short positions.
     */
    function getFundingFeeRates(uint256 longVolume, uint256 shortVolume, int256 maxRatio, int256 maxFeeRate)
        public
        pure
        returns (int256 longFeeRate, int256 shortFeeRate)
    {
        if (longVolume == shortVolume) {
            return (0, 0);
        }

        uint256 excessVolume;
        uint256 deficientVolume;
        bool isLongExcess;

        // Assign if long or short is excess
        if (longVolume > shortVolume) {
            excessVolume = longVolume;
            deficientVolume = shortVolume;
            isLongExcess = true;

            // edge case: when short volume is 0, long has to pay the max fee
            if (shortVolume == 0) {
                return (maxFeeRate, 0);
            }
        } else {
            excessVolume = shortVolume;
            deficientVolume = longVolume;
            isLongExcess = false;

            // edge case: when long volume is 0, short has to pay the max fee
            if (longVolume == 0) {
                return (0, maxFeeRate);
            }
        }

        // Do the actual fee calculation
        int256 normalizedVolumeRatio = normalizedExcessRatio(excessVolume, deficientVolume, maxRatio);
        int256 normalizedFeeRate = curve(normalizedVolumeRatio);
        int256 feeRate = calculateFundingFee(normalizedFeeRate, maxFeeRate);
        int256 rewardRate = calculateFundingFeeReward(excessVolume, deficientVolume, feeRate);

        // Assign the fees to the correct position
        if (isLongExcess) {
            longFeeRate = int256(feeRate);
            shortFeeRate = rewardRate;
        } else {
            longFeeRate = rewardRate;
            shortFeeRate = int256(feeRate);
        }

        return (longFeeRate, shortFeeRate);
    }

    /**
     * @notice calculates the normalized excess volume
     * @param excessVolume the excess volume
     * @param deficientVolume the deficient volume
     * @param maxRatio the maximum ratio of excess volume to deficient volume. Denominated in ONE. When the ratio is higher than this value, the return value is ONE.
     * @return the normalized excess volume to be used in the curve. Denominated like ONE.
     */
    function normalizedExcessRatio(uint256 excessVolume, uint256 deficientVolume, int256 maxRatio)
        public
        pure
        onlyPositiveVolumeExcess(excessVolume, deficientVolume)
        returns (int256)
    {
        // When maxRatio is smaller than ONE, it is considered an error. Return ONE
        if (maxRatio <= ONE) {
            return ONE;
        }

        // When the excess volume is equal to the deficient volume, the normalizedExcessRatio is 0
        if (excessVolume == deficientVolume) {
            return 0;
        }

        int256 ratio = ONE * int256(excessVolume) / int256(deficientVolume);

        // When the ratio is higher than the max ratio, the normalized excess volume is ONE
        if (ratio >= maxRatio) {
            return ONE;
        }

        // When the ratio is lower than the max ratio, the ratio gets normalized to a range from 0 to ONE
        return ONE * (ratio - ONE) / (maxRatio - ONE);
    }

    /**
     * @notice Curve to calculate the balance fee
     * The curve resembles a logarithmic growth function, but is easier to calculate.
     * Function starts at zero and goes to one.
     * Function has a soft ease-in-ease-out.
     *
     *
     * 1|-------------------
     * .|           ~°°°
     * .|        +´
     * .|       /
     * .|    +´
     * .|_~°°
     * 0+-------------------
     * #0                  1
     *
     * Function:
     * y = 0; x <= 0;
     * y = ((2x)**2)/2; 0 <= x < 0.5;
     * y = (2-(2-2x)**2)/2; 0.5 <= x < 1;
     * y = 1; 1 <= x;
     *
     * Represents concave function starting at (0,0) and reaching the max value
     * and a slope of 0 at (1/1)
     * @param x needs to have decimals of PERCENT
     * @return y
     */

    function curve(int256 x) public pure returns (int256 y) {
        // x <= 0
        // y = 0
        if (x <= 0) {
            return 0;
        }
        // 0 < x < 0.5
        // y = ((2x)**2)/2
        else if (x < ONE / 2) {
            return ((2 * x) ** 2) / 2 / ONE;
        }
        // 0.5 <= x < 1
        // y = (2-(2-2x)**2)/2
        else if (x < ONE) {
            return (TWO - ((TWO - 2 * x) ** 2) / ONE) / 2;
        }

        // x >= 1
        // y = 1
        return ONE;
    }

    /**
     * @notice Calculates the funding fee
     * @param normalizedFeeValue the normalized fee value between 0 and ONE. Denominated in PERCENT.
     * @param maxFee the maximum fee. Denominated in PERCENT
     * @return fee the funding fee. Denominated in PERCENT
     */
    function calculateFundingFee(int256 normalizedFeeValue, int256 maxFee) public pure returns (int256 fee) {
        if (normalizedFeeValue > ONE) {
            return maxFee;
        }
        return normalizedFeeValue * maxFee / ONE;
    }

    /**
     * @notice calculates the funding reward. The funding reward is the fee that is paid to the "other" position.
     * @dev It is calculated by distributing the total collected funding fee to the "other" positions based on their share of the total volume.
     * @param excessVolume the excess volume
     * @param deficientVolume the deficient volume
     * @param fee the relative fee for the excess volume. Denominated in PERCENT
     */
    function calculateFundingFeeReward(uint256 excessVolume, uint256 deficientVolume, int256 fee)
        public
        pure
        onlyPositiveVolumeExcess(excessVolume, deficientVolume)
        returns (int256)
    {
        if (deficientVolume == 0) {
            return 0;
        }

        return -1 * int256(fee) * int256(excessVolume) / int256(deficientVolume);
    }

    /**
     * @notice checks if excessVolume is higher than deficientVolume
     * @param excessVolume the excess volume
     * @param deficientVolume the deficient volume
     */
    modifier onlyPositiveVolumeExcess(uint256 excessVolume, uint256 deficientVolume) {
        require(
            excessVolume >= deficientVolume,
            "FundingFee::onlyPositiveVolumeExcess: Excess volume must be higher than deficient volume"
        );
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "./../shared/Constants.sol";

interface ITradePair_Multiplier {
    function collateralToPriceMultiplier() external view returns (uint256);
}

/* ========== STRUCTS ========== */
/**
 * @notice Struct to store details of a position
 * @custom:member margin the margin of the position
 * @custom:member volume the volume of the position
 * @custom:member assetAmount the underlying amount of assets. Normalized to  ASSET_DECIMALS
 * @custom:member pastBorrowFeeIntegral the integral of borrow fee at the moment of opening or last fee update
 * @custom:member lastBorrowFeeAmount the last borrow fee amount at the moment of last fee update
 * @custom:member pastFundingFeeIntegral the integral of funding fee at the moment of opening or last fee update
 * @custom:member lastFundingFeeAmount the last funding fee amount at the moment of last fee update
 * @custom:member collectedFundingFeeAmount the total collected funding fee amount, to add up the total funding fee amount
 * @custom:member lastFeeCalculationAt moment of the last fee update
 * @custom:member openedAt moment of the position opening
 * @custom:member isShort bool if the position is short
 * @custom:member owner the owner of the position
 * @custom:member lastAlterationBlock the last block where the position was altered or opened
 */
struct Position {
    uint256 margin;
    uint256 volume;
    uint256 assetAmount;
    int256 pastBorrowFeeIntegral;
    int256 lastBorrowFeeAmount;
    int256 collectedBorrowFeeAmount;
    int256 pastFundingFeeIntegral;
    int256 lastFundingFeeAmount;
    int256 collectedFundingFeeAmount;
    uint48 lastFeeCalculationAt;
    uint48 openedAt;
    bool isShort;
    address owner;
    uint40 lastAlterationBlock;
}

/**
 * @title Position Maths
 * @notice Provides financial maths for leveraged positions.
 */
library PositionMaths {
    /**
     * External Functions
     */

    /**
     * @notice Price at entry level
     * @return price int
     */
    function entryPrice(Position storage self) public view returns (int256) {
        return self._entryPrice();
    }

    function _entryPrice(Position storage self) internal view returns (int256) {
        return int256(self.volume * collateralToPriceMultiplier() * ASSET_MULTIPLIER / self.assetAmount);
    }

    /**
     * @notice Leverage at entry level
     * @return leverage uint
     */
    function entryLeverage(Position storage self) public view returns (uint256) {
        return self._entryLeverage();
    }

    function _entryLeverage(Position storage self) internal view returns (uint256) {
        return self.volume * LEVERAGE_MULTIPLIER / self.margin;
    }

    /**
     * @notice Last net leverage is calculated with the last net margin, which is entry margin minus last total fees. Margin of zero means position is liquidatable.
     * @return net leverage uint. When margin is less than zero, leverage is max uint256
     * @dev this value is only valid when the position got updated at the same block
     */
    function lastNetLeverage(Position storage self) public view returns (uint256) {
        return self._lastNetLeverage();
    }

    function _lastNetLeverage(Position storage self) internal view returns (uint256) {
        uint256 lastNetMargin_ = self._lastNetMargin();
        if (lastNetMargin_ == 0) {
            return type(uint256).max;
        }
        return self.volume * LEVERAGE_MULTIPLIER / lastNetMargin_;
    }

    /**
     * @notice Current Net Margin, which is entry margin minus current total fees. Margin of zero means position is liquidatable.
     * @return net margin int
     */
    function currentNetMargin(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
        public
        view
        returns (uint256)
    {
        return self._currentNetMargin(currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentNetMargin(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
        internal
        view
        returns (uint256)
    {
        int256 actualCurrentMargin =
            int256(self.margin) - self._currentTotalFeeAmount(currentBorrowFeeIntegral, currentFundingFeeIntegral);
        return actualCurrentMargin > 0 ? uint256(actualCurrentMargin) : 0;
    }

    /**
     * @notice Returns the last net margin, calculated at the moment of last fee update
     * @return last net margin uint. Can be zero.
     * @dev this value is only valid when the position got updated at the same block
     * It is a convenience function because the caller does not need to provice fee integrals
     */
    function lastNetMargin(Position storage self) internal view returns (uint256) {
        return self._lastNetMargin();
    }

    function _lastNetMargin(Position storage self) internal view returns (uint256) {
        int256 _lastMargin = int256(self.margin) - self.lastBorrowFeeAmount - self.lastFundingFeeAmount;
        return _lastMargin > 0 ? uint256(_lastMargin) : 0;
    }

    /**
     * @notice Current Net Leverage, which is entry volume divided by current net margin
     * @return current net leverage
     */
    function currentNetLeverage(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) public view returns (uint256) {
        return self._currentNetLeverage(currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentNetLeverage(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) internal view returns (uint256) {
        uint256 currentNetMargin_ = self._currentNetMargin(currentBorrowFeeIntegral, currentFundingFeeIntegral);
        if (currentNetMargin_ == 0) {
            return type(uint256).max;
        }
        return self.volume * LEVERAGE_MULTIPLIER / currentNetMargin_;
    }

    /**
     * @notice Liquidation price takes into account fee-reduced collateral and absolute maintenance margin
     * @return liquidationPrice int
     */
    function liquidationPrice(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral,
        uint256 maintenanceMargin
    ) public view returns (int256) {
        return self._liquidationPrice(currentBorrowFeeIntegral, currentFundingFeeIntegral, maintenanceMargin);
    }

    function _liquidationPrice(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral,
        uint256 maintenanceMargin
    ) internal view returns (int256) {
        // Reduce current margin by liquidator reward
        int256 liquidatableMargin = int256(self._currentNetMargin(currentBorrowFeeIntegral, currentFundingFeeIntegral))
            - int256(maintenanceMargin);

        // If margin is zero, position is liquidatable by fee reduction alone.
        // Return entry price
        if (liquidatableMargin <= 0) {
            return self._entryPrice();
        }

        // Return entryPrice +/- entryPrice / leverage
        // Where leverage = volume / liquidatableMargin
        return self._entryPrice()
            - self._entryPrice() * int256(LEVERAGE_MULTIPLIER) * self._shortMultiplier() * liquidatableMargin
                / int256(self.volume * LEVERAGE_MULTIPLIER);
    }

    function _shortMultiplier(Position storage self) internal view returns (int256) {
        if (self.isShort) {
            return int256(-1);
        } else {
            return int256(1);
        }
    }

    /**
     * @notice Current Volume is the current mark price times the asset amount (this is not the current value)
     * @param currentPrice int current mark price
     * @return currentVolume uint
     */
    function currentVolume(Position storage self, int256 currentPrice) public view returns (uint256) {
        return self._currentVolume(currentPrice);
    }

    function _currentVolume(Position storage self, int256 currentPrice) internal view returns (uint256) {
        return self.assetAmount * uint256(currentPrice) / ASSET_MULTIPLIER / collateralToPriceMultiplier();
    }

    /**
     * @notice Current Profit and Losses (without fees)
     * @param currentPrice int current mark price
     * @return currentPnL int
     */
    function currentPnL(Position storage self, int256 currentPrice) public view returns (int256) {
        return self._currentPnL(currentPrice);
    }

    function _currentPnL(Position storage self, int256 currentPrice) internal view returns (int256) {
        return (int256(self._currentVolume(currentPrice)) - int256(self.volume)) * self._shortMultiplier();
    }

    /**
     * @notice Current Value is the derived value that takes into account entry volume and PNL
     * @dev This value is shown on the UI. It normalized the differences of LONG/SHORT into a single value
     * @param currentPrice int current mark price
     * @return currentValue int
     */
    function currentValue(Position storage self, int256 currentPrice) public view returns (int256) {
        return self._currentValue(currentPrice);
    }

    function _currentValue(Position storage self, int256 currentPrice) internal view returns (int256) {
        return int256(self.volume) + self._currentPnL(currentPrice);
    }

    /**
     * @notice Current Equity (without fees)
     * @param currentPrice int current mark price
     * @return currentEquity int
     */
    function currentEquity(Position storage self, int256 currentPrice) public view returns (int256) {
        return self._currentEquity(currentPrice);
    }

    function _currentEquity(Position storage self, int256 currentPrice) internal view returns (int256) {
        return self._currentPnL(currentPrice) + int256(self.margin);
    }

    function currentTotalFeeAmount(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) public view returns (int256) {
        return self._currentTotalFeeAmount(currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentTotalFeeAmount(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) internal view returns (int256) {
        return self._currentBorrowFeeAmount(currentBorrowFeeIntegral)
            + self._currentFundingFeeAmount(currentFundingFeeIntegral);
    }

    /**
     * @notice Current Amount of Funding Fee, accumulated over time
     * @param currentFundingFeeIntegral uint current funding fee integral
     * @return currentFundingFeeAmount int
     */
    function currentFundingFeeAmount(Position storage self, int256 currentFundingFeeIntegral)
        public
        view
        returns (int256)
    {
        return self._currentFundingFeeAmount(currentFundingFeeIntegral);
    }

    function _currentFundingFeeAmount(Position storage self, int256 currentFundingFeeIntegral)
        internal
        view
        returns (int256)
    {
        int256 elapsedFundingFeeAmount =
            (currentFundingFeeIntegral - self.pastFundingFeeIntegral) * int256(self.volume) / FEE_MULTIPLIER;
        return self.lastFundingFeeAmount + elapsedFundingFeeAmount;
    }

    /**
     * @notice Current amount of borrow fee, accumulated over time
     * @param currentBorrowFeeIntegral uint current fee integral
     * @return currentBorrowFeeAmount int
     */
    function currentBorrowFeeAmount(Position storage self, int256 currentBorrowFeeIntegral)
        public
        view
        returns (int256)
    {
        return self._currentBorrowFeeAmount(currentBorrowFeeIntegral);
    }

    function _currentBorrowFeeAmount(Position storage self, int256 currentBorrowFeeIntegral)
        internal
        view
        returns (int256)
    {
        return self.lastBorrowFeeAmount
            + (currentBorrowFeeIntegral - self.pastBorrowFeeIntegral) * int256(self.volume) / FEE_MULTIPLIER;
    }

    /**
     * @notice Current Net PnL, including fees
     * @param currentPrice int current mark price
     * @param currentBorrowFeeIntegral uint current fee integral
     * @param currentFundingFeeIntegral uint current funding fee integral
     * @return currentNetPnL int
     */
    function currentNetPnL(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) public view returns (int256) {
        return self._currentNetPnL(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentNetPnL(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) internal view returns (int256) {
        return self._currentPnL(currentPrice)
            - int256(self._currentTotalFeeAmount(currentBorrowFeeIntegral, currentFundingFeeIntegral));
    }

    /**
     * @notice Current Net Equity, including fees
     * @param currentPrice int current mark price
     * @param currentBorrowFeeIntegral uint current fee integral
     * @param currentFundingFeeIntegral uint current funding fee integral
     * @return currentNetEquity int
     */
    function currentNetEquity(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) public view returns (int256) {
        return self._currentNetEquity(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentNetEquity(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) internal view returns (int256) {
        return
            self._currentNetPnL(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral) + int256(self.margin);
    }

    /**
     * @notice Determines if the position can be liquidated
     * @param currentPrice int current mark price
     * @param currentBorrowFeeIntegral uint current fee integral
     * @param currentFundingFeeIntegral uint current funding fee integral
     * @param absoluteMaintenanceMargin absolute amount of maintenance margin.
     * @return isLiquidatable bool
     * @dev A position is liquidatable, when either the margin or the current equity
     * falls under or equals the absolute maintenance margin
     */
    function isLiquidatable(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral,
        uint256 absoluteMaintenanceMargin
    ) public view returns (bool) {
        return self._isLiquidatable(
            currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral, absoluteMaintenanceMargin
        );
    }

    function _isLiquidatable(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral,
        uint256 absoluteMaintenanceMargin
    ) internal view returns (bool) {
        // If margin does not cover fees, position is liquidatable.
        if (
            int256(self.margin)
                <= int256(absoluteMaintenanceMargin)
                    + int256(self._currentTotalFeeAmount(currentBorrowFeeIntegral, currentFundingFeeIntegral))
        ) {
            return true;
        }
        // Otherwise, a position is liquidatable if equity is below the absolute maintenance margin.
        return self._currentNetEquity(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral)
            <= int256(absoluteMaintenanceMargin);
    }

    /* ========== POSITION ALTERATIONS ========== */

    /**
     * @notice Partially closes a position
     * @param currentPrice int current mark price
     * @param closeProportion the share of the position that should be closed
     */
    function partiallyClose(Position storage self, int256 currentPrice, uint256 closeProportion)
        public
        returns (int256)
    {
        return self._partiallyClose(currentPrice, closeProportion);
    }

    /**
     * @dev Partially closing works as follows:
     *
     * 1. Sell a share of the position, and use the proceeds to either:
     * 2.a) Get a payout and by this, leave the leverage as it is
     * 2.b) "Buy" new margin and by this decrease the leverage
     * 2.c) a mixture of 2.a) and 2.b)
     */
    function _partiallyClose(Position storage self, int256 currentPrice, uint256 closeProportion)
        internal
        returns (int256)
    {
        require(
            closeProportion < PERCENTAGE_MULTIPLIER,
            "PositionMaths::_partiallyClose: cannot partially close full position"
        );

        Position memory delta;
        // Close a proportional share of the position
        delta.margin = self._lastNetMargin() * closeProportion / PERCENTAGE_MULTIPLIER;
        delta.volume = self.volume * closeProportion / PERCENTAGE_MULTIPLIER;
        delta.assetAmount = self.assetAmount * closeProportion / PERCENTAGE_MULTIPLIER;

        // The realized PnL is the change in volume minus the price of the changes in size at LONG
        // And the inverse of that at SHORT
        // @dev At a long position, the delta of size is sold to give back the volume
        // @dev At a short position, the volume delta is used, to "buy" the change of size (and give it back)
        int256 priceOfSizeDelta =
            currentPrice * int256(delta.assetAmount) / int256(collateralToPriceMultiplier()) / int256(ASSET_MULTIPLIER);
        int256 realizedPnL = (priceOfSizeDelta - int256(delta.volume)) * self._shortMultiplier();

        int256 payout = int256(delta.margin) + realizedPnL;

        // change storage values
        self.margin -= self.margin * closeProportion / PERCENTAGE_MULTIPLIER;
        self.volume -= delta.volume;
        self.assetAmount -= delta.assetAmount;

        // Update borrow fee amounts
        self.collectedBorrowFeeAmount +=
            self.lastBorrowFeeAmount * int256(closeProportion) / int256(PERCENTAGE_MULTIPLIER);
        self.lastBorrowFeeAmount -= self.lastBorrowFeeAmount * int256(closeProportion) / int256(PERCENTAGE_MULTIPLIER);

        // Update funding fee amounts
        self.collectedFundingFeeAmount +=
            self.lastFundingFeeAmount * int256(closeProportion) / int256(PERCENTAGE_MULTIPLIER);
        self.lastFundingFeeAmount -= self.lastFundingFeeAmount * int256(closeProportion) / int256(PERCENTAGE_MULTIPLIER);

        // Return payout for further calculations
        return payout;
    }

    /**
     * @notice Adds margin to a position
     * @param addedMargin the margin that gets added to the position
     */
    function addMargin(Position storage self, uint256 addedMargin) public {
        self._addMargin(addedMargin);
    }

    function _addMargin(Position storage self, uint256 addedMargin) internal {
        self.margin += addedMargin;
    }

    /**
     * @notice Removes margin from a position
     * @dev The remaining equity has to stay positive
     * @param removedMargin the margin to remove
     */
    function removeMargin(Position storage self, uint256 removedMargin) public {
        self._removeMargin(removedMargin);
    }

    function _removeMargin(Position storage self, uint256 removedMargin) internal {
        require(self.margin > removedMargin, "PositionMaths::_removeMargin: cannot remove more margin than available");
        self.margin -= removedMargin;
    }

    /**
     * @notice Extends position with margin and loan.
     * @param addedMargin Margin added to position.
     * @param addedAssetAmount Asset amount added to position.
     * @param addedVolume Loan added to position.
     */
    function extend(Position storage self, uint256 addedMargin, uint256 addedAssetAmount, uint256 addedVolume) public {
        self._extend(addedMargin, addedAssetAmount, addedVolume);
    }

    function _extend(Position storage self, uint256 addedMargin, uint256 addedAssetAmount, uint256 addedVolume)
        internal
    {
        self.margin += addedMargin;
        self.assetAmount += addedAssetAmount;
        self.volume += addedVolume;
    }

    /**
     * @notice Extends position with loan to target leverage.
     * @param currentPrice current asset price
     * @param targetLeverage target leverage
     */
    function extendToLeverage(Position storage self, int256 currentPrice, uint256 targetLeverage) public {
        self._extendToLeverage(currentPrice, targetLeverage);
    }

    function _extendToLeverage(Position storage self, int256 currentPrice, uint256 targetLeverage) internal {
        require(
            targetLeverage > self._lastNetLeverage(),
            "PositionMaths::_extendToLeverage: target leverage must be larger than current leverage"
        );

        // calculate changes
        Position memory delta;
        delta.volume = targetLeverage * self._lastNetMargin() / LEVERAGE_MULTIPLIER - self.volume;
        delta.assetAmount = delta.volume * collateralToPriceMultiplier() * ASSET_MULTIPLIER / uint256(currentPrice);

        // store changes
        self.assetAmount += delta.assetAmount;
        self.volume += delta.volume;
    }

    /**
     * @notice Returns if the position exists / is open
     */
    function exists(Position storage self) public view returns (bool) {
        return self._exists();
    }

    function _exists(Position storage self) internal view returns (bool) {
        return self.margin > 0;
    }

    /**
     * @notice Adds all elapsed fees to the fee amounts. After this, the position can be altered.
     */
    function updateFees(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
        public
    {
        self._updateFees(currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    /**
     * Internal Functions (that are only called internally and not mirror a public function)
     */

    function _updateFees(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
        internal
    {
        int256 elapsedBorrowFeeAmount =
            (currentBorrowFeeIntegral - self.pastBorrowFeeIntegral) * int256(self.volume) / FEE_MULTIPLIER;
        int256 elapsedFundingFeeAmount =
            (currentFundingFeeIntegral - self.pastFundingFeeIntegral) * int256(self.volume) / FEE_MULTIPLIER;

        self.lastBorrowFeeAmount += elapsedBorrowFeeAmount;
        self.lastFundingFeeAmount += elapsedFundingFeeAmount;
        self.pastBorrowFeeIntegral = currentBorrowFeeIntegral;
        self.pastFundingFeeIntegral = currentFundingFeeIntegral;
        self.lastFeeCalculationAt = uint48(block.timestamp);
    }

    /**
     * @notice Returns the multiplier from TradePair, as PositionMaths is decimal agnostic
     */
    function collateralToPriceMultiplier() private view returns (uint256) {
        return ITradePair_Multiplier(address(this)).collateralToPriceMultiplier();
    }
}

using PositionMaths for Position;

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

/* ========== STRUCTS ========== */

/**
 * @notice Struct to store statistical information about all positions
 * @custom:member totalLongMargin total amount of margin for long positions
 * @custom:member totalLongVolume total volume for long positions
 * @custom:member totalLongAssetAmount total amount of size for long positions
 * @custom:member totalShortMargin total amount of margin for short positions
 * @custom:member totalShortVolume total volume for short positions
 * @custom:member totalShortAssetAmount total amount of size for short positions
 */
struct PositionStats {
    uint256 totalLongMargin;
    uint256 totalLongVolume;
    uint256 totalLongAssetAmount;
    uint256 totalShortMargin;
    uint256 totalShortVolume;
    uint256 totalShortAssetAmount;
}

/**
 * @title PositionStats
 * @notice Provides data structures and functions for Aggregated positions statistics at TradePair
 * @dev This contract is a library and should be used by a contract that implements the ITradePair interface
 * Provides methods to keep track of total volume, margin and volume for long and short positions
 */
library PositionStatsLib {
    uint256 constant PERCENTAGE_MULTIPLIER = 1_000_000;

    /* =========== EXTERNAL FUNCTIONS =========== */

    /**
     * @notice add total margin, volume and size
     * @param margin the margin to add
     * @param volume the volume to add
     * @param size the size to add
     * @param isShort bool if the data belongs to a short position
     */
    function addTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
        public
    {
        _self._addTotalCount(margin, volume, size, isShort);
    }

    /**
     * @notice remove total margin, volume and size
     * @param margin the margin to remove
     * @param volume the volume to remove
     * @param size the size to remove
     * @param isShort bool if the data belongs to a short position
     */
    function removeTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
        public
    {
        _self._removeTotalCount(margin, volume, size, isShort);
    }

    /**
     * @notice add total margin, volume and size
     * @param margin the margin to add
     * @param volume the volume to add
     * @param size the size to add
     * @param isShort bool if the data belongs to a short position
     */
    function _addTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
        internal
    {
        if (isShort) {
            _self.totalShortMargin += margin;
            _self.totalShortVolume += volume;
            _self.totalShortAssetAmount += size;
        } else {
            _self.totalLongMargin += margin;
            _self.totalLongVolume += volume;
            _self.totalLongAssetAmount += size;
        }
    }

    /**
     * @notice remove total margin, volume and size
     * @param margin the margin to remove
     * @param volume the volume to remove
     * @param size the size to remove
     * @param isShort bool if the data belongs to a short position
     */
    function _removeTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
        internal
    {
        if (isShort) {
            _self.totalShortMargin -= margin;
            _self.totalShortVolume -= volume;
            _self.totalShortAssetAmount -= size;
        } else {
            _self.totalLongMargin -= margin;
            _self.totalLongVolume -= volume;
            _self.totalLongAssetAmount -= size;
        }
    }
}

using PositionStatsLib for PositionStats;

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

/**
 * @dev These are global constants used in the Unlimited protocol.
 * These constants are mainly used as multipliers.
 */

// 100 percent in BPS.
uint256 constant FULL_PERCENT = 100_00;
int256 constant FEE_MULTIPLIER = 1e14;
int256 constant FEE_BPS_MULTIPLIER = FEE_MULTIPLIER / 1e4; // 1e10
int256 constant BUFFER_MULTIPLIER = 1e6;
uint256 constant PERCENTAGE_MULTIPLIER = 1e6;
uint256 constant LEVERAGE_MULTIPLIER = 1_000_000;
uint8 constant ASSET_DECIMALS = 18;
uint256 constant ASSET_MULTIPLIER = 10 ** ASSET_DECIMALS;

// Rational to use 24 decimals for prices:
// 24 decimals is larger or equal than decimals of all important tokens. (Ethereum = 18, BNB = 18, USDT = 6)
// It is higher than most price feeds (Chainlink = 8, Uniswap = 18, Binance = 8)
uint256 constant PRICE_DECIMALS = 24;
uint256 constant PRICE_MULTIPLIER = 10 ** PRICE_DECIMALS;

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../interfaces/IUnlimitedOwner.sol";

/// @title Logic to help check whether the caller is the Unlimited owner
abstract contract UnlimitedOwnable {
    /* ========== STATE VARIABLES ========== */

    /// @notice Contract that holds the address of Unlimited owner
    IUnlimitedOwner public immutable unlimitedOwner;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Sets correct initial values
     * @param _unlimitedOwner Unlimited owner contract address
     */
    constructor(IUnlimitedOwner _unlimitedOwner) {
        require(
            address(_unlimitedOwner) != address(0),
            "UnlimitedOwnable::constructor: Unlimited owner contract address cannot be 0"
        );

        unlimitedOwner = _unlimitedOwner;
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Checks if caller is Unlimited owner
     * @return True if caller is Unlimited owner, false otherwise
     */
    function isUnlimitedOwner() internal view returns (bool) {
        return unlimitedOwner.isUnlimitedOwner(msg.sender);
    }

    /// @notice Checks and throws if caller is not Unlimited owner
    function _onlyOwner() private view {
        require(isUnlimitedOwner(), "UnlimitedOwnable::_onlyOwner: Caller is not the Unlimited owner");
    }

    /// @notice Checks and throws if caller is not Unlimited owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../external/interfaces/ArbSys.sol";
import "../interfaces/IFeeManager.sol";
import "../interfaces/ILiquidityPoolAdapter.sol";
import "../interfaces/IPriceFeedAdapter.sol";
import "../interfaces/ITradeManager.sol";
import "../interfaces/ITradePair.sol";
import "../interfaces/IUserManager.sol";
import "../shared/Constants.sol";
import "../shared/UnlimitedOwnable.sol";
import "../lib/FeeBuffer.sol";
import "../lib/FeeIntegral.sol";
import "../lib/PositionMaths.sol";
import "../lib/PositionStats.sol";

contract TradePair is ITradePair, UnlimitedOwnable, Initializable {
    using SafeERC20 for IERC20;
    using FeeIntegralLib for FeeIntegral;
    using FeeBufferLib for FeeBuffer;
    using PositionMaths for Position;
    using PositionStatsLib for PositionStats;

    /* ========== CONSTANTS ========== */

    uint256 private constant SURPLUS_MULTIPLIER = 1_000_000; // 1e6
    uint256 private constant BPS_MULTIPLIER = 100_00; // 1e4

    uint128 private constant MIN_LEVERAGE = 11 * uint128(LEVERAGE_MULTIPLIER) / 10;
    uint128 private constant MAX_LEVERAGE = 100 * uint128(LEVERAGE_MULTIPLIER);

    uint256 private constant USD_TRIM = 10 ** 8;

    enum PositionAlteration {
        partialClose,
        partiallyCloseToLeverage,
        extend,
        extendToLeverage,
        removeMargin,
        addMargin
    }

    /* ========== SYSTEM SMART CONTRACTS ========== */

    /// @notice Trade manager that manages trades.
    ITradeManager public immutable tradeManager;

    /// @notice manages fees per user
    IUserManager public immutable userManager;

    /// @notice Fee Manager that collects and distributes fees
    IFeeManager public immutable feeManager;

    // =============================================================
    //                            STORAGE
    // =============================================================

    /// @notice The price feed to calculate asset to collateral amounts
    IPriceFeedAdapter public priceFeedAdapter;

    /// @notice The liquidity pool adapter that the funds will get borrowed from
    ILiquidityPoolAdapter public liquidityPoolAdapter;

    /// @notice The token that is used as a collateral
    IERC20 public collateral;

    /* ========== PARAMETERS ========== */

    /// @notice The name of this trade pair
    string public name;

    /// @notice Multiplier from collateral to price
    uint256 private _collateralToPriceMultiplier;

    /* ============ INTERNAL SETTINGS ========== */

    /// @notice Minimum Leverage
    uint128 public minLeverage;

    /// @notice Maximum Leverage
    uint128 public maxLeverage;

    /// @notice Minimum margin
    uint256 public minMargin;

    /// @notice Maximum Volume a position can have
    uint256 public volumeLimit;

    /// @notice Total volume limit for each side
    uint256 public totalVolumeLimit;

    /// @notice reward for liquidator
    uint256 public liquidatorReward;

    /* ========== STATE VARIABLES ========== */

    /// @notice The positions of this tradepair
    mapping(uint256 => Position) positions;

    /// @notice Maps position id to the white label address that opened a position
    /// @dev White label recieves part of the open and close position fees collected
    mapping(uint256 => address) public positionIdToWhiteLabel;

    /// @notice increasing counter for the next position id
    uint256 public nextId;

    /// @notice Keeps track of total amounts of positions
    PositionStats public positionStats;

    /// @notice Calculates the fee integrals
    FeeIntegral public feeIntegral;

    /// @notice Keeps track of the fee buffer
    FeeBuffer public feeBuffer;

    /// @notice Amount of overcollected fees
    int256 public overcollectedFees;

    // Storage gap
    uint256[50] __gap;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructs the TradePair contract
     * @param unlimitedOwner_ The Unlimited Owner constract
     * @param tradeManager_ The TradeManager contract
     * @param userManager_ The UserManager contract
     * @param feeManager_ The FeeManager contract
     */
    constructor(
        IUnlimitedOwner unlimitedOwner_,
        ITradeManager tradeManager_,
        IUserManager userManager_,
        IFeeManager feeManager_
    ) UnlimitedOwnable(unlimitedOwner_) {
        tradeManager = tradeManager_;
        userManager = userManager_;
        feeManager = feeManager_;
    }

    /**
     * @notice Initializes state variables
     * @param name_ The name of this trade pair
     * @param collateral_ the collateral ERC20 contract
     * @param priceFeedAdapter_ The price feed adapter
     * @param liquidityPoolAdapter_ The liquidity pool adapter
     */
    function initialize(
        string calldata name_,
        IERC20Metadata collateral_,
        IPriceFeedAdapter priceFeedAdapter_,
        ILiquidityPoolAdapter liquidityPoolAdapter_
    ) external onlyOwner initializer {
        name = name_;
        collateral = collateral_;
        liquidityPoolAdapter = liquidityPoolAdapter_;

        setPriceFeedAdapter(priceFeedAdapter_);

        minLeverage = MIN_LEVERAGE;
        maxLeverage = MAX_LEVERAGE;
    }

    /* ========== CORE FUNCTIONS - POSITIONS ========== */

    /**
     * @notice opens a position
     * @param maker_ owner of the position
     * @param margin_ the amount of collateral used as a margin
     * @param leverage_ the target leverage, should respect LEVERAGE_MULTIPLIER
     * @param isShort_ bool if the position is a short position
     */
    function openPosition(address maker_, uint256 margin_, uint256 leverage_, bool isShort_, address whitelabelAddress)
        external
        verifyLeverage(leverage_)
        onlyTradeManager
        syncFeesBefore
        checkTotalVolumeLimit
        returns (uint256)
    {
        if (whitelabelAddress != address(0)) {
            positionIdToWhiteLabel[nextId] = whitelabelAddress;
        }

        return _openPosition(maker_, margin_, leverage_, isShort_);
    }

    /**
     * @dev Should have received margin from TradeManager
     */
    function _openPosition(address maker_, uint256 margin_, uint256 leverage_, bool isShort_)
        private
        returns (uint256)
    {
        require(margin_ >= minMargin, "TradePair::_openPosition: margin must be above or equal min margin");

        uint256 id = nextId;
        nextId++;

        margin_ = _deductAndTransferOpenFee(maker_, margin_, leverage_, id);

        uint256 volume = (margin_ * leverage_) / LEVERAGE_MULTIPLIER;
        require(volume <= volumeLimit, "TradePair::_openPosition: borrow limit reached");
        _registerUserVolume(maker_, volume);

        uint256 assetAmount;
        if (isShort_) {
            assetAmount = priceFeedAdapter.collateralToAssetMax(volume);
        } else {
            assetAmount = priceFeedAdapter.collateralToAssetMin(volume);
        }

        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(isShort_);

        positions[id] = Position({
            margin: margin_,
            volume: volume,
            assetAmount: assetAmount,
            pastBorrowFeeIntegral: currentBorrowFeeIntegral,
            lastBorrowFeeAmount: 0,
            pastFundingFeeIntegral: currentFundingFeeIntegral,
            lastFundingFeeAmount: 0,
            collectedFundingFeeAmount: 0,
            collectedBorrowFeeAmount: 0,
            lastFeeCalculationAt: uint48(block.timestamp),
            openedAt: uint48(block.timestamp),
            isShort: isShort_,
            owner: maker_,
            lastAlterationBlock: uint40(ArbSys(address(100)).arbBlockNumber())
        });

        positionStats.addTotalCount(margin_, volume, assetAmount, isShort_);

        _verifyPositionsValidity(id);

        emit OpenedPosition(maker_, id, margin_, volume, assetAmount, isShort_);

        return id;
    }

    /**
     * @notice Closes A position
     * @param maker_ address of the maker of this position.
     * @param positionId_ the position id.
     */
    function closePosition(address maker_, uint256 positionId_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
    {
        _verifyAndUpdateLastAlterationBlock(positionId_);
        _closePosition(positionId_);
    }

    function _closePosition(uint256 positionId_) private {
        Position storage position = positions[positionId_];

        // Clear Buffer
        (uint256 remainingMargin, uint256 remainingBufferFee, uint256 requestLoss) = _clearBuffer(position, false);

        // Get the payout to the maker
        uint256 payoutToMaker = _getPayoutToMaker(position);

        // update aggregated values
        positionStats.removeTotalCount(position.margin, position.volume, position.assetAmount, position.isShort);

        int256 protocolPnL = int256(remainingMargin) - int256(payoutToMaker) - int256(requestLoss);

        // fee manager receives the remaining fees
        _depositBorrowFees(remainingBufferFee);

        uint256 payout = _registerProtocolPnL(protocolPnL);

        // Make sure the payout to maker does not exceed the collateral for this position made up of the remaining margin and the (possible) received loss payout
        if (payoutToMaker > payout + remainingMargin) {
            payoutToMaker = payout + remainingMargin;
        }

        if (payoutToMaker > 0) {
            _payoutToMaker(position.owner, int256(payoutToMaker), position.volume, positionId_);
        }

        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);

        emit RealizedPnL(
            position.owner,
            positionId_,
            _getCurrentNetPnL(position),
            position.currentBorrowFeeAmount(currentBorrowFeeIntegral),
            position.currentFundingFeeAmount(currentFundingFeeIntegral)
        );

        emit ClosedPosition(positionId_, _getCurrentPrice(position.isShort, true));

        // Finally delete position
        _deletePosition(positionId_);
    }

    /**
     * @notice Partially closes a position on a trade pair.
     * @param maker_ owner of the position
     * @param positionId_ id of the position
     * @param proportion_ the proportion of the position that should be closed, should respect PERCENTAGE_MULTIPLIER
     */
    function partiallyClosePosition(address maker_, uint256 positionId_, uint256 proportion_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
    {
        _partiallyClosePosition(maker_, positionId_, proportion_);
    }

    function _partiallyClosePosition(address maker_, uint256 positionId_, uint256 proportion_) private {
        Position storage position = positions[positionId_];

        int256 payoutToMaker;

        // positionDelta saves the changes in position margin, volume and size.
        // First it gets assigned the old values, than the new values are subtracted.
        PositionDetails memory positionDelta;

        // Assign old values to positionDelta
        positionDelta.margin = position.margin;
        positionDelta.volume = position.volume;
        positionDelta.assetAmount = position.assetAmount;
        int256 realizedPnL = _getCurrentNetPnL(position);

        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);
        int256 realizedBorrowFeeAmount = position.currentBorrowFeeAmount(currentBorrowFeeIntegral);
        int256 realizedFundingFeeAmount = position.currentFundingFeeAmount(currentFundingFeeIntegral);

        // partially close in storage
        payoutToMaker = position.partiallyClose(_getCurrentPrice(position.isShort, true), proportion_);

        // Subtract new values from positionDelta. This way positionDelta contains the changes in position margin, volume and size.
        positionDelta.margin -= position.margin;
        positionDelta.volume -= position.volume;
        positionDelta.assetAmount -= position.assetAmount;
        realizedPnL -= _getCurrentNetPnL(position);
        realizedBorrowFeeAmount -= position.lastBorrowFeeAmount;
        realizedFundingFeeAmount -= position.lastFundingFeeAmount;

        uint256 payout = _registerProtocolPnL(-realizedPnL);

        if (payoutToMaker > int256(payout + positionDelta.margin)) {
            payoutToMaker = int256(payout + positionDelta.margin);
        }

        if (payoutToMaker > 0) {
            _payoutToMaker(maker_, int256(payoutToMaker), positionDelta.volume, positionId_);
        }

        // Use positionDelta to update positionStats
        positionStats.removeTotalCount(
            positionDelta.margin, positionDelta.volume, positionDelta.assetAmount, position.isShort
        );

        emit AlteredPosition(
            PositionAlterationType.partiallyClose,
            positionId_,
            position.lastNetMargin(),
            position.volume,
            position.assetAmount
        );

        emit RealizedPnL(maker_, positionId_, realizedPnL, realizedBorrowFeeAmount, realizedFundingFeeAmount);
    }

    /**
     * @notice Extends position with margin and leverage. Leverage determins added loan. New margin and loan get added
     * to the existing position.
     * @param maker_ Address of the position maker.
     * @param positionId_ ID of the position.
     * @param addedMargin_ Margin added to the position.
     * @param addedLeverage_ Denoted in LEVERAGE_MULTIPLIER.
     */
    function extendPosition(address maker_, uint256 positionId_, uint256 addedMargin_, uint256 addedLeverage_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        verifyLeverage(addedLeverage_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
        checkTotalVolumeLimit
    {
        _extendPosition(maker_, positionId_, addedMargin_, addedLeverage_);
    }

    /**
     * @notice Should have received margin from TradeManager
     * @dev extendPosition simply "adds" a "new" position on top of the existing position. The two positions get merged.
     */
    function _extendPosition(address maker_, uint256 positionId_, uint256 addedMargin_, uint256 addedLeverage_)
        private
    {
        Position storage position = positions[positionId_];

        addedMargin_ = _deductAndTransferOpenFee(maker_, addedMargin_, addedLeverage_, positionId_);

        uint256 addedVolume = addedMargin_ * addedLeverage_ / LEVERAGE_MULTIPLIER;
        _registerUserVolume(maker_, addedVolume);

        uint256 addedSize;
        if (position.isShort) {
            addedSize = priceFeedAdapter.collateralToAssetMax(addedVolume);
        } else {
            addedSize = priceFeedAdapter.collateralToAssetMin(addedVolume);
        }

        // Update tally.
        positionStats.addTotalCount(addedMargin_, addedVolume, addedSize, position.isShort);

        // Update position.
        position.extend(addedMargin_, addedSize, addedVolume);

        emit AlteredPosition(
            PositionAlterationType.extend, positionId_, position.lastNetMargin(), position.volume, position.assetAmount
        );
    }

    /**
     * @notice Extends position with loan to target leverage.
     * @param maker_ Address of the position maker.
     * @param positionId_ ID of the position.
     * @param targetLeverage_ Target leverage in respect to LEVERAGE_MULTIPLIER.
     */
    function extendPositionToLeverage(address maker_, uint256 positionId_, uint256 targetLeverage_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
        verifyLeverage(targetLeverage_)
        checkTotalVolumeLimit
    {
        _extendPositionToLeverage(positionId_, targetLeverage_);
    }

    function _extendPositionToLeverage(uint256 positionId_, uint256 targetLeverage_) private {
        Position storage position = positions[positionId_];

        int256 currentPrice = _getCurrentPrice(position.isShort, false);

        // Old values are needed to calculate the differences of aggregated values
        uint256 old_margin = position.margin;
        uint256 old_volume = position.volume;
        uint256 old_size = position.assetAmount;

        // The user does not deposit fee with this transaction, so the fee is taken from the margin of the position
        position.margin = _deductAndTransferExtendToLeverageFee(
            position.owner, position.margin, position.currentVolume(currentPrice), targetLeverage_, positionId_
        );

        // update position in storage
        position.extendToLeverage(currentPrice, targetLeverage_);

        // update aggregated values
        _registerUserVolume(position.owner, position.volume - old_volume);
        positionStats.addTotalCount(0, position.volume - old_volume, position.assetAmount - old_size, position.isShort);

        positionStats.removeTotalCount(old_margin - position.margin, 0, 0, position.isShort);

        emit AlteredPosition(
            PositionAlterationType.extendToLeverage,
            positionId_,
            position.lastNetMargin(),
            position.volume,
            position.assetAmount
        );
    }

    /**
     * @notice Removes margin from a position
     * @param maker_ owner of the position
     * @param positionId_ id of the position
     * @param removedMargin_ the margin to be removed
     */
    function removeMarginFromPosition(address maker_, uint256 positionId_, uint256 removedMargin_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
    {
        _removeMarginFromPosition(maker_, positionId_, removedMargin_);
    }

    function _removeMarginFromPosition(address maker_, uint256 positionId_, uint256 removedMargin_) private {
        Position storage position = positions[positionId_];

        // update position in storage
        position.removeMargin(removedMargin_);

        // The minMargin condition has to hold after the margin is removed
        require(
            position.lastNetMargin() >= minMargin,
            "TradePair::_removeMarginFromPosition: Margin must be above minMargin"
        );

        // update aggregated values
        positionStats.removeTotalCount(removedMargin_, 0, 0, position.isShort);

        _payoutToMaker(maker_, int256(removedMargin_), 0, positionId_);

        emit AlteredPosition(
            PositionAlterationType.removeMargin,
            positionId_,
            position.lastNetMargin(),
            position.volume,
            position.assetAmount
        );
    }

    /**
     * @notice Adds margin to a position
     * @param maker_ owner of the position
     * @param positionId_ id of the position
     * @param addedMargin_ the margin to be added
     */
    function addMarginToPosition(address maker_, uint256 positionId_, uint256 addedMargin_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
    {
        _addMarginToPosition(maker_, positionId_, addedMargin_);
    }

    /**
     * @dev Should have received margin from TradeManager
     */
    function _addMarginToPosition(address maker_, uint256 positionId_, uint256 addedMargin_) private {
        Position storage position = positions[positionId_];

        addedMargin_ = _deductAndTransferOpenFee(maker_, addedMargin_, LEVERAGE_MULTIPLIER, positionId_);

        // change position in storage
        position.addMargin(addedMargin_);

        // The maxLeverage condition has to hold
        require(
            position.lastNetLeverage() >= minLeverage,
            "TradePair::_addMarginToPosition: Leverage must be above minLeverage"
        );

        // update aggregated values
        positionStats.addTotalCount(addedMargin_, 0, 0, position.isShort);

        emit AlteredPosition(
            PositionAlterationType.addMargin,
            positionId_,
            position.lastNetMargin(),
            position.volume,
            position.assetAmount
        );
    }

    /**
     * @notice Liquidates position and sends liquidation reward to msg.sender
     * @param liquidator_ Address of the liquidator.
     * @param positionId_ position id
     */
    function liquidatePosition(address liquidator_, uint256 positionId_)
        external
        onlyTradeManager
        onlyLiquidatable(positionId_)
        syncFeesBefore
    {
        _verifyAndUpdateLastAlterationBlock(positionId_);
        _liquidatePosition(liquidator_, positionId_);
    }

    /**
     * @notice liquidates a position
     */
    function _liquidatePosition(address liquidator_, uint256 positionId_) private {
        Position storage position = positions[positionId_];

        // Clear Buffer
        (uint256 remainingMargin, uint256 remainingBufferFee, uint256 requestLoss) = _clearBuffer(position, true);

        // Get the payout to the maker
        uint256 payoutToMaker = _getPayoutToMaker(position);

        // Calculate the protocol PnL
        int256 protocolPnL = int256(remainingMargin) - int256(payoutToMaker) - int256(requestLoss);

        // Register the protocol PnL and receive a possible payout
        uint256 payout = _registerProtocolPnL(protocolPnL);

        // Calculate the available liquidity for this position's liquidation
        uint256 availableLiquidity = remainingBufferFee + payout + uint256(liquidatorReward);

        // Prio 1: Keep the request loss at TradePair, as this makes up the funding fee that pays the other positions
        if (availableLiquidity > requestLoss) {
            availableLiquidity -= requestLoss;
        } else {
            // If available liquidity is not enough to cover the requested loss,
            // emit a warning, because the liquidity pools are drained.
            requestLoss = availableLiquidity;
            emit LiquidityGapWarning(requestLoss);
            availableLiquidity = 0;
        }

        // Prio 2: Pay out the liquidator reward
        if (availableLiquidity > liquidatorReward) {
            _payOut(liquidator_, liquidatorReward);
            availableLiquidity -= liquidatorReward;
        } else {
            _payOut(liquidator_, availableLiquidity);
            availableLiquidity = 0;
        }

        // Prio 3: Pay out to the maker
        if (availableLiquidity > payoutToMaker) {
            _payoutToMaker(position.owner, int256(payoutToMaker), position.volume, positionId_);
            availableLiquidity -= payoutToMaker;
        } else {
            _payoutToMaker(position.owner, int256(availableLiquidity), position.volume, positionId_);
            availableLiquidity = 0;
        }

        // Prio 4: Pay out the buffered fee
        if (availableLiquidity > remainingBufferFee) {
            _depositBorrowFees(remainingBufferFee);
            availableLiquidity -= remainingBufferFee;
        } else {
            _depositBorrowFees(availableLiquidity);
            availableLiquidity = 0;
        }
        // Now, available liquity is zero

        // Remove position from total counts
        positionStats.removeTotalCount(position.margin, position.volume, position.assetAmount, position.isShort);

        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);

        emit RealizedPnL(
            position.owner,
            positionId_,
            _getCurrentNetPnL(position),
            position.currentBorrowFeeAmount(currentBorrowFeeIntegral),
            position.currentFundingFeeAmount(currentFundingFeeIntegral)
        );

        emit LiquidatedPosition(positionId_, liquidator_);

        // Delete Position
        _deletePosition(positionId_);
    }

    /* ========== HELPER FUNCTIONS ========= */

    /**
     * @notice Calculates outstanding borrow fees, transfers it to FeeManager and updates the fee integrals.
     * Funding fee stays at this TradePair as it is transfered virtually to the opposite positions ("long pays short").
     *
     * All positions' margins make up the trade pair's balance of which the fee is transfered from.
     * @dev This function is public to allow possible fee syncing in periods without trades.
     */
    function syncPositionFees() public {
        // The total amount of borrow fee is based on the entry volume of all positions
        // This is done to batch collect borrow fees for all open positions

        uint256 timeSinceLastUpdate = block.timestamp - feeIntegral.lastUpdatedAt;

        if (timeSinceLastUpdate > 0) {
            int256 elapsedBorrowFeeIntegral = feeIntegral.getElapsedBorrowFeeIntegral();
            uint256 totalVolume = positionStats.totalShortVolume + positionStats.totalLongVolume;

            int256 newBorrowFeeAmount = elapsedBorrowFeeIntegral * int256(totalVolume) / FEE_MULTIPLIER;

            // Fee Integrals get updated for funding fee.
            feeIntegral.update(positionStats.totalLongAssetAmount, positionStats.totalShortAssetAmount);

            emit UpdatedFeeIntegrals(
                feeIntegral.borrowFeeIntegral, feeIntegral.longFundingFeeIntegral, feeIntegral.shortFundingFeeIntegral
            );

            // Reduce by the fee buffer
            // Buffer is used to prevent overrtaking the fees from the position
            uint256 reducedFeeAmount = feeBuffer.takeBufferFrom(uint256(newBorrowFeeAmount));

            // Transfer borrow fee to FeeManager
            _depositBorrowFees(reducedFeeAmount);
        }
    }

    /**
     * @dev Deletes position entries from storage.
     */
    function _deletePosition(uint256 positionId_) internal {
        delete positions[positionId_];
    }

    /**
     * @notice Clears the fee buffer and returns the remaining margin, remaining buffer fee and request loss.
     * @param position_ The position to clear the buffer for.
     * @param isLiquidation_ Whether the buffer is cleared due to a liquidation. In this case, liquidatorReward is added to funding fee.
     * @return remainingMargin the _margin of the position after clearing the buffer and paying fees
     * @return remainingBuffer remaining amount that needs to be transferred to the fee manager
     * @return requestLoss the amount of loss that needs to be requested from the liquidity pool
     */
    function _clearBuffer(Position storage position_, bool isLiquidation_)
        private
        returns (uint256, uint256, uint256)
    {
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position_.isShort);

        uint256 additionalFee = isLiquidation_ ? liquidatorReward : 0;

        // Clear Buffer
        return feeBuffer.clearBuffer(
            position_.margin,
            position_.currentBorrowFeeAmount(currentBorrowFeeIntegral) + position_.collectedBorrowFeeAmount,
            position_.currentFundingFeeAmount(currentFundingFeeIntegral) + position_.collectedFundingFeeAmount
                + int256(additionalFee)
        );
    }

    /**
     * @notice updates the fee of this position. Necessary before changing its volume.
     * @param positionId_ the id of the position
     */
    function _updatePositionFees(uint256 positionId_) internal {
        Position storage position = positions[positionId_];
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);

        position.updateFees(currentBorrowFeeIntegral, currentFundingFeeIntegral);

        emit UpdatedFeesOfPosition(
            positionId_, position.lastBorrowFeeAmount + position.lastFundingFeeAmount, position.lastNetMargin()
        );
    }

    /**
     * @notice Registers profit or loss at liquidity pool adapter
     * @param protocolPnL_ Profit or loss of protocol
     * @return payout Payout received from the liquidity pool adapter
     */
    function _registerProtocolPnL(int256 protocolPnL_) internal returns (uint256 payout) {
        if (protocolPnL_ > 0) {
            // Profit
            collateral.safeTransfer(address(liquidityPoolAdapter), uint256(protocolPnL_));
            liquidityPoolAdapter.depositProfit(uint256(protocolPnL_));
        } else if (protocolPnL_ < 0) {
            // Loss
            payout = liquidityPoolAdapter.requestLossPayout(uint256(-protocolPnL_));
        }
        // if PnL == 0, nothing happens

        emit RegisteredProtocolPnL(protocolPnL_, payout);
    }

    /**
     * @notice Pays out amount to receiver. If balance does not suffice, registers loss.
     * @param receiver_ Address of receiver.
     * @param amount_ Amount to pay out.
     */
    function _payOut(address receiver_, uint256 amount_) internal {
        if (amount_ > collateral.balanceOf(address(this))) {
            liquidityPoolAdapter.requestLossPayout(amount_ - collateral.balanceOf(address(this)));
        }
        collateral.safeTransfer(receiver_, amount_);
    }

    /**
     * @dev Deducts fees from the given amount and pays the rest to maker
     */
    function _payoutToMaker(address maker_, int256 amount_, uint256 closedVolume, uint256 positionId_) private {
        if (amount_ > 0) {
            uint256 closePositionFee = feeManager.calculateUserCloseFeeAmount(maker_, closedVolume);
            _depositClosePositionFees(maker_, closePositionFee, positionId_);

            uint256 reducedAmount;
            if (uint256(amount_) > closePositionFee) {
                reducedAmount = uint256(amount_) - closePositionFee;
            }

            _payOut(maker_, reducedAmount);

            emit PayedOutCollateral(maker_, reducedAmount, positionId_);
        }
    }

    /**
     * @notice Deducts open position fee for a given margin and leverage. Returns the margin after fee deduction.
     * @dev The fee is exactly [userFee] of the resulting volume.
     * @param margin_ The margin of the position.
     * @param leverage_ The leverage of the position.
     * @return marginAfterFee_ The margin after fee deduction.
     */
    function _deductAndTransferOpenFee(address maker_, uint256 margin_, uint256 leverage_, uint256 positionId_)
        internal
        returns (uint256 marginAfterFee_)
    {
        uint256 openPositionFee = feeManager.calculateUserOpenFeeAmount(maker_, margin_, leverage_);
        _depositOpenPositionFees(maker_, openPositionFee, positionId_);

        marginAfterFee_ = margin_ - openPositionFee;
    }

    /**
     * @notice Deducts open position fee for a given margin and leverage. Returns the margin after fee deduction.
     * @dev The fee is exactly [userFee] of the resulting volume.
     * @param maker_ The maker of the position.
     * @param margin_ The margin of the position.
     * @param volume_ The volume of the position.
     * @param targetLeverage_ The target leverage of the position.
     * @param positionId_ The id of the position.
     * @return marginAfterFee_ The margin after fee deduction.
     */
    function _deductAndTransferExtendToLeverageFee(
        address maker_,
        uint256 margin_,
        uint256 volume_,
        uint256 targetLeverage_,
        uint256 positionId_
    ) internal returns (uint256 marginAfterFee_) {
        uint256 openPositionFee =
            feeManager.calculateUserExtendToLeverageFeeAmount(maker_, margin_, volume_, targetLeverage_);
        _depositOpenPositionFees(maker_, openPositionFee, positionId_);

        marginAfterFee_ = margin_ - openPositionFee;
    }

    /**
     * @notice Registers user volume in USD.
     * @dev Trimms decimals from USD value.
     *
     * @param user_ User address.
     * @param volume_ Volume in collateral.
     */
    function _registerUserVolume(address user_, uint256 volume_) private {
        uint256 volumeUsd = priceFeedAdapter.collateralToUsdMin(volume_);

        uint40 volumeUsdTrimmed = uint40(volumeUsd / USD_TRIM);

        userManager.addUserVolume(user_, volumeUsdTrimmed);
    }

    /**
     * @dev Deposits the open position fees to the FeeManager.
     */
    function _depositOpenPositionFees(address user_, uint256 amount_, uint256 positionId_) private {
        _resetApprove(address(feeManager), amount_);
        feeManager.depositOpenFees(user_, address(collateral), amount_, positionIdToWhiteLabel[positionId_]);

        emit DepositedOpenFees(user_, amount_, positionId_);
    }

    /**
     * @dev Deposits the close position fees to the FeeManager.
     */
    function _depositClosePositionFees(address user_, uint256 amount_, uint256 positionId_) private {
        _resetApprove(address(feeManager), amount_);
        feeManager.depositCloseFees(user_, address(collateral), amount_, positionIdToWhiteLabel[positionId_]);

        emit DepositedCloseFees(user_, amount_, positionId_);
    }

    /**
     * @dev Deposits the borrow fees to the FeeManager
     */
    function _depositBorrowFees(uint256 amount_) private {
        if (amount_ > 0) {
            _resetApprove(address(feeManager), amount_);
            feeManager.depositBorrowFees(address(collateral), amount_);
        }

        emit DepositedBorrowFees(amount_);
    }

    /**
     * @dev Sets the allowance on the collateral to 0.
     */
    function _resetApprove(address user_, uint256 amount_) private {
        if (collateral.allowance(address(this), user_) > 0) {
            collateral.safeApprove(user_, 0);
        }

        collateral.safeApprove(user_, amount_);
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Multiplier from collateral to price.
     * @return collateralToPriceMultiplier
     */
    function collateralToPriceMultiplier() external view returns (uint256) {
        return _collateralToPriceMultiplier;
    }

    /**
     * @notice Calculates the current funding fee rates
     * @return longFundingFeeRate long funding fee rate
     * @return shortFundingFeeRate short funding fee rate
     */
    function getCurrentFundingFeeRates()
        external
        view
        returns (int256 longFundingFeeRate, int256 shortFundingFeeRate)
    {
        return feeIntegral.getCurrentFundingFeeRates(
            positionStats.totalLongAssetAmount, positionStats.totalShortAssetAmount
        );
    }

    /**
     * @notice returns the details of a position
     * @dev returns PositionDetails
     */
    function detailsOfPosition(uint256 positionId_) external view returns (PositionDetails memory) {
        Position storage position = positions[positionId_];
        require(position.exists(), "TradePair::detailsOfPosition: Position does not exist");

        // Fee integrals
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);

        uint256 maintenanceMargin =
            absoluteMaintenanceMargin() + feeManager.calculateUserCloseFeeAmount(position.owner, position.volume);

        // Construnct position info
        PositionDetails memory positionDetails;
        positionDetails.id = positionId_;
        positionDetails.margin = position.currentNetMargin(currentBorrowFeeIntegral, currentFundingFeeIntegral);
        positionDetails.volume = position.volume;
        positionDetails.assetAmount = position.assetAmount;
        positionDetails.isShort = position.isShort;
        positionDetails.leverage = position.currentNetLeverage(currentBorrowFeeIntegral, currentFundingFeeIntegral);
        positionDetails.entryPrice = position.entryPrice();
        positionDetails.liquidationPrice =
            position.liquidationPrice(currentBorrowFeeIntegral, currentFundingFeeIntegral, maintenanceMargin);
        positionDetails.currentBorrowFeeAmount = position.currentBorrowFeeAmount(currentBorrowFeeIntegral);
        positionDetails.currentFundingFeeAmount = position.currentFundingFeeAmount(currentFundingFeeIntegral);
        return positionDetails;
    }

    /**
     * @notice Returns if a position is liquidatable
     * @param positionId_ the position id
     */
    function positionIsLiquidatable(uint256 positionId_) external view returns (bool) {
        return _positionIsLiquidatable(positionId_);
    }

    /**
     * @notice Simulates if a position is liquidatable at a given price. Meant to be used by external liquidation services.
     * @param positionId_ the position id
     * @param price_ the price to simulate
     */
    function positionIsLiquidatableAtPrice(uint256 positionId_, int256 price_) external view returns (bool) {
        Position storage position = positions[positionId_];
        require(position.exists(), "TradePair::positionIsLiquidatableAtPrice: position does not exist");
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);

        // Maintenance margin is the absolute maintenance margin plus the fee for closing the position
        uint256 maintenanceMargin =
            absoluteMaintenanceMargin() + feeManager.calculateUserCloseFeeAmount(position.owner, position.volume);

        return position.isLiquidatable(price_, currentBorrowFeeIntegral, currentFundingFeeIntegral, maintenanceMargin);
    }

    /**
     * @notice Returns if the position is short
     * @param positionId_ the position id
     * @return isShort_ true if the position is short
     */
    function positionIsShort(uint256 positionId_) external view returns (bool) {
        return positions[positionId_].isShort;
    }

    /**
     * @notice Returns the current min and max price
     */
    function getCurrentPrices() external view returns (int256, int256) {
        return (priceFeedAdapter.markPriceMin(), priceFeedAdapter.markPriceMax());
    }

    /**
     * @notice returns absolute maintenance margin
     * @dev Currently only the liquidator reward is the absolute maintenance margin, but this could change in the future
     * @return absoluteMaintenanceMargin
     */
    function absoluteMaintenanceMargin() public view returns (uint256) {
        return liquidatorReward;
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /**
     * @notice Sets the basis hourly borrow fee
     * @param borrowFeeRate_ should be in FEE_DECIMALS and per hour
     */
    function setBorrowFeeRate(int256 borrowFeeRate_) public onlyOwner syncFeesBefore {
        feeIntegral.borrowFeeRate = int256(borrowFeeRate_);

        emit SetBorrowFeeRate(borrowFeeRate_);
    }

    /**
     * @notice Sets the surplus fee
     * @param maxFundingFeeRate_ should be in FEE_DECIMALS and per hour
     */
    function setMaxFundingFeeRate(int256 maxFundingFeeRate_) public onlyOwner syncFeesBefore {
        feeIntegral.fundingFeeRate = maxFundingFeeRate_;

        emit SetMaxFundingFeeRate(maxFundingFeeRate_);
    }

    /**
     * @notice Sets the max excess ratio at which the full funding fee is charged
     * @param maxExcessRatio_ should be denominated by FEE_MULTIPLER
     */
    function setMaxExcessRatio(int256 maxExcessRatio_) public onlyOwner syncFeesBefore {
        feeIntegral.maxExcessRatio = maxExcessRatio_;

        emit SetMaxExcessRatio(maxExcessRatio_);
    }

    /**
     * @notice Sets the liquidator reward
     * @param liquidatorReward_ in collateral decimals
     */
    function setLiquidatorReward(uint256 liquidatorReward_) public onlyOwner {
        liquidatorReward = liquidatorReward_;

        emit SetLiquidatorReward(liquidatorReward_);
    }

    /**
     * @notice Sets the minimum leverage
     * @param minLeverage_ in respect to LEVERAGE_MULTIPLIER
     */
    function setMinLeverage(uint128 minLeverage_) public onlyOwner {
        require(minLeverage_ >= MIN_LEVERAGE, "TradePair::setMinLeverage: Leverage too small");
        minLeverage = minLeverage_;

        emit SetMinLeverage(minLeverage_);
    }

    /**
     * @notice Sets the maximum leverage
     * @param maxLeverage_ in respect to LEVERAGE_MULTIPLIER
     */
    function setMaxLeverage(uint128 maxLeverage_) public onlyOwner {
        require(maxLeverage_ <= MAX_LEVERAGE, "TradePair::setMaxLeverage: Leverage to high");
        maxLeverage = maxLeverage_;

        emit SetMaxLeverage(maxLeverage_);
    }

    /**
     * @notice Sets the minimum margin
     * @param minMargin_ in collateral decimals
     */
    function setMinMargin(uint256 minMargin_) public onlyOwner {
        minMargin = minMargin_;

        emit SetMinMargin(minMargin_);
    }

    /**
     * @notice Sets the borrow limit
     * @param volumeLimit_ in collateral decimals
     */
    function setVolumeLimit(uint256 volumeLimit_) public onlyOwner {
        volumeLimit = volumeLimit_;

        emit SetVolumeLimit(volumeLimit_);
    }

    /**
     * @notice Sets the factor for the fee buffer. Denominated by BUFFER_MULTIPLIER
     * @param feeBufferFactor_ the factor for the fee buffer
     */
    function setFeeBufferFactor(int256 feeBufferFactor_) public onlyOwner syncFeesBefore {
        feeBuffer.bufferFactor = feeBufferFactor_;

        emit SetFeeBufferFactor(feeBufferFactor_);
    }

    /**
     * @notice Sets the total volume limit for both long and short positions
     * @param totalVolumeLimit_ total volume limit
     */
    function setTotalVolumeLimit(uint256 totalVolumeLimit_) public onlyOwner {
        totalVolumeLimit = totalVolumeLimit_;
        emit SetTotalVolumeLimit(totalVolumeLimit_);
    }

    /**
     * @notice Sets the price feed adapter
     * @param priceFeedAdapter_ IPriceFeedAdapter
     * @dev PriceFeedAdapter checks that asset and collateral decimals are less or equal than price decimals,
     * So they can be savely used here.
     */
    function setPriceFeedAdapter(IPriceFeedAdapter priceFeedAdapter_) public onlyOwner {
        // Set Decimals

        // Calculate Multipliers
        _collateralToPriceMultiplier = PRICE_MULTIPLIER / (10 ** priceFeedAdapter_.collateralDecimals());

        // Set PriceFeedAdapter
        priceFeedAdapter = priceFeedAdapter_;
        emit SetPriceFeedAdapter(address(priceFeedAdapter_));
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns the payout to the maker of this position
     * @param position_ the position to calculate the payout for
     * @return the payout to the maker of this position
     */
    function _getPayoutToMaker(Position storage position_) private view returns (uint256) {
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position_.isShort);

        int256 netEquity = position_.currentNetEquity(
            _getCurrentPrice(position_.isShort, true), currentBorrowFeeIntegral, currentFundingFeeIntegral
        );
        return netEquity > 0 ? uint256(netEquity) : 0;
    }

    /**
     * @notice Returns the current price
     * @param position_ the position to calculate the price for
     * @return the current price
     */
    function _getCurrentNetPnL(Position storage position_) private view returns (int256) {
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position_.isShort);

        return position_.currentNetPnL(
            _getCurrentPrice(position_.isShort, true), currentBorrowFeeIntegral, currentFundingFeeIntegral
        );
    }

    /**
     * @dev Returns borrow and funding fee intagral for long or short position
     */
    function _getCurrentFeeIntegrals(bool isShort_) internal view returns (int256, int256) {
        // Funding fee integrals differ for short and long positions
        (int256 longFeeIntegral, int256 shortFeeIntegral) = feeIntegral.getCurrentFundingFeeIntegrals(
            positionStats.totalLongAssetAmount, positionStats.totalShortAssetAmount
        );
        int256 currentFundingFeeIntegral = isShort_ ? shortFeeIntegral : longFeeIntegral;

        // Borrow fee integrals are the same for short and long positions
        int256 currentBorrowFeeIntegral = feeIntegral.getCurrentBorrowFeeIntegral();

        // Return the current fee integrals
        return (currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    /**
     * @notice Returns if a position is liquidatable
     * @param positionId_ the position id
     */
    function _positionIsLiquidatable(uint256 positionId_) internal view returns (bool) {
        Position storage position = positions[positionId_];
        require(position.exists(), "TradePair::_positionIsLiquidatable: position does not exist");
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);

        // Maintenance margin is the absolute maintenance margin plus the fee for closing the position
        uint256 maintenanceMargin =
            absoluteMaintenanceMargin() + feeManager.calculateUserCloseFeeAmount(position.owner, position.volume);

        return position.isLiquidatable(
            _getCurrentPrice(position.isShort, true),
            currentBorrowFeeIntegral,
            currentFundingFeeIntegral,
            maintenanceMargin
        );
    }

    /**
     * @notice Returns current price depending on the direction of the trade and if is buying or selling
     * @param isShort_ bool if the position is short
     * @param isDecreasingPosition_ true on closing and decreasing the position. False on open and extending.
     */
    function _getCurrentPrice(bool isShort_, bool isDecreasingPosition_) internal view returns (int256) {
        if (isShort_ == isDecreasingPosition_) {
            // buy long, sell short
            // get maxprice
            return priceFeedAdapter.markPriceMax();
        } else {
            // buy short, sell long
            // get minprice
            return priceFeedAdapter.markPriceMin();
        }
    }

    /* ========== RESTRICTION FUNCTIONS ========== */

    /**
     * @dev Reverts when sender is not the TradeManager
     */
    function _onlyTradeManager() private view {
        require(msg.sender == address(tradeManager), "TradePair::_onlyTradeManager: only TradeManager");
    }

    /**
     * @dev Reverts when either long or short positions extend the total volume limit
     */
    function _checkTotalVolumeLimitAfter() private view {
        require(
            positionStats.totalLongVolume <= totalVolumeLimit,
            "TradePair::_checkTotalVolumeLimitAfter: total volume limit reached by long positions"
        );
        require(
            positionStats.totalShortVolume <= totalVolumeLimit,
            "TradePair::_checkTotalVolumeLimitAfter: total volume limit reached by short positions"
        );
    }

    /**
     * @notice Verifies that the position did not get altered this block and updates lastAlterationBlock of this position.
     * @dev Positions must not be altered at the same block. This reduces that risk of sandwich attacks.
     */
    function _verifyAndUpdateLastAlterationBlock(uint256 positionId_) private {
        require(
            positions[positionId_].lastAlterationBlock < ArbSys(address(100)).arbBlockNumber(),
            "TradePair::_verifyAndUpdateLastAlterationBlock: position already altered this block"
        );
        positions[positionId_].lastAlterationBlock = uint40(ArbSys(address(100)).arbBlockNumber());
    }

    /**
     * @notice Checks if the position is valid:
     *
     * - The position must exists
     * - The position must not be liquidatable
     * - The position must not reach the volume limit
     * - The position must not reach the leverage limits
     */
    function _verifyPositionsValidity(uint256 positionId_) private view {
        Position storage _position = positions[positionId_];

        // Position must exist
        require(_position.exists(), "TradePair::_verifyPositionsValidity: position does not exist");

        // Position must not be liquidatable
        {
            (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) =
                _getCurrentFeeIntegrals(_position.isShort);
            require(
                !_position.isLiquidatable(
                    _getCurrentPrice(_position.isShort, true),
                    currentBorrowFeeIntegral,
                    currentFundingFeeIntegral,
                    absoluteMaintenanceMargin()
                ),
                "TradePair::_verifyPositionsValidity: position would be liquidatable"
            );
        }

        // Position must not reach the volume limit
        {
            require(
                _position.currentVolume(_getCurrentPrice(_position.isShort, false)) <= volumeLimit,
                "TradePair_verifyPositionsValidity: Borrow limit reached"
            );
        }

        // The position must not reach the leverage limits
        _verifyLeverage(_position.lastNetLeverage());
    }

    /**
     * @dev Reverts when leverage is out of bounds
     */
    function _verifyLeverage(uint256 leverage_) private view {
        // We add/subtract 1 to the limits to account for rounding errors
        require(
            leverage_ >= minLeverage - 1, "TradePair::_verifyLeverage: leverage must be above or equal min leverage"
        );
        require(leverage_ <= maxLeverage, "TradePair::_verifyLeverage: leverage must be under or equal max leverage");
    }

    function _verifyOwner(address maker_, uint256 positionId_) private view {
        require(positions[positionId_].owner == maker_, "TradePair::_verifyOwner: not the owner");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev updates the fee collected fees of this position. Necessary before changing its volume.
     * @param positionId_ the id of the position
     */
    modifier updatePositionFees(uint256 positionId_) {
        _updatePositionFees(positionId_);
        _;
    }

    /**
     * @dev collects fees by transferring them to the FeeManager
     */
    modifier syncFeesBefore() {
        syncPositionFees();
        _;
    }

    /**
     * @dev reverts when position is not liquidatable
     */
    modifier onlyLiquidatable(uint256 positionId_) {
        require(_positionIsLiquidatable(positionId_), "TradePair::onlyLiquidatable: position is not liquidatable");
        _;
    }

    /**
     * @dev Reverts when aggregated size reaches asset amount limit after transaction
     */
    modifier checkTotalVolumeLimit() {
        _;
        _checkTotalVolumeLimitAfter();
    }

    /**
     * @notice Checks if the alteration is valid. Alteration is valid, when:
     *
     * - The position did not get altered at this block
     * - The position is not liquidatable after the alteration
     */
    modifier onlyValidAlteration(uint256 positionId_) {
        _verifyAndUpdateLastAlterationBlock(positionId_);
        _;
        _verifyPositionsValidity(positionId_);
    }

    /**
     * @dev verifies that leverage is in bounds
     */
    modifier verifyLeverage(uint256 leverage_) {
        _verifyLeverage(leverage_);
        _;
    }

    /**
     * @dev Verfies that sender is the owner of the position
     */
    modifier verifyOwner(address maker_, uint256 positionId_) {
        _verifyOwner(maker_, positionId_);
        _;
    }

    /**
     * @dev Verfies that TradeManager sent the transactions
     */
    modifier onlyTradeManager() {
        _onlyTradeManager();
        _;
    }
}