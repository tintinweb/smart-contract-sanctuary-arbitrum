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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";

error AccessControlIsInitialized();
error AccessDenied(address executor, uint256 deniedForRole);

/// @title Access Control Library
library AccessControlLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.accesscontrol.storage");
    uint256 constant FULL_PRIVILEGES_MASK = type(uint256).max;
    uint256 constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint32 constant ROLE_CREATE_MANAGER = 0x0001_0000;
    uint32 constant ROLE_DELETE_MANAGER = 0x0002_0000;
    uint32 constant ROLE_EDIT_MANAGER = 0x0004_0000;
    uint32 constant ROLE_CONFIG_MANAGER = 0x0008_0000;
    uint32 constant ROLE_INVEST_MANAGER = 0x0010_0000;
    uint32 constant ROLE_WITHDRAW_MANAGER = 0x0020_0000;
    uint32 constant ROLE_DISTRIBUTE_MANAGER = 0x0040_0000;
    uint32 constant ROLE_FEE_MANAGER = 0x0080_0000;

    struct AccessControlState {
        mapping(address => uint256) userRoles;
        bool isInitialized;
    }

    event RoleUpdated(address indexed by, address indexed to, uint256 requested, uint256 actual);

    /// @dev Returns storage position of access control library inside diamond
    function diamondStorage() internal pure returns (AccessControlState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Checks if role `actual` contains all the permissions required `required`
    /// @param _actual Existent role
    /// @param _required Required role
    /// @return true If actual has required role (all permissions), false otherwise
	function hasRole(uint256 _actual, uint256 _required) internal pure returns(bool) {
		return _actual & _required == _required;
	}
    
    /// @dev Effectively reads userRoles role for the contract itself
    /// @notice Retrieves globally set of features enabled
    /// @return 256-bit bitmask of the features enabled
    function features() internal view returns(uint256) {
		AccessControlState storage accessControlState = diamondStorage();
        return accessControlState.userRoles[address(this)];
	}

    /// @dev Checks if requested set of features is enabled globally on the contract
    /// @param _required Set of features to check against
    /// @return true If all the features requested are enabled, false otherwise
    function isFeatureEnabled(uint256 _required) internal view returns(bool) {
		return hasRole(features(), _required);
	}

    /// @dev Checks if operator has all the permissions (role) required
    /// @param _operator Address of the user to check role for
    /// @param _required Set of permissions (role) to check
    /// @return true If all the permissions requested are enabled, false otherwise
    function isOperatorInRole(address _operator, uint256 _required) internal view returns(bool) {
		AccessControlState storage accessControlState = diamondStorage();
        return hasRole(accessControlState.userRoles[_operator], _required);
	}

    /// @dev Checks if transaction sender `msg.sender` has all the permissions required
    /// @param _required Set of permissions (role) to check against
    /// @return true If all the permissions requested are enabled, false otherwise
	function isSenderInRole(uint256 _required) internal view returns(bool) {
		return isOperatorInRole(msg.sender, _required);
	}

    /// @notice Determines the permission bitmask an operator can set on the target permission set
    /// @notice Used to calculate the permission bitmask to be set when requested
    //          in `updateRole` and `updateFeatures` functions
    //
    /// @dev Calculated based on:
    //       1) operator's own permission set read from userRoles[operator]
    //       2) target permission set - what is already set on the target
    //       3) desired permission set - what do we want set target to
    //
    /// @dev Corner cases:
    //       1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
    //        `desired` bitset is returned regardless of the `target` permission set value
    //        (what operator sets is what they get)
    //       2) Operator with no permissions (zero bitset):
    //        `target` bitset is returned regardless of the `desired` value
    //        (operator has no authority and cannot modify anything)
    //
    /// @dev Example:
    //       Consider an operator with the permissions bitmask     00001111
    //       is about to modify the target permission set          01010101
    //       Operator wants to set that permission set to          00110011
    //       Based on their role, an operator has the permissions
    //       to update only lowest 4 bits on the target, meaning that
    //       high 4 bits of the target set in this example is left
    //       unchanged and low 4 bits get changed as desired:      01010011
    //
    /// @param _operator Address of the contract operator which is about to set the permissions
    /// @param _target Input set of permissions to operator is going to modify
    /// @param _desired Desired set of permissions operator would like to set
    /// @return Set of permissions given operator will set
    function evaluateBy(address _operator, uint256 _target, uint256 _desired) internal view returns(uint256) {
		AccessControlState storage accessControlState = diamondStorage();
		uint256 p = accessControlState.userRoles[_operator];
        _target |= p & _desired;
		_target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ _desired));
		return _target;
	}

    /// @dev Initializes access control by assigning full privileges to contract owner
    /// @notice Restricted access function, should be called by owner only
    function initializeAccessControl() internal {
        LibDiamond.enforceIsContractOwner();
        AccessControlState storage accessControlState = diamondStorage();
        if(accessControlState.isInitialized) {
            revert AccessControlIsInitialized();
        }
        accessControlState.userRoles[LibDiamond.contractOwner()] = FULL_PRIVILEGES_MASK;
        accessControlState.isInitialized = true;
    }

    /// @dev Updates set of permissions (role) for a given user, 
    //       taking into account sender's permissions
    /// @notice Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
    /// @param _operator Address of a user to alter permissions for or zero
    //         to alter global features of the smart contract
    /// @param _role Bitmask representing a set of permissions to enable/disable for a user specified
	function updateRole(address _operator, uint256 _role) internal {
		AccessControlState storage accessControlState = diamondStorage();
        if(!isSenderInRole(ROLE_ACCESS_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_ACCESS_MANAGER);
        }
		accessControlState.userRoles[_operator] = evaluateBy(msg.sender, accessControlState.userRoles[_operator], _role);
        emit RoleUpdated(msg.sender, _operator, _role, accessControlState.userRoles[_operator]);
    }

    /// @dev Updates set of the globally enabled features (`features`)
    /// @notice Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
    /// @param _mask Bitmask representing a set of features to enable/disable
    function updateFeatures(uint256 _mask) internal {
		updateRole(address(this), _mask);
	}

    /// @dev Throws error if sender do not have create manager role
    function enforceIsCreateManager() internal view {
        if(!isSenderInRole(ROLE_CREATE_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_CREATE_MANAGER);
        }        
    }

    /// @dev Throws error if sender do not have delete manager role
    function enforceIsDeleteManager() internal view {
        if(!isSenderInRole(ROLE_DELETE_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_DELETE_MANAGER);
        }        
    }

    /// @dev Throws error if sender do not have edit manager role
    function enforceIsEditManager() internal view {
        if(!isSenderInRole(ROLE_EDIT_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_EDIT_MANAGER);
        }        
    }

    /// @dev Throws error if sender do not have config manager role
    function enforceIsConfigManager() internal view {
        if(!isSenderInRole(ROLE_CONFIG_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_CONFIG_MANAGER);
        }        
    }

    /// @dev Throws error if sender do not have invest manager role
    function enforceIsInvestManager() internal view {
        if(!isSenderInRole(ROLE_INVEST_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_INVEST_MANAGER);
        }        
    }

    /// @dev Throws error if sender do not have withdraw manager role
    function enforceIsWithdrawManager() internal view {
        if(!isSenderInRole(ROLE_WITHDRAW_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_WITHDRAW_MANAGER);
        }        
    }

    /// @dev Throws error if sender do not have distribute manager role
    function enforceIsDistributeManager() internal view {
        if(!isSenderInRole(ROLE_DISTRIBUTE_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_DISTRIBUTE_MANAGER);
        }        
    }

    /// @dev Throws error if sender do not have fee manager role
    function enforceIsFeeManager() internal view {
        if(!isSenderInRole(ROLE_FEE_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_FEE_MANAGER);
        }        
    }
}

/// @title Access Control Facet
contract AccessControlFacet {
    /// @dev Effectively reads userRoles role for the contract itself
    /// @notice Retrieves globally set of features enabled
    /// @return 256-bit bitmask of the features enabled
    function features() external view returns(uint256) {
		return AccessControlLib.features();
	}

    /// @dev Checks if requested set of features is enabled globally on the contract
    /// @param _required Set of features to check against
    /// @return true If all the features requested are enabled, false otherwise
    function isFeatureEnabled(uint256 _required) external view returns(bool) {
		return AccessControlLib.isFeatureEnabled(_required);
	}

    /// @dev Checks if operator has all the permissions (role) required
    /// @param _operator Address of the user to check role for
    /// @param _required Set of permissions (role) to check
    /// @return true If all the permissions requested are enabled, false otherwise
    function isOperatorInRole(address _operator, uint256 _required) external view returns(bool) {
		return AccessControlLib.isOperatorInRole(_operator, _required);
	}

    /// @dev Checks if transaction sender `msg.sender` has all the permissions required
    /// @param _required Set of permissions (role) to check against
    /// @return true If all the permissions requested are enabled, false otherwise
	function isSenderInRole(uint256 _required) external view returns(bool) {
		return AccessControlLib.isSenderInRole(_required);
	}

    /// @dev Initializes access control by assigning full privileges to contract owner
    /// @notice Restricted access function, should be called by owner only
    function initializeAccessControl() external {
        AccessControlLib.initializeAccessControl();
    }
    
    /// @dev Updates set of permissions (role) for a given user, 
    //       taking into account sender's permissions
    /// @notice Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
    /// @param _operator Address of a user to alter permissions for or zero
    //         to alter global features of the smart contract
    /// @param _role Bitmask representing a set of permissions to enable/disable for a user specified
	function updateRole(address _operator, uint256 _role) external {
		AccessControlLib.updateRole(_operator, _role);
	}

    /// @dev Updates set of the globally enabled features (`features`)
    /// @notice Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
    /// @param _mask Bitmask representing a set of features to enable/disable
    function updateFeatures(uint256 _mask) external {
		return AccessControlLib.updateRole(address(this), _mask);
	}
}

// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import {PoolManagerLib} from "./PoolManagerFacet.sol";
import {LenderLib} from "./LenderFacet.sol";
import {VaultLib} from "./VaultFacet.sol";
import {MetadataLib} from "./MetadataFacet.sol";
import {AccessControlLib} from "./AccessControlFacet.sol";
import {StableCoinLib} from "./StableCoinExtension.sol";

error CreditPoolIdExist(string _id);
error NotCreditPoolCall();
error PoolIsNotActive(string _id);
error PoolIsExpired(string _id);
error LenderIdsExist(uint256 _length);
error InvalidRoleOrPoolId(string roleId, string poolId);
error InvalidLenderOrPoolId(string roleId, string poolId);
error LenderBoundWithPool(string roleId, string poolId);
error InvalidPoolId(string poolId);
error InvalidAmount(uint256 amount);

