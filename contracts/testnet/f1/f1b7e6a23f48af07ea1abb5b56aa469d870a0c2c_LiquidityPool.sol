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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

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

/**
 * @notice Struct to be returned by view functions to inform about locked and unlocked pool shares of a user
 * @custom:member totalPoolShares Total amount of pool shares of the user in this pool
 * @custom:member unlockedPoolShares Total amount of unlocked pool shares of the user in this pool
 * @custom:member totalShares Total amount of pool shares of the user in this pool
 * @custom:member unlockedShares Total amount of unlocked pool shares of the user in this pool
 * @custom:member totalAssets  Total amount of assets of the user in this pool
 * @custom:member unlockedAssets Total amount of unlocked assets of the user in this pool
 */
struct UserPoolDetails {
    uint256 poolId;
    uint256 totalPoolShares;
    uint256 unlockedPoolShares;
    uint256 totalShares;
    uint256 unlockedShares;
    uint256 totalAssets;
    uint256 unlockedAssets;
}

interface ILiquidityPool {
    /* ========== EVENTS ========== */

    event PoolAdded(uint256 indexed poolId, uint256 lockTime, uint256 multiplier);

    event PoolUpdated(uint256 indexed poolId, uint256 lockTime, uint256 multiplier);

    event AddedToPool(uint256 indexed poolId, uint256 assetAmount, uint256 amount, uint256 shares);

    event RemovedFromPool(address indexed user, uint256 indexed poolId, uint256 poolShares, uint256 lpShares);

    event DepositedFees(address liquidityPoolAdapter, uint256 amount);

    event UpdatedDefaultLockTime(uint256 defaultLockTime);

    event UpdatedEarlyWithdrawalFee(uint256 earlyWithdrawalFee);

    event UpdatedEarlyWithdrawalTime(uint256 earlyWithdrawalTime);

    event UpdatedMinimumAmount(uint256 minimumAmount);

    event DepositedProfit(address indexed liquidityPoolAdapter, uint256 profit);

    event PayedOutLoss(address indexed liquidityPoolAdapter, uint256 loss);

    event CollectedEarlyWithdrawalFee(address user, uint256 amount);

    /* ========== CORE FUNCTIONS ========== */

    function deposit(uint256 amount, uint256 minOut) external returns (uint256);

    function withdraw(uint256 lpAmount, uint256 minOut) external returns (uint256);

    function depositAndLock(uint256 amount, uint256 minOut, uint256 poolId) external returns (uint256);

    function requestLossPayout(uint256 loss) external;

    function depositProfit(uint256 profit) external;

    function depositFees(uint256 amount) external;

    function previewPoolsOf(address user) external view returns (UserPoolDetails[] memory);

    function previewRedeemPoolShares(uint256 poolShares_, uint256 poolId_) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function updateDefaultLockTime(uint256 defaultLockTime) external;

    function updateEarlyWithdrawalFee(uint256 earlyWithdrawalFee) external;

    function updateEarlyWithdrawalTime(uint256 earlyWithdrawalTime) external;

    function updateMinimumAmount(uint256 minimumAmount) external;

    function addPool(uint40 lockTime_, uint16 multiplier_) external returns (uint256);

    function updatePool(uint256 poolId_, uint40 lockTime_, uint16 multiplier_) external;

    /* ========== VIEW FUNCTIONS ========== */

    function availableLiquidity() external view returns (uint256);

    function canTransferLps(address user) external view returns (bool);

    function canWithdrawLps(address user) external view returns (bool);

