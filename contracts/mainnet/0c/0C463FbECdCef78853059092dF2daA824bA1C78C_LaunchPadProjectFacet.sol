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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausableInternal } from './IPausableInternal.sol';

interface IPausable is IPausableInternal {
    /**
     * @notice query whether contract is paused
     * @return status whether contract is paused
     */
    function paused() external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IPausableInternal {
    error Pausable__Paused();
    error Pausable__NotPaused();

    event Paused(address account);
    event Unpaused(address account);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausable } from './IPausable.sol';
import { PausableInternal } from './PausableInternal.sol';

/**
 * @title Pausable security control module.
 */
abstract contract Pausable is IPausable, PausableInternal {
    /**
     * @inheritdoc IPausable
     */
    function paused() external view virtual returns (bool status) {
        status = _paused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IPausableInternal } from './IPausableInternal.sol';
import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal is IPausableInternal {
    modifier whenNotPaused() {
        if (_paused()) revert Pausable__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused()) revert Pausable__NotPaused();
        _;
    }

    /**
     * @notice query whether contract is paused
     * @return status whether contract is paused
     */
    function _paused() internal view virtual returns (bool status) {
        status = PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        delete PausableStorage.layout().paused;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IReentrancyGuard } from './IReentrancyGuard.sol';
import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard is IReentrancyGuard {
    uint256 internal constant REENTRANCY_STATUS_LOCKED = 2;
    uint256 internal constant REENTRANCY_STATUS_UNLOCKED = 1;

    modifier nonReentrant() virtual {
        if (_isReentrancyGuardLocked()) revert ReentrancyGuard__ReentrantCall();
        _lockReentrancyGuard();
        _;
        _unlockReentrancyGuard();
    }

    /**
     * @notice returns true if the reentrancy guard is locked, false otherwise
     */
    function _isReentrancyGuardLocked() internal view virtual returns (bool) {
        return
            ReentrancyGuardStorage.layout().status == REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice lock functions that use the nonReentrant modifier
     */
    function _lockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_LOCKED;
    }

    /**
     * @notice unlock functions that use the nonReentrant modifier
     */
    function _unlockReentrancyGuard() internal virtual {
        ReentrancyGuardStorage.layout().status = REENTRANCY_STATUS_UNLOCKED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IPaymentModule } from "./IPaymentModule.sol";

interface ICrossPaymentModule {
    struct CrossPaymentSignatureInput {
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
        bytes signature;
    }

    struct ProcessCrossPaymentOutput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address spender;
        uint256 destinationChainId;
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
    }

    function updateSignerAddress(address newSignerAddress) external;
    function processCrossPayment(
        IPaymentModule.ProcessPaymentInput memory paymentInput,
        address spender,
        uint256 destinationChainId
    ) external payable returns (uint256);
    function spendCrossPaymentSignature(address spender, ProcessCrossPaymentOutput memory output, bytes memory signature) external;
    function getSignerAddress() external view returns (address);
    function getCrossPaymentOutputByIndex(uint256 paymentIndex) external view returns (ProcessCrossPaymentOutput memory);
    function prefixedMessage(bytes32 hash) external pure returns (bytes32);
    function getHashedMessage(ProcessCrossPaymentOutput memory output) external pure returns (bytes32);
    function recoverSigner(bytes32 message, bytes memory signature) external pure returns (address);
    function checkSignature(ProcessCrossPaymentOutput memory output, bytes memory signature) external view;
    function getChainID() external view returns (uint256);

    /** EVENTS */
    event CrossPaymentProcessed(uint256 indexed previousBlock, uint256 indexed paymentIndex);
    event CrossPaymentSignatureSpent(uint256 indexed previousBlock, uint256 indexed sourceChainId, uint256 indexed paymentIndex);
    event SignerAddressUpdated(address indexed oldSigner, address indexed newSigner);

    /** ERRORS */
    error ProcessCrossPaymentError(string errorMessage);
    error CheckSignatureError(string errorMessage);
    error ProcessCrossPaymentSignatureError(string errorMessage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IPaymentModule {
    enum PaymentMethod {
        NATIVE,
        USD,
        ALTCOIN
    }

    enum PaymentType {
        NATIVE,
        GIFT,
        CROSSCHAIN
    }

    struct AcceptedToken {
        string name;
        PaymentMethod tokenType;
        address token;
        address router;
        bool isV2Router;
        uint256 slippageTolerance;
    }

    struct ProcessPaymentInput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address referrer;
        address user;
        address tokenAddress;
    }

    struct ProcessPaymentOutput {
        ProcessPaymentInput processPaymentInput;
        uint256 usdPrice;
        uint256 paymentAmount;
        uint256 burnedAmount;
        uint256 treasuryShare;
        uint256 referrerShare;
    }

    struct ProcessCrossPaymentOutput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address payer;
        address spender;
        uint256 sourceChainId;
        uint256 destinationChainId;
    }

    // solhint-disable-next-line func-name-mixedcase
    function PAYMENT_PROCESSOR_ROLE() external pure returns (bytes32);
    function adminWithdraw(address tokenAddress, uint256 amount, address treasury) external;
    function setUsdToken(address newUsdToken) external;
    function setRouterAddress(address newRouter) external;
    function addAcceptedToken(AcceptedToken memory acceptedToken) external;
    function removeAcceptedToken(address tokenAddress) external;
    function updateAcceptedToken(AcceptedToken memory acceptedToken) external;
    function setV3PoolFeeForTokenNative(address token, uint24 poolFee) external;
    function getUsdToken() external view returns (address);
    function processPayment(ProcessPaymentInput memory params) external payable returns (uint256);
    function getPaymentByIndex(uint256 paymentIndex) external view returns (ProcessPaymentOutput memory);
    function getQuoteTokenPrice(address token0, address token1) external view returns (uint256 price);
    function getV3PoolFeeForTokenWithNative(address token) external view returns (uint24);
    function isV2Router() external view returns (bool);
    function getRouterAddress() external view returns (address);
    function getAcceptedTokenByAddress(address tokenAddress) external view returns (AcceptedToken memory);
    function getAcceptedTokens() external view returns (address[] memory);

    /** EVENTS */
    event TokenBurned(uint256 indexed tokenBurnedLastBlock, address indexed tokenAddress, uint256 amount);
    event PaymentProcessed(uint256 indexed previousBlock, uint256 indexed paymentIndex);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);

    /** ERRORS */
    error ProcessPaymentError(string errorMessage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibCommonConsts {
    uint256 internal constant BASIS_POINTS = 10_000;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
        INNER_STRUCT is used for storing inner struct in mappings within diamond storage
     */
    bytes32 internal constant INNER_STRUCT = keccak256("floki.common.consts.inner.struct");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISwapRouterV3 } from "../../interfaces/ISwapRouterV3.sol";
import { IUniswapV3Pool } from "../../interfaces/IUniswapV3Pool.sol";

library LibSwapTokens {
    using SafeERC20 for IERC20;

    function _swapEthForExactTokensV2(uint256 ethAmount, address token, uint256 amountOut, address router) internal {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(router).WETH();
        path[1] = address(token);
        IUniswapV2Router02(router).swapETHForExactTokens{ value: ethAmount }(amountOut, path, address(this), block.timestamp);
    }

    function _swapEthForExactTokensV3(uint256 ethAmount, address token, uint256 amountOut, address router, uint24 v3PoolFee) internal {
        ISwapRouterV3.ExactOutputSingleParams memory params = ISwapRouterV3.ExactOutputSingleParams({
            tokenIn: ISwapRouterV3(router).WETH9(),
            tokenOut: token,
            fee: v3PoolFee,
            recipient: address(this),
            amountOut: amountOut,
            amountInMaximum: ethAmount,
            sqrtPriceLimitX96: 0
        });
        uint256 amountIn = ISwapRouterV3(router).exactOutputSingle{ value: ethAmount }(params);

        if (amountIn < ethAmount) {
            ISwapRouterV3(router).refundETH();
        }
    }

    function _swapExactTokensForTokensV2(address inputToken, address outputToken, uint256 inputAmount, address treasury, address router) internal {
        address[] memory path = new address[](3);
        path[0] = inputToken;
        path[1] = IUniswapV2Router02(router).WETH();
        path[2] = outputToken;
        if (IERC20(inputToken).allowance(address(this), router) != 0) {
            IERC20(inputToken).safeApprove(router, 0);
        }
        IERC20(inputToken).safeApprove(router, inputAmount);

        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(inputAmount, 0, path, treasury, block.timestamp);
    }

    function _swapTokensForExactTokensV2(
        address inputToken,
        uint256 amountInMax,
        address outputToken,
        uint256 amountOut,
        address treasury,
        address router
    ) internal {
        address[] memory path = new address[](3);
        path[0] = inputToken;
        path[1] = IUniswapV2Router02(router).WETH();
        path[2] = outputToken;
        if (IERC20(inputToken).allowance(address(this), router) != 0) {
            IERC20(inputToken).safeApprove(router, 0);
        }

        IERC20(inputToken).safeApprove(router, amountInMax);
        IUniswapV2Router02(router).swapTokensForExactTokens(amountInMax, amountOut, path, treasury, block.timestamp);
    }

    function _swapExactTokensForTokensV3(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint24 inputTokenPoolFee,
        uint24 outputTokenPoolFee,
        address treasury,
        address router
    ) internal {
        if (IERC20(inputToken).allowance(address(this), router) != 0) {
            IERC20(inputToken).safeApprove(router, 0);
        }
        IERC20(inputToken).safeApprove(router, inputAmount);

        bytes memory path = abi.encodePacked(inputToken, inputTokenPoolFee, ISwapRouterV3(router).WETH9(), outputTokenPoolFee, outputToken);

        ISwapRouterV3.ExactInputParams memory params = ISwapRouterV3.ExactInputParams({
            path: path,
            recipient: treasury,
            amountIn: inputAmount,
            amountOutMinimum: 0
        });

        ISwapRouterV3(router).exactInput(params);
    }

    function _swapTokensForExactTokensV3(
        address inputToken,
        uint256 amountInMax,
        address outputToken,
        uint256 amountOut,
        uint24 inputTokenPoolFee,
        uint24 outputTokenPoolFee,
        address treasury,
        address router
    ) internal {
        if (IERC20(inputToken).allowance(address(this), router) != 0) {
            IERC20(inputToken).safeApprove(router, 0);
        }
        IERC20(inputToken).safeApprove(router, amountInMax);

        bytes memory path = abi.encodePacked(outputToken, outputTokenPoolFee, ISwapRouterV3(router).WETH9(), inputTokenPoolFee, inputToken);

        ISwapRouterV3.ExactOutputParams memory params = ISwapRouterV3.ExactOutputParams({
            path: path,
            recipient: treasury,
            amountOut: amountOut,
            amountInMaximum: amountInMax
        });

        ISwapRouterV3(router).exactOutput(params);
    }

    function _getQuoteTokenPriceV2Weth(address token0, address token1, address router) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token0;
        uint256 token0Unit = 10 ** IERC20Metadata(token0).decimals();
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(token0Unit, path);

        return amounts[0];
    }
    function _getQuoteTokenPriceV2(address token0, address token1, address router) internal view returns (uint256) {
        address weth = IUniswapV2Router02(router).WETH();
        if (token0 == address(0)) {
            return _getQuoteTokenPriceV2Weth(weth, token1, router);
        } else if (token1 == address(0)) {
            return _getQuoteTokenPriceV2Weth(token0, weth, router);
        }

        address[] memory path = new address[](3);
        path[0] = token1;
        path[1] = IUniswapV2Router02(router).WETH();
        path[2] = token0;

        uint256 token0Unit = 10 ** IERC20Metadata(token0).decimals();
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(token0Unit, path);

        return amounts[0];
    }

    function _shiftRightBits(uint256 value) internal pure returns (uint256 result, uint256 bits) {
        uint256 maxNumber = 1 << 128;
        result = value;
        if (result >= maxNumber) {
            for (bits = 1; bits <= 96; bits++) {
                result = (value >> bits);
                if (result < maxNumber) {
                    return (result, bits);
                }
            }
        }
    }

    function _getTokenPriceFromSqrtX96(uint256 sqrtPrice) internal pure returns (uint256 price) {
        (uint256 bitResult, uint256 bits) = _shiftRightBits(sqrtPrice);
        uint256 leftBits = (96 - bits) * 2;
        price = (bitResult * bitResult);
        (price, bits) = _shiftRightBits(price);
        leftBits -= bits;
        price = (price * 1e18) >> leftBits;
    }

    function _getQuoteTokenPriceV3Weth(address token, uint24 poolFee, address router) internal view returns (uint256, uint256) {
        address weth = ISwapRouterV3(router).WETH9();
        address factory = ISwapRouterV3(router).factory();
        address pool = ISwapRouterV3(factory).getPool(weth, token, poolFee);
        uint256 tokenDecimals = IERC20Metadata(token).decimals();

        address poolToken0 = IUniswapV3Pool(pool).token0();
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        uint256 tokenPerWeth = _getTokenPriceFromSqrtX96(sqrtPriceX96);
        uint256 wethPerToken = (10 ** (18 + tokenDecimals)) / tokenPerWeth;

        if (poolToken0 == weth) {
            return (tokenPerWeth, wethPerToken);
        } else {
            return (wethPerToken, tokenPerWeth);
        }
    }

    function _getQuoteTokenPriceV3(address token0, address token1, uint24 token0PoolFee, uint24 token1PoolFee, address router) internal view returns (uint256) {
        uint256 wethPerToken;
        uint256 tokenPerWeth;
        if (token0 == address(0)) {
            (tokenPerWeth, ) = _getQuoteTokenPriceV3Weth(token1, token1PoolFee, router);
            return tokenPerWeth;
        } else if (token1 == address(0)) {
            (, wethPerToken) = _getQuoteTokenPriceV3Weth(token0, token0PoolFee, router);
            return wethPerToken;
        }

        (, wethPerToken) = _getQuoteTokenPriceV3Weth(token0, token0PoolFee, router);
        (tokenPerWeth, ) = _getQuoteTokenPriceV3Weth(token1, token1PoolFee, router);

        return (wethPerToken * tokenPerWeth) / 1e18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ISwapRouterV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    // solhint-disable-next-line func-name-mixedcase
    function WETH9() external pure returns (address);

    function factory() external pure returns (address);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    function refundETH() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IUniswapV3Pool {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Pausable } from "@solidstate/contracts/security/pausable/Pausable.sol";
import { ReentrancyGuard } from "@solidstate/contracts/security/reentrancy_guard/ReentrancyGuard.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ILaunchPadFactory } from "../interfaces/ILaunchPadFactory.sol";
import { ILaunchPadQuerier } from "../interfaces/ILaunchPadQuerier.sol";
import { ILaunchPadProject, ILaunchPadCommon } from "../interfaces/ILaunchPadProject.sol";
import { LibLaunchPadProjectStorage } from "../libraries/LibLaunchPadProjectStorage.sol";
import { LibCommonConsts } from "../../common/admin/libraries/LibCommonConsts.sol";
import { IPaymentModule } from "../../common/admin/interfaces/IPaymentModule.sol";
import { LibSwapTokens } from "../../common/admin/libraries/LibSwapTokens.sol";

contract LaunchPadProjectFacet is ILaunchPadProject, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    function buyTokens(uint256 tokenAmount) external payable override whenNotPaused whenSaleInProgress(6) nonReentrant {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();

        if (ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount == 0) {
            ds.investors.push(msg.sender);
        }

        ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount = ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount.add(tokenAmount);
        ds.totalTokensSold = ds.totalTokensSold.add(tokenAmount);

        require(
            ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount <= ds.launchPadInfo.maxInvestPerWallet,
            "LaunchPad:buyTokens: Max invest per wallet reached"
        );
        require(ds.totalTokensSold <= ds.launchPadInfo.fundTarget.hardCap, "LaunchPad:buyTokens: Hard cap reached");

        _buyTokens(tokenAmount);
    }

    function buyTokensWithSupercharger(
        ILaunchPadProject.BuyTokenInput memory input
    ) external payable override whenNotPaused whenSaleInProgress(getCurrentTier()) onlySupercharger nonReentrant {
        require(block.timestamp <= input.deadline, "LaunchPad:checkSignature: Signature expired");
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();

        require(input.tier <= getCurrentTier(), "LaunchPad:buyTokensWithSupercharger: User not allowed in this tier");

        // Validate signature and nonce
        require(ds.buyTokenNonces[msg.sender].length == input.nonce, "LaunchPad:buyTokensWithSupercharger: Nonce already used");
        ds.buyTokenNonces[msg.sender].push(input.nonce);
        checkSignature(msg.sender, input.tier, input.nonce, input.deadline, input.signature);

        if (ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount == 0) {
            ds.investors.push(msg.sender);
        }

        ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount = ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount + input.tokenAmount;
        ds.totalTokensSold = ds.totalTokensSold.add(input.tokenAmount);
        uint256 currentTier = getCurrentTier();
        uint256 purchasedInBasisPoint = ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount.mul(LibCommonConsts.BASIS_POINTS);

        require(purchasedInBasisPoint <= getMaxInvestPerWalletPerTier(currentTier), "LaunchPad:buyTokens: Max invest per wallet reached");
        require(ds.totalTokensSold <= getHardCapPerTier(currentTier), "LaunchPad:buyTokens: Hard cap reached");

        _buyTokens(input.tokenAmount);
    }

    function _buyTokens(uint256 tokenAmount) internal {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        uint256 cost = (tokenAmount * ds.launchPadInfo.price) / (10 ** tokenDecimals());
        // LaunchPad expects payment to be in native
        if (ds.launchPadInfo.paymentTokenAddress == address(0)) {
            require(msg.value == cost, "LaunchPad:buyTokens: Not enough ETH");
            ds.purchasedInfoByUser[msg.sender].paidTokenAmount = ds.purchasedInfoByUser[msg.sender].paidTokenAmount.add(cost);
        } else {
            // User wants to buyTokens with native
            if (msg.value > 0) {
                uint256 oldEthBalance = address(this).balance;
                address router = IPaymentModule(ds.launchPadFactory).getRouterAddress();
                bool isV2 = IPaymentModule(ds.launchPadFactory).isV2Router();
                if (isV2) {
                    LibSwapTokens._swapEthForExactTokensV2(msg.value, ds.launchPadInfo.paymentTokenAddress, cost, router);
                } else {
                    LibSwapTokens._swapEthForExactTokensV3(
                        msg.value,
                        ds.launchPadInfo.paymentTokenAddress,
                        cost,
                        router,
                        IPaymentModule(ds.launchPadFactory).getV3PoolFeeForTokenWithNative(ds.launchPadInfo.paymentTokenAddress)
                    );
                }
                // Refund leftover ETH
                uint256 weiToBeRefunded = msg.value - (oldEthBalance - address(this).balance);
                (bool success, ) = payable(msg.sender).call{ value: weiToBeRefunded }("");
                require(success, "Failed to refund leftover ETH");
            } else {
                IERC20Metadata paymentToken = IERC20Metadata(ds.launchPadInfo.paymentTokenAddress);
                require(paymentToken.allowance(msg.sender, address(this)) >= cost, "LaunchPad:buyTokens: Not enough allowance");
                paymentToken.safeTransferFrom(msg.sender, address(this), cost);
            }

            ds.purchasedInfoByUser[msg.sender].paidTokenAmount = ds.purchasedInfoByUser[msg.sender].paidTokenAmount.add(cost);
        }

        // Emit event
        ILaunchPadFactory(ds.launchPadFactory).addInvestorToLaunchPad(msg.sender);
        emit LibLaunchPadProjectStorage.TokensPurchased(msg.sender, tokenAmount);
    }

    function checkSignature(address wallet, uint256 tier, uint256 nonce, uint256 deadline, bytes memory signature) public view override {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        address signer = ILaunchPadQuerier(ds.launchPadFactory).getSignerAddress();
        bytes32 messageHash = _prefixed(keccak256(abi.encodePacked(wallet, tier, nonce, deadline)));
        address recoveredSigner = recoverSigner(messageHash, signature);
        require(signer == recoveredSigner, "LaunchPad:validSignature: Invalid signature");
    }

    function claimTokens() external override whenNotPaused whenSaleEnded nonReentrant {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();

        require(ds.launchPadInfo.tokenAddress != address(0), "LaunchPad:claimTokens: Token address is 0 - token does not exist");

        uint256 claimableAmount = getTokensAvailableToBeClaimed(msg.sender);
        if (claimableAmount == 0) return;

        ds.totalTokensClaimed = ds.totalTokensClaimed.add(claimableAmount);
        ds.purchasedInfoByUser[msg.sender].claimedTokenAmount = ds.purchasedInfoByUser[msg.sender].claimedTokenAmount.add(claimableAmount);

        // Transfer tokens to buyer
        IERC20Metadata token = IERC20Metadata(ds.launchPadInfo.tokenAddress);
        require(token.balanceOf(address(this)) >= claimableAmount, "LaunchPad:claimTokens: Not enough tokens in contract");
        token.safeTransfer(msg.sender, claimableAmount);
    }

    function getCurrentTier() public view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        uint256[] memory headstarts = ILaunchPadQuerier(ds.launchPadFactory).getSuperChargerHeadstarts();
        if (ds.launchPadInfo.startTimestamp < block.timestamp) return headstarts.length; // last tier
        uint256 secondsLeft = ds.launchPadInfo.startTimestamp - block.timestamp;
        for (uint256 i = 0; i < headstarts.length; i++) {
            if (secondsLeft > headstarts[i]) return i;
        }
        return 0; // not active yet
    }

    function getFeeShare() public view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        uint256 totalRaised = getTotalRaised();
        return totalRaised.mul(ds.feePercentage).div(LibCommonConsts.BASIS_POINTS);
    }

    function getHardCapPerTier(uint256 tier) public view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        uint256 tokensPerc = ILaunchPadQuerier(ds.launchPadFactory).getSuperChargerTokensPercByTier(tier);
        return (ds.launchPadInfo.fundTarget.hardCap * tokensPerc) / LibCommonConsts.BASIS_POINTS;
    }

    function getMaxInvestPerWalletPerTier(uint256 tier) public view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        uint256 multiplier = ILaunchPadQuerier(ds.launchPadFactory).getSuperChargerMultiplierByTier(tier);
        return (ds.launchPadInfo.maxInvestPerWallet * multiplier);
    }

    function getNextNonce(address user) external view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.buyTokenNonces[user].length;
    }

    function getTotalRaised() public view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.totalTokensSold.mul(ds.launchPadInfo.price).div(10 ** tokenDecimals());
    }

    function getLaunchPadAddress() external view override returns (address) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.launchPadFactory;
    }

    function getLaunchPadInfo() external view override returns (ILaunchPadCommon.LaunchPadInfo memory) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.launchPadInfo;
    }

    function getProjectOwnerRole() external pure override returns (bytes32) {
        return LibLaunchPadProjectStorage.LAUNCHPAD_OWNER_ROLE;
    }

    function getReleaseSchedule() external view override returns (ILaunchPadCommon.ReleaseScheduleV2[] memory) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.releaseScheduleV2;
    }

    function getReleasedTokensPercentage() public view override returns (uint256 releasedPerc) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        uint256 releaseScheduleV2Length = ds.releaseScheduleV2.length;
        for (uint256 i = 0; i < releaseScheduleV2Length; i++) {
            if (ds.releaseScheduleV2[i].timestamp <= block.timestamp) {
                releasedPerc += ds.releaseScheduleV2[i].percent;
            } else if (i > 0 && ds.releaseScheduleV2[i].isVesting && ds.releaseScheduleV2[i - 1].timestamp <= block.timestamp) {
                releasedPerc +=
                    (ds.releaseScheduleV2[i].percent * (block.timestamp - ds.releaseScheduleV2[i - 1].timestamp)) /
                    (ds.releaseScheduleV2[i].timestamp - ds.releaseScheduleV2[i - 1].timestamp);
                break;
            }
        }
        return releasedPerc;
    }

    function getTokensAvailableToBeClaimed(address user) public view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        if (ds.launchPadInfo.tokenAddress == address(0)) return 0;
        uint256 releasedPerc = getReleasedTokensPercentage();
        if (releasedPerc == LibCommonConsts.BASIS_POINTS)
            return ds.purchasedInfoByUser[user].purchasedTokenAmount.sub(ds.purchasedInfoByUser[user].claimedTokenAmount);
        if (releasedPerc == 0) return 0;

        uint256 originalTokenDecimals = tokenDecimals();
        uint256 actualTokenDecimals = IERC20Metadata(ds.launchPadInfo.tokenAddress).decimals();
        uint256 claimableAmount = ds.purchasedInfoByUser[user].purchasedTokenAmount.mul(releasedPerc).div(LibCommonConsts.BASIS_POINTS);
        claimableAmount = claimableAmount.mul(10 ** actualTokenDecimals).div(10 ** originalTokenDecimals);

        return claimableAmount.sub(ds.purchasedInfoByUser[user].claimedTokenAmount);
    }

    function getTokenCreationDeadline() external view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.launchPadInfo.tokenCreationDeadline;
    }

    function getPurchasedInfoByUser(address user) external view override returns (PurchasedInfo memory) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.purchasedInfoByUser[user];
    }

    function getInvestorsLength() external view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.investors.length;
    }

    function getAllInvestors() external view override returns (address[] memory) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.investors;
    }

    function getInvestorAddressByIndex(uint256 index) external view override returns (address) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.investors[index];
    }

    function isSuperchargerEnabled() external view override returns (bool) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.isSuperchargerEnabled;
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function _prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(bytes32 message, bytes memory signature) public pure returns (address) {
        require(signature.length == 65, "LaunchPad:recoverSigner: Signature length is invalid");
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return ecrecover(message, v, r, s);
    }

    function _refundPaymentToken(address user, uint256 tokenAmount, uint256 refundAmount, uint256 penaltyFee) private {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();

        ds.purchasedInfoByUser[user].purchasedTokenAmount -= tokenAmount;
        ds.purchasedInfoByUser[user].paidTokenAmount -= refundAmount;

        uint256 _refundableAmount = refundAmount - penaltyFee;
        require(_refundableAmount > 0, "LaunchPad:refund: refundable amount must be greater than zero");

        if (ds.launchPadInfo.paymentTokenAddress == address(0)) {
            // We specifically ignore this return value.
            (bool success, ) = payable(user).call{ value: _refundableAmount }("");
            require(success, "LaunchPad:refund: Failed to transfer ETH to buyer");
        } else {
            IERC20Metadata paymentToken = IERC20Metadata(ds.launchPadInfo.paymentTokenAddress);
            paymentToken.safeTransfer(user, _refundableAmount);
        }

        emit LibLaunchPadProjectStorage.TokensRefunded(user, tokenAmount);
    }

    function refund(uint256 tokenAmount) external override whenSaleInProgress(6) nonReentrant {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        require(ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount >= tokenAmount, "LaunchPad:refund: Amount must be less than ds.purchasedAmountByUser");
        require(block.timestamp <= ds.launchPadInfo.startTimestamp.add(ds.launchPadInfo.refundInfo.expireDuration), "LaunchPad:refund: Refund time has passed");

        uint256 refundAmount = tokenAmount.mul(ds.launchPadInfo.price).div(10 ** tokenDecimals());
        require(
            refundAmount <= ds.purchasedInfoByUser[msg.sender].paidTokenAmount,
            "LaunchPad:refund: Amount of paymentToken must be less than ds.paidTokenAmountByUser"
        );

        uint256 penaltyFee = refundAmount.mul(ds.launchPadInfo.refundInfo.penaltyFeePercent).div(LibCommonConsts.BASIS_POINTS);

        _refundPaymentToken(msg.sender, tokenAmount, refundAmount, penaltyFee);
    }

    function refundOnTokenCreationExpired(uint256 tokenAmount) external override whenSaleEnded nonReentrant {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        require(ds.launchPadInfo.tokenAddress == address(0), "LaunchPad:refundOnTokenCreationExpired: Token has been created");
        require(block.timestamp > ds.launchPadInfo.tokenCreationDeadline, "LaunchPad:refundOnTokenCreationExpired: Token creation deadline has not passed");
        require(
            ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount >= tokenAmount,
            "LaunchPad:refundOnTokenCreationExpired: Amount must be less than ds.purchasedAmountByUser"
        );

        uint256 refundAmount = tokenAmount.mul(ds.launchPadInfo.price).div(10 ** tokenDecimals());
        require(refundAmount <= ds.purchasedInfoByUser[msg.sender].paidTokenAmount, "LaunchPad:refundOnTokenCreationExpired: Amount of paymentToken too big");
        _refundPaymentToken(msg.sender, tokenAmount, refundAmount, 0);
    }

    function refundOnSoftCapFailure() external override whenSaleEnded nonReentrant {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        require(ds.totalTokensSold < ds.launchPadInfo.fundTarget.softCap, "LaunchPad:refundOnSoftCapFailure: Soft cap has been reached");
        _refundPaymentToken(msg.sender, ds.purchasedInfoByUser[msg.sender].purchasedTokenAmount, ds.purchasedInfoByUser[msg.sender].paidTokenAmount, 0);
    }

    function tokenDecimals() public view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ILaunchPadQuerier(ds.launchPadFactory).getLaunchPadTokenInfo(address(this)).decimals;
    }

    function totalTokensSold() external view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.totalTokensSold;
    }

    function totalTokensClaimed() external view override returns (uint256) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        return ds.totalTokensClaimed;
    }

    /** MODIFIER */

    modifier onlySupercharger() {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        require(ds.isSuperchargerEnabled, "LaunchPad:onlySupercharger: Supercharger is not enabled");
        _;
    }

    modifier whenSaleInProgress(uint256 tier) {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        require(tier > 0, "LaunchPad:whenSaleInProgress: Tier must be greater than 0");
        uint256 headstart = ILaunchPadQuerier(ds.launchPadFactory).getSuperChargerHeadstartByTier(tier);
        uint256 startTimestamp = ds.launchPadInfo.startTimestamp - headstart;
        require(
            block.timestamp >= startTimestamp && block.timestamp <= ds.launchPadInfo.startTimestamp.add(ds.launchPadInfo.duration),
            "Sale is outside of the duration"
        );
        _;
    }

    modifier whenSaleEnded() {
        LibLaunchPadProjectStorage.DiamondStorage storage ds = LibLaunchPadProjectStorage.diamondStorage();
        require(block.timestamp > ds.launchPadInfo.startTimestamp.add(ds.launchPadInfo.duration), "Sale is still ongoing");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ILaunchPadCommon {
    enum LaunchPadType {
        FlokiPadCreatedBefore,
        FlokiPadCreatedAfter
    }

    struct IdoInfo {
        bool enabled;
        address dexRouter;
        address pairToken;
        uint256 price;
        uint256 amountToList;
    }

    struct RefundInfo {
        uint256 penaltyFeePercent;
        uint256 expireDuration;
    }

    struct FundTarget {
        uint256 softCap;
        uint256 hardCap;
    }

    struct ReleaseSchedule {
        uint256 timestamp;
        uint256 percent;
    }

    struct ReleaseScheduleV2 {
        uint256 timestamp;
        uint256 percent;
        bool isVesting;
    }

    struct CreateErc20Input {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 maxSupply;
        address owner;
        uint256 treasuryReserved;
    }

    struct LaunchPadInfo {
        address owner;
        address tokenAddress;
        address paymentTokenAddress;
        uint256 price;
        FundTarget fundTarget;
        uint256 maxInvestPerWallet;
        uint256 startTimestamp;
        uint256 duration;
        uint256 tokenCreationDeadline;
        RefundInfo refundInfo;
        IdoInfo idoInfo;
    }

    struct CreateLaunchPadInput {
        LaunchPadType launchPadType;
        LaunchPadInfo launchPadInfo;
        ReleaseScheduleV2[] releaseSchedule;
        CreateErc20Input createErc20Input;
        address referrer;
        bool isSuperchargerEnabled;
        uint256 feePercentage;
        address paymentTokenAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";
import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ILaunchPadFactory {
    struct StoreLaunchPadInput {
        ILaunchPadCommon.LaunchPadType launchPadType;
        address launchPadAddress;
        address owner;
        address referrer;
    }

    function addInvestorToLaunchPad(address investor) external;
    function createLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory input) external payable;
    function createLaunchPadWithPaymentSignature(
        ILaunchPadCommon.CreateLaunchPadInput memory storeInput,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadProject {
    struct PurchasedInfo {
        uint256 purchasedTokenAmount;
        uint256 claimedTokenAmount;
        uint256 paidTokenAmount;
    }

    struct BuyTokenInput {
        uint256 tokenAmount;
        uint256 tier;
        uint256 nonce;
        uint256 deadline;
        bytes signature;
    }

    function buyTokens(uint256 tokenAmount) external payable;

    function buyTokensWithSupercharger(BuyTokenInput memory input) external payable;

    function checkSignature(address wallet, uint256 tier, uint256 nonce, uint256 deadline, bytes memory signature) external view;

    function claimTokens() external;

    function getAllInvestors() external view returns (address[] memory);

    function getCurrentTier() external view returns (uint256);

    function getFeeShare() external view returns (uint256);

    function getHardCapPerTier(uint256 tier) external view returns (uint256);

    function getInvestorAddressByIndex(uint256 index) external view returns (address);

    function getInvestorsLength() external view returns (uint256);

    function getLaunchPadAddress() external view returns (address);

    function getLaunchPadInfo() external view returns (ILaunchPadCommon.LaunchPadInfo memory);

    function getMaxInvestPerWalletPerTier(uint256 tier) external view returns (uint256);

    function getNextNonce(address user) external view returns (uint256);

    function getProjectOwnerRole() external view returns (bytes32);

    function getPurchasedInfoByUser(address user) external view returns (PurchasedInfo memory);

    function getReleasedTokensPercentage() external view returns (uint256);

    function getReleaseSchedule() external view returns (ILaunchPadCommon.ReleaseScheduleV2[] memory);

    function getTokensAvailableToBeClaimed(address user) external view returns (uint256);

    function getTokenCreationDeadline() external view returns (uint256);

    function getTotalRaised() external view returns (uint256);

    function isSuperchargerEnabled() external view returns (bool);

    function recoverSigner(bytes32 message, bytes memory signature) external view returns (address);

    function refund(uint256 tokenAmount) external;

    function refundOnSoftCapFailure() external;

    function refundOnTokenCreationExpired(uint256 tokenAmount) external;

    function tokenDecimals() external view returns (uint256);

    function totalTokensClaimed() external view returns (uint256);

    function totalTokensSold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadQuerier is ILaunchPadCommon {
    function LAUNCHPAD_PRODUCT_ID() external pure returns (bytes32);

    function getLaunchPadsPaginated(uint256 quantity, uint256 page) external view returns (address[] memory);

    function getLaunchPadsCount() external view returns (uint256);

    function getLaunchPadsByInvestorPaginated(address investor, uint256 quantity, uint256 page) external view returns (address[] memory);

    function getLaunchPadsByInvestorCount() external view returns (uint256);

    function getLaunchPadCountByOwner(address owner) external view returns (uint256);

    function getLaunchPadsByOwnerPaginated(address owner, uint256 quantity, uint256 page) external view returns (address[] memory);

    function getMaxTokenCreationDeadline() external view returns (uint256);

    function getSignerAddress() external view returns (address);

    function getSuperChargerHeadstartByTier(uint256 tier) external view returns (uint256);

    function getSuperChargerHeadstarts() external view returns (uint256[] memory);

    function getSuperChargerMultiplierByTier(uint256 tier) external view returns (uint256);

    function getSuperChargerTokensPercByTier(uint256 tier) external view returns (uint256);

    function getLaunchPadTokenInfo(address launchPadAddress) external view returns (CreateErc20Input memory createErc20Input);

    function getLaunchPadMaxDurationIncrement() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "../interfaces/ILaunchPadProject.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";

/// @notice storage for LaunchPads created by users

library LibLaunchPadProjectStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.launchpad.project.diamond.storage");
    bytes32 internal constant LAUNCHPAD_OWNER_ROLE = keccak256("LAUNCHPAD_OWNER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct DiamondStorage {
        ILaunchPadCommon.LaunchPadInfo launchPadInfo;
        address launchPadFactory;
        uint256 totalTokensSold;
        uint256 totalTokensClaimed;
        uint256 feePercentage; // in basis points 1e4
        bool feeShareCollected;
        bool isSuperchargerEnabled;
        ILaunchPadCommon.ReleaseSchedule[] releaseSchedule;
        ILaunchPadCommon.ReleaseScheduleV2[] releaseScheduleV2;
        mapping(address => ILaunchPadProject.PurchasedInfo) purchasedInfoByUser;
        address[] investors;
        mapping(address => uint256[]) buyTokenNonces;
    }

    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensRefunded(address indexed buyer, uint256 amount);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}