/// @title Credit Pool Library
library CreditPoolLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.creditpool.storage");

    struct CreditPoolState {
        mapping(string => CreditPool) creditPools;
        mapping(string => mapping(string => Binding)) lenderBinding;
        bool isCreditPoolCall;
    }

    struct CreditPool {
        string creditPoolId;
        string poolManagerId;
        string metaHash;
        uint256 borrowingAmount;
        uint64 inceptionTime;
        uint64 expiryTime;
        uint32 curingPeriod;
        CreditRatings ratings;
        uint16 bindingIndex;
        CreditPoolStatus status;
        string[] lenderIds;
        string[] paymentIds;
    }

    struct Binding {
        bool isBound;
        uint16 lenderIndexInPool;
        uint16 poolIndexInLender;
    }

    enum CreditRatings {PENDING, AAA, AA, A, BBB, BB, B, CCC, CC, C}

    enum CreditPoolStatus {PENDING, ACTIVE, INACTIVE}

    /// @dev Returns storage position of credit pool library inside diamond
    function diamondStorage() internal pure returns (CreditPoolState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Returns on-chain attributes of given credit pool
    /// @param _poolId PoolId associated with given credit pool 
    function getCreditPool(string calldata _poolId) internal view returns (CreditPool memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId];
    }

    /// @dev Returns PoolManagerId of the manager who owns given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolManagerId(string calldata _poolId) internal view returns (string memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].poolManagerId;
    }

    /// @dev Returns IPFS hash of given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolMetaHash(string calldata _poolId) internal view returns (string memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].metaHash;
    }

    /// @dev Returns pool size of given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolBorrowingAmount(string memory _poolId) internal view returns (uint256) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].borrowingAmount;
    }

    /// @dev Returns credit pool inception time (Unix timestamp)
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolInceptionTime(string calldata _poolId) internal view returns (uint64) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].inceptionTime;
    }

    /// @dev Returns credit pool cut-off time (Unix timestamp)
    ///      beyond which pool won't accept new investment from lenders
    /// @param _poolId PoolId associated with given credit pool  
    function getCreditPoolExpiryTime(string calldata _poolId) internal view returns (uint64) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].expiryTime;
    }

    /// @dev Returns curing period (in seconds) of given credit pool
    /// @param _poolId PoolId associated with given credit pool 
    function getCreditPoolCuringPeriod(string calldata _poolId) internal view returns (uint32) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].curingPeriod;
    }

    /// @dev Returns credit ratings of given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolRatings(string calldata _poolId) internal view returns (CreditRatings) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].ratings;
    }

    /// @dev Returns index of given credit pool in pool manager's pool list
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolBindingIndex(string calldata _poolId) internal view returns (uint16) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].bindingIndex;
    }

    /// @dev Returns credit pool status
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolStatus(string calldata _poolId) internal view returns (CreditPoolStatus) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].status;
    }

    /// @dev Returns number of active lenders associated with given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getLenderIdsLength(string calldata _poolId) internal view returns (uint256) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].lenderIds.length;
    }

    /// @dev Returns LenderId that is associated with given credit pool based on given index
    /// @param _poolId PoolId associated with given credit pool
    /// @param _index Index number to query
    function getLenderId(string calldata _poolId, uint256 _index) internal view returns (string memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].lenderIds[_index];
    }

    /// @dev Returns number if payments associated with given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getPaymentIdsLength(string calldata _poolId) internal view returns (uint256) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].paymentIds.length;
    }

    /// @dev Returns PaymentId that is associated with given credit pool based on given index
    /// @param _poolId PoolId associated with given credit pool
    /// @param _index Index number to query
    function getPaymentId(string calldata _poolId, uint256 _index) internal view returns (string memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.creditPools[_poolId].paymentIds[_index];
    }

    /// @dev Returns index of given credit pool in lender's pool list
    /// @param _lenderId LenderId associated with given lender
    /// @param _poolId PoolId associated with given credit pool
    function getLenderBinding(string calldata _lenderId, string calldata _poolId) internal view returns (Binding memory) {
        CreditPoolState storage creditPoolState = diamondStorage();
        return creditPoolState.lenderBinding[_lenderId][_poolId];
    }

    /// @dev Returns IPFS URL of given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getMetadataURI(string calldata _poolId) internal view returns (string memory) {
        enforceIsCreditPoolIdExist(_poolId);
        string memory _baseURI = MetadataLib.getBaseURI();
        string memory _metaHash = getCreditPoolMetaHash(_poolId);
        return bytes(_baseURI).length > 0 ? string(string.concat(bytes(_baseURI), bytes(_metaHash))) : "";
    }

    /// @dev Creates a new credit pool
    /// @notice Restricted access function, should be called by an address with create manager role
    /// @param _creditPoolId Id associated with credit pool
    /// @param _poolManagerId PoolManagerId of manager who owns the pool
    /// @param _metaHash IPFS hash of credit pool
    /// @param _borrowingAmount Pool size
    /// @param _inceptionTime Credit pool inception time (Unix timestamp)
    /// @param _expiryTime Credit pool cut-off time (Unix timestamp)
    /// @param _curingPeriod Curing period of credit pool in seconds
    /// @param _status Status of cresit pool
    function createCreditPool(
        string calldata _creditPoolId,
        string calldata _poolManagerId,
        string calldata _metaHash,
        uint256 _borrowingAmount,
        uint64 _inceptionTime,
        uint64 _expiryTime,
        uint32 _curingPeriod,
        CreditPoolStatus _status
    ) internal returns (CreditPool memory) {
        AccessControlLib.enforceIsCreateManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(keccak256(bytes(_creditPoolId)) == keccak256(bytes(creditPoolState.creditPools[_creditPoolId].creditPoolId))) {
            revert CreditPoolIdExist(_creditPoolId);
        }
        PoolManagerLib.enforceIsPoolManagerKYBVerified(_poolManagerId);
        creditPoolState.creditPools[_creditPoolId] = CreditPool(
            _creditPoolId,
            _poolManagerId,
            _metaHash,
            _borrowingAmount,
            _inceptionTime,
            _expiryTime,
            _curingPeriod,
            CreditRatings.PENDING,
            uint16(PoolManagerLib.getPoolIdsLength(_poolManagerId)),
            _status,
            new string[](0),
            new string[](0)
        );
        creditPoolState.isCreditPoolCall = true;
        PoolManagerLib.addPoolId(_poolManagerId, _creditPoolId);
        creditPoolState.isCreditPoolCall = false;
        return creditPoolState.creditPools[_creditPoolId];
    }

    /// @dev Deletes existing credit pool
    /// @notice Restricted access function, should be called by an address with delete manager role
    /// @param _creditPoolId PoolId associated with credit pool
    function removeCreditPool(string calldata _creditPoolId) internal {
        AccessControlLib.enforceIsDeleteManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.creditPools[_creditPoolId].lenderIds.length != 0) {
            revert LenderIdsExist(creditPoolState.creditPools[_creditPoolId].lenderIds.length);
        }
        string memory _poolManagerId = creditPoolState.creditPools[_creditPoolId].poolManagerId;
        uint16 _index = creditPoolState.creditPools[_creditPoolId].bindingIndex;
        creditPoolState.isCreditPoolCall = true;
        PoolManagerLib.removePoolIdByIndex(_poolManagerId, _index);
        StableCoinLib.deletePoolToken(_creditPoolId);
        creditPoolState.isCreditPoolCall = false;
        delete creditPoolState.creditPools[_creditPoolId];
    }

    /// @dev Updates IPFS hash of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _hash IPFS hash of credit pool
    function updateCreditPoolHash(string calldata _creditPoolId, string calldata _hash) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].metaHash = _hash;
    }

    /// @dev Updates pool size of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _borrowingAmount Pool size of given credit pool
    function updateCreditPoolBorrowingAmount(string calldata _creditPoolId, uint256 _borrowingAmount) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        if(_borrowingAmount < VaultLib.getBorrowedAmount(_creditPoolId)) {
            revert InvalidAmount(_borrowingAmount);
        }
        creditPoolState.creditPools[_creditPoolId].borrowingAmount = _borrowingAmount;
    }

    /// @dev Updates inception time of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _inceptionTime Inception time (Unix timestamp) of credit pool
    function updateCreditPoolInceptionTime(string calldata _creditPoolId, uint64 _inceptionTime) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].inceptionTime = _inceptionTime;
    }

    /// @dev Updates expiry time of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _expiryTime Cut-off time (Unix timestamp) of credit pool
    function updateCreditPoolExpiryTime(string calldata _creditPoolId, uint64 _expiryTime) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].expiryTime = _expiryTime;
    }

    /// @dev Updates curing period of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _curingPeriod Curing period (In seconds) of credit pool 
    function updateCreditPoolCuringPeriod(string calldata _creditPoolId, uint32 _curingPeriod) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].curingPeriod = _curingPeriod;
    }

    /// @dev Updates index of credit pool in pool manager's pool list
    /// @notice Called internally when pool list of pool manager gets updated
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _bindingIndex Index of credit pool to assign in pool manager's pool list
    function updateBindingIndexOfPool(string memory _creditPoolId, uint256 _bindingIndex) internal {
        enforceIsCreditPool();
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].bindingIndex = uint16(_bindingIndex);
    }

    /// @dev Updates credit ratings of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _ratings Credit ratings of given credit pool
    function updateCreditRatings(string calldata _creditPoolId, CreditRatings _ratings) internal {
        AccessControlLib.enforceIsEditManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.creditPools[_creditPoolId].status != CreditPoolStatus.ACTIVE) {
            revert PoolIsNotActive(_creditPoolId);
        }
        creditPoolState.creditPools[_creditPoolId].ratings = _ratings;
    }

    /// @dev Updates status of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _status Status of given credit pool
    function updateCreditPoolStatus(string calldata _creditPoolId, CreditPoolStatus _status) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsCreditPoolIdExist(_creditPoolId);
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.creditPools[_creditPoolId].status = _status;
    }

    /// @dev Updates index of credit pool in lender's pool list
    /// @notice Called internally when pool list of lender gets updated
    /// @param _lenderId LenderId of lender whose pool list gets updated
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _poolIndexInLender Index of credit pool to assign in lender's pool list
    function updatePoolIndexInLender(
        string memory _lenderId,
        string memory _creditPoolId,
        uint256 _poolIndexInLender
    ) internal {
        enforceIsCreditPool();
        CreditPoolState storage creditPoolState = diamondStorage();
        creditPoolState.lenderBinding[_lenderId][_creditPoolId].poolIndexInLender = uint16(_poolIndexInLender);
    }

    /// @dev Adds LenderId to given credit pool's lender list
    /// @notice Called internally when lender makes a new investment
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _lenderId LenderId of lender who invested in given credit pool
    function addLenderId(string memory _creditPoolId, string memory _lenderId) internal {
        VaultLib.enforceIsVault();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.creditPools[_creditPoolId].status != CreditPoolStatus.ACTIVE) {
            revert PoolIsNotActive(_creditPoolId);
        }
        if(!creditPoolState.lenderBinding[_lenderId][_creditPoolId].isBound) {
            uint16 _lenderIndexInPool = uint16(creditPoolState.creditPools[_creditPoolId].lenderIds.length);
            uint16 _poolIndexInLender = uint16(LenderLib.getPoolIdsLength(_lenderId));
            creditPoolState.isCreditPoolCall = true;
            LenderLib.addPoolId(_lenderId, _creditPoolId);
            creditPoolState.isCreditPoolCall = false;
            creditPoolState.creditPools[_creditPoolId].lenderIds.push(_lenderId);
            creditPoolState.lenderBinding[_lenderId][_creditPoolId] = Binding(true, _lenderIndexInPool, _poolIndexInLender);
        }
    }

    /// @dev Removes LenderId from given credit pool's lender list
    /// @notice Called internally when lender exits the pool
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _lenderId LenderId of lender who exited from given credit pool
    function removeLenderId(string memory _creditPoolId, string memory _lenderId) internal {
        VaultLib.enforceIsVault();
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.lenderBinding[_lenderId][_creditPoolId].isBound) {
            uint16 _lastLenderIndexInPool = uint16(creditPoolState.creditPools[_creditPoolId].lenderIds.length - 1);
            uint16 _lenderIndexInPool = creditPoolState.lenderBinding[_lenderId][_creditPoolId].lenderIndexInPool;
            uint16 _poolIndexInLender = creditPoolState.lenderBinding[_lenderId][_creditPoolId].poolIndexInLender;
            creditPoolState.isCreditPoolCall = true;
            LenderLib.removePoolIdByIndex(_lenderId, _poolIndexInLender);
            creditPoolState.isCreditPoolCall = false;
            if(_lenderIndexInPool != _lastLenderIndexInPool) {
                creditPoolState.creditPools[_creditPoolId].lenderIds[_lenderIndexInPool] = creditPoolState.creditPools[_creditPoolId].lenderIds[_lastLenderIndexInPool];
                string memory _lastLenderId = creditPoolState.creditPools[_creditPoolId].lenderIds[_lenderIndexInPool];
                creditPoolState.lenderBinding[_lastLenderId][_creditPoolId].lenderIndexInPool = uint16(_lenderIndexInPool);
            }
            creditPoolState.creditPools[_creditPoolId].lenderIds.pop();
            delete creditPoolState.lenderBinding[_lenderId][_creditPoolId];
        }
    }

    /// @dev Adds PaymentId associated with given credit pool
    /// @notice Called internally whenever a new payment registered to given credit pool 
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _paymentId PaymentId associated with a new payment
    function addPaymentId(string memory _creditPoolId, string memory _paymentId) internal {
        VaultLib.enforceIsVault();
        CreditPoolState storage creditPoolState = diamondStorage();
        CreditPool storage creditPool = creditPoolState.creditPools[_creditPoolId];
        creditPool.paymentIds.push(_paymentId);
    }

    /// @dev Removes PaymentId associated with given credit pool
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _paymentId PaymentId to remove
    function removePaymentId(string calldata _creditPoolId, string calldata _paymentId) internal {
        AccessControlLib.enforceIsDeleteManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        CreditPool storage creditPool = creditPoolState.creditPools[_creditPoolId];
        uint256 index;
        for (uint256 i = 0; i < creditPool.paymentIds.length; i++) {
            if (keccak256(bytes(creditPool.paymentIds[i])) == keccak256(bytes(_paymentId))) {
                index = i;
                break;
            }
        }
        creditPool.paymentIds[index] = creditPool.paymentIds[creditPool.paymentIds.length - 1];
        creditPool.paymentIds.pop();
    }

    /// @dev Removes PaymentId associated with given credit pool
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _paymentIndex Index of PaymentId to remove
    function removePaymentIdByIndex(string calldata _creditPoolId, uint256 _paymentIndex) internal {
        AccessControlLib.enforceIsDeleteManager();
        CreditPoolState storage creditPoolState = diamondStorage();
        CreditPool storage creditPool = creditPoolState.creditPools[_creditPoolId];
        if(_paymentIndex != creditPool.paymentIds.length - 1) {
            creditPool.paymentIds[_paymentIndex] = creditPool.paymentIds[creditPool.paymentIds.length - 1];
        }
        creditPool.paymentIds.pop();
    }

    /// @dev Throws error if called by other than credit pool library
    function enforceIsCreditPool() internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(!creditPoolState.isCreditPoolCall) {
            revert NotCreditPoolCall();
        }
    }

    /// @dev Throws error if pool is not active
    function enforceIsActivePool(string memory _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.creditPools[_creditPoolId].status != CreditPoolStatus.ACTIVE) {
            revert PoolIsNotActive(_creditPoolId);
        }
    }

    /// @dev Throws error if pool cut-off time reached
    function enforcePoolIsNotExpired(string memory _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(block.timestamp > creditPoolState.creditPools[_creditPoolId].expiryTime) {
            revert PoolIsExpired(_creditPoolId);
        }
    }

    /// @dev Throws error if lender is not active investor of given pool
    function enforceIsLenderBoundWithPool(string calldata _lenderId, string calldata _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(!creditPoolState.lenderBinding[_lenderId][_creditPoolId].isBound) {
            revert InvalidLenderOrPoolId(_lenderId, _creditPoolId);
        }
    }

    /// @dev Throws error if lender is active investor of given pool
    function enforceLenderIsNotBoundWithPool(string calldata _lenderId, string calldata _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(creditPoolState.lenderBinding[_lenderId][_creditPoolId].isBound) {
            revert LenderBoundWithPool(_lenderId, _creditPoolId);
        }
    }

    /// @dev Throws error if pool manager is not owner of the pool
    function enforceIsPoolManagerBoundWithPool(string calldata _poolManagerId, string calldata _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(keccak256(bytes(_poolManagerId)) != keccak256(bytes(creditPoolState.creditPools[_creditPoolId].poolManagerId))) {
            revert InvalidRoleOrPoolId(_poolManagerId, _creditPoolId);
        }
    }

    /// @dev Throws error if credit pool not exist
    function enforceIsCreditPoolIdExist(string calldata _creditPoolId) internal view {
        CreditPoolState storage creditPoolState = diamondStorage();
        if(bytes(creditPoolState.creditPools[_creditPoolId].creditPoolId).length == 0) {
            revert InvalidPoolId(_creditPoolId);
        }
    }
}

