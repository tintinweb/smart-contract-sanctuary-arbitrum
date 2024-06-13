// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Combined overflow check (`x == 0 || (x * y) / x == y`) and edge case check
        // where x == -1 and y == type(int256).min, for y == -1 and x == min int256,
        // the second overflow check will catch this.
        // See: https://secure-contracts.com/learn_evm/arithmetic-checks.html#arithmetic-checks-for-int256-multiplication
        // Combining into 1 expression saves gas as resulting bytecode will only have 1 `JUMPI`
        // rather than 2.
        if iszero(
            and(
                or(iszero(x), eq(sdiv(r, x), y)),
                or(lt(x, not(0)), sgt(y, 0x8000000000000000000000000000000000000000000000000000000000000000))
            )
        ) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

/// @dev Will not work with negative bases, only use when x is positive.
function wadPow(int256 x, int256 y) pure returns (int256) {
    // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
    return wadExp((wadLn(x) * y) / 1e18); // Using ln(x) means x must be greater than 0.
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {Math} from "openzeppelin-contracts/utils/math/Math.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import "solmate/utils/SignedWadMath.sol";

import {LibError} from "./lib/LibError.sol";
import {IRBAC} from "./interfaces/IRBAC.sol";

import {OrderDS} from "./OrderDS.sol";
import {IParifiVault} from "./interfaces/IParifiVault.sol";
import {IOrderManager} from "./interfaces/IOrderManager.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";

/// @title Data Fabric contract
/// @author Parifi
/// @notice The contract acts as a data layer that stores important market data for the Order Manager
/// @dev Precision of each data variable varies:
///        - Deviation => 1% = 1e12
///        - Base and Dynamic borrow fees, it has precision of 18 digits. So 1% = 1e18
///        - Skew and Market Utilization is in basis points: 1% = 100
contract DataFabric {
    using FixedPointMathLib for uint256;
    using Math for uint256;

    /////////////////////////////////////////////
    //              EVENTS
    /////////////////////////////////////////////

    /// @dev Emitted when market is updated by the order manager
    event CumulativeFeeUpdated(
        bytes32 indexed marketId,
        uint256 baseFeeCumulativeLongs,
        uint256 baseFeeCumulativeShorts,
        uint256 dynamicLongFeeCumulative,
        uint256 dynamicShortFeeCumulative,
        uint256 feeLastUpdatedTimestamp
    );

    /// @dev Emitted when order manager contract is updated
    event OrderManagerUpdated(address indexed newOrderManager);

    /// @dev Emitted when liquidity curve config params are updated
    event LiquidityCurveUpdated(bytes32 indexed marketId, uint256 deviationCoeff, uint256 deviationConst);

    /// @dev Emitted when borrowing curve config params are updated
    event BorrowingCurveUpdated(
        bytes32 indexed marketId,
        uint256 baseCoeff,
        uint256 baseConst,
        uint256 dynamicCoeff,
        uint256 maxDynamicBorrowFee
    );

    /// @dev Emitted when the creation of new positions are stopped for a given market.
    // Existing positions can only be closed
    event CloseOnlyModeUpdated(bytes32 indexed marketId, bool status);

    /// @dev Emitted when the max open interest for a given market is updated
    event MaxOiUpdated(bytes32 indexed marketId, uint256 updatedOi);

    event MarketPaused(bytes32 indexed marketId);
    event MarketUnpaused(bytes32 indexed marketId);

    event MarketAdded(bytes32 indexed marketId);
    event MarketUpdated(bytes32 indexed marketId);

    event MarketOiUpdated(bytes32 indexed marketId, uint256 totalLongs, uint256 totalShorts);

    event ExecutionFeeUpdated(address depositToken, uint256 amount);

    /////////////////////////////////////////////
    //              STATE VARIABLES
    /////////////////////////////////////////////

    // Constants
    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.
    uint256 internal constant SECONDS_IN_YEAR = 365 days;
    uint256 internal constant PRECISION_MULTIPLIER = 10_000;
    uint256 internal constant FEE_CAP = 500_000; // 1% = 100_000
    uint256 internal constant EXECUTION_FEE_CAP_USD = 10 * 1e8; // 10 USD (with 8 decimals)

    struct MarketConfig {
        uint256 maximumOi;
        uint256 totalLongs;
        uint256 totalShorts;
        uint256 feeLastUpdatedTimestamp;
        // Base Borrowing Fees
        uint256 baseCoeff;
        uint256 baseConst;
        uint256 baseFeeCumulativeLongs;
        uint256 baseFeeCumulativeShorts;
        // Dynamic Borrowing Fees
        uint256 dynamicCoeff;
        uint256 maxDynamicBorrowFee;
        uint256 dynamicFeeCumulativeLongs;
        uint256 dynamicFeeCumulativeShorts;
        // Liquidity Curve
        uint256 deviationCoeff;
        uint256 deviationConst;
    }

    // MarketId => Market
    mapping(bytes32 => OrderDS.Market) private availableMarkets;

    // MarketId => MarketConfig
    mapping(bytes32 => MarketConfig) private marketConfig;

    // Collateral Token => Execution Fees
    mapping(address => uint256) private depositTokenToExecutionFee;

    IRBAC public immutable rbac;

    address public orderManager;

    mapping(bytes32 => bool) public closeOnlyMode;

    /////////////////////////////////////////////
    //                 MODIFIERS
    /////////////////////////////////////////////

    modifier onlyAdmin() {
        if (!rbac.hasRole(rbac.ADMIN(), msg.sender)) revert LibError.InvalidRole("admin");
        _;
    }

    modifier onlyMarketManagerOrAdmin() {
        if (!rbac.hasRole(rbac.MARKET_MANAGER(), msg.sender) && !rbac.hasRole(rbac.ADMIN(), msg.sender)) {
            revert LibError.InvalidRole("MARKET");
        }
        _;
    }

    modifier onlyOrderManager() {
        if (msg.sender != orderManager) revert LibError.InvalidRole("manager");
        _;
    }

    constructor(address _rbac) {
        rbac = IRBAC(_rbac);
    }

    /////////////////////////////////////////////
    //              INTERNAL FUNCTIONS
    /////////////////////////////////////////////

    /// @notice Updates values of cumulative fees for Longs and shorts based on current market data
    /// @param marketId The market for which data is to be updated
    function _updateCumulativeFees(bytes32 marketId) internal {
        MarketConfig storage config = marketConfig[marketId];

        if (config.feeLastUpdatedTimestamp == 0) {
            config.feeLastUpdatedTimestamp = block.timestamp;
            return;
        }

        // If fees have been updated in the same block, return as `timeDelta` will be 0.
        if (block.timestamp == config.feeLastUpdatedTimestamp) return;

        uint256 timeDelta = block.timestamp - config.feeLastUpdatedTimestamp;

        config.baseFeeCumulativeLongs =
            config.baseFeeCumulativeLongs + timeDelta * getBaseBorrowRatePerSecond(marketId, true);
        config.baseFeeCumulativeShorts =
            config.baseFeeCumulativeShorts + timeDelta * getBaseBorrowRatePerSecond(marketId, false);

        if (config.totalLongs > config.totalShorts) {
            config.dynamicFeeCumulativeLongs =
                config.dynamicFeeCumulativeLongs + timeDelta * getDynamicBorrowRatePerSecond(marketId);
        } else {
            config.dynamicFeeCumulativeShorts =
                config.dynamicFeeCumulativeShorts + timeDelta * getDynamicBorrowRatePerSecond(marketId);
        }

        config.feeLastUpdatedTimestamp = block.timestamp;

        emit CumulativeFeeUpdated(
            marketId,
            config.baseFeeCumulativeLongs,
            config.baseFeeCumulativeShorts,
            config.dynamicFeeCumulativeLongs,
            config.dynamicFeeCumulativeShorts,
            block.timestamp
        );
    }

    function _checkMaxOi(uint256 totalOi, uint256 maxOi) internal pure {
        if (totalOi > maxOi) revert LibError.MaxOI();
    }

    /// @notice Utility function to return the absolute difference between two numbers `a` and `b`
    /// @param a First number to calculate the difference
    /// @param b Second number to calculate the difference
    /// @return diff Calculated difference between `a` and `b`
    function _getDiff(uint256 a, uint256 b) internal pure returns (uint256 diff) {
        diff = a > b ? (a - b) : (b - a);
    }

    /////////////////////////////////////////////
    //         PUBLIC/EXTERNAL FUNCTIONS
    /////////////////////////////////////////////

    /// @notice Returns Cumulative fees for the Market `marketId` and the side/direction
    /// @dev The cumulative fee is the total borrow Fee. It factors in both - The Base fees and the Dynamic fees
    /// @param marketId The market for which fees is to be returned
    /// @param isLong Direction of the trade - true for long, false for short
    /// @return currentFeeCumulative Current cumulative fees for the `marketId` in %, where 1% = 1e18
    function getCurrentFeeCumulative(bytes32 marketId, bool isLong)
        external
        view
        returns (uint256 currentFeeCumulative)
    {
        MarketConfig memory config = marketConfig[marketId];
        if (isLong) {
            currentFeeCumulative = config.baseFeeCumulativeLongs + config.dynamicFeeCumulativeLongs;
        } else {
            currentFeeCumulative = config.baseFeeCumulativeShorts + config.dynamicFeeCumulativeShorts;
        }
    }

    /// @notice Get skew for the Market `marketId` based on the total active long and short positions
    /// @dev The function returns 0 in case longs and shorts are 0
    /// @param marketId The market for which skew is to be calculated
    /// @return skew Market skew for the `marketId` in basis points, 1% skew = 100
    function getMarketSkew(bytes32 marketId) public view returns (uint256 skew) {
        MarketConfig memory config = marketConfig[marketId];

        if (config.totalLongs + config.totalShorts == 0) return 0;

        skew = _getDiff(config.totalLongs, config.totalShorts).mulDiv(
            PRECISION_MULTIPLIER, (config.totalLongs + config.totalShorts), Math.Rounding.Up
        );
    }

    /// @notice Calculates the current utilization of the marketId for longs or shorts, based on maximum allowed OI.
    /// @dev The function returns 0 in case the maximum OI is set to 0 or never set
    /// @param marketId The market for which Utilization is to be calculated
    /// @param isLong flag to determine if the utilization is to be calculated for longs or shorts
    /// @return utilization Current utilization in basis points, 1% utilization = 100

    function getMarketUtilization(bytes32 marketId, bool isLong) public view returns (uint256 utilization) {
        MarketConfig memory config = marketConfig[marketId];
        if (config.maximumOi == 0) return 0;

        if (isLong) {
            utilization = (config.totalLongs).mulDiv(PRECISION_MULTIPLIER, config.maximumOi, Math.Rounding.Up);
        } else {
            utilization = (config.totalShorts).mulDiv(PRECISION_MULTIPLIER, config.maximumOi, Math.Rounding.Up);
        }
    }

    /// @notice Calculates the expected utilization of the marketId
    /// @dev used by getPriceDeviation to calculate average deviation
    /// @param marketId The market for which Utilization is to be calculated
    /// @param isLong flag to determine if the utilization is to be calculated for longs or shorts
    /// @param isIncrease flag to determine we are increasing or decreasing the position
    /// @param sizeDelta amount of position size change in market assets
    /// @return utilization expected utilization in basis points, 1% utilization = 100
    function getExpectedUtilization(bytes32 marketId, bool isLong, bool isIncrease, uint256 sizeDelta)
        public
        view
        returns (uint256 utilization)
    {
        MarketConfig memory config = marketConfig[marketId];
        if (config.maximumOi == 0) return 0;

        uint256 totalOi;

        if (isLong) {
            if (isIncrease) {
                totalOi = config.totalLongs + sizeDelta;
                _checkMaxOi(totalOi, config.maximumOi);
            } else {
                totalOi = config.totalLongs - sizeDelta;
            }
        } else {
            if (isIncrease) {
                totalOi = config.totalShorts + sizeDelta;
                _checkMaxOi(totalOi, config.maximumOi);
            } else {
                totalOi = config.totalShorts - sizeDelta;
            }
        }

        utilization = totalOi.mulDiv(PRECISION_MULTIPLIER, config.maximumOi, Math.Rounding.Up);
    }

    /// @notice Calculate the price deviation of the market
    /// @dev Deviation is calculated and returned in deviationPoints
    /// @param marketId The market for which price deviation is to be calculated
    /// @return deviationPerc deviation percentage Price Deviation for market with 12 decimals. 1% deviation = 10^12
    function getPriceDeviation(bytes32 marketId, bool isLong, bool isIncrease, uint256 sizeDelta)
        external
        view
        returns (uint256 deviationPerc)
    {
        uint256 u1 = getMarketUtilization(marketId, isLong);
        uint256 d1 = marketConfig[marketId].deviationCoeff * u1 * u1 + marketConfig[marketId].deviationConst;

        if (sizeDelta == 0) return d1;

        uint256 u2 = getExpectedUtilization(marketId, isLong, isIncrease, sizeDelta);
        uint256 d2 = marketConfig[marketId].deviationCoeff * u2 * u2 + marketConfig[marketId].deviationConst;

        deviationPerc = d1.average(d2);
    }

    /// @notice Calculate the base borrow rate per second for market
    /// @dev Base borrow rate is in WADS i.e with 18 digits of precision
    /// @param marketId The market for which base borrow rate is to be calculated
    /// @return baseBorrowRate Base borrow rate (%) per second in WADS, where 1% = 1e18
    function getBaseBorrowRatePerSecond(bytes32 marketId, bool isLong) public view returns (uint256 baseBorrowRate) {
        uint256 utilizationBps = getMarketUtilization(marketId, isLong) * 100;
        baseBorrowRate = WAD
            * (marketConfig[marketId].baseCoeff * utilizationBps * utilizationBps + marketConfig[marketId].baseConst);
        baseBorrowRate = baseBorrowRate / (1e12 * SECONDS_IN_YEAR);
    }

    /// @notice Calculate the dynamic borrow rate per second for market
    /// @dev Dynamic borrow rate is in WADS i.e with 18 digits of precision
    ///      Dynamic rate is applied based on market skew (i.e. totalLongs > totalShorts, dynamicRateShorts = 0)
    ///      This is calculated in the _updateCumulativeFees function
    /// @param marketId The market for which base borrow rate is to be calculated
    /// @return dynamicBorrowRate Dynamic borrow rate (%) per second in WADS, where 1% = 1e18
    function getDynamicBorrowRatePerSecond(bytes32 marketId) public view returns (uint256 dynamicBorrowRate) {
        uint256 skew = getMarketSkew(marketId);

        uint256 e_k_sigma = uint256(
            wadExp(-int256((marketConfig[marketId].dynamicCoeff * skew).divWadDown(PRECISION_MULTIPLIER * 100)))
        );

        // dynamicBorrowRate = M * (1 - e_k_sigma) / (1 + e_k_sigma)
        dynamicBorrowRate =
            ((marketConfig[marketId].maxDynamicBorrowFee * (WAD - e_k_sigma)).divWadDown(WAD + e_k_sigma));

        dynamicBorrowRate = dynamicBorrowRate / (100 * SECONDS_IN_YEAR);
    }

    /// @dev Returns the total long and short positions for a market ID
    /// @param marketId Market ID for the asset/marketVault pair
    /// @return total_longs Total open positions for Long
    /// @return total_shorts Total open positions for Shorts
    function getMarketData(bytes32 marketId) external view returns (uint256 total_longs, uint256 total_shorts) {
        return (marketConfig[marketId].totalLongs, marketConfig[marketId].totalShorts);
    }

    function getCumulativeFeesComponents(bytes32 marketId)
        external
        view
        returns (
            uint256 baseFeeCumulativeLongs,
            uint256 baseFeeCumulativeShorts,
            uint256 dynamicFeeCumulativeLongs,
            uint256 dynamicFeeCumulativeShorts,
            uint256 feeLastUpdatedTimestamp
        )
    {
        MarketConfig memory config = marketConfig[marketId];
        return (
            config.baseFeeCumulativeLongs,
            config.baseFeeCumulativeShorts,
            config.dynamicFeeCumulativeLongs,
            config.dynamicFeeCumulativeShorts,
            config.feeLastUpdatedTimestamp
        );
    }

    function getLiquidityCurveConfig(bytes32 marketId)
        external
        view
        returns (uint256 deviationCoeff, uint256 deviationConst)
    {
        MarketConfig memory config = marketConfig[marketId];
        return (config.deviationCoeff, config.deviationConst);
    }

    function getBorrowingCurveConfig(bytes32 marketId)
        external
        view
        returns (uint256 baseCoeff, uint256 baseConst, uint256 dynamicCoeff, uint256 maxDynamicBorrowFee)
    {
        MarketConfig memory config = marketConfig[marketId];
        return (config.baseCoeff, config.baseConst, config.dynamicCoeff, config.maxDynamicBorrowFee);
    }

    function totalLongs(bytes32 marketId) external view returns (uint256) {
        return marketConfig[marketId].totalLongs;
    }

    function totalShorts(bytes32 marketId) external view returns (uint256) {
        return marketConfig[marketId].totalShorts;
    }

    function getMarketConfig(bytes32 marketId) external view returns (MarketConfig memory config) {
        return marketConfig[marketId];
    }

    /// @notice Returns market details for `marketId`
    /// @param marketId Market ID
    /// @return marketDetails Market details for `marketId`
    function getMarket(bytes32 marketId) external view returns (OrderDS.Market memory marketDetails) {
        return availableMarkets[marketId];
    }

    function getVaultAddressForMarket(bytes32 marketId) external view returns (address vaultAddress) {
        return availableMarkets[marketId].vaultAddress;
    }

    function getMaxLeverageForMarket(bytes32 marketId) public view returns (uint256) {
        return availableMarkets[marketId].maxLeverage;
    }

    function getMarketStatus(bytes32 marketId) external view returns (bool isMarketLive) {
        return availableMarkets[marketId].isLive;
    }

    function getDepositToken(bytes32 marketId) external view returns (address) {
        return availableMarkets[marketId].depositToken;
    }

    function getExecutionFee(address depositToken) external view returns (uint256) {
        return depositTokenToExecutionFee[depositToken];
    }

    /////////////////////////////////////////////
    //         ADMIN/RESTRICTED FUNCTIONS
    /////////////////////////////////////////////

    /// @notice Updates values of cumulative fees for Longs and shorts based on current market data
    /// @param marketId The market for which data is to be updated
    function updateCumulativeFees(bytes32 marketId) public onlyOrderManager {
        _updateCumulativeFees(marketId);
    }

    /// @notice Updates the Market data based on the arguments. Also updates the cumulative fees
    /// @dev Function can only be called by OrderManager
    /// @param marketId The market for which data is to be updated
    /// @param size Position size that was added/removed from the market
    /// @param isLong True if the direction is Long side, false otherwise
    function updateMarketData(bytes32 marketId, uint256 size, bool isLong, bool isIncrease) external onlyOrderManager {
        if (size == 0 && !closeOnlyMode[marketId]) return;
        MarketConfig storage config = marketConfig[marketId];

        if (isIncrease) {
            // Only allow closing positions when market closeOnlyMode is set to true
            if (closeOnlyMode[marketId]) revert LibError.CloseOnlyMode();

            if (isLong) {
                config.totalLongs = config.totalLongs + size;
                _checkMaxOi(config.totalLongs, config.maximumOi);
            } else {
                config.totalShorts = config.totalShorts + size;
                _checkMaxOi(config.totalShorts, config.maximumOi);
            }
        } else {
            if (isLong) {
                config.totalLongs = config.totalLongs - size;
            } else {
                config.totalShorts = config.totalShorts - size;
            }
        }

        emit MarketOiUpdated(marketId, config.totalLongs, config.totalShorts);
    }

    /// @notice Pause market (Change status to inactive)
    /// @dev Updated cumulative fees before pausing. Fees are not charged for the duration the markets have been
    /// paused/inactive
    /// @param marketId Market ID
    function pauseMarket(bytes32 marketId) external onlyMarketManagerOrAdmin {
        OrderDS.Market storage market = availableMarkets[marketId];
        if (market.vaultAddress == address(0)) revert LibError.ZeroAddress();
        market.isLive = false;

        // Updated cumulative fees when pausing
        _updateCumulativeFees(marketId);
        emit MarketPaused(marketId);
    }

    /// @notice Unpause markets (change status to Live)
    /// @dev Fees are not charged for the duration the markets have been paused/inactive
    /// @param marketId Market ID
    function unpauseMarket(bytes32 marketId) external onlyMarketManagerOrAdmin {
        OrderDS.Market storage market = availableMarkets[marketId];
        if (market.vaultAddress == address(0)) revert LibError.ZeroAddress();

        marketConfig[marketId].feeLastUpdatedTimestamp = block.timestamp;

        market.isLive = true;
        emit MarketUnpaused(marketId);
    }

    /// @notice Set the market to not accept creation of new positions when the flag is set to true
    /// @param marketId The market for which closeOnlyMode is to be set/unset
    /// @param status True if closeOnlyMode is enabled, false otherwise
    function setCloseOnlyMode(bytes32 marketId, bool status) external onlyAdmin {
        closeOnlyMode[marketId] = status;
        emit CloseOnlyModeUpdated(marketId, status);
    }

    function setExecutionFee(address depositToken, uint256 amount) external onlyMarketManagerOrAdmin {
        address priceFeed = IOrderManager(orderManager).priceFeed();
        uint256 valueInUsd = IPriceFeed(priceFeed).convertTokenToUsd(depositToken, amount);
        if (valueInUsd > EXECUTION_FEE_CAP_USD) revert LibError.MaxFee();
        depositTokenToExecutionFee[depositToken] = amount;
        emit ExecutionFeeUpdated(depositToken, amount);
    }

    /// @notice Sets maximum open interest for Longs and Shorts for a market
    /// @dev The MaxOi is set for one side of the market. Total MaxOI for the market is 2 * maxOi
    /// @param marketId The market for which maxOi is to be updated
    function setMaximumOi(bytes32 marketId, uint256 maxOi) external onlyMarketManagerOrAdmin {
        OrderDS.Market memory market = availableMarkets[marketId];
        if (market.isLive) revert LibError.MarketIsActive();

        marketConfig[marketId].maximumOi = maxOi;
        emit MaxOiUpdated(marketId, maxOi);
    }

    /// @param _orderManager New Order Manager address
    /// @notice Updates the OrderManager contract address
    function setOrderManager(address _orderManager) external onlyAdmin {
        if (_orderManager == address(0)) revert LibError.ZeroAddress();

        // Revert if orderManager has been already initialized
        if (orderManager != address(0)) revert LibError.AlreadyInitialized();

        orderManager = _orderManager;
        emit OrderManagerUpdated(_orderManager);
    }

    /// @notice Sets the liquidity curve config values for a market
    /// @param _marketId The market for which value is to be updated
    /// @param _deviationCoeff New value for deviation coefficient
    /// @param _deviationConst New value for deviation constant
    function setLiquidityCurveConfig(bytes32 _marketId, uint256 _deviationCoeff, uint256 _deviationConst)
        external
        onlyMarketManagerOrAdmin
    {
        marketConfig[_marketId].deviationCoeff = _deviationCoeff;
        marketConfig[_marketId].deviationConst = _deviationConst;
        emit LiquidityCurveUpdated(_marketId, _deviationCoeff, _deviationConst);
    }

    /// @notice Sets the borrowing curve config values for a market
    /// @param _marketId The market for which value is to be updated
    /// @param _baseCoeff New value for base coefficient
    /// @param _baseConst New value for base constant
    /// @param _dynamicCoeff New value for  Dynamic coefficient
    /// @param _maxDynamicBorrowFee New value for  Maximum Dynamic Borrow Fee
    function setBorrowingCurveConfig(
        bytes32 _marketId,
        uint256 _baseCoeff,
        uint256 _baseConst,
        uint256 _dynamicCoeff,
        uint256 _maxDynamicBorrowFee
    ) external onlyMarketManagerOrAdmin {
        OrderDS.Market memory market = availableMarkets[_marketId];
        if (market.isLive) revert LibError.MarketIsActive();

        marketConfig[_marketId].baseCoeff = _baseCoeff;
        marketConfig[_marketId].baseConst = _baseConst;
        marketConfig[_marketId].dynamicCoeff = _dynamicCoeff;
        marketConfig[_marketId].maxDynamicBorrowFee = _maxDynamicBorrowFee;
        emit BorrowingCurveUpdated(_marketId, _baseCoeff, _baseConst, _dynamicCoeff, _maxDynamicBorrowFee);
    }

    /// @notice Update an existing market
    /// @dev Not all fields can be updated for a market. Only config values can be updated
    /// @param _marketId Market ID of the market
    /// @param _updatedMarket Market details
    function updateExistingMarket(bytes32 _marketId, OrderDS.Market calldata _updatedMarket) external onlyAdmin {
        OrderDS.Market memory market = availableMarkets[_marketId];
        if (market.vaultAddress == address(0)) revert LibError.InvalidVaultAddress();

        // Markets should be paused before updating the markets
        if (market.isLive) revert LibError.MarketIsActive();

        if (market.vaultAddress != _updatedMarket.vaultAddress) revert LibError.InvalidVaultAddress();
        if (market.depositToken != _updatedMarket.depositToken) revert LibError.InvalidToken();
        if (market.marketDecimals != _updatedMarket.marketDecimals) revert LibError.InvalidMarketDecimals();

        if (_updatedMarket.openingFee + _updatedMarket.closingFee > FEE_CAP) revert LibError.MaxFee();
        if (_updatedMarket.liquidationFee > FEE_CAP) revert LibError.MaxFee();

        if (_updatedMarket.liquidationThreshold < 5_000 || _updatedMarket.liquidationThreshold >= PRECISION_MULTIPLIER)
        {
            revert LibError.InvalidValue();
        }

        availableMarkets[_marketId] = _updatedMarket;

        // Set the market to inactive initially, needs to be unpaused by ADMIN after update
        if (_updatedMarket.isLive) availableMarkets[_marketId].isLive = false;

        emit MarketUpdated(_marketId);
    }

    /// @notice Adds a new market to the protocol
    /// @param _marketId Market ID of the market
    /// @param _newMarket Market details
    function addNewMarket(bytes32 _marketId, OrderDS.Market calldata _newMarket) external onlyAdmin {
        if (_marketId == bytes32(0)) revert LibError.InvalidMarketId();

        OrderDS.Market memory market = availableMarkets[_marketId];
        if (market.vaultAddress != address(0)) revert LibError.InvalidVaultAddress();
        if (market.isLive) revert LibError.MarketIsActive();

        if (_newMarket.marketDecimals == 0) revert LibError.InvalidMarketDecimals();
        if (_newMarket.openingFee + _newMarket.closingFee > FEE_CAP) revert LibError.MaxFee();
        if (_newMarket.liquidationFee > FEE_CAP) revert LibError.MaxFee();
        if (_newMarket.liquidationThreshold < 5_000 || _newMarket.liquidationThreshold > PRECISION_MULTIPLIER) {
            revert LibError.InvalidValue();
        }

        availableMarkets[_marketId] = _newMarket;

        emit MarketAdded(_marketId);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IFeeManager {
    function distributeFees(address _token) external;

    function lastTransferTimestamp() external view returns (uint256);

    function lpShare() external view returns (uint256);

    function protocolShare() external view returns (uint256);

    function rbac() external view returns (address);

    function setTokenFeeChunkSize(address _token, uint256 _chunkSize) external;

    function tokenToChunkSize(address) external view returns (uint256);

    function tokenToLpFeeReceiver(address) external view returns (address);

    function tokenToProtocolFeeReceiver(address) external view returns (address);

    function updateFeeDistribution(uint256 _lpShare, uint256 _protocolShare) external;

    function updateLpFeeReceiver(address _token, address _lpFeeReceiver) external;

    function updateProtocolFeeReceiver(address _token, address _protocolFeeReceiver) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {OrderDS} from "../OrderDS.sol";

interface IOrderManager {
    function accumulatedPartnerFees(address, address) external view returns (uint256);

    function addNewMarket(bytes32 _marketId, OrderDS.Market memory _newMarket) external;

    function cancelPendingOrder(bytes32 _orderId) external;

    function claimPartnerFees(address partnerAddress, address tokenAddress) external;

    function createOrder(OrderDS.Order memory _order, address partner) external;

    function dataFabric() external view returns (address);

    function feeManager() external view returns (address);

    function getAccruedBorrowFeesInMarket(bytes32 _positionId) external view returns (uint256 accruedBorrowFees);

    function getMarket(bytes32 marketId) external view returns (OrderDS.Market memory marketDetails);

    function getOrderId(
        bytes32 _marketId,
        address _marketAddress,
        address _userAddress,
        bool _isLong,
        uint256 _sequence
    ) external pure returns (bytes32);

    function getPendingOrder(bytes32 orderId) external view returns (OrderDS.Order memory orderDetails);

    function getPosition(bytes32 positionId) external view returns (OrderDS.Position memory positionData);

    function getPositionId(bytes32 _marketId, address _marketAddress, address _userAddress, bool _isLong)
        external
        pure
        returns (bytes32);

    function getPositionIdFromOrderId(bytes32 _orderId) external view returns (bytes32 positionId);

    function getProfitOrLossInCollateral(bytes32 _positionId, uint256 _executionPrice)
        external
        view
        returns (uint256 profitOrLoss, bool isProfit);

    function getProfitOrLossInUsd(bytes32 _positionId, uint256 _price)
        external
        view
        returns (uint256 totalProfitOrLoss, bool isProfit);

    function isPendingOrder(bytes32 _orderId) external view returns (bool);

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function isValidPosition(bytes32 _positionId) external view returns (bool);

    function liquidatePosition(bytes32 positionId, bytes[] memory priceUpdateData) external;

    function partnerFee() external view returns (uint256);

    function pause() external;

    function paused() external view returns (bool);

    function priceFeed() external view returns (address);

    function rbac() external view returns (address);

    function setPartnerFee(uint256 _updatedFee) external;

    function settleOrder(bytes32 orderId, bytes[] memory priceUpdateData) external;

    function toggleMarketStatus(bytes32 _marketId) external;

    function unpause() external;

    function updateExistingMarket(bytes32 _marketId, OrderDS.Market memory _updatedMarket) external;

    function updateFeeManager(address _newFeeManager) external;

    function updatePriceFeed(address _priceFeed) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IParifiVault {
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function feeManager() external view returns (address);

    function inCaseTokensGetStuck(address _token) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function mint(uint256 shares, address receiver) external returns (uint256);

    function name() external view returns (string memory);

    function orderManager() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function rbac() external view returns (address);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);

    function symbol() external view returns (string memory);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function unpause() external;

    function updateFeeManager(address _newFeeManager) external;

    function updateWithdrawalFee(uint256 _fee) external;

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    function withdrawUserProfits(uint256 _profitAmount) external;

    function withdrawalFee() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IPriceFeed {
    function convertMarketToToken(bytes32 marketId, uint256 marketAmount, address tokenAddress)
        external
        view
        returns (uint256 tokenAmount);

    function convertMarketToTokenSecondary(bytes32 marketId, uint256 marketAmount, address tokenAddress)
        external
        view
        returns (uint256 tokenAmount);

    function convertTokenToToken(address tokenA, uint256 amountA, address tokenB)
        external
        view
        returns (uint256 amountB);

    function convertTokenToTokenSecondary(address tokenA, uint256 amountA, address tokenB)
        external
        view
        returns (uint256 amountB);

    function convertMarketToUsd(bytes32 marketId, uint256 amount) external view returns (uint256 amountUsd);

    function convertTokenToUsd(address tokenAddress, uint256 amount) external view returns (uint256 amountUsd);

    function getLatestPriceMarket(bytes32 marketId) external view returns (uint256 marketPriceUsd);

    function getLatestPriceToken(address tokenAddress) external view returns (uint256 tokenPriceUsd);

    function getMarketPricePrimary(bytes32 marketId) external view returns (uint256 marketPriceUsd);

    function getMarketPriceSecondary(bytes32 marketId) external view returns (uint256 marketPriceUsd);

    function getMarketPricePyth(bytes32 marketId) external view returns (uint256 marketPriceUsd);

    function getMarketPricePythEMA(bytes32 marketId) external view returns (uint256 marketPriceUsd);

    function getTokenPricePrimary(address tokenAddress) external view returns (uint256 tokenPriceUsd);

    function getTokenPriceSecondary(address tokenAddress) external view returns (uint256 tokenPriceUsd);

    function getTokenPricePyth(address tokenAddress) external view returns (uint256 tokenPriceUsd);

    function getTokenPricePythEMA(address tokenAddress) external view returns (uint256 tokenPriceUsd);

    // function marketDecimals(bytes32) external view returns (uint8);

    function marketToPythPriceId(bytes32) external view returns (bytes32);

    function pyth() external view returns (address);

    function rbac() external view returns (address);

    // function setMarketDecimals(bytes32 marketId, uint8 decimals) external;

    function tokenToPythPriceId(address) external view returns (bytes32);

    function updateAndGetMarketPrice(bytes32 marketId, bytes[] memory priceUpdateData)
        external
        returns (uint256 marketPriceUsd);

    function updateAndGetTokenPrice(address tokenAddress, bytes[] memory priceUpdateData)
        external
        returns (uint256 tokenPriceUsd);

    function updateChainlinkSequencerUptimeFeed(address feedAddress) external;

    function updateMarketFeedPyth(bytes32 marketId, bytes32 priceId) external;

    function updatePythPrice(bytes[] memory priceUpdateData) external;

    function updateSequencerUptimeStatus(bool status) external;

    function updateTokenFeedPyth(address tokenAddress, bytes32 priceId) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IRBAC {
    function ADMIN() external view returns (bytes32);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function KEEPER() external view returns (bytes32);

    function LIQUIDATOR() external view returns (bytes32);

    function MINIMUM_DELAY() external view returns (uint256);

    function ORACLE() external view returns (bytes32);

    function ROLE_MANAGER() external view returns (bytes32);

    function MARKET_MANAGER() external view returns (bytes32);

    function SETTLER() external view returns (bytes32);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function multisig() external view returns (address);

    function proposeNewMultisig(address _newMultisig) external;

    function proposedMultisig() external view returns (address);

    function proposedTimestamp() external view returns (uint256);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function updateMultisig() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

library LibError {
    error ZeroAddress();
    error ZeroAmount();
    error MaxOI();
    error MaxFee();
    error InvalidValue();

    // RBAC
    error InvalidRole(string errorMsg);
    error InvalidAddress();
    error InvalidTimestamp();

    // Forwarder
    error InvalidNonce();
    error InvalidToAddress();
    error InvalidTxValue();
    error InvalidGasPrice();
    error InvalidSignature();
    error InvalidToken();
    error InsufficientAllowance();
    error InsufficientBalance();
    error InsufficientGas();

    // PriceFeed
    error PriceOutdated();
    error InvalidPrice();
    error IncompatiblePriceFeed();

    // Order Manager
    error InvalidVaultAddress();
    error InvalidMarketDecimals();
    error InvalidMarketId();
    error InactiveMarket();
    error MarketIsActive();

    error OrderDoesNotExist();
    error ExistingOrder();
    error InvalidUserAddress();
    error InvalidCollateralAmount();
    error BelowMinCollateral();
    error InvalidSize();
    error InvalidOrderType();
    error InvalidLimitOrder();
    error OrderExpired();
    error CloseOnlyMode();
    error AlreadyInitialized();

    error PriceMismatch(uint256 expected, uint256 current);
    error InvalidPositionId();

    error ExistingPosition();
    error LiquidationErrorNoLoss();
    error InsufficientAssets(uint256 required, uint256 available);

    error OverLeveraged(uint256 expected, uint256 current);

    // Price Feed errors
    error PriceOutOfRange(uint256 expected, uint256 current);
    error SequencerDown();
    error GracePeriodNotOver();

    error InsufficientCooldown();
    error WithdrawalWindowExpired();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

contract OrderDS {
    /////////////////////////////////////////////
    //                 STRUCTS
    /////////////////////////////////////////////
    enum OrderType {
        OPEN_NEW_POSITION, // Open a new position
        CLOSE_POSITION, // Close an existing position
        INCREASE_POSITION, // Increase position by adding more collateral and/or increasing position size
        DECREASE_POSITION // Decrease position by removing collateral and/or decreasing position size
    }

    struct Market {
        address vaultAddress; // Contract address of the market vault
        address depositToken; // Token that is deposited to the Vault by LPs and by traders as collateral
        bool isLive; // Set to true if the market is active
        uint256 marketDecimals; // Number of decimal digits per token
        uint256 liquidationThreshold; // Threshold after which a position can be liquidated
        uint256 minCollateral; // Min. amount of collateral to deposit
        uint256 maxLeverage; // Leverage is multiplied by 10^4 for precision
        uint256 openingFee; // Opening fee in basis points
        uint256 closingFee; // Closing fee in basis points
        uint256 liquidationFee; // Liquidation fee in basis points
        uint256 maxPriceDeviation; // Price deviation after which orders cannot be executed
    }

    struct Order {
        bytes32 marketId; // keccak256 hash of asset symbol + vaultAddress
        address userAddress; // User that signed/submitted the order
        OrderType orderType; // Refer enum OrderType
        bool isLong; // Set to true if it is a Long order, false for a Short order
        bool isLimitOrder; // Flag to identify limit orders
        bool triggerAbove; // Flag to trigger price above or below expectedPrice
        uint256 deadline; // Timestamp after which order cannot be executed
        uint256 deltaCollateral; // Change in collateral amount (increased/decreased)
        uint256 deltaSize; // Change in Order size (increased/decreased)
        uint256 expectedPrice; // Desired Value for order execution
        uint256 maxSlippage; // Maximum allowed slippage in executionPrice from expectedPrice (in basis points)
        address partnerAddress; // Address that receives referral fees for new position orders (a share of opening fee)
    }

    struct Position {
        bytes32 marketId; // keccak256 hash of asset symbol + vaultAddress
        address userAddress; // User that owns the position
        bool isLong; // Set to true if it is a Long order, false for a Short order
        uint256 positionCollateral; // Collateral deposited as a backing for the position
        uint256 positionSize; // Size of the position
        uint256 avgPrice; // Average price of entry
        uint256 lastTimestamp; // Last modified timestamp
        uint256 lastCumulativeFee; // Last cumulative fee that was charged
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC20Metadata, IERC20} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Context, ERC2771Context} from "openzeppelin-contracts/metatx/ERC2771Context.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";

import {LibError} from "./lib/LibError.sol";

import {DataFabric, OrderDS} from "./DataFabric.sol";

import {IRBAC} from "./interfaces/IRBAC.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {IParifiVault} from "./interfaces/IParifiVault.sol";

contract OrderManager is OrderDS, ReentrancyGuard, Pausable, ERC2771Context {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /////////////////////////////////////////////
    //              EVENTS
    /////////////////////////////////////////////
    event OrderCreated(bytes32 indexed orderId);
    event OrderSettled(bytes32 indexed orderId, uint256 executionPrice);
    event OrderCancelled(bytes32 indexed orderId, uint256 balanceReceived);

    event NewPositionCreated(
        bytes32 indexed positionId, bytes32 indexed marketId, address indexed userAddress, uint256 avgPrice
    );
    event PositionClosed(bytes32 indexed positionId, uint256 balanceReceived, uint256 positionSize);
    event PositionUpdated(bytes32 indexed positionId, uint256 collateralAmount, uint256 positionSize);
    event PositionLiquidated(
        bytes32 indexed positionId, uint256 balanceReceived, uint256 liquidationPrice, uint256 lossInCollateral
    );

    event PartnerFeeUpdated(uint256 oldFee, uint256 updatedFee);
    event PartnerFeesClaimed(address indexed partnerAddress, address indexed tokenAddress, uint256 accruedFees);

    event ParifiPriceFeedUpdated(address indexed newPriceFeed);
    event FeeManagerUpdated(address indexed newFeeManager);
    event ExecutionFeeReceived(bytes32 indexed orderId, address indexed token, uint256 amount);
    event ExecutionFeeReceiverUpdate(address previousReceiver, address newFeeReceiver);

    /// @dev Emitted when liquidation is not triggered on time, resulting in fees not entirely covered by collateral
    event ProtocolLoss(bytes32 indexed marketId, address indexed tokenAddress, uint256 lossAmount);

    /// @dev Emitted when creating/updating/closing positions.
    event PnlRealized(
        bytes32 indexed positionId, bool isProfit, uint256 pnlInCollateral, uint256 feesCharged, uint256 executionPrice
    );

    /////////////////////////////////////////////
    //              STATE VARIABLES
    /////////////////////////////////////////////
    uint256 private immutable _CACHED_CHAIN_ID;

    DataFabric public immutable dataFabric;
    IRBAC public immutable rbac;
    IPriceFeed public priceFeed;

    address public feeManager;

    address public executionFeeReceiver;
    uint256 public partnerFee;

    // 100% Fee for opening and closing positions, 0.1% => 10_000 / 10_000_000 = 0.001
    uint256 internal constant MAX_FEE = 10_000_000; // 1% = 100_000
    uint256 internal constant PRECISION_MULTIPLIER = 10_000;

    // Price Deviation for market with 12 decimals. 1% deviation = 10^10. 100% deviation = 10^12
    uint256 internal constant DEVIATION_PRECISION_MULTIPLIER = 1e12;

    // Position nonce for user address, used to generate positionId
    mapping(address => uint256) public positionNonce;

    // Order nonce for user address, used to generate orderId
    mapping(address => uint256) public orderNonce;

    // Order ID to Position ID
    mapping(bytes32 => bytes32) private orderToPositionId;

    // OrderId => Order
    mapping(bytes32 => Order) private pendingOrders;

    // PositionId => Position
    mapping(bytes32 => Position) private openPositions;

    // Partner Address => Token Address => Amount
    mapping(address => mapping(address => uint256)) public accumulatedPartnerFees;

    /////////////////////////////////////////////
    //                 MODIFIERS
    /////////////////////////////////////////////
    modifier onlyAdmin() {
        if (!rbac.hasRole(rbac.ADMIN(), msg.sender)) revert LibError.InvalidRole("admin");
        _;
    }

    modifier onlyKeeper() {
        if (!rbac.hasRole(rbac.KEEPER(), msg.sender)) revert LibError.InvalidRole("keeper");
        _;
    }

    constructor(address _rbac, address _dataFabric, address _priceFeed, address _feeManager, address _trustedForwarder)
        ERC2771Context(_trustedForwarder)
    {
        rbac = IRBAC(_rbac);
        dataFabric = DataFabric(_dataFabric);
        priceFeed = IPriceFeed(_priceFeed);
        feeManager = _feeManager;

        _CACHED_CHAIN_ID = block.chainid;
    }

    /////////////////////////////////////////////
    //              INTERNAL FUNCTIONS
    /////////////////////////////////////////////

    /// @notice Utility function to return the absolute difference between two numbers `a` and `b`
    /// @param a First number to calculate the difference
    /// @param b Second number to calculate the difference
    /// @return diff Calculated difference between `a` and `b`
    function _getDiff(uint256 a, uint256 b) internal pure returns (uint256 diff) {
        diff = a > b ? (a - b) : (b - a);
    }

    /// @notice Used to validate leverage for a position
    /// @param _marketId The market for position
    /// @param _size Size of the position/order in market token
    /// @param _collateralAmount Amount that is used for collateral deposit
    function _validateLeverage(bytes32 _marketId, uint256 _size, uint256 _collateralAmount) internal view {
        uint256 maxLeverage = dataFabric.getMaxLeverageForMarket(_marketId);
        uint256 sizeInCollateral =
            priceFeed.convertMarketToTokenSecondary(_marketId, _size, dataFabric.getDepositToken(_marketId));
        uint256 leverage = sizeInCollateral * PRECISION_MULTIPLIER / _collateralAmount;

        if (leverage > maxLeverage) revert LibError.OverLeveraged(maxLeverage, leverage);
    }

    /// @notice Calculates current price accounting the deviation based on market conditions
    /// @param currentPrice current market price
    /// @param marketId Market ID
    /// @param isLong long or short position
    /// @param sizeDelta The increase/decrease in the utilization
    /// @return updatedPrice new updated price
    function _getPriceWithDeviation(
        uint256 currentPrice,
        bytes32 marketId,
        bool isLong,
        bool isIncrease,
        uint256 sizeDelta
    ) internal view returns (uint256 updatedPrice) {
        uint256 deviationPoints = dataFabric.getPriceDeviation(marketId, isLong, isIncrease, sizeDelta);

        if (isLong) {
            updatedPrice = currentPrice.mulDiv(
                (100 * DEVIATION_PRECISION_MULTIPLIER + deviationPoints),
                (100 * DEVIATION_PRECISION_MULTIPLIER),
                Math.Rounding.Up
            );
        } else {
            updatedPrice = currentPrice.mulDiv(
                (100 * DEVIATION_PRECISION_MULTIPLIER - deviationPoints),
                (100 * DEVIATION_PRECISION_MULTIPLIER),
                Math.Rounding.Down
            );
        }
    }

    /// @notice Validates the price accross both oracles and returns adjusted price with liquidity curve
    /// @param _marketId The market ID for trader market
    /// @param _isLong True when on the Long side, false for Shorts
    /// @return updatedPrice Adjusted price
    function _verifyAndUpdatePrice(
        bytes32 _marketId,
        bool _isLong,
        bool isIncrease,
        OrderType orderType,
        uint256 sizeDelta
    ) internal view returns (uint256 updatedPrice) {
        uint256 primaryPrice = priceFeed.getMarketPricePrimary(_marketId);
        uint256 secondaryPrice = priceFeed.getMarketPriceSecondary(_marketId);

        Market memory market = dataFabric.getMarket(_marketId);

        uint256 diffBps = (_getDiff(primaryPrice, secondaryPrice) * PRECISION_MULTIPLIER) / secondaryPrice;
        if (diffBps > market.maxPriceDeviation) {
            revert LibError.PriceOutOfRange(secondaryPrice, primaryPrice);
        }

        updatedPrice = primaryPrice;

        // Calculate final price based on the liquidity curve. 1% deviation = 10^12
        // Deviation is only calculated opening new positions (includes increase/decrease new avgPrice after pnl realized)
        if (orderType == OrderType.OPEN_NEW_POSITION) {
            updatedPrice = _getPriceWithDeviation(updatedPrice, _marketId, _isLong, isIncrease, sizeDelta);
        }
    }

    /// @notice Used to validate if the market is active/live or not
    /// @param _marketId Market ID
    function _validateMarket(bytes32 _marketId) internal view {
        bool isMarketLive = dataFabric.getMarketStatus(_marketId);
        if (!isMarketLive) revert LibError.InactiveMarket();

        // Validate market decimals are not zero
        if (dataFabric.getMarket(_marketId).marketDecimals == 0) revert LibError.InvalidMarketDecimals();
    }

    /// @notice Used to validate if a position with `_positionId` exists or not
    /// @param _positionId Position ID
    function _validateExistingPosition(bytes32 _positionId) internal view {
        if (!isValidPosition(_positionId)) revert LibError.InvalidPositionId();
    }

    /// @notice Returns  user position details
    /// @param _positionId Position ID
    /// @return userPosition Position details
    function _getUserPosition(bytes32 _positionId) internal view returns (Position storage userPosition) {
        return openPositions[_positionId];
    }

    /// @notice Calculates the current profit or loss in Collateral of the position with `positionId`
    /// @param _positionId Position ID
    /// @return profitOrLoss Amount of Profit or Loss in Collateral
    /// @return isProfit Boolean to indicate if it is a profit or loss
    function _getProfitOrLossInCollateral(bytes32 _positionId, uint256 _executionPrice)
        internal
        view
        returns (uint256 profitOrLoss, bool isProfit)
    {
        address collateralToken = dataFabric.getDepositToken(openPositions[_positionId].marketId);
        uint256 pnlInUsd;
        (pnlInUsd, isProfit) = getProfitOrLossInUsd(_positionId, _executionPrice);
        uint256 tokenPrice = priceFeed.getLatestPriceToken(collateralToken);

        uint256 tokenMultiplier = 10 ** IERC20Metadata(collateralToken).decimals();
        profitOrLoss = pnlInUsd.mulDiv(tokenMultiplier, tokenPrice, Math.Rounding.Up);
    }

    /// @notice Returns the net profit or loss factoring in total fees as well
    /// @param positionId Position ID
    /// @param sizeDelta Delta size on which fee should be charged
    /// @param fee closing or opening fee for given sizeDelta
    /// @param executionPrice price to use for calculating pnl
    /// @return netProfitOrLoss profit or loss in collateral factoring in fees
    /// @return isNetProfit boolean to indicate if it is a profit or loss
    /// @return feeAmount Fees charged to the user in collateral
    function _getNetProfitOrLossIncludingFees(
        bytes32 positionId,
        uint256 sizeDelta,
        uint256 fee,
        uint256 executionPrice
    ) internal returns (uint256 netProfitOrLoss, bool isNetProfit, uint256 feeAmount) {
        (uint256 pnlInCollateral, bool isProfit, uint256 feesInCollateral) =
            _getProfitOrLossExcludingFees(positionId, sizeDelta, fee, executionPrice);

        if (isProfit) {
            if (pnlInCollateral > feesInCollateral) {
                netProfitOrLoss = pnlInCollateral - feesInCollateral;
                isNetProfit = true;
            } else {
                netProfitOrLoss = feesInCollateral - pnlInCollateral;
                isNetProfit = false;
            }
        } else {
            netProfitOrLoss = feesInCollateral + pnlInCollateral;
            isNetProfit = false;
        }
        feeAmount = feesInCollateral;
    }

    function _getProfitOrLossExcludingFees(bytes32 positionId, uint256 sizeDelta, uint256 fee, uint256 executionPrice)
        internal
        returns (uint256 pnlInCollateral, bool isProfit, uint256 feesInCollateral)
    {
        bytes32 marketId = openPositions[positionId].marketId;

        // Update cumulative fees for the time passed since last fee update
        dataFabric.updateCumulativeFees(marketId);

        // Calculate Fees
        uint256 totalFeeAmount = fee.mulDiv(sizeDelta, MAX_FEE, Math.Rounding.Up);

        totalFeeAmount = totalFeeAmount + getAccruedBorrowFeesInMarket(positionId);
        feesInCollateral =
            priceFeed.convertMarketToToken(marketId, totalFeeAmount, dataFabric.getDepositToken(marketId));

        (pnlInCollateral, isProfit) = _getProfitOrLossInCollateral(positionId, executionPrice);
    }

    function _chargeFeesAndSettleUnrealizedProfitOrLoss(
        bytes32 positionId,
        uint256 sizeDeltaForFees,
        uint256 fee,
        uint256 executionPrice
    ) internal returns (uint256 updatedCollateral) {
        (uint256 pnlInCollateral, bool isProfit, uint256 feesInCollateral) =
            _getProfitOrLossExcludingFees(positionId, sizeDeltaForFees, fee, executionPrice);

        uint256 positionCollateral = openPositions[positionId].positionCollateral;

        bytes32 marketId = openPositions[positionId].marketId;
        OrderDS.Market memory market = dataFabric.getMarket(marketId);

        uint256 netFee;
        if (isProfit) {
            // Withdraw profits from vault when there is profit
            IParifiVault(market.vaultAddress).withdrawUserProfits(pnlInCollateral);

            // Fees to pay are already above the positions collateral + profit
            // It shouldnt get to this point as the position should be liquidated
            if (feesInCollateral > positionCollateral + pnlInCollateral) {
                emit ProtocolLoss(
                    marketId, market.depositToken, feesInCollateral - positionCollateral - pnlInCollateral
                );

                updatedCollateral = 0;
                netFee = positionCollateral + pnlInCollateral;
            }
            // Expected flow when in profit, add profits and subtract fees
            else {
                updatedCollateral = positionCollateral + pnlInCollateral - feesInCollateral;
                netFee = feesInCollateral;
            }
        } else {
            // Fees to pay + loss are already above the positions collateral
            // It shouldnt get to this point as the position should be liquidated
            if (feesInCollateral + pnlInCollateral > positionCollateral) {
                emit ProtocolLoss(
                    marketId, market.depositToken, feesInCollateral + pnlInCollateral - positionCollateral
                );

                updatedCollateral = 0;
                netFee = positionCollateral;
            }
            // Expected flow when at a loss, subtract fees and pnl
            else {
                updatedCollateral = positionCollateral - feesInCollateral - pnlInCollateral;
                netFee = feesInCollateral + pnlInCollateral;
            }
        }

        if (netFee != 0) {
            IERC20(market.depositToken).safeTransfer(feeManager, netFee);
            IFeeManager(feeManager).distributeFees(market.depositToken);
        }

        emit PnlRealized(positionId, isProfit, pnlInCollateral, feesInCollateral, executionPrice);
    }

    /// @notice Creates a new position from Order details provided during createOrder
    /// @param _orderId Order ID
    /// @param _executionPrice deviated price before order is settled
    function _createNewPosition(bytes32 _orderId, uint256 _executionPrice) internal {
        Order memory userOrder = pendingOrders[_orderId];
        Market memory market = dataFabric.getMarket(userOrder.marketId);

        bytes32 positionId = getPositionIdForUser(userOrder.userAddress);
        _incrementPositionNonce(userOrder.userAddress);

        if (isValidPosition(positionId)) revert LibError.ExistingPosition();

        Position storage userPosition = openPositions[positionId];

        // Update cumulative fees for the time passed since last fee update
        dataFabric.updateCumulativeFees(userOrder.marketId);

        // Calculate opening fees for NEW positions.
        if (market.openingFee != 0) {
            uint256 fees = (market.openingFee * userOrder.deltaSize) / MAX_FEE;
            // We are using the Secondary EMA price here to be consistent with the initial function `createNewPosition`
            // even though latest market price was pushed during settleOrder
            uint256 feeInCollateral =
                priceFeed.convertMarketToTokenSecondary(userOrder.marketId, fees, market.depositToken);
            userOrder.deltaCollateral -= feeInCollateral;

            // Store partner fees in mapping, which can be pulled later by the partner
            // Accumulated Partner fees stay in the OrderManager contract
            if (userOrder.partnerAddress != address(0) && partnerFee != 0) {
                uint256 partnerFeeAmount = (feeInCollateral * partnerFee) / MAX_FEE;
                accumulatedPartnerFees[userOrder.partnerAddress][market.depositToken] += partnerFeeAmount;
                feeInCollateral -= partnerFeeAmount;
            }

            // Transfer fees to FeeManager for Protocol and LP share
            if (feeInCollateral != 0) {
                IERC20(market.depositToken).safeTransfer(feeManager, feeInCollateral);
                IFeeManager(feeManager).distributeFees(market.depositToken);
            }
        }

        // Charge ExecutionFee, deduct from collateral sent
        uint256 executionFee = dataFabric.getExecutionFee(market.depositToken);
        if (executionFee != 0) {
            userOrder.deltaCollateral -= executionFee;
            IERC20(market.depositToken).safeTransfer(executionFeeReceiver, executionFee);
            emit ExecutionFeeReceived(positionId, market.depositToken, executionFee);
        }

        // Validate minimum collateral after deducting opening and executionFee
        if (userOrder.deltaCollateral < market.minCollateral) {
            revert LibError.InvalidCollateralAmount();
        }

        userPosition.marketId = userOrder.marketId;
        userPosition.userAddress = userOrder.userAddress;
        userPosition.isLong = userOrder.isLong;
        // The collateral amount stored for the position here is after deducting the openingFees and executionFee
        userPosition.positionCollateral = userOrder.deltaCollateral;
        userPosition.positionSize = userOrder.deltaSize;
        userPosition.avgPrice = _executionPrice;
        userPosition.lastCumulativeFee = dataFabric.getCurrentFeeCumulative(userOrder.marketId, userOrder.isLong);
        userPosition.lastTimestamp = block.timestamp;

        _validateLeverage(userOrder.marketId, userPosition.positionSize, userPosition.positionCollateral);
        dataFabric.updateMarketData(userOrder.marketId, userOrder.deltaSize, userOrder.isLong, true);
        emit NewPositionCreated(positionId, userOrder.marketId, userOrder.userAddress, userPosition.avgPrice);
    }

    /// @notice Close an existing user position
    /// @param _orderId Order ID
    function _closePosition(bytes32 _orderId, uint256 _executionPrice) internal {
        bytes32 positionId = getPositionIdFromOrderId(_orderId);
        _validateExistingPosition(positionId);

        _chargeExecutionFeeFromPosition(positionId);

        Position storage userPosition = openPositions[positionId];
        Market memory market = dataFabric.getMarket(userPosition.marketId);

        uint256 updatedCollateral = _chargeFeesAndSettleUnrealizedProfitOrLoss(
            positionId, userPosition.positionSize, market.closingFee, _executionPrice
        );

        dataFabric.updateMarketData(userPosition.marketId, userPosition.positionSize, userPosition.isLong, false);

        address _userAddress = userPosition.userAddress;
        emit PositionClosed(positionId, updatedCollateral, userPosition.positionSize);

        delete openPositions[positionId];

        // External Interaction
        if (updatedCollateral != 0) {
            IERC20(market.depositToken).safeTransfer(_userAddress, updatedCollateral);
        }
    }

    /// @notice Increases position collateral and/or size by Order details provided during createOrder
    /// @param _orderId Order ID
    /// @param _executionPrice Price at which the order is executed
    function _increasePosition(bytes32 _orderId, uint256 _executionPrice) internal {
        bytes32 positionId = getPositionIdFromOrderId(_orderId);
        _validateExistingPosition(positionId);

        Order memory userOrder = pendingOrders[_orderId];
        Market memory market = dataFabric.getMarket(userOrder.marketId);
        Position storage userPosition = openPositions[positionId];

        uint256 updatedCollateral = _chargeFeesAndSettleUnrealizedProfitOrLoss(
            positionId, userOrder.deltaSize, market.openingFee, _executionPrice
        );

        // As previous PNL is settled, the updated average price for the position is the execution price
        // trader would get as if creating a new position
        uint256 updatedAvgPrice = _verifyAndUpdatePrice(
            userPosition.marketId, userPosition.isLong, true, OrderDS.OrderType.OPEN_NEW_POSITION, userOrder.deltaSize
        );

        userPosition.positionSize = userPosition.positionSize + userOrder.deltaSize;
        userPosition.positionCollateral = updatedCollateral + userOrder.deltaCollateral;
        userPosition.avgPrice = updatedAvgPrice;
        userPosition.lastCumulativeFee = dataFabric.getCurrentFeeCumulative(userOrder.marketId, userOrder.isLong);
        userPosition.lastTimestamp = block.timestamp;

        _chargeExecutionFeeFromPosition(positionId);

        _validateLeverage(userPosition.marketId, userPosition.positionSize, userPosition.positionCollateral);
        dataFabric.updateMarketData(userOrder.marketId, userOrder.deltaSize, userOrder.isLong, true);

        emit PositionUpdated(positionId, userPosition.positionCollateral, userPosition.positionSize);
    }

    /// @notice Reduces position collateral and/or size by Order details provided during createOrder
    /// @param _orderId Order ID
    /// @param _executionPrice Price at which the order is executed
    function _decreasePosition(bytes32 _orderId, uint256 _executionPrice) internal {
        bytes32 positionId = getPositionIdFromOrderId(_orderId);
        _validateExistingPosition(positionId);

        _chargeExecutionFeeFromPosition(positionId);

        Order memory userOrder = pendingOrders[_orderId];
        Position storage userPosition = openPositions[positionId];
        Market memory market = dataFabric.getMarket(userOrder.marketId);

        uint256 updatedCollateral = _chargeFeesAndSettleUnrealizedProfitOrLoss(
            positionId, userOrder.deltaSize, market.closingFee, _executionPrice
        );

        if (updatedCollateral - userOrder.deltaCollateral < market.minCollateral) {
            revert LibError.InvalidCollateralAmount();
        }

        // As previous PNL is settled, the updated average price for the position is the execution price
        // trader would get as if creating a new position
        uint256 updatedAvgPrice = _verifyAndUpdatePrice(
            userPosition.marketId, userPosition.isLong, false, OrderDS.OrderType.OPEN_NEW_POSITION, userOrder.deltaSize
        );

        userPosition.positionSize = userPosition.positionSize - userOrder.deltaSize;
        userPosition.positionCollateral = updatedCollateral - userOrder.deltaCollateral;
        userPosition.lastCumulativeFee = dataFabric.getCurrentFeeCumulative(userOrder.marketId, userOrder.isLong);
        userPosition.lastTimestamp = block.timestamp;
        userPosition.avgPrice = updatedAvgPrice;

        _validateLeverage(userPosition.marketId, userPosition.positionSize, userPosition.positionCollateral);

        dataFabric.updateMarketData(userOrder.marketId, userOrder.deltaSize, userOrder.isLong, false);

        emit PositionUpdated(positionId, userPosition.positionCollateral, userPosition.positionSize);

        // External Interaction
        if (userOrder.deltaCollateral != 0) {
            IERC20(market.depositToken).safeTransfer(userPosition.userAddress, userOrder.deltaCollateral);
        }
    }

    /// @notice Settles a pending order to update the position
    /// @dev The price feeds must be up to date to settle an order
    /// @param _orderId Order ID
    function _settleOrder(bytes32 _orderId) internal {
        Order memory userOrder = pendingOrders[_orderId];
        uint256 expectedPrice = userOrder.expectedPrice;

        if (!isPendingOrder(_orderId)) revert LibError.OrderDoesNotExist();
        if (userOrder.deadline < block.timestamp && userOrder.deadline != 0) revert LibError.OrderExpired();
        if (userOrder.isLimitOrder && expectedPrice == 0) revert LibError.InvalidLimitOrder();

        _validateMarket(userOrder.marketId);

        bool isIncrease =
            (userOrder.orderType == OrderType.OPEN_NEW_POSITION) || (userOrder.orderType == OrderType.INCREASE_POSITION);

        // Get market price for marketId. Avg deviated price for new positions, primary market price otherwise
        uint256 executionPrice = _verifyAndUpdatePrice(
            userOrder.marketId, userOrder.isLong, isIncrease, userOrder.orderType, userOrder.deltaSize
        );

        // If its a limit order, check if the limit price is reached, either above or below
        // depending on the triggerAbove flag
        if (userOrder.isLimitOrder) {
            if (
                (userOrder.triggerAbove && executionPrice < expectedPrice)
                    || (!userOrder.triggerAbove && executionPrice > expectedPrice)
            ) {
                revert LibError.PriceMismatch(executionPrice, expectedPrice);
            }
        }
        // Market Orders
        // Check if current market price is within slippage range
        else {
            if (expectedPrice != 0) {
                uint256 upperLimit =
                    (userOrder.expectedPrice * (PRECISION_MULTIPLIER + userOrder.maxSlippage)) / PRECISION_MULTIPLIER;
                uint256 lowerLimit =
                    (userOrder.expectedPrice * (PRECISION_MULTIPLIER - userOrder.maxSlippage)) / PRECISION_MULTIPLIER;

                if (
                    (userOrder.isLong && executionPrice > upperLimit)
                        || (!userOrder.isLong && executionPrice < lowerLimit)
                ) {
                    revert LibError.PriceMismatch(executionPrice, userOrder.expectedPrice);
                }
            }
        }

        if (userOrder.orderType == OrderType.OPEN_NEW_POSITION) {
            _createNewPosition(_orderId, executionPrice);
        } else if (userOrder.orderType == OrderType.CLOSE_POSITION) {
            _closePosition(_orderId, executionPrice);
        } else if (userOrder.orderType == OrderType.INCREASE_POSITION) {
            _increasePosition(_orderId, executionPrice);
        } else if (userOrder.orderType == OrderType.DECREASE_POSITION) {
            _decreasePosition(_orderId, executionPrice);
        }

        delete pendingOrders[_orderId];
        delete orderToPositionId[_orderId];

        emit OrderSettled(_orderId, executionPrice);
    }

    /// @notice Liquidates a position at loss
    /// @dev A position can be liquidated if it has reached the market liquidation threshold
    /// @param _positionId Position ID
    function _liquidatePosition(bytes32 _positionId) internal {
        Position storage userPosition = openPositions[_positionId];
        _validateExistingPosition(_positionId);
        _validateMarket(userPosition.marketId);

        Market memory market = dataFabric.getMarket(userPosition.marketId);

        uint256 executionPrice = priceFeed.getMarketPricePrimary(userPosition.marketId);

        (uint256 netPnl, bool isNetProfit, uint256 feesInCollateral) = _getNetProfitOrLossIncludingFees(
            _positionId, userPosition.positionSize, market.liquidationFee + market.closingFee, executionPrice
        );
        if (isNetProfit) revert LibError.LiquidationErrorNoLoss();

        uint256 liquidationThreshold =
            (market.liquidationThreshold * userPosition.positionCollateral) / PRECISION_MULTIPLIER;

        // Only liquidate if netPnl (feesInCollateral + pnlInCollateral) is above a % of user collateral
        if (netPnl <= liquidationThreshold) {
            revert LibError.LiquidationErrorNoLoss();
        }

        // Allow liquidation if user collateral cant cover netPnl
        // by just limiting netPnl to all user available collateral
        if (netPnl > userPosition.positionCollateral) {
            // Emit event before updating netPnl to know the real loss
            emit ProtocolLoss(userPosition.marketId, market.depositToken, netPnl - userPosition.positionCollateral);

            // shouldnt get to this point as the position should have been liquidated
            netPnl = userPosition.positionCollateral;
            feesInCollateral = 0;
        }

        // Calculate user remaining collateral
        uint256 remainingCollateral;
        address userAddress = userPosition.userAddress;
        if (netPnl < userPosition.positionCollateral) {
            remainingCollateral = userPosition.positionCollateral - netPnl;
        }

        // Decrease shorts/longs in DataFabric
        dataFabric.updateMarketData(userPosition.marketId, userPosition.positionSize, userPosition.isLong, false);

        // Remove position
        delete openPositions[_positionId];
        emit PositionLiquidated(_positionId, remainingCollateral, executionPrice, netPnl);

        // External Interactions
        if (netPnl != 0) {
            IERC20(market.depositToken).safeTransfer(feeManager, netPnl);
            IFeeManager(feeManager).distributeFees(market.depositToken);
        }

        if (remainingCollateral != 0) {
            IERC20(market.depositToken).safeTransfer(userAddress, remainingCollateral);
        }

        emit PnlRealized(_positionId, false, 0, feesInCollateral, executionPrice);
    }

    function _incrementOrderNonce(address userAddress) internal {
        orderNonce[userAddress] = orderNonce[userAddress] + 1;
    }

    function _incrementPositionNonce(address userAddress) internal {
        positionNonce[userAddress] = positionNonce[userAddress] + 1;
    }

    function _validateOrder(Order memory _order) internal view {
        if (_order.userAddress != _msgSender()) revert LibError.InvalidUserAddress();
        if (_order.deadline < block.timestamp && _order.deadline != 0) revert LibError.InvalidTimestamp();
        if (_order.isLimitOrder && _order.expectedPrice == 0) revert LibError.InvalidLimitOrder();
        _validateMarket(_order.marketId);
    }

    /// @notice Overrides for Openzeppelin Context contract
    /// @inheritdoc ERC2771Context
    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        sender = ERC2771Context._msgSender();
    }

    /// @notice Overrides for Openzeppelin Context contract
    /// @inheritdoc ERC2771Context
    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _chargeExecutionFeeFromPosition(bytes32 positionId) internal {
        Position storage userPosition = openPositions[positionId];

        address depositToken = dataFabric.getDepositToken(userPosition.marketId);
        uint256 executionFee = dataFabric.getExecutionFee(depositToken);

        if (executionFee != 0 && executionFeeReceiver != address(0)) {
            userPosition.positionCollateral -= executionFee;
            IERC20(depositToken).safeTransfer(executionFeeReceiver, executionFee);
            emit ExecutionFeeReceived(positionId, depositToken, executionFee);
        }
    }

    /////////////////////////////////////////////
    //         PUBLIC/EXTERNAL FUNCTIONS
    /////////////////////////////////////////////

    /// @notice Create a new position with provided details
    /// The order needs to be settled by a keeper before a position is created/updated
    /// @param _order   Order details. Refer OrderDS.Order
    function createNewPosition(Order memory _order, bool isRelayed) external nonReentrant whenNotPaused {
        if (_order.orderType != OrderType.OPEN_NEW_POSITION) revert LibError.InvalidOrderType();

        // Validate order details
        if (_order.deadline < block.timestamp && _order.deadline != 0) revert LibError.InvalidTimestamp();
        if (_order.isLimitOrder && _order.expectedPrice == 0) revert LibError.InvalidLimitOrder();
        _validateMarket(_order.marketId);

        Market memory market = dataFabric.getMarket(_order.marketId);

        // Validate minimum collateral after opening fees
        uint256 openingFees = (market.openingFee * _order.deltaSize) / MAX_FEE;
        uint256 openingFeesInCollateral =
            priceFeed.convertMarketToTokenSecondary(_order.marketId, openingFees, market.depositToken);

        uint256 executionFee = dataFabric.getExecutionFee(market.depositToken);
        if (_order.deltaCollateral < market.minCollateral + openingFeesInCollateral + executionFee) {
            revert LibError.InvalidCollateralAmount();
        }

        // If the order is not relayed on someone's behalf, validate order.userAddress with actual user of the order
        if (!isRelayed && _order.userAddress != _msgSender()) {
            revert LibError.InvalidUserAddress();
        }

        IERC20(market.depositToken).safeTransferFrom(_msgSender(), address(this), _order.deltaCollateral);

        bytes32 orderId = getOrderIdForUser(_order.userAddress);
        _incrementOrderNonce(_order.userAddress);

        // If `openingFeesInCollateral` is greater than `_order.deltaCollateral`, it should revert because of underflow
        // even before the leverage validation, which is an expected behaviour.
        _validateLeverage(
            _order.marketId, _order.deltaSize, _order.deltaCollateral - openingFeesInCollateral - executionFee
        );

        // Store order details in storage for settlement
        pendingOrders[orderId] = _order;
        emit OrderCreated(orderId);
    }

    /// @notice Create a new position with provided details
    /// The order needs to be settled by a keeper before a position is created/updated
    /// @param _order   Order details. Refer OrderDS.Order
    function modifyPosition(bytes32 positionId, Order memory _order) external nonReentrant whenNotPaused {
        bytes32 orderId = getOrderIdForUser(_order.userAddress);
        _validateExistingPosition(positionId);
        _validateOrder(_order);

        Position memory userPosition = _getUserPosition(positionId);
        Market memory market = dataFabric.getMarket(userPosition.marketId);

        // Collect collateral from user if increasing position
        if (_order.orderType == OrderType.INCREASE_POSITION && _order.deltaCollateral != 0) {
            IERC20(market.depositToken).safeTransferFrom(_msgSender(), address(this), _order.deltaCollateral);
        }

        _incrementOrderNonce(_order.userAddress);

        // Validate if sender is owner of given positionId
        if (_msgSender() != userPosition.userAddress) revert LibError.InvalidUserAddress();

        // Validate if order direction differs
        if (_order.isLong != userPosition.isLong) revert LibError.InvalidOrderType();

        // Validate if marketId differs
        if (_order.marketId != userPosition.marketId) revert LibError.InvalidMarketId();

        if (_order.orderType == OrderType.CLOSE_POSITION) {
            // Fees for borrowing and closing position will be deducted on settlement from collateral
            // For closing a position, orderSize be equal to position size.
            if (_order.deltaSize != userPosition.positionSize) {
                revert LibError.InvalidSize();
            }
        } else if (_order.orderType == OrderType.INCREASE_POSITION) {
            // Increase
            // CollateralAmount can be zero in case user wants to increase the positionSize. OrderSize should be the
            // increase in positionSize
            // OrderSize can be 0 in case user wants to add more collateral to the same position size
            // Both collateralAmount and orderSize cannot be zero at the same time
            if (_order.deltaCollateral == 0 && _order.deltaSize == 0) {
                revert LibError.InvalidCollateralAmount();
            }
        } else if (_order.orderType == OrderType.DECREASE_POSITION) {
            // Decrease
            // CollateralAmount can be zero in case user wants to only decrease the positionSize
            // If user wants to withdraw some profits from collateral deposited, collateralAmount is the amount
            // withdrawn
            // Both collateralAmount and orderSize cannot be zero at the same time
            // Collateral and size cant be more than existing position
            // Order Size needs to be less than existing position size

            if (_order.deltaCollateral == 0 && _order.deltaSize == 0) {
                revert LibError.InvalidCollateralAmount();
            }

            // If `deltaCollateral` is more than `positionCollateral`, the tx will revert with underflow
            // also failing minCollateral check, which is an expected behaviour
            if (userPosition.positionCollateral - _order.deltaCollateral < market.minCollateral) {
                revert LibError.BelowMinCollateral();
            }

            if (_order.deltaSize >= userPosition.positionSize) {
                revert LibError.InvalidSize();
            }
        } else {
            revert LibError.InvalidOrderType();
        }

        // Store order details in storage for settlement
        orderToPositionId[orderId] = positionId;
        pendingOrders[orderId] = _order;
        emit OrderCreated(orderId);
    }

    /// @notice Settles a pending order to update the position
    /// @dev The price feeds must be up to date to settle an order
    /// @param orderId Order ID
    /// @param priceUpdateData Price update data from Pyth network
    function settleOrder(bytes32 orderId, bytes[] calldata priceUpdateData)
        external
        nonReentrant
        onlyKeeper
        whenNotPaused
    {
        priceFeed.updatePythPrice(priceUpdateData);
        _settleOrder(orderId);
    }

    /// @notice Liquidates a position at loss
    /// @dev A position can be liquidated if it has reached the market liquidation threshold
    /// @param positionId Position ID
    /// @param priceUpdateData Price update data from Pyth network
    function liquidatePosition(bytes32 positionId, bytes[] calldata priceUpdateData)
        external
        nonReentrant
        onlyKeeper
        whenNotPaused
    {
        priceFeed.updatePythPrice(priceUpdateData);
        _liquidatePosition(positionId);
    }

    /// @notice Cancel an unsettled pending order
    /// @param _orderId Order ID
    function cancelPendingOrder(bytes32 _orderId) external nonReentrant whenNotPaused {
        if (!isPendingOrder(_orderId)) revert LibError.OrderDoesNotExist();

        Order storage userOrder = pendingOrders[_orderId];
        if (userOrder.userAddress != _msgSender()) revert LibError.InvalidUserAddress();

        Market memory market = dataFabric.getMarket(userOrder.marketId);

        address userAddress = userOrder.userAddress;
        uint256 userBalance;

        // Only return the amount if sent by the user to this contract
        if (userOrder.orderType == OrderType.OPEN_NEW_POSITION || userOrder.orderType == OrderType.INCREASE_POSITION) {
            userBalance = userOrder.deltaCollateral;
        }

        delete pendingOrders[_orderId];
        delete orderToPositionId[_orderId];
        emit OrderCancelled(_orderId, userBalance);

        // External Interactions
        if (userBalance != 0) {
            IERC20(market.depositToken).safeTransfer(userAddress, userBalance);
        }
    }

    /// @notice Calculates the current profit or loss in USD of the position with `positionId`
    /// @param _positionId Position ID
    /// @param _price execution price to compare the avg price to
    /// @return totalProfitOrLoss Amount of Profit or Loss in USD
    /// @return isProfit Boolean to indicate if it is a profit or loss
    function getProfitOrLossInUsd(bytes32 _positionId, uint256 _price)
        public
        view
        returns (uint256 totalProfitOrLoss, bool isProfit)
    {
        Position memory userPosition = openPositions[_positionId];
        _validateExistingPosition(_positionId);

        uint256 profitOrLoss;
        if (userPosition.isLong) {
            if (_price > userPosition.avgPrice) {
                // User position is profitable
                profitOrLoss = (_price - userPosition.avgPrice);
                isProfit = true;
            } else {
                // User position is at loss
                profitOrLoss = (userPosition.avgPrice - _price);
                // isProfit = false (default value)
            }
        } else {
            if (_price > userPosition.avgPrice) {
                // User position is at loss
                profitOrLoss = (_price - userPosition.avgPrice);
                // isProfit = false (default value)
            } else {
                // User position is profitable
                profitOrLoss = (userPosition.avgPrice - _price);
                isProfit = true;
            }
        }
        uint256 marketDecimals = dataFabric.getMarket(userPosition.marketId).marketDecimals;
        totalProfitOrLoss = userPosition.positionSize * profitOrLoss / 10 ** marketDecimals;
    }

    /// @notice Calculates the amount owed in borrow fees for a position
    /// @param _positionId Position ID
    /// @return accruedBorrowFees Amount owed in borrow fees in market
    function getAccruedBorrowFeesInMarket(bytes32 _positionId) public view returns (uint256 accruedBorrowFees) {
        Position memory userPosition = openPositions[_positionId];
        uint256 currFeeCumulative = dataFabric.getCurrentFeeCumulative(userPosition.marketId, userPosition.isLong);

        // currFeeCumulative is in wei and % so we need to divide by 100 and by 1 ether;
        // we roundUp to avoid losing fees
        accruedBorrowFees = userPosition.positionSize.mulDiv(
            _getDiff(currFeeCumulative, userPosition.lastCumulativeFee), 100 * 1 ether, Math.Rounding.Up
        );
    }

    /// @notice Returns true if a valid position exists with `_positionId`
    /// @param _positionId Position ID
    /// @return bool True if valid, false if invalid positionID
    function isValidPosition(bytes32 _positionId) public view returns (bool) {
        if (_positionId == bytes32(0)) return false;
        Position memory userPosition = openPositions[_positionId];
        if (userPosition.marketId == bytes32(0)) return false;
        if (userPosition.userAddress == address(0)) return false;

        return true;
    }

    /// @notice Returns true if an unsettled pending order exists with `_orderId`
    /// @param _orderId Order ID
    /// @return bool True if order is pending, false otherwise
    function isPendingOrder(bytes32 _orderId) public view returns (bool) {
        Order memory userOrder = pendingOrders[_orderId];
        if (userOrder.marketId == bytes32(0)) return false;
        if (userOrder.userAddress == address(0)) return false;

        return true;
    }

    /// @notice Returns the computed order ID based on params
    /// @param userAddress User address
    /// @return orderId
    function getOrderIdForUser(address userAddress) public view returns (bytes32 orderId) {
        orderId = keccak256(abi.encode("ORD", userAddress, orderNonce[userAddress], _CACHED_CHAIN_ID));
    }

    /// @notice Returns the computed position ID based on params
    /// @param userAddress User address
    /// @return positionId
    function getPositionIdForUser(address userAddress) public view returns (bytes32 positionId) {
        positionId = keccak256(abi.encode("POS", userAddress, positionNonce[userAddress], _CACHED_CHAIN_ID));
    }

    /// @notice Returns the position ID for an orderId
    /// @param _orderId Order ID
    /// @return positionId Position ID for orderId
    function getPositionIdFromOrderId(bytes32 _orderId) public view returns (bytes32) {
        return orderToPositionId[_orderId];
    }

    /// @notice Returns pending order details for `orderId`
    /// @param orderId Order ID
    /// @return orderDetails Order details for `orderId`
    function getPendingOrder(bytes32 orderId) external view returns (Order memory orderDetails) {
        return pendingOrders[orderId];
    }

    /// @notice Returns position details for `positionId`
    /// @param positionId Position ID
    /// @return positionData Position details for `positionId`
    function getPosition(bytes32 positionId) external view returns (Position memory positionData) {
        return openPositions[positionId];
    }

    /// @notice Used to claim accrued partner fees
    /// @param partnerAddress Address of the partner
    /// @param tokenAddress ERC20 token address
    function claimPartnerFees(address partnerAddress, address tokenAddress) external {
        uint256 accruedFees = accumulatedPartnerFees[partnerAddress][tokenAddress];
        accumulatedPartnerFees[partnerAddress][tokenAddress] = 0;

        IERC20(tokenAddress).safeTransfer(partnerAddress, accruedFees);
        emit PartnerFeesClaimed(partnerAddress, tokenAddress, accruedFees);
    }

    /////////////////////////////////////////////
    //         ADMIN/RESTRICTED FUNCTIONS
    /////////////////////////////////////////////

    /// @notice Update the Price Feed and FeeManager addresses
    /// @param _newPriceFeed New price feed address
    /// @param _newFeeManager New Fee Manager address
    function updateContractAddresses(address payable _newPriceFeed, address _newFeeManager) external onlyAdmin {
        if (_newPriceFeed == address(0) || _newFeeManager == address(0)) revert LibError.ZeroAddress();
        priceFeed = IPriceFeed(_newPriceFeed);
        emit ParifiPriceFeedUpdated(_newPriceFeed);

        feeManager = _newFeeManager;
        emit FeeManagerUpdated(_newFeeManager);
    }

    /// @notice Sets the partner fee for referrals
    /// @dev The partner fee is a percentage of the opening fee and cannot be more than 50% of the opening fee
    /// @param _updatedFee Address of the token
    function setPartnerFee(uint256 _updatedFee) external onlyAdmin {
        if (_updatedFee >= (MAX_FEE / 2)) revert LibError.MaxFee();
        emit PartnerFeeUpdated(partnerFee, _updatedFee);
        partnerFee = _updatedFee;
    }

    /// @notice Sets receiver address for executionFees
    /// @param _feeReceiver receiver address
    function setExecutionFeeReceiver(address _feeReceiver) external onlyAdmin {
        emit ExecutionFeeReceiverUpdate(executionFeeReceiver, _feeReceiver);
        executionFeeReceiver = _feeReceiver;
    }

    /// @notice Triggers stopped state
    function pause() external onlyAdmin {
        _pause();
    }

    /// @notice Returns to normal state
    function unpause() external onlyAdmin {
        _unpause();
    }
}