// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


interface IL2Gateway {
    /// @notice Estimate the fee to call send withdraw message
    function estimateWithdrawETHFee(address _owner, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) external view returns (uint256 nativeFee);

    /// @notice Withdraw ETH to L1 for owner
    /// @param _owner The address received eth on L1
    /// @param _amount The eth amount received
    /// @param _accountIdOfNonce Account that supply nonce, may be different from accountId
    /// @param _subAccountIdOfNonce SubAccount that supply nonce
    /// @param _nonce SubAccount nonce, used to produce unique accept info
    /// @param _fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
    function withdrawETH(address _owner, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) external payable;

    /// @notice Estimate the fee to call send withdraw message
    function estimateWithdrawERC20Fee(address _owner, address _token, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) external view returns (uint256 nativeFee);

    /// @notice Withdraw ERC20 token to L1 for owner
    /// @dev gateway need to pay fee to message service
    /// @param _owner The address received token on L1
    /// @param _token The token address on L2
    /// @param _amount The token amount received
    /// @param _accountIdOfNonce Account that supply nonce, may be different from accountId
    /// @param _subAccountIdOfNonce SubAccount that supply nonce
    /// @param _nonce SubAccount nonce, used to produce unique accept info
    /// @param _fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
    function withdrawERC20(address _owner, address _token, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) external payable;

    /// @notice Return the fee of sending sync hash to ethereum
    /// @param syncHash the sync hash
    function estimateSendSlaverSyncHashFee(bytes32 syncHash) external view returns (uint nativeFee);

    /// @notice Send sync hash message to ethereum
    /// @param syncHash the sync hash
    function sendSlaverSyncHash(bytes32 syncHash) external payable;

    /// @notice Return the fee of sending sync hash to ethereum
    /// @param blockNumber the block number
    /// @param syncHash the sync hash
    function estimateSendMasterSyncHashFee(uint32 blockNumber, bytes32 syncHash) external view returns (uint nativeFee);

    /// @notice Send sync hash message to ethereum
    /// @param blockNumber the block number
    /// @param syncHash the sync hash
    function sendMasterSyncHash(uint32 blockNumber, bytes32 syncHash) external payable;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Sync service for sending cross chain message
/// @author zk.link
interface ISyncService {
    /// @notice Return the fee of sending sync hash to master chain
    /// @param syncHash the sync hash
    function estimateSendSyncHashFee(bytes32 syncHash) external view returns (uint nativeFee);

    /// @notice Send sync hash message to master chain
    /// @param syncHash the sync hash
    function sendSyncHash(bytes32 syncHash) external payable;

    /// @notice Estimate the fee of sending confirm block message to slaver chain
    /// @param destZkLinkChainId the destination chain id defined by zkLink
    /// @param blockNumber the height of stored block
    function estimateConfirmBlockFee(uint8 destZkLinkChainId, uint32 blockNumber) external view returns (uint nativeFee);

    /// @notice Send block confirmation message to slaver chains
    /// @param destZkLinkChainId the destination chain id defined by zkLink
    /// @param blockNumber the block height
    function confirmBlock(uint8 destZkLinkChainId, uint32 blockNumber) external payable;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Verifier interface contract
/// @author zk.link
interface IVerifier {
    function verifyAggregatedBlockProof(uint256[] memory _recursiveInput, uint256[] memory _proof, uint8[] memory _vkIndexes, uint256[] memory _individualVksInputs, uint256[16] memory _subProofsLimbs) external returns (bool);

    function verifyExitProof(bytes32 _rootHash, uint8 _chainId, uint32 _accountId, uint8 _subAccountId, bytes32 _owner, uint16 _tokenId, uint16 _srcTokenId, uint128 _amount, uint256[] calldata _proof) external returns (bool);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./zksync/Operations.sol";
import "./zksync/Config.sol";
import "./interfaces/IVerifier.sol";
import "./interfaces/ISyncService.sol";
import "./interfaces/IL2Gateway.sol";
import "./zksync/SafeCast.sol";
import "./ZkLinkAcceptor.sol";

/// @title ZkLink storage contract
/// @dev Be carefully to change the order of variables
/// @author zk.link
contract Storage is ZkLinkAcceptor, Config {
    /// @dev Used to safely call `delegatecall`, immutable state variables don't occupy storage slot
    address internal immutable self = address(this);

    // verifier(20 bytes) + totalBlocksExecuted(4 bytes) + firstPriorityRequestId(8 bytes) stored in the same slot

    /// @notice Verifier contract. Used to verify block proof and exit proof
    IVerifier public verifier;

    /// @notice Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
    uint32 public totalBlocksExecuted;

    /// @notice First open priority request id
    uint64 public firstPriorityRequestId;

    // networkGovernor(20 bytes) + totalBlocksCommitted(4 bytes) + totalOpenPriorityRequests(8 bytes) stored in the same slot

    /// @notice The the owner of whole system
    address public networkGovernor;

    /// @notice Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
    uint32 public totalBlocksCommitted;

    /// @notice Total number of requests
    uint64 public totalOpenPriorityRequests;

    // gateway(20 bytes) + totalBlocksProven(4 bytes) + totalCommittedPriorityRequests(8 bytes) stored in the same slot

    /// @notice The gateway is used for communicating with L1
    /// @dev The gateway will not be set if local chain is a L1
    IL2Gateway public gateway;

    /// @notice Total blocks proven.
    uint32 public totalBlocksProven;

    /// @notice Total number of committed requests.
    /// @dev Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
    uint64 public totalCommittedPriorityRequests;

    // totalBlocksSynchronized(4 bytes) + exodusMode(1 bytes) stored in the same slot

    /// @dev Latest synchronized block height
    uint32 public totalBlocksSynchronized;

    /// @notice Flag indicates that exodus (mass exit) mode is triggered
    /// @notice Once it was raised, it can not be cleared again, and all users must exit
    bool public exodusMode;

    /// @dev Root-chain balances (per owner and token id) to withdraw
    /// @dev the amount of pending balance need to recovery decimals when withdraw
    /// @dev The struct of this map is (owner => tokenId => balance)
    /// @dev The type of owner is bytes32, when storing evm address, 12 bytes of prefix zero will be appended
    /// @dev for example: 0x000000000000000000000000A1a547358A9Ca8E7b320d7742729e3334Ad96546
    mapping(bytes32 => mapping(uint16 => uint128)) internal pendingBalances;

    /// @dev Store withdraw data hash that need to be relayed to L1 by gateway
    /// @dev The key is the withdraw data hash
    /// @dev The value is a flag to indicating whether withdraw exists
    mapping(bytes32 => bool) public pendingL1Withdraws;

    /// @notice Flag indicates that a user has exited a certain token balance in the exodus mode
    /// @dev The struct of this map is (accountId => subAccountId => withdrawTokenId => deductTokenId => performed)
    /// @dev withdrawTokenId is the token that withdraw to user in L1
    /// @dev deductTokenId is the token that deducted from user in L2
    mapping(uint32 => mapping(uint8 => mapping(uint16 => mapping(uint16 => bool)))) public performedExodus;

    /// @dev Priority Requests mapping (request id - operation)
    /// Contains op type, pubdata and expiration block of unsatisfied requests.
    /// Numbers are in order of requests receiving
    mapping(uint64 => Operations.PriorityOperation) public priorityRequests;

    /// @notice User authenticated fact hashes for some nonce.
    mapping(address => mapping(uint32 => bytes32)) public authFacts;

    /// @dev Timer for authFacts entry reset (address, nonce -> timer).
    /// Used when user wants to reset `authFacts` for some nonce.
    mapping(address => mapping(uint32 => uint256)) public authFactsResetTimer;

    /// @dev Stored hashed StoredBlockInfo for some block number
    mapping(uint32 => bytes32) public storedBlockHashes;

    /// @dev Store sync hash for slaver chains
    /// chainId => syncHash
    mapping(uint8 => bytes32) public synchronizedChains;

    /// @notice A set of permitted validators
    mapping(address => bool) public validators;

    struct RegisteredToken {
        bool registered; // whether token registered to ZkLink or not, default is false
        bool paused; // whether token can deposit to ZkLink or not, default is false
        address tokenAddress; // the token address
        uint8 decimals; // the token decimals of layer one
    }

    /// @notice A map of registered token infos
    mapping(uint16 => RegisteredToken) public tokens;

    /// @notice A map of token address to id, 0 is invalid token id
    mapping(address => uint16) public tokenIds;

    /// @dev Support multiple sync services, for example:
    /// <Linea, zkSync Era> - LayerZero
    /// <Linea, Scroll> - zkBridge
    /// chainId => sync service
    mapping(uint8 => ISyncService) public chainSyncServiceMap;
    mapping(address => bool) public syncServiceMap;

    /// @dev Store withdraw data hash that need to be called
    /// @dev The key is the withdraw data hash
    /// @dev The value is a flag to indicating whether withdraw exists
    mapping(bytes32 => bool) public pendingWithdrawWithCalls;

    /// @notice block stored data
    /// @dev `blockNumber`,`timestamp`,`stateHash`,`commitment` are the same on all chains
    /// `priorityOperations`,`pendingOnchainOperationsHash` is different for each chain
    struct StoredBlockInfo {
        uint32 blockNumber; // Rollup block number
        uint64 priorityOperations; // Number of priority operations processed
        bytes32 pendingOnchainOperationsHash; // Hash of all operations that must be processed after verify
        uint256 timestamp; // Rollup block timestamp, have the same format as Ethereum block constant
        bytes32 stateHash; // Root hash of the rollup state
        bytes32 commitment; // Verified input for the ZkLink circuit
        SyncHash[] syncHashs; // Used for cross chain block verify
    }
    struct SyncHash {
        uint8 chainId;
        bytes32 syncHash;
    }


    /// @notice Checks that current state not is exodus mode
    modifier active() {
        require(!exodusMode, "0");
        _;
    }

    /// @notice Checks that current state is exodus mode
    modifier notActive() {
        require(exodusMode, "1");
        _;
    }

    /// @notice Set logic contract must be called through proxy
    modifier onlyDelegateCall() {
        require(address(this) != self, "2");
        _;
    }

    modifier onlyGovernor {
        require(msg.sender == networkGovernor, "3");
        _;
    }

    /// @notice Check if msg sender is a validator
    modifier onlyValidator() {
        require(validators[msg.sender], "4");
        _;
    }

    /// @notice Check if msg sender is sync service
    modifier onlySyncService() {
        require(syncServiceMap[msg.sender], "6");
        _;
    }

    /// @notice Check if msg sender is gateway
    modifier onlyGateway() {
        require(msg.sender == address(gateway), "7");
        _;
    }

    /// @notice Returns the keccak hash of the ABI-encoded StoredBlockInfo
    function hashStoredBlockInfo(StoredBlockInfo memory _storedBlockInfo) internal pure returns (bytes32) {
        return keccak256(abi.encode(_storedBlockInfo));
    }

    /// @notice Increase pending balance to withdraw
    /// @param _address the pending balance owner
    /// @param _tokenId token id
    /// @param _amount pending amount that need to recovery decimals when withdraw
    function increaseBalanceToWithdraw(bytes32 _address, uint16 _tokenId, uint128 _amount) internal {
        uint128 balance = pendingBalances[_address][_tokenId];
        // overflow should not happen here
        // (2^128 / 10^18 = 3.4 * 10^20) is enough to meet the really token balance of L2 account
        pendingBalances[_address][_tokenId] = balance + _amount;
    }

    /// @notice Extend address to bytes32
    /// @dev for example: extend 0xA1a547358A9Ca8E7b320d7742729e3334Ad96546 and the result is 0x000000000000000000000000a1a547358a9ca8e7b320d7742729e3334ad96546
    function extendAddress(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    /// @dev improve decimals when deposit, for example, user deposit 2 USDC in ui, and the decimals of USDC is 6
    /// the `_amount` params when call contract will be 2 * 10^6
    /// because all token decimals defined in layer two is 18
    /// so the `_amount` in deposit pubdata should be 2 * 10^6 * 10^(18 - 6) = 2 * 10^18
    function improveDecimals(uint128 _amount, uint8 _decimals) internal pure returns (uint128) {
        // overflow is impossible,  `_decimals` has been checked when register token
        return _amount * SafeCast.toUint128(10**(TOKEN_DECIMALS_OF_LAYER2 - _decimals));
    }

    /// @dev recover decimals when withdraw, this is the opposite of improve decimals
    function recoveryDecimals(uint128 _amount, uint8 _decimals) internal pure returns (uint128) {
        // overflow is impossible,  `_decimals` has been checked when register token
        return _amount / SafeCast.toUint128(10**(TOKEN_DECIMALS_OF_LAYER2 - _decimals));
    }

    /// @dev Return withdraw hash with call data
    /// @dev (_accountIdOfNonce, _subAccountIdOfNonce, _nonce) ensures the uniqueness of withdraw hash
    function getWithdrawWithDataHash(address _owner, address _tokenAddress, uint128 _amount, bytes32 _dataHash, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner, _tokenAddress, _amount, _dataHash, _accountIdOfNonce, _subAccountIdOfNonce, _nonce));
    }