    function userWithdrawalFee(address user) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ILiquidityPoolVault {
    /* ========== EVENTS ========== */

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /* ========== VIEW FUNCTIONS ========== */

    function asset() external view returns (address assetTokenAddress);

    function totalAssets() external view returns (uint256 totalManagedAssets);

    function convertToShares(uint256 assets) external view returns (uint256 shares);

    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);
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

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IController.sol";
import "../interfaces/ILiquidityPool.sol";
import "./LiquidityPoolVault.sol";
import "../shared/Constants.sol";
import "../shared/UnlimitedOwnable.sol";

/**
 * @notice User deposits into a lock pool
 * @custom:member poolShares Amount of lp shares deposited
 * @custom:member depositTime timestamp when the deposit happened
 */
struct UserPoolDeposit {
    uint256 poolShares;
    uint40 depositTime;
}

/**
 * @notice Aggregated Info about a users locked shares in a lock pool
 * @custom:member userPoolShares Amount of lp shares deposited
 * @custom:member unlockedPoolShares Amount of lp shares unlocked
 * @custom:member nextIndex The index of the next, not yet unlocked, UserPoolDeposit
 * @custom:member length The length of the UserPoolDeposit array
 * @custom:member deposits mapping of UserPoolDeposit; Each deposit is represented by one entry.
 */
struct UserPoolInfo {
    uint256 userPoolShares;
    uint256 unlockedPoolShares;
    uint128 nextIndex;
    uint128 length;
    mapping(uint256 => UserPoolDeposit) deposits;
}

/**
 * @notice Lock pool information
 * @custom:member lockTime Lock time of the deposit
 * @custom:member multiplier Multiplier of the deposit
 * @custom:member amount amount of collateral in this pool
 * @custom:member totalPoolShares amount of pool shares in this pool
 */
struct LockPoolInfo {
    uint40 lockTime;
    uint16 multiplier;
    uint256 amount;
    uint256 totalPoolShares;
}

/**
 * @title LiquidityPool
 * @notice LiquidityPool is a contract that allows users to deposit and withdraw liquidity.
 *
 * It follows most of the EIP4625 standard. Users deposit an asset and receive liquidity pool shares (LPS).
 * Users can withdraw their LPS at any time.
 * Users can also decide to lock their LPS for a period of time to receive a multiplier on their rewards.
 * The lock mechanism is realized by the pools in this contract.
 * Each pool defines a different lock period and multiplier.
 */
contract LiquidityPool is ILiquidityPool, UnlimitedOwnable, Initializable, LiquidityPoolVault {
    using SafeERC20 for IERC20Metadata;
    using Math for uint256;

    /* ========== CONSTANTS ========== */

    uint256 constant MAXIMUM_MULTIPLIER = 5 * FULL_PERCENT;

    uint256 constant MAXIMUM_LOCK_TIME = 365 days;

    /* ========== STATE VARIABLES ========== */

    /// @notice Controller contract.
    IController public immutable controller;

    /// @notice Time locked after the deposit.
    uint256 public defaultLockTime;

    /// @notice Relative fee to early withdraw non-locked shares.
    uint256 public earlyWithdrawalFee;

    /// @notice Time when the early withdrawal fee is applied shares.
    uint256 public earlyWithdrawalTime;

    /// @notice minimum amount of asset to stay in the pool.
    uint256 public minimumAmount;

    /// @notice Array of pools with different lock time and multipliers.
    LockPoolInfo[] public pools;

    /// @notice Last deposit time of a user.
    mapping(address => uint256) public lastDepositTime;

    /// @notice Mapping of UserPoolInfo for each user for each pool. userPoolInfo[poolId][user]
    mapping(uint256 => mapping(address => UserPoolInfo)) public userPoolInfo;

    // Storage gap
    uint256[50] ___gap;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Initialize the contract.
     * @param unlimitedOwner_ The address of the unlimited owner.
     * @param collateral_ The address of the collateral.
     * @param controller_ The address of the controller.
     */

    constructor(IUnlimitedOwner unlimitedOwner_, IERC20Metadata collateral_, IController controller_)
        LiquidityPoolVault(collateral_)
        UnlimitedOwnable(unlimitedOwner_)
    {
        controller = controller_;
    }

    /* ========== INITIALIZER ========== */

    /**
     * @notice Initialize the contract.
     * @param name_ The name of the pool's ERC20 liquidity token.
     * @param symbol_ The symbol of the pool's ERC20 liquidity token.
     * @param defaultLockTime_ The default lock time of the pool.
     * @param earlyWithdrawalFee_ The early withdrawal fee of the pool.
     * @param earlyWithdrawalTime_ The early withdrawal time of the pool.
     * @param minimumAmount_ The minimum amount of the pool (subtracted from available liquidity).
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 defaultLockTime_,
        uint256 earlyWithdrawalFee_,
        uint256 earlyWithdrawalTime_,
        uint256 minimumAmount_
    ) public onlyOwner initializer {
        __ERC20_init(name_, symbol_);

        _updateDefaultLockTime(defaultLockTime_);
        _updateEarlyWithdrawalFee(earlyWithdrawalFee_);
        _updateEarlyWithdrawalTime(earlyWithdrawalTime_);
        _updateMinimumAmount(minimumAmount_);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Returns the total available liquidity in the pool.
     * @return The total available liquidity in the pool.
     * @dev The available liquidity is reduced by the minimum amount to make sure no rounding errors occur when liquidity is
     * drained.
     */
    function availableLiquidity() public view returns (uint256) {
        uint256 _totalAssets = totalAssets();

        if (_totalAssets > minimumAmount) {
            _totalAssets -= minimumAmount;
        } else {
            _totalAssets = 0;
        }

        return _totalAssets;
    }

    /**
     * @notice Returns information about user's pool deposits. Including locked and unlocked pool shares, shares and assets.
     * @return userPools an array of UserPoolDetails. This informs about current user's locked and unlocked shares
     */
    function previewPoolsOf(address user_) external view returns (UserPoolDetails[] memory userPools) {
        userPools = new UserPoolDetails[](pools.length);

        for (uint256 i = 0; i < pools.length; ++i) {
            userPools[i] = previewPoolOf(user_, i);
        }
    }

    /**
     * @notice Returns information about user's pool deposits. Including locked and unlocked pool shares, shares and assets.
     * @param user_ the user to get the pool details for
     * @param poolId_ the id of the pool to preview
     * @return userPool the UserPoolDetails. This informs about current user's locked and unlocked shares
     */
    function previewPoolOf(address user_, uint256 poolId_) public view returns (UserPoolDetails memory userPool) {
        userPool.poolId = poolId_;
        userPool.totalPoolShares = userPoolInfo[poolId_][user_].userPoolShares;
        userPool.unlockedPoolShares = _totalUnlockedPoolShares(user_, poolId_);
        userPool.totalShares = _poolSharesToShares(userPool.totalPoolShares, poolId_);
        userPool.unlockedShares = _poolSharesToShares(userPool.unlockedPoolShares, poolId_);
        userPool.totalAssets = previewRedeem(userPool.totalShares);
        userPool.unlockedAssets = previewRedeem(userPool.unlockedShares);
    }

    /**
     * @notice Function to check if a user is able to transfer their shares to another address
     * @param user_ the address of the user
     * @return bool true if the user is able to transfer their shares
     */
    function canTransferLps(address user_) public view returns (bool) {
        uint256 transferLockTime = earlyWithdrawalTime > defaultLockTime ? earlyWithdrawalTime : defaultLockTime;
        return block.timestamp - lastDepositTime[user_] >= transferLockTime;
    }

    /**
     * @notice Function to check if a user is able to withdraw their shares, with a possible loss to earlyWithdrawalFee
     * @param user_ the address of the user
     * @return bool true if the user is able to withdraw their shares
     */
    function canWithdrawLps(address user_) public view returns (bool) {
        return block.timestamp - lastDepositTime[user_] >= defaultLockTime;
    }

    /**
     * @notice Returns a possible earlyWithdrawalFee for a user. Fee applies when the user withdraws after the earlyWithdrawalTime and before the defaultLockTime
     * @param user_ the address of the user
     * @return uint256 the earlyWithdrawalFee or 0
     */
    function userWithdrawalFee(address user_) public view returns (uint256) {
        return block.timestamp - lastDepositTime[user_] < earlyWithdrawalTime ? earlyWithdrawalFee : 0;
    }

    /**
     * @notice Preview function to convert locked pool shares to asset
     * @param poolShares_ the amount of pool shares to convert
     * @param poolId_ the id of the pool to convert
     * @return the amount of assets that would be received
     */
    function previewRedeemPoolShares(uint256 poolShares_, uint256 poolId_) external view returns (uint256) {
        return previewRedeem(_poolSharesToShares(poolShares_, poolId_));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Deposits an amount of the collateral asset.
     * @param assets_ The amount of the collateral asset to deposit.
     * @param minShares_ The desired minimum amount to receive in exchange for the deposited collateral. Reverts otherwise.
     * @return The amount of shares received for the deposited collateral.
     */
    function deposit(uint256 assets_, uint256 minShares_) external updateUser(msg.sender) returns (uint256) {
        return _depositAsset(assets_, minShares_, msg.sender);
    }

    /**
     * @notice Deposits an amount of the collateral asset and locks it directly
     * @param assets_ The amount of the collateral asset to deposit.
     * @param minShares_ The desired minimum amount to receive in exchange for the deposited collateral. Reverts otherwise.
     * @param poolId_ Id of the pool to lock the deposit
     * @return The amount of shares received for the deposited collateral.
     */
    function depositAndLock(uint256 assets_, uint256 minShares_, uint256 poolId_)
        external
        verifyPoolId(poolId_)
        updateUser(msg.sender)
        returns (uint256)
    {
        // deposit assets and mint directly for this contract as we're locking the tokens right away
        uint256 shares = _depositAsset(assets_, minShares_, address(this));

        _lockShares(shares, poolId_, msg.sender);

        return shares;
    }

    /**
     * @notice Locks LPs for a user.
     * @param shares_ The amount of shares to lock.
     * @param poolId_ Id of the pool to lock the deposit
     */
    function lockShares(uint256 shares_, uint256 poolId_) external verifyPoolId(poolId_) {
        _transfer(msg.sender, address(this), shares_);
        _lockShares(shares_, poolId_, msg.sender);
    }

    /**
     * @dev deposits assets into the pool
     */
    function _depositAsset(uint256 assets_, uint256 minShares_, address receiver_) private returns (uint256) {
        uint256 shares = previewDeposit(assets_);

        require(shares >= minShares_, "LiquidityPool::_depositAsset: Bad slippage");

        _deposit(msg.sender, receiver_, assets_, shares);

        return shares;
    }

    /**
     * @dev Internal function to lock shares
     */
    function _lockShares(uint256 lpShares_, uint256 poolId_, address user_) private {
        LockPoolInfo storage poolInfo = pools[poolId_];

        uint256 newPoolShares =
            _convertToPoolShares(lpShares_, poolInfo.totalPoolShares, poolInfo.amount, Math.Rounding.Down);

        poolInfo.amount += lpShares_;
        poolInfo.totalPoolShares += newPoolShares;

        emit AddedToPool(poolId_, previewRedeem(lpShares_), lpShares_, newPoolShares);

        UserPoolInfo storage _userPoolInfo = userPoolInfo[poolId_][user_];
        _addUserPoolDeposit(_userPoolInfo, newPoolShares);
    }

    function _addUserPoolDeposit(UserPoolInfo storage _userPoolInfo, uint256 newPoolShares_) private {
        _userPoolInfo.userPoolShares += newPoolShares_;

        _userPoolInfo.deposits[_userPoolInfo.length] = UserPoolDeposit(newPoolShares_, uint40(block.timestamp));
        _userPoolInfo.length++;
    }

    /**
     * @notice Withdraws an amount of the collateral asset.
     * @param shares_ The amount of shares to withdraw.
     * @param minOut_ The desired minimum amount of collateral to receive in exchange for the withdrawn shares. Reverts otherwise.
     * @return The amount of collateral received for the withdrawn shares.
     */
    function withdraw(uint256 shares_, uint256 minOut_) external canWithdraw(msg.sender) returns (uint256) {
        return _withdrawShares(msg.sender, shares_, minOut_, msg.sender);
    }

    /**
     * @notice Unlocks and withdraws an amount of the collateral asset.
     * @param poolId_ the id of the pool to unlock the shares from
     * @param poolShares_ the amount of pool shares to unlock and withdraw
     * @param minOut_ the desired minimum amount of collateral to receive in exchange for the withdrawn shares. Reverts otherwise.
     * return the amount of collateral received for the withdrawn shares.
     */
    function withdrawFromPool(uint256 poolId_, uint256 poolShares_, uint256 minOut_)
        external
        canWithdraw(msg.sender)
        verifyPoolId(poolId_)
        updateUserPoolDeposits(msg.sender, poolId_)
        returns (uint256)
    {
        uint256 lpAmount = _unlockShares(msg.sender, poolId_, poolShares_);
        return _withdrawShares(address(this), lpAmount, minOut_, msg.sender);
    }

    /**
     * @notice Unlocks shares and returns them to the user.
     * @param poolId_ the id of the pool to unlock the shares from
     * @param poolShares_ the amount of pool shares to unlock
     * @return lpAmount the amount of shares unlocked
     */
    function unlockShares(uint256 poolId_, uint256 poolShares_)
        external
        verifyPoolId(poolId_)
        updateUserPoolDeposits(msg.sender, poolId_)
        returns (uint256 lpAmount)
    {
        lpAmount = _unlockShares(msg.sender, poolId_, poolShares_);
        _transfer(address(this), msg.sender, lpAmount);
    }

    /**
     * @dev Withdraws share frm the pool
     */
    function _withdrawShares(address user, uint256 shares, uint256 minOut, address receiver)
        private
        returns (uint256)
    {
        uint256 assets = previewRedeem(shares);

        require(assets >= minOut, "LiquidityPool::_withdrawShares: Bad slippage");

        // When user withdraws before earlyWithdrawalPeriod is over, they will be charged a fee
        uint256 feeAmount = userWithdrawalFee(receiver) * assets / FULL_PERCENT;
        if (feeAmount > 0) {
            assets -= feeAmount;
            emit CollectedEarlyWithdrawalFee(user, feeAmount);
        }

        _withdraw(user, receiver, user, assets, shares);

        return assets;
    }

    /**
     * @dev Internal function to unlock pool shares
     */
    function _unlockShares(address user_, uint256 poolId_, uint256 poolShares_) private returns (uint256 lpAmount) {
        require(poolShares_ > 0, "LiquidityPool::_unlockShares: Cannot withdraw zero shares");
        UserPoolInfo storage _userPoolInfo = userPoolInfo[poolId_][user_];

        if (poolShares_ == type(uint256).max) {
            poolShares_ = _userPoolInfo.unlockedPoolShares;
        } else {
            require(
                _userPoolInfo.unlockedPoolShares >= poolShares_,
                "LiquidityPool::_unlockShares: User does not have enough unlocked pool shares"
            );
        }

        // Decrease users unlocked pool shares
        unchecked {
            _userPoolInfo.unlockedPoolShares -= poolShares_;
            _userPoolInfo.userPoolShares -= poolShares_;
        }

        // transform
        LockPoolInfo storage poolInfo = pools[poolId_];
        lpAmount = _poolSharesToShares(poolShares_, poolId_);

        // Remove total pool shares
        poolInfo.totalPoolShares -= poolShares_;
        poolInfo.amount -= lpAmount;

        emit RemovedFromPool(user_, poolId_, poolShares_, lpAmount);
    }

    /**
     * @dev Converts Pool Shares to Shares
     */
    function _poolSharesToShares(uint256 poolShares_, uint256 poolId_) internal view returns (uint256) {
        if (pools[poolId_].totalPoolShares == 0) {
            return 0;
        } else {
            return pools[poolId_].amount * poolShares_ / pools[poolId_].totalPoolShares;
        }
    }

    /**
     * @dev Converts an amount of shares to the equivalent amount of pool shares
     */
    function _convertToPoolShares(
        uint256 newLps_,
        uint256 totalPoolShares_,
        uint256 lockedLps_,
        Math.Rounding rounding_
    ) private pure returns (uint256 newPoolShares) {
        return (newLps_ == 0 || totalPoolShares_ == 0)
            ? newLps_ * 1e12
            : newLps_.mulDiv(totalPoolShares_, lockedLps_, rounding_);
    }

    /**
     * @notice Previews the total amount of unlocked pool shares for a user
     * @param user_ the user to preview the unlocked pool shares for
     * @param poolId_ the id of the pool to preview
     * @return the total amount of unlocked pool shares
     */
    function _totalUnlockedPoolShares(address user_, uint256 poolId_) internal view returns (uint256) {
        (uint256 newUnlockedPoolShares,) = _previewPoolShareUnlock(user_, poolId_);
        return userPoolInfo[poolId_][user_].unlockedPoolShares + newUnlockedPoolShares;
    }

    /**
     * @dev Updates the user's pool deposit info. This function effectively unlockes the eligible pool shares.
     * It works by iterating over the user's deposits and unlocking the shares that have been locked for more than the
     * lock period.
     */
    function _updateUserPoolDeposits(address user_, uint256 poolId_) private {
        UserPoolInfo storage _userPoolInfo = userPoolInfo[poolId_][user_];

        (uint256 newUnlockedShares, uint256 nextIndex) = _previewPoolShareUnlock(user_, poolId_);

        if (newUnlockedShares > 0) {
            _userPoolInfo.nextIndex = uint128(nextIndex);
            _userPoolInfo.unlockedPoolShares += newUnlockedShares;
        }
    }

    /**
     * @notice Previews the amount of unlocked pool shares for a user, by iterating through the user's deposits.
     * @param user_ the user to preview the unlocked pool shares for
     * @param poolId_ the id of the pool to preview
     * @return newUnlockedPoolShares the total amount of new unlocked pool shares
     * @return newNextIndex the index of the next deposit to be unlocked
     */
    function _previewPoolShareUnlock(address user_, uint256 poolId_)
        private
        view
        returns (uint256 newUnlockedPoolShares, uint256 newNextIndex)
    {
        uint256 poolLockTime = pools[poolId_].lockTime;
        UserPoolInfo storage _userPoolInfo = userPoolInfo[poolId_][user_];

        uint256 depositsCount = _userPoolInfo.length;
        for (newNextIndex = _userPoolInfo.nextIndex; newNextIndex < depositsCount; newNextIndex++) {
            if (block.timestamp - _userPoolInfo.deposits[newNextIndex].depositTime >= poolLockTime) {
                // deposit can be unlocked
                newUnlockedPoolShares += _userPoolInfo.deposits[newNextIndex].poolShares;
            } else {
                break;
            }
        }
    }

    /* ========== PROFIT/LOSS FUNCTIONS ========== */

    /**
     * @notice deposits a protocol profit when a trader made a loss
     * @param profit_ the profit of the asset with respect to the asset multiplier
     * @dev the allowande of the sender needs to be sufficient
     */
    function depositProfit(uint256 profit_) external onlyValidLiquidityPoolAdapter {
        _asset.safeTransferFrom(msg.sender, address(this), profit_);

        emit DepositedProfit(msg.sender, profit_);
    }

    /**
     * @notice Deposits fees from the protocol into this liquidity pool. Distributes assets over the liquidity providers by increasing LP shares.
     * @param amount_ the amount of fees to deposit
     */
    function depositFees(uint256 amount_) external onlyValidLiquidityPoolAdapter {
        (uint256[] memory multipliedPoolValues, uint256 totalMultipliedValues) = _getPoolMultipliers();

        // multiply the supply by the full percent so we use the same multiplier as the locked pools
        uint256 lpSupplyMultiplied = totalSupply() * FULL_PERCENT;

        if (lpSupplyMultiplied > 0 && totalMultipliedValues > 0) {
            // calculate the asset amount_ with which to mint new lp tokens that will be distributed as a reward to the already locked lps
            uint256 assetsToMint = amount_ * totalMultipliedValues / (lpSupplyMultiplied + totalMultipliedValues);

            // transfer assets belonging to lps without the multiplier
            unchecked {
                _asset.safeTransferFrom(msg.sender, address(this), amount_ - assetsToMint);
            }

            uint256 newShares = previewDeposit(assetsToMint);

            // transfer assets belonging to lps with the multiplier
            _asset.safeTransferFrom(msg.sender, address(this), assetsToMint);
            // mint new shares to distribute to locked tps
            _mint(address(this), newShares);

            uint256 newPoolLpsLeft = newShares;
            for (uint256 i; i < multipliedPoolValues.length - 1; ++i) {
                uint256 newPoolLps = newShares * multipliedPoolValues[i] / totalMultipliedValues;
                newPoolLpsLeft -= newPoolLps;
                pools[i].amount += newPoolLps;
            }

            pools[multipliedPoolValues.length - 1].amount += newPoolLpsLeft;
        } else {
            _asset.safeTransferFrom(msg.sender, address(this), amount_);
        }

        emit DepositedFees(msg.sender, amount_);
    }

    /**
     * @notice requests payout of a protocol loss when a trader made a profit
     * @param loss_ the requested amount of the asset with respect to the asset multiplier
     * @dev pays out the loss when msg.sender is a registered liquidity pool adapter
     */
    function requestLossPayout(uint256 loss_) external onlyValidLiquidityPoolAdapter {
        require(loss_ <= availableLiquidity(), "LiquidityPool::requestLossPayout: Payout exceeds limit");
        _asset.safeTransfer(msg.sender, loss_);
        emit PayedOutLoss(msg.sender, loss_);
    }

    /**
     * @dev Returns all pool multipliers and the sum of all pool multipliers
     */
    function _getPoolMultipliers()
        private
        view
        returns (uint256[] memory multipliedPoolValues, uint256 totalMultipliedValues)
    {
        multipliedPoolValues = new uint256[](pools.length);

        for (uint256 i; i < multipliedPoolValues.length; ++i) {
            uint256 multiplier = pools[i].multiplier;
            if (multiplier > 0) {
                multipliedPoolValues[i] = pools[i].amount * multiplier;
                totalMultipliedValues += multipliedPoolValues[i];
            }
        }
    }

    /**
     * @dev Overwrite of the ERC20 function. Includes a check if the user is able to transfer their shares, which
     * depends on if the last deposit time longer ago than the defaultLockTime.
     */
    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        // We have to make sure that this is neither a mint or burn, nor a lock or unlock
        if (to != address(this) && from != address(this) && from != address(0) && to != address(0)) {
            _canTransfer(from);
        }
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /**
     * @notice Add pool with a lock time and a multiplier
     * @param lockTime_ Deposit lock time in seconds
     * @param multiplier_ Multiplier that applies to the pool. 10_00 is multiplier of x1.1, 100_00 is x2.0.
     * @dev User receives the reward for the normal shares, and the reward for the locked shares additional to that.
     * This is why 10_00 will total to a x1.1 multiplier.
     */
    function addPool(uint40 lockTime_, uint16 multiplier_)
        external
        onlyOwner
        verifyPoolParameters(lockTime_, multiplier_)
        returns (uint256)
    {
        pools.push(LockPoolInfo(lockTime_, multiplier_, 0, 0));

        emit PoolAdded(pools.length - 1, lockTime_, multiplier_);

        return pools.length - 1;
    }

    /**
     * @notice Updates a lock pool
     * @param poolId_ Id of the pool to update
     * @param lockTime_ Deposit lock time in seconds
     * @param multiplier_ Multiplier that applies to the pool. 10_00 is multiplier of x1.1, 100_00 is x2.0.
     */
    function updatePool(uint256 poolId_, uint40 lockTime_, uint16 multiplier_)
        external
        onlyOwner
        verifyPoolId(poolId_)
        verifyPoolParameters(lockTime_, multiplier_)
    {
        if (lockTime_ > 0) {
            pools[poolId_].lockTime = lockTime_;
        }

        if (multiplier_ > 0) {
            pools[poolId_].multiplier = multiplier_;
        } else if (lockTime_ == 0) {
            // if both values are 0, unlock them and set multiplier to 0
            pools[poolId_].lockTime = 0;
            pools[poolId_].multiplier = 0;
        }

        emit PoolUpdated(poolId_, lockTime_, multiplier_);
    }

    /**
     * @notice Update default lock time
     * @param defaultLockTime_ default lock time
     */
    function updateDefaultLockTime(uint256 defaultLockTime_) external onlyOwner {
        _updateDefaultLockTime(defaultLockTime_);
    }

    /**
     * @notice Update default lock time
     * @param defaultLockTime_ default lock time
     */
    function _updateDefaultLockTime(uint256 defaultLockTime_) private {
        defaultLockTime = defaultLockTime_;

        emit UpdatedDefaultLockTime(defaultLockTime_);
    }

    /**
     * @notice Update early withdrawal fee
     * @param earlyWithdrawalFee_ early withdrawal fee
     */
    function updateEarlyWithdrawalFee(uint256 earlyWithdrawalFee_) external onlyOwner {
        _updateEarlyWithdrawalFee(earlyWithdrawalFee_);
    }

    /**
     * @notice Update early withdrawal fee
     * @param earlyWithdrawalFee_ early withdrawal fee
     */
    function _updateEarlyWithdrawalFee(uint256 earlyWithdrawalFee_) private {
        earlyWithdrawalFee = earlyWithdrawalFee_;

        emit UpdatedEarlyWithdrawalFee(earlyWithdrawalFee_);
    }

    /**
     * @notice Update early withdrawal time
     * @param earlyWithdrawalTime_ early withdrawal time
     */
    function updateEarlyWithdrawalTime(uint256 earlyWithdrawalTime_) external onlyOwner {
        _updateEarlyWithdrawalTime(earlyWithdrawalTime_);
    }

    /**
     * @notice Update early withdrawal time
     * @param earlyWithdrawalTime_ early withdrawal time
     */
    function _updateEarlyWithdrawalTime(uint256 earlyWithdrawalTime_) private {
        earlyWithdrawalTime = earlyWithdrawalTime_;

        emit UpdatedEarlyWithdrawalTime(earlyWithdrawalTime_);
    }

    /**
     * @notice Update minimum amount
     * @param minimumAmount_ minimum amount
     */
    function updateMinimumAmount(uint256 minimumAmount_) external onlyOwner {
        _updateMinimumAmount(minimumAmount_);
    }

    /**
     * @notice Update minimum amount
     * @param minimumAmount_ minimum amount
     */
    function _updateMinimumAmount(uint256 minimumAmount_) private {
        minimumAmount = minimumAmount_;

        emit UpdatedMinimumAmount(minimumAmount_);
    }

    function _updateUser(address user) private {
        lastDepositTime[user] = block.timestamp;
    }

    /* ========== RESTRICTION FUNCTIONS ========== */

    function _canTransfer(address user) private view {
        require(canTransferLps(user), "LiquidityPool::_canTransfer: User cannot transfer LP tokens");
    }

    function _canWithdrawLps(address user) private view {
        require(canWithdrawLps(user), "LiquidityPool::_canWithdrawLps: User cannot withdraw LP tokens");
    }

    function _onlyValidLiquidityPoolAdapter() private view {
        require(
            controller.isLiquidityPoolAdapter(msg.sender),
            "LiquidityPool::_onlyValidLiquidityPoolAdapter: Caller not a valid liquidity pool adapter"
        );
    }

    function _verifyPoolId(uint256 poolId) private view {
        require(pools.length > poolId, "LiquidityPool::_verifyPoolId: Invalid pool id");
    }

    function _verifyPoolParameters(uint256 lockTime, uint256 multiplier) private pure {
        require(lockTime <= MAXIMUM_LOCK_TIME, "LiquidityPool::_verifyPoolParameters: Invalid pool lockTime");
        require(multiplier <= MAXIMUM_MULTIPLIER, "LiquidityPool::_verifyPoolParameters: Invalid pool multiplier");
    }

    /* ========== MODIFIERS ========== */

    modifier updateUser(address user) {
        _updateUser(user);
        _;
    }

    modifier updateUserPoolDeposits(address user, uint256 poolId) {
        _updateUserPoolDeposits(user, poolId);
        _;
    }

    modifier canTransfer(address user) {
        _canTransfer(user);
        _;
    }

    modifier canWithdraw(address user) {
        _canWithdrawLps(user);
        _;
    }

    modifier verifyPoolId(uint256 poolId) {
        _verifyPoolId(poolId);
        _;
    }

    modifier verifyPoolParameters(uint256 lockTime, uint256 multiplier) {
        _verifyPoolParameters(lockTime, multiplier);
        _;
    }

    modifier onlyValidLiquidityPoolAdapter() {
        _onlyValidLiquidityPoolAdapter();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "../interfaces/ILiquidityPoolVault.sol";

/**
 * @notice ADAPTATION OF THE OPENZEPPELIN ERC4626 CONTRACT
 * @dev
 * All function implementations are left as in the original implementation.
 * Some functions are removed.
 * Some function scopes are changed from private to internal.
 */
abstract contract LiquidityPoolVault is ERC20Upgradeable, ILiquidityPoolVault {
    using Math for uint256;

    IERC20Metadata internal immutable _asset;

    uint8 internal constant _decimals = 24;

    // Storage gap
    uint256[50] __gap;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20Metadata asset_) {
        // To prevent a front-running attack, we make sure that the share decimals are larger than the asset decimals.
        require(asset_.decimals() <= 18, "LiquidityPoolVault::constructor: asset decimals must be <= 18");
        _asset = asset_;
    }

    /**
     * @dev See {IERC4262-asset}
     */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /**
     * @dev See {IERC4262-decimals}
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC4262-totalAssets}
     */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /**
     * @dev See {IERC4262-convertToShares}
     */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /**
     * @dev See {IERC4262-convertToAssets}
     */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /**
     * @dev See {IERC4262-previewDeposit}
     */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /**
     * @dev See {IERC4262-previewMint}
     */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /**
     * @dev See {IERC4262-previewWithdraw}
     */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /**
     * @dev See {IERC4262-previewRedeem}
     */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /**
     * @dev Internal convertion function (from assets to shares) with support for rounding direction
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amout of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return (assets == 0 || supply == 0)
            ? assets.mulDiv(10 ** decimals(), 10 ** _asset.decimals(), rounding)
            : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal convertion function (from shares to assets) with support for rounding direction
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return (supply == 0)
            ? shares.mulDiv(10 ** _asset.decimals(), 10 ** decimals(), rounding)
            : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Deposit/mint common workflow
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transfered and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal {
        // If _asset is ERC777, `transfer` can trigger trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transfered, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }
}

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