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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ILendingVault {

  /* ========== STRUCTS ========== */

  struct Borrower {
    // Boolean for whether borrower is approved to borrow from this vault
    bool approved;
    // Debt share of the borrower in this vault
    uint256 debt;
    // The last timestamp borrower borrowed from this vault
    uint256 lastUpdatedAt;
  }

  struct InterestRate {
    // Base interest rate which is the y-intercept when utilization rate is 0 in 1e18
    uint256 baseRate;
    // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
    uint256 multiplier;
    // Multiplier after hitting a specified utilization point (kink2) in 1e18
    uint256 jumpMultiplier;
    // Utilization point at which the interest rate is fixed in 1e18
    uint256 kink1;
    // Utilization point at which the jump multiplier is applied in 1e18
    uint256 kink2;
  }

  function totalAsset() external view returns (uint256);
  function totalAvailableAsset() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function lvTokenValue() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address borrower) external view returns (uint256);
  function depositNative(uint256 assetAmt, uint256 minSharesAmt) payable external;
  function deposit(uint256 assetAmt, uint256 minSharesAmt) external;
  function withdraw(uint256 sharesAmt, uint256 minAssetAmt) external;
  function borrow(uint256 assetAmt) external;
  function repay(uint256 repayAmt) external;
  function withdrawReserve(uint256 assetAmt) external;
  function updatePerformanceFee(uint256 newPerformanceFee) external;
  function updateInterestRate(InterestRate memory newInterestRate) external;
  function approveBorrower(address borrower) external;
  function revokeBorrower(address borrower) external;
  function updateKeeper(address keeper, bool approval) external;
  function emergencyRepay(uint256 repayAmt, address defaulter) external;
  function emergencyShutdown() external;
  function emergencyResume() external;
  function updateMaxCapacity(uint256 newMaxCapacity) external;
  function updateTreasury(address newTreasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IChainlinkOracle {
  function consult(address token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address token) external view returns (uint256 price);
  function addTokenPriceFeed(address token, address feed) external;
  function addTokenMaxDelay(address token, uint256 maxDelay) external;
  function addTokenMaxDeviation(address token, uint256 maxDeviation) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IGMXOracle {
  struct MarketPoolValueInfoProps {
    int256 poolValue;
    int256 longPnl;
    int256 shortPnl;
    int256 netPnl;

    uint256 longTokenAmount;
    uint256 shortTokenAmount;
    uint256 longTokenUsd;
    uint256 shortTokenUsd;

    uint256 totalBorrowingFees;
    uint256 borrowingFeePoolFactor;

    uint256 impactPoolAmount;
  }

  function getAmountsOut(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenIn,
    uint256 amountIn
  ) external view returns (uint256);

  function getAmountsIn(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenOut,
    uint256 amountsOut
  ) external view returns (uint256);

  function getMarketTokenInfo(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bytes32 pnlFactorType,
    bool maximize
  ) external view returns (
    int256,
    MarketPoolValueInfoProps memory
  );

  function getLpTokenReserves(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken
  ) external view returns (uint256, uint256);

  function getLpTokenValue(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);

  function getLpTokenAmount(
    uint256 givenValue,
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDeposit {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account depositing liquidity
  // @param receiver the address to send the liquidity tokens to
  // @param callbackContract the callback contract
  // @param uiFeeReceiver the ui fee receiver
  // @param market the market to deposit to
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
  }

  // @param initialLongTokenAmount the amount of long tokens to deposit
  // @param initialShortTokenAmount the amount of short tokens to deposit
  // @param minMarketTokens the minimum acceptable number of liquidity tokens
  // @param updatedAtBlock the block that the deposit was last updated at
  // sending funds back to the user in case the deposit gets cancelled
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  struct Numbers {
    uint256 initialLongTokenAmount;
    uint256 initialShortTokenAmount;
    uint256 minMarketTokens;
    uint256 updatedAtBlock;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  // @param shouldUnwrapNativeToken whether to unwrap the native token when
  struct Flags {
    bool shouldUnwrapNativeToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IEvent {
  struct Props {
    AddressItems addressItems;
    UintItems uintItems;
    IntItems intItems;
    BoolItems boolItems;
    Bytes32Items bytes32Items;
    BytesItems bytesItems;
    StringItems stringItems;
  }

  struct AddressItems {
    AddressKeyValue[] items;
    AddressArrayKeyValue[] arrayItems;
  }

  struct UintItems {
    UintKeyValue[] items;
    UintArrayKeyValue[] arrayItems;
  }

  struct IntItems {
    IntKeyValue[] items;
    IntArrayKeyValue[] arrayItems;
  }

  struct BoolItems {
    BoolKeyValue[] items;
    BoolArrayKeyValue[] arrayItems;
  }

  struct Bytes32Items {
    Bytes32KeyValue[] items;
    Bytes32ArrayKeyValue[] arrayItems;
  }

  struct BytesItems {
    BytesKeyValue[] items;
    BytesArrayKeyValue[] arrayItems;
  }

  struct StringItems {
    StringKeyValue[] items;
    StringArrayKeyValue[] arrayItems;
  }

  struct AddressKeyValue {
    string key;
    address value;
  }

  struct AddressArrayKeyValue {
    string key;
    address[] value;
  }

  struct UintKeyValue {
    string key;
    uint256 value;
  }

  struct UintArrayKeyValue {
    string key;
    uint256[] value;
  }

  struct IntKeyValue {
    string key;
    int256 value;
  }

  struct IntArrayKeyValue {
    string key;
    int256[] value;
  }

  struct BoolKeyValue {
    string key;
    bool value;
  }

  struct BoolArrayKeyValue {
    string key;
    bool[] value;
  }

  struct Bytes32KeyValue {
    string key;
    bytes32 value;
  }

  struct Bytes32ArrayKeyValue {
    string key;
    bytes32[] value;
  }

  struct BytesKeyValue {
    string key;
    bytes value;
  }

  struct BytesArrayKeyValue {
    string key;
    bytes[] value;
  }

  struct StringKeyValue {
    string key;
    string value;
  }

  struct StringArrayKeyValue {
    string key;
    string[] value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IExchangeRouter {
  struct CreateDepositParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minMarketTokens;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  struct CreateWithdrawalParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  struct CreateOrderParams {
    CreateOrderParamsAddresses addresses;
    CreateOrderParamsNumbers numbers;
    OrderType orderType;
    DecreasePositionSwapType decreasePositionSwapType;
    bool isLong;
    bool shouldUnwrapNativeToken;
    bytes32 referralCode;
  }

  struct CreateOrderParamsAddresses {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialCollateralToken;
    address[] swapPath;
  }

  struct CreateOrderParamsNumbers {
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 triggerPrice;
    uint256 acceptablePrice;
    uint256 executionFee;
    uint256 callbackGasLimit;
    uint256 minOutputAmount;
  }

  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  function sendWnt(address receiver, uint256 amount) external payable;

  function sendTokens(
    address token,
    address receiver,
    uint256 amount
  ) external payable;

  function createDeposit(
    CreateDepositParams calldata params
  ) external payable returns (bytes32);

  function createWithdrawal(
    CreateWithdrawalParams calldata params
  ) external payable returns (bytes32);

  function createOrder(
    CreateOrderParams calldata params
  ) external payable returns (bytes32);

  // function cancelDeposit(bytes32 key) external payable;

  // function cancelWithdrawal(bytes32 key) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOrder {
  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  // to help further differentiate orders
  enum SecondaryOrderType {
    None,
    Adl
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account of the order
  // @param receiver the receiver for any token transfers
  // this field is meant to allow the output of an order to be
  // received by an address that is different from the creator of the
  // order whether this is for swaps or whether the account is the owner
  // of a position
  // for funding fees and claimable collateral, the funds are still
  // credited to the owner of the position indicated by order.account
  // @param callbackContract the contract to call for callbacks
  // @param uiFeeReceiver the ui fee receiver
  // @param market the trading market
  // @param initialCollateralToken for increase orders, initialCollateralToken
  // is the token sent in by the user, the token will be swapped through the
  // specified swapPath, before being deposited into the position as collateral
  // for decrease orders, initialCollateralToken is the collateral token of the position
  // withdrawn collateral from the decrease of the position will be swapped
  // through the specified swapPath
  // for swaps, initialCollateralToken is the initial token sent for the swap
  // @param swapPath an array of market addresses to swap through
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialCollateralToken;
    address[] swapPath;
  }

  // @param sizeDeltaUsd the requested change in position size
  // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
  // is the amount of the initialCollateralToken sent in by the user
  // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
  // collateralToken to withdraw
  // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
  // in for the swap
  // @param orderType the order type
  // @param triggerPrice the trigger price for non-market orders
  // @param acceptablePrice the acceptable execution price for increase / decrease orders
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  // @param minOutputAmount the minimum output amount for decrease orders and swaps
  // note that for decrease orders, multiple tokens could be received, for this reason, the
  // minOutputAmount value is treated as a USD value for validation in decrease orders
  // @param updatedAtBlock the block at which the order was last updated
  struct Numbers {
    OrderType orderType;
    DecreasePositionSwapType decreasePositionSwapType;
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 triggerPrice;
    uint256 acceptablePrice;
    uint256 executionFee;
    uint256 callbackGasLimit;
    uint256 minOutputAmount;
    uint256 updatedAtBlock;
  }

  // @param isLong whether the order is for a long or short
  // @param shouldUnwrapNativeToken whether to unwrap native tokens before
  // transferring to the user
  // @param isFrozen whether the order is frozen
  struct Flags {
    bool isLong;
    bool shouldUnwrapNativeToken;
    bool isFrozen;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWithdrawal {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account The account to withdraw for.
  // @param receiver The address that will receive the withdrawn tokens.
  // @param callbackContract The contract that will be called back.
  // @param uiFeeReceiver The ui fee receiver.
  // @param market The market on which the withdrawal will be executed.
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
  }

  // @param marketTokenAmount The amount of market tokens that will be withdrawn.
  // @param minLongTokenAmount The minimum amount of long tokens that must be withdrawn.
  // @param minShortTokenAmount The minimum amount of short tokens that must be withdrawn.
  // @param updatedAtBlock The block at which the withdrawal was last updated.
  // @param executionFee The execution fee for the withdrawal.
  // @param callbackGasLimit The gas limit for calling the callback contract.
  struct Numbers {
    uint256 marketTokenAmount;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    uint256 updatedAtBlock;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  // @param shouldUnwrapNativeToken whether to unwrap the native token when
  struct Flags {
    bool shouldUnwrapNativeToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { GMXTypes } from  "../../../strategy/gmx/GMXTypes.sol";

interface IGMXVault {
  function store() external view returns (GMXTypes.Store memory);
  function isTokenWhitelisted(address token) external view returns (bool);

  function deposit(GMXTypes.DepositParams memory dp) payable external;
  function depositNative(GMXTypes.DepositParams memory dp) payable external;
  function processMint(bytes32 depositKey) payable external;

  function withdraw(GMXTypes.WithdrawParams memory wp) payable external;
  function processSwapForRepay(bytes32 orderKey) external;
  function processRepay(bytes32 withdrawKey, bytes32 orderKey) external;
  function processSwapForWithdraw(bytes32 orderKey) external;
  function processBurn(bytes32 withdrawKey, bytes32 orderKey) payable external;

  function emergencyWithdraw(GMXTypes.WithdrawParams memory wp) external;
  function mintMgmtFee() external;

  function compound(GMXTypes.CompoundParams memory cp) payable external;
  function processCompoundAdd(bytes32 orderKey) external;
  function processCompoundAdded(bytes32 depositKey) payable external;

  function rebalanceAdd(GMXTypes.RebalanceAddParams memory rebalanceAddParams) payable external;
  function processRebalanceAdd(bytes32 depositKey) payable external;

  function rebalanceRemove(GMXTypes.RebalanceRemoveParams memory rebalanceRemoveParams) payable external;
  function processRebalanceRemoveSwapForRepay(bytes32 withdrawKey) external;
  function processRebalanceRemoveRepay(bytes32 withdrawKey, bytes32 swapKey) external;
  function processRebalanceRemoveAddLiquidity(bytes32 depositKey) payable external;

  function emergencyShutdown() payable external;
  function emergencyResume() payable external;

  function pause() external;
  function unpause() external;

  function updateKeeper(address keeper, bool approval) external;
  function updateTreasury(address treasury) external;
  function updateQueue(address queue) external;
  function updateCallback(address callback) external;
  function updateMgmtFeePerSecond(uint256 mgmtFeePerSecond) external;
  function updatePerformanceFee(uint256 performanceFee) external;
  function updateMaxCapacity(uint256 maxCapacity) external;
  function mint(address to, uint256 amt) external;
  function burn(address to, uint256 amt) external;

  function updateInvariants(
    uint256 debtRatioStepThreshold,
    uint256 deltaStepThreshold,
    uint256 debtRatioUpperLimit,
    uint256 debtRatioLowerLimit,
    int256 deltaUpperLimit,
    int256 deltaLowerLimit
  ) external;

  function updateMinExecutionFee(uint256 minExecutionFee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWNT {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IDeposit } from "../../interfaces/protocols/gmx/IDeposit.sol";
import { IWithdrawal } from "../../interfaces/protocols/gmx/IWithdrawal.sol";
import { IEvent } from "../../interfaces/protocols/gmx/IEvent.sol";
import { IOrder } from "../../interfaces/protocols/gmx/IOrder.sol";
import { Errors } from "../../utils/Errors.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";

library GMXChecks {

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  uint256 public constant DUST_AMOUNT = 1e17;

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * @dev Checks before native token deposits
    * @param self Vault store data
    * @param dp DepositParams struct
  */
  function beforeNativeDepositChecks(
    GMXTypes.Store storage self,
    GMXTypes.DepositParams memory dp
  ) external view {
    if (dp.token != address(self.WNT))
      revert Errors.InvalidNativeTokenAddress();
    if (address(self.tokenA) != address(self.WNT))
      revert Errors.OnlyNonNativeDepositToken();
    if (address(self.tokenB) != address(self.WNT))
      revert Errors.OnlyNonNativeDepositToken();

    if (msg.value <= 0) revert Errors.EmptyDepositAmount();

    if (dp.amt + dp.executionFee != msg.value)
      revert Errors.DepositAndExecutionFeeDoesNotMatchMsgValue();
  }

  /**
    * @dev Checks before token deposits
    * @param self Vault store data
  */
  function beforeDepositChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();

    GMXTypes.DepositCache memory _dc = self.depositCache;

    if (_dc.depositParams.executionFee < self.minExecutionFee)
      revert Errors.InsufficientExecutionFeeAmount();

    if (!self.vault.isTokenWhitelisted(_dc.depositParams.token))
      revert Errors.InvalidDepositToken();

    if (_dc.depositParams.amt <= 0)
      revert Errors.InsufficientDepositAmount();

    if (_dc.depositValue <= 0)
      revert Errors.InsufficientDepositAmount();

    if (_dc.depositValue <= DUST_AMOUNT)
      revert Errors.InsufficientDepositAmount();

    if (_dc.depositValue >= GMXReader.additionalCapacity(self))
      revert Errors.InsufficientLendingLiquidity();
  }

  /**
    * @dev Checks during processing deposit
    * @param self Vault store data
    * @param depositKey Deposit key hash to find deposit info
  */
  function processMintChecks(
    GMXTypes.Store storage self,
    bytes32 depositKey
  ) external view {
    GMXTypes.DepositCache memory _dc = self.depositCache;

    if (self.status != GMXTypes.Status.Mint)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (_dc.user == address(0))
      revert Errors.InvalidDepositKey();

    if (_dc.depositKey != depositKey)
      revert Errors.InvalidDepositKey();
  }

  /**
    * @dev Checks after token deposits
    * @param self Vault store data
  */
  function afterDepositChecks(
    GMXTypes.Store storage self
  ) external view {
    GMXTypes.DepositCache memory _dc = self.depositCache;

    if (self.status != GMXTypes.Status.Mint)
      revert Errors.NotAllowedInCurrentVaultStatus();

    // TODO do we  really need a maxCapacity for strategy vaults...?
    // if (dc.healthParams.equityAfter > self.maxCapacity)
    //   revert Errors.InsufficientCapacity();

    if (
      _dc.sharesToUser <
      _dc.depositParams.minSharesAmt
    ) revert Errors.InsufficientSharesMinted();

    // Invariant: check that equity did not decrease
    if (
      _dc.healthParams.equityAfter <
      _dc.healthParams.equityBefore
    ) revert Errors.InvalidEquity();

    // Invariant: check that lpAmt did not decrease
    if (GMXReader.lpAmt(self) < _dc.healthParams.lpAmtBefore)
      revert Errors.InsufficientLPTokensMinted();

    // Invariant: check that debt ratio is within step change range
    if (!_isWithinRange(
      _dc.healthParams.debtRatioBefore,
      GMXReader.debtRatio(self),
      self.debtRatioStepThreshold
    )) revert Errors.InvalidDebtRatio();

    // Invariant: check that delta is within step change range
    if (self.delta == GMXTypes.Delta.Neutral) {
      if (!_isWithinRange(
        uint256(_dc.healthParams.deltaBefore),
        uint256(GMXReader.delta(self)),
        self.deltaStepThreshold
      )) revert Errors.InvalidDelta();
    }
  }

  /**
    * @dev Checks before vault withdrawals
    * @param self Vault store data

  */
  function beforeWithdrawChecks(
    GMXTypes.Store storage self
  ) external view {
    GMXTypes.WithdrawCache memory _wc = self.withdrawCache;

    if (self.status != GMXTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (self.vault.isTokenWhitelisted(_wc.withdrawParams.token))
      revert Errors.InvalidWithdrawToken();

    // TODO this doesnt apply to GMX.. to remove?
    if (block.number == self.lastDepositBlock)
      revert Errors.WithdrawNotAllowedInSameDepositBlock();

    if (_wc.withdrawParams.shareAmt <= 0)
      revert Errors.EmptyWithdrawAmount();

    if (_wc.withdrawParams.executionFee < self.minExecutionFee)
      revert Errors.InsufficientExecutionFeeAmount();

    if (_wc.withdrawParams.swapForRepayParams.executionFee < self.minExecutionFee)
      revert Errors.InsufficientExecutionFeeAmount();

    if (_wc.withdrawParams.swapForWithdrawParams.executionFee < self.minExecutionFee)
      revert Errors.InsufficientExecutionFeeAmount();

    if (msg.value <= 0) revert Errors.InvalidExecutionFeeAmount();

    if (_wc.withdrawParams.executionFee +
        _wc.withdrawParams.swapForRepayParams.executionFee +
        _wc.withdrawParams.swapForWithdrawParams.executionFee != msg.value)
      revert Errors.InvalidExecutionFeeAmount();
  }

  /**
    * @dev Checks before processing repayment
    * @param self Vault store data
    * @param withdrawKey Withdraw key hash to find withdrawal info
  */
  function processSwapForRepayChecks(
    GMXTypes.Store storage self,
    bytes32 withdrawKey
  ) external view {
    GMXTypes.WithdrawCache memory _wc = self.withdrawCache;

    if (self.status != GMXTypes.Status.Swap_For_Repay)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (_wc.user == address(0))
      revert Errors.InvalidWithdrawKey();

    if (_wc.withdrawKey != withdrawKey)
      revert Errors.InvalidWithdrawKey();
  }

  /**
    * @dev Checks before processing of swap for repay after removing liquidity
    * @param self Vault store data
    * @param withdrawKey Withdraw key hash to find withdrawal info
    * @param orderKey Swap key hash to find withdrawKey hash
  */
  function processRepayChecks(
    GMXTypes.Store storage self,
    bytes32 withdrawKey,
    bytes32 orderKey
  ) external view {
    GMXTypes.WithdrawCache memory _wc = self.withdrawCache;

    if (self.status != GMXTypes.Status.Repay)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (_wc.user == address(0))
      revert Errors.InvalidWithdrawKey();

    if (_wc.withdrawKey != withdrawKey)
      revert Errors.InvalidWithdrawKey();

    // orderKey can be bytes32(0) if there is no swap needed for repay
    // but if not, we should check it is the same order key for the swap for repay performed
    if (
      _wc.withdrawParams.swapForRepayParams.orderKey != bytes32(0) &&
      _wc.withdrawParams.swapForRepayParams.orderKey != orderKey
    ) revert Errors.InvalidOrderKey();
  }

  /**
    * @dev Checks before processing swaps for withdrawal
    * @param self Vault store data
    * @param withdrawKey Withdraw key hash to find withdrawal info
  */
  function processSwapForWithdrawChecks(
    GMXTypes.Store storage self,
    bytes32 withdrawKey
  ) external view {
    GMXTypes.WithdrawCache memory _wc = self.withdrawCache;

    if (self.status != GMXTypes.Status.Swap_For_Withdraw)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (_wc.user == address(0))
      revert Errors.InvalidWithdrawKey();

    if (_wc.withdrawKey != withdrawKey)
      revert Errors.InvalidWithdrawKey();
  }

  /**
    * @dev Checks before processing withdrawal
    * @param self Vault store data
    * @param withdrawKey Withdraw key hash to find withdrawal info
    * @param orderKey Swap key hash to find withdrawKey hash
  */
  function processBurnChecks(
    GMXTypes.Store storage self,
    bytes32 withdrawKey,
    bytes32 orderKey
  ) external view {
    GMXTypes.WithdrawCache memory _wc = self.withdrawCache;

    if (self.status != GMXTypes.Status.Withdraw)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (_wc.user == address(0))
      revert Errors.InvalidWithdrawKey();

    if (_wc.withdrawKey != withdrawKey)
      revert Errors.InvalidWithdrawKey();

    // orderKey can be bytes32(0) if there is no swap needed for withdraw
    // but if not, we should check it is the same order key for the swap for withdraw performed
    if (
      _wc.withdrawParams.swapForWithdrawParams.orderKey != bytes32(0) &&
      _wc.withdrawParams.swapForWithdrawParams.orderKey != orderKey
    ) revert Errors.InvalidOrderKey();
  }

  /**
    * @dev Checks after token withdrawals
    * @param self Vault store data
  */
  function afterWithdrawChecks(
    GMXTypes.Store storage self
  ) external view {
    GMXTypes.WithdrawCache memory _wc = self.withdrawCache;

    if (
      _wc.withdrawTokenAmt <
      _wc.withdrawParams.minWithdrawTokenAmt
    ) revert Errors.InsufficientAssetsReceived();

    // Invariant: check that equity did not increase
    if (
      _wc.healthParams.equityAfter >
      _wc.healthParams.equityBefore
    ) revert Errors.InvalidEquity();

    // Invariant: check that lpAmt did not increase
    if (GMXReader.lpAmt(self) > _wc.healthParams.lpAmtBefore)
      revert Errors.InsufficientLPTokensBurned();

    // Invariant: check that debt ratio is within step change range
    if (!_isWithinRange(
      _wc.healthParams.debtRatioBefore,
      GMXReader.debtRatio(self),
      self.debtRatioStepThreshold
    )) revert Errors.InvalidDebtRatio();

    // Invariant: check that delta is within step change range
    if (self.delta == GMXTypes.Delta.Neutral) {
      if (!_isWithinRange(
        uint256(_wc.healthParams.deltaBefore),
        uint256(GMXReader.delta(self)),
        self.deltaStepThreshold
      )) revert Errors.InvalidDelta();
    }
  }

  /**
    * @dev Checks before rebalancing add liquidity
    * @param self Vault store data
  */
  function beforeRebalanceAddChecks(
    GMXTypes.Store storage self
  ) external view {
    GMXTypes.RebalanceAddCache memory _rac =
      self.rebalanceAddCache;

    if (self.status != GMXTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();

    // Check that rebalance conditions have been met
    if (
      _rac.healthParams.debtRatioBefore <= self.debtRatioUpperLimit ||
      _rac.healthParams.debtRatioBefore >= self.debtRatioLowerLimit
    ) revert Errors.InvalidRebalancePreConditions();

    if (self.delta == GMXTypes.Delta.Neutral) {
      if (
        _rac.healthParams.deltaBefore <= self.deltaUpperLimit ||
        _rac.healthParams.deltaBefore >= self.deltaLowerLimit
      ) revert Errors.InvalidRebalancePreConditions();
    }
  }

  /**
    * @dev Checks during processing of rebalancing by adding liquidity
    * @param self Vault store data
  */
  function processRebalanceAddChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Rebalance_Add_Add_Liquidity)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @dev Checks after rebalancing add liquidity
    * @param self Vault store data
  */
  function afterRebalanceAddChecks(
    GMXTypes.Store storage self
  ) external view {
    GMXTypes.RebalanceAddCache memory _rac =
      self.rebalanceAddCache;

    // Invariant: check that lpAmt did not decrease
    if (
      GMXReader.lpAmt(self) < _rac.healthParams.lpAmtBefore
    ) revert Errors.InsufficientLPTokensMinted();

    // Invariant: check that debt amt did not decrease
    (
      uint256 _debtAmtTokenAAfter,
      uint256 _debtAmtTokenBAfter
    ) = GMXReader.debtAmt(self);

    if (
      _debtAmtTokenAAfter < _rac.healthParams.debtAmtTokenABefore ||
      _debtAmtTokenBAfter < _rac.healthParams.debtAmtTokenBBefore
    ) revert Errors.InvalidRebalanceDebtAmounts();

    // Invariant: check that debt ratio is within global limits
    if (
      GMXReader.debtRatio(self) > self.debtRatioUpperLimit ||
      GMXReader.debtRatio(self) < self.debtRatioLowerLimit
    ) revert Errors.InvalidDebtRatio();

    // Invariant: check that delta is within global limits
    if (
      GMXReader.delta(self) > self.deltaUpperLimit ||
      GMXReader.delta(self) < self.deltaLowerLimit
    ) revert Errors.InvalidDelta();
  }

  /**
    * @dev Checks before rebalancing remove liquidity
    * @param self Vault store data
  */
  function beforeRebalanceRemoveChecks(
    GMXTypes.Store storage self
  ) external view {
    GMXTypes.RebalanceRemoveCache memory _rrc =
      self.rebalanceRemoveCache;

    if (self.status != GMXTypes.Status.Rebalance_Remove)
      revert Errors.NotAllowedInCurrentVaultStatus();

    // Check that rebalance conditions have been met
    if (
      _rrc.healthParams.debtRatioBefore <= self.debtRatioUpperLimit ||
      _rrc.healthParams.debtRatioBefore >= self.debtRatioLowerLimit
    ) revert Errors.InvalidRebalancePreConditions();

    if (self.delta == GMXTypes.Delta.Neutral) {
      if (
        _rrc.healthParams.deltaBefore <= self.deltaUpperLimit ||
        _rrc.healthParams.deltaBefore >= self.deltaLowerLimit
      ) revert Errors.InvalidRebalancePreConditions();
    }
  }

  /**
    * @dev Checks during processing of rebalancing by removing liquidity, checking if swaps needed
    * @param self Vault store data
    * @param withdrawKey Withdraw key hash to find withdrawal info
  */
  function processRebalanceRemoveSwapForRepayChecks(
    GMXTypes.Store storage self,
    bytes32 withdrawKey
  ) external view {
    GMXTypes.RebalanceRemoveCache memory _rrc =
      self.rebalanceRemoveCache;

    if (self.status != GMXTypes.Status.Rebalance_Remove_Swap_For_Repay)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (_rrc.withdrawKey != withdrawKey)
      revert Errors.InvalidWithdrawKey();
  }

  /**
    * @dev Checks during processing of rebalancing by removing liquidity, making repayments after swaps
    * @param self Vault store data
    * @param withdrawKey Withdraw key
    * @param orderKey Order key hash
  */
  function processRebalanceRemoveRepayChecks(
    GMXTypes.Store storage self,
    bytes32 withdrawKey,
    bytes32 orderKey
  ) external view {
    GMXTypes.RebalanceRemoveCache memory _rrc =
      self.rebalanceRemoveCache;

    if (self.status != GMXTypes.Status.Rebalance_Remove_Repay)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (_rrc.withdrawKey != withdrawKey)
      revert Errors.InvalidWithdrawKey();

    // orderKey can be bytes32(0) if there is no swap needed for withdraw
    // but if not, we should check it is the same order key for the swap for withdraw performed
    if (
      _rrc.rebalanceRemoveParams.swapForRepayParams.orderKey != bytes32(0) &&
      _rrc.rebalanceRemoveParams.swapForRepayParams.orderKey != orderKey
    ) revert Errors.InvalidOrderKey();
  }

  /**
    * @dev Checks during processing of rebalancing by removing liquidity, making repayments after swaps
    * @param self Vault store data
    * @param depositKey Deposit key
  */
  function processRebalanceRemoveAddLiquidityChecks(
    GMXTypes.Store storage self,
    bytes32 depositKey
  ) external view {
    GMXTypes.RebalanceRemoveCache memory _rrc =
      self.rebalanceRemoveCache;

    if (self.status != GMXTypes.Status.Rebalance_Remove_Add_Liquidity)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (_rrc.depositKey != depositKey)
      revert Errors.InvalidWithdrawKey();
  }

  /**
    * @dev Checks after rebalancing remove liquidity
    * @param self Vault store data
  */
  function afterRebalanceRemoveChecks(
    GMXTypes.Store storage self
  ) external view {
    GMXTypes.RebalanceRemoveCache memory _rrc =
      self.rebalanceRemoveCache;

    // Invariant: check that lpAmt did not increase
    if (
      GMXReader.lpAmt(self) > _rrc.healthParams.lpAmtBefore
    ) revert Errors.InsufficientLPTokensMinted();

    // Invariant: check that debt amt did not increase
    (
      uint256 _debtAmtTokenAAfter,
      uint256 _debtAmtTokenBAfter
    ) = GMXReader.debtAmt(self);

    if (
      _debtAmtTokenAAfter > _rrc.healthParams.debtAmtTokenABefore ||
      _debtAmtTokenBAfter > _rrc.healthParams.debtAmtTokenBBefore
    ) revert Errors.InvalidRebalanceDebtAmounts();

    // Invariant: check that debt ratio is within global limits
    if (
      GMXReader.debtRatio(self) > self.debtRatioUpperLimit ||
      GMXReader.debtRatio(self) < self.debtRatioLowerLimit
    ) revert Errors.InvalidDebtRatio();

    // Invariant: check that delta is within global limits
    if (
      GMXReader.delta(self) > self.deltaUpperLimit ||
      GMXReader.delta(self) < self.deltaLowerLimit
    ) revert Errors.InvalidDelta();
  }

  /**
    * @dev Checks before processing compound
    * @param self Vault store data
  */
  function beforeCompoundChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @dev Checks before processing compound
    * @param self Vault store data
    * @param orderKey Order key
  */
  function processCompoundAddChecks(
    GMXTypes.Store storage self,
    bytes32 orderKey
  ) external view {
    GMXTypes.CompoundCache memory _cc = self.compoundCache;

    if (self.status != GMXTypes.Status.Compound_Add_Liquidity)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (
      _cc.compoundParams.swapParams.orderKey != bytes32(0) &&
      _cc.compoundParams.swapParams.orderKey != orderKey
    ) revert Errors.InvalidOrderKey();
  }

  /**
    * @dev Checks before processing compound
    * @param self Vault store data
    * @param depositKey Deposit key
  */
  function processCompoundAddedChecks(
    GMXTypes.Store storage self,
    bytes32 depositKey
  ) external view {
    GMXTypes.CompoundCache memory _cc = self.compoundCache;

    if (self.status != GMXTypes.Status.Compound_Liquidity_Added)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (
      _cc.depositKey != bytes32(0) &&
      _cc.depositKey != depositKey
    ) revert Errors.InvalidDepositKey();
  }

  /**
    * @dev Checks before token deposits
    * @param self Vault store data
  */
  function beforeEmergencyShutdownChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @dev Checks before token deposits
    * @param self Vault store data
  */
  function beforeEmergencyResumeChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Closed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @dev Checks before emergency withdrawals
    * @param self Vault store data
    * @param shareAmt Amount of shares to burn
  */
  function beforeEmergencyWithdrawChecks(
    GMXTypes.Store storage self,
    uint256 shareAmt
  ) external view {
    if (self.status != GMXTypes.Status.Closed)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (shareAmt <= 0)
      revert Errors.EmptyWithdrawAmount();
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * @dev Helper function to check if values are within threshold range
    * @param valueBefore Previous value
    * @param valueAfter New value
    * @param threshold Tolerance threshold; 100 = 1%
    * @return Whether value after is within threshold range
  */
  function _isWithinRange(
    uint256 valueBefore,
    uint256 valueAfter,
    uint256 threshold
  ) internal pure returns (bool) {
    // TODO To check if this is initial state which will result in valueBefore as 0
    // TODO also to check if emergency withdrawing.. if so, then valueAfter can be 0 as well?

    // TEMP
    if (valueBefore == 0 || valueAfter == 0) {
      return true;
    }

    return (
      valueAfter >= valueBefore * (10000 - threshold) / 10000 &&
      valueAfter <= valueBefore * (10000 + threshold) / 10000
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IDeposit } from "../../interfaces/protocols/gmx/IDeposit.sol";
import { IWithdrawal } from "../../interfaces/protocols/gmx/IWithdrawal.sol";
import { IEvent } from "../../interfaces/protocols/gmx/IEvent.sol";
import { IOrder } from "../../interfaces/protocols/gmx/IOrder.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";
import { GMXChecks } from "./GMXChecks.sol";
import { GMXManager } from "./GMXManager.sol";

library GMXDeposit {
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== EVENTS ========== */

  event DepositCreated(
    address indexed user,
    address asset,
    uint256 assetAmt
  );
  event DepositCompleted(
    address indexed user,
    uint256 shareAmt,
    uint256 equityBefore,
    uint256 equityAfter
  );

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
    * @dev Deposits native asset into vault and mint svToken to user
    * @param self Vault store data
    * @param dp DepositParams struct of deposit parameters
  */
  function depositERC20(
    GMXTypes.Store storage self,
    GMXTypes.DepositParams memory dp
  ) external {
    IERC20(dp.token).safeTransferFrom(msg.sender, address(this), dp.amt);

    _deposit(self, dp);
  }

  /**
    * @dev Deposits native asset into vault and mint svToken to user
    * @param self Vault store data
    * @param dp DepositParams struct
  */
  function depositNative(
    GMXTypes.Store storage self,
    GMXTypes.DepositParams memory dp
  ) external {
    GMXChecks.beforeNativeDepositChecks(self, dp);

    self.WNT.deposit{ value: dp.amt }();

    _deposit(self, dp);
  }

  /**
    * @dev Mint shares after deposit is executed on GMX
    * @notice Called after _deposit()
    * @param self Vault store data
    * @param depositKey Deposit key hash to find deposit info
  */
  function processMint(
    GMXTypes.Store storage self,
    bytes32 depositKey
  ) external {
    GMXChecks.processMintChecks(self, depositKey);

    GMXTypes.DepositCache memory _dc = self.depositCache;

    _dc.healthParams.equityAfter = GMXReader.equityValue(self);

    // Calculate shares to mint to user based on equity change
    _dc.sharesToUser = GMXReader.valueToShares(
      self,
      _dc.healthParams.equityAfter - _dc.healthParams.equityBefore,
      _dc.healthParams.equityBefore
    );

    self.depositCache = _dc;

    GMXChecks.afterDepositChecks(self);

    // Mint shares to depositor
    self.vault.mint(
      _dc.user,
      _dc.sharesToUser
    );

    self.status = GMXTypes.Status.Open;

    emit DepositCompleted(
      _dc.user,
      _dc.sharesToUser,
      _dc.healthParams.equityBefore,
      _dc.healthParams.equityAfter
    );
  }

  /* ========== INTERNAL FUNCTIONS ========== */


  /**
    * @dev Deposits ERC20 asset into vault and mint svToken to user
    * @notice processMint() to be called after this
    * @param self Vault store data
    * @param dp DepositParams struct of deposit parameter
  */
  function _deposit(
    GMXTypes.Store storage self,
    GMXTypes.DepositParams memory dp
  ) internal {
    GMXTypes.HealthParams memory _hp;
    _hp.equityBefore = GMXReader.equityValue(self);
    _hp.lpAmtBefore = GMXReader.lpAmt(self);
    _hp.debtRatioBefore = GMXReader.debtRatio(self);
    _hp.deltaBefore = GMXReader.delta(self);

    GMXTypes.DepositCache memory _dc;
    _dc.user = payable(msg.sender);
    _dc.timestamp = block.timestamp;
    _dc.depositValue = GMXReader.convertToUsdValue(
      self,
      dp.token,
      dp.amt
    );
    _dc.depositParams = dp;
    _dc.healthParams = _hp;

    self.depositCache = _dc;

    GMXChecks.beforeDepositChecks(self);

    self.status = GMXTypes.Status.Deposit;

    self.vault.mintMgmtFee();

    self.status = GMXTypes.Status.Borrow;

    // Borrow assets and create deposit in GMX
    (
      uint256 _borrowTokenAAmt,
      uint256 _borrowTokenBAmt
    ) = GMXManager.calcBorrow(self, _dc.depositValue);

    _dc.borrowParams.borrowTokenAAmt = _borrowTokenAAmt;
    _dc.borrowParams.borrowTokenBAmt = _borrowTokenBAmt;

    GMXManager.borrow(self, _borrowTokenAAmt, _borrowTokenBAmt);

    self.status = GMXTypes.Status.Add_Liquidity;

    bytes32 _depositKey = GMXManager.addLiquidity(
      self,
      _dc.depositParams
    );

    _dc.depositKey = _depositKey;

    self.depositCache = _dc;

    self.lastDepositBlock = block.number;

    self.status = GMXTypes.Status.Mint;

    emit DepositCreated(
      _dc.user,
      _dc.depositParams.token,
      _dc.depositParams.amt
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";
import { GMXWorker } from "./GMXWorker.sol";

library GMXManager {
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
    * @dev Borrow tokens from lending vaults
    * @param self Vault store data
    * @param borrowTokenAAmt Amount of tokenA to borrow in token decimals
    * @param borrowTokenBAmt Amount of tokenB to borrow in token decimals
  */
  function borrow(
    GMXTypes.Store storage self,
    uint256 borrowTokenAAmt,
    uint256 borrowTokenBAmt
  ) public {
    if (borrowTokenAAmt > 0) {
      self.tokenALendingVault.borrow(borrowTokenAAmt);
    }
    if (borrowTokenBAmt > 0) {
      self.tokenBLendingVault.borrow(borrowTokenBAmt);
    }
  }

  /**
    * @dev Repay tokens to lending vaults
    * @param self Vault store data
    * @param repayTokenAAmt Amount of tokenA to repay in token decimals
    * @param repayTokenBAmt Amount of tokenB to repay in token decimals
  */
  function repay(
    GMXTypes.Store storage self,
    uint256 repayTokenAAmt,
    uint256 repayTokenBAmt
  ) public {
    if (repayTokenAAmt > 0) {
      self.tokenALendingVault.repay(repayTokenAAmt);
    }
    if (repayTokenBAmt > 0) {
      self.tokenBLendingVault.repay(repayTokenBAmt);
    }
  }

  /**
    * @dev Called by deposit function add liquidity
    * @param self Vault store data
    * @param dp GMXTypes.DepositParams
    * @return depositKey
  */
  function addLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.DepositParams memory dp
  ) public returns (bytes32) {
    GMXTypes.AddLiquidityParams memory _alp;
    _alp.tokenAAmt = self.tokenA.balanceOf(address(this));
    _alp.tokenBAmt = self.tokenB.balanceOf(address(this));
    _alp.slippage = dp.slippage;
    _alp.executionFee = dp.executionFee;

    bytes32 _depositKey = GMXWorker.addLiquidity(self, _alp);

    return _depositKey;
  }

  /**
    * @dev Called by withdraw function to remove liquidity
    * @param self Vault store data
    * @param wp GMXTypes.WithdrawParams
    * @return withdrawKey
  */
  function removeLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.WithdrawParams memory wp
  ) public returns (bytes32) {
    GMXTypes.RemoveLiquidityParams memory _rlp;
    _rlp.lpTokenAmt = wp.lpAmtToRemove;
    _rlp.slippage = wp.slippage;
    _rlp.executionFee = wp.executionFee;
    bytes32 _withdrawKey = GMXWorker.removeLiquidity(self, _rlp);

    return _withdrawKey;
  }

  /**
    * @dev Swap tokens in this vault
    * @param self Vault store data
    * @param sp GMXTypes.SwapParams struct
    * @return swapKey Swap order key
  */
  function swap(
    GMXTypes.Store storage self,
    GMXTypes.SwapParams memory sp
  ) external returns (bytes32) {
    return GMXWorker.swap(self, sp);
  }

  /**
    * @dev Check if swap between tokens is needed to ensure enough repayment for both tokens
    * @param self Vault store data
    * @param rp GMXTypes.RepayParams struct
    * @return (swapNeeded, tokenFrom, tokenTo, swapFromAmt)
  */
  function swapForRepay(
    GMXTypes.Store storage self,
    GMXTypes.RepayParams memory rp
  ) external view returns (bool, address, address, uint256) {
    address _tokenFrom;
    address _tokenTo;
    uint256 _tokenFromAmt;
    uint256 _tokenToAmt;

    if (rp.repayTokenAAmt > self.tokenA.balanceOf(address(this))) {
      // If more tokenA is needed for repayment
      _tokenToAmt = rp.repayTokenAAmt - self.tokenA.balanceOf(address(this));
      _tokenFrom = address(self.tokenB);
      _tokenTo = address(self.tokenA);
    } else if (rp.repayTokenBAmt > self.tokenB.balanceOf(address(this))) {
      // If more tokenB is needed for repayment
      _tokenToAmt = rp.repayTokenBAmt - self.tokenB.balanceOf(address(this));
      _tokenFrom = address(self.tokenA);
      _tokenTo = address(self.tokenB);
    } else {
      // If more there is enough to repay both tokens
      return (false, address(0), address(0), 0);
    }

    // Get estimated amounts to swap tokenFrom for desired amount of tokenTo
    _tokenFromAmt = self.gmxOracle.getAmountsIn(
      address(self.lpToken), // marketToken
      address(self.tokenA), // indexToken
      address(self.tokenA), // longToken
      address(self.tokenB), // shortToken
      _tokenTo, // _tokenTo
      _tokenToAmt // amountsOut of _tokenTo wanted
    );

    if (_tokenFromAmt > 0) {
      return (true, _tokenFrom, _tokenTo, _tokenFromAmt);
    } else {
      return (false, address(0), address(0), 0);
    }
  }

  // /**
  //   * @dev Compound ERC20 token rewards, convert to more LP
  //   * @notice keeper will call compound with different ERC20 reward tokens received by vault
  //   * @param self Vault store data
  //   * @param token Address of token to swap from
  //   * @param slippage Slippage tolerance for minimum amount to receive; e.g. 3 = 0.03%
  //   * @param deadline Timestamp of deadline for swap to go through
  // */
  // function compound(
  //   GMXTypes.Store storage self,
  //   address token,
  //   uint256 slippage,
  //   uint256 deadline
  // ) external {
  //   IERC20(token).approve(address(self.router), IERC20(token).balanceOf(address(this)));

  //   GMXWorker.swap(
  //     self,
  //     token,
  //     address(self.tokenB),
  //     IERC20(token).balanceOf(address(this)),
  //     slippage,
  //     deadline
  //   );

  //   // Clip vault strategy fee
  //   uint256 _fee = self.tokenB.balanceOf(address(this))
  //                 * self.performanceFee
  //                 / SAFE_MULTIPLIER;

  //   self.tokenB.safeTransfer(self.treasury, _fee);

  //   // Add liquidity and stake
  //   GMXWorker.swapForOptimalDeposit(self, slippage, deadline);
  //   GMXWorker.addLiquidity(self, slippage, deadline);
  //   GMXWorker.stake(self, self.lpToken.balanceOf(address(this)));
  // }


  /**
    * @dev Unstakes and withdraws all LP tokens, repay all debts to lending
    * vaults and leaving assets in vault for depositors to withdraw
    * @param self Vault store data
    * @param slippage Slippage tolerance for minimum amount to receive; e.g. 3 = 0.03%
    * @param deadline Timestamp of deadline for swap to go through
  */
  function emergencyShutdown(
    GMXTypes.Store storage self,
    uint256 slippage,
    uint256 deadline
  ) external {
    // uint256 lpAmt_ = GMXReader.lpAmt(self);

    // removeLiquidityAndRepay(self, lpAmt_, slippage, deadline);
  }

  /**
    * @dev Borrow assets again and re-add liquidity using all available assets and restake
    * @param self Vault store data
    * @param slippage Slippage tolerance for minimum amount to receive; e.g. 3 = 0.03%
    * @param deadline Timestamp of deadline for swap to go through
  */
  function emergencyResume(
    GMXTypes.Store storage self,
    uint256 slippage,
    uint256 deadline
  ) external {
    // // Get the "equity value" which is tokenA + tokenB value in the vault
    // uint256 _valueOfAssetsInVault =
    //   GMXReader.convertToUsdValue(
    //     self,
    //     address(self.tokenA),
    //     10**(IERC20Metadata(address(self.tokenA)).decimals())
    //   )
    //   +
    //   GMXReader.convertToUsdValue(
    //     self,
    //     address(self.tokenB),
    //     10**(IERC20Metadata(address(self.tokenB)).decimals())
    //   );

    // borrowAndAddLiquidity(self, _valueOfAssetsInVault, slippage, deadline);
  }

  /**
    * @dev Calculate how much tokens to borrow
    * @param self Vault store data
    * @param depositValue Deposit value in 1e18
  */
  function calcBorrow(
    GMXTypes.Store storage self,
    uint256 depositValue
  ) external view returns (uint256, uint256) {
    // Calculate final position value based on deposit value
    uint256 _positionValue = depositValue * self.leverage / SAFE_MULTIPLIER;
    // Obtain the value to borrow
    uint256 _borrowValue = _positionValue - depositValue;

    uint256 _tokenADecimals = IERC20Metadata(address(self.tokenA)).decimals();
    uint256 _tokenBDecimals = IERC20Metadata(address(self.tokenB)).decimals();
    uint256 _borrowLongTokenAmt;
    uint256 _borrowShortTokenAmt;

    // If delta is long, borrow all in short token
    if (self.delta == GMXTypes.Delta.Long) {
      _borrowShortTokenAmt = _borrowValue * SAFE_MULTIPLIER
                             / GMXReader.convertToUsdValue(self, address(self.tokenB), 10**(_tokenBDecimals))
                             / (10 ** (18 - _tokenBDecimals));
    }

    // If delta is neutral, borrow appropriate amount in long token to hedge, and the rest in short token
    if (self.delta == GMXTypes.Delta.Neutral) {
      // Get token weights in LP, e.g. 50% = 5e17
      (uint256 _tokenAWeight,) = GMXReader.tokenWeights(self);

      // Get value of long token (typically tokenA)
      uint256 _longTokenWeightedValue = _tokenAWeight * _positionValue / SAFE_MULTIPLIER;

      // Borrow appropriate amount in long token to hedge
      _borrowLongTokenAmt = _longTokenWeightedValue * SAFE_MULTIPLIER
                            / GMXReader.convertToUsdValue(self, address(self.tokenA), 10**(_tokenADecimals))
                            / (10 ** (18 - _tokenADecimals));

      // Borrow the shortfall value in short token
      _borrowShortTokenAmt = (_borrowValue - _longTokenWeightedValue) * SAFE_MULTIPLIER
                             / GMXReader.convertToUsdValue(self, address(self.tokenB), 10**(_tokenBDecimals))
                             / (10 ** (18 - _tokenBDecimals));
    }

    return (_borrowLongTokenAmt, _borrowShortTokenAmt);
  }

  /**
    * @dev Calculate how much tokens to repay
    * @param self Vault store data
    * @param shareRatio Amount of svTokens relative to total supply of svTokens in 1e18
  */
  function calcRepay(
    GMXTypes.Store storage self,
    uint256 shareRatio
  ) external view returns (uint256, uint256) {
    (uint256 tokenADebtAmt, uint256 tokenBDebtAmt) = GMXReader.debtAmt(self);

    uint256 _repayTokenAAmt = shareRatio * tokenADebtAmt / SAFE_MULTIPLIER;
    uint256 _repayTokenBAmt = shareRatio * tokenBDebtAmt / SAFE_MULTIPLIER;

    return (_repayTokenAAmt, _repayTokenBAmt);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { GMXTypes } from "./GMXTypes.sol";

library GMXReader {
  using SafeCast for uint256;

  /* ========== CONSTANTS FUNCTIONS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * @dev Returns the value of each share token; total equity / share token supply
    * @param self Vault store data
    * @return svTokenValue   Value of each share token in 1e18
  */
  function svTokenValue(GMXTypes.Store storage self) public view returns (uint256) {
    uint256 equityValue_ = equityValue(self);
    uint256 totalSupply_ = IERC20(address(self.vault)).totalSupply();
    if (equityValue_ == 0 || totalSupply_ == 0) return SAFE_MULTIPLIER;
    return equityValue_ * SAFE_MULTIPLIER / totalSupply_;
  }

  /**
    * @dev Amount of share pending for minting as a form of mgmt fee
    * @param self Vault store data
    * @return pendingMgmtFee in 1e18
  */
  function pendingMgmtFee(GMXTypes.Store storage self) public view returns (uint256) {
    uint256 totalSupply_ = IERC20(address(self.vault)).totalSupply();
    uint256 _secondsFromLastCollection = block.timestamp - self.lastFeeCollected;
    return (totalSupply_ * self.mgmtFeePerSecond * _secondsFromLastCollection) / SAFE_MULTIPLIER;
  }

  /**
    * @dev Conversion of equity value to svToken shares
    * @param self Vault store data
    * @param value Equity value change after deposit in 1e18
    * @param currentEquity Current equity value of vault in 1e18
    * @return sharesAmt Shares amt in 1e18
  */
  function valueToShares(
    GMXTypes.Store storage self,
    uint256 value,
    uint256 currentEquity
  ) public view returns (uint256) {
    uint256 _sharesSupply = IERC20(address(self.vault)).totalSupply() + pendingMgmtFee(self);
    if (_sharesSupply == 0 || currentEquity == 0) return value;
    return value * _sharesSupply / currentEquity;
  }

  /**
    * @dev Convert token amount to value using oracle price
    * @param self Vault store data
    * @param token Token address
    * @param amt Amount of token in token decimals
    @ @return tokenValue Token USD value in 1e18
  */
  function convertToUsdValue(
    GMXTypes.Store storage self,
    address token,
    uint256 amt
  ) public view returns (uint256) {
    return amt * 10**(18 - IERC20Metadata(token).decimals())
                * self.chainlinkOracle.consultIn18Decimals(token)
                / SAFE_MULTIPLIER;
  }

  /**
    * @dev Return % weighted value of tokens in LP
    * @param self Vault store data
    @ @return (tokenAWeight, tokenBWeight) in 1e18; e.g. 50% = 5e17
  */
  function tokenWeights(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    // Get amounts of tokenA and tokenB in liquidity pool in token decimals
    (uint256 _reserveA, uint256 _reserveB) = self.gmxOracle.getLpTokenReserves(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB)
    );

    // Get value of tokenA and tokenB in 1e18
    uint256 _tokenAValue = convertToUsdValue(self, address(self.tokenA), _reserveA);
    uint256 _tokenBValue = convertToUsdValue(self, address(self.tokenB), _reserveB);

    uint256 _totalLpValue = _tokenAValue + _tokenBValue;

    return (
      _tokenAValue * SAFE_MULTIPLIER / _totalLpValue,
      _tokenBValue * SAFE_MULTIPLIER / _totalLpValue
    );
  }

  /**
    * @dev Returns the total value of token A & token B assets held by the vault;
    * asset = debt + equity
    * @param self Vault store data
    * @return assetValue   Value of total assets in 1e18
  */
  function assetValue(GMXTypes.Store storage self) public view returns (uint256) {
    return lpAmt(self) * self.gmxOracle.getLpTokenValue(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB),
      false,
      false
    ) / SAFE_MULTIPLIER;
  }

  /**
    * @dev Returns the value of token A & token B debt held by the vault
    * @param self Vault store data
    * @return debtValue   Value of token A and token B debt in 1e18
  */
  function debtValue(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    (uint256 _tokenADebtAmt, uint256 _tokenBDebtAmt) = debtAmt(self);
    return (
      convertToUsdValue(self, address(self.tokenA), _tokenADebtAmt),
      convertToUsdValue(self, address(self.tokenB), _tokenBDebtAmt)
    );
  }

  /**
    * @dev Returns the value of token A & token B equity held by the vault;
    * equity = asset - debt
    * @param self Vault store data
    * @return equityValue   Value of total equity in 1e18
  */
  function equityValue(GMXTypes.Store storage self) public view returns (uint256) {
    (uint256 _tokenADebtAmt, uint256 _tokenBDebtAmt) = debtAmt(self);

    uint256 assetValue_ = assetValue(self);

    uint256 _debtValue = convertToUsdValue(self, address(self.tokenA), _tokenADebtAmt)
                         + convertToUsdValue(self, address(self.tokenB), _tokenBDebtAmt);

    // in underflow condition return 0
    unchecked {
      if (assetValue_ < _debtValue) return 0;

      return assetValue_ - _debtValue;
    }
  }

  /**
    * @dev Returns the amt of token A & token B assets held by vault
    * @param self Vault store data
    * @return assetAmt   Amt of token A and token B asset in asset decimals
  */
  function assetAmt(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    (uint256 _reserveA, uint256 _reserveB) = self.gmxOracle.getLpTokenReserves(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB)
    );

    return (
      _reserveA * SAFE_MULTIPLIER * lpAmt(self) / self.lpToken.totalSupply() / SAFE_MULTIPLIER,
      _reserveB * SAFE_MULTIPLIER * lpAmt(self) / self.lpToken.totalSupply() / SAFE_MULTIPLIER
    );
  }

  /**
    * @dev Returns the amt of token A & token B debt held by vault
    * @param self Vault store data
    * @return debtAmt   Amt of token A and token B debt in token decimals
  */
  function debtAmt(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    return (
      self.tokenALendingVault.maxRepay(address(self.vault)),
      self.tokenBLendingVault.maxRepay(address(self.vault))
    );
  }

  /**
    * @dev Returns the amt of LP tokens held by vault
    * @param self Vault store data
    * @return lpAmt   Amt of LP tokens in 1e18
  */
  function lpAmt(GMXTypes.Store storage self) public view returns (uint256) {
    return self.lpToken.balanceOf(address(self.vault));
  }

  /**
    * @dev Returns the current leverage (asset / equity)
    * @param self Vault store data
    * @return leverage   Current leverage in 1e18
  */
  function leverage(GMXTypes.Store storage self) public view returns (uint256) {
    if (assetValue(self) == 0 || equityValue(self) == 0) return 0;
    return assetValue(self) * SAFE_MULTIPLIER / equityValue(self);
  }

  /**
    * @dev Returns the current delta (tokenA equityValue / vault equityValue)
    * Delta refers to the position exposure of this vault's strategy to the
    * underlying volatile asset. This function assumes that tokenA will always
    * be the non-stablecoin token and tokenB always being the stablecoin
    * The delta can be a negative value
    * @param self Vault store data
    * @return delta  Current delta (0 = Neutral, > 0 = Long, < 0 = Short) in 1e18
  */
  function delta(GMXTypes.Store storage self) public view returns (int256) {
    (uint256 _tokenAAmt,) = assetAmt(self);
    (uint256 _tokenADebtAmt,) = debtAmt(self);

    if (_tokenAAmt == 0 && _tokenADebtAmt == 0) return 0;

    bool _isPositive = _tokenAAmt >= _tokenADebtAmt;

    uint256 _unsignedDelta = _isPositive ?
      _tokenAAmt - _tokenADebtAmt :
      _tokenADebtAmt - _tokenAAmt;

    int256 signedDelta = (_unsignedDelta
      * self.chainlinkOracle.consultIn18Decimals(address(self.tokenA))
      / equityValue(self)).toInt256();

    if (_isPositive) return signedDelta;
    else return -signedDelta;
  }

  /**
    * @dev Returns the debt ratio (tokenA and tokenB debtValue) / (total assetValue)
    * When assetValue is 0, we assume the debt ratio to also be 0
    * @param self Vault store data
    * @return debtRatio   Current debt ratio % in 1e18
  */
  function debtRatio(GMXTypes.Store storage self) public view returns (uint256) {
    (uint256 _tokenADebtValue, uint256 _tokenBDebtValue) = debtValue(self);
    if (assetValue(self) == 0) return 0;
    return (_tokenADebtValue + _tokenBDebtValue) * SAFE_MULTIPLIER / assetValue(self);
  }

  /**
    * @dev To get additional capacity vault can hold based on lending vault available liquidity
    * @param self Vault store data
    @ @return additionalCapacity Additional capacity vault can hold based on lending vault available liquidity
  */
  function additionalCapacity(GMXTypes.Store storage self) public view returns (uint256) {
    uint256 _additionalCapacity;

    // Long strategy only borrows short token (typically stablecoin)
    if (self.delta == GMXTypes.Delta.Long) {
      _additionalCapacity = convertToUsdValue(
        self,
        address(self.tokenB),
        self.tokenBLendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER
        / ((self.leverage - 1e18) / SAFE_MULTIPLIER)
        / SAFE_MULTIPLIER;
    }

    // Neutral strategy borrows both long (typical volatile) and short token (typically stablecoin)
    if (self.delta == GMXTypes.Delta.Neutral) {
      (uint256 _tokenAWeight, uint256 _tokenBWeight) = tokenWeights(self);

      uint256 _maxTokenALending = convertToUsdValue(
        self,
        address(self.tokenA),
        self.tokenALendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER
        / (_tokenAWeight * (self.leverage - SAFE_MULTIPLIER) / SAFE_MULTIPLIER)
        / SAFE_MULTIPLIER;

      uint256 _maxTokenBLending = convertToUsdValue(
        self,
        address(self.tokenB),
        self.tokenBLendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER
        / (_tokenBWeight * (self.leverage - SAFE_MULTIPLIER) / SAFE_MULTIPLIER)
        / SAFE_MULTIPLIER;

      _additionalCapacity =  _maxTokenALending > _maxTokenBLending ? _maxTokenBLending : _maxTokenALending;
    }

    return _additionalCapacity;
  }

  /**
    * @dev External function to get soft capacity vault can hold based on lending vault available liquidity and current equity
    * @param self Vault store datavalue
    @ @return capacity soft capacity of vault
  */
  function capacity(GMXTypes.Store storage self) public view returns (uint256) {
    return additionalCapacity(self) + equityValue(self);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWNT } from "../../interfaces/tokens/IWNT.sol";
import { ILendingVault } from "../../interfaces/lending/ILendingVault.sol";
import { IGMXVault } from "../../interfaces/strategy/gmx/IGMXVault.sol";
import { IChainlinkOracle } from "../../interfaces/oracles/IChainlinkOracle.sol";
import { IGMXOracle } from "../../interfaces/oracles/IGMXOracle.sol";
import { IExchangeRouter } from "../../interfaces/protocols/gmx/IExchangeRouter.sol";

library GMXTypes {

  /* ========== STRUCTS ========== */

  struct Store {
    // Target leverage of the vault in 1e18
    uint256 leverage;
    // Delta strategy
    Delta delta;
    // Management fee per second in % in 1e18
    uint256 mgmtFeePerSecond;
    // Performance fee in % in 1e18
    uint256 performanceFee;
    // Max capacity of vault in USD value in 1e18
    uint256 maxCapacity;
    // Treasury address
    address treasury;

    // Invariant: threshold for debtRatio change after deposit/withdraw
    uint256 debtRatioStepThreshold; // in 1e4; e.g. 500 = 5%
    // Invariant: threshold for delta change after deposit/withdraw
    uint256 deltaStepThreshold; // in 1e4; e.g. 500 = 5%
    // Invariant: upper limit of debt ratio after rebalance
    uint256 debtRatioUpperLimit; // in 1e4; e.g. 6900 = 0.69
    // Invariant: lower limit of debt ratio after rebalance
    uint256 debtRatioLowerLimit; // in 1e4; e.g. 6100 = 0.61
    // Invariant: upper limit of delta after rebalance
    int256 deltaUpperLimit; // in 1e4; e.g. 10500 = 1.05
    // Invariant: lower limit of delta after rebalance
    int256 deltaLowerLimit; // in 1e4; e.g. 9500 = 0.95
    // Minimum execution fee required
    uint256 minExecutionFee; // in 1e18

    // Token A in this strategy; long token + index token
    IERC20 tokenA;
    // Token B in this strategy; short token
    IERC20 tokenB;
    // LP token of this strategy; market token
    IERC20 lpToken;
    // Native token for this chain (e.g. WETH, WAVAX, WBNB, etc.)
    IWNT WNT;

    // Token A lending vault
    ILendingVault tokenALendingVault;
    // Token B lending vault
    ILendingVault tokenBLendingVault;

    // Vault address
    IGMXVault vault;
    // Queue contract address; if address(0) it means there is no queue enabled
    address queue;
    // Callback contract address; if address(0) it means there is no callback enabled
    address callback;

    // Chainlink Oracle contract address
    IChainlinkOracle chainlinkOracle;
    // GMX Oracle contract address
    IGMXOracle gmxOracle;

    // GMX exchange router contract address
    IExchangeRouter exchangeRouter;
    // GMX router contract address
    address router;
    // GMX deposit vault address
    address depositVault;
    // GMX withdrawal vault address
    address withdrawalVault;
    // GMX order vault address
    address orderVault;
    // GMX role store address
    address roleStore;

    // Status of the vault
    Status status;

    // Timestamp when vault last collected management fee
    uint256 lastFeeCollected;
    // Timestamp when last user deposit happened
    uint256 lastDepositBlock;

    // DepositCache
    DepositCache depositCache;
    // WithdrawCache
    WithdrawCache withdrawCache;
    // RebalanceAddCache
    RebalanceAddCache rebalanceAddCache;
    // RebalanceRemoveCache
    RebalanceRemoveCache rebalanceRemoveCache;
    // CompoundCache
    CompoundCache compoundCache;
  }

  struct DepositCache {
    // Address of user that is depositing
    address payable user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // USD value of deposit in 1e18; filled by vault
    uint256 depositValue;
    // Amount of shares to mint in 1e18; filled by vault
    uint256 sharesToUser;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct WithdrawCache {
    // Address of user that is withdrawing
    address payable user;
    // Timestamp of withdrawal created, filled by vault
    uint256 timestamp;
    // Ratio of shares out of total supply of shares to burn; filled by vault
    uint256 shareRatio;
    // Actual amount of withdraw token that user receives
    uint256 withdrawTokenAmt;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // RepayParams
    RepayParams repayParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct RebalanceAddCache {
    // This should be the approved keeper address; filled by vault
    address payable user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // RebalanceAddParams
    RebalanceAddParams rebalanceAddParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct RebalanceRemoveCache {
    // This should be the approved keeper address; filled by vault
    address payable user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // RebalanceRemoveParams
    RebalanceRemoveParams rebalanceRemoveParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct CompoundCache {
    // This should be the approved keeper address; filled by vault
    address payable user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // CompoundParams
    CompoundParams compoundParams;
  }

  struct DepositParams {
    // Address of token depositing; can be tokenA, tokenB or lpToken
    address token;
    // Amount of token to deposit in token decimals
    uint256 amt;
    // Minimum amount of shares to receive in 1e18
    uint256 minSharesAmt;
    // Slippage tolerance for adding liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // TODO Timestamp of deadline
    uint256 deadline;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct WithdrawParams {
    // Amount of shares to burn in 1e18
    uint256 shareAmt;
    // Address of token to withdraw to; could be tokenA, tokenB or lpToken
    address token;
    // Minimum amount of token to receive in token decimals
    uint256 minWithdrawTokenAmt;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // TODO Timestamp of deadline
    uint256 deadline;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
    // Amount of shares to remove in 1e18; filled by vault
    uint256 lpAmtToRemove;
    // SwapParams Swap for repay parameters
    SwapParams swapForRepayParams;
    // SwapParams Swap for withdraw parameters
    SwapParams swapForWithdrawParams;
  }

  struct RebalanceAddParams {
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // RepayParams
    RepayParams repayParams;
  }

  struct RebalanceRemoveParams {
    // Amount of LP tokens to remove
    uint256 lpAmtToRemove;
    // DepositParams
    DepositParams depositParams;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // BorrowParams
    BorrowParams borrowParams;
    // RepayParams
    RepayParams repayParams;
    // SwapParams Swap for repay parameters
    SwapParams swapForRepayParams;
  }

  struct CompoundParams {
    // SwapParams
    SwapParams swapParams;
    // DepositParams
    DepositParams depositParams;
  }

  struct AddLiquidityParams {
    // Amount of tokenA to add liquidity
    uint256 tokenAAmt;
    // Amount of tokenB to add liquidity
    uint256 tokenBAmt;
    // Slippage tolerance for adding liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct RemoveLiquidityParams {
    // Amount of lpToken to remove liquidity
    uint256 lpTokenAmt;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
  }

  struct BorrowParams {
    // Amount of tokenA to borrow in tokenA decimals
    uint256 borrowTokenAAmt;
    // Amount of tokenB to borrow in tokenB decimals
    uint256 borrowTokenBAmt;
  }

  struct RepayParams {
    // Amount of tokenA to repay in tokenA decimals
    uint256 repayTokenAAmt;
    // Amount of tokenB to repay in tokenB decimals
    uint256 repayTokenBAmt;
  }

  struct SwapParams {
    // Address of token swapping from; filled by vault
    address tokenFrom;
    // Address of token swapping to; filled by vault
    address tokenTo;
    // Amount of token swapping from; filled by vault
    uint256 tokenFromAmt;
    // Slippage tolerance swap; e.g. 3 = 0.03%
    uint256 slippage;
    // TODO Timestamp of deadline
    uint256 deadline;
    // Execution fee sent to GMX for swap orders
    uint256 executionFee;
    // Order key from GMX in bytes32
    bytes32 orderKey;
  }

  struct HealthParams {
    // USD value of equity in 1e18
    uint256 equityBefore;
    // Debt ratio in 1e18
    uint256 debtRatioBefore;
    // Delta in 1e18
    int256 deltaBefore;
    // LP token balance in 1e18
    uint256 lpAmtBefore;
    // Debt amount of tokenA in token decimals
    uint256 debtAmtTokenABefore;
    // Debt amount of tokenB in token decimals
    uint256 debtAmtTokenBBefore;
    // USD value of equity in 1e18
    uint256 equityAfter;
    // svToken value before in 1e18
    uint256 svTokenValueBefore;
    // // svToken value after in 1e18
    uint256 svTokenValueAfter;
  }

  /* ========== ENUM ========== */

  enum Status {
    // Vault is not open for any action
    Closed,
    // Vault is open for deposit/withdraw/rebalance
    Open,
    // User is depositing assets
    Deposit,
    // Vault is borrowing assets
    Borrow,
    // Vault is swapping for adding liquidity; note: unused
    Swap_For_Add,
    // Vault is adding liquidity
    Add_Liquidity,
    // Vault is minting shares
    Mint,
    // Vault is staking LP token; note: unused
    Stake,
    // User is withdrawing assets
    Withdraw,
    // Vault is unstaking LP token; note: unused
    Unstake,
    // Vault is removing liquidity
    Remove_Liquidity,
    // Vault is swapping assets for repayments
    Swap_For_Repay,
    // Vault is repaying assets
    Repay,
    // Vault is swapping assets for withdrawal
    Swap_For_Withdraw,
    // Vault is burning shares
    Burn,
    // Vault is rebalancing by adding more debt
    Rebalance_Add,
    // Vault is borrowing during rebalancing add
    Rebalance_Add_Borrow,
    // Vault is repaying during rebalancing add
    Rebalance_Add_Repay,
    // Vault is swapping for adding liquidity during rebalancing add; note: unused
    Rebalance_Add_Swap_For_Add,
    // Vault is adding liquidity during rebalancing add
    Rebalance_Add_Add_Liquidity,
    // Vault is rebalancing by reducing debt
    Rebalance_Remove,
    // Vault is removing liquidity during rebalancing remove
    Rebalance_Remove_Remove_Liquidity,
    // Vault is borrowing during rebalancing remove
    Rebalance_Remove_Borrow,
    // Vault is swapping for repay during rebalancing remove
    Rebalance_Remove_Swap_For_Repay,
    // Vault is repaying during rebalancing remove
    Rebalance_Remove_Repay,
    // Vault is swapping for adding liquidity during rebalancing remove; note: unused
    Rebalance_Remove_Swap_For_Add,
    // Vault is adding liquidity during rebalancing remove
    Rebalance_Remove_Add_Liquidity,
    // Vault is starting to compound
    Compound,
    // Vault is swapping during compound
    Compound_Swap,
    // Vault is adding liquidity during compound
    Compound_Add_Liquidity,
    // Vault is has added liquidity during compound
    Compound_Liquidity_Added,
    // Vault is performing an emergency shutdown
    Emergency_Shutdown,
    // // Vault is performing an emergency resume
    Emergency_Resume
  }

  enum Delta {
    Neutral,
    Long
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IExchangeRouter } from  "../../interfaces/protocols/gmx/IExchangeRouter.sol";
import { GMXTypes } from "./GMXTypes.sol";

library GMXWorker {

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
    * @dev Add strategy's tokens for liquidity and receive LP tokens
    * @param self Vault store data
    * @param alp GMXTypes.AddLiquidityParams
    * @return depositKey Hashed key of created deposit in bytes32
  */
  function addLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.AddLiquidityParams memory alp
  ) external returns (bytes32) {
    // Send native token for execution fee
    self.exchangeRouter.sendWnt{ value: alp.executionFee }(
      self.depositVault,
      alp.executionFee
    );

    // Send tokens
    self.exchangeRouter.sendTokens(
      address(self.tokenA),
      self.depositVault,
      alp.tokenAAmt
    );

    self.exchangeRouter.sendTokens(
      address(self.tokenB),
      self.depositVault,
      alp.tokenBAmt
    );

    // TODO calculate slippage in minMarketTokens
    // alp.slippage

    // Create deposit
    IExchangeRouter.CreateDepositParams memory _cdp =
      IExchangeRouter.CreateDepositParams({
        receiver: address(this),
        callbackContract: self.callback,
        uiFeeReceiver: address(0), // TODO uiFeeReceiver?
        market: address(self.lpToken),
        initialLongToken: address(self.tokenA),
        initialShortToken: address(self.tokenB),
        longTokenSwapPath: new address[](0),
        shortTokenSwapPath: new address[](0),
        minMarketTokens: 0,
        shouldUnwrapNativeToken: false,
        executionFee: alp.executionFee,
        callbackGasLimit: 2000000
      });

    return self.exchangeRouter.createDeposit(_cdp);
  }

  /**
    * @dev Remove liquidity of strategy's LP token and receive underlying tokens
    * @param self Vault store data
    * @param rlp GMXTypes.RemoveLiquidityParams
    * @return withdrawKey Hashed key of created withdraw in bytes32
  */
  function removeLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.RemoveLiquidityParams memory rlp
  ) external returns (bytes32) {
    // Send native token for execution fee
    self.exchangeRouter.sendWnt{value: rlp.executionFee }(
      self.withdrawalVault,
      rlp.executionFee
    );

    // Send GM LP tokens
    self.exchangeRouter.sendTokens(
      address(self.lpToken),
      self.withdrawalVault,
      rlp.lpTokenAmt
    );

    // TODO address slippage
    // TODO address slippage in minLongTokenAmount/minShortTokenAmount

    // Create withdrawal
    IExchangeRouter.CreateWithdrawalParams memory _cwp =
      IExchangeRouter.CreateWithdrawalParams({
        receiver: address(this),
        callbackContract: self.callback,
        uiFeeReceiver: address(0),
        market: address(self.lpToken),
        longTokenSwapPath: new address[](0),
        shortTokenSwapPath: new address[](0),
        minLongTokenAmount: 0,
        minShortTokenAmount: 0,
        shouldUnwrapNativeToken: false,
        executionFee: rlp.executionFee,
        callbackGasLimit: 2000000
      });

    return self.exchangeRouter.createWithdrawal(_cwp);
  }

  /**
    * @dev Swap one token for another token
    * @param self Vault store data
    * @param sp GMXTypes.SwapParams struct
    * @return swapKey Key hash of order created
  */
  function swap(
    GMXTypes.Store storage self,
    GMXTypes.SwapParams memory sp
  ) external returns (bytes32) {
    // Send native token for execution fee
    self.exchangeRouter.sendWnt{value: sp.executionFee}(
      self.orderVault,
      sp.executionFee
    );

    // Send tokens
    self.exchangeRouter.sendTokens(
      sp.tokenFrom,
      self.orderVault,
      sp.tokenFromAmt
    );

    address[] memory _swapPath = new address[](1);
    _swapPath[0] = address(self.lpToken);

    IExchangeRouter.CreateOrderParamsAddresses memory _addresses;
    _addresses.receiver = address(this);
    _addresses.initialCollateralToken = sp.tokenFrom;
    _addresses.callbackContract = self.callback;
    _addresses.market = address(0);
    _addresses.swapPath = _swapPath;
    _addresses.uiFeeReceiver = address(0);

    IExchangeRouter.CreateOrderParamsNumbers memory _numbers;
    _numbers.sizeDeltaUsd = 0;
    _numbers.initialCollateralDeltaAmount = 0;
    _numbers.triggerPrice = 0;
    _numbers.acceptablePrice = 0;
    _numbers.executionFee = sp.executionFee;
    _numbers.callbackGasLimit = 2000000;
    _numbers.minOutputAmount = 0; // TODO

    IExchangeRouter.CreateOrderParams memory _params =
      IExchangeRouter.CreateOrderParams({
        addresses: _addresses,
        numbers: _numbers,
        orderType: IExchangeRouter.OrderType.MarketSwap,
        decreasePositionSwapType: IExchangeRouter.DecreasePositionSwapType.NoSwap,
        isLong: false,
        shouldUnwrapNativeToken: false,
        referralCode: bytes32(0)
      });

    // Returns bytes32 orderKey
    return self.exchangeRouter.createOrder(_params);

    // Note that keeper is needed to continue the swap once GMX keeper has fulfilled it
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Errors {

  /* ========== AUTHORIZATION ========== */

  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();
  error OnlyBorrowerAllowed();
  error OnlyCallbackOrKeeperAllowed();
  error OnlyQueueAllowed();

  /* ========== LENDING ========== */

  error InsufficientBorrowAmount();
  error InsufficientRepayAmount();
  error BorrowerAlreadyApproved();
  error BorrowerAlreadyRevoked();
  error InsufficientLendingLiquidity();
  error InsufficientAssetsBalance();

  /* ========== VAULT DEPOSIT ========== */

  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error OnlyNonNativeDepositToken();
  error InvalidNativeTokenAddress();
  error DepositAndExecutionFeeDoesNotMatchMsgValue();
  error InvalidExecutionFeeAmount();
  error InsufficientExecutionFeeAmount();
  error InsufficientSecurityDeposit();

  /* ========== VAULT WITHDRAWAL ========== */

  error EmptyWithdrawAmount();
  error InvalidWithdrawToken();
  error InsufficientWithdrawAmount();
  error InsufficientWithdrawBalance();
  error InsufficientAssetsReceived();
  error WithdrawNotAllowedInSameDepositBlock();

  /* ========== VAULT REBALANCE ========== */

  error InvalidDebtRatio();
  error InvalidDelta();
  error InvalidEquity();
  error InsufficientLPTokensMinted();
  error InsufficientLPTokensBurned();
  error InvalidRebalancePreConditions();
  error InvalidRebalanceDebtAmounts();

  /* ========== VAULT CALLBACKS ========== */

  error InvalidDepositKey();
  error InvalidWithdrawKey();
  error InvalidOrderKey();
  error InvalidCallbackHandler();

  /* ========== ORACLE ========== */

  error NoTokenPriceFeedAvailable();
  error FrozenTokenPriceFeed();
  error BrokenTokenPriceFeed();
  error TokenPriceFeedAlreadySet();
  error TokenPriceFeedMaxDelayMustBeGreaterOrEqualToZero();
  error TokenPriceFeedMaxDeviationMustBeGreaterOrEqualToZero();
  error InvalidTokenInLPPool();
  error InvalidReservesInLPPool();
  error OrderAmountOutMustBeGreaterThanZero();
  error SequencerDown();
  error GracePeriodNotOver();

  /* ========== GENERAL ========== */

  error NotAllowedInCurrentVaultStatus();
  error ZeroAddressNotAllowed();
  error TokenDecimalsMustBeLessThan18();
}