// @title Credit Pool Facet
contract CreditPoolFacet {
    event CreateCreditPoolEvent(CreditPoolLib.CreditPool creditPool);
    event DeleteCreditPoolEvent(string indexed poolId);
    event UpdateCreditPoolHashEvent(string indexed poolId, string prevHash, string newHash);
    event UpdateCreditPoolBorrowingAmountEvent(string indexed poolId, uint256 prevAmount, uint256 newAmount);
    event UpdateCreditPoolInceptionTimeEvent(string indexed poolId, uint64 prevTime, uint64 newTime);
    event UpdateCreditPoolExpiryTimeEvent(string indexed poolId, uint64 prevTime, uint64 newTime);
    event UpdateCreditPoolCuringPeriodEvent(string indexed poolId, uint32 prevPeriod, uint32 newPeriod);
    event UpdateCreditRatingsEvent(
        string indexed poolId,
        CreditPoolLib.CreditRatings prevRatings,
        CreditPoolLib.CreditRatings newRatings
    );
    event UpdateCreditPoolStatusEvent(
        string indexed poolId,
        CreditPoolLib.CreditPoolStatus prevStatus,
        CreditPoolLib.CreditPoolStatus newStatus
    );

    /// @dev Returns on-chain attributes of given credit pool
    /// @param _poolId PoolId associated with given credit pool 
    function getCreditPool(string calldata _poolId) external view returns (CreditPoolLib.CreditPool memory) {
        return CreditPoolLib.getCreditPool(_poolId);
    }

    /// @dev Returns PoolManagerId of the manager who owns given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolManagerId(string calldata _poolId) external view returns (string memory) {
        return CreditPoolLib.getCreditPoolManagerId(_poolId);
    }

    /// @dev Returns IPFS hash of given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolMetaHash(string calldata _poolId) external view returns (string memory) {
        return CreditPoolLib.getCreditPoolMetaHash(_poolId);
    }

    /// @dev Returns pool size of given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolBorrowingAmount(string calldata _poolId) external view returns (uint256) {
        return CreditPoolLib.getCreditPoolBorrowingAmount(_poolId);
    }

    /// @dev Returns credit pool inception time (Unix timestamp)
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolInceptionTime(string calldata _poolId) external view returns (uint64) {
        return CreditPoolLib.getCreditPoolInceptionTime(_poolId);
    }

    /// @dev Returns credit pool cut-off time (Unix timestamp)
    ///      beyond which pool won't accept new investment from lenders
    /// @param _poolId PoolId associated with given credit pool  
    function getCreditPoolExpiryTime(string calldata _poolId) external view returns (uint64) {
        return CreditPoolLib.getCreditPoolExpiryTime(_poolId);
    }

    /// @dev Returns curing period (in seconds) of given credit pool
    /// @param _poolId PoolId associated with given credit pool 
    function getCreditPoolCuringPeriod(string calldata _poolId) external view returns (uint32) {
        return CreditPoolLib.getCreditPoolCuringPeriod(_poolId);
    }

    /// @dev Returns credit ratings of given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolRatings(string calldata _poolId) external view returns (CreditPoolLib.CreditRatings) {
        return CreditPoolLib.getCreditPoolRatings(_poolId);
    }

    /// @dev Returns index of given credit pool in pool manager's pool list
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolBindingIndex(string calldata _poolId) external view returns (uint16) {
        return CreditPoolLib.getCreditPoolBindingIndex(_poolId);
    }

    /// @dev Returns credit pool status
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolStatus(string calldata _poolId) external view returns (CreditPoolLib.CreditPoolStatus) {
        return CreditPoolLib.getCreditPoolStatus(_poolId);
    }

    /// @dev Returns number of active lenders associated with given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolLenderIdsLength(string calldata _poolId) external view returns (uint256) {
        return CreditPoolLib.getLenderIdsLength(_poolId);
    }

    /// @dev Returns LenderId that is associated with given credit pool based on given index
    /// @param _poolId PoolId associated with given credit pool
    /// @param _index Index number to query
    function getCreditPoolLenderId(string calldata _poolId, uint256 _index) external view returns (string memory) {
        return CreditPoolLib.getLenderId(_poolId, _index);
    }

    /// @dev Returns number if payments associated with given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolPaymentIdsLength(string calldata _poolId) external view returns (uint256) {
        return CreditPoolLib.getPaymentIdsLength(_poolId);
    }

    /// @dev Returns PaymentId that is associated with given credit pool based on given index
    /// @param _poolId PoolId associated with given credit pool
    /// @param _index Index number to query
    function getCreditPoolPaymentId(string calldata _poolId, uint256 _index) external view returns (string memory) {
        return CreditPoolLib.getPaymentId(_poolId, _index);
    }

    /// @dev Returns index of given credit pool in lender's pool list
    /// @param _lenderId LenderId associated with given lender
    /// @param _poolId PoolId associated with given credit pool
    function getLenderBinding(string calldata _lenderId, string calldata _poolId) external view returns (CreditPoolLib.Binding memory) {
        return CreditPoolLib.getLenderBinding(_lenderId, _poolId);
    }

    /// @dev Returns IPFS URL of given credit pool
    /// @param _poolId PoolId associated with given credit pool
    function getCreditPoolMetadataURI(string calldata _poolId) external view returns (string memory) {
        return CreditPoolLib.getMetadataURI(_poolId);
    }

    /// @dev Creates a new credit pool
    /// @notice Restricted access function, should be called by an address with create manager role
    /// @param _creditPoolId Id associated with credit pool
    /// @param _poolManagerId PoolManagerId of manager who owns the pool
    /// @param _metaHash IPFS hash of credit pool
    /// @param _borrowingAmount Pool size
    /// @param _inceptionTime Credit pool inception time (Unix timestamp)
    /// @param _expiryTime Credit pool cut-off time (Unix timestamp)
    /// @param _curingPeriod Curing period of credit pool in seconds
    /// @param _status Status of cresit pool
    function createCreditPool(
        string calldata _creditPoolId,
        string calldata _poolManagerId,
        string calldata _metaHash,
        uint256 _borrowingAmount,
        uint64 _inceptionTime,
        uint64 _expiryTime,
        uint32 _curingPeriod,
        CreditPoolLib.CreditPoolStatus _status
    ) external {
        CreditPoolLib.CreditPool memory creditPool = CreditPoolLib.createCreditPool(_creditPoolId, _poolManagerId, _metaHash, _borrowingAmount, _inceptionTime, _expiryTime, _curingPeriod, _status);
        emit CreateCreditPoolEvent(creditPool);
    }

    /// @dev Deletes existing credit pool
    /// @notice Restricted access function, should be called by an address with delete manager role
    /// @param _creditPoolId PoolId associated with credit pool
    function deleteCreditPool(string calldata _creditPoolId) external {
        CreditPoolLib.removeCreditPool(_creditPoolId);
        emit DeleteCreditPoolEvent(_creditPoolId);
    }

    /// @dev Updates IPFS hash of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _hash IPFS hash of credit pool
    function updateCreditPoolHash(string calldata _creditPoolId, string calldata _hash) external {
        string memory _prevHash = CreditPoolLib.getCreditPoolMetaHash(_creditPoolId);
        CreditPoolLib.updateCreditPoolHash(_creditPoolId, _hash);
        emit UpdateCreditPoolHashEvent(_creditPoolId, _prevHash, _hash);
    }

    /// @dev Updates pool size of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _amount Pool size of given credit pool
    function updateCreditPoolBorrowingAmount(string calldata _creditPoolId, uint256 _amount) external {
        uint256 _prevAmount = CreditPoolLib.getCreditPoolBorrowingAmount(_creditPoolId);
        CreditPoolLib.updateCreditPoolBorrowingAmount(_creditPoolId, _amount);
        emit UpdateCreditPoolBorrowingAmountEvent(_creditPoolId, _prevAmount, _amount);
    }

    /// @dev Updates inception time of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _time Inception time (Unix timestamp) of credit pool
    function updateCreditPoolInceptionTime(string calldata _creditPoolId, uint64 _time) external {
        uint64 _prevTime = CreditPoolLib.getCreditPoolInceptionTime(_creditPoolId);
        CreditPoolLib.updateCreditPoolInceptionTime(_creditPoolId, _time);
        emit UpdateCreditPoolInceptionTimeEvent(_creditPoolId, _prevTime, _time);
    }

    /// @dev Updates expiry time of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _time Cut-off time (Unix timestamp) of credit pool
    function updateCreditPoolExpiryTime(string calldata _creditPoolId, uint64 _time) external {
        uint64 _prevTime = CreditPoolLib.getCreditPoolExpiryTime(_creditPoolId);
        CreditPoolLib.updateCreditPoolExpiryTime(_creditPoolId, _time);
        emit UpdateCreditPoolExpiryTimeEvent(_creditPoolId, _prevTime, _time);
    }

    /// @dev Updates curing period of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _curingPeriod Curing period (In seconds) of credit pool 
    function updateCreditPoolCuringPeriod(string calldata _creditPoolId, uint32 _curingPeriod) external {
        uint32 _prevPeriod = CreditPoolLib.getCreditPoolCuringPeriod(_creditPoolId);
        CreditPoolLib.updateCreditPoolCuringPeriod(_creditPoolId, _curingPeriod);
        emit UpdateCreditPoolCuringPeriodEvent(_creditPoolId, _prevPeriod, _curingPeriod);
    }

    /// @dev Updates credit ratings of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _ratings Credit ratings of given credit pool
    function updateCreditRatings(string calldata _creditPoolId, CreditPoolLib.CreditRatings _ratings) external {
        CreditPoolLib.CreditRatings _prevRatings = CreditPoolLib.getCreditPoolRatings(_creditPoolId);
        CreditPoolLib.updateCreditRatings(_creditPoolId, _ratings);
        emit UpdateCreditRatingsEvent(_creditPoolId, _prevRatings, _ratings);
    }

    /// @dev Updates status of given credit pool
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _status Status of given credit pool
    function updateCreditPoolStatus(string calldata _creditPoolId, CreditPoolLib.CreditPoolStatus _status) external {
        CreditPoolLib.CreditPoolStatus _prevStatus = CreditPoolLib.getCreditPoolStatus(_creditPoolId);
        CreditPoolLib.updateCreditPoolStatus(_creditPoolId, _status);
        emit UpdateCreditPoolStatusEvent(_creditPoolId, _prevStatus, _status);
    }

    /// @dev Removes PaymentId associated with given credit pool
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _paymentId PaymentId to remove
    function removeCreditPoolPaymentId(string calldata _creditPoolId, string calldata _paymentId) external {
        CreditPoolLib.removePaymentId(_creditPoolId, _paymentId);
    }

    /// @dev Removes PaymentId associated with given credit pool
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _paymentIndex Index of PaymentId to remove
    function removeCreditPoolPaymentIdByIndex(string calldata _creditPoolId, uint256 _paymentIndex) external {
        CreditPoolLib.removePaymentIdByIndex(_creditPoolId, _paymentIndex);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import {AccessControlLib} from "./AccessControlFacet.sol";
import {VaultLib} from "./VaultFacet.sol";

error InvalidSigner(address signer, uint256 deniedForRole);
error NonceUsed(address signer, uint256 nonce);
error NotDistributeCall();

/// @title Distribute Library
library DistributeLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.distribute.storage");
    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 constant PAYMENT_INFO_TYPEHASH = keccak256(
        "PaymentInfo(uint256 amount,uint8 paymentType)"
    );
    bytes32 constant REQUEST_TYPEHASH = keccak256(
        "Request(uint256 nonce,string roleId,string poolId,PaymentInfo[] paymentInfo)PaymentInfo(uint256 amount,uint8 paymentType)"
    );

    struct DistributeState {
        mapping(address => mapping(uint256 => bool)) usedNonces;
        bytes32 domainSeperator;
        bool isDistributeCall;   
    }

    struct Request {
        uint256 nonce;
        string roleId;
        string poolId;
        VaultLib.PaymentInfo[] paymentInfo;
    }

    event AuthorizationUsed(address indexed authorizer, Request request);

    /// @dev Returns storage position of distribute library inside diamond
    function diamondStorage() internal pure returns (DistributeState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    /// @dev Internal function to return encoded data of given payment information struct
    /// @param _paymentInfo Payment information 
    function encodePaymentInfo(VaultLib.PaymentInfo calldata _paymentInfo) internal pure returns (bytes memory) {
        return abi.encode(PAYMENT_INFO_TYPEHASH, _paymentInfo.amount, _paymentInfo.paymentType);
    }

    /// @dev Internal function to return hash of given request
    /// @param _request Request information
    function hashStruct(Request calldata _request) internal pure returns (bytes32) {
        bytes32[] memory encodedPaymentInfo = new bytes32[](_request.paymentInfo.length);
        for (uint256 i = 0; i < _request.paymentInfo.length; i++) {
            encodedPaymentInfo[i] = keccak256(encodePaymentInfo(_request.paymentInfo[i]));
        }
        return
            keccak256(
                abi.encode(
                    REQUEST_TYPEHASH,
                    _request.nonce,
                    keccak256(abi.encodePacked(_request.roleId)),
                    keccak256(abi.encodePacked(_request.poolId)),
                    keccak256(abi.encodePacked(encodedPaymentInfo))
                )
            );
    }

    /// @dev Returns the state of an authorization,
    //       more specifically if the specified nonce was already used by the address specified
    /// @param _signer Signer's address
    /// @param _nonce Nonce of the authorization
    /// @return true if nonce is used
    function authorizationState(address _signer, uint256 _nonce) internal view returns (bool) {
        DistributeState storage distributeState = diamondStorage();
        return distributeState.usedNonces[_signer][_nonce];
    }

    /// @dev Returns EIP-712 contract's domain separator
    /// @notice see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
    function getDomainSeperator() internal view returns (bytes32) {
        DistributeState storage distributeState = diamondStorage();
        return distributeState.domainSeperator;
    }

    /// @dev Returns chain id to construct domain seperator
    function getChainId() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @dev Accept message hash and returns hash message in EIP712 compatible form,
    //       So that it can be used to recover signer from signature signed using EIP712 formatted data 
    function toTypedMessageHash(bytes32 _messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(), _messageHash));
    }

    /// @dev Sets the EIP-712 contract domain separator
    /// @notice Restricted access function, should be called by an address with config manager role
    function setDomainSeperator() internal {
        AccessControlLib.enforceIsConfigManager();
        DistributeState storage distributeState = diamondStorage();
        distributeState.domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("cSigmaDiamond")),
                keccak256(bytes("1")),
                getChainId(),
                address(this)
            )
        );
    }

    /// @dev Withdraws undistributed paid amount into the vault account of given lender
    /// @notice Throws error if signer do not have ROLE_DISTRIBUTE_MANAGER permission
    /// @param _request Request struct
    /// @param _sigR Half of the ECDSA signature pair
    /// @param _sigS Half of the ECDSA signature pair
    /// @param _sigV The recovery byte of the signature 
    function withdrawPoolPaymentIntoVault(
        Request calldata _request,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) internal {
        DistributeState storage distributeState = diamondStorage();
        address _signer = ecrecover(toTypedMessageHash(hashStruct(_request)), _sigV, _sigR, _sigS);
        if(!AccessControlLib.isOperatorInRole(_signer, AccessControlLib.ROLE_DISTRIBUTE_MANAGER)) {
            revert InvalidSigner(_signer, AccessControlLib.ROLE_DISTRIBUTE_MANAGER);
        }
        if(distributeState.usedNonces[_signer][_request.nonce]) {
            revert NonceUsed(_signer, _request.nonce);
        }
        distributeState.usedNonces[_signer][_request.nonce] = true;
        distributeState.isDistributeCall = true;
        VaultLib.distribute(_request.roleId, _request.poolId, _request.paymentInfo);
        distributeState.isDistributeCall = false;
        emit AuthorizationUsed(_signer, _request);
    }

    /// @dev Throws error if called by other than distribute library
    function enforceIsDistribute() internal view {
        DistributeState storage distributeState = diamondStorage();
        if(!distributeState.isDistributeCall) {
            revert NotDistributeCall();
        }
    }
}

/// @title Distribute facet
contract DistributeFacet {
    event Distribute(string indexed roleId, string poolId, VaultLib.PaymentInfo[] paymentInfo);
    event Withdraw(string indexed roleId, uint256 amount);
    event WithdrawStableCoin(string indexed roleId, address token, uint256 amount);
    event WithdrawRequest(string roleId, address token, uint256 amount);
    
    /// @dev Returns the state of an authorization,
    //       more specifically if the specified nonce was already used by the address specified
    /// @param _signer Signer's address
    /// @param _nonce Nonce of the authorization
    /// @return true if nonce is used
    function authorizationState(address _signer, uint256 _nonce) external view returns (bool) {
        return DistributeLib.authorizationState(_signer, _nonce);
    }

    /// @dev Returns EIP-712 contract's domain separator
    /// @notice see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
    function getDomainSeperator() external view returns (bytes32) {
        return DistributeLib.getDomainSeperator();
    }

    /// @dev Sets the EIP-712 contract domain separator
    /// @notice Restricted access function, should be called by an address with config manager role
    function setDomainSeperator() external {
        return DistributeLib.setDomainSeperator();
    }

    /// @dev Withdraws undistributed paid amount into the vault account of given lender
    /// @notice Throws error if signer do not have ROLE_DISTRIBUTE_MANAGER permission
    /// @param _request Request struct
    /// @param _sigR Half of the ECDSA signature pair
    /// @param _sigS Half of the ECDSA signature pair
    /// @param _sigV The recovery byte of the signature 
    function withdrawPoolPaymentIntoVault(
        DistributeLib.Request calldata _request,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) external { 
        DistributeLib.withdrawPoolPaymentIntoVault(_request, _sigR, _sigS, _sigV);
        emit Distribute(_request.roleId, _request.poolId, _request.paymentInfo);
    }

    /// @dev Withdraws undistributed paid amount into the vault account of given lender,
    //       Submits withdraw request to withdraw given amount into the wallet
    /// @notice Throws error if signer do not have ROLE_DISTRIBUTE_MANAGER permission
    /// @param _request Request struct
    /// @param _sigR Half of the ECDSA signature pair
    /// @param _sigS Half of the ECDSA signature pair
    /// @param _sigV The recovery byte of the signature
    /// @param _token Address of token to withdraw from vault
    /// @param _amount Amount of token to withdraw from vault  
    function withdrawPoolPaymentIntoWallet(
        DistributeLib.Request calldata _request,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV,
        address _token,
        uint256 _amount
    ) external {
        DistributeLib.withdrawPoolPaymentIntoVault(_request, _sigR, _sigS, _sigV);
        emit Distribute(_request.roleId, _request.poolId, _request.paymentInfo);
        bool _isWithdrawn = VaultLib.withdrawRequest(_request.roleId, _token, _amount);
        if(_isWithdrawn) {
            if(_token == VaultLib.getPaymentToken()) {
                emit Withdraw(_request.roleId, _amount);
            } else {
                emit WithdrawStableCoin(_request.roleId, _token, _amount);
            }
        } else {
            emit WithdrawRequest(_request.roleId, _token, _amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import {CreditPoolLib} from "./CreditPoolFacet.sol";
import {VaultLib} from "./VaultFacet.sol";
import {MetadataLib} from "./MetadataFacet.sol";
import {AccessControlLib} from "./AccessControlFacet.sol";

error NotLender(address _user, address _lender);
error LenderIdExist(string _id);
error PoolIdsExist(uint256 _length);
error NotVerifiedLender(string _id);
error InvalidLenderId(string _id);

/// @title Lender library
library LenderLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.lender.storage");

    struct LenderState {
        mapping(string => Lender) lenders;
    }

    struct Lender {
        string lenderId;
        string userId;
        string metaHash;
        string country;
        uint64 onBoardTime;
        address wallet;
        KYBStatus status;
        string[] poolIds;
        string[] paymentIds;
    }

    enum KYBStatus {PENDING, VERIFIED, REJECTED}

    /// @dev Returns storage position of lender library inside diamond
    function diamondStorage() internal pure returns (LenderState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Returns on-chain attributes of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLender(string calldata _lenderId) internal view returns (Lender memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId];
    }

    /// @dev Returns userId of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderUserId(string calldata _lenderId) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].userId;
    }

    /// @dev Returns IPFS hash of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderMetaHash(string calldata _lenderId) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].metaHash;
    }

    /// @dev Returns country of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderCountry(string calldata _lenderId) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].country;
    }

    /// @dev Returns onboarding time (Unix timestamp) of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderOnBoardTime(string calldata _lenderId) internal view returns (uint64) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].onBoardTime;
    }

    /// @dev Returns wallet address of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderWallet(string calldata _lenderId) internal view returns (address) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].wallet;
    }

    /// @dev Returns KYB status of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderKYBStatus(string calldata _lenderId) internal view returns (KYBStatus) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].status;
    }

    /// @dev Returns number of active pools for given lender
    /// @param _lenderId LenderId associated with given lender
    function getPoolIdsLength(string memory _lenderId) internal view returns (uint256) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].poolIds.length;
    }

    /// @dev Returns PoolId associated with given lender at given index
    /// @param _lenderId LenderId associated with given lender
    /// @param _index Index number to query
    function getPoolId(string calldata _lenderId, uint256 _index) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].poolIds[_index];
    }

    /// @dev Returns all PoolIds associated with given lender
    /// @param _lenderId LenderId associated with given lender
    function getPoolIds(string calldata _lenderId) internal view returns (string[] memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].poolIds;
    }

    /// @dev Returns number of payments associated with given lender
    /// @param _lenderId LenderId associated with given lender
    function getPaymentIdsLength(string calldata _lenderId) internal view returns (uint256) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].paymentIds.length;
    }

    /// @dev Returns PaymentId that is associated with given lender at given index
    /// @param _lenderId LenderId associated with given lender
    /// @param _index Index number to query
    function getPaymentId(string calldata _lenderId, uint256 _index) internal view returns (string memory) {
        LenderState storage lenderState = diamondStorage();
        return lenderState.lenders[_lenderId].paymentIds[_index];
    }

    /// @dev Returns IPFS URL of given Lender
    /// @param _lenderId LenderId associated with given lender
    function getMetadataURI(string calldata _lenderId) internal view returns (string memory) {
        enforceIsLenderIdExist(_lenderId);
        string memory _baseURI = MetadataLib.getBaseURI();
        string memory _metaHash = getLenderMetaHash(_lenderId);
        return bytes(_baseURI).length > 0 ? string(string.concat(bytes(_baseURI), bytes(_metaHash))) : "";
    }

    /// @dev Creates a new lender
    /// @notice Restricted access function, should be called by an address with create manager role
    /// @param _lenderId RoleId associated with lender
    /// @param _userId UserId associated with lender
    /// @param _metaHash IPFS has of lender
    /// @param _country Country code of lender
    /// @param _onBoardTime On-boarding time (Unix timestamp) of lender
    /// @param _wallet Wallet address of lender
    /// @param _status KYB status of lender 
    function createLender(
        string calldata _lenderId,
        string calldata _userId,
        string calldata _metaHash,
        string calldata _country,
        uint64 _onBoardTime,
        address _wallet,
        KYBStatus _status
    ) internal returns (Lender memory) {
        AccessControlLib.enforceIsCreateManager();
        LenderState storage lenderState = diamondStorage();
        if(keccak256(bytes(_lenderId)) == keccak256(bytes(lenderState.lenders[_lenderId].lenderId))) {
            revert LenderIdExist(_lenderId);
        }
        lenderState.lenders[_lenderId] = Lender(_lenderId, _userId, _metaHash, _country, _onBoardTime, _wallet, _status, new string[](0), new string[](0));
        return lenderState.lenders[_lenderId];
    }

    /// @dev Deletes existing lender
    /// @notice Restricted access function, should be called by an address with delete manager role
    /// @param _lenderId LenderId to delete
    function removeLender(string calldata _lenderId) internal {
        AccessControlLib.enforceIsDeleteManager();
        LenderState storage lenderState = diamondStorage();
        if(lenderState.lenders[_lenderId].poolIds.length != 0) {
            revert PoolIdsExist(lenderState.lenders[_lenderId].poolIds.length);
        }
        delete lenderState.lenders[_lenderId];
    }

    /// @dev Updates IPFS hash of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _hash New IPFS hash to set 
    function updateLenderHash(string calldata _lenderId, string calldata _hash) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].metaHash = _hash;
    }

    /// @dev Updates country of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _country New country to set
    function updateLenderCountry(string calldata _lenderId, string calldata _country) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].country = _country;
    }

    /// @dev Updates on-boarding time (Unix timestamp) of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _onBoardTime New on-board time (Unix timestamp) to set
    function updateLenderOnBoardTime(string calldata _lenderId, uint64 _onBoardTime) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].onBoardTime = _onBoardTime;
    }

    /// @dev Updates wallet address of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _wallet New wallet address to set
    function updateLenderWallet(string calldata _lenderId, address _wallet) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].wallet = _wallet;
    }

    /// @dev Updates KYB status of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _status KYB status to set  
    function updateLenderKYB(string calldata _lenderId, KYBStatus _status) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsLenderIdExist(_lenderId);
        LenderState storage lenderState = diamondStorage();
        lenderState.lenders[_lenderId].status = _status;
    }

    /// @dev Adds PoolId to given lender's pool list
    /// @notice Called internally whenever lender invests for first time in given pool
    /// @param _lenderId LenderId associated with given lender
    /// @param _poolId PoolId in which lender has invested for first time
    function addPoolId(string memory _lenderId, string memory _poolId) internal {
        CreditPoolLib.enforceIsCreditPool();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        lender.poolIds.push(_poolId);
    }

    /// @dev Removes PoolId from given lender's pool list based on given index
    /// @notice Called internally whenever lender exits from given pool
    /// @param _lenderId LenderId associated with given lender
    /// @param _poolIndex Index of pool to remove from lender's pool list
    function removePoolIdByIndex(string memory _lenderId, uint256 _poolIndex) internal {
        CreditPoolLib.enforceIsCreditPool();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        if(_poolIndex != lender.poolIds.length - 1) {
            lender.poolIds[_poolIndex] = lender.poolIds[lender.poolIds.length - 1];
            string memory _poolId = lender.poolIds[_poolIndex];
            CreditPoolLib.updatePoolIndexInLender(_lenderId, _poolId, _poolIndex);
        }
        lender.poolIds.pop();
    }
    
    /// @dev Adds PaymentId associated with given lender
    /// @notice Called internally whenever a new payment registered that is associated with given lender 
    /// @param _lenderId LenderId associated with given lender
    /// @param _paymentId PaymentId associated with a new payment
    function addPaymentId(string memory _lenderId, string memory _paymentId) internal {
        VaultLib.enforceIsVault();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        lender.paymentIds.push(_paymentId);
    }

    /// @dev Removes PaymentId associated with given lender
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _lenderId LenderId associated with given lender
    /// @param _paymentId PaymentId to remove
    function removePaymentId(string calldata _lenderId, string calldata _paymentId) internal {
        AccessControlLib.enforceIsDeleteManager();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        uint256 index;
        for (uint256 i = 0; i < lender.paymentIds.length; i++) {
            if (keccak256(bytes(lender.paymentIds[i])) == keccak256(bytes(_paymentId))) {
                index = i;
                break;
            }
        }
        lender.paymentIds[index] = lender.paymentIds[lender.paymentIds.length - 1];
        lender.paymentIds.pop();
    }

    /// @dev Removes PaymentId associated with given lender based on given index
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _lenderId LenderId associated with given lender
    /// @param _paymentIndex Index of PaymentId to remove
    function removePaymentIdByIndex(string calldata _lenderId, uint256 _paymentIndex) internal {
        AccessControlLib.enforceIsDeleteManager();
        LenderState storage lenderState = diamondStorage();
        Lender storage lender = lenderState.lenders[_lenderId];
        if(_paymentIndex != lender.paymentIds.length - 1) {
            lender.paymentIds[_paymentIndex] = lender.paymentIds[lender.paymentIds.length - 1];
        }
        lender.paymentIds.pop();
    }

    /// @dev Throws error if called by other than lender
    function enforceIsLender(string calldata _lenderId) internal view {
        LenderState storage lenderState = diamondStorage();
        if(msg.sender != lenderState.lenders[_lenderId].wallet) {
            revert NotLender(msg.sender, lenderState.lenders[_lenderId].wallet);
        }
    }

    /// @dev Throws error if lender is not KYB verified
    function enforceIsLenderKYBVerified(string memory _lenderId) internal view {
        LenderState storage lenderState = diamondStorage();
        if(lenderState.lenders[_lenderId].status != KYBStatus.VERIFIED) {
            revert NotVerifiedLender(_lenderId);
        }
    }

    /// @dev Throws error if lender id not exist
    function enforceIsLenderIdExist(string calldata _lenderId) internal view {
        LenderState storage lenderState = diamondStorage();
        if(bytes(lenderState.lenders[_lenderId].lenderId).length == 0) {
            revert InvalidLenderId(_lenderId);
        }
    }

}