    /// @notice Performs a delegatecall to the contract implementation
    /// @dev Fallback function allowing to perform a delegatecall to the given implementation
    /// This function will return whatever the implementation call returns
    function _fallback(address _target) internal {
        require(_target != address(0), "5");
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./zksync/ReentrancyGuard.sol";
import "./Storage.sol";
import "./zksync/Events.sol";
import "./zksync/UpgradeableMaster.sol";
import "./zksync/Utils.sol";

/// @title ZkLink contract
/// @dev Be carefully to use delegate to split contract(when the code size is too big) code to different files
/// see https://docs.openzeppelin.com/upgrades-plugins/1.x/faq#delegatecall-selfdestruct
/// @dev add `nonReentrant` to all user external interfaces to avoid a closed loop reentrant attack
/// @author zk.link
contract ZkLink is ReentrancyGuard, Storage, Events, UpgradeableMaster {
    using SafeERC20 for IERC20;

    enum ChangePubkeyType {ECRECOVER, CREATE2}

    /// @notice Data needed to process onchain operation from block public data.
    /// @notice Onchain operations is operations that need some processing on L1: Deposits, Withdrawals, ChangePubKey.
    /// @param ethWitness Some external data that can be needed for operation processing
    /// @param publicDataOffset Byte offset in public data for onchain operation
    struct OnchainOperationData {
        bytes ethWitness;
        uint32 publicDataOffset;
    }

    /// @notice Data needed to commit new block
    /// @dev `publicData` contain pubdata of all chains when compressed is disabled or only current chain if compressed is enabled
    /// `onchainOperations` contain onchain ops of all chains when compressed is disabled or only current chain if compressed is enabled
    struct CommitBlockInfo {
        bytes32 newStateHash;
        bytes publicData;
        uint256 timestamp;
        OnchainOperationData[] onchainOperations;
        uint32 blockNumber;
    }


    /// @notice Data needed to execute committed and verified block
    /// @param storedBlock the block info that will be executed
    /// @param pendingOnchainOpsPubdata onchain ops(e.g. Withdraw, ForcedExit, FullExit) that will be executed
    struct ExecuteBlockInfo {
        StoredBlockInfo storedBlock;
        bytes[] pendingOnchainOpsPubdata;
    }

    /// @dev The periphery code address which is a runtime constant
    address public immutable periphery;

    constructor(address _periphery) {
        periphery = _periphery;
    }

    // =================Upgrade interface=================

    /// @notice Notice period before activation preparation status of upgrade mode
    function getNoticePeriod() external pure override returns (uint256) {
        return UPGRADE_NOTICE_PERIOD;
    }

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external view override returns (bool) {
        return !exodusMode;
    }

    /// @notice ZkLink contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    /// @dev _verifierAddress The address of Verifier contract
    /// @dev _peripheryAddress The address of ZkLinkPeriphery contract
    /// @dev _networkGovernor The address of system controller
    function initialize(bytes calldata initializationParameters) external onlyDelegateCall {
        initializeReentrancyGuard();

        (address _verifierAddress, address _networkGovernor, bytes32 _stateHash) = abi.decode(initializationParameters, (address, address, bytes32));
        require(_verifierAddress != address(0), "i0");
        require(_networkGovernor != address(0), "i2");

        verifier = IVerifier(_verifierAddress);
        networkGovernor = _networkGovernor;

        // We need initial state hash because it is used in the commitment of the next block
        StoredBlockInfo memory storedBlockZero =
            StoredBlockInfo(0, 0, EMPTY_STRING_KECCAK, 0, _stateHash, bytes32(0), new SyncHash[](0));

        storedBlockHashes[0] = hashStoredBlockInfo(storedBlockZero);
    }


    // =================Delegate call=================

    /// @notice Will run when no functions matches call data
    fallback() external payable {
        _fallback(periphery);
    }

    // =================User interface=================

    /// @notice Deposit ETH to Layer 2 - transfer ether from user into contract, validate it, register deposit
    /// @param _zkLinkAddress The receiver Layer 2 address
    /// @param _subAccountId The receiver sub account
    function depositETH(bytes32 _zkLinkAddress, uint8 _subAccountId) external payable nonReentrant {
        // ETH is not a mapping token in zkLink
        deposit(ETH_ADDRESS, SafeCast.toUint128(msg.value), _zkLinkAddress, _subAccountId, false);
    }

    /// @notice Deposit ERC20 token to Layer 2 - transfer ERC20 tokens from user into contract, validate it, register deposit
    /// @dev it MUST be ok to call other external functions within from this function
    /// when the token(eg. erc777) is not a pure erc20 token
    /// @param _token Token address
    /// @param _amount Token amount
    /// @param _zkLinkAddress The receiver Layer 2 address
    /// @param _subAccountId The receiver sub account
    /// @param _mapping If true and token has a mapping token, user will receive mapping token at L2
    function depositERC20(IERC20 _token, uint104 _amount, bytes32 _zkLinkAddress, uint8 _subAccountId, bool _mapping) external nonReentrant {
        // erc20 token address MUST NOT be ETH_ADDRESS which represent deposit eth
        // it's nearly impossible to create an erc20 token which address is the ETH_ADDRESS
        // add check to avoid this extreme case
        require(address(_token) != ETH_ADDRESS, "e");
        deposit(address(_token), _amount, _zkLinkAddress, _subAccountId, _mapping);
    }

    // =================Validator interface=================

    /// @notice Commit block
    /// @dev 1. Checks onchain operations of all chains, timestamp.
    /// 2. Store block commitments, sync hash
    function commitBlocks(StoredBlockInfo memory _lastCommittedBlockData, CommitBlockInfo[] memory _newBlocksData) external active onlyValidator nonReentrant
    {
        // ===Checks===
        require(_newBlocksData.length > 0, "f0");
        // Check that we commit blocks after last committed block
        require(storedBlockHashes[totalBlocksCommitted] == hashStoredBlockInfo(_lastCommittedBlockData), "f1");

        // ===Effects===
        for (uint32 i = 0; i < _newBlocksData.length; ++i) {
            _lastCommittedBlockData = commitOneBlock(_lastCommittedBlockData, _newBlocksData[i]);

            // forward `totalCommittedPriorityRequests` because it will be reused in the next `commitOneBlock`
            totalCommittedPriorityRequests = totalCommittedPriorityRequests + _lastCommittedBlockData.priorityOperations;
            storedBlockHashes[_lastCommittedBlockData.blockNumber] = hashStoredBlockInfo(_lastCommittedBlockData);
        }
        require(totalCommittedPriorityRequests <= totalOpenPriorityRequests, "f2");

        totalBlocksCommitted = totalBlocksCommitted + SafeCast.toUint32(_newBlocksData.length);
        // log the last new committed block number
        emit BlockCommit(_lastCommittedBlockData.blockNumber);
    }

    /// @dev Process one block commit using previous block StoredBlockInfo,
    /// returns new block StoredBlockInfo
    /// NOTE: Does not change storage (except events, so we can't mark it view)
    function commitOneBlock(StoredBlockInfo memory _previousBlock, CommitBlockInfo memory _newBlock) internal view returns (StoredBlockInfo memory storedNewBlock) {
        require(_newBlock.blockNumber == _previousBlock.blockNumber + 1, "g0");

        // Check timestamp of the new block
        require(_newBlock.timestamp >= _previousBlock.timestamp, "g2");

        // Check onchain operations
        (
            bytes32 pendingOnchainOpsHash,
            uint64 priorityReqCommitted,
            bytes memory onchainOpsOffsetCommitment,
            uint256 slaverChainNum,
            bytes32[] memory onchainOperationPubdataHashs
        ) = collectOnchainOps(_newBlock);

        // Create block commitment for verification proof
        bytes32 commitment = createBlockCommitment(_previousBlock, _newBlock, onchainOpsOffsetCommitment);
        // Create synchronization hash for cross chain block verify
        SyncHash[] memory syncHashs = createSyncHash(_previousBlock.syncHashs, _newBlock, slaverChainNum, onchainOperationPubdataHashs);

        return StoredBlockInfo(
            _newBlock.blockNumber,
            priorityReqCommitted,
            pendingOnchainOpsHash,
            _newBlock.timestamp,
            _newBlock.newStateHash,
            commitment,
            syncHashs
        );
    }

    /// @dev Gets operations packed in bytes array. Unpacks it and stores onchain operations.
    /// Priority operations must be committed in the same order as they are in the priority queue.
    /// NOTE: does not change storage! (only emits events)
    /// processableOperationsHash - hash of the all operations of the current chain that needs to be executed  (Withdraws, ForcedExits, FullExits)
    /// priorityOperationsProcessed - number of priority operations processed of the current chain in this block (Deposits, FullExits)
    /// offsetsCommitment - array where 1 is stored in chunk where onchainOperation begins and other is 0 (used in commitments)
    /// slaverChainNum - the slaver chain num
    /// onchainOperationPubdatas - onchain operation (Deposits, ChangePubKeys, Withdraws, ForcedExits, FullExits) pubdatas group by chain id (used in cross chain block verify)
    function collectOnchainOps(CommitBlockInfo memory _newBlockData) internal view returns (bytes32 processableOperationsHash, uint64 priorityOperationsProcessed, bytes memory offsetsCommitment, uint256 slaverChainNum, bytes32[] memory onchainOperationPubdataHashs) {
        bytes memory pubData = _newBlockData.publicData;
        // pubdata length must be a multiple of CHUNK_BYTES
        require(pubData.length % CHUNK_BYTES == 0, "h0");
        offsetsCommitment = new bytes(pubData.length / CHUNK_BYTES);
        priorityOperationsProcessed = 0;
        (slaverChainNum, onchainOperationPubdataHashs) = initOnchainOperationPubdataHashs();
        processableOperationsHash = EMPTY_STRING_KECCAK;

        // early return to save once slot read
        if (_newBlockData.onchainOperations.length == 0) {
            return (processableOperationsHash, priorityOperationsProcessed, offsetsCommitment, slaverChainNum, onchainOperationPubdataHashs);
        }
        uint64 uncommittedPriorityRequestsOffset = firstPriorityRequestId + totalCommittedPriorityRequests;
        for (uint256 i = 0; i < _newBlockData.onchainOperations.length; ++i) {
            OnchainOperationData memory onchainOpData = _newBlockData.onchainOperations[i];

            uint256 pubdataOffset = onchainOpData.publicDataOffset;
            // uint256 chainIdOffset = pubdataOffset.add(1);
            // comment this value to resolve stack too deep error
            require(pubdataOffset + 1 < pubData.length, "h1");
            require(pubdataOffset % CHUNK_BYTES == 0, "h2");

            {
                uint256 chunkId = pubdataOffset / CHUNK_BYTES;
                require(offsetsCommitment[chunkId] == 0x00, "h3"); // offset commitment should be empty
                offsetsCommitment[chunkId] = bytes1(0x01);
            }

            // check chain id
            uint8 chainId = uint8(pubData[pubdataOffset + 1]);
            checkChainId(chainId);

            Operations.OpType opType = Operations.OpType(uint8(pubData[pubdataOffset]));

            uint64 nextPriorityOpIndex = uncommittedPriorityRequestsOffset + priorityOperationsProcessed;
            (uint64 newPriorityProceeded, bytes memory opPubData, bytes memory processablePubData) = checkOnchainOp(
                opType,
                chainId,
                pubData,
                pubdataOffset,
                nextPriorityOpIndex,
                onchainOpData.ethWitness);
            priorityOperationsProcessed = priorityOperationsProcessed + newPriorityProceeded;
            // group onchain operations pubdata hash by chain id for slaver chains
            if (chainId != CHAIN_ID) {
                uint256 chainOrder = chainId - 1;
                onchainOperationPubdataHashs[chainOrder] = Utils.concatHash(onchainOperationPubdataHashs[chainOrder], opPubData);
            }
            if (processablePubData.length > 0) {
                // concat processable onchain operations pubdata hash of current chain
                processableOperationsHash = Utils.concatHash(processableOperationsHash, processablePubData);
            }
        }
    }

    /// @dev Creates block commitment from its data
    /// @dev _offsetCommitment - hash of the array where 1 is stored in chunk where onchainOperation begins and 0 for other chunks
    function createBlockCommitment(StoredBlockInfo memory _previousBlock, CommitBlockInfo memory _newBlockData, bytes memory offsetsCommitment) internal pure returns (bytes32 commitment) {
        bytes32 offsetsCommitmentHash = sha256(offsetsCommitment);
        bytes32 newBlockPubDataHash = sha256(_newBlockData.publicData);
        commitment = sha256(abi.encodePacked(
            uint256(_newBlockData.blockNumber),
            uint256(DEFAULT_FEE_ACCOUNT_ID),
            _previousBlock.stateHash,
            _newBlockData.newStateHash,
            uint256(_newBlockData.timestamp),
            newBlockPubDataHash,
            offsetsCommitmentHash
        ));
    }

    /// @dev Create synchronization hash for cross chain block verify
    function createSyncHash(SyncHash[] memory preBlockSyncHashs, CommitBlockInfo memory _newBlock, uint256 slaverChainNum, bytes32[] memory onchainOperationPubdataHashs) internal pure returns (SyncHash[] memory syncHashs) {
        syncHashs = new SyncHash[](slaverChainNum);
        uint256 chainOrder = 0;
        for (uint8 i = 0; i < onchainOperationPubdataHashs.length; ++i) {
            uint8 chainId = i + 1;
            if (chainId == CHAIN_ID) {
                continue;
            }
            uint256 chainIndex = 1 << chainId - 1;
            if (chainIndex & ALL_CHAINS == chainIndex) {
                bytes32 preBlockSyncHash = EMPTY_STRING_KECCAK;
                for (uint j = 0; j < preBlockSyncHashs.length; ++j) {
                    SyncHash memory _preBlockSyncHash = preBlockSyncHashs[j];
                    if (_preBlockSyncHash.chainId == chainId) {
                        preBlockSyncHash = _preBlockSyncHash.syncHash;
                        break;
                    }
                }
                // only append syncHash if onchain op exist in pubdata
                bytes32 newBlockSyncHash = preBlockSyncHash;
                bytes32 onchainOperationPubdataHash = onchainOperationPubdataHashs[i];
                if (onchainOperationPubdataHash != EMPTY_STRING_KECCAK) {
                    newBlockSyncHash = createSlaverChainSyncHash(preBlockSyncHash, _newBlock.blockNumber, _newBlock.newStateHash, onchainOperationPubdataHash);
                }
                syncHashs[chainOrder] = SyncHash(chainId, newBlockSyncHash);
                chainOrder++;
            }
        }
    }

    /// @dev init onchain op pubdata hash for all slaver chains
    function initOnchainOperationPubdataHashs() internal pure returns (uint256 slaverChainNum, bytes32[] memory onchainOperationPubdataHashs) {
        slaverChainNum = 0;
        onchainOperationPubdataHashs = new bytes32[](MAX_CHAIN_ID);
        for(uint8 chainId = MIN_CHAIN_ID; chainId <= MAX_CHAIN_ID; ++chainId) {
            uint256 chainIndex = 1 << chainId - 1;
            if (chainIndex & ALL_CHAINS == chainIndex) {
                if (chainId == CHAIN_ID) {
                    continue;
                }
                slaverChainNum++;
                onchainOperationPubdataHashs[chainId - MIN_CHAIN_ID] = EMPTY_STRING_KECCAK;
            }
        }
    }

    function checkChainId(uint8 chainId) internal pure {
        require(chainId >= MIN_CHAIN_ID && chainId <= MAX_CHAIN_ID, "i1");
        // revert if invalid chain id exist
        // for example, when `ALL_CHAINS` = 13(1 << 0 | 1 << 2 | 1 << 3), it means 2(1 << 2 - 1) is a invalid chainId
        uint256 chainIndex = 1 << chainId - 1; // overflow is impossible, min(i) = MIN_CHAIN_ID = 1
        require(chainIndex & ALL_CHAINS == chainIndex, "i2");
    }

    function checkOnchainOp(Operations.OpType opType, uint8 chainId, bytes memory pubData, uint256 pubdataOffset, uint64 nextPriorityOpIdx, bytes memory ethWitness) internal view returns (uint64 priorityOperationsProcessed, bytes memory opPubData, bytes memory processablePubData) {
        priorityOperationsProcessed = 0;
        processablePubData = new bytes(0);
        // ignore check if ops are not part of the current chain
        if (opType == Operations.OpType.Deposit) {
            opPubData = Bytes.slice(pubData, pubdataOffset, DEPOSIT_BYTES);
            if (chainId == CHAIN_ID) {
                Operations.checkDepositOperation(opPubData, priorityRequests[nextPriorityOpIdx].hashedPubData);
                priorityOperationsProcessed = 1;
            }
        } else if (opType == Operations.OpType.ChangePubKey) {
            opPubData = Bytes.slice(pubData, pubdataOffset, CHANGE_PUBKEY_BYTES);
            if (chainId == CHAIN_ID) {
                Operations.ChangePubKey memory op = Operations.readChangePubKeyPubdata(opPubData);
                if (ethWitness.length != 0) {
                    bool valid = verifyChangePubkey(ethWitness, op);
                    require(valid, "k0");
                } else {
                    bool valid = authFacts[op.owner][op.nonce] == keccak256(abi.encodePacked(op.pubKeyHash));
                    require(valid, "k1");
                }
            }
        } else {
            if (opType == Operations.OpType.Withdraw) {
                opPubData = Bytes.slice(pubData, pubdataOffset, WITHDRAW_BYTES);
            } else if (opType == Operations.OpType.ForcedExit) {
                opPubData = Bytes.slice(pubData, pubdataOffset, FORCED_EXIT_BYTES);
            } else if (opType == Operations.OpType.FullExit) {
                opPubData = Bytes.slice(pubData, pubdataOffset, FULL_EXIT_BYTES);
                if (chainId == CHAIN_ID) {
                    Operations.checkFullExitOperation(opPubData, priorityRequests[nextPriorityOpIdx].hashedPubData);
                    priorityOperationsProcessed = 1;
                }
            } else {
                revert("k2");
            }
            if (chainId == CHAIN_ID) {
                // clone opPubData here instead of return its reference
                // because opPubData and processablePubData will be consumed in later concatHash
                processablePubData = Bytes.slice(opPubData, 0, opPubData.length);
            }
        }
    }

    /// @notice Execute blocks, completing priority operations and processing withdrawals.
    /// @dev 1. Processes all pending operations (Send Exits, Complete priority requests)
    /// 2. Finalizes block on Ethereum
    function executeBlocks(ExecuteBlockInfo[] memory _blocksData) external active onlyValidator nonReentrant {
        uint32 nBlocks = uint32(_blocksData.length);
        require(nBlocks > 0, "d0");

        uint32 _totalBlocksExecuted = totalBlocksExecuted;
        require(_totalBlocksExecuted + nBlocks <= totalBlocksSynchronized, "d1");

        uint64 priorityRequestsExecuted = 0;

        for (uint32 i = 0; i < nBlocks; ++i) {
            uint32 _executedBlockIdx = _totalBlocksExecuted + i + 1;
            ExecuteBlockInfo memory _blockExecuteData = _blocksData[i];
            require(_blockExecuteData.storedBlock.blockNumber == _executedBlockIdx, "d2");
            executeOneBlock(_blockExecuteData, _executedBlockIdx);
            priorityRequestsExecuted = priorityRequestsExecuted + _blockExecuteData.storedBlock.priorityOperations;
        }

        firstPriorityRequestId = firstPriorityRequestId + priorityRequestsExecuted;
        totalCommittedPriorityRequests = totalCommittedPriorityRequests - priorityRequestsExecuted;
        totalOpenPriorityRequests = totalOpenPriorityRequests - priorityRequestsExecuted;

        totalBlocksExecuted = _totalBlocksExecuted + nBlocks;

        emit BlockExecuted(_blocksData[nBlocks-1].storedBlock.blockNumber);
    }


    function createSlaverChainSyncHash(bytes32 preBlockSyncHash, uint32 _newBlockNumber, bytes32 _newBlockStateHash, bytes32 _newBlockOnchainOperationPubdataHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(preBlockSyncHash, _newBlockNumber, _newBlockStateHash, _newBlockOnchainOperationPubdataHash));
    }

    // =================Internal functions=================

    function deposit(address _tokenAddress, uint128 _amount, bytes32 _zkLinkAddress, uint8 _subAccountId, bool _mapping) internal active {
        // ===Checks===
        // disable deposit to zero address or global asset account
        require(_zkLinkAddress != bytes32(0) && _zkLinkAddress != GLOBAL_ASSET_ACCOUNT_ADDRESS, "e1");
        // subAccountId MUST be valid
        require(_subAccountId == 0, "e2");
        // token MUST be registered to ZkLink and deposit MUST be enabled
        uint16 tokenId = tokenIds[_tokenAddress];
        // 0 is a invalid token and MUST NOT register to zkLink contract
        require(tokenId != 0, "e3");
        RegisteredToken storage rt = tokens[tokenId];
        require(rt.registered, "e3");
        require(!rt.paused, "e4");

        if (_tokenAddress != ETH_ADDRESS) {
            // transfer erc20 token from sender to zkLink contract
            IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        }

        // improve decimals before send to layer two
        _amount = improveDecimals(_amount, rt.decimals);
        // disable deposit with zero amount
        require(_amount > 0 && _amount <= MAX_DEPOSIT_AMOUNT, "e0");

        // only stable tokens(e.g. USDC, BUSD) support mapping to USD when deposit
        uint16 targetTokenId;
        if (_mapping) {
            require(tokenId >= MIN_USD_STABLE_TOKEN_ID && tokenId <= MAX_USD_STABLE_TOKEN_ID, "e5");
            targetTokenId = USD_TOKEN_ID;
        } else {
            targetTokenId = tokenId;
        }

        // ===Effects===
        // Priority Queue request
        Operations.Deposit memory op =
        Operations.Deposit({
            chainId: CHAIN_ID,
            accountId: 0, // unknown at this point
            subAccountId: _subAccountId,
            owner: _zkLinkAddress,
            tokenId: tokenId,
            targetTokenId: targetTokenId,
            amount: _amount
        });
        bytes memory pubData = Operations.writeDepositPubdataForPriorityQueue(op);
        addPriorityRequest(Operations.OpType.Deposit, pubData, Operations.DEPOSIT_CHECK_BYTES);
    }

    // Priority queue

    /// @notice Saves priority request in storage
    /// @dev Calculates expiration block for request, store this request and emit NewPriorityRequest event
    /// @param _opType Rollup operation type
    /// @param _pubData Operation pubdata
    /// @param _hashSize Operation pubdata hash size
    function addPriorityRequest(Operations.OpType _opType, bytes memory _pubData, uint256 _hashSize) internal {
        // Expiration block is: current block number + priority expiration delta
        uint64 expirationBlock = SafeCast.toUint64(block.number + PRIORITY_EXPIRATION);

        uint64 nextPriorityRequestId = firstPriorityRequestId + totalOpenPriorityRequests;

        bytes20 hashedPubData = Utils.hashBytesWithSizeToBytes20(_pubData, _hashSize);

        priorityRequests[nextPriorityRequestId] = Operations.PriorityOperation({
            hashedPubData: hashedPubData,
            expirationBlock: expirationBlock,
            opType: _opType
        });

        emit NewPriorityRequest(msg.sender, nextPriorityRequestId, _opType, _pubData, uint256(expirationBlock));

        totalOpenPriorityRequests = totalOpenPriorityRequests + 1;
    }

    /// @notice Checks that change operation is correct
    function verifyChangePubkey(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk) internal pure returns (bool) {
        ChangePubkeyType changePkType = ChangePubkeyType(uint8(_ethWitness[0]));
        if (changePkType == ChangePubkeyType.ECRECOVER) {
            return verifyChangePubkeyECRECOVER(_ethWitness, _changePk);
        } else if (changePkType == ChangePubkeyType.CREATE2) {
            return verifyChangePubkeyCREATE2(_ethWitness, _changePk);
        } else {
            return false;
        }
    }

    /// @notice Checks that signature is valid for pubkey change message
    function verifyChangePubkeyECRECOVER(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk) internal pure returns (bool) {
        (, bytes memory signature) = Bytes.read(_ethWitness, 1, 65); // offset is 1 because we skip type of ChangePubkey
        bytes memory message = abi.encodePacked("ChangePubKey\nPubKeyHash: ", Strings.toHexString(uint160(_changePk.pubKeyHash), 20), "\nNonce: ", Strings.toString(_changePk.nonce), "\nAccountId: ", Strings.toString(_changePk.accountId));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(message.length), message));
        address recoveredAddress = Utils.recoverAddressFromEthSignature(signature, messageHash);
        return recoveredAddress == _changePk.owner;
    }

    /// @notice Checks that signature is valid for pubkey change message
    function verifyChangePubkeyCREATE2(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk) internal pure returns (bool) {
        address creatorAddress;
        bytes32 saltArg; // salt arg is additional bytes that are encoded in the CREATE2 salt
        bytes32 codeHash;
        uint256 offset = 1; // offset is 1 because we skip type of ChangePubkey
        (offset, creatorAddress) = Bytes.readAddress(_ethWitness, offset);
        (offset, saltArg) = Bytes.readBytes32(_ethWitness, offset);
        (offset, codeHash) = Bytes.readBytes32(_ethWitness, offset);
        // salt from CREATE2 specification
        bytes32 salt = keccak256(abi.encodePacked(saltArg, _changePk.pubKeyHash));
        // Address computation according to CREATE2 definition: https://eips.ethereum.org/EIPS/eip-1014
        address recoveredAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), creatorAddress, salt, codeHash))))
        );
        // This type of change pubkey can be done only once(when the account is not active)
        return recoveredAddress == _changePk.owner && _changePk.nonce == 0;
    }

    /// @dev Executes one block
    /// 1. Processes all pending operations (Send Exits, Complete priority requests)
    /// 2. Finalizes block on Ethereum
    /// _executedBlockIdx is index in the array of the blocks that we want to execute together
    function executeOneBlock(ExecuteBlockInfo memory _blockExecuteData, uint32 _executedBlockIdx) internal {
        // Ensure block was committed
        require(
            hashStoredBlockInfo(_blockExecuteData.storedBlock) ==
            storedBlockHashes[_executedBlockIdx],
            "m0"
        );

        bytes32 pendingOnchainOpsHash = EMPTY_STRING_KECCAK;
        for (uint32 i = 0; i < _blockExecuteData.pendingOnchainOpsPubdata.length; ++i) {
            bytes memory pubData = _blockExecuteData.pendingOnchainOpsPubdata[i];

            Operations.OpType opType = Operations.OpType(uint8(pubData[0]));

            // `pendingOnchainOpsPubdata` only contains ops of the current chain
            // no need to check chain id

            if (opType == Operations.OpType.Withdraw) {
                Operations.Withdraw memory op = Operations.readWithdrawPubdata(pubData);
                // account request fast withdraw and sub account supply nonce
                _executeWithdraw(op.accountId, op.subAccountId, op.nonce, op.owner, op.tokenId, op.amount, op.dataHash, op.fastWithdrawFeeRate, op.withdrawToL1);
            } else if (opType == Operations.OpType.ForcedExit) {
                Operations.ForcedExit memory op = Operations.readForcedExitPubdata(pubData);
                // request forced exit for target account but initiator sub account supply nonce
                // forced exit take no fee for fast withdraw
                _executeWithdraw(op.initiatorAccountId, op.initiatorSubAccountId, op.initiatorNonce, op.target, op.tokenId, op.amount, bytes32(0), 0, op.withdrawToL1);
            } else if (opType == Operations.OpType.FullExit) {
                Operations.FullExit memory op = Operations.readFullExitPubdata(pubData);
                increasePendingBalance(op.tokenId, op.owner, op.amount);
            } else {
                revert("m2");
            }
            pendingOnchainOpsHash = Utils.concatHash(pendingOnchainOpsHash, pubData);
        }
        require(pendingOnchainOpsHash == _blockExecuteData.storedBlock.pendingOnchainOperationsHash, "m3");
    }

    /// @dev The circuit will check whether there is dust in the amount
    function _executeWithdraw(uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce, address owner, uint16 tokenId, uint128 amount, bytes32 dataHash, uint16 fastWithdrawFeeRate, uint8 withdrawToL1) internal {
        // token MUST be registered
        RegisteredToken storage rt = tokens[tokenId];
        require(rt.registered, "o0");

        // recover withdraw amount
        uint128 recoverAmount = recoveryDecimals(amount, rt.decimals);
        bytes32 withdrawHash = getWithdrawHash(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, rt.tokenAddress, recoverAmount, fastWithdrawFeeRate);
        if (withdrawToL1 == 1) {
            // store L1 withdraw data hash to wait relayer consuming it
            pendingL1Withdraws[withdrawHash] = true;
            emit WithdrawalPendingL1(withdrawHash);
        } else {
            address acceptor = accepts[withdrawHash];
            if (acceptor == address(0)) {
                // receiver act as an acceptor
                accepts[withdrawHash] = owner;
                if (dataHash != bytes32(0)) {
                    // record token ownership to pending withdraw with calls and waiting relayer to call `withdrawPendingBalanceWithCall`
                    bytes32 withdrawWithDataHash = getWithdrawWithDataHash(owner, rt.tokenAddress, recoverAmount, dataHash, accountIdOfNonce, subAccountIdOfNonce, nonce);
                    pendingWithdrawWithCalls[withdrawWithDataHash] = true;
                } else {
                    // record token ownership to pending balances and waiting relayer to call `withdrawPendingBalance`
                    increasePendingBalance(tokenId, owner, amount);
                }
            } else {
                increasePendingBalance(tokenId, acceptor, amount);
            }
        }
    }

    /// @dev Increase `_recipient` balance to withdraw
    /// @param _amount amount that need to recovery decimals when withdraw
    function increasePendingBalance(uint16 _tokenId, address _recipient, uint128 _amount) internal {
        bytes32 recipient = extendAddress(_recipient);
        increaseBalanceToWithdraw(recipient, _tokenId, _amount);
        emit WithdrawalPending(_tokenId, recipient, _amount);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title ZkLink acceptor contract
/// @author zk.link
abstract contract ZkLinkAcceptor {
    using SafeERC20 for IERC20;

    /// @dev Address represent eth when deposit or withdraw
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev When set fee = 100, it means 1%
    uint16 internal constant MAX_ACCEPT_FEE_RATE = 10000;

    /// @dev Accept infos of withdraw
    /// @dev key is keccak256(abi.encodePacked(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, token, amount, fastWithdrawFeeRate))
    /// @dev value is the acceptor
    mapping(bytes32 => address) public accepts;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /// @notice Event emitted when acceptor accept a fast withdraw
    event Accept(address acceptor, address receiver, address token, uint128 amount, uint16 withdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce, uint128 amountReceive);

    /// @notice Acceptor accept a eth fast withdraw, acceptor will get a fee for profit
    /// @param receiver User receive token from acceptor (the owner of withdraw operation)
    /// @param amount The amount of withdraw operation
    /// @param fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
    /// @param accountIdOfNonce Account that supply nonce
    /// @param subAccountIdOfNonce SubAccount that supply nonce
    /// @param nonce SubAccount nonce, used to produce unique accept info
    function acceptETH(address payable receiver, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) external payable {
        // ===Checks===
        uint128 amountReceive = _checkAccept(msg.sender, receiver, ETH_ADDRESS, amount, fastWithdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce);

        // ===Interactions===
        // make sure msg value >= amountReceive
        uint256 amountReturn = msg.value - amountReceive;
        // msg.sender should set a reasonable gas limit when call this function
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = receiver.call{value: amountReceive}("");
        require(success, "E0");
        // if send too more eth then return back to msg sender
        if (amountReturn > 0) {
            // it's safe to use call to msg.sender and can send all gas left to it
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = msg.sender.call{value: amountReturn}("");
            require(success, "E1");
        }
        emit Accept(msg.sender, receiver, ETH_ADDRESS, amount, fastWithdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce, amountReceive);
    }

    /// @notice Acceptor accept a erc20 token fast withdraw, acceptor will get a fee for profit
    /// @param receiver User receive token from acceptor (the owner of withdraw operation)
    /// @param token Token address
    /// @param amount The amount of withdraw operation
    /// @param fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
    /// @param accountIdOfNonce Account that supply nonce
    /// @param subAccountIdOfNonce SubAccount that supply nonce
    /// @param nonce SubAccount nonce, used to produce unique accept info
    function acceptERC20(address receiver, address token, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) external {
        // ===Checks===
        uint128 amountReceive = _checkAccept(msg.sender, receiver, token, amount, fastWithdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce);

        // ===Interactions===
        IERC20(token).safeTransferFrom(msg.sender, receiver, amountReceive);
        emit Accept(msg.sender, receiver, token, amount, fastWithdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce, amountReceive);
    }

    function _checkAccept(address acceptor, address receiver, address token, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) internal returns (uint128 amountReceive) {
        // acceptor and receiver MUST be set and MUST not be the same
        require(receiver != address(0), "H1");
        require(receiver != acceptor, "H2");
        // feeRate MUST be valid and MUST not be 100%
        require(fastWithdrawFeeRate < MAX_ACCEPT_FEE_RATE, "H3");
        amountReceive = amount * (MAX_ACCEPT_FEE_RATE - fastWithdrawFeeRate) / MAX_ACCEPT_FEE_RATE;

        // accept tx may be later than block exec tx(with user withdraw op)
        bytes32 hash = getWithdrawHash(accountIdOfNonce, subAccountIdOfNonce, nonce, receiver, token, amount, fastWithdrawFeeRate);
        require(accepts[hash] == address(0), "H4");

        // ===Effects===
        accepts[hash] = acceptor;
    }

    /// @dev Return accept record hash for withdraw
    /// @dev (accountIdOfNonce, subAccountIdOfNonce, nonce) ensures the uniqueness of withdraw hash
    function getWithdrawHash(uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce, address owner, address token, uint128 amount, uint16 fastWithdrawFeeRate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, token, amount, fastWithdrawFeeRate));
    }

    /// @dev Update the receiver of withdraw claim
    /// @dev If acceptor accepted this withdraw then return acceptor or return owner
    function updateAcceptReceiver(address _owner, address _token, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) internal returns (address) {
        bytes32 withdrawHash = getWithdrawHash(_accountIdOfNonce, _subAccountIdOfNonce, _nonce, _owner, _token, _amount, _fastWithdrawFeeRate);
        address acceptor = accepts[withdrawHash];
        address receiver = acceptor;
        if (acceptor == address(0)) {
            // receiver act as a acceptor
            receiver = _owner;
            accepts[withdrawHash] = _owner;
        }
        return receiver;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
            add(bts, 32), // BYTES_HEADER_SIZE
            data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromUIntTruncated(uint256(uint160(self)), 20);
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return newOffset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 newOffset, bytes memory data) {
        data = slice(_data, _offset, _length);
        newOffset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bool r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint8 r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint16 r) {
        newOffset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint24 r) {
        newOffset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint32 r) {
        newOffset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint128 r) {
        newOffset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint160 r) {
        newOffset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, address r) {
        newOffset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes20 r) {
        newOffset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes32 r) {
        newOffset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _newLength) internal pure returns (uint256 r) {
        require(_newLength <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _newLength, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _newLength) * 8);
    }

    // Helper function for hex conversion.
    function halfByteToHex(bytes1 _byte) internal pure returns (bytes1 _hexByte) {
        require(uint8(_byte) < 0x10, "hbh11"); // half byte's value is out of 0..15 range.

        // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
        return bytes1(uint8(0x66656463626139383736353433323130 >> (uint8(_byte) * 8)));
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
            // here outStringByte from each half of input byte calculates by the next:
            //
            // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
            // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                out_curr,
                shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                add(out_curr, 0x01),
                shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {
    /// @dev Default fee address in state
    address public constant DEFAULT_FEE_ADDRESS = 0x374632e7D48B7872d904524FdC5Dd4516F42cDFF;

    bytes32 internal constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /// @dev Bytes in one chunk
    uint8 internal constant CHUNK_BYTES = 23;

    /// @dev Bytes of L2 PubKey hash
    uint8 internal constant PUBKEY_HASH_BYTES = 20;

    /// @dev Max amount of tokens registered in the network
    uint16 internal constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 65535;

    /// @dev Max account id that could be registered in the network
    uint32 internal constant MAX_ACCOUNT_ID = 16777215;

    /// @dev Max sub account id that could be bound to account id
    uint8 internal constant MAX_SUB_ACCOUNT_ID = 31;

    /// @dev Expected average period of block creation
    uint256 internal constant BLOCK_PERIOD = 12 seconds;

    /// @dev Operation chunks
    uint256 internal constant DEPOSIT_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant FULL_EXIT_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant WITHDRAW_BYTES = 5 * CHUNK_BYTES;
    uint256 internal constant FORCED_EXIT_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant CHANGE_PUBKEY_BYTES = 3 * CHUNK_BYTES;

    /// @dev Expiration delta for priority request to be satisfied (in seconds)
    /// @dev NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD)
    /// @dev otherwise incorrect block with priority op could not be reverted.
    uint256 internal constant PRIORITY_EXPIRATION_PERIOD = 14 days;

    /// @dev Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 internal constant PRIORITY_EXPIRATION =
        2592000;

    /// @dev Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant MASS_FULL_EXIT_PERIOD = 5 days;

    /// @dev Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @dev Notice period before activation preparation status of upgrade mode (in seconds)
    /// @dev NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint256 internal constant UPGRADE_NOTICE_PERIOD =
        0;

    /// @dev Max commitment produced in zk proof where highest 3 bits is 0
    uint256 internal constant MAX_PROOF_COMMITMENT = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 internal constant INPUT_MASK = 14474011154664524427946373126085988481658748083205070504932198000989141204991;

    /// @dev Auth fact reset timelock
    uint256 internal constant AUTH_FACT_RESET_TIMELOCK = 1 days;

    /// @dev Max deposit of ERC20 token that is possible to deposit
    uint128 internal constant MAX_DEPOSIT_AMOUNT = 20282409603651670423947251286015;

    /// @dev Chain id defined by ZkLink
    uint8 public constant CHAIN_ID = 9;

    /// @dev Min chain id defined by ZkLink
    uint8 public constant MIN_CHAIN_ID = 1;

    /// @dev Max chain id defined by ZkLink
    uint8 public constant MAX_CHAIN_ID = 9;

    /// @dev All chain index, for example [1, 2, 3, 4] => 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 = 15
    uint256 public constant ALL_CHAINS = 268;

    /// @dev Master chain id defined by ZkLink
    uint8 public constant MASTER_CHAIN_ID = 9;

    /// @dev NONE, ORIGIN, NEXUS
    uint8 internal constant SYNC_TYPE = 1;
    uint8 internal constant SYNC_NONE = 0;
    uint8 internal constant SYNC_ORIGIN = 1;
    uint8 internal constant SYNC_NEXUS = 2;

    /// @dev Token decimals is a fixed value at layer two in ZkLink
    uint8 internal constant TOKEN_DECIMALS_OF_LAYER2 = 18;

    /// @dev The default fee account id
    uint32 internal constant DEFAULT_FEE_ACCOUNT_ID = 0;

    /// @dev Global asset account in the network
    /// @dev Can not deposit to or full exit this account
    uint32 internal constant GLOBAL_ASSET_ACCOUNT_ID = 1;
    bytes32 internal constant GLOBAL_ASSET_ACCOUNT_ADDRESS = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @dev USD and USD stable tokens defined by zkLink
    /// @dev User can deposit USD stable token(eg. USDC, BUSD) to get USD in layer two
    /// @dev And user also can full exit USD in layer two and get back USD stable tokens
    uint16 internal constant USD_TOKEN_ID = 1;
    uint16 internal constant MIN_USD_STABLE_TOKEN_ID = 17;
    uint16 internal constant MAX_USD_STABLE_TOKEN_ID = 31;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Upgradeable.sol";
import "./Operations.sol";

/// @title zkSync events
/// @author Matter Labs
interface Events {
    /// @notice Event emitted when a block is committed
    event BlockCommit(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is proven
    event BlockProven(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is synced
    event BlockSynced(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is executed
    event BlockExecuted(uint32 indexed blockNumber);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state and contract
    event Withdrawal(uint16 indexed tokenId, uint128 amount);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state but not from contract
    event WithdrawalPending(uint16 indexed tokenId, bytes32 indexed recepient, uint128 amount);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state to a target contract
    event WithdrawalCall(bytes32 indexed withdrawHash);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state to L1 and contract
    event WithdrawalL1(bytes32 indexed withdrawHash);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state to L1 but not from contract
    event WithdrawalPendingL1(bytes32 indexed withdrawHash);

    /// @notice Event emitted when user sends a authentication fact (e.g. pub-key hash)
    event FactAuth(address indexed sender, uint32 nonce, bytes fact);

    /// @notice Event emitted when authentication fact reset clock start
    event FactAuthResetTime(address indexed sender, uint32 nonce, uint256 time);

    /// @notice Event emitted when blocks are reverted
    event BlocksRevert(uint32 totalBlocksVerified, uint32 totalBlocksCommitted);

    /// @notice Exodus mode entered event
    event ExodusMode();

    /// @notice New priority request event. Emitted when a request is placed into mapping
    event NewPriorityRequest(
        address sender,
        uint64 serialId,
        Operations.OpType opType,
        bytes pubData,
        uint256 expirationBlock
    );

    /// @notice Token added to ZkLink net
    /// @dev log token decimals on this chain to let L2 know(token decimals maybe different on different chains)
    event NewToken(uint16 indexed tokenId, address indexed token, uint8 decimals);

    /// @notice Governor changed
    event NewGovernor(address newGovernor);

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(address indexed validatorAddress, bool isActive);

    /// @notice Token pause status update
    event TokenPausedUpdate(uint16 indexed token, bool paused);

    /// @notice Sync service changed
    event SetSyncService(uint8 chainId, address newSyncService);

    /// @notice Gateway address changed
    event SetGateway(address indexed newGateway);

    /// @notice Event emitted when send sync hash to master chain
    event SendSlaverSyncHash(bytes32 syncHash);

    /// @notice Event emitted when send sync hash to arbitration
    event SendMasterSyncHash(uint32 blockNumber, bytes32 syncHash);

    /// @notice Event emitted when receive sync hash from a slaver chain
    event ReceiveSlaverSyncHash(uint8 slaverChainId, bytes32 syncHash);
}

/// @title Upgrade events
/// @author Matter Labs
interface UpgradeEvents {
    /// @notice Event emitted when new upgradeable contract is added to upgrade gatekeeper's list of managed contracts
    event NewUpgradable(uint256 indexed versionId, address indexed upgradeable);

    /// @notice Upgrade mode enter event
    event NoticePeriodStart(
        uint256 indexed versionId,
        address[] newTargets,
        uint256 noticePeriod // notice period (in seconds)
    );

    /// @notice Upgrade mode cancel event
    event UpgradeCancel(uint256 indexed versionId);

    /// @notice Upgrade mode complete event
    event UpgradeComplete(uint256 indexed versionId, address[] newTargets);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Bytes.sol";
import "./Utils.sol";

/// @title zkSync operations tools
/// @dev Circuit ops and their pubdata (chunks * bytes)
library Operations {
    /// @dev zkSync circuit operation type
    enum OpType {
        Noop, // 0
        Deposit, // 1 L1 Op
        TransferToNew, // 2 L2 Op
        Withdraw, // 3 L2 Op
        Transfer, // 4 L2 Op
        FullExit, // 5 L1 Op
        ChangePubKey, // 6 L2 Op
        ForcedExit, // 7 L2 Op
        OrderMatching, // 8 L2 Op
        ContractMatching, // 9 L2 Op
        Liquidation, // 10 L2 Op
        AutoDeleveraging, // 11 L2 Op
        UpdateGlobalVar, // 12 L2 Op
        Funding // 13 L2 Op
    }

    // Byte lengths

    /// @dev op is uint8
    uint8 internal constant OP_TYPE_BYTES = 1;

    /// @dev chainId is uint8
    uint8 internal constant CHAIN_BYTES = 1;

    /// @dev token is uint16
    uint8 internal constant TOKEN_BYTES = 2;

    /// @dev nonce is uint32
    uint8 internal constant NONCE_BYTES = 4;

    /// @dev address is 20 bytes length
    uint8 internal constant ADDRESS_BYTES = 20;

    /// @dev address prefix zero bytes length
    uint8 internal constant ADDRESS_PREFIX_ZERO_BYTES = 12;

    /// @dev fee is uint16
    uint8 internal constant FEE_BYTES = 2;

    /// @dev accountId is uint32
    uint8 internal constant ACCOUNT_ID_BYTES = 4;

    /// @dev subAccountId is uint8
    uint8 internal constant SUB_ACCOUNT_ID_BYTES = 1;

    /// @dev amount is uint128
    uint8 internal constant AMOUNT_BYTES = 16;

    /// @dev Priority hash bytes length
    uint256 internal constant DEPOSIT_CHECK_BYTES = 55;
    uint256 internal constant FULL_EXIT_CHECK_BYTES = 43;

    // Priority operations: Deposit, FullExit
    struct PriorityOperation {
        bytes20 hashedPubData; // hashed priority operation public data
        uint64 expirationBlock; // expiration block number (ETH block) for this request (must be satisfied before)
        OpType opType; // priority operation type
    }

    struct Deposit {
        // uint8 opType
        uint8 chainId; // deposit from which chain that identified by L2 chain id
        uint8 subAccountId; // the sub account is bound to account, default value is 0(the global public sub account)
        uint16 tokenId; // the token that registered to L2
        uint16 targetTokenId; // the token that user increased in L2
        uint128 amount; // the token amount deposited to L2
        bytes32 owner; // the address that receive deposited token at L2
        uint32 accountId; // the account id bound to the owner address, ignored at serialization and will be set when the block is submitted
    } // 59 bytes

    /// @dev Deserialize deposit pubdata
    function readDepositPubdata(bytes memory _data) internal pure returns (Deposit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.targetTokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        (offset, parsed.owner) = Bytes.readBytes32(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
    }

    /// @dev Serialize deposit pubdata
    function writeDepositPubdataForPriorityQueue(Deposit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.Deposit),
            op.chainId,
            op.subAccountId,
            op.tokenId,
            op.targetTokenId,
            op.amount,
            op.owner,
            uint32(0) // accountId (ignored during hash calculation)
        );
    }

    /// @dev Checks that op pubdata is same as operation in priority queue
    function checkDepositOperation(bytes memory _opPubData, bytes20 hashedPubData) internal pure {
        require(Utils.hashBytesWithSizeToBytes20(_opPubData, DEPOSIT_CHECK_BYTES) == hashedPubData, "OP: invalid deposit hash");
    }

    struct FullExit {
        // uint8 opType
        uint8 chainId; // withdraw to which chain that identified by L2 chain id
        uint32 accountId; // the account id to withdraw from
        uint8 subAccountId; // the sub account is bound to account, default value is 0(the global public sub account)
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address owner; // the address that own the account at L2
        uint16 tokenId; // the token that withdraw to L1
        uint16 srcTokenId; // the token that deducted in L2
        uint128 amount; // the token amount that fully withdrawn to owner, ignored at serialization and will be set when the block is submitted
    } // 59 bytes

    /// @dev Deserialize fullExit pubdata
    function readFullExitPubdata(bytes memory _data) internal pure returns (FullExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.srcTokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
    }

    /// @dev Serialize fullExit pubdata
    function writeFullExitPubdataForPriorityQueue(FullExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.FullExit),
            op.chainId,
            op.accountId,
            op.subAccountId,
            bytes12(0), // append 12 zero bytes
            op.owner,
            op.tokenId,
            op.srcTokenId,
            uint128(0) // amount(ignored during hash calculation)
        );
    }

    /// @dev Checks that op pubdata is same as operation in priority queue
    function checkFullExitOperation(bytes memory _opPubData, bytes20 hashedPubData) internal pure {
        require(Utils.hashBytesWithSizeToBytes20(_opPubData, FULL_EXIT_CHECK_BYTES) == hashedPubData, "OP: invalid fullExit hash");
    }

    struct Withdraw {
        //uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain the withdraw happened
        uint32 accountId; // the account id to withdraw from
        uint8 subAccountId; // the sub account id to withdraw from
        uint16 tokenId; // the token that to withdraw
        //uint16 srcTokenId; -- the token that decreased in L2, present in pubdata, ignored at serialization
        uint128 amount; // the token amount to withdraw
        //uint16 fee; -- present in pubdata, ignored at serialization
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address owner; // the address to receive token
        uint32 nonce; // the sub account nonce
        uint16 fastWithdrawFeeRate; // fast withdraw fee rate taken by acceptor
        uint8 withdrawToL1; // when this flag is 1, it means withdraw token to L1
        bytes32 dataHash; // the call data for withdraw
    } // 100 bytes

    function readWithdrawPubdata(bytes memory _data) internal pure returns (Withdraw memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        offset += TOKEN_BYTES;
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        offset += FEE_BYTES;
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);
        (offset, parsed.fastWithdrawFeeRate) = Bytes.readUInt16(_data, offset);
        (offset, parsed.withdrawToL1) = Bytes.readUint8(_data, offset);
        (offset, parsed.dataHash) = Bytes.readBytes32(_data, offset);
    }

    struct ForcedExit {
        //uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain the force exit happened
        uint32 initiatorAccountId; // the account id of initiator
        uint8 initiatorSubAccountId; // the sub account id of initiator
        uint32 initiatorNonce; // the sub account nonce of initiator
        uint32 targetAccountId; // the account id of target
        //uint8 targetSubAccountId; -- present in pubdata, ignored at serialization
        uint16 tokenId; // the token that to withdraw
        //uint16 srcTokenId; -- the token that decreased in L2, present in pubdata, ignored at serialization
        uint128 amount; // the token amount to withdraw
        uint8 withdrawToL1; // when this flag is 1, it means withdraw token to L1
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address target; // the address to receive token
    } // 69 bytes

    function readForcedExitPubdata(bytes memory _data) internal pure returns (ForcedExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.initiatorAccountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.initiatorSubAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.initiatorNonce) = Bytes.readUInt32(_data, offset);
        (offset, parsed.targetAccountId) = Bytes.readUInt32(_data, offset);
        offset += SUB_ACCOUNT_ID_BYTES;
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        offset += TOKEN_BYTES;
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        (offset, parsed.withdrawToL1) = Bytes.readUint8(_data, offset);
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.target) = Bytes.readAddress(_data, offset);
    }

    // ChangePubKey
    struct ChangePubKey {
        // uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain to verify(only one chain need to verify for gas saving)
        uint32 accountId; // the account that to change pubkey
        //uint8 subAccountId; -- present in pubdata, ignored at serialization
        bytes20 pubKeyHash; // hash of the new rollup pubkey
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address owner; // the owner that own this account
        uint32 nonce; // the account nonce
        //uint16 tokenId; -- present in pubdata, ignored at serialization
        //uint16 fee; -- present in pubdata, ignored at serialization
    } // 67 bytes

    function readChangePubKeyPubdata(bytes memory _data) internal pure returns (ChangePubKey memory parsed) {
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        offset += SUB_ACCOUNT_ID_BYTES;
        (offset, parsed.pubKeyHash) = Bytes.readBytes20(_data, offset);
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    /// @dev Address of lock flag variable.
    /// @dev Flag is placed at random memory location to not interfere with Storage contract.
    uint256 private constant LOCK_FLAG_ADDRESS = 0x8e94fed44239eb2314ab7a406345e6c5a8f0ccedf3b600de3d004e672c33abf4; // keccak256("ReentrancyGuard") - 1;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/566a774222707e424896c0c390a84dc3c13bdcb2/contracts/security/ReentrancyGuard.sol
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function initializeReentrancyGuard() internal {
        uint256 lockSlotOldValue;

        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange every call to nonReentrant
        // will be cheaper.
        assembly {
            lockSlotOldValue := sload(LOCK_FLAG_ADDRESS)
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }

        // Check that storage slot for reentrancy guard is empty to rule out possibility of double initialization
        require(lockSlotOldValue == 0, "1B");
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        uint256 _status;
        assembly {
            _status := sload(LOCK_FLAG_ADDRESS)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_status == _NOT_ENTERED);

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "16");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "17");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "18");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "19");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "1a");
        return uint8(value);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the upgradeable contract
/// @author Matter Labs
interface Upgradeable {
    /// @notice Upgrades target of upgradeable contract
    /// @param newTarget New target
    function upgradeTarget(address newTarget) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the upgradeable master contract (defines notice period duration and allows finish upgrade during preparation of it)
/// @author Matter Labs
interface UpgradeableMaster {
    /// @notice Notice period before activation preparation status of upgrade mode
    function getNoticePeriod() external returns (uint256);

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external returns (bool);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Bytes.sol";

library Utils {
    /// @notice Returns lesser of two values
    function minU32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    /// @notice Recovers signer's address from ethereum signature for given message
    /// @param _signature 65 bytes concatenated. R (32) + S (32) + V (1)
    /// @param _messageHash signed message hash.
    /// @return address of the signer
    function recoverAddressFromEthSignature(bytes memory _signature, bytes32 _messageHash)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65, "ut0"); // incorrect signature length

        bytes32 signR;
        bytes32 signS;
        uint8 signV;
        assembly {
            signR := mload(add(_signature, 32))
            signS := mload(add(_signature, 64))
            signV := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_messageHash, signV, signR, signS);
    }

    /// @notice Returns new_hash = hash(old_hash + bytes)
    function concatHash(bytes32 _hash, bytes memory _bytes) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let bytesLen := add(mload(_bytes), 32)
            mstore(_bytes, _hash)
            result := keccak256(_bytes, bytesLen)
        }
        return result;
    }

    /// @notice Returns new_hash = hash(a + b)
    function concatTwoHash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    function hashBytesWithSizeToBytes20(bytes memory _bytes, uint256 _size) internal pure returns (bytes20) {
        bytes32 result;
        assembly {
            result := keccak256(add(_bytes, 32), _size)
        }
        return bytes20(uint160(uint256(result)));
    }
}