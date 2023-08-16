/**
 *Submitted for verification at Arbiscan on 2023-08-15
*/

// Sources flattened with hardhat v2.16.1 https://hardhat.org

// File lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol

// SPDX-License-Identifier: MIT AND GPL-3.0-only AND BUSL-1.1
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

// File lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File lib/openzeppelin-contracts/contracts/utils/Address.sol

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
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

// File lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                oldAllowance + value
            )
        );
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    oldAllowance - value
                )
            );
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeWithSelector(
            token.approve.selector,
            spender,
            value
        );

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, 0)
            );
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
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        require(
            returndata.length == 0 || abi.decode(returndata, (bool)),
            "SafeERC20: ERC20 operation did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(
        IERC20 token,
        bytes memory data
    ) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            Address.isContract(address(token));
    }
}

// File lib/openzeppelin-contracts/contracts/utils/math/Math.sol

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
    function sqrt(
        uint256 a,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
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
    function log10(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
    function log256(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol

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

// File lib/openzeppelin-contracts/contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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
        return
            string(
                abi.encodePacked(
                    value < 0 ? "-" : "",
                    toString(SignedMath.abs(value))
                )
            );
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
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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
    function equal(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(
        bytes memory s
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(
        address validator,
        bytes memory data
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// File src/types/EventTypes.sol

pragma solidity ^0.8.17;

library EventTypes {
    /// -----------------------------------------------------------------------
    /// Types
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line
    uint8 constant EVENT_TYPE_PROTOCOL_LEVEL = 1;
    // solhint-disable-next-line
    uint8 constant EVENT_TYPE_CUSTODY_LEVEL = 2;
    // solhint-disable-next-line
    uint8 constant EVENT_TYPE_ASSET_LEVEL = 3;

    // solhint-disable-next-line
    uint8 constant MIN_VALUE_TRIGGER = 1;

    /// -----------------------------------------------------------------------
    /// Storage Structure
    /// -----------------------------------------------------------------------

    struct Base {
        uint32 id;
        string name;
        string description;
        uint8 eventType;
    }

    struct MinValueTrigger {
        uint8 version;
        address asset;
        uint256 minValue;
        uint8 decimal;
    }
}

// File src/interface/IAssetLevelEvent.sol

pragma solidity ^0.8.17;

interface IAssetLevelEvent {
    function getAssetAndTriggerValue(
        bytes calldata trigger
    )
        external
        view
        returns (bool isSuccess, address asset, uint256 value, uint8 decimal);

    function getRoundId(
        bytes calldata proof
    ) external pure returns (uint80 roundId);
}

// File src/interface/IPortfolio.sol

pragma solidity ^0.8.15;

interface IPortfolio {
    event ExecutedBorrow(
        address indexed owner,
        address indexed portfolio,
        uint256 borrowAmount,
        uint256 newAmount
    );

    event ExecutedDeposit(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        uint256 addedAmount,
        uint256 newAmount
    );

    event ExecutedWithdraw(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        uint256 withdrawAmount,
        uint256 newAmount
    );

    event ExecutedRepay(
        address indexed owner,
        address indexed portfolio,
        uint256 repayAmount,
        uint256 newAmount
    );

    event ExecutedTransferCollateral(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        address receiver,
        uint256 amount
    );

    function getPortfolioId() external view returns (uint256);

    function getSeller() external view returns (address);

    function getPool() external view returns (address);

    function getTDSContractFactory() external view returns (address);

    function getRemainBorrowAmount() external view returns (uint128);

    function getBorrowAmount() external view returns (uint128);

    function getAllCollateralAmount()
        external
        view
        returns (uint256[] memory vaultAmountList);

    function getMaxBorrowAmount() external view returns (uint128);

    function validateExecuteBorrow(
        uint128 addBorrowAmount
    ) external returns (uint128);

    function portfolioLeverageRatio() external view returns (uint128);

    function executeBorrow(uint128 addBorrowAmount) external returns (bool);

    function executeDeposit(
        address from,
        address vault,
        uint256 amount
    ) external;

    function executeWithdraw(
        address vault,
        uint256 amount,
        address receiver
    ) external;

    function executeRepay(uint128 repayAmount) external returns (bool);

    function executeTransferCollateralAsset(
        address vault,
        address receiver,
        uint256 amount
    ) external returns (bool);
}

// File src/interface/IPortfolioFactory.sol

pragma solidity ^0.8.17;

interface IPortfolioFactory {
    event PortfolioCreated(
        address indexed seller,
        address indexed portfolio,
        uint256 indexed portfolioId,
        uint8 portfolioType
    );
    event PortfolioManagerCreated(address indexed seller);

    event ExecutedDeposit(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        uint256 depositAmount
    );

    event ExecutedWithdraw(
        address indexed owner,
        address indexed portfolio,
        address indexed vault,
        uint256 withdrawAmount,
        address receiver
    );

    function getPortfolioListBySeller(
        address seller
    ) external view returns (address[] memory);

    function getPortfolioById(
        address seller,
        uint256 portfolioId
    ) external view returns (address);

    function createIsolatedProtfolio() external;

    function depositWithPermit(
        uint256 portfolioId,
        address supplier,
        address vault,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        uint256 portfolioId,
        address supplier,
        address vault,
        uint256 amount
    ) external;

    function withdraw(
        uint256 portfolioId,
        address vault,
        uint256 amount,
        address receiver
    ) external;
}

// File src/interface/IReferenceEvent.sol

pragma solidity ^0.8.17;

interface IReferenceEvent {
    function id() external view returns (uint32);

    function name() external view returns (string memory);

    function description() external view returns (string memory);

    function eventType() external view returns (uint8);

    function verifyTriggerSanity(
        bytes calldata trigger
    ) external view returns (bool);

    function verifyProofSanity(
        bytes calldata proof
    ) external view returns (bool);
}

// File src/types/TDSTypes.sol

pragma solidity ^0.8.17;

library TDSTypes {
    /// -----------------------------------------------------------------------
    /// Types
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line
    uint8 constant SETTLEMENT_TYPE_PARAMETRIC = 1;
    // solhint-disable-next-line
    uint8 constant SETTLEMENT_TYPE_OPTIMISTIC = 2;
    // solhint-disable-next-line
    uint8 constant SETTLEMENT_TYPE_HYBRID = 3;

    /// -----------------------------------------------------------------------
    /// Status
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line
    uint8 constant STATUS_OPEN = 1;
    // solhint-disable-next-line
    uint8 constant STATUS_EXPIRE = 2;
    // solhint-disable-next-line
    uint8 constant STATUS_PARAMETRIC_ORACLE_DEFAULT = 3;
    // solhint-disable-next-line
    uint8 constant STATUS_OPTIMISTIC_ORACLE_DEFAULT = 4;
    // solhint-disable-next-line
    uint8 constant STATUS_MULTI_SIGN_DEFAULT = 5;
    // solhint-disable-next-line
    uint8 constant STATUS_DEFAULT = 6;
    // solhint-disable-next-line
    uint8 constant STATUS_DEFAULT_PAID = 7;

    /// -----------------------------------------------------------------------
    /// Storage Structure
    /// -----------------------------------------------------------------------

    struct TDSContract {
        uint256 id;
        uint64 startDate; // timestamp value, when tdsContract is first created
        uint64 duration; // count in second
        uint32 referenceEvent;
        uint32 remainPaymentTimes; // payment times remain
        uint64 paymentInterval; // duration between each payment, must be divide evenly by duration
        uint128 recoveryRate; // express in Wad
        uint128 notional; // ConconrdUSD express in Wad
        uint128 spread; // APY express in Wad
        uint128 premiumPerPayment; // express in Wad premium amount for each payment time
        address exchangeAsset;
        address buyer;
        address seller;
        address sellerPortfolio;
        uint8 status;
        uint8 settlementType;
        uint64 defaultTime;
        bytes defaultTrigger;
    }

    struct TDSTermBaseRequest {
        uint64 requestExpire; // this request will be valid until
        uint64 duration; // count in second
        uint64 paymentInterval; // duration between each payment, must be divide evenly by duration
        uint32 referenceEvent;
        uint128 recoveryRate; // express in Wad
        uint128 notional; // payment amount in case of default
        uint128 spread; // bps with Wad, 100 bps = 1%, per year
        address exchangeAsset;
        uint8 settlementType;
        bytes defaultTrigger;
    }

    struct TDSTermSellRequest {
        TDSTermBaseRequest baseRequest;
        address seller;
        address sellerPortfolio;
        bool isPersist;
        uint256 nonce; // nonce of seller
    }

    struct TDSTermBuyRequest {
        TDSTermBaseRequest baseRequest;
        address buyer;
        uint256 nonce; // nonce of buyer
    }
}

// File src/interface/ITDSContractFactory.sol

pragma solidity ^0.8.17;

interface ITDSContractFactory {
    event TDSContractCreated(
        uint256 indexed tdsContractId,
        TDSTypes.TDSContract tdsContract
    );

    event TDSContractPreimumTransfered(
        uint256 indexed tdsContractId,
        address indexed buyer,
        address indexed seller,
        uint256 premium
    );

    event TDSContractRepaid(
        uint256 indexed tdsContractId,
        address indexed portfolio,
        uint256 notion
    );

    event TDSContractDefault(
        uint256 indexed tdsContractId,
        uint32 indexed referenceEvent,
        uint8 indexed status,
        bytes defaultTrigger
    );

    event TDSContractClaimedPaymentWhenDefault(
        uint256 indexed tdsContractId,
        address indexed exchangeAsset,
        address buyer,
        address seller,
        uint256 notional
    );

    function getTDSContract(
        uint256 tdsContractId
    ) external view returns (TDSTypes.TDSContract memory);

    function createTDSContractFromBuyRequest(
        bytes calldata tdsTermBuyRequest,
        bytes calldata buyerSignature,
        bytes calldata sellerSignature,
        address seller,
        address sellerPortfolio
    ) external;

    function createTDSContractFromSellRequest(
        bytes calldata tdsTermSellRequest,
        bytes calldata sellerSignature,
        bytes calldata buyerSignature,
        address buyer
    ) external;

    function executeTDSContractTransferPremium(uint256 tdsContractId) external;

    function executeTDSContractSettlement(
        uint256 tdsContractId,
        bytes memory proof
    ) external;

    function executeClaimPaymentWhenDefault(uint256 tdsContractId) external;
}

// File lib/openzeppelin-contracts/contracts/interfaces/IERC1271.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4 magicValue);
}

// File src/error/Error.sol

pragma solidity ^0.8.17;

/// -----------------------------------------------------------------------
/// Pool Custom Errors
/// -----------------------------------------------------------------------

error CVaultNotExist();
error GivenAssetNotMatchUnderlyingAsset();
error UnderlyingAssetExisted(address);
error InvalidVaultDeicmals(uint8);

/// -----------------------------------------------------------------------
/// Portfolio Custom Errors
/// -----------------------------------------------------------------------

error SellerExisted();
error SellerNotExisted();
error PortfolioNotExisted();
error IsolatedPortfolioAlreadyOpenTDSContract();
error TransferCollateralAssetError(string);
error PermissionDenied();
error AmountTooSmall();
error ExceedWarningRatio(uint256);
error VaultNotAllowed(address);
error InsufficientWithdrawAmount(uint256);
error InsufficientRepayAmount(uint256);

/// -----------------------------------------------------------------------
/// SignatureChecker Custom Errors
/// -----------------------------------------------------------------------

error InvalidSignatureLength(uint256);
error InvalidSignature();

/// -----------------------------------------------------------------------
/// TDSContract Custom Errors
/// -----------------------------------------------------------------------

error RequestExpire();
error InvalidPaymentInterval(uint256, uint256);
error BuyerInsufficientBalance(uint256);
error InvalidTDSContractCaller(address);
error ExecuteBorrowError(string);
error ExecuteRepayError(string);
error InvalidDecimal(uint8);
error TDSContractNotOpen(uint256);
error AlreadyPayAllPremium(uint256);
error NotReachPaymentDateYet(uint256);
error TDSContractNotDefault(uint256);
error EventDefaultValidatioError(string);
error ClaimPaymentWhenDefaultError(string);
error InvalidProof();
error InvalidPriceOracleRoundId(string);
error InvalidPriceOracleTime();

/// -----------------------------------------------------------------------
/// Nonce Custom Errors
/// -----------------------------------------------------------------------

error InvalidSellerNonce();
error InvalidBuyerNonce();
error InvalidReferenceEvent(uint256);
error InvalidDefaultTrigger();
error InvalidMinNonce();
error InvalidSender();

/// -----------------------------------------------------------------------
/// Oracle Custom Errors
/// -----------------------------------------------------------------------

error AssetNotSupported(address);
error ReportNotFound();
error TDSContractIsDefault();
error TDSContractUnderReporting();
error TDSContractReportTimeout();
error TDSContractAlreadyReported();

/// -----------------------------------------------------------------------
/// Reference Event Custom Errors
/// -----------------------------------------------------------------------

error InvalidEventType();

// File src/libraries/SignatureChecker.sol

pragma solidity 0.8.17;

///@title Signature Checker
///@notice Library to check if a given signature is valid for EOAs or contract accounts.
///@dev This library is a modification of an Open-Zeppelin `SignatureChecker` library extended by a support for EIP-2098 compact signatures.
library SignatureChecker {
    // solhint-disable-next-line var-name-mixedcase, private-vars-leading-underscore
    string internal constant VERSION = "1.0";

    ///@dev Function will try to recover a signer of a given signature and check if is the same as given signer address.
    ///     For a contract account signer address, function will check signature validity by calling `isValidSignature` function defined by EIP-1271.
    ///@param signer Address that should be a `hash` signer or a signature validator, in case of a contract account.
    ///@param hash Hash of a signed message that should validated.
    ///@param signature Signature of a signed `hash`. Could be empty for a contract account signature validation.
    ///                 Signature can be standard (65 bytes) or compact (64 bytes) defined by EIP-2098.
    ///@return True if a signature is valid.
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        // Check that signature is valid for contract account
        if (signer.code.length > 0) {
            (bool success, bytes memory result) = signer.staticcall(
                abi.encodeWithSelector(
                    IERC1271.isValidSignature.selector,
                    hash,
                    signature
                )
            );
            return
                success &&
                result.length == 32 &&
                abi.decode(result, (bytes32)) ==
                bytes32(IERC1271.isValidSignature.selector);
        }
        // Check that signature is valid for EOA
        else {
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Standard signature data (65 bytes)
            if (signature.length == 65) {
                assembly {
                    r := mload(add(signature, 0x20))
                    s := mload(add(signature, 0x40))
                    v := byte(0, mload(add(signature, 0x60)))
                }
            }
            // Compact signature data (64 bytes) - see EIP-2098
            else if (signature.length == 64) {
                bytes32 vs;

                assembly {
                    r := mload(add(signature, 0x20))
                    vs := mload(add(signature, 0x40))
                }

                s =
                    vs &
                    bytes32(
                        0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                    );
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert InvalidSignatureLength(signature.length);
            }

            return signer == ECDSA.recover(hash, v, r, s);
        }
    }
}

// File src/interface/IPriceOracle.sol

pragma solidity ^0.8.17;

interface IPriceOracle {
    function getDataByRoundId(
        address asset,
        uint80 roundId
    )
        external
        view
        returns (
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound,
            uint8 decimal
        );

    function getLatestData(
        address asset
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound,
            uint8 decimal
        );
}

// File src/interface/IReferenceEventFactory.sol

pragma solidity ^0.8.17;

interface IReferenceEventFactory {
    event AssetAdded(address indexed asset);

    event ReferenceEventCreated(
        uint256 indexed id,
        uint8 indexed eventType,
        address eventAddress,
        string name
    );

    function lastReferenceEventId() external view returns (uint32);

    function isAllowAsset(address asset) external view returns (bool);

    function getReferenceEventById(
        uint32 eventId
    ) external view returns (address);

    function assets() external view returns (address[] memory);
}

// File src/libraries/WadRayMath.sol

pragma solidity ^0.8.0;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    // solhint-disable-next-line
    uint256 internal constant WAD = 1e18;
    // solhint-disable-next-line
    uint256 internal constant HALF_WAD = 0.5e18;
    // solhint-disable-next-line
    uint256 internal constant RAY = 1e27;
    // solhint-disable-next-line
    uint256 internal constant HALF_RAY = 0.5e27;
    // solhint-disable-next-line
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return c = a * b, in wad
     */
    function wadMul128(uint128 a, uint128 b) internal pure returns (uint128 c) {
        // solhint-disable-next-line
        uint128 MAX_UINT128 = type(uint128).max;
        assembly {
            let result := div(add(mul(a, b), HALF_WAD), WAD)
            if gt(result, MAX_UINT128) {
                revert(0, 0)
            } // Check for overflow
            c := result
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     */
    function wadDiv128(uint128 a, uint128 b) internal pure returns (uint128 c) {
        // solhint-disable-next-line
        uint128 MAX_UINT128 = type(uint128).max;
        assembly {
            if iszero(b) {
                revert(0, 0)
            }

            let result := div(add(mul(a, WAD), div(b, 2)), b)
            if gt(result, MAX_UINT128) {
                revert(0, 0)
            } // Check for overflow
            c := result
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }

    /// @dev Return result is express in ray
    /// @notice round down is not a problem
    function calculateTotal(
        uint256 collateralRayAmount,
        uint256 price,
        uint8 decimal
    ) external pure returns (uint256 total) {
        if (decimal > 27) {
            assembly {
                price := div(price, exp(10, sub(decimal, 27)))
            }
        } else {
            assembly {
                price := mul(price, exp(10, sub(27, decimal)))
            }
        }
        total = rayMul(collateralRayAmount, price);
    }
}

// File lib/solady/utils/SafeCastLib.sol

pragma solidity ^0.8.4;

/// @notice Safe integer casting library that reverts on overflow.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error Overflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          UNSIGNED INTEGER SAFE CASTING OPERATIONS          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toUint8(uint256 x) internal pure returns (uint8) {
        if (x >= 1 << 8) _revertOverflow();
        return uint8(x);
    }

    function toUint16(uint256 x) internal pure returns (uint16) {
        if (x >= 1 << 16) _revertOverflow();
        return uint16(x);
    }

    function toUint24(uint256 x) internal pure returns (uint24) {
        if (x >= 1 << 24) _revertOverflow();
        return uint24(x);
    }

    function toUint32(uint256 x) internal pure returns (uint32) {
        if (x >= 1 << 32) _revertOverflow();
        return uint32(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        if (x >= 1 << 40) _revertOverflow();
        return uint40(x);
    }

    function toUint48(uint256 x) internal pure returns (uint48) {
        if (x >= 1 << 48) _revertOverflow();
        return uint48(x);
    }

    function toUint56(uint256 x) internal pure returns (uint56) {
        if (x >= 1 << 56) _revertOverflow();
        return uint56(x);
    }

    function toUint64(uint256 x) internal pure returns (uint64) {
        if (x >= 1 << 64) _revertOverflow();
        return uint64(x);
    }

    function toUint72(uint256 x) internal pure returns (uint72) {
        if (x >= 1 << 72) _revertOverflow();
        return uint72(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        if (x >= 1 << 80) _revertOverflow();
        return uint80(x);
    }

    function toUint88(uint256 x) internal pure returns (uint88) {
        if (x >= 1 << 88) _revertOverflow();
        return uint88(x);
    }

    function toUint96(uint256 x) internal pure returns (uint96) {
        if (x >= 1 << 96) _revertOverflow();
        return uint96(x);
    }

    function toUint104(uint256 x) internal pure returns (uint104) {
        if (x >= 1 << 104) _revertOverflow();
        return uint104(x);
    }

    function toUint112(uint256 x) internal pure returns (uint112) {
        if (x >= 1 << 112) _revertOverflow();
        return uint112(x);
    }

    function toUint120(uint256 x) internal pure returns (uint120) {
        if (x >= 1 << 120) _revertOverflow();
        return uint120(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x >= 1 << 128) _revertOverflow();
        return uint128(x);
    }

    function toUint136(uint256 x) internal pure returns (uint136) {
        if (x >= 1 << 136) _revertOverflow();
        return uint136(x);
    }

    function toUint144(uint256 x) internal pure returns (uint144) {
        if (x >= 1 << 144) _revertOverflow();
        return uint144(x);
    }

    function toUint152(uint256 x) internal pure returns (uint152) {
        if (x >= 1 << 152) _revertOverflow();
        return uint152(x);
    }

    function toUint160(uint256 x) internal pure returns (uint160) {
        if (x >= 1 << 160) _revertOverflow();
        return uint160(x);
    }

    function toUint168(uint256 x) internal pure returns (uint168) {
        if (x >= 1 << 168) _revertOverflow();
        return uint168(x);
    }

    function toUint176(uint256 x) internal pure returns (uint176) {
        if (x >= 1 << 176) _revertOverflow();
        return uint176(x);
    }

    function toUint184(uint256 x) internal pure returns (uint184) {
        if (x >= 1 << 184) _revertOverflow();
        return uint184(x);
    }

    function toUint192(uint256 x) internal pure returns (uint192) {
        if (x >= 1 << 192) _revertOverflow();
        return uint192(x);
    }

    function toUint200(uint256 x) internal pure returns (uint200) {
        if (x >= 1 << 200) _revertOverflow();
        return uint200(x);
    }

    function toUint208(uint256 x) internal pure returns (uint208) {
        if (x >= 1 << 208) _revertOverflow();
        return uint208(x);
    }

    function toUint216(uint256 x) internal pure returns (uint216) {
        if (x >= 1 << 216) _revertOverflow();
        return uint216(x);
    }

    function toUint224(uint256 x) internal pure returns (uint224) {
        if (x >= 1 << 224) _revertOverflow();
        return uint224(x);
    }

    function toUint232(uint256 x) internal pure returns (uint232) {
        if (x >= 1 << 232) _revertOverflow();
        return uint232(x);
    }

    function toUint240(uint256 x) internal pure returns (uint240) {
        if (x >= 1 << 240) _revertOverflow();
        return uint240(x);
    }

    function toUint248(uint256 x) internal pure returns (uint248) {
        if (x >= 1 << 248) _revertOverflow();
        return uint248(x);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           SIGNED INTEGER SAFE CASTING OPERATIONS           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function toInt8(int256 x) internal pure returns (int8) {
        int8 y = int8(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt16(int256 x) internal pure returns (int16) {
        int16 y = int16(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt24(int256 x) internal pure returns (int24) {
        int24 y = int24(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt32(int256 x) internal pure returns (int32) {
        int32 y = int32(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt40(int256 x) internal pure returns (int40) {
        int40 y = int40(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt48(int256 x) internal pure returns (int48) {
        int48 y = int48(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt56(int256 x) internal pure returns (int56) {
        int56 y = int56(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt64(int256 x) internal pure returns (int64) {
        int64 y = int64(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt72(int256 x) internal pure returns (int72) {
        int72 y = int72(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt80(int256 x) internal pure returns (int80) {
        int80 y = int80(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt88(int256 x) internal pure returns (int88) {
        int88 y = int88(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt96(int256 x) internal pure returns (int96) {
        int96 y = int96(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt104(int256 x) internal pure returns (int104) {
        int104 y = int104(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt112(int256 x) internal pure returns (int112) {
        int112 y = int112(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt120(int256 x) internal pure returns (int120) {
        int120 y = int120(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt128(int256 x) internal pure returns (int128) {
        int128 y = int128(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt136(int256 x) internal pure returns (int136) {
        int136 y = int136(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt144(int256 x) internal pure returns (int144) {
        int144 y = int144(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt152(int256 x) internal pure returns (int152) {
        int152 y = int152(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt160(int256 x) internal pure returns (int160) {
        int160 y = int160(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt168(int256 x) internal pure returns (int168) {
        int168 y = int168(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt176(int256 x) internal pure returns (int176) {
        int176 y = int176(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt184(int256 x) internal pure returns (int184) {
        int184 y = int184(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt192(int256 x) internal pure returns (int192) {
        int192 y = int192(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt200(int256 x) internal pure returns (int200) {
        int200 y = int200(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt208(int256 x) internal pure returns (int208) {
        int208 y = int208(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt216(int256 x) internal pure returns (int216) {
        int216 y = int216(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt224(int256 x) internal pure returns (int224) {
        int224 y = int224(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt232(int256 x) internal pure returns (int232) {
        int232 y = int232(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt240(int256 x) internal pure returns (int240) {
        int240 y = int240(x);
        if (x != y) _revertOverflow();
        return y;
    }

    function toInt248(int256 x) internal pure returns (int248) {
        int248 y = int248(x);
        if (x != y) _revertOverflow();
        return y;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _revertOverflow() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `Overflow()`.
            mstore(0x00, 0x35278d12)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}

// File src/tds/TDSContractLogic.sol

pragma solidity ^0.8.17;

/// @title  TDSContractLogic
/// @notice Logic for tdsContract
library TDSContractLogic {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeCastLib for uint256;

    using WadRayMath for uint128;

    using WadRayMath for uint256;

    /// -----------------------------------------------------------------------
    /// Logic
    /// -----------------------------------------------------------------------

    function getPremiumPerPayment(
        TDSTypes.TDSContract memory tdsContract
    ) public pure returns (uint128) {
        uint256 result = (tdsContract.paymentInterval *
            (tdsContract.notional.wadMul128(tdsContract.spread))) / 365 days;
        return result.toUint128();
    }

    function getTotalPremium(
        TDSTypes.TDSContract memory tdsContract
    ) public pure returns (uint128) {
        uint256 result = (tdsContract.duration *
            (tdsContract.notional.wadMul128(tdsContract.spread))) / 365 days;
        return result.toUint128();
    }

    function getTotalPremiumByExchangeAsset(
        TDSTypes.TDSContract memory tdsContract
    ) public pure returns (uint256) {
        return getTotalPremium(tdsContract).wadToRay();
    }

    function getRemainPremium(
        TDSTypes.TDSContract memory tdsContract
    ) public pure returns (uint128) {
        return
            getPremiumPerPayment(tdsContract) * tdsContract.remainPaymentTimes;
    }

    /// @dev convert premium from Wad to Ray
    function getPremiumPerPaymentByExchangeAsset(
        TDSTypes.TDSContract memory tdsContract
    ) public pure returns (uint256) {
        return uint256(tdsContract.premiumPerPayment).wadToRay();
    }

    /// @dev convert notional from Wad to Ray
    function getNotionalByExchangeAsset(
        TDSTypes.TDSContract memory tdsContract
    ) public pure returns (uint256) {
        return uint256(tdsContract.notional).wadToRay();
    }

    function getTotalPaymentTimes(
        TDSTypes.TDSContract memory tdsContract
    ) public pure returns (uint32) {
        unchecked {
            return uint32(tdsContract.duration / tdsContract.paymentInterval);
        }
    }

    function getNextPaymentDate(
        TDSTypes.TDSContract memory tdsContract
    ) public pure returns (uint256 nextPaymentDate) {
        // Example with 12 months contract, payment date will be the end of month 3 6 9 12
        uint32 totalPaymentTimes = getTotalPaymentTimes(tdsContract);
        uint32 paidTimes = totalPaymentTimes - tdsContract.remainPaymentTimes;
        if (paidTimes == totalPaymentTimes) {
            // Finish all payments then return last payment date
            nextPaymentDate =
                tdsContract.startDate +
                tdsContract.paymentInterval *
                paidTimes;
        } else {
            nextPaymentDate =
                tdsContract.startDate +
                tdsContract.paymentInterval *
                (paidTimes + 1);
        }
    }
}

// File src/interface/IRevokedNonce.sol

pragma solidity 0.8.17;

interface IRevokedNonce {
    event NonceRevoked(address indexed owner, uint256 indexed nonce);

    event MinNonceSet(address indexed owner, uint256 indexed minNonce);

    function name() external view returns (string memory);

    function isNonceRevoked(
        address owner,
        uint256 nonce
    ) external view returns (bool);

    function minNonces(address owner) external view returns (uint256);

    function revokeNonce(address owner, uint256 nonce) external;

    function setMinNonce(address owner, uint256 minNonce) external;
}

// File src/tds/TDSTermRequest.sol

pragma solidity ^0.8.17;

/// @title  TDSTermRequest
/// @notice Create tdsContract from term
abstract contract TDSTermRequest {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using TDSContractLogic for TDSTypes.TDSContract;

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    IReferenceEventFactory internal immutable _eventFactory;

    constructor(address eventFactory_) {
        _eventFactory = IReferenceEventFactory(eventFactory_);
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    /// @dev create contract from given term
    function _createTDSContract(
        TDSTypes.TDSTermBaseRequest memory request,
        address buyer,
        bytes calldata buyerSignature,
        address seller,
        address sellerPortfolio,
        bytes calldata sellerSignature,
        bytes32 requestHash
    ) internal view returns (TDSTypes.TDSContract memory tdsContract) {
        address refEventAddress = _eventFactory.getReferenceEventById(
            request.referenceEvent
        );

        // Verify reference event existence
        if (refEventAddress == address(0))
            revert InvalidReferenceEvent(request.referenceEvent);

        // Verify default trigger sanity data, each event will provide a list
        // of default trigger
        if (
            !IReferenceEvent(refEventAddress).verifyTriggerSanity(
                request.defaultTrigger
            )
        ) revert InvalidDefaultTrigger();

        // Verify buyer signature
        if (
            SignatureChecker.isValidSignatureNow(
                buyer,
                requestHash,
                buyerSignature
            ) == false
        ) revert InvalidSignature();

        // Verify seller signature
        if (
            SignatureChecker.isValidSignatureNow(
                seller,
                requestHash,
                sellerSignature
            ) == false
        ) revert InvalidSignature();

        // Verify payment interval against contract duration
        if (request.duration < request.paymentInterval) {
            revert InvalidPaymentInterval(
                request.duration,
                request.paymentInterval
            );
        }

        // Verify duration is divisible by payment interval
        // if not, system can't produce the next payment time
        if (request.duration % request.paymentInterval != 0)
            revert InvalidPaymentInterval(
                request.duration,
                request.paymentInterval
            );

        tdsContract.startDate = uint64(block.timestamp);
        tdsContract.duration = request.duration;
        tdsContract.referenceEvent = request.referenceEvent;
        tdsContract.defaultTrigger = request.defaultTrigger;
        tdsContract.exchangeAsset = request.exchangeAsset;
        tdsContract.recoveryRate = request.recoveryRate;
        tdsContract.notional = request.notional;
        tdsContract.spread = request.spread;
        tdsContract.paymentInterval = request.paymentInterval;
        tdsContract.buyer = buyer;
        tdsContract.seller = seller;
        tdsContract.sellerPortfolio = sellerPortfolio;
        tdsContract.status = TDSTypes.STATUS_OPEN;
        tdsContract.premiumPerPayment = tdsContract.getPremiumPerPayment();
        tdsContract.remainPaymentTimes = tdsContract.getTotalPaymentTimes();
        tdsContract.settlementType = request.settlementType;
    }
}

// File src/tds/TDSTermBuyRequest.sol

pragma solidity ^0.8.17;

/// @title  TDSTermBuyRequest
/// @notice Create tdsContract from buy request
abstract contract TDSTermBuyRequest is TDSTermRequest {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeCastLib for uint256;

    using TDSContractLogic for TDSTypes.TDSContract;

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line
    bytes32 internal immutable BUY_REQUEST_DOMAIN_SEPARATOR;

    IRevokedNonce internal immutable _buyerRevokeNonce;

    // solhint-disable-next-line
    bytes32 internal immutable BUY_REQUEST_HASH =
        keccak256(
            "TDSTermBuyRequest((uint256 requestExpire,uint256 duration,bytes referenceEvent,bytes defaultTrigger,address exchangeAsset,uint128 recoveryRate,uint128 notional,uint128 spread,uint256 paymentInterval),address buyer,uint256 nonce)"
        );

    constructor(address buyerRevokeNonce_) {
        _buyerRevokeNonce = IRevokedNonce(buyerRevokeNonce_);
        BUY_REQUEST_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("TDSTermBuyRequest"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /// -----------------------------------------------------------------------
    /// View Functions
    /// -----------------------------------------------------------------------

    function getBuyRequestDomainSeparator() external view returns (bytes32) {
        return BUY_REQUEST_DOMAIN_SEPARATOR;
    }

    /// @dev get hash according to EIP-712
    function getTdsTermBuyRequestHash(
        TDSTypes.TDSTermBuyRequest memory request
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    hex"1901",
                    BUY_REQUEST_DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encodePacked(BUY_REQUEST_HASH, abi.encode(request))
                    )
                )
            );
    }

    function encodeTDSTermBuyRequest(
        TDSTypes.TDSTermBuyRequest memory request
    ) public pure returns (bytes memory) {
        return abi.encode(request);
    }

    function getBuyerMinNonce(address buyer) public view returns (uint256) {
        return _buyerRevokeNonce.minNonces(buyer);
    }

    function isBuyerNonceRevoked(
        address buyer,
        uint256 nonce
    ) public view returns (bool) {
        return _buyerRevokeNonce.isNonceRevoked(buyer, nonce);
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------.

    function revokeBuyerNonce(uint256 nonce) external {
        _buyerRevokeNonce.revokeNonce(msg.sender, nonce);
    }

    function setMinBuyerNonce(uint256 minNonce) external {
        _buyerRevokeNonce.setMinNonce(msg.sender, minNonce);
    }

    /// @dev create new contract from buy request
    /// @notice its require signature from both buyer and seller
    /// @notice also seller must provide its portfolio address
    function _createTDSContractFromBuyRequest(
        bytes calldata tdsTermBuyRequest,
        bytes calldata buyerSignature,
        bytes calldata sellerSignature,
        address seller,
        address sellerPortfolio
    ) internal returns (TDSTypes.TDSContract memory tdsContract) {
        TDSTypes.TDSTermBuyRequest memory request = abi.decode(
            tdsTermBuyRequest,
            (TDSTypes.TDSTermBuyRequest)
        );

        // Verify request valid time
        if (request.baseRequest.requestExpire < block.timestamp)
            revert RequestExpire();

        bytes32 requestHash = getTdsTermBuyRequestHash(request);
        address buyer = request.buyer;

        // Verify request buyer's nonce
        if (_buyerRevokeNonce.isNonceRevoked(request.buyer, request.nonce))
            revert InvalidBuyerNonce();

        tdsContract = _createTDSContract(
            request.baseRequest,
            buyer,
            buyerSignature,
            seller,
            sellerPortfolio,
            sellerSignature,
            requestHash
        );

        _buyerRevokeNonce.revokeNonce(request.buyer, request.nonce);
    }
}

// File src/tds/TDSTermSellRequest.sol

pragma solidity ^0.8.17;

/// @title  TDSTermSellRequest
/// @notice Create tdsContract from sell request
abstract contract TDSTermSellRequest is TDSTermRequest {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------
    using SafeCastLib for uint256;

    using TDSContractLogic for TDSTypes.TDSContract;

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line
    bytes32 internal immutable SELL_REQUEST_DOMAIN_SEPARATOR; // EIP 712

    IRevokedNonce internal immutable _sellerRevokeNonce;

    // solhint-disable-next-line
    bytes32 internal immutable SELL_REQUEST_HASH =
        keccak256(
            "TDSTermSellRequest((uint256 requestExpire,uint256 duration,bytes referenceEvent,bytes defaultTrigger,address exchangeAsset,uint128 recoveryRate,uint128 notional,uint128 spread,uint256 paymentInterval),address seller,address sellerPortfolio,uint256 nonce)"
        );

    constructor(address sellerRevokeNonce_) {
        _sellerRevokeNonce = IRevokedNonce(sellerRevokeNonce_);
        SELL_REQUEST_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("TDSTermSellRequest"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /// -----------------------------------------------------------------------
    /// View Functions
    /// -----------------------------------------------------------------------

    function getDomainSeparator() external view returns (bytes32) {
        return SELL_REQUEST_DOMAIN_SEPARATOR;
    }

    /// @dev get tdsTermSellRequestHash according to EIP-712
    function getTdsTermSellRequestHash(
        TDSTypes.TDSTermSellRequest memory request
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    hex"1901",
                    SELL_REQUEST_DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encodePacked(SELL_REQUEST_HASH, abi.encode(request))
                    )
                )
            );
    }

    function encodeTDSTermSellRequest(
        TDSTypes.TDSTermSellRequest memory request
    ) public pure returns (bytes memory) {
        return abi.encode(request);
    }

    function getSellerMinNonce(address seller) public view returns (uint256) {
        return _sellerRevokeNonce.minNonces(seller);
    }

    function isSellerNonceRevoked(
        address seller,
        uint256 nonce
    ) public view returns (bool) {
        return _sellerRevokeNonce.isNonceRevoked(seller, nonce);
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    function revokeSellerNonce(uint256 nonce) external {
        _sellerRevokeNonce.revokeNonce(msg.sender, nonce);
    }

    function setMinSellerNonce(uint256 minNonce) external {
        _sellerRevokeNonce.setMinNonce(msg.sender, minNonce);
    }

    function _createTDSContractFromSellRequest(
        bytes calldata tdsTermSellRequest,
        bytes calldata buyerSignature,
        bytes calldata sellerSignature,
        address buyer
    ) internal returns (TDSTypes.TDSContract memory tdsContract) {
        TDSTypes.TDSTermSellRequest memory request = abi.decode(
            tdsTermSellRequest,
            (TDSTypes.TDSTermSellRequest)
        );
        if (request.baseRequest.requestExpire < block.timestamp)
            revert RequestExpire();
        bytes32 requestHash = getTdsTermSellRequestHash(request);
        address seller = request.seller;
        address sellerPortfolio = request.sellerPortfolio;
        if (_sellerRevokeNonce.isNonceRevoked(request.seller, request.nonce))
            revert InvalidSellerNonce();
        tdsContract = _createTDSContract(
            request.baseRequest,
            buyer,
            buyerSignature,
            seller,
            sellerPortfolio,
            sellerSignature,
            requestHash
        );
        if (!request.isPersist) {
            _sellerRevokeNonce.revokeNonce(request.seller, request.nonce);
        }
    }
}

// File src/tds/TDSContractFactory.sol

pragma solidity ^0.8.17;

/// @title  TDSContracFactory
/// @notice Contract create, maintain, interact with TDSContract
contract TDSContractFactory is
    ITDSContractFactory,
    TDSTermBuyRequest,
    TDSTermSellRequest
{
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using TDSContractLogic for TDSTypes.TDSContract;

    using WadRayMath for uint128;

    using WadRayMath for uint256;

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    IPriceOracle internal immutable _priceOracle;

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    uint256 internal _lastTdsContractId;

    mapping(uint256 => TDSTypes.TDSContract) private _tdsContracts;

    constructor(
        address buyerRevokeNonce_,
        address sellerRevokeNonce_,
        address eventFactory_,
        address priceOracle_
    )
        TDSTermRequest(eventFactory_)
        TDSTermBuyRequest(buyerRevokeNonce_)
        TDSTermSellRequest(sellerRevokeNonce_)
    {
        _priceOracle = IPriceOracle(priceOracle_);
    }

    /// -----------------------------------------------------------------------
    /// Modifier
    /// -----------------------------------------------------------------------

    modifier mustOpen(uint256 tdsContractId) {
        if (_tdsContracts[tdsContractId].status != 1)
            revert TDSContractNotOpen(tdsContractId);
        _;
    }

    /// -----------------------------------------------------------------------
    /// View Functions
    /// -----------------------------------------------------------------------

    function getTDSContract(
        uint256 tdsContractId
    ) external view returns (TDSTypes.TDSContract memory) {
        return _tdsContracts[tdsContractId];
    }

    function getNextPaymentDate(
        uint256 tdsContractId
    ) external view returns (uint256 nextPaymentDate) {
        if (_tdsContracts[tdsContractId].id != 0) {
            nextPaymentDate = _tdsContracts[tdsContractId].getNextPaymentDate();
        } else {
            nextPaymentDate = 0;
        }
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    /// @dev create a new contract from buy request, then add to factory
    /// @notice to create a new contract, buyer must create the term
    function createTDSContractFromBuyRequest(
        bytes calldata tdsTermBuyRequest,
        bytes calldata buyerSignature,
        bytes calldata sellerSignature,
        address seller,
        address sellerPortfolio
    ) external override {
        TDSTypes.TDSContract
            memory tdsContract = _createTDSContractFromBuyRequest(
                tdsTermBuyRequest,
                buyerSignature,
                sellerSignature,
                seller,
                sellerPortfolio
            );
        _createTDSContract(tdsContract);
    }

    /// @dev create a new contract from sell request, then add to factory
    /// @notice to create a new contract, seller must create the term
    function createTDSContractFromSellRequest(
        bytes calldata tdsTermBuyRequest,
        bytes calldata buyerSignature,
        bytes calldata sellerSignature,
        address buyer
    ) external override {
        TDSTypes.TDSContract
            memory tdsContract = _createTDSContractFromSellRequest(
                tdsTermBuyRequest,
                buyerSignature,
                sellerSignature,
                buyer
            );
        _createTDSContract(tdsContract);
    }

    function _createTDSContract(
        TDSTypes.TDSContract memory tdsContract
    ) internal {
        // Verify portoflio collateral and sufficient borrow amount for tds contract
        IPortfolio(tdsContract.sellerPortfolio).validateExecuteBorrow(
            tdsContract.notional
        );

        // Verify buyer balance for total premium payment
        uint256 buyerBalance = IERC20(tdsContract.exchangeAsset).balanceOf(
            tdsContract.buyer
        );
        if (buyerBalance < tdsContract.getTotalPremiumByExchangeAsset())
            revert BuyerInsufficientBalance(buyerBalance);

        // Add Token Id to TDS Contract, use this as unique id of TDS Contract
        uint256 tdsContractId = ++_lastTdsContractId;
        tdsContract.id = tdsContractId;

        // Execute borrow
        uint128 beforeMaxBorrowAmount = IPortfolio(tdsContract.sellerPortfolio)
            .getRemainBorrowAmount();

        try
            IPortfolio(tdsContract.sellerPortfolio).executeBorrow(
                tdsContract.notional
            )
        {
            // Intentionally left empty as we only want to catch and rethrow the error
        } catch Error(string memory errorMessage) {
            revert ExecuteBorrowError(errorMessage);
        } catch (bytes memory reason) {
            revert ExecuteBorrowError(string(reason));
        }

        uint128 afterMaxBorrowAmount = IPortfolio(tdsContract.sellerPortfolio)
            .getRemainBorrowAmount();
        // Verify result after execute borrow
        if (
            beforeMaxBorrowAmount - afterMaxBorrowAmount != tdsContract.notional
        ) revert ExecuteBorrowError("Insufficient Balance After Borrow");

        // Permit and Transfer exchange asset from buyer to TDSContractFactory
        SafeERC20.safeTransferFrom(
            IERC20(tdsContract.exchangeAsset),
            tdsContract.buyer,
            address(this),
            tdsContract.getTotalPremiumByExchangeAsset()
        );

        _tdsContracts[tdsContractId] = tdsContract;
        emit TDSContractCreated(tdsContractId, tdsContract);
    }

    /// @dev Make a preimium transfer to seller
    /// @notice Check for next payment time
    /// @notice TDSContractFactory now holding the buyer all premium
    ///         any account can trigger this function to make a transfer
    function executeTDSContractTransferPremium(
        uint256 tdsContractId
    ) external override mustOpen(tdsContractId) {
        TDSTypes.TDSContract storage tdsContract = _tdsContracts[tdsContractId];

        // Verify the remaining payment times
        if (tdsContract.remainPaymentTimes == 0)
            revert AlreadyPayAllPremium(tdsContractId);

        // Verify next payment interval
        uint256 nextPaymentDate = tdsContract.getNextPaymentDate();

        // Verify next payment timestamp with current timestamp
        if (nextPaymentDate <= block.timestamp) {
            // transfer
            SafeERC20.safeTransfer(
                IERC20(tdsContract.exchangeAsset),
                tdsContract.seller,
                tdsContract.getPremiumPerPaymentByExchangeAsset()
            );
            emit TDSContractPreimumTransfered(
                tdsContractId,
                tdsContract.buyer,
                tdsContract.seller,
                tdsContract.premiumPerPayment
            );

            // Decrease remain payment times
            tdsContract.remainPaymentTimes -= 1;

            if (tdsContract.remainPaymentTimes == 0) {
                // Repay concordUSD after finish all payment duty
                try
                    IPortfolio(tdsContract.sellerPortfolio).executeRepay(
                        tdsContract.notional
                    )
                {
                    tdsContract.status = TDSTypes.STATUS_EXPIRE;
                    emit TDSContractRepaid(
                        tdsContractId,
                        tdsContract.sellerPortfolio,
                        tdsContract.notional
                    );
                } catch Error(string memory errorMessage) {
                    revert ExecuteRepayError(errorMessage);
                } catch (bytes memory reason) {
                    revert ExecuteRepayError(string(reason));
                }
            }
        } else {
            revert NotReachPaymentDateYet(tdsContractId);
        }
    }

    /// @dev Execute contract settlement procedure in case of default
    /// @notice Check reference event and deafault trigger against proof
    /// @notice A settement proceduce must be chosen prior to creating an outstanding contract
    function executeTDSContractSettlement(
        uint256 tdsContractId,
        bytes memory proof
    ) external override mustOpen(tdsContractId) {
        TDSTypes.TDSContract storage tdsContract = _tdsContracts[tdsContractId];
        IReferenceEvent refEvent = IReferenceEvent(
            _eventFactory.getReferenceEventById(tdsContract.referenceEvent)
        );

        // Verify Proof Sanity data
        if (!refEvent.verifyProofSanity(proof)) revert InvalidProof();

        // Check for relavent settlement procedure
        if (refEvent.eventType() == EventTypes.EVENT_TYPE_ASSET_LEVEL) {
            if (tdsContract.settlementType == 1) {
                _executeParametricSettlementProcedure(
                    tdsContract,
                    IAssetLevelEvent(address(refEvent)),
                    proof
                );
            }
        }
    }

    /// @dev Execute parametric settlement procedure
    function _executeParametricSettlementProcedure(
        TDSTypes.TDSContract storage tdsContract,
        IAssetLevelEvent assetLevelEvent,
        bytes memory proof
    ) internal {
        uint80 roundId = assetLevelEvent.getRoundId(proof);
        (
            ,
            address asset,
            uint256 triggerValue,
            uint8 triggerDecimal
        ) = assetLevelEvent.getAssetAndTriggerValue(tdsContract.defaultTrigger);

        try _priceOracle.getDataByRoundId(asset, roundId) returns (
            int256 answer,
            uint256,
            uint256 updatedAt,
            uint80,
            uint8 answerDecimal
        ) {
            // Verify contract endtime with given proof
            uint64 endDate = tdsContract.startDate + tdsContract.duration;
            if (
                uint64(updatedAt) > endDate ||
                uint64(updatedAt) < tdsContract.startDate
            ) revert InvalidPriceOracleTime();

            // Convert proof answer and trigger value to the same decimal
            uint256 convertedAnswer = answer > 0 ? uint256(answer) : 0;
            if (triggerDecimal > answerDecimal) {
                convertedAnswer *= 10 ** (triggerDecimal - answerDecimal);
            } else if (triggerDecimal < answerDecimal) {
                triggerValue *= 10 ** (answerDecimal - triggerDecimal);
            }

            // Verify converted answer against trigger value
            if (convertedAnswer < triggerValue) {
                _executeTDSContractDefault(
                    tdsContract,
                    TDSTypes.STATUS_PARAMETRIC_ORACLE_DEFAULT
                );
            } else {
                revert TDSContractNotDefault(tdsContract.id);
            }
        } catch Error(string memory errorMessage) {
            revert InvalidPriceOracleRoundId(errorMessage);
        } catch (bytes memory reason) {
            revert InvalidPriceOracleRoundId(string(reason));
        }
    }

    /// @dev Update contract state if it's defaulted
    function _executeTDSContractDefault(
        TDSTypes.TDSContract storage tdsContract,
        uint8 newStatus
    ) internal {
        tdsContract.status = newStatus;
        emit TDSContractDefault(
            tdsContract.id,
            tdsContract.referenceEvent,
            tdsContract.status,
            tdsContract.defaultTrigger
        );
    }

    /// @dev Provide Concord Signature as 2FA confirmation for contract default
    function executeMultiSignConfirm(
        uint256 tdsContractId,
        bytes calldata multiSign
    ) external {
        //TODO: implement
    }

    /// @dev Buyer claim payment if contract is defaulted
    function executeClaimPaymentWhenDefault(
        uint256 tdsContractId
    ) external override {
        // Verify contract status
        if (_tdsContracts[tdsContractId].status != TDSTypes.STATUS_DEFAULT)
            revert TDSContractNotDefault(tdsContractId);

        TDSTypes.TDSContract storage tdsContract = _tdsContracts[tdsContractId];
        // Transfer exchange asset in collateral list from seller portfolio to buyer
        try
            IPortfolio(tdsContract.sellerPortfolio)
                .executeTransferCollateralAsset(
                    tdsContract.exchangeAsset,
                    tdsContract.buyer,
                    tdsContract.getNotionalByExchangeAsset()
                )
        returns (bool result) {
            if (result == false) {
                revert ClaimPaymentWhenDefaultError(
                    "Failed to claim collateral asset"
                );
            }
            emit TDSContractClaimedPaymentWhenDefault(
                tdsContractId,
                tdsContract.exchangeAsset,
                tdsContract.buyer,
                tdsContract.seller,
                tdsContract.notional
            );
        } catch Error(string memory errorMessage) {
            revert ClaimPaymentWhenDefaultError(errorMessage);
        } catch (bytes memory reason) {
            revert ClaimPaymentWhenDefaultError(string(reason));
        }

        // Repay concordUSD after claiming default payment
        try
            IPortfolio(tdsContract.sellerPortfolio).executeRepay(
                tdsContract.notional
            )
        {
            tdsContract.status = TDSTypes.STATUS_DEFAULT_PAID; // finish all terms duty in case of default

            emit TDSContractRepaid(
                tdsContractId,
                tdsContract.sellerPortfolio,
                tdsContract.notional
            );
        } catch Error(string memory errorMessage) {
            revert ExecuteRepayError(errorMessage);
        } catch (bytes memory reason) {
            revert ExecuteRepayError(string(reason));
        }
    }
}

// File src/tds/TDSContractBuilder.sol
pragma solidity ^0.8.17;

/// @title TDSContractBuiler
/// @notice build term and sign on chain, for testing purpose
contract TDSContractBuilder {
    IPortfolioFactory public immutable portfolioFactory;
    TDSContractFactory public immutable tdsContractFactory;

    constructor(address portfolioFactory_, address tdsContractFactory_) {
        portfolioFactory = IPortfolioFactory(portfolioFactory_);
        tdsContractFactory = TDSContractFactory(tdsContractFactory_);
    }

    function buildTDSTermBuyRequestHash(
        uint64 requestExpire,
        uint64 duration,
        uint64 paymentInterval,
        uint32 referenceEvent,
        uint128 notional,
        uint128 spread,
        address exchangeAsset,
        bytes memory defaultTrigger,
        address buyer,
        uint256 nonce
    ) external view returns (bytes32) {
        TDSTypes.TDSTermBuyRequest memory tdsTerm;
        tdsTerm.baseRequest.requestExpire = requestExpire;
        tdsTerm.baseRequest.duration = duration;
        tdsTerm.baseRequest.paymentInterval = paymentInterval;
        tdsTerm.baseRequest.referenceEvent = referenceEvent;
        tdsTerm.baseRequest.recoveryRate = 0;
        tdsTerm.baseRequest.notional = notional;
        tdsTerm.baseRequest.spread = spread;
        tdsTerm.baseRequest.exchangeAsset = exchangeAsset;
        tdsTerm.baseRequest.settlementType = 1;
        tdsTerm.baseRequest.defaultTrigger = defaultTrigger;
        tdsTerm.buyer = buyer;
        tdsTerm.nonce = nonce;
        return tdsContractFactory.getTdsTermBuyRequestHash(tdsTerm);
    }

    function buildTDSTermBuyRequest(
        uint64 requestExpire,
        uint64 duration,
        uint64 paymentInterval,
        uint32 referenceEvent,
        uint128 notional,
        uint128 spread,
        address exchangeAsset,
        bytes memory defaultTrigger,
        address buyer,
        uint256 nonce
    ) external pure returns (bytes memory) {
        TDSTypes.TDSTermBuyRequest memory tdsTerm;
        tdsTerm.baseRequest.requestExpire = requestExpire;
        tdsTerm.baseRequest.duration = duration;
        tdsTerm.baseRequest.paymentInterval = paymentInterval;
        tdsTerm.baseRequest.referenceEvent = referenceEvent;
        tdsTerm.baseRequest.recoveryRate = 0;
        tdsTerm.baseRequest.notional = notional;
        tdsTerm.baseRequest.spread = spread;
        tdsTerm.baseRequest.exchangeAsset = exchangeAsset;
        tdsTerm.baseRequest.settlementType = 1;
        tdsTerm.baseRequest.defaultTrigger = defaultTrigger;
        tdsTerm.buyer = buyer;
        tdsTerm.nonce = nonce;
        return abi.encode(tdsTerm);
    }

    function buildTDSTermSellRequest(
        uint64 requestExpire,
        uint64 duration,
        uint64 paymentInterval,
        uint32 referenceEvent,
        uint128 notional,
        uint128 spread,
        address exchangeAsset,
        bytes memory defaultTrigger,
        address seller,
        uint256 sellerPortfolioId,
        bool isPersist,
        uint256 nonce
    ) external view returns (bytes32) {
        TDSTypes.TDSTermSellRequest memory tdsTerm;
        tdsTerm.baseRequest.requestExpire = requestExpire;
        tdsTerm.baseRequest.duration = duration;
        tdsTerm.baseRequest.paymentInterval = paymentInterval;
        tdsTerm.baseRequest.referenceEvent = referenceEvent;
        tdsTerm.baseRequest.recoveryRate = 0;
        tdsTerm.baseRequest.notional = notional;
        tdsTerm.baseRequest.spread = spread;
        tdsTerm.baseRequest.exchangeAsset = exchangeAsset;
        tdsTerm.baseRequest.settlementType = 1;
        tdsTerm.baseRequest.defaultTrigger = defaultTrigger;
        tdsTerm.seller = seller;
        tdsTerm.sellerPortfolio = portfolioFactory.getPortfolioById(
            seller,
            sellerPortfolioId
        );
        tdsTerm.isPersist = isPersist;
        tdsTerm.nonce = nonce;
        return tdsContractFactory.getTdsTermSellRequestHash(tdsTerm);
    }

    function buildTDSTermSellRequestHash(
        uint64 requestExpire,
        uint64 duration,
        uint64 paymentInterval,
        uint32 referenceEvent,
        uint128 notional,
        uint128 spread,
        address exchangeAsset,
        bytes memory defaultTrigger,
        address seller,
        uint256 sellerPortfolioId,
        bool isPersist,
        uint256 nonce
    ) external view returns (bytes memory) {
        TDSTypes.TDSTermSellRequest memory tdsTerm;
        tdsTerm.baseRequest.requestExpire = requestExpire;
        tdsTerm.baseRequest.duration = duration;
        tdsTerm.baseRequest.paymentInterval = paymentInterval;
        tdsTerm.baseRequest.referenceEvent = referenceEvent;
        tdsTerm.baseRequest.recoveryRate = 0;
        tdsTerm.baseRequest.notional = notional;
        tdsTerm.baseRequest.spread = spread;
        tdsTerm.baseRequest.exchangeAsset = exchangeAsset;
        tdsTerm.baseRequest.settlementType = 1;
        tdsTerm.baseRequest.defaultTrigger = defaultTrigger;
        tdsTerm.seller = seller;
        tdsTerm.sellerPortfolio = portfolioFactory.getPortfolioById(
            seller,
            sellerPortfolioId
        );
        tdsTerm.isPersist = isPersist;
        tdsTerm.nonce = nonce;
        return abi.encode(tdsTerm);
    }
}