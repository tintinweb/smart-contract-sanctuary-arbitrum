// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    /// getRoundData and latestRoundData should both raise "No data present"
    /// if they do not have data to report, instead of returning unset values
    /// which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @title The oracle V2.2 interface by Woo.Network.
/// @notice update and posted the latest price info by Woo.
interface IWooracleV2_2 {
    struct State {
        uint128 price;
        uint64 spread;
        uint64 coeff;
        bool woFeasible;
    }

    // /// @notice Wooracle spread value
    // function woSpread(address base) external view returns (uint64);

    // /// @notice Wooracle coeff value
    // function woCoeff(address base) external view returns (uint64);

    // /// @notice Wooracle state for the specified base token
    // function woState(address base) external view returns (State memory);

    // /// @notice Chainlink oracle address for the specified base token
    // function cloAddress(address base) external view returns (address clo);

    // /// @notice Wooracle price of the base token
    // function woPrice(address base) external view returns (uint128 price, uint256 timestamp);

    /// @notice ChainLink price of the base token / quote token
    function cloPrice(address base) external view returns (uint256 price, uint256 timestamp);

    /// @notice Returns Woooracle price if available, otherwise fallback to ChainLink
    function price(address base) external view returns (uint256 priceNow, bool feasible);

    /// @notice Updates the Wooracle price for the specified base token
    function postPrice(address base, uint128 _price) external;

    /// Updates the state of the given base token.
    /// @param _base baseToken address
    /// @param _price the new prices
    /// @param _spread the new spreads
    /// @param _coeff the new slippage coefficent
    function postState(
        address _base,
        uint128 _price,
        uint64 _spread,
        uint64 _coeff
    ) external;

    /// @notice State of the specified base token.
    function state(address base) external view returns (State memory);

    /// @notice The price decimal for the specified base token (e.g. 8)
    function decimals(address base) external view returns (uint8);

    /// @notice The quote token for calculating WooPP query price
    function quoteToken() external view returns (address);

    /// @notice last updated timestamp
    function timestamp() external view returns (uint256);

    /// @notice Flag for Wooracle price feasible
    function isWoFeasible(address base) external view returns (bool);

    // /// @notice Flag for account admin
    // function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import "../interfaces/IWooracleV2_2.sol";
import "../interfaces/AggregatorV3Interface.sol";

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

// OpenZeppelin contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Wooracle V2.2 contract for WooPPV2
/// subversion 1 change: no timestamp update for posting price from WooPP.
/// subversion 2 change: support legacy postState utilizing block.timestamp
contract WooracleV2_2 is Ownable, IWooracleV2_2 {
    /* ----- State variables ----- */

    // 128 + 64 + 64 = 256 bits (slot size)
    struct TokenInfo {
        uint128 price; // as chainlink oracle (e.g. decimal = 8)                zip: 32 bits = (27, 5)
        uint64 coeff; // k: decimal = 18.    18.4 * 1e18                        zip: 16 bits = (11, 5), 2^11 = 2048
        uint64 spread; // s: decimal = 18.   spread <= 2e18   18.4 * 1e18       zip: 16 bits = (11, 5)
    }

    struct CLOracle {
        address oracle;
        uint8 decimal;
        bool cloPreferred;
    }

    struct PriceRange {
        uint128 min;
        uint128 max;
    }

    mapping(address => TokenInfo) public infos;
    mapping(address => CLOracle) public clOracles;
    mapping(address => PriceRange) public priceRanges;

    address public quoteToken;
    uint256 public timestamp;

    uint256 public staleDuration;
    uint64 public bound;

    address public wooPP;

    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isGuardian;

    mapping(uint8 => address) public basesMap;

    constructor() {
        staleDuration = uint256(300); // default: 5 mins
        bound = uint64(1e16); // 1%
    }

    modifier onlyAdmin() {
        require(owner() == msg.sender || isAdmin[msg.sender], "WooracleV2_2: !Admin");
        _;
    }

    modifier onlyGuardian() {
        require(isGuardian[msg.sender], "WooracleV2_2: !Guardian");
        _;
    }

    /* ----- External Functions ----- */

    function setRange(
        address _base,
        uint128 _min,
        uint128 _max
    ) external onlyGuardian {
        PriceRange storage priceRange = priceRanges[_base];
        priceRange.min = _min;
        priceRange.max = _max;
    }

    function setWooPP(address _wooPP) external onlyAdmin {
        wooPP = _wooPP;
    }

    function setAdmin(address _addr, bool _flag) external onlyOwner {
        isAdmin[_addr] = _flag;
    }

    function setGuardian(address _addr, bool _flag) external onlyOwner {
        isGuardian[_addr] = _flag;
    }

    /// @dev Set the quote token address.
    /// @param _oracle the token address
    function setQuoteToken(address _quote, address _oracle) external onlyAdmin {
        quoteToken = _quote;
        CLOracle storage cloRef = clOracles[_quote];
        cloRef.oracle = _oracle;
        cloRef.decimal = AggregatorV3Interface(_oracle).decimals();
    }

    function setBound(uint64 _bound) external onlyOwner {
        bound = _bound;
    }

    function setCLOracle(
        address _token,
        address _oracle,
        bool _cloPreferred
    ) external onlyAdmin {
        CLOracle storage cloRef = clOracles[_token];
        cloRef.oracle = _oracle;
        cloRef.decimal = AggregatorV3Interface(_oracle).decimals();
        cloRef.cloPreferred = _cloPreferred;
    }

    function setCloPreferred(address _token, bool _cloPreferred) external onlyAdmin {
        CLOracle storage cloRef = clOracles[_token];
        cloRef.cloPreferred = _cloPreferred;
    }

    /// @dev Set the staleDuration.
    /// @param _staleDuration the new stale duration
    function setStaleDuration(uint256 _staleDuration) external onlyAdmin {
        staleDuration = _staleDuration;
    }

    /// @dev Update the base token prices.
    /// @param _base the baseToken address
    /// @param _price the new prices for the base token
    function postPrice(address _base, uint128 _price) external onlyAdmin {
        // NOTE: update spread before setting a new price
        _updateSpreadForNewPrice(_base, _price);
        infos[_base].price = _price;
        if (msg.sender != wooPP) {
            timestamp = block.timestamp;
        }
    }

    /// @dev Update the base token prices.
    /// @param _base the baseToken address
    /// @param _price the new prices for the base token
    /// @param _ts the manual updated TS
    function postPrice(
        address _base,
        uint128 _price,
        uint256 _ts
    ) external onlyAdmin {
        // NOTE: update spread before setting a new price
        _updateSpreadForNewPrice(_base, _price);
        infos[_base].price = _price;
        timestamp = _ts;
    }

    /// @dev batch update baseTokens prices
    /// @param _bases list of baseToken address
    /// @param _prices the updated prices list
    function postPriceList(
        address[] calldata _bases,
        uint128[] calldata _prices,
        uint256 _ts
    ) external onlyAdmin {
        uint256 length = _bases.length;
        require(length == _prices.length, "WooracleV2_2: length_INVALID");

        for (uint256 i = 0; i < length; i++) {
            // NOTE: update spread before setting a new price
            _updateSpreadForNewPrice(_bases[i], _prices[i]);
            infos[_bases[i]].price = _prices[i];
        }

        timestamp = _ts;
    }

    /// @dev update the state of the given base token.
    /// @param _base baseToken address
    /// @param _price the new prices
    /// @param _spread the new spreads
    /// @param _coeff the new slippage coefficent
    function postState(
        address _base,
        uint128 _price,
        uint64 _spread,
        uint64 _coeff
    ) external onlyAdmin {
        _setState(_base, _price, _spread, _coeff);
        timestamp = block.timestamp;
    }

    /// @dev update the state of the given base token with the offchain timestamp.
    /// @param _base baseToken address
    /// @param _price the new prices
    /// @param _spread the new spreads
    /// @param _coeff the new slippage coefficent
    /// @param _ts the local timestamp
    function postState(
        address _base,
        uint128 _price,
        uint64 _spread,
        uint64 _coeff,
        uint256 _ts
    ) external onlyAdmin {
        _setState(_base, _price, _spread, _coeff);
        timestamp = _ts;
    }

    /// @dev batch update the prices, spreads and slipagge coeffs info.
    /// @param _bases list of baseToken address
    /// @param _prices the prices list
    /// @param _spreads the spreads list
    /// @param _coeffs the slippage coefficent list
    function postStateList(
        address[] calldata _bases,
        uint128[] calldata _prices,
        uint64[] calldata _spreads,
        uint64[] calldata _coeffs,
        uint256 _ts
    ) external onlyAdmin {
        uint256 length = _bases.length;
        for (uint256 i = 0; i < length; i++) {
            _setState(_bases[i], _prices[i], _spreads[i], _coeffs[i]);
        }
        timestamp = _ts;
    }

    /*
        Price logic:
        - woPrice: wooracle price
        - cloPrice: chainlink price

        woFeasible is, price > 0 and price timestamp NOT stale

        when woFeasible && priceWithinBound     -> woPrice, feasible
        when woFeasible && !priceWithinBound    -> woPrice, infeasible
        when !woFeasible && clo_preferred       -> cloPrice, feasible
        when !woFeasible && !clo_preferred      -> cloPrice, infeasible
    */
    function price(address _base) public view returns (uint256 priceOut, bool feasible) {
        uint256 woPrice_ = uint256(infos[_base].price);
        uint256 woPriceTimestamp = timestamp;

        (uint256 cloPrice_, ) = _cloPriceInQuote(_base, quoteToken);

        bool woFeasible = woPrice_ != 0 && block.timestamp <= (woPriceTimestamp + staleDuration);

        // bool woPriceInBound = cloPrice_ == 0 ||
        //     ((cloPrice_ * (1e18 - bound)) / 1e18 <= woPrice_ && woPrice_ <= (cloPrice_ * (1e18 + bound)) / 1e18);
        bool woPriceInBound = cloPrice_ != 0 &&
            ((cloPrice_ * (1e18 - bound)) / 1e18 <= woPrice_ && woPrice_ <= (cloPrice_ * (1e18 + bound)) / 1e18);

        if (woFeasible) {
            priceOut = woPrice_;
            feasible = woPriceInBound;
        } else {
            priceOut = clOracles[_base].cloPreferred ? cloPrice_ : 0;
            feasible = priceOut != 0;
        }

        // Guardian check: min-max
        if (feasible) {
            PriceRange memory range = priceRanges[_base];
            require(priceOut > range.min, "WooracleV2_2: !min");
            require(priceOut < range.max, "WooracleV2_2: !max");
        }
    }

    /// @notice the price decimal for the specified base token
    function decimals(address) external pure returns (uint8) {
        return 8;
    }

    function cloPrice(address _base) external view returns (uint256 refPrice, uint256 refTimestamp) {
        return _cloPriceInQuote(_base, quoteToken);
    }

    function isWoFeasible(address _base) external view override returns (bool) {
        return infos[_base].price != 0 && block.timestamp <= (timestamp + staleDuration);
    }

    function woState(address _base) external view returns (State memory) {
        TokenInfo memory info = infos[_base];
        return
            State({
                price: info.price,
                spread: info.spread,
                coeff: info.coeff,
                woFeasible: (info.price != 0 && block.timestamp <= (timestamp + staleDuration))
            });
    }

    function state(address _base) external view returns (State memory) {
        TokenInfo memory info = infos[_base];
        (uint256 basePrice, bool feasible) = price(_base);
        return State({price: uint128(basePrice), spread: info.spread, coeff: info.coeff, woFeasible: feasible});
    }

    /* ----- Internal Functions ----- */

    function _updateSpreadForNewPrice(address _base, uint128 _price) internal {
        uint64 preS = infos[_base].spread;
        uint128 preP = infos[_base].price;
        if (preP == 0 || _price == 0 || preS >= 1e18) {
            // previous price or current price is 0, no action is needed
            return;
        }

        uint256 maxP = _price >= preP ? _price : preP;
        uint256 minP = _price <= preP ? _price : preP;
        uint256 antiS = (uint256(1e18) * 1e18 * minP) / maxP / (uint256(1e18) - preS);
        if (antiS < 1e18) {
            uint64 newS = uint64(1e18 - antiS);
            if (newS > preS) {
                infos[_base].spread = newS;
            }
        }
    }

    function _updateSpreadForNewPrice(
        address _base,
        uint128 _price,
        uint64 _spread
    ) internal {
        require(_spread < 1e18, "!_spread");

        uint64 preS = infos[_base].spread;
        uint128 preP = infos[_base].price;
        if (preP == 0 || _price == 0 || preS >= 1e18) {
            // previous price or current price is 0, just use _spread
            infos[_base].spread = _spread;
            return;
        }

        uint256 maxP = _price >= preP ? _price : preP;
        uint256 minP = _price <= preP ? _price : preP;
        uint256 antiS = (uint256(1e18) * 1e18 * minP) / maxP / (uint256(1e18) - preS);
        if (antiS < 1e18) {
            uint64 newS = uint64(1e18 - antiS);
            infos[_base].spread = newS > _spread ? newS : _spread;
        } else {
            infos[_base].spread = _spread;
        }
    }

    function _setState(
        address _base,
        uint128 _price,
        uint64 _spread,
        uint64 _coeff
    ) internal {
        TokenInfo storage info = infos[_base];
        // NOTE: update spread before setting a new price
        _updateSpreadForNewPrice(_base, _price, _spread);
        info.price = _price;
        info.coeff = _coeff;
    }

    function _cloPriceInQuote(address _fromToken, address _toToken)
        internal
        view
        returns (uint256 refPrice, uint256 refTimestamp)
    {
        address baseOracle = clOracles[_fromToken].oracle;

        // NOTE: Only for chains where chainlink oracle is unavailable
        // if (baseOracle == address(0)) {
        //     return (0, 0);
        // }
        require(baseOracle != address(0), "WooracleV2_2: !oracle");

        address quoteOracle = clOracles[_toToken].oracle;
        uint8 quoteDecimal = clOracles[_toToken].decimal;

        (, int256 rawBaseRefPrice, , uint256 baseUpdatedAt, ) = AggregatorV3Interface(baseOracle).latestRoundData();
        (, int256 rawQuoteRefPrice, , uint256 quoteUpdatedAt, ) = AggregatorV3Interface(quoteOracle).latestRoundData();
        uint256 baseRefPrice = uint256(rawBaseRefPrice);
        uint256 quoteRefPrice = uint256(rawQuoteRefPrice);

        // NOTE: Assume wooracle token decimal is same as chainlink token decimal.
        uint256 ceoff = uint256(10)**quoteDecimal;
        refPrice = (baseRefPrice * ceoff) / quoteRefPrice;
        refTimestamp = baseUpdatedAt >= quoteUpdatedAt ? quoteUpdatedAt : baseUpdatedAt;
    }

    /* ----- Zip Related Functions ----- */

    function setBase(uint8 _id, address _base) external onlyAdmin {
        require(getBase(_id) == address(0), "WooracleV2_2: !id_SET_ALREADY");
        basesMap[_id] = _base;
    }

    function getBase(uint8 _id) public view returns (address) {
        address[5] memory CONST_BASES = [
            // mload
            // NOTE: Update token address for different chains
            0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, // WETH
            0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f, // WBTC
            0x912CE59144191C1204E64559FE8253a0e49E6548, // ARB
            0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, // USDT
            0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8  // USDC.e
        ];

        return _id < CONST_BASES.length ? CONST_BASES[_id] : basesMap[_id];
    }

    // https://docs.soliditylang.org/en/v0.8.12/contracts.html#fallback-function
    // prettier-ignore
    fallback (bytes calldata _input) external onlyAdmin returns (bytes memory _output) {
        /*
            2 bit:  0: post prices,
                    1: post states,
                    2: post prices with local timestamp
                    3: post states with local timestamp
            6 bits: length

            post prices:
               [price] -->
                  base token: 8 bites (1 byte)
                  price data: 32 bits = (27, 5)

            post states:
               [states] -->
                  base token: 8 bites (1 byte)
                  price:      32 bits (4 bytes) = (27, 5)
                  k coeff:    16 bits (2 bytes) = (11, 5)
                  s spread:   16 bits (2 bytes) = (11, 5)

            4 bytes (32bits): timestamp
                MAX: 2^32-1 = 4,294,967,295 = Feb 7, 2106 6:28:15 AM (~83 years away)
        */

        uint256 x = _input.length;
        require(x > 0, "WooracleV2_2: !calldata");

        uint8 firstByte = uint8(bytes1(_input[0]));
        uint8 op = firstByte >> 6; // 11000000
        uint8 len = firstByte & 0x3F; // 00111111

        if (op == 0 || op == 2) {
            // post prices list
            address base;
            uint128 p;

            for (uint256 i = 0; i < len; ++i) {
                base = getBase(uint8(bytes1(_input[1 + i * 5:1 + i * 5 + 1])));
                p = _decodePrice(uint32(bytes4(_input[1 + i * 5 + 1:1 + i * 5 + 5])));

                // NOTE: update spread before setting a new price
                _updateSpreadForNewPrice(base, p);
                infos[base].price = p;
            }

            timestamp = (op == 0) ? block.timestamp : uint256(uint32(bytes4(_input[1 + len * 5:1 + len * 5 + 4])));
        } else if (op == 1 || op == 3) {
            // post states list
            address base;
            uint128 p;
            uint64 s;
            uint64 k;

            for (uint256 i = 0; i < len; ++i) {
                base = getBase(uint8(bytes1(_input[1 + i * 9:1 + i * 9 + 1])));
                p = _decodePrice(uint32(bytes4(_input[1 + i * 9 + 1:1 + i * 9 + 5])));
                s = _decodeKS(uint16(bytes2(_input[1 + i * 9 + 5:1 + i * 9 + 7])));
                k = _decodeKS(uint16(bytes2(_input[1 + i * 9 + 7:1 + i * 9 + 9])));
                _setState(base, p, s, k);
            }

            timestamp = (op == 1) ? block.timestamp : uint256(uint32(bytes4(_input[1 + len * 9:1 + len * 9 + 4])));
        } else {
            revert("WooracleV2_2: !op");
        }
    }

    function _decodePrice(uint32 b) internal pure returns (uint128) {
        return uint128((b >> 5) * (10**(b & 0x1F))); // 0x1F = 00011111
    }

    function _decodeKS(uint16 b) internal pure returns (uint64) {
        return uint64((b >> 5) * (10**(b & 0x1F)));
    }

    function inCaseTokenGotStuck(address stuckToken) external onlyAdmin {
        if (stuckToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            TransferHelper.safeTransferETH(owner(), address(this).balance);
        } else {
            uint256 amount = IERC20(stuckToken).balanceOf(address(this));
            TransferHelper.safeTransfer(stuckToken, owner(), amount);
        }
    }
}