// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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

import './IAssetLocker.sol';
import 'contracts/fee/IFeeSettings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @title used to block asset for any time
abstract contract AssetLockerBase is IAssetLocker, ReentrancyGuard {
    /// @notice total created positions count
    uint256 _positionsCount;
    /// @notice tax system contract
    IFeeSettings immutable _feeSettings;

    /// @notice constructor
    /// @param feeSettingsAddress tax system contract
    constructor(address feeSettingsAddress) {
        _feeSettings = IFeeSettings(feeSettingsAddress);
    }

    /// @notice allows only existing positions
    modifier OnlyExistingPosition(uint256 positionId) {
        require(_positionExists(positionId), 'position is not exists');
        _;
    }

    /// @notice total created positions count
    function positionsCount() external view returns (uint256) {
        return _positionsCount;
    }

    /// @notice returns tax system contract address
    function feeSettings() external view returns (address) {
        return address(_feeSettings);
    }

    /// @notice returns true, if position is locked
    /// @param id id of position
    /// @return bool true if locked
    function isLocked(uint256 id) external view returns (bool) {
        return _isLocked(id);
    }

    function _isLocked(uint256 id) internal view virtual returns (bool) {
        uint256 time = this.unlockTime(id);
        return time == 0 || time > block.timestamp;
    }

    /// @notice returns true if asset locked permanently
    /// @param id id of  position
    function isPermanentLock(uint256 id) external view returns (bool) {
        return this.unlockTime(id) == 0;
    }

    /// @notice withdraws the position
    /// @param id id of position
    function withdraw(uint256 id) external nonReentrant {
        require(!this.withdrawed(id), 'already withdrawed');
        require(!this.isPermanentLock(id), 'locked permanently');
        require(!this.isLocked(id), 'still locked');
        require(this.withdrawer(id) == msg.sender, 'only for withdrawer');
        _withdraw(id);
        _setWithdrawed(id);
        emit OnWithdraw(id);
    }

    /// @dev internal withdraw algorithm, asset speciffic
    /// @param id id of position
    function _withdraw(uint256 id) internal virtual;

    /// @dev internal sets position as withdrawed to prevent re-withdrawal
    /// @param id id of position
    function _setWithdrawed(uint256 id) internal virtual;

    /// @dev returns new position ID
    function _newPositionId() internal returns (uint256) {
        return ++_positionsCount;
    }

    /// @dev returns true, if position is exists
    function _positionExists(uint256 positionId) internal view returns (bool) {
        return positionId > 0 && positionId <= _positionsCount;
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

import '../AssetLockerBase.sol';
import './IErc20Locker.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Erc20Locker is AssetLockerBase, IErc20Locker {
    using SafeERC20 for IERC20;
    mapping(uint256 => Erc20LockData) _positions;

    constructor(
        address feeSettingsAddress
    ) AssetLockerBase(feeSettingsAddress) {}

    function position(
        uint256 id
    ) external view OnlyExistingPosition(id) returns (Erc20LockData memory) {
        return _positions[id];
    }

    function withdrawer(
        uint256 id
    ) external view OnlyExistingPosition(id) returns (address) {
        return _positions[id].withdrawer;
    }

    function _isLocked(uint256 id) internal view override returns (bool) {
        Erc20LockData memory data = _positions[id];
        if (data.stepByStepUnlockCount == 0) return super._isLocked(id);
        return _unlockedCountWithdrawAvailable(id) == 0 && super._isLocked(id);
    }

    function unlockTime(
        uint256 id
    ) external view OnlyExistingPosition(id) returns (uint256) {
        uint256 remain = _remainingTokensToWithdraw(id);
        if (remain == 0) return 0;
        Erc20LockData memory data = _positions[id];
        if (data.stepByStepUnlockCount == 0) return this.unlockAllTime(id);
        uint256 unlocked = _unlockedCount(id);
        if (unlocked >= data.count) return this.unlockAllTime(id);
        return
            data.creationTime +
            ((block.timestamp - data.creationTime) / data.timeInterval + 1) *
            data.timeInterval;
    }

    function unlockAllTime(uint256 id) external view returns (uint256) {
        Erc20LockData memory data = _positions[id];
        if (data.stepByStepUnlockCount == 0)
            return data.creationTime + data.timeInterval;
        if (data.count % data.stepByStepUnlockCount == 0) {
            return
                data.creationTime +
                (_positions[id].count / data.stepByStepUnlockCount) *
                _positions[id].timeInterval;
        } else {
            return
                data.creationTime +
                (data.count / data.stepByStepUnlockCount) *
                data.timeInterval +
                data.stepByStepUnlockCount;
        }
    }

    function remainingTokensToWithdraw(
        uint256 id
    ) external view returns (uint256) {
        return _remainingTokensToWithdraw(id);
    }

    function _remainingTokensToWithdraw(
        uint256 id
    ) internal view returns (uint256) {
        return _positions[id].count - _positions[id].withdrawedCount;
    }

    function withdrawed(
        uint256 id
    ) external view OnlyExistingPosition(id) returns (bool) {
        return _positions[id].withdrawedCount >= _positions[id].count;
    }

    function _setWithdrawed(uint256 id) internal override {
        _positions[id].withdrawedCount += _unlockedCountWithdrawAvailable(id);
    }

    function lockTimeFor(
        address token,
        uint256 count,
        uint256 unlockTime_,
        address withdrawer_
    ) external {
        require(unlockTime_ > 0, 'time can not be zero');
        require(withdrawer_ != address(0), 'withdrawer can not be zero');
        _lock(token, count, unlockTime_, withdrawer_);
    }

    function lockTime(
        address token,
        uint256 count,
        uint256 unlockTime_
    ) external {
        require(unlockTime_ > 0, 'time can not be zero');
        _lock(token, count, unlockTime_, msg.sender);
    }

    function lockSecondsFor(
        address token,
        uint256 count,
        uint256 seconds_,
        address withdrawer_
    ) external {
        require(withdrawer_ != address(0), 'withdrawer can not be zero');
        _lock(token, count, block.timestamp + seconds_, withdrawer_);
    }

    function lockSeconds(
        address token,
        uint256 count,
        uint256 seconds_
    ) external {
        _lock(token, count, block.timestamp + seconds_, msg.sender);
    }

    function lockStepByStepUnlocking(
        address tokenAddress,
        uint256 count,
        address withdrawer_,
        uint256 interval,
        uint256 stepByStepUnlockCount
    ) external {
        _lock(
            tokenAddress,
            count,
            withdrawer_,
            interval,
            stepByStepUnlockCount
        );
    }

    function _lock(
        address tokenAddress,
        uint256 count,
        uint256 unlockTime_,
        address withdrawer_
    ) private {
        _lock(
            tokenAddress,
            count,
            withdrawer_,
            unlockTime_ - block.timestamp,
            0
        );
    }

    function _lock(
        address tokenAddress,
        uint256 count,
        address withdrawer_,
        uint256 interval,
        uint256 stepByStepUnlockCount
    ) internal {
        require(count > 0, 'nothing to lock');
        uint256 id = _newPositionId();
        Erc20LockData storage data = _positions[id];
        data.token = tokenAddress;
        data.creationTime = block.timestamp;
        data.timeInterval = interval;
        data.withdrawer = withdrawer_;
        data.stepByStepUnlockCount = stepByStepUnlockCount;
        uint256 fee = _feeSettings.feeForCount(withdrawer_, count);

        IERC20 token = IERC20(tokenAddress);

        // fee transfer
        if (fee > 0)
            token.safeTransferFrom(msg.sender, _feeSettings.feeAddress(), fee);

        // lock transfer
        uint256 lastCount = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), count - fee);
        data.count = token.balanceOf(address(this)) - lastCount;
        emit OnLockPosition(id);
    }

    function _withdraw(uint256 id) internal override {
        Erc20LockData memory data = _positions[id];
        IERC20(data.token).safeTransfer(
            data.withdrawer,
            _unlockedCountWithdrawAvailable(id)
        );
    }

    function unlockedCount(uint256 id) external view returns (uint256) {
        return _unlockedCount(id);
    }

    function _unlockedCount(uint256 id) internal view returns (uint256) {
        Erc20LockData memory data = _positions[id];
        if (data.stepByStepUnlockCount == 0) {
            if (this.isLocked(id)) return 0;
            else return data.count;
        }

        uint256 unlocked = ((block.timestamp - data.creationTime) /
            data.timeInterval) * data.stepByStepUnlockCount;
        if (unlocked > data.count) unlocked = data.count;
        return unlocked;
    }

    function unlockedCountWithdrawAvailable(
        uint256 id
    ) external view returns (uint256) {
        return _unlockedCountWithdrawAvailable(id);
    }

    function _unlockedCountWithdrawAvailable(
        uint256 id
    ) internal view returns (uint256) {
        Erc20LockData memory data = _positions[id];
        if (data.stepByStepUnlockCount == 0) {
            if (this.isLocked(id)) return 0;
            return data.count;
        }

        return _unlockedCount(id) - data.withdrawedCount;
    }
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