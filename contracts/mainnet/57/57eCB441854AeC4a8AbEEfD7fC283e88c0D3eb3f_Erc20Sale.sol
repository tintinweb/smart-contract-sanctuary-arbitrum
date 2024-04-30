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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @title erc20 lock data
struct Erc20LockData {
    /// @notice locked token
    address token;
    /// @notice the address with withdraw right for position
    address withdrawer;
    /// @notice position unlock time or unlock time interval if step-by-step
    uint256 creationTime;
    /// @notice position unlock time interval
    uint256 timeInterval;
    /// @notice how many tokens are withdrawed already
    uint256 withdrawedCount;
    /// @notice whole lock count
    uint256 count;
    /// @notice if >0 than unlock is step-by-step and this equal for one unlock count
    uint256 stepByStepUnlockCount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../IAssetLocker.sol';
import './Erc20LockData.sol';

/// @title erc20 lock algorithm
interface IErc20Locker is IAssetLocker {
    /// @notice returns the locked position data
    /// @param id id of position
    /// @return Erc20LockData the locked position data
    function position(uint256 id) external view returns (Erc20LockData memory);

    /// @notice locks the erc20 tokens, that can be withdrawed by certait address
    /// @param token token address
    /// @param count token count without decimals
    /// @param unlockTime token unlock time
    /// @param withdrawer the address with withdraw right for position
    function lockTimeFor(
        address token,
        uint256 count,
        uint256 unlockTime,
        address withdrawer
    ) external;

    /// @notice locks the erc20 tokens, that can be withdraw by caller address
    /// @param token token address
    /// @param count token count without decimals
    /// @param unlockTime token unlock time
    function lockTime(
        address token,
        uint256 count,
        uint256 unlockTime
    ) external;

    /// @notice locks the token, that can be withdrawed by certait address
    /// @param token token address
    /// @param count token count without decimals
    /// @param seconds_ seconds for lock
    /// @param withdrawer the address with withdraw right for position
    function lockSecondsFor(
        address token,
        uint256 count,
        uint256 seconds_,
        address withdrawer
    ) external;

    /// @notice locks the token, that can be withdrawed by certait address
    /// @param token token address
    /// @param count token count without decimals
    /// @param seconds_ seconds for lock
    function lockSeconds(
        address token,
        uint256 count,
        uint256 seconds_
    ) external;

    /// @notice locks the step-by-step unlocking position
    /// @param tokenAddress token address
    /// @param count token count without decimals for lock
    /// @param withdrawer the address with withdraw right for position
    /// @param interval the interval for unlock
    /// @param stepByStepUnlockCount how many tokens are unlocked each interval
    function lockStepByStepUnlocking(
        address tokenAddress,
        uint256 count,
        address withdrawer,
        uint256 interval,
        uint256 stepByStepUnlockCount
    ) external;

    /// @notice remaining tokens for withdraw
    function remainingTokensToWithdraw(uint256 id) external view returns (uint256);

    /// @notice unlocked tokens count. All unlocked tokens.(withdrawen and not)
    function unlockedCount(uint256 id) external view returns (uint256);

    /// @notice unlocked tokens count. Available for withdraw
    function unlockedCountWithdrawAvailable(uint256 id) external view returns (uint256);

    /// @notice the unlock all time
    function unlockAllTime(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @title used to block asset for any time
interface IAssetLocker {
    /// @notice new position locked
    /// @param id id of new locked position
    event OnLockPosition(uint256 id);
    /// @notice position withdrawed
    /// @param id id of new locked position
    event OnWithdraw(uint256 id);

    /// @notice total created positions count
    function positionsCount() external view returns (uint256);

    /// @notice returns tax system contract address
    function feeSettings() external view returns (address);

    /// @notice the address with withdraw right for position
    /// @param id id of position
    /// @return address the address with withdraw right for position
    function withdrawer(uint256 id) external view returns (address);

    /// @notice time when the position will be unlocked (only full unlock)
    /// @param id id of position
    /// @return uint256 linux epoh time, when unlock or 0 if lock permanently
    function unlockTime(uint256 id) external view returns (uint256);

    /// @notice  returns true, if position is locked
    /// @param id id of position
    /// @return bool true if locked
    function isLocked(uint256 id) external view returns (bool);

    /// @notice if true than position is already withdrawed
    /// @param id id of position
    /// @return bool true if position is withdrawed
    function withdrawed(uint256 id) external view returns (bool);

    /// @notice withdraws the position
    /// @param id id of position
    function withdraw(uint256 id) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @title the fee settings of GigaSwap system interface
interface IFeeSettings {
    /// @notice address to pay fee
    function feeAddress() external view returns (address);

    /// @notice fee in 1/decimals for dividing values
    function feePercent() external view returns (uint256);

    /// @notice account fee share
    /// @dev used only if asset is dividing
    /// @dev fee in 1/feeDecimals for dividing values
    /// @param account the account, that can be hold GigaSwap token
    /// @return uint256 asset fee share in 1/feeDecimals
    function feePercentFor(address account) external view returns (uint256);

    /// @notice account fee for certain asset count
    /// @dev used only if asset is dividing
    /// @param account the account, that can be hold GigaSwap token
    /// @param count asset count for calculate fee
    /// @return uint256 asset fee count
    function feeForCount(
        address account,
        uint256 count
    ) external view returns (uint256);

    /// @notice decimals for fee shares
    function feeDecimals() external view returns (uint256);

    /// @notice fix fee value
    /// @dev used only if asset is not dividing
    function feeEth() external view returns (uint256);

    /// @notice fee in 1/decimals for dividing values
    function feeEthFor(address account) external view returns (uint256);

    /// @notice if account balance is greather than or equal this value, than this account has no fee
    function zeroFeeShare() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'contracts/fee/IFeeSettings.sol';
import './IErc20Sale.sol';
import '../lib/ownable/Ownable.sol';
import 'contracts/asset_lockers/erc20/IErc20Locker.sol';

struct BuyFunctionData {
    uint256 spend;
    uint256 lastCount;
    uint256 transferred;
    uint256 sendCount;
}

contract Erc20Sale is IErc20Sale {
    using SafeERC20 for IERC20;

    IFeeSettings public immutable feeSettings;
    IErc20Locker public immutable locker;
    mapping(uint256 => PositionData) _positions;
    mapping(uint256 => mapping(address => bool)) _whiteLists;
    mapping(uint256 => uint256) _limits;
    mapping(uint256 => mapping(address => uint256)) _usedLimits;
    mapping(uint256 => OfferData) _offers;
    mapping(uint256 => BuyLockSettings) _lockSettings;
    uint256 public totalOffers;
    uint256 _totalPositions;

    constructor(address feeSettings_, address locker_) {
        feeSettings = IFeeSettings(feeSettings_);
        locker = IErc20Locker(locker_);
    }

    function createPosition(
        address asset1,
        address asset2,
        uint256 priceNom,
        uint256 priceDenom,
        uint256 count,
        uint256 buyLimit,
        address[] calldata whiteList,
        BuyLockSettings calldata lockSettings
    ) external {
        uint8 flags = 0;
        if (count > 0) {
            uint256 lastCount = IERC20(asset1).balanceOf(address(this));
            IERC20(asset1).safeTransferFrom(msg.sender, address(this), count);
            count = IERC20(asset1).balanceOf(address(this)) - lastCount;
        }

        // calculate position flags
        if (buyLimit > 0) flags |= BUYLIMIT_FLAG;
        if (whiteList.length > 0) flags |= WHITELIST_FLAG;
        if (lockSettings.lockTime > 0) flags |= LOCK_FLAG;

        _positions[++_totalPositions] = PositionData(
            msg.sender,
            asset1,
            asset2,
            priceNom,
            priceDenom,
            count,
            0,
            flags
        );

        if (flags & LOCK_FLAG > 0) {
            require(
                lockSettings.receivePercent < LOCK_PRECISION,
                'receive percent in lock must be less than 100% for lock'
            );
            require(
                lockSettings.receivePercent +
                    lockSettings.unlockPercentByTime <=
                    LOCK_PRECISION,
                'lock settings is not correct: receivePercent+unlockPercentByTime > LOCK_PRECISION'
            );
            _lockSettings[_totalPositions] = lockSettings;
        }

        if (buyLimit > 0) _limits[_totalPositions] = buyLimit;
        for (uint256 i = 0; i < whiteList.length; ++i)
            _whiteLists[_totalPositions][whiteList[i]] = true;

        emit OnCreate(_totalPositions);
        if (whiteList.length > 0)
            emit OnWhiteListed(_totalPositions, true, whiteList);
    }

    function createOffer(
        uint256 positionId,
        uint256 asset1Count,
        uint256 asset2Count
    ) external {
        // get position data
        PositionData memory position = _positions[positionId];
        require(position.owner != address(0), 'position is not exists');

        // create offer
        ++totalOffers;
        _offers[totalOffers].positionId = positionId;
        _offers[totalOffers].state = 1;
        _offers[totalOffers].owner = msg.sender;
        _offers[totalOffers].asset1Count = asset1Count;
        _offers[totalOffers].asset2Count = asset2Count;

        // transfer asset
        uint256 lastCount = IERC20(position.asset2).balanceOf(address(this));
        IERC20(position.asset2).safeTransferFrom(
            msg.sender,
            address(this),
            asset2Count
        );
        _offers[totalOffers].asset2Count =
            IERC20(position.asset2).balanceOf(address(this)) -
            lastCount;

        // event
        emit OnOfer(positionId, totalOffers);
    }

    function removeOffer(uint256 offerId) external {
        OfferData storage offer = _offers[offerId];
        require(offer.state == 1, 'offer is not created or already used');
        require(offer.owner == msg.sender, 'only owner can remove the offer');
        offer.state = 0;
        PositionData memory position = _positions[offer.positionId];
        IERC20(position.asset2).safeTransferFrom(
            address(this),
            offer.owner,
            offer.asset2Count
        );
        emit OnRemoveOfer(offer.positionId, offerId);
    }

    function applyOffer(uint256 offerId) external {
        // get offer
        OfferData storage offer = _offers[offerId];
        require(offer.state == 1, 'offer is not created or already used');
        offer.state = 2;

        // get position data
        PositionData storage pos = _positions[offer.positionId];
        require(pos.owner != address(0), 'position is not exists');
        require(pos.owner == msg.sender, 'only owner can apply offer');

        // buyCount
        uint256 buyCount_ = offer.asset1Count;
        require(
            buyCount_ <= pos.count1,
            'not enough owner asset to apply offer'
        );
        require(buyCount_ > 0, 'nothing to buy');

        // transfer the buy asset
        if (pos.flags & LOCK_FLAG > 0) {
            IERC20(pos.asset1).approve(address(locker), type(uint256).max);
            BuyLockSettings memory lockSettings = _lockSettings[
                offer.positionId
            ];
            uint256 sendCount = (buyCount_ * lockSettings.receivePercent) /
                LOCK_PRECISION;
            if (sendCount > 0) {
                uint256 fee = feeSettings.feeForCount(offer.owner, sendCount);
                if (fee > 0)
                    IERC20(pos.asset1).safeTransfer(
                        feeSettings.feeAddress(),
                        fee
                    );
                IERC20(pos.asset1).safeTransfer(offer.owner, sendCount - fee);
            }
            locker.lockStepByStepUnlocking(
                pos.asset1,
                buyCount_ - sendCount,
                offer.owner,
                lockSettings.lockTime,
                ((buyCount_ - sendCount) * lockSettings.unlockPercentByTime) /
                    LOCK_PRECISION
            );
        } else {
            // calculate the fee of buy count
            uint256 buyFee = feeSettings.feeForCount(offer.owner, buyCount_);
            if (buyFee > 0) {
                IERC20(pos.asset1).safeTransfer(
                    feeSettings.feeAddress(),
                    buyFee
                );
            }
            // transfer buy asset
            IERC20(pos.asset1).safeTransfer(offer.owner, buyCount_ - buyFee);
        }

        // transfer asset2 to position
        pos.count1 -= buyCount_;

        uint256 sellFee = feeSettings.feeForCount(pos.owner, offer.asset2Count);
        if (sellFee > 0) {
            IERC20(pos.asset2).safeTransfer(feeSettings.feeAddress(), sellFee);
        }
        pos.count2 += offer.asset2Count - sellFee;

        // event
        emit OnApplyOfer(offer.positionId, offerId);
    }

    function getOffer(
        uint256 offerId
    ) external view returns (OfferData memory) {
        return _offers[offerId];
    }

    function addBalance(uint256 positionId, uint256 count) external {
        PositionData storage pos = _positions[positionId];
        uint256 lastCount = IERC20(pos.asset1).balanceOf(address(this));
        IERC20(pos.asset1).safeTransferFrom(msg.sender, address(this), count);
        pos.count1 += IERC20(pos.asset1).balanceOf(address(this)) - lastCount;
    }

    function withdraw(
        uint256 positionId,
        uint256 assetCode,
        address to,
        uint256 count
    ) external {
        _withdraw(positionId, _positions[positionId], assetCode, to, count);
    }

    function withdrawAllTo(
        uint256 positionId,
        uint256 assetCode,
        address to
    ) external {
        PositionData storage pos = _positions[positionId];
        if (assetCode == 1)
            _withdraw(
                positionId,
                _positions[positionId],
                assetCode,
                to,
                pos.count1
            );
        else if (assetCode == 2)
            _withdraw(
                positionId,
                _positions[positionId],
                assetCode,
                to,
                pos.count2
            );
        else revert('unknown asset code');
    }

    function withdrawAll(uint256 positionId, uint256 assetCode) external {
        PositionData storage pos = _positions[positionId];
        if (assetCode == 1)
            _withdraw(
                positionId,
                _positions[positionId],
                assetCode,
                msg.sender,
                pos.count1
            );
        else if (assetCode == 2)
            _withdraw(
                positionId,
                _positions[positionId],
                assetCode,
                msg.sender,
                pos.count2
            );
        else revert('unknown asset code');
    }

    function _withdraw(
        uint256 positionId,
        PositionData storage pos,
        uint256 assetCode,
        address to,
        uint256 count
    ) private {
        require(pos.owner == msg.sender, 'only for position owner');

        if (assetCode == 1) {
            require(pos.count1 >= count, 'not enough asset count');
            uint256 lastCount = IERC20(pos.asset1).balanceOf(address(this));
            IERC20(pos.asset1).safeTransfer(to, count);
            uint256 transferred = lastCount -
                IERC20(pos.asset1).balanceOf(address(this));
            require(
                pos.count1 >= transferred,
                'not enough asset count after withdraw'
            );
            pos.count1 -= transferred;
        } else if (assetCode == 2) {
            require(pos.count2 >= count, 'not enough asset count');
            uint256 lastCount = IERC20(pos.asset2).balanceOf(address(this));
            IERC20(pos.asset2).safeTransfer(to, count);
            uint256 transferred = lastCount -
                IERC20(pos.asset2).balanceOf(address(this));
            require(
                pos.count2 >= transferred,
                'not enough asset count after withdraw'
            );
            pos.count2 -= transferred;
        } else revert('unknown asset code');

        emit OnWithdraw(positionId, assetCode, to, count);
    }

    function setPrice(
        uint256 positionId,
        uint256 priceNom,
        uint256 priceDenom
    ) external {
        PositionData storage pos = _positions[positionId];
        require(pos.owner == msg.sender, 'only for position owner');
        pos.priceNom = priceNom;
        pos.priceDenom = priceDenom;
        emit OnPrice(positionId);
    }

    function setWhiteList(
        uint256 positionId,
        bool whiteListed,
        address[] calldata accounts
    ) external {
        PositionData storage pos = _positions[positionId];
        require(pos.owner == msg.sender, 'only for position owner');
        for (uint256 i = 0; i < accounts.length; ++i) {
            _whiteLists[positionId][accounts[i]] = whiteListed;
        }

        emit OnWhiteListed(positionId, whiteListed, accounts);
    }

    function isWhiteListed(
        uint256 positionId,
        address account
    ) external view returns (bool) {
        return _whiteLists[positionId][account];
    }

    function enableWhiteList(uint256 positionId, bool enabled) external {
        PositionData storage pos = _positions[positionId];
        require(pos.owner == msg.sender, 'only for position owner');

        if (enabled) pos.flags |= WHITELIST_FLAG;
        else pos.flags &= ~WHITELIST_FLAG;

        emit OnWhiteListEnabled(positionId, enabled);
    }

    function enableBuyLimit(uint256 positionId, bool enabled) external {
        PositionData storage pos = _positions[positionId];
        require(pos.owner == msg.sender, 'only for position owner');

        if (enabled) pos.flags |= BUYLIMIT_FLAG;
        else pos.flags &= ~BUYLIMIT_FLAG;

        emit OnBuyLimitEnable(positionId, enabled);
    }

    function setBuyLimit(uint256 positionId, uint256 limit) external {
        PositionData storage pos = _positions[positionId];
        require(pos.owner == msg.sender, 'only for position owner');

        _limits[positionId] = limit;

        emit OnBuyLimit(positionId, limit);
    }

    function getBuyLimit(uint256 positionId) external view returns (uint256) {
        return _limits[positionId];
    }

    function buy(
        uint256 positionId,
        address to,
        uint256 count,
        uint256 priceNom,
        uint256 priceDenom,
        address antibot
    ) external {
        PositionData storage pos = _positions[positionId];
        BuyFunctionData memory data;

        // check antibot
        require(msg.sender == antibot, 'antibot');

        // check whitelist
        if (pos.flags & WHITELIST_FLAG > 0) {
            require(
                _whiteLists[positionId][msg.sender],
                'the account is not in whitelist'
            );
        }

        // check limit
        if (pos.flags & BUYLIMIT_FLAG > 0) {
            uint256 usedLimit = _usedLimits[positionId][msg.sender] + count;
            _usedLimits[positionId][msg.sender] = usedLimit;
            require(
                usedLimit <= _limits[positionId],
                'account buy limit is over'
            );
        }

        // price frontrun protection
        require(
            pos.priceNom == priceNom && pos.priceDenom == priceDenom,
            'the price is changed'
        );
        data.spend = _spendToBuy(pos, count);
        require(
            data.spend > 0,
            'spend asset count is zero (count parameter is less than minimum count to spend)'
        );

        // transfer buy
        require(pos.count1 >= count, 'not enough asset count at position');
        data.lastCount = IERC20(pos.asset1).balanceOf(address(this));

        // transfer to buyer
        if (pos.flags & LOCK_FLAG > 0) {
            IERC20(pos.asset1).approve(address(locker), type(uint256).max);
            BuyLockSettings memory lockSettings = _lockSettings[positionId];
            data.sendCount =
                (count * lockSettings.receivePercent) /
                LOCK_PRECISION;
            if (data.sendCount > 0) {
                uint256 fee = feeSettings.feeForCount(to, data.sendCount);
                if (fee > 0)
                    IERC20(pos.asset1).safeTransfer(
                        feeSettings.feeAddress(),
                        fee
                    );
                IERC20(pos.asset1).safeTransfer(to, data.sendCount - fee);
            }
            locker.lockStepByStepUnlocking(
                pos.asset1,
                count - data.sendCount,
                to,
                lockSettings.lockTime,
                ((count - data.sendCount) * lockSettings.unlockPercentByTime) /
                    LOCK_PRECISION
            );
        } else {
            uint256 fee = feeSettings.feeForCount(to, count);
            if (fee > 0)
                IERC20(pos.asset1).safeTransfer(feeSettings.feeAddress(), fee);
            IERC20(pos.asset1).safeTransfer(to, count - fee);
        }
        data.transferred =
            data.lastCount -
            IERC20(pos.asset1).balanceOf(address(this));
        require(
            pos.count1 >= data.transferred,
            'not enough asset count after withdraw'
        );
        pos.count1 -= data.transferred;

        // transfer spend
        data.lastCount = IERC20(pos.asset2).balanceOf(address(this));
        uint256 sellFee = feeSettings.feeForCount(pos.owner, data.spend);
        if (sellFee > 0) {
            IERC20(pos.asset2).safeTransferFrom(
                msg.sender,
                feeSettings.feeAddress(),
                sellFee
            );
        }
        IERC20(pos.asset2).safeTransferFrom(
            msg.sender,
            address(this),
            data.spend - sellFee
        );
        pos.count2 +=
            IERC20(pos.asset2).balanceOf(address(this)) -
            data.lastCount;

        // emit event
        emit OnBuy(positionId, to, count);
    }

    function spendToBuy(
        uint256 positionId,
        uint256 count
    ) external view returns (uint256) {
        return _spendToBuy(_positions[positionId], count);
    }

    function buyCount(
        uint256 positionId,
        uint256 spend
    ) external view returns (uint256) {
        PositionData memory pos = _positions[positionId];
        return (spend * pos.priceDenom) / pos.priceNom;
    }

    function _spendToBuy(
        PositionData memory pos,
        uint256 count
    ) private pure returns (uint256) {
        return (count * pos.priceNom) / pos.priceDenom;
    }

    function getPosition(
        uint256 positionId
    ) external view returns (PositionData memory) {
        return _positions[positionId];
    }

    function getPositionLockSettings(
        uint256 positionId
    ) external view returns (BuyLockSettings memory) {
        return _lockSettings[positionId];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IErc20SaleCounterOffer.sol';

/// @dev has whiteList
uint8 constant WHITELIST_FLAG = 1 << 0;
/// @dev has buy limit by addresses
uint8 constant BUYLIMIT_FLAG = 1 << 1;
/// @dev buy sends token to lock
uint8 constant LOCK_FLAG = 1 << 2;

/// @title the position main data
struct PositionData {
    /// @notice position owner
    address owner;
    /// @notice asset address, that sells owner
    address asset1;
    /// @notice asset address, that owner wish to buy
    address asset2;
    /// @notice price nomenator
    uint256 priceNom;
    /// @notice price denomenator
    uint256 priceDenom;
    /// @notice asset1 count
    uint256 count1;
    /// @notice asset2 count
    uint256 count2;
    /// @dev flags
    /// 0 - WHITELIST_FLAG has whiteList
    /// 1 - BUYLIMIT_FLAG has buy limit by addresses
    /// 2 - LOCK_FLAG buy sends token to lock
    uint8 flags;
}

/// @title settings for lock after token buy
struct BuyLockSettings {
    /// @notice receive token percent without lock.
    /// @dev see LOCK_PRECISION
    uint256 receivePercent;
    /// @notice lock time if unlockPercentByTime==0 or interval for unlock if unlockPercentByTime>0.
    /// @notice If this parameter is 0 than has no lock.
    uint256 lockTime;
    /// @notice percent for unlock every lockTime. Or 0 (or 100%) if unlock all after lockTime
    /// @dev see LOCK_PRECISION
    uint256 unlockPercentByTime;
}

/// @dev precision for lock after buy (0.01% ie. 100%=10000)
uint256 constant LOCK_PRECISION = 10000;

/// @title erc20sale contract
interface IErc20Sale is IErc20SaleCounterOffer {
    /// @notice when position created
    /// @param positionId id of position
    event OnCreate(uint256 indexed positionId);
    /// @notice when buy happens
    /// @param positionId id of position
    /// @param account buyer
    /// @param count buy count
    event OnBuy(
        uint256 indexed positionId,
        address indexed account,
        uint256 count
    );
    /// @notice position price changed
    /// @param positionId id of position
    event OnPrice(uint256 indexed positionId);
    /// @notice owner withdraw asset from position
    /// @param positionId id of position
    /// @param assetCode asset code
    /// @param to address to withdraw
    /// @param count asset count
    event OnWithdraw(
        uint256 indexed positionId,
        uint256 assetCode,
        address to,
        uint256 count
    );
    /// @notice white list is changed
    /// @param positionId id of position
    /// @param isWhiteListed witelisted or not
    /// @param accounts accounts list
    event OnWhiteListed(
        uint256 indexed positionId,
        bool isWhiteListed,
        address[] accounts
    );
    /// @notice white list is enabled
    /// @param positionId id of position
    /// @param enabled enabled or not
    event OnWhiteListEnabled(uint256 indexed positionId, bool enabled);
    /// @notice buy limit is enabled
    /// @param positionId id of position
    /// @param enable enabled or not
    event OnBuyLimitEnable(uint256 indexed positionId, bool enable);
    /// @notice buy limit is changed
    /// @param positionId id of position
    /// @param limit new buy limit
    event OnBuyLimit(uint256 indexed positionId, uint256 limit);

    /// @notice creates new position
    /// @param asset1 asset for sale
    /// @param asset2 asset that wish to buy
    /// @param priceNom price nomenator
    /// @param priceDenom price denomenator
    /// @param count count of asset to sale
    /// @param buyLimit one buy libit or zero
    /// @param whiteList if not empty - accounts, that can buy
    /// @param lockSettings settings if after buy use lock
    function createPosition(
        address asset1,
        address asset2,
        uint256 priceNom,
        uint256 priceDenom,
        uint256 count,
        uint256 buyLimit,
        address[] calldata whiteList,
        BuyLockSettings calldata lockSettings
    ) external;

    function addBalance(uint256 positionId, uint256 count) external;

    function withdraw(
        uint256 positionId,
        uint256 assetCode,
        address to,
        uint256 count
    ) external;

    function withdrawAllTo(
        uint256 positionId,
        uint256 assetCode,
        address to
    ) external;

    function withdrawAll(uint256 positionId, uint256 assetCode) external;

    function setPrice(
        uint256 positionId,
        uint256 priceNom,
        uint256 priceDenom
    ) external;

    function setWhiteList(
        uint256 positionId,
        bool whiteListed,
        address[] calldata accounts
    ) external;

    function isWhiteListed(
        uint256 positionId,
        address account
    ) external view returns (bool);

    function enableWhiteList(uint256 positionId, bool enabled) external;

    function enableBuyLimit(uint256 positionId, bool enabled) external;

    function setBuyLimit(uint256 positionId, uint256 limit) external;

    function getBuyLimit(uint256 positionId) external view returns (uint256);

    function buy(
        uint256 positionId,
        address to,
        uint256 count,
        uint256 priceNom,
        uint256 priceDenom,
        address antibot
    ) external;

    function spendToBuy(
        uint256 positionId,
        uint256 count
    ) external view returns (uint256);

    function buyCount(
        uint256 positionId,
        uint256 spend
    ) external view returns (uint256);

    function getPosition(
        uint256 positionId
    ) external view returns (PositionData memory);

    function getPositionLockSettings(
        uint256 positionId
    ) external view returns (BuyLockSettings memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @title the offer data
struct OfferData {
    /// @notice position id
    uint256 positionId;
    /// @notice asset 1 offer count
    uint256 asset1Count;
    /// @notice asset 2 offer count
    uint256 asset2Count;
    /// @notice state
    /// @dev 0 - not created
    /// @dev 1 - created
    /// @dev 2 - applied
    uint8 state;
    /// @notice the offer owner (creator)
    address owner;
}

/// @title the ecr20sales offers interface
interface IErc20SaleCounterOffer {
    /// @notice new offer created
    /// @param positionId the position id
    /// @param offerId the offer id
    event OnOfer(uint256 indexed positionId, uint256 indexed offerId);
    /// @notice the position owner has applyed the offer
    /// @param positionId the position id
    /// @param offerId the offer id
    event OnApplyOfer(uint256 indexed positionId, uint256 indexed offerId);
    /// @notice the offer has been removed
    /// @param positionId the position id
    /// @param offerId the offer id
    event OnRemoveOfer(uint256 indexed positionId, uint256 indexed offerId);

    /// @notice creates the new offer to positiion
    /// @param positionId the position id
    /// @param asset1Count offered asset1 count
    /// @param asset2Count offered asset2 count
    function createOffer(
        uint256 positionId,
        uint256 asset1Count,
        uint256 asset2Count
    ) external;

    /// @notice removes the offer
    /// @param offerId the offer id
    function removeOffer(uint256 offerId) external;

    /// @notice returns the offer data
    /// @param offerId the offer id
    function getOffer(uint256 offerId) external returns (OfferData memory);

    /// @notice applies the offer to the position
    /// @dev only by position owner
    function applyOffer(uint256 offerId) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/// @title enables owner of contract
interface IOwnable {
    /// @notice owner of contract
    function owner() external view returns (address);

    /// @notice transfers ownership of contract
    /// @param newOwner new owner of contract
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IOwnable.sol';

contract Ownable is IOwnable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'caller is not the owner');
        _;
    }

    function owner() external virtual view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }
}