/// @title Lender Facet
contract LenderFacet {
    event DeleteLenderEvent(string indexed lenderId);
    event CreateLenderEvent(LenderLib.Lender lender);
    event UpdateLenderHashEvent(string indexed lenderId, string prevHash, string newHash);
    event UpdateLenderCountryEvent(string indexed lenderId, string prevCountry, string newCountry);
    event UpdateLenderOnBoardTimeEvent(string indexed lenderId, uint64 prevTime, uint64 newTime);
    event UpdateLenderWalletEvent(string indexed lenderId, address prevWallet, address newWallet);
    event UpdateLenderKYBEvent(string indexed lenderId, LenderLib.KYBStatus prevStatus, LenderLib.KYBStatus newStatus);
    
    /// @dev Returns on-chain attributes of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLender(string calldata _lenderId) external view returns (LenderLib.Lender memory) {
        return LenderLib.getLender(_lenderId);
    }

    /// @dev Returns userId of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderUserId(string calldata _lenderId) external view returns (string memory) {
        return LenderLib.getLenderUserId(_lenderId);
    }

    /// @dev Returns IPFS hash of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderMetaHash(string calldata _lenderId) external view returns (string memory) {
        return LenderLib.getLenderMetaHash(_lenderId);
    }

    /// @dev Returns country of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderCountry(string calldata _lenderId) external view returns (string memory) {
        return LenderLib.getLenderCountry(_lenderId);
    }

    /// @dev Returns onboarding time (Unix timestamp) of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderOnBoardTime(string calldata _lenderId) external view returns (uint64) {
        return LenderLib.getLenderOnBoardTime(_lenderId);
    }

    /// @dev Returns wallet address of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderWallet(string calldata _lenderId) external view returns (address) {
        return LenderLib.getLenderWallet(_lenderId);
    }

    /// @dev Returns KYB status of given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderKYBStatus(string calldata _lenderId) external view returns (LenderLib.KYBStatus) {
        return LenderLib.getLenderKYBStatus(_lenderId);
    }

    /// @dev Returns number of active pools for given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderPoolIdsLength(string calldata _lenderId) external view returns (uint256) {
        return LenderLib.getPoolIdsLength(_lenderId);
    }

    /// @dev Returns PoolId associated with given lender at given index
    /// @param _lenderId LenderId associated with given lender
    /// @param _index Index number to query
    function getLenderPoolId(string calldata _lenderId, uint256 _index) external view returns (string memory) {
        return LenderLib.getPoolId(_lenderId, _index);
    }

    /// @dev Returns all PoolIds associated with given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderPoolIds(string calldata _lenderId) external view returns (string[] memory) {
        return LenderLib.getPoolIds(_lenderId);
    }

    /// @dev Returns number of payments associated with given lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderPaymentIdsLength(string calldata _lenderId) external view returns (uint256) {
        return LenderLib.getPaymentIdsLength(_lenderId);
    }

    /// @dev Returns PaymentId that is associated with given lender at given index
    /// @param _lenderId LenderId associated with given lender
    /// @param _index Index number to query
    function getLenderPaymentId(string calldata _lenderId, uint256 _index) external view returns (string memory) {
        return LenderLib.getPaymentId(_lenderId, _index);
    }

    /// @dev Returns IPFS URL of given Lender
    /// @param _lenderId LenderId associated with given lender
    function getLenderMetadataURI(string calldata _lenderId) external view returns (string memory) {
        return LenderLib.getMetadataURI(_lenderId);
    }

    /// @dev Creates a new lender
    /// @notice Restricted access function, should be called by an address with create manager role
    /// @param _lenderId RoleId associated with lender
    /// @param _userId UserId associated with lender
    /// @param _metaHash IPFS has of lender
    /// @param _country Country code of lender
    /// @param _onBoardTime On-boarding time (Unix timestamp) of lender
    /// @param _wallet Wallet address of lender
    /// @param _status KYB status of lender 
    function createLender(
        string calldata _lenderId,
        string calldata _userId,
        string calldata _metaHash,
        string calldata _country,
        uint64 _onBoardTime,
        address _wallet,
        LenderLib.KYBStatus _status
    ) external {
        LenderLib.Lender memory lender = LenderLib.createLender(_lenderId, _userId, _metaHash, _country, _onBoardTime, _wallet, _status);
        emit CreateLenderEvent(lender);
    }

    /// @dev Deletes existing lender
    /// @notice Restricted access function, should be called by an address with delete manager role
    /// @param _lenderId LenderId to delete
    function deleteLender(string calldata _lenderId) external {
        LenderLib.removeLender(_lenderId);
        emit DeleteLenderEvent(_lenderId);
    }

    /// @dev Updates IPFS hash of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _hash New IPFS hash to set 
    function updateLenderHash(string calldata _lenderId, string calldata _hash) external {
        string memory _prevHash = LenderLib.getLenderMetaHash(_lenderId);
        LenderLib.updateLenderHash(_lenderId, _hash);
        emit UpdateLenderHashEvent(_lenderId, _prevHash, _hash);
    }

    /// @dev Updates country of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _country New country to set
    function updateLenderCountry(string calldata _lenderId, string calldata _country) external {
        string memory _prevCountry = LenderLib.getLenderCountry(_lenderId);
        LenderLib.updateLenderCountry(_lenderId, _country);
        emit UpdateLenderCountryEvent(_lenderId, _prevCountry, _country);
    }

    /// @dev Updates on-boarding time (Unix timestamp) of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _onBoardTime New on-board time (Unix timestamp) to set
    function updateLenderOnBoardTime(string calldata _lenderId, uint64 _onBoardTime) external {
        uint64 _prevTime = LenderLib.getLenderOnBoardTime(_lenderId);
        LenderLib.updateLenderOnBoardTime(_lenderId, _onBoardTime);
        emit UpdateLenderOnBoardTimeEvent(_lenderId, _prevTime, _onBoardTime);
    }

    /// @dev Updates wallet address of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _wallet New wallet address to set
    function updateLenderWallet(string calldata _lenderId, address _wallet) external {
        address _prevWallet = LenderLib.getLenderWallet(_lenderId);
        LenderLib.updateLenderWallet(_lenderId, _wallet);
        emit UpdateLenderWalletEvent(_lenderId, _prevWallet, _wallet);
    }

    /// @dev Updates KYB status of given lender
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _lenderId LenderId associated with given lender
    /// @param _status KYB status to set  
    function updateLenderKYB(string calldata _lenderId, LenderLib.KYBStatus _status) external {
        LenderLib.KYBStatus _prevStatus = LenderLib.getLenderKYBStatus(_lenderId);
        LenderLib.updateLenderKYB(_lenderId, _status);
        emit UpdateLenderKYBEvent(_lenderId, _prevStatus, _status);
    }

    /// @dev Removes PaymentId associated with given lender
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _lenderId LenderId associated with given lender
    /// @param _paymentId PaymentId to remove
    function removeLenderPaymentId(string calldata _lenderId, string calldata _paymentId) external {
        LenderLib.removePaymentId(_lenderId, _paymentId);
    }

    /// @dev Removes PaymentId associated with given lender based on given index
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _lenderId LenderId associated with given lender
    /// @param _paymentIndex Index of PaymentId to remove
    function removeLenderPaymentIdByIndex(string calldata _lenderId, uint256 _paymentIndex) external {
        LenderLib.removePaymentIdByIndex(_lenderId, _paymentIndex);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import {AccessControlLib} from "./AccessControlFacet.sol";

/// @title Metadata Library
library MetadataLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.metadata.storage");

    struct MetadataState {
        string baseURI;
    }

    /// @dev Returns storage position of metadata library inside diamond
    function diamondStorage() internal pure returns (MetadataState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Returns base URI which is used to construct IPFS URL of given hash
    function getBaseURI() internal view returns (string memory) {
        MetadataState storage metadataState = diamondStorage();
        return metadataState.baseURI;
    }

    /// @dev Updates base URI which is used to construct IPFS URL of given hash
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _baseURI New base URI to set
    function updateBaseURI(string calldata _baseURI) internal {
        AccessControlLib.enforceIsConfigManager();
        MetadataState storage metadataState = diamondStorage();
        metadataState.baseURI = _baseURI;
    }    
}

/// @title Metadata Facet
contract MetadataFacet {
    event UpdateBaseURI(string prevBaseURI, string newBaseURI);

    /// @dev Returns base URI which is used to construct IPFS URL of given hash
    function getBaseURI() external view returns (string memory) {
        return MetadataLib.getBaseURI();
    }

    /// @dev Updates base URI which is used to construct IPFS URL of given hash
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _baseURI New base URI to set
    function updateBaseURI(string calldata _baseURI) external {
        string memory _prevBaseURI = MetadataLib.getBaseURI();
        MetadataLib.updateBaseURI(_baseURI);
        emit UpdateBaseURI(_prevBaseURI, _baseURI);
    }
}

// SPDX-License-Identifier: BUSL-1.1

// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import {VaultLib} from "./VaultFacet.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title Payment Library
library PaymentLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.payment.storage");

    struct PaymentState {
        mapping(string => Payment) payments;
        uint256 paymentId;
    }

    struct Payment {
        string roleId;
        string creditPoolId;
        PaymentType paymentType;
        uint64 timeStamp;
        address from;
        address to;
        uint256 amount;
    }

    enum PaymentType {
        INVESTMENT,
        PANDC,
        DEPOSIT,
        WITHDRAW,
        FEE,
        EXIT,
        PRINCIPAL,
        COUPON,
        PASTDUE
    }

    event PaymentEvent(PaymentLib.Payment payment);

    /// @dev Returns storage position of payment library inside diamond
    function diamondStorage() internal pure returns (PaymentState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Returns payment information of given payment
    /// @param _paymentId PaymentId of given payment
    function getPayment(string calldata _paymentId) internal view returns (Payment memory) {
        PaymentState storage paymentState = diamondStorage();
        return paymentState.payments[_paymentId];
    }

    /// @dev Returns last PaymentId recorded in payment library
    function getLastPaymentId() internal view returns (uint256) {
        PaymentState storage paymentState = diamondStorage();
        return paymentState.paymentId;
    }

    /// @dev Adds payment information
    /// @notice Called internally whenever new payment has been recorded by vault
    /// @param _roleId LenderId / PoolManagerId
    /// @param _creditPoolId PoolId associated with credit pool
    /// @param _type Type of payment
    /// @param _from Address from which payment has been made
    /// @param _to Address to which payment has been made
    /// @param _amount Paid amount
    function addPayment(
        string memory _roleId,
        string memory _creditPoolId,
        PaymentType _type,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (string memory) {
        VaultLib.enforceIsVault();
        PaymentState storage paymentState = diamondStorage();
        paymentState.paymentId++;
        string memory _paymentId = Strings.toString(paymentState.paymentId);
        paymentState.payments[_paymentId] = Payment(_roleId, _creditPoolId, _type, uint64(block.timestamp), _from, _to, _amount);
        emit PaymentEvent(paymentState.payments[_paymentId]);
        return _paymentId;
    }
}

/// @title Payment Facet
contract PaymentFacet {
    /// @dev Returns payment information of given payment
    /// @param _paymentId PaymentId of given payment
    function getPayment(string calldata _paymentId) external view returns (PaymentLib.Payment memory) {
        return PaymentLib.getPayment(_paymentId);
    }

    /// @dev Returns last PaymentId recorded in payment library
    function getLastPaymentId() external view returns (uint256) {
        return PaymentLib.getLastPaymentId();
    }
}

// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import {CreditPoolLib} from "./CreditPoolFacet.sol";
import {VaultLib} from "./VaultFacet.sol";
import {MetadataLib} from "./MetadataFacet.sol";
import {AccessControlLib} from "./AccessControlFacet.sol";

error NotPoolManager(address _user, address _poolManager);
error PoolManagerIdExist(string _id);
error PoolIdsExist(uint256 _length);
error NotVerifiedPoolManager(string _id);
error InvalidPoolManagerId(string _id);

// @title Pool Manager Library
library PoolManagerLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.poolmanager.storage");

    struct PoolManagerState {
        mapping(string => PoolManager) poolManagers;
    }

    struct PoolManager {
        string poolManagerId;
        string userId;
        string metaHash;
        string country;
        uint64 onBoardTime;
        address wallet;
        KYBStatus status;
        string[] poolIds;
        string[] paymentIds;
    }

    enum KYBStatus {PENDING, VERIFIED, REJECTED}

    /// @dev Returns storage position of pool manager library inside diamond
    function diamondStorage() internal pure returns (PoolManagerState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Returns on-chain attributes of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManager(string calldata _poolManagerId) internal view returns (PoolManager memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId];
    }

    /// @dev Returns userId of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerUserId(string calldata _poolManagerId) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].userId;
    }

    /// @dev Returns IPFS hash of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerMetaHash(string calldata _poolManagerId) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].metaHash;
    }

    /// @dev Returns country of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerCountry(string calldata _poolManagerId) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].country;
    }

    /// @dev Returns onboarding time (Unix timestamp) of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerOnBoardTime(string calldata _poolManagerId) internal view returns (uint64) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].onBoardTime;
    }

    /// @dev Returns wallet address of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerWallet(string calldata _poolManagerId) internal view returns (address) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].wallet;
    }

    /// @dev Returns KYB status of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerKYBStatus(string calldata _poolManagerId) internal view returns (KYBStatus) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].status;
    }

    /// @dev Returns number of pools associated with given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolIdsLength(string calldata _poolManagerId) internal view returns (uint256) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].poolIds.length;
    }

    /// @dev Returns PoolId associated with given pool manager at given index
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _index Index number to query
    function getPoolId(string calldata _poolManagerId, uint256 _index) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].poolIds[_index];
    }

    /// @dev Returns all PoolIds associated with given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolIds(string calldata _poolManagerId) internal view returns (string[] memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].poolIds;
    }

    /// @dev Returns number of payments associated with given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPaymentIdsLength(string calldata _poolManagerId) internal view returns (uint256) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].paymentIds.length;
    }

    /// @dev Returns PaymentId that is associated with given pool manager at given index
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _index Index number to query
    function getPaymentId(string calldata _poolManagerId, uint256 _index) internal view returns (string memory) {
        PoolManagerState storage poolManagerState = diamondStorage();
        return poolManagerState.poolManagers[_poolManagerId].paymentIds[_index];
    }

    /// @dev Returns IPFS URL of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getMetadataURI(string calldata _poolManagerId) internal view returns (string memory) {
        enforceIsPoolManagerIdExist(_poolManagerId);
        string memory _baseURI = MetadataLib.getBaseURI();
        string memory _metaHash = getPoolManagerMetaHash(_poolManagerId);
        return bytes(_baseURI).length > 0 ? string(string.concat(bytes(_baseURI), bytes(_metaHash))) : "";
    }

    /// @dev Creates a new pool manager
    /// @notice Restricted access function, should be called by an address with create manager role
    /// @param _poolManagerId RoleId associated with pool manager
    /// @param _userId UserId associated with pool manager
    /// @param _metaHash IPFS has of pool manager
    /// @param _country Country code of pool manager
    /// @param _onBoardTime On-boarding time (Unix timestamp) of pool manager
    /// @param _wallet Wallet address of pool manager
    /// @param _status KYB status of pool manager
    function createPoolManager(
        string calldata _poolManagerId,
        string calldata _userId,
        string calldata _metaHash,
        string calldata _country,
        uint64 _onBoardTime,
        address _wallet,
        KYBStatus _status
    ) internal returns (PoolManager memory) {
        AccessControlLib.enforceIsCreateManager();
        PoolManagerState storage poolManagerState = diamondStorage();
        if(keccak256(bytes(_poolManagerId)) == keccak256(bytes(poolManagerState.poolManagers[_poolManagerId].poolManagerId))) {
            revert PoolManagerIdExist(_poolManagerId);
        }
        poolManagerState.poolManagers[_poolManagerId] = PoolManager(_poolManagerId, _userId, _metaHash, _country, _onBoardTime, _wallet, _status, new string[](0), new string[](0));
        return poolManagerState.poolManagers[_poolManagerId];
    }

    /// @dev Deletes existing pool manager
    /// @notice Restricted access function, should be called by an address with delete manager role
    /// @param _poolManagerId PoolManagerId to delete
    function removePoolManager(string calldata _poolManagerId) internal {
        AccessControlLib.enforceIsDeleteManager();
        PoolManagerState storage poolManagerState = diamondStorage();
        if(poolManagerState.poolManagers[_poolManagerId].poolIds.length != 0) {
            revert PoolIdsExist(poolManagerState.poolManagers[_poolManagerId].poolIds.length);
        }
        delete poolManagerState.poolManagers[_poolManagerId];
    }

    /// @dev Updates IPFS hash of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _hash New IPFS hash to set 
    function updatePoolManagerHash(string calldata _poolManagerId, string calldata _hash) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].metaHash = _hash;
    }

    /// @dev Updates country of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _country New country to set
    function updatePoolManagerCountry(string calldata _poolManagerId, string calldata _country) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].country = _country;
    }

    /// @dev Updates on-boarding time (Unix timestamp) of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _onBoardTime New on-board time (Unix timestamp) to set
    function updatePoolManagerOnBoardTime(string calldata _poolManagerId, uint64 _onBoardTime) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].onBoardTime = _onBoardTime;
    }
    
    /// @dev Updates wallet address of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _wallet New wallet address to set
    function updatePoolManagerWallet(string calldata _poolManagerId, address _wallet) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].wallet = _wallet;
    }

    /// @dev Updates KYB status of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _status KYB status to set  
    function updatePoolManagerKYB(string calldata _poolManagerId, KYBStatus _status) internal {
        AccessControlLib.enforceIsEditManager();
        enforceIsPoolManagerIdExist(_poolManagerId);
        PoolManagerState storage poolManagerState = diamondStorage();
        poolManagerState.poolManagers[_poolManagerId].status = _status;
    }

    /// @dev Adds PoolId to given pool manager's pool list
    /// @notice Called internally whenever pool manager creates a new pool
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _poolId PoolId associated with credit pool that is created
    function addPoolId(string calldata _poolManagerId, string calldata _poolId) internal {
        CreditPoolLib.enforceIsCreditPool();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        poolManager.poolIds.push(_poolId);
    }

    /// @dev Removes PoolId from given pool manager's pool list based on given index
    /// @notice Called internally whenever delete manager removes a pool 
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _poolIndex Index of pool to remove from pool manager's pool list
    function removePoolIdByIndex(string memory _poolManagerId, uint256 _poolIndex) internal {
        CreditPoolLib.enforceIsCreditPool();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        if(_poolIndex != poolManager.poolIds.length - 1) {
            poolManager.poolIds[_poolIndex] = poolManager.poolIds[poolManager.poolIds.length - 1];
            string memory _poolId = poolManager.poolIds[_poolIndex];
            CreditPoolLib.updateBindingIndexOfPool(_poolId, _poolIndex);
        }
        poolManager.poolIds.pop();
    }
    
    /// @dev Adds PaymentId associated with given pool manager
    /// @notice Called internally whenever a new payment registered that is associated with given pool manager 
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _paymentId PaymentId associated with a new payment
    function addPaymentId(string memory _poolManagerId, string memory _paymentId) internal {
        VaultLib.enforceIsVault();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        poolManager.paymentIds.push(_paymentId);
    }

    /// @dev Removes PaymentId associated with given pool manager
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _paymentId PaymentId to remove
    function removePaymentId(string calldata _poolManagerId, string calldata _paymentId) internal {
        AccessControlLib.enforceIsDeleteManager();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        uint256 index;
        for (uint256 i = 0; i < poolManager.paymentIds.length; i++) {
            if (keccak256(bytes(poolManager.paymentIds[i])) == keccak256(bytes(_paymentId))) {
                index = i;
                break;
            }
        }
        poolManager.paymentIds[index] = poolManager.paymentIds[poolManager.paymentIds.length - 1];
        poolManager.paymentIds.pop();
    }

    /// @dev Removes PaymentId associated with given pool manager based on given index
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _paymentIndex Index of PaymentId to remove
    function removePaymentIdByIndex(string calldata _poolManagerId, uint256 _paymentIndex) internal {
        AccessControlLib.enforceIsDeleteManager();
        PoolManagerState storage poolManagerState = diamondStorage();
        PoolManager storage poolManager = poolManagerState.poolManagers[_poolManagerId];
        if(_paymentIndex != poolManager.paymentIds.length - 1) {
            poolManager.paymentIds[_paymentIndex] = poolManager.paymentIds[poolManager.paymentIds.length - 1];
        }
        poolManager.paymentIds.pop();
    }

    /// @dev Throws error if called by other than pool manager
    function enforceIsPoolManager(string calldata _poolManagerId) internal view {
        PoolManagerState storage poolManagerState = diamondStorage();
        if(msg.sender != poolManagerState.poolManagers[_poolManagerId].wallet) {
            revert NotPoolManager(msg.sender, poolManagerState.poolManagers[_poolManagerId].wallet);
        }
    }

    /// @dev Throws error if pool manager is not KYB verified
    function enforceIsPoolManagerKYBVerified(string memory _poolManagerId) internal view {
        PoolManagerState storage poolManagerState = diamondStorage();
        if(poolManagerState.poolManagers[_poolManagerId].status != KYBStatus.VERIFIED) {
            revert NotVerifiedPoolManager(_poolManagerId);
        }
    }

    /// @dev Throws error if pool manager id not exist
    function enforceIsPoolManagerIdExist(string calldata _poolManagerId) internal view {
        PoolManagerState storage poolManagerState = diamondStorage();
        if(bytes(poolManagerState.poolManagers[_poolManagerId].poolManagerId).length == 0) {
            revert InvalidPoolManagerId(_poolManagerId);
        }
    }

}

/// @title Pool Manager Facet
contract PoolManagerFacet {
    event DeletePoolManagerEvent(string indexed poolManagerId);
    event CreatePoolManagerEvent(PoolManagerLib.PoolManager poolManager);
    event UpdatePoolManagerHashEvent(string indexed poolManagerId, string prevHash, string newHash);
    event UpdatePoolManagerCountryEvent(string indexed poolManagerId, string prevCountry, string newCountry);
    event UpdatePoolManagerOnBoardTimeEvent(string indexed poolManagerId, uint64 prevTime, uint64 newTime);
    event UpdatePoolManagerWalletEvent(string indexed poolManagerId, address prevWallet, address newWallet);
    event UpdatePoolManagerKYBEvent(string indexed poolManagerId, PoolManagerLib.KYBStatus prevStatus, PoolManagerLib.KYBStatus newStatus);
    
    /// @dev Returns on-chain attributes of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManager(string calldata _poolManagerId) external view returns (PoolManagerLib.PoolManager memory) {
        return PoolManagerLib.getPoolManager(_poolManagerId);
    }

    /// @dev Returns userId of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerUserId(string calldata _poolManagerId) external view returns (string memory) {
        return PoolManagerLib.getPoolManagerUserId(_poolManagerId);
    }

    /// @dev Returns IPFS hash of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerMetaHash(string calldata _poolManagerId) external view returns (string memory) {
        return PoolManagerLib.getPoolManagerMetaHash(_poolManagerId);
    }

    /// @dev Returns country of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerCountry(string calldata _poolManagerId) external view returns (string memory) {
        return PoolManagerLib.getPoolManagerCountry(_poolManagerId);
    }

    /// @dev Returns onboarding time (Unix timestamp) of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerOnBoardTime(string calldata _poolManagerId) external view returns (uint64) {
        return PoolManagerLib.getPoolManagerOnBoardTime(_poolManagerId);
    }

    /// @dev Returns wallet address of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerWallet(string calldata _poolManagerId) external view returns (address) {
        return PoolManagerLib.getPoolManagerWallet(_poolManagerId);
    }

    /// @dev Returns KYB status of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerKYBStatus(string calldata _poolManagerId) external view returns (PoolManagerLib.KYBStatus) {
        return PoolManagerLib.getPoolManagerKYBStatus(_poolManagerId);
    }

    /// @dev Returns number of pools associated with given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerPoolIdsLength(string calldata _poolManagerId) external view returns (uint256) {
        return PoolManagerLib.getPoolIdsLength(_poolManagerId);
    }

    /// @dev Returns PoolId associated with given pool manager at given index
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _index Index number to query
    function getPoolManagerPoolId(string calldata _poolManagerId, uint256 _index) external view returns (string memory) {
        return PoolManagerLib.getPoolId(_poolManagerId, _index);
    }

    /// @dev Returns all PoolIds associated with given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerPoolIds(string calldata _poolManagerId) external view returns (string[] memory) {
        return PoolManagerLib.getPoolIds(_poolManagerId);
    }

    /// @dev Returns number of payments associated with given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerPaymentIdsLength(string calldata _poolManagerId) external view returns (uint256) {
        return PoolManagerLib.getPaymentIdsLength(_poolManagerId);
    }

    /// @dev Returns PaymentId that is associated with given pool manager at given index
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _index Index number to query
    function getPoolManagerPaymentId(string calldata _poolManagerId, uint256 _index) external view returns (string memory) {
        return PoolManagerLib.getPaymentId(_poolManagerId, _index);
    }

    /// @dev Returns IPFS URL of given pool manager
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    function getPoolManagerMetadataURI(string calldata _poolManagerId) external view returns (string memory) {
        return PoolManagerLib.getMetadataURI(_poolManagerId);
    }

    /// @dev Creates a new pool manager
    /// @notice Restricted access function, should be called by an address with create manager role
    /// @param _poolManagerId RoleId associated with pool manager
    /// @param _userId UserId associated with pool manager
    /// @param _metaHash IPFS has of pool manager
    /// @param _country Country code of pool manager
    /// @param _onBoardTime On-boarding time (Unix timestamp) of pool manager
    /// @param _wallet Wallet address of pool manager
    /// @param _status KYB status of pool manager
    function createPoolManager(
        string calldata _poolManagerId,
        string calldata _userId,
        string calldata _metaHash,
        string calldata _country,
        uint64 _onBoardTime,
        address _wallet,
        PoolManagerLib.KYBStatus _status
    ) external {
        PoolManagerLib.PoolManager memory poolManager = PoolManagerLib.createPoolManager(_poolManagerId, _userId, _metaHash, _country, _onBoardTime, _wallet, _status);
        emit CreatePoolManagerEvent(poolManager);
    }

    /// @dev Deletes existing pool manager
    /// @notice Restricted access function, should be called by an address with delete manager role
    /// @param _poolManagerId PoolManagerId to delete
    function deletePoolManager(string calldata _poolManagerId) external {
        PoolManagerLib.removePoolManager(_poolManagerId);
        emit DeletePoolManagerEvent(_poolManagerId);
    }

    /// @dev Updates IPFS hash of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _hash New IPFS hash to set 
    function updatePoolManagerHash(string calldata _poolManagerId, string calldata _hash) external {
        string memory _prevHash = PoolManagerLib.getPoolManagerMetaHash(_poolManagerId);
        PoolManagerLib.updatePoolManagerHash(_poolManagerId, _hash);
        emit UpdatePoolManagerHashEvent(_poolManagerId, _prevHash, _hash);
    }

    /// @dev Updates country of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _country New country to set
    function updatePoolManagerCountry(string calldata _poolManagerId, string calldata _country) external {
        string memory _prevCountry = PoolManagerLib.getPoolManagerCountry(_poolManagerId);
        PoolManagerLib.updatePoolManagerCountry(_poolManagerId, _country);
        emit UpdatePoolManagerCountryEvent(_poolManagerId, _prevCountry, _country);
    }

    /// @dev Updates on-boarding time (Unix timestamp) of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _onBoardTime New on-board time (Unix timestamp) to set
    function updatePoolManagerOnBoardTime(string calldata _poolManagerId, uint64 _onBoardTime) external {
        uint64 _prevTime = PoolManagerLib.getPoolManagerOnBoardTime(_poolManagerId);
        PoolManagerLib.updatePoolManagerOnBoardTime(_poolManagerId, _onBoardTime);
        emit UpdatePoolManagerOnBoardTimeEvent(_poolManagerId, _prevTime, _onBoardTime);
    }

    /// @dev Updates wallet address of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _wallet New wallet address to set
    function updatePoolManagerWallet(string calldata _poolManagerId, address _wallet) external {
        address _prevWallet = PoolManagerLib.getPoolManagerWallet(_poolManagerId);
        PoolManagerLib.updatePoolManagerWallet(_poolManagerId, _wallet);
        emit UpdatePoolManagerWalletEvent(_poolManagerId, _prevWallet, _wallet);
    }

    /// @dev Updates KYB status of given pool manager
    /// @notice Restricted access function, should be called by an address with edit manager role
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _status KYB status to set  
    function updatePoolManagerKYB(string calldata _poolManagerId, PoolManagerLib.KYBStatus _status) external {
        PoolManagerLib.KYBStatus _prevStatus = PoolManagerLib.getPoolManagerKYBStatus(_poolManagerId);
        PoolManagerLib.updatePoolManagerKYB(_poolManagerId, _status);
        emit UpdatePoolManagerKYBEvent(_poolManagerId, _prevStatus, _status);
    }

    /// @dev Removes PaymentId associated with given pool manager
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _paymentId PaymentId to remove
    function removePoolManagerPaymentId(string calldata _poolManagerId, string calldata _paymentId) external {
        PoolManagerLib.removePaymentId(_poolManagerId, _paymentId);
    }

    /// @dev Removes PaymentId associated with given pool manager based on given index
    /// @notice Restricted access function, should be called by an address with delete manager role 
    /// @param _poolManagerId PoolManagerId associated with given pool manager
    /// @param _paymentIndex Index of PaymentId to remove
    function removePoolManagerPaymentIdByIndex(string calldata _poolManagerId, uint256 _paymentIndex) external {
        PoolManagerLib.removePaymentIdByIndex(_poolManagerId, _paymentIndex);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import {AccessControlLib} from "./AccessControlFacet.sol";
import {CreditPoolLib} from "./CreditPoolFacet.sol";
import {VaultLib} from "./VaultFacet.sol";
import {LenderLib} from "./LenderFacet.sol";
import {PaymentLib} from "./PaymentFacet.sol";

error PoolTokenInitializedBefore(string poolId);
error InvalidToken(address poolToken);
error EnforcedPause();
error InvalidAmount(uint256 amount);

/// @title Stable Coin Library
library StableCoinLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.stablecoin.storage");

    struct StableCoinState {
        mapping (string => address) poolToken;
        mapping (address => bool) isWhitelisted;
        mapping (string => mapping (address => uint256)) stableCoinBalance;
        mapping (string => address) requestedToken;
        mapping (string => address) paymentStableCoin;
        mapping (string => uint256) paidBalance;
        mapping (string => uint64) lastWithdrawalTimeStamp;
        uint64 lenderThreshold;
        uint64 poolThreshold;
        uint64 lenderCoolingTime;
        uint64 poolCoolingTime;
    }

    /// @dev Returns storage position of stable coin library inside diamond
    function diamondStorage() internal pure returns (StableCoinState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Returns address of stable coin associated with given credit pool
    /// @param _poolId PoolId of given credit pool 
    function getPoolToken(string memory _poolId) internal view returns (address) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.poolToken[_poolId];
    }

    /// @dev Returns whitelisting status of given stable coin
    /// @param _token Address of given stable coin
    function isWhitelistedToken(address _token) internal view returns (bool) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.isWhitelisted[_token];
    }

    /// @dev Returns stable coin balance of given vault account
    /// @param _roleId RoleId associated with given vault account
    /// @param _token Address of stable coin
    function getStableCoinBalance(string calldata _roleId, address _token) internal view returns (uint256) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.stableCoinBalance[_roleId][_token];
    }

    /// @dev Returns address of stable coin requested to be withdrawn by given roleId
    /// @param _roleId RoleId associated with given vault account 
    function getRequestedToken(string memory _roleId) internal view returns (address) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.requestedToken[_roleId];
    }

    /// @dev Returns address of stable coin associated with given payment
    /// @param _paymentId PaymentId of given payment
    function getPaymentStableCoin(string memory _paymentId) internal view returns (address) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.paymentStableCoin[_paymentId];
    }

    /// @dev Returns threshold amount for lender auto withdrawal
    function getLenderThreshold() internal view returns (uint64) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.lenderThreshold;
    }
    
    /// @dev Returns threshold amount for investment auto withdrawal
    function getPoolThreshold() internal view returns (uint64) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.poolThreshold;
    }

    /// @dev Returns cooling time in seconds for lender auto withdrawal
    function getLenderCoolingTime() internal view returns (uint64) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.lenderCoolingTime;
    }

    /// @dev Returns cooling time in seconds for investment auto withdrawal
    function getPoolCoolingTime() internal view returns (uint64) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.poolCoolingTime;
    }

    /// @dev Returns undistributed amount of given pool
    /// @param _roleId PoolId of given credit pool
    function getPaidBalance(string calldata _roleId) internal view returns (uint256) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.paidBalance[_roleId];
    }

    /// @dev Returns timestamp of last withdrawal
    /// @param _roleId RoleId / PoolId of given lender / credit pool
    function getLastWithdrawalTimeStamp(string calldata _roleId) internal view returns (uint64) {
        StableCoinState storage stableCoinState = diamondStorage();
        return stableCoinState.lastWithdrawalTimeStamp[_roleId];
    }

    /// @dev Initializes stable coin information of given pool
    /// @notice Restricted access function, should be called by an address with create manager role
    /// @param _poolId PoolId of given credit pool
    /// @param _poolToken Address of stable coin associated with given credit pool
    function initializePoolToken(string calldata _poolId, address _poolToken) internal {
        AccessControlLib.enforceIsCreateManager();
        CreditPoolLib.enforceIsCreditPoolIdExist(_poolId);
        StableCoinState storage stableCoinState = diamondStorage();
        if(!stableCoinState.isWhitelisted[_poolToken]) {
            revert InvalidToken(_poolToken);
        }
        if(stableCoinState.poolToken[_poolId] == address(0)) {
            stableCoinState.poolToken[_poolId] = _poolToken;
        }
    }

    /// @dev Removes stable coin information of given pool
    /// @notice Called internally whenever pool has been deleted
    /// @param _poolId PoolId of given credit pool
    function deletePoolToken(string calldata _poolId) internal {
        CreditPoolLib.enforceIsCreditPool();
        StableCoinState storage stableCoinState = diamondStorage();
        delete stableCoinState.poolToken[_poolId];
    }

    /// @dev Adds / Removes stable coin to/from whitelist
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _token Address of stable coin
    function updateWhitelist(address _token) internal {
        AccessControlLib.enforceIsConfigManager();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.isWhitelisted[_token] = !stableCoinState.isWhitelisted[_token];
    }

    /// @dev Updates threshold amount for lender auto withdrawal
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _threshold New threshold amount to set
    function updateLenderThreshold(uint64 _threshold) internal {
        AccessControlLib.enforceIsConfigManager();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.lenderThreshold = _threshold;
    }

    /// @dev Updates threshold amount for investment auto withdrawal
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _threshold New threshold amount to set
    function updatePoolThreshold(uint64 _threshold) internal {
        AccessControlLib.enforceIsConfigManager();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.poolThreshold = _threshold;
    }

    /// @dev Updates cooling time in seconds for lender auto withdrawal
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _time New cooling time in seconds
    function updateLenderCoolingTime(uint64 _time) internal {
        AccessControlLib.enforceIsConfigManager();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.lenderCoolingTime = _time;
    }

    /// @dev Updates cooling time in seconds for investment auto withdrawal
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _time New cooling time in seconds
    function updatePoolCoolingTime(uint64 _time) internal {
        AccessControlLib.enforceIsConfigManager();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.poolCoolingTime = _time;
    }

    /// @dev Increases stable coin balance of given lender
    /// @notice Called internally whenever stable coin balance of given lender gets increased
    /// @param _roleId LenderId of given lender
    /// @param _token Address of stable coin
    /// @param _amount Amount of stable coin to be added into lender stable coin balance
    function increaseBalance(string memory _roleId, address _token, uint256 _amount) internal {
        VaultLib.enforceIsVault();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.stableCoinBalance[_roleId][_token] += _amount;
    }

    /// @dev Decreases stable coin balance of given lender
    /// @notice Called internally whenever stable coin balance of given lender gets decreased
    /// @param _roleId LenderId of given lender
    /// @param _token Address of stable coin
    /// @param _amount Amount of stable coin to be subtracted from lender stable coin balance
    function decreaseBalance(string memory _roleId, address _token, uint256 _amount) internal {
        VaultLib.enforceIsVault();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.stableCoinBalance[_roleId][_token] -= _amount;
    }

    /// @dev Increases paid balance of given pool
    /// @notice Called internally whenever paid balance of given pool gets increased
    /// @param _roleId PoolId of given credit pool
    /// @param _amount Amount of stable coin to be added into pool paid balance
    function increasePaidBalance(string memory _roleId, uint256 _amount) internal {
        VaultLib.enforceIsVault();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.paidBalance[_roleId] += _amount;
    }

    /// @dev Decreases paid balance of given pool
    /// @notice Called internally whenever paid balance of given pool gets decreased
    /// @param _roleId PoolId of given credit pool
    /// @param _amount Amount of stable coin to be subtracted from pool paid balance
    function decreasePaidBalance(string memory _roleId, uint256 _amount) internal {
        VaultLib.enforceIsVault();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.paidBalance[_roleId] -= _amount;
    }

    /// @dev Updates last withdrawal time of given lender / pool
    /// @notice Called internally whenever lender / pool withdrawal processed automatically
    /// @param _roleId LenderId / PoolId of given lender / credit pool
    /// @param _timeStamp Timestamp of last withdrawal
    function updateLastWithdrawalTimeStamp(string memory _roleId, uint64 _timeStamp) internal {
        VaultLib.enforceIsVault();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.lastWithdrawalTimeStamp[_roleId] = _timeStamp;
    }

    /// @dev Binds requested stable coin information with given roleId
    /// @notice Called internally whenever given wallet requests to withdraw stable coin
    /// @param _roleId LenderId who requested given tokens to be withdrawn from vault
    /// @param _token Address of requested stable coin
    function addRequestedToken(string calldata _roleId, address _token) internal {
        VaultLib.enforceIsVault();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.requestedToken[_roleId] = _token;
    }

    /// @dev Binds stable coin information with given payment
    /// @notice Called internally whenever a direct payment in given stable coin has been initiated
    /// @param _paymentId PaymentId of given payment
    /// @param _token Address of stable coin
    function addPaymentStableCoin(string memory _paymentId, address _token) internal {
        VaultLib.enforceIsVault();
        StableCoinState storage stableCoinState = diamondStorage();
        stableCoinState.paymentStableCoin[_paymentId] = _token;
    }
}

/// @title Stable Coin Facet
contract StableCoinExtension {
    event UpdatePoolToken(string indexed poolId, address poolToken);
    event UpdateWhitelist(address indexed token, bool isWhitelisted);
    event UpdateLenderThreshold(uint64 prevThreshold, uint64 newThreshold);
    event UpdatePoolThreshold(uint64 prevThreshold, uint64 newThreshold);
    event UpdateLenderCoolingTime(uint64 prevTime, uint64 newTime);
    event UpdatePoolCoolingTime(uint64 prevTime, uint64 newTime);
    event CreateCreditPoolEvent(CreditPoolLib.CreditPool creditPool);
    event AdjustStableCoin(string indexed roleId, uint256 amount, address token, PaymentLib.PaymentType paymentType);
    event EmergencyWithdraw(address indexed executor, address token, address receiver, uint256 amount);

    /// @dev Returns address of stable coin associated with given credit pool
    /// @param _poolId PoolId of given credit pool 
    function getPoolToken(string calldata _poolId) external view returns (address) {
        return StableCoinLib.getPoolToken(_poolId);
    }

    /// @dev Returns whitelisting status of given stable coin
    /// @param _token Address of given stable coin
    function isWhitelistedToken(address _token) external view returns (bool) {
        return StableCoinLib.isWhitelistedToken(_token);
    }

    /// @dev Returns stable coin balance of given vault account
    /// @param _roleId RoleId associated with given vault account
    /// @param _token Address of stable coin
    function getStableCoinBalance(string calldata _roleId, address _token) external view returns (uint256) {
        return StableCoinLib.getStableCoinBalance(_roleId, _token);
    }

    /// @dev Returns address of stable coin requested to be withdrawn by given roleId
    /// @param _roleId RoleId associated with given vault account 
    function getRequestedToken(string memory _roleId) external view returns (address) {
        return StableCoinLib.getRequestedToken(_roleId);
    }

    /// @dev Returns address of stable coin associated with given payment
    /// @param _paymentId PaymentId of given payment
    function getPaymentStableCoin(string memory _paymentId) external view returns (address) {
        return StableCoinLib.getPaymentStableCoin(_paymentId);
    }

    /// @dev Returns threshold amount for lender auto withdrawal
    function getLenderThreshold() external view returns (uint64) {
        return StableCoinLib.getLenderThreshold();
    }
    
    /// @dev Returns threshold amount for investment auto withdrawal
    function getPoolThreshold() external view returns (uint64) {
        return StableCoinLib.getPoolThreshold();
    }

    /// @dev Returns cooling time in seconds for lender auto withdrawal
    function getLenderCoolingTime() external view returns (uint64) {
        return StableCoinLib.getLenderCoolingTime();
    }

    /// @dev Returns cooling time in seconds for investment auto withdrawal
    function getPoolCoolingTime() external view returns (uint64) {
        return StableCoinLib.getPoolCoolingTime();
    }

    /// @dev Returns undistributed amount of given pool
    /// @param _roleId PoolId of given credit pool
    function getPaidBalance(string calldata _roleId) external view returns (uint256) {
        return StableCoinLib.getPaidBalance(_roleId);
    }

    /// @dev Returns timestamp of last withdrawal
    /// @param _roleId RoleId / PoolId of given lender / credit pool
    function getLastWithdrawalTimeStamp(string calldata _roleId) external view returns (uint64) {
        return StableCoinLib.getLastWithdrawalTimeStamp(_roleId);
    }

    /// @dev Initializes stable coin information of given pool
    /// @notice Restricted access function, should be called by an address with create manager role
    /// @param _poolId PoolId of given credit pool
    /// @param _poolToken Address of stable coin associated with given credit pool
    function initializePoolToken(string calldata _poolId, address _poolToken) external {
        StableCoinLib.initializePoolToken(_poolId, _poolToken);
        emit UpdatePoolToken(_poolId, _poolToken);
    }

    /// @dev Adds / Removes stable coin to/from whitelist
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _token Address of stable coin
    function updateWhitelist(address _token) external {
        StableCoinLib.updateWhitelist(_token);
        bool _isWhitelisted = StableCoinLib.isWhitelistedToken(_token);
        emit UpdateWhitelist(_token, _isWhitelisted);
    }

    /// @dev Updates threshold amount for lender auto withdrawal
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _threshold New threshold amount to set
    function updateLenderThreshold(uint64 _threshold) external {
        uint64 _prev = StableCoinLib.getLenderThreshold();
        emit UpdateLenderThreshold(_prev, _threshold);
        StableCoinLib.updateLenderThreshold(_threshold);
    }

    /// @dev Updates threshold amount for investment auto withdrawal
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _threshold New threshold amount to set
    function updatePoolThreshold(uint64 _threshold) external {
        uint64 _prev = StableCoinLib.getPoolThreshold();
        emit UpdatePoolThreshold(_prev, _threshold);
        StableCoinLib.updatePoolThreshold(_threshold);
    }

    /// @dev Updates cooling time in seconds for lender auto withdrawal
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _time New cooling time in seconds
    function updateLenderCoolingTime(uint64 _time) external {
        uint64 _prev = StableCoinLib.getLenderCoolingTime();
        emit UpdateLenderCoolingTime(_prev, _time);
        StableCoinLib.updateLenderCoolingTime(_time);
    }

    /// @dev Updates cooling time in seconds for investment auto withdrawal
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _time New cooling time in seconds
    function updatePoolCoolingTime(uint64 _time) external {
        uint64 _prev = StableCoinLib.getPoolCoolingTime();
        emit UpdatePoolCoolingTime(_prev, _time);
        StableCoinLib.updatePoolCoolingTime(_time);
    }

    /// @dev Creates a new credit pool
    /// @notice Restricted access function, should be called by an address with create manager role
    /// @param _creditPoolId Id associated with credit pool
    /// @param _poolManagerId PoolManagerId of manager who owns the pool
    /// @param _metaHash IPFS hash of credit pool
    /// @param _borrowingAmount Pool size
    /// @param _inceptionTime Credit pool inception time (Unix timestamp)
    /// @param _expiryTime Credit pool cut-off time (Unix timestamp)
    /// @param _curingPeriod Curing period of credit pool in seconds
    /// @param _status Status of cresit pool
    /// @param _poolToken Address of stable coin to be used as payment token
    function createCreditPool(
        string calldata _creditPoolId,
        string calldata _poolManagerId,
        string calldata _metaHash,
        uint256 _borrowingAmount,
        uint64 _inceptionTime,
        uint64 _expiryTime,
        uint32 _curingPeriod,
        CreditPoolLib.CreditPoolStatus _status,
        address _poolToken
    ) external {
        CreditPoolLib.CreditPool memory creditPool = CreditPoolLib.createCreditPool(_creditPoolId, _poolManagerId, _metaHash, _borrowingAmount, _inceptionTime, _expiryTime, _curingPeriod, _status);
        emit CreateCreditPoolEvent(creditPool);
        StableCoinLib.initializePoolToken(_creditPoolId, _poolToken);
        emit UpdatePoolToken(_creditPoolId, _poolToken);       
    }

    /// @dev Adjusts balance of lender account in case of correction
    /// @notice Restricted access function, should be called by an owner only
    /// @param _roleId LenderId of a vault account
    /// @param _amount Amount of payment token to adjust
    /// @param _token Address of stable coin
    /// @param _type Type of adjustment (deposit / withdraw) 
    function adjustStableCoinBalance(
        string calldata _roleId,
        uint256 _amount,
        address _token,
        PaymentLib.PaymentType _type
    ) external {
        VaultLib.adjustStableCoinBalance(_roleId, _amount, _token, _type);
        emit AdjustStableCoin(_roleId, _amount, _token, _type);
    }

    /// @dev Withdraws ERC20 token from contract in case of emergency
    /// @notice Restricted access function, should be called by an owner only
    /// @param _token Address of ERC20 token to withdraw
    /// @param _to Address of receiver
    /// @param _amount Amount of ERC20 token to withdraw from contract 
    function emergencyWithdraw(address _token, address _to, uint256 _amount) external {
        VaultLib.emergencyWithdraw(_token, _to, _amount);
        emit EmergencyWithdraw(msg.sender, _token, _to, _amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LenderLib} from "./LenderFacet.sol";
import {CreditPoolLib} from "./CreditPoolFacet.sol";
import {PoolManagerLib} from "./PoolManagerFacet.sol";
import {PaymentLib} from "./PaymentFacet.sol";
import {AccessControlLib} from "./AccessControlFacet.sol";
import {StableCoinLib} from "./StableCoinExtension.sol";
import {DistributeLib} from "./DistributeExtension.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

error NotVaultCall();
error PaymentTokenIsInitialized(address token);
error InvalidAmount(uint256 amount);
error InvalidPaymentType(PaymentLib.PaymentType paymentType);
error CuringPeriodIsNotOver(string roleId);
error PendingRequestExist(string roleId);
error InvalidRequestIndex(uint256 index);
error EnforcedPause();
error ExpectedPause();
error InvalidPoolToken(address poolToken);
error InvalidFunction();

/// @title Vault library
library VaultLib {
    using SafeERC20 for IERC20;
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.vault.storage");

    struct VaultState {
        mapping(string => uint256) vaultBalance;
        mapping(string => uint256) borrowedAmount;
        mapping(string => RequestStatus) pendingRequest;
        Request[] requests;
        uint256 minDepositLimit;
        address paymentToken;
        bool isVaultCall;
        bool paused;
    }

    struct Request {
        string roleId;
        string poolId;
        address wallet;
        RequestType requestType;
        uint256 amount;
    }

    struct RequestStatus {
        bool isPending;
        uint256 requestIndex;
    }

    struct PaymentInfo {
        uint256 amount;
        PaymentLib.PaymentType paymentType;
    }

    enum RequestType {INVESTMENT, WITHDRAW, RECEIVE}

    enum AccountType {LENDER, POOL}

    event Exit(string indexed roleId, string poolId, uint256 amount);
    event Fee(string indexed poolId, uint256 amount);

    modifier whenNotPaused() {
        requireNotPaused();
        _;
    }

    modifier whenPaused() {
        requirePaused();
        _;
    }
    
    /// @dev Returns storage position of vault library inside diamond
    function diamondStorage() internal pure returns (VaultState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev Returns vault balance of given vault account
    /// @param _roleId RoleId associated with given vault account  
    function getVaultBalance(string calldata _roleId) internal view returns (uint256) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.vaultBalance[_roleId];
    }

    /// @dev Returns stable coin balance of given vault account
    /// @param _roleId RoleId associated with given vault account
    /// @param _token Address of stable coin  
    function getTokenBalance(string calldata _roleId, address _token) internal view returns (uint256) {
        if(_token == getPaymentToken()) {
            return getVaultBalance(_roleId);
        } else {
            return StableCoinLib.getStableCoinBalance(_roleId, _token);
        }
    }

    /// @dev Returns amount already borrowed by given pool
    /// @param _poolId PoolId associated with given pool
    function getBorrowedAmount(string memory _poolId) internal view returns (uint256) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.borrowedAmount[_poolId];
    }

    /// @dev Returns minimum amount that needs to be deposited 
    function getMinDepositLimit() internal view returns (uint256) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.minDepositLimit;
    }

    /// @dev Returns contract address of payment token
    function getPaymentToken() internal view returns (address) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.paymentToken;
    }

    /// @dev Returns request status of given user
    /// @param _roleId LenderId / PoolManagerId of given user
    function getRequestStatus(string calldata _roleId) internal view returns (RequestStatus memory) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.pendingRequest[_roleId];
    }

    /// @dev Returns request list
    function getRequests() internal view returns (Request[] memory) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.requests;
    }

    /// @dev Returns request data associated with request index
    /// @param _reqIndex Request index to query for data
    function getRequestByIndex(uint256 _reqIndex) internal view returns (Request memory) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.requests[_reqIndex];
    }

    /// @dev Returns number of requests registered so far 
    function getRequestsLength() internal view returns (uint256) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.requests.length;
    }

    /// @dev Returns true if contract is paused for certain operations
    function paused() internal view returns (bool) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.paused;
    }

    /// @dev Initializes payment token address
    /// @notice This function can be called only once, throws error if the address is already set
    /// @notice Restricted access function, should be called by owner only
    /// @param _token Address of payment token
    function initializePaymentToken(address _token) internal {
        LibDiamond.enforceIsContractOwner();
        VaultState storage vaultState = diamondStorage();
        if(vaultState.paymentToken != address(0)) {
            revert PaymentTokenIsInitialized(vaultState.paymentToken);
        }
        vaultState.paymentToken = _token;
    }

    /// @dev Sets minimum deposit limit
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _limit New limit to set
    function setMinDepositLimit(uint256 _limit) internal {
        AccessControlLib.enforceIsConfigManager();
        VaultState storage vaultState = diamondStorage();
        vaultState.minDepositLimit = _limit;
    }

    /// @dev Pauses the contract to restrict certain functions
    /// @notice Restricted access function, should be called by owner only
    function pause() internal whenNotPaused {
        LibDiamond.enforceIsContractOwner();
        VaultState storage vaultState = diamondStorage();
        vaultState.paused = true;
    }

    /// @dev Unpauses the contract to allow certain functions
    /// @notice Restricted access function, should be called by owner only
    function unpause() internal whenPaused {
        LibDiamond.enforceIsContractOwner();
        VaultState storage vaultState = diamondStorage();
        vaultState.paused = false;
    }

    /// @dev Allows lender to deposit whitelisted tokens into vault
    /// @notice Throws error if lender is not KYB verified
    /// @param _roleId LenderId of given user
    /// @param _token Address of stable coin
    /// @param _amount Amount of payment token to deposit
    function deposit(string calldata _roleId, address _token, uint256 _amount) internal whenNotPaused returns (string memory) {
        LenderLib.enforceIsLender(_roleId);
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        VaultState storage vaultState = diamondStorage();
        uint256 _minAmount = (VaultLib.getMinDepositLimit() * (10 ** IERC20Metadata(_token).decimals())) / 1000000;
        if(_amount == 0 || _amount < _minAmount) {
            revert InvalidAmount(_amount);
        }
        if(!StableCoinLib.isWhitelistedToken(_token)) {
            revert InvalidPoolToken(_token);
        }
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        vaultState.isVaultCall = true;
        string memory _paymentId = PaymentLib.addPayment(_roleId, new string(0), PaymentLib.PaymentType.DEPOSIT, msg.sender, address(this), _amount);
        LenderLib.addPaymentId(_roleId, _paymentId);
        if(_token == vaultState.paymentToken) {
            vaultState.vaultBalance[_roleId] += _amount;
        } else {
            StableCoinLib.increaseBalance(_roleId, _token, _amount);
            StableCoinLib.addPaymentStableCoin(_paymentId, _token);
        }
        vaultState.isVaultCall = false;
        return _paymentId;
    }

    /// @dev Allows lender to invest into given pool
    /// @param _roleId LenderId of given user
    /// @param _poolId PoolId of the credit pool to which user wants to invest in
    /// @param _amount Amount of payment token to invest 
    function invest(string calldata _roleId, string calldata _poolId, uint256 _amount) internal whenNotPaused {
        LenderLib.enforceIsLender(_roleId);
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        CreditPoolLib.enforceIsActivePool(_poolId);
        CreditPoolLib.enforcePoolIsNotExpired(_poolId);
        VaultState storage vaultState = diamondStorage();
        uint256 _balance = getTokenBalance(_roleId, StableCoinLib.getPoolToken(_poolId));
        if(
            _amount == 0 ||
            _amount > _balance ||
            _amount + vaultState.borrowedAmount[_poolId] > CreditPoolLib.getCreditPoolBorrowingAmount(_poolId)
        ) {
            revert InvalidAmount(_amount);
        }
        if(vaultState.pendingRequest[_roleId].isPending) {
            revert PendingRequestExist(_roleId);
        }
        vaultState.isVaultCall = true;
        string memory _paymentId = PaymentLib.addPayment(
            _roleId,
            _poolId,
            PaymentLib.PaymentType.INVESTMENT,
            msg.sender,
            address(this),
            _amount
        );
        LenderLib.addPaymentId(_roleId, _paymentId);
        CreditPoolLib.addPaymentId(_poolId, _paymentId);
        CreditPoolLib.addLenderId(_poolId, _roleId);
        if(StableCoinLib.getPoolToken(_poolId) == vaultState.paymentToken) {
            vaultState.vaultBalance[_roleId] -= _amount;
        } else {
            StableCoinLib.decreaseBalance(_roleId, StableCoinLib.getPoolToken(_poolId), _amount);
        }
        vaultState.isVaultCall = false;
        vaultState.vaultBalance[_poolId] += _amount;
        vaultState.borrowedAmount[_poolId] += _amount;
    }

    /// @dev Distributes pool payment to lender who invested into the pool
    /// @notice Ristricted access function, should be called by distribute facet only 
    /// @param _roleId LenderId of user to distribute
    /// @param _poolId PoolId of credit pool from which payment is being distributed
    /// @param _paymentInfo Payment details with breakdown that is being distributed
    function distribute(
        string calldata _roleId,
        string calldata _poolId,
        PaymentInfo[] calldata _paymentInfo
    ) internal whenNotPaused {
        DistributeLib.enforceIsDistribute();
        VaultState storage vaultState = diamondStorage();
        LenderLib.enforceIsLender(_roleId);
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        CreditPoolLib.enforceIsLenderBoundWithPool(_roleId, _poolId);
        uint256 _amount;
        vaultState.isVaultCall = true;
        for(uint i = 0; i < _paymentInfo.length; i++) {
            if(_paymentInfo[i].amount == 0) revert InvalidAmount(_paymentInfo[i].amount);
            if(
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.INVESTMENT ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.DEPOSIT ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.WITHDRAW ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.FEE
            ) {
                revert InvalidPaymentType(_paymentInfo[i].paymentType);
            }
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                _poolId,
                _paymentInfo[i].paymentType,
                address(this),
                msg.sender,
                _paymentInfo[i].amount
            );
            LenderLib.addPaymentId(_roleId, _paymentId);
            CreditPoolLib.addPaymentId(_poolId, _paymentId);
            if(_paymentInfo[i].paymentType == PaymentLib.PaymentType.EXIT) {
                CreditPoolLib.removeLenderId(_poolId, _roleId);
                emit Exit(_roleId, _poolId, _paymentInfo[i].amount);
            }
            _amount += _paymentInfo[i].amount;
        }
        if(_amount > StableCoinLib.getPaidBalance(_poolId)) revert InvalidAmount(_amount);
        StableCoinLib.decreasePaidBalance(_poolId, _amount);
        if(StableCoinLib.getPoolToken(_poolId) == vaultState.paymentToken) {
            vaultState.vaultBalance[_roleId] += _amount;
        } else {
            StableCoinLib.increaseBalance(_roleId, StableCoinLib.getPoolToken(_poolId), _amount);
        }
        vaultState.isVaultCall = false;
    }

    /// @dev Withdraws given amount from vault if eligible, registers a request otherwise
    /// @param _roleId LenderId of given user
    /// @param _token Address of whitelisted stable coin
    /// @param _amount Amount of stable coin to withdraw from vault
    function withdrawRequest(string calldata _roleId, address _token, uint256 _amount) internal whenNotPaused returns(bool _isWithdrawn) {
        LenderLib.enforceIsLender(_roleId);
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        VaultState storage vaultState = diamondStorage();
        uint256 _balance = getTokenBalance(_roleId, _token);
        if(_amount == 0 || _amount > _balance) {
            revert InvalidAmount(_amount);
        }
        vaultState.isVaultCall = true;
        uint256 _threshold = (StableCoinLib.getLenderThreshold() * (10 ** IERC20Metadata(_token).decimals())) / 1000000;
        if(
            (_amount <= _threshold) && 
            (block.timestamp > StableCoinLib.getLenderCoolingTime() + StableCoinLib.getLastWithdrawalTimeStamp(_roleId))
        ) {
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                new string(0),
                PaymentLib.PaymentType.WITHDRAW,
                address(this),
                msg.sender,
                _amount
            );
            LenderLib.addPaymentId(_roleId, _paymentId);
            if(_token == vaultState.paymentToken) {
                vaultState.vaultBalance[_roleId] -= _amount;
            } else {
                StableCoinLib.decreaseBalance(_roleId, _token, _amount);
                StableCoinLib.addPaymentStableCoin(_paymentId, _token);
            }
            StableCoinLib.updateLastWithdrawalTimeStamp(_roleId, uint64(block.timestamp));
            IERC20(_token).safeTransfer(msg.sender, _amount);
            _isWithdrawn = true;    
        } else {
            if(vaultState.pendingRequest[_roleId].isPending) {
                revert PendingRequestExist(_roleId);
            }
            uint256 _reqIndex = vaultState.requests.length;
            vaultState.requests.push(Request(_roleId, new string(0), msg.sender, RequestType.WITHDRAW, _amount));
            StableCoinLib.addRequestedToken(_roleId, _token);
            vaultState.pendingRequest[_roleId] = RequestStatus(true, _reqIndex);
        }
        vaultState.isVaultCall = false;
    }

    /// @dev Processes withdraw request of lender
    /// @notice Restricted access function, should be called by an address with withdraw manager role
    /// @param _reqIndex Request index to process
    /// @param _isApproved True / False to accept / reject request
    function processWithdrawRequest(uint256 _reqIndex, bool _isApproved) internal {
        AccessControlLib.enforceIsWithdrawManager();
        VaultState storage vaultState = diamondStorage();
        if(vaultState.requests[_reqIndex].requestType != RequestType.WITHDRAW) {
            revert InvalidRequestIndex(_reqIndex);
        }
        Request memory _request = vaultState.requests[_reqIndex];
        if(_isApproved) {
            LenderLib.enforceIsLenderKYBVerified(_request.roleId);
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _request.roleId,
                _request.poolId,
                PaymentLib.PaymentType.WITHDRAW,
                address(this),
                _request.wallet,
                _request.amount
            );
            LenderLib.addPaymentId(_request.roleId, _paymentId);
            address _token = StableCoinLib.getRequestedToken(_request.roleId);
            if(_token == vaultState.paymentToken) {
                vaultState.vaultBalance[_request.roleId] -= _request.amount;
            } else {
                StableCoinLib.decreaseBalance(_request.roleId, _token, _request.amount);
                StableCoinLib.addPaymentStableCoin(_paymentId, _token);
            }
            vaultState.isVaultCall = false;
            IERC20(_token).safeTransfer(_request.wallet, _request.amount);
        }
        uint256 _lastReqIndex = vaultState.requests.length - 1;
        if(_reqIndex != _lastReqIndex) {
            vaultState.requests[_reqIndex] = vaultState.requests[_lastReqIndex];
            vaultState.pendingRequest[vaultState.requests[_lastReqIndex].roleId].requestIndex = _reqIndex;
        }
        vaultState.requests.pop();
        delete vaultState.pendingRequest[_request.roleId];
    }

    /// @dev Withdraws given amount from pool if eligible, registers a request otherwise
    /// @param _roleId PoolManagerId of given user
    /// @param _poolId PoolId of credit pool from which pool manager wants to withdraw funds
    /// @param _amount Amount of payment token to withdraw from given pool
    function receiveInvestmentRequest(string calldata _roleId, string calldata _poolId, uint256 _amount) internal whenNotPaused returns(bool _isWithdrawn) {
        CreditPoolLib.enforceIsPoolManagerBoundWithPool(_roleId, _poolId);
        PoolManagerLib.enforceIsPoolManager(_roleId);
        PoolManagerLib.enforceIsPoolManagerKYBVerified(_roleId);
        CreditPoolLib.enforceIsActivePool(_poolId);
        VaultState storage vaultState = diamondStorage();
        if(_amount == 0 || _amount > vaultState.vaultBalance[_poolId]) {
            revert InvalidAmount(_amount);
        }
        vaultState.isVaultCall = true;
        uint256 _threshold = (StableCoinLib.getPoolThreshold() * (10 ** IERC20Metadata(StableCoinLib.getPoolToken(_poolId)).decimals())) / 1000000;
        if(
            (_amount <= _threshold) && 
            (block.timestamp > StableCoinLib.getPoolCoolingTime() + StableCoinLib.getLastWithdrawalTimeStamp(_poolId))
        ) {
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                _poolId,
                PaymentLib.PaymentType.WITHDRAW,
                address(this),
                msg.sender,
                _amount
            );
            PoolManagerLib.addPaymentId(_roleId, _paymentId);
            CreditPoolLib.addPaymentId(_poolId, _paymentId);
            vaultState.vaultBalance[_poolId] -= _amount;
            address _token = StableCoinLib.getPoolToken(_poolId);
            StableCoinLib.updateLastWithdrawalTimeStamp(_poolId, uint64(block.timestamp));
            IERC20(_token).safeTransfer(msg.sender, _amount);
            _isWithdrawn = true;
        } else {
            if(vaultState.pendingRequest[_roleId].isPending) {
                revert PendingRequestExist(_roleId);
            }
            uint256 _reqIndex = vaultState.requests.length;
            vaultState.requests.push(Request(_roleId, _poolId, msg.sender, RequestType.RECEIVE, _amount));
            vaultState.pendingRequest[_roleId] = RequestStatus(true, _reqIndex);
        }
        vaultState.isVaultCall = false;
    }

    /// @dev Processes withdraw request of pool manager
    /// @notice Restricted access function, should be called by an address with withdraw manager role
    /// @param _reqIndex Request index to process
    /// @param _isApproved True / False to accept / reject request
    function processReceiveInvestmentRequest(uint256 _reqIndex, bool _isApproved) internal {
        AccessControlLib.enforceIsWithdrawManager();
        VaultState storage vaultState = diamondStorage();
        if(vaultState.requests[_reqIndex].requestType != RequestType.RECEIVE) {
            revert InvalidRequestIndex(_reqIndex);
        }
        Request memory _request = vaultState.requests[_reqIndex];
        if(_isApproved) {
            PoolManagerLib.enforceIsPoolManagerKYBVerified(_request.roleId);
            CreditPoolLib.enforceIsActivePool(_request.poolId);
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _request.roleId,
                _request.poolId,
                PaymentLib.PaymentType.WITHDRAW,
                address(this),
                _request.wallet,
                _request.amount
            );
            PoolManagerLib.addPaymentId(_request.roleId, _paymentId);
            CreditPoolLib.addPaymentId(_request.poolId, _paymentId);
            vaultState.isVaultCall = false;
            vaultState.vaultBalance[_request.poolId] -= _request.amount;
            address _token = StableCoinLib.getPoolToken(_request.poolId);
            IERC20(_token).safeTransfer(_request.wallet, _request.amount);
        }
        uint256 _lastReqIndex = vaultState.requests.length - 1;
        if(_reqIndex != _lastReqIndex) {
            vaultState.requests[_reqIndex] = vaultState.requests[_lastReqIndex];
            vaultState.pendingRequest[vaultState.requests[_lastReqIndex].roleId].requestIndex = _reqIndex;
        }
        vaultState.requests.pop();
        delete vaultState.pendingRequest[_request.roleId];
    }

    /// @dev Allows pool manager to pay payment tokens to credit pool
    /// @param _roleId PoolManagerId of given user
    /// @param _poolId PoolId of credit pool to pay for
    /// @param _paymentInfo Payment details with breakdown that is being paid to given pool
    function pay(
        string calldata _roleId,
        string calldata _poolId,
        PaymentInfo[] calldata _paymentInfo
    ) internal whenNotPaused {
        CreditPoolLib.enforceIsPoolManagerBoundWithPool(_roleId, _poolId);
        PoolManagerLib.enforceIsPoolManager(_roleId);
        PoolManagerLib.enforceIsPoolManagerKYBVerified(_roleId);
        CreditPoolLib.enforceIsActivePool(_poolId);
        VaultState storage vaultState = diamondStorage();
        uint256 _amount;
        vaultState.isVaultCall = true;
        address _token = StableCoinLib.getPoolToken(_poolId);
        for(uint i = 0; i < _paymentInfo.length; i++) {
            if(_paymentInfo[i].amount == 0) revert InvalidAmount(_paymentInfo[i].amount);
            if(
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.INVESTMENT ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.DEPOSIT ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.WITHDRAW
            ) {
                revert InvalidPaymentType(_paymentInfo[i].paymentType);
            }
            string memory _paymentId;
            if(_paymentInfo[i].paymentType == PaymentLib.PaymentType.FEE) {
                _paymentId = PaymentLib.addPayment(_roleId, _poolId, PaymentLib.PaymentType.FEE, msg.sender, LibDiamond.contractOwner(), _paymentInfo[i].amount);
                IERC20(_token).safeTransfer(LibDiamond.contractOwner(), _paymentInfo[i].amount);
                emit Fee(_poolId, _paymentInfo[i].amount);
            } else {
                _paymentId = PaymentLib.addPayment(_roleId, _poolId, _paymentInfo[i].paymentType, msg.sender, address(this), _paymentInfo[i].amount);
                _amount += _paymentInfo[i].amount;
            }
            PoolManagerLib.addPaymentId(_roleId, _paymentId);
            CreditPoolLib.addPaymentId(_poolId, _paymentId);
        }
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        StableCoinLib.increasePaidBalance(_poolId, _amount);
        vaultState.isVaultCall = false;
    }

    /// @dev Adjusts vault balance of lender / paid balance of pool case of correction
    /// @notice Restricted access function, should be called by an owner only
    /// @param _id LenderId / PoolId of a vault account
    /// @param _amount Amount of payment token to adjust
    /// @param _account Account type of given id
    /// @param _type Type of adjustment (deposit / withdraw) 
    function adjustVaultBalance(
        string calldata _id,
        uint256 _amount,
        AccountType _account,
        PaymentLib.PaymentType _type
    ) internal {
        LibDiamond.enforceIsContractOwner();
        VaultState storage vaultState = diamondStorage();
        if(_amount == 0) revert InvalidAmount(_amount);
        string memory _roleId = _account == AccountType.LENDER ? _id : new string(0);
        string memory _poolId = _account == AccountType.POOL ? _id : new string(0);
        if(_type == PaymentLib.PaymentType.DEPOSIT) {
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                _poolId,
                _type,
                msg.sender,
                address(this),
                _amount
            );
            if (_account == AccountType.LENDER) {
                LenderLib.addPaymentId(_id, _paymentId);
                vaultState.vaultBalance[_id] += _amount;
            } else {
                CreditPoolLib.addPaymentId(_id, _paymentId);
                StableCoinLib.increasePaidBalance(_id, _amount);
            } 
            vaultState.isVaultCall = false;
        }
        if(_type == PaymentLib.PaymentType.WITHDRAW) {
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                _poolId,
                _type,
                address(this),
                msg.sender,
                _amount
            );
            if (_account == AccountType.LENDER) {
                LenderLib.addPaymentId(_id, _paymentId);
                vaultState.vaultBalance[_id] -= _amount;
            } else {
                CreditPoolLib.addPaymentId(_id, _paymentId);
                StableCoinLib.decreasePaidBalance(_id, _amount);
            }
            vaultState.isVaultCall = false;
        }
    }

    /// @dev Adjusts balance of lender account in case of correction
    /// @notice Restricted access function, should be called by an owner only
    /// @param _roleId LenderId of a vault account
    /// @param _amount Amount of payment token to adjust
    /// @param _token Address of stable coin
    /// @param _type Type of adjustment (deposit / withdraw) 
    function adjustStableCoinBalance(
        string calldata _roleId,
        uint256 _amount,
        address _token,
        PaymentLib.PaymentType _type
    ) internal {
        LibDiamond.enforceIsContractOwner();
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        VaultState storage vaultState = diamondStorage();
        if(_amount == 0) revert InvalidAmount(_amount);
        if(!StableCoinLib.isWhitelistedToken(_token)) {
            revert InvalidPoolToken(_token);
        }
        if(_token == vaultState.paymentToken) {
            revert InvalidFunction();
        }
        if(_type == PaymentLib.PaymentType.DEPOSIT) {
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                new string(0),
                _type,
                msg.sender,
                address(this),
                _amount
            );
            LenderLib.addPaymentId(_roleId, _paymentId);
            StableCoinLib.increaseBalance(_roleId, _token, _amount);
            StableCoinLib.addPaymentStableCoin(_paymentId, _token);
            vaultState.isVaultCall = false;
        }
        if(_type == PaymentLib.PaymentType.WITHDRAW) {
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                new string(0),
                _type,
                address(this),
                msg.sender,
                _amount
            );
            LenderLib.addPaymentId(_roleId, _paymentId);
            StableCoinLib.decreaseBalance(_roleId, _token, _amount);
            StableCoinLib.addPaymentStableCoin(_paymentId, _token);
            vaultState.isVaultCall = false;
        }
    }

    /// @dev Withdraws ERC20 token from contract in case of emergency
    /// @notice Restricted access function, should be called by an owner only
    /// @param _token Address of ERC20 token to withdraw
    /// @param _to Address of receiver
    /// @param _amount Amount of ERC20 token to withdraw from contract 
    function emergencyWithdraw(address _token, address _to, uint256 _amount) internal {
        LibDiamond.enforceIsContractOwner();
        if(_amount == 0) revert InvalidAmount(_amount);
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @dev Throws error if called by other than vault library
    function enforceIsVault() internal view {
        VaultState storage vaultState = diamondStorage();
        if(!vaultState.isVaultCall) {
            revert NotVaultCall();
        }
    }

    /// @dev Throws error if contract is not paused
    function requireNotPaused() internal view {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /// @dev Throws error if contract is paused
    function requirePaused() internal view {
        if (!paused()) {
            revert ExpectedPause();
        }
    }    
}

/// @title Vault facet
contract VaultFacet {
    event Adjust(string indexed id, uint256 amount, VaultLib.AccountType account, PaymentLib.PaymentType paymentType);
    event Deposit(string indexed roleId, uint256 amount);
    event DepositStableCoin(string indexed roleId, address token, uint256 amount);
    event Invest(string indexed roleId, string poolId, uint256 amount);
    event Withdraw(string indexed roleId, uint256 amount);
    event WithdrawStableCoin(string indexed roleId, address token, uint256 amount);
    event WithdrawRequest(string roleId, address token, uint256 amount);
    event Receive(string indexed roleId, string poolId, uint256 amount);
    event ReceiveRequest(string roleId, string poolId, uint256 amount);
    event Pay(string indexed roleId, string poolId, VaultLib.PaymentInfo[] paymentInfo);
    event Paused(address account);
    event Unpaused(address account);
    
    /// @dev Returns balance of given vault account
    /// @param _roleId RoleId associated with given vault account  
    function getVaultBalance(string calldata _roleId) external view returns (uint256) {
        return VaultLib.getVaultBalance(_roleId);
    }

    /// @dev Returns stable coin balance of given vault account
    /// @param _roleId RoleId associated with given vault account
    /// @param _token Address of stable coin  
    function getTokenBalance(string calldata _roleId, address _token) external view returns (uint256) {
        return VaultLib.getTokenBalance(_roleId, _token);
    }

    /// @dev Returns amount already borrowed by given pool
    /// @param _poolId PoolId associated with given pool
    function getBorrowedAmount(string calldata _poolId) external view returns (uint256) {
        return VaultLib.getBorrowedAmount(_poolId);
    }

    /// @dev Returns minimum amount that needs to be deposited 
    function getMinDepositLimit() external view returns (uint256) {
        return VaultLib.getMinDepositLimit();
    }

    /// @dev Returns contract address of payment token
    function getPaymentToken() external view returns (address) {
        return VaultLib.getPaymentToken();
    }

    /// @dev Returns request status of given user
    /// @param _roleId LenderId / PoolManagerId of given user
    function getRequestStatus(string calldata _roleId) external view returns (VaultLib.RequestStatus memory) {
        return VaultLib.getRequestStatus(_roleId);
    }

    /// @dev Returns request list
    function getRequests() external view returns (VaultLib.Request[] memory) {
        return VaultLib.getRequests();
    }

    /// @dev Returns request data associated with request index
    /// @param _reqIndex Request index to query for data
    function getRequestByIndex(uint256 _reqIndex) external view returns (VaultLib.Request memory) {
        return VaultLib.getRequestByIndex(_reqIndex);
    }

    /// @dev Returns number of requests registered so far 
    function getRequestsLength() external view returns (uint256) {
        return VaultLib.getRequestsLength();
    }

    /// @dev Returns true if contract is paused for certain operations
    function paused() external view returns (bool) {
        return VaultLib.paused();
    }

    /// @dev Initializes payment token address
    /// @notice This function can be called only once, throws error if the address is already set
    /// @notice Restricted access function, should be called by owner only
    /// @param _token Address of payment token
    function initializePaymentToken(address _token) external {
        return VaultLib.initializePaymentToken(_token);
    }

    /// @dev Sets minimum deposit limit
    /// @notice Restricted access function, should be called by an address with config manager role
    /// @param _limit New limit to set
    function setMinDepositLimit(uint256 _limit) external {
        return VaultLib.setMinDepositLimit(_limit);
    }

    /// @dev Adjusts vault balance of lender / paid balance of pool case of correction
    /// @notice Restricted access function, should be called by an owner only
    /// @param _id LenderId / PoolId of a vault account
    /// @param _amount Amount of payment token to adjust
    /// @param _account Account type of given id
    /// @param _type Type of adjustment (deposit / withdraw) 
    function adjustVaultBalance(
        string calldata _id,
        uint256 _amount,
        VaultLib.AccountType _account,
        PaymentLib.PaymentType _type
    ) external {
        VaultLib.adjustVaultBalance(_id, _amount, _account, _type);
        emit Adjust(_id, _amount, _account, _type);
    }

    /// @dev Pauses the contract to restrict certain functions
    /// @notice Restricted access function, should be called by owner only
    function pause() external {
        VaultLib.pause();
        emit Paused(msg.sender);
    }

    /// @dev Unpauses the contract to allow certain functions
    /// @notice Restricted access function, should be called by owner only
    function unpause() external {
        VaultLib.unpause();
        emit Unpaused(msg.sender);
    }

    /// @dev Allows lender to deposit whitelisted tokens into vault
    /// @notice Throws error if lender is not KYB verified
    /// @param _roleId LenderId of given user
    /// @param _token Address of stable coin
    /// @param _amount Amount of payment token to deposit
    function deposit(string calldata _roleId, address _token, uint256 _amount) external returns (string memory) {
        if(_token == VaultLib.getPaymentToken()) {
            emit Deposit(_roleId, _amount);
        } else {
            emit DepositStableCoin(_roleId, _token, _amount);
        }
        return VaultLib.deposit(_roleId, _token, _amount);
    }

    /// @dev Allows lender to invest into given pool
    /// @param _roleId LenderId of given user
    /// @param _poolId PoolId of the credit pool to which user wants to invest in
    /// @param _amount Amount of payment token to invest 
    function invest(string calldata _roleId, string calldata _poolId, uint256 _amount) external {
        VaultLib.invest(_roleId, _poolId, _amount);
        emit Invest(_roleId, _poolId, _amount);
    }

    /// @dev Withdraws given amount from vault if eligible, registers a request otherwise
    /// @param _roleId LenderId of given user
    /// @param _token Address of whitelisted stable coin
    /// @param _amount Amount of stable coin to withdraw from vault
    function withdrawRequest(string calldata _roleId, address _token, uint256 _amount) external returns(bool _isWithdrawn) {
        _isWithdrawn = VaultLib.withdrawRequest(_roleId, _token, _amount);
        if(_isWithdrawn) {
            if(_token == VaultLib.getPaymentToken()) {
                emit Withdraw(_roleId, _amount);
            } else {
                emit WithdrawStableCoin(_roleId, _token, _amount);
            }
        } else {
            emit WithdrawRequest(_roleId, _token, _amount);
        }
    }

    /// @dev Processes withdraw request of lender
    /// @notice Restricted access function, should be called by an address with withdraw manager role
    /// @param _reqIndex Request index to process
    /// @param _isApproved True / False to accept / reject request
    function processWithdrawRequest(uint256 _reqIndex, bool _isApproved) external {
        if(_isApproved) {
            VaultLib.Request memory _request = VaultLib.getRequestByIndex(_reqIndex);
            address _token = StableCoinLib.getRequestedToken(_request.roleId);
            if(_token == VaultLib.getPaymentToken()) {
                emit Withdraw(_request.roleId, _request.amount);
            } else {
                emit WithdrawStableCoin(_request.roleId, _token, _request.amount);
            }
        }
        VaultLib.processWithdrawRequest(_reqIndex, _isApproved);
    }

    /// @dev Withdraws given amount from pool if eligible, registers a request otherwise
    /// @param _roleId PoolManagerId of given user
    /// @param _poolId PoolId of credit pool from which pool manager wants to withdraw funds
    /// @param _amount Amount of payment token to withdraw from given pool
    function receiveInvestmentRequest(string calldata _roleId, string calldata _poolId, uint256 _amount) external returns(bool _isWithdrawn) {
        _isWithdrawn = VaultLib.receiveInvestmentRequest(_roleId, _poolId, _amount);
        if(_isWithdrawn) {
            emit Receive(_roleId, _poolId, _amount);
        } else {
            emit ReceiveRequest(_roleId, _poolId, _amount);
        }
    }

    /// @dev Processes withdraw request of pool manager
    /// @notice Restricted access function, should be called by an address with withdraw manager role
    /// @param _reqIndex Request index to process
    /// @param _isApproved True / False to accept / reject request
    function processReceiveInvestmentRequest(uint256 _reqIndex, bool _isApproved) external {
        if(_isApproved) {
            VaultLib.Request memory _request = VaultLib.getRequestByIndex(_reqIndex);
            emit Receive(_request.roleId, _request.poolId, _request.amount);
        }
        VaultLib.processReceiveInvestmentRequest(_reqIndex, _isApproved);
    }

    /// @dev Allows pool manager to pay payment tokens to credit pool
    /// @param _roleId PoolManagerId of given user
    /// @param _poolId PoolId of credit pool to pay for
    /// @param _paymentInfo Payment details with breakdown that is being paid to given pool
    function pay(
        string calldata _roleId,
        string calldata _poolId,
        VaultLib.PaymentInfo[] calldata _paymentInfo
    ) external {
        VaultLib.pay(_roleId, _poolId, _paymentInfo);
        emit Pay(_roleId, _poolId, _paymentInfo);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamond } from "./IDiamond.sol";

interface IDiamondCut is IDiamond {    

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamond } from "../interfaces/IDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if(msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }        
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if(functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        if(_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);                
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if(oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }            
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        if(_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if(oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if(oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if(oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if(_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }        
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }
            
            
            // can't remove immutable functions -- functions defined directly in the diamond
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }        
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if(contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }        
    }
}