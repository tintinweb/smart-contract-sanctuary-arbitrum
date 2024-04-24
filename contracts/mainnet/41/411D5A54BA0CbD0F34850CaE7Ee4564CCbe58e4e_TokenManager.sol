// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

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
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

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
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ITokenManager {
  function usageAllocations(address userAddress, address usageAddress) external view returns (uint256 allocation);
  function allocateFromUsage(address userAddress, uint256 amount) external;
  function deallocateFromUsage(address userAddress, uint256 amount) external;
  function convertTo(uint256 amount, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IesSDY is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IesSDYUsage {
  function allocate(address userAddress, uint256 amount, bytes calldata data) external;
  function deallocate(address userAddress, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISDY is IERC20 {
  function mint(address account, uint256 amount) external;
  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISDY } from "../interfaces/tokens/ISDY.sol";
import { IesSDY} from "../interfaces/tokens/IesSDY.sol";
import { IesSDYUsage } from "../interfaces/tokens/IesSDYUsage.sol";
import { ITokenManager } from "../interfaces/staking/ITokenManager.sol";
import { Errors } from "../utils/Errors.sol";

/**
  * @title TokenManager
  * @author Steadefi
  * @notice Contract that manages the function and dynamics of SDY and esSDY.
  * This contract is made to receive esSDY deposits from users in order to allocate them
  * to Usages (plugins) contracts.
*/
contract TokenManager is Ownable2Step, ReentrancyGuard, ITokenManager, Pausable {

  using SafeERC20 for IERC20;

  /* ==================== STATE VARIABLES ==================== */

  // SDY token address
  address public immutable SDY;
  // esSDY token address
  address public immutable esSDY;
  // Whether pairing of SDY is required for esSDY redemption
  bool public pairingSDYRequired;
  // Minimum redemption ratio
  uint256 public minRedeemRatio = 0.35e18;
  // Maximum redemption ratio
  uint256 public maxRedeemRatio = 1e18;
  // Minimum redemption duration
  uint256 public minRedeemDuration = 30 seconds;
  // Maximum redemption duration
  uint256 public maxRedeemDuration = 180 seconds;

  /* ======================= STRUCTS ========================= */

  struct esSDYBalance {
    // Amount of esSDY allocated to a Usage
    uint256 allocatedAmount;
    // Total amount of esSDY currently being redeemed
    uint256 redeemingAmount;
  }

  struct RedeemInfo {
    // esSDY amount to redeem
    uint256 esSDYAmount;
    // SDY amount to receive when vesting has ended
    uint256 SDYAmount;
    // paired SDY amount for this redemption; received when vesting has ended
    uint256 pairedSDYAmount;
    // Timestamp when vesting ends
    uint256 endTime;
  }

  /* ====================== CONSTANTS ======================== */

  uint256 public constant MAX_DEALLOCATION_FEE = 2e16; // 2%
  uint256 public constant MAX_FIXED_RATIO = 1e18; // 100%
  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================= MAPPINGS ======================== */

  // Usage approvals to allocate esSDY
  mapping(address => mapping(address => uint256)) public usageApprovals;
  // Active esSDY allocations to usages
  mapping(address => mapping(address => uint256)) public override usageAllocations;
  // User's esSDY balances
  mapping(address => esSDYBalance) public esSDYBalances;
  // User's redeeming instances
  mapping(address => RedeemInfo[]) public userRedeems;
  // Fee paid when deallocating esSDY
  mapping(address => uint256) public usagesDeallocationFee;

  /* ======================= EVENTS ========================== */

  event ApproveUsage(address indexed userAddress, address indexed usageAddress, uint256 amount);
  event Convert(address indexed from, address to, uint256 amount);
  event UpdateRedeemSettings(
    uint256 minRedeemRatio,
    uint256 maxRedeemRatio,
    uint256 minRedeemDuration,
    uint256 maxRedeemDuration
  );
  event UpdateDeallocationFee(address indexed usageAddress, uint256 fee);
  event Redeem(
    address indexed userAddress,
    uint256 esSDYAmount,
    uint256 SDYAmount,
    uint256 pairedSDYAmount,
    uint256 duration
  );
  event FinalizeRedeem(
    address indexed userAddress,
    uint256 esSDYAmount,
    uint256 SDYAmount,
    uint256 pairedSDYAmount
  );
  event CancelRedeem(address indexed userAddress, uint256 esSDYAmount);
  event Allocate(address indexed userAddress, address indexed usageAddress, uint256 amount);
  event Deallocate(
    address indexed userAddress,
    address indexed usageAddress,
    uint256 amount,
    uint256 fee
  );
  event UpdatePairingSDYRequired(bool required);

  /* ======================= MODIFIERS ======================= */

  /**
    * @notice Check if a redeem entry exists
    * @param _userAddress address of redeemer
    * @param _redeemIndex index to check
  */
  modifier validateRedeem(address _userAddress, uint256 _redeemIndex) {
    if (_redeemIndex >= userRedeems[_userAddress].length) revert Errors.RedeemEntryDoesNotExist();
    _;
  }

  /* ====================== CONSTRUCTOR ====================== */

  /**
    * @param _SDY address of SDY token
    * @param _esSDY address of esSDY token
  */
  constructor(address _SDY, address _esSDY) Ownable(msg.sender) {
    if (_SDY == address(0)) revert Errors.ZeroAddressNotAllowed();
    if (_esSDY == address(0)) revert Errors.ZeroAddressNotAllowed();

    SDY = _SDY;
    esSDY = _esSDY;

     // Pause redemption on first deployment
    _pause();
  }

  /* ==================== VIEW FUNCTIONS ===================== */

  /**
    * @notice Returns redeemable SDY for "amount" of esSDY vested for "duration" seconds
    * @param amount amount of esSDY being redeemed in 1e18
    * @param duration duration of redemption
    * @return amount amount of SDY to receive after redemption is completed in 1e18
  */
  function getSDYByVestingDuration(uint256 amount, uint256 duration) public view returns (uint256) {
    if (duration < minRedeemDuration) {
      return 0;
    }

    // capped to maxRedeemDuration
    if (duration > maxRedeemDuration) {
      return amount * (maxRedeemRatio) / (SAFE_MULTIPLIER);
    }

    uint256 _redeemRatio = minRedeemRatio + (
      (duration - minRedeemDuration) * (maxRedeemRatio - minRedeemRatio)
      / (maxRedeemDuration - minRedeemDuration)
    );

    return amount * _redeemRatio / SAFE_MULTIPLIER;
  }

  /**
    * @notice Returns quantity of "userAddress" pending redeems
    * @param userAddress user address
    * @return pendingRedeems amount of esSDY allocated to a plugin in 1e18
  */
  function getUserRedeemsLength(address userAddress) external view returns (uint256) {
    return userRedeems[userAddress].length;
  }

  /**
    * @notice Returns "userAddress" info for a pending redeem identified by "redeemIndex"
    * @param userAddress address of redeemer
    * @param redeemIndex index to check
    * @return SDYAmount amount of SDY in redemption
    * @return esSDYAmount amount of esSDY redeemable in this redemption
    * @return pairedSDYAmount amount of paired SDY in this redemption
    * @return endTime timestamp when redemption is fully complete
  */
  function getUserRedeem(
    address userAddress,
    uint256 redeemIndex
  ) external view validateRedeem(userAddress, redeemIndex)
    returns (uint256 SDYAmount, uint256 esSDYAmount, uint256 pairedSDYAmount, uint256 endTime)
  {
    RedeemInfo storage _redeem = userRedeems[userAddress][redeemIndex];
    return (_redeem.SDYAmount, _redeem.esSDYAmount, _redeem.pairedSDYAmount, _redeem.endTime);
  }

  /**
    * @notice Returns approved esSDY to allocate from "userAddress" to "usageAddress"
    * @param userAddress address of user
    * @param usageAddress address of plugin
    * @return amount amount of esSDY approved to plugin in 1e18
  */
  function getUsageApproval(
    address userAddress,
    address usageAddress
  ) external view returns (uint256) {
    return usageApprovals[userAddress][usageAddress];
  }

  /**
    * @notice Returns allocated esSDY from "userAddress" to "usageAddress"
    * @param userAddress address of user
    * @param usageAddress address of plugin
    * @return amount amount of esSDY allocated to plugin in 1e18
  */
  function getUsageAllocation(
    address userAddress,
    address usageAddress
  ) external view returns (uint256) {
    return usageAllocations[userAddress][usageAddress];
  }

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice Convert SDY to esSDY
    * @param amount amount of SDY to convert in 1e18
  */
  function convert(uint256 amount) external nonReentrant {
    _convert(amount, msg.sender);
  }

  /**
    * @notice Convert SDY to esSDY to "to" address
    * @param amount amount of SDY to convert in 1e18
    * @param to address to convert to
  */
  function convertTo(uint256 amount, address to) external override nonReentrant {
    _convert(amount, to);
  }

  /**
    * @notice Approves "usage" address to get allocations up to "amount" of esSDY from msg.sender
    * @param usage address of usage plugin
    * @param amount amount of esSDY to approve in 1e18
  */
  function approveUsage(IesSDYUsage usage, uint256 amount) external nonReentrant {
    if (address(usage) == address(0)) revert Errors.ZeroAddressNotAllowed();

    usageApprovals[msg.sender][address(usage)] = amount;
    emit ApproveUsage(msg.sender, address(usage), amount);
  }

  /**
    * @notice Initiates redeem process (esSDY to SDY)
    * @notice If pairingSDYRequired is true, transfer equal amounts of SDY as esSDY to redeem
    * @param esSDYAmount amount of esSDY to redeem
    * @param duration selected timestamp of redemption completion
  */
  function redeem(uint256 esSDYAmount, uint256 duration) external nonReentrant whenNotPaused {
    if (esSDYAmount == 0) revert Errors.InvalidAmount();
    if (duration > maxRedeemDuration) revert Errors.InvalidRedeemDuration();

    uint256 _pairedSDYAmount;

    if (pairingSDYRequired) {
      _pairedSDYAmount = esSDYAmount;
      IERC20(SDY).safeTransferFrom(msg.sender, address(this), _pairedSDYAmount);
    }

    IERC20(esSDY).safeTransferFrom(msg.sender, address(this), esSDYAmount);

    // get post vest SDY amount
    uint256 SDYAmount = getSDYByVestingDuration(esSDYAmount, duration);

    // add to redeeming total
    esSDYBalances[msg.sender].redeemingAmount += esSDYAmount;

    if (duration < minRedeemDuration) revert Errors.InvalidRedeemDuration();

    // add redeeming entry
    userRedeems[msg.sender].push(
      RedeemInfo(
        esSDYAmount,
        SDYAmount,
        _pairedSDYAmount,
        block.timestamp + duration
      )
    );

    emit Redeem(msg.sender, esSDYAmount, SDYAmount, esSDYAmount, duration);
  }

  /**
    * @notice Finalizes redeem process when vesting duration has been reached
    * @param redeemIndex redemption index
    * Can only be called by the redeem entry owner
  */
  function finalizeRedeem(
    uint256 redeemIndex
  ) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
    esSDYBalance storage balance = esSDYBalances[msg.sender];
    RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];

    if (block.timestamp < _redeem.endTime) revert Errors.VestingPeriodNotOver();

    balance.redeemingAmount = balance.redeemingAmount - _redeem.esSDYAmount;

    _finalizeRedeem(msg.sender, _redeem.esSDYAmount, _redeem.SDYAmount, _redeem.pairedSDYAmount);

    // remove redeem entry
    _deleteRedeemEntry(redeemIndex);
  }

  /**
    * @notice Cancels an ongoing redeem entry
    * @param redeemIndex redemption index
    * Can only be called by its owner
  */
  function cancelRedeem(
    uint256 redeemIndex
  ) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
    esSDYBalance storage balance = esSDYBalances[msg.sender];
    RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];

    // make redeeming esSDY and paired SDY available again
    balance.redeemingAmount = balance.redeemingAmount - (_redeem.esSDYAmount);
    IERC20(esSDY).safeTransfer(msg.sender, _redeem.esSDYAmount);
    IERC20(SDY).safeTransfer(msg.sender, _redeem.pairedSDYAmount);

    emit CancelRedeem(msg.sender, _redeem.esSDYAmount);

    // remove redeem entry
    _deleteRedeemEntry(redeemIndex);
  }

  /**
    * @notice Allocates caller's "amount" of available esSDY to "usageAddress" contract
    * args specific to usage contract must be passed into "usageData"
    * @param usageAddress address of plugin
    * @param amount amount of esSDY in 1e18
    * @param usageData for extra data params for specific plugins
  */
  function allocate(address usageAddress, uint256 amount, bytes calldata usageData) external nonReentrant {
    _allocate(msg.sender, usageAddress, amount);

    // allocates esSDY to usageContract
    IesSDYUsage(usageAddress).allocate(msg.sender, amount, usageData);
  }

  /**
    * @notice Allocates "amount" of available esSDY from "userAddress" to caller (ie usage contract)
    * @param userAddress address of user
    * @param amount amount of esSDY in 1e18
    * Caller must have an allocation approval for the required esSDY from "userAddress"
  */
  function allocateFromUsage(address userAddress, uint256 amount) external override nonReentrant {
    _allocate(userAddress, msg.sender, amount);
  }

  /**
    * @notice Deallocates caller's "amount" of available esSDY from "usageAddress" contract
    * args specific to usage contract must be passed into "usageData"
    * @param usageAddress address of plugin
    * @param amount amount of esSDY in 1e18
    * @param usageData for extra data params for specific plugins
  */
  function deallocate(address usageAddress, uint256 amount, bytes calldata usageData) external nonReentrant {
    _deallocate(msg.sender, usageAddress, amount);

    // deallocate esSDY into usageContract
    IesSDYUsage(usageAddress).deallocate(msg.sender, amount, usageData);
  }

  /**
    * @notice Deallocates "amount" of allocated esSDY belonging to "userAddress" from caller (ie usage contract)
    * Caller can only deallocate esSDY from itself
    * @param userAddress address of user
    * @param amount amount of esSDY in 1e18
  */
  function deallocateFromUsage(address userAddress, uint256 amount) external override nonReentrant {
    _deallocate(userAddress, msg.sender, amount);
  }

  /* ================== INTERNAL FUNCTIONS =================== */

  /**
    * @notice Convert caller's "amount" of SDY into esSDY to "to"
    * @param amount amount of SDY in 1e18
    * @param to address to send esSDY to
  */
  function _convert(uint256 amount, address to) internal {
    if (amount == 0) revert Errors.InvalidAmount();

    IERC20(SDY).safeTransferFrom(msg.sender, address(this), amount);

    // mint new esSDY
    IesSDY(esSDY).mint(to, amount);

    emit Convert(msg.sender, to, amount);

  }

  /**
    * @notice Finalizes the redeeming process for "userAddress" by transferring him "SDYAmount" and removing "esSDYAmount" from supply
    * Any vesting check should be ran before calling this
    * SDY excess is automatically burnt
    * @param userAddress address of user finalizing redemption
    * @param esSDYAmount amount of esSDY to remove in 1e18
    * @param SDYAmount amount of SDY to transfer in 1e18
    * @param pairedSDYAmount amount of paired SDY to transfer in 1e18

  */
  function _finalizeRedeem(
    address userAddress,
    uint256 esSDYAmount,
    uint256 SDYAmount,
    uint256 pairedSDYAmount
  ) internal {
    uint256 SDYExcess = esSDYAmount - SDYAmount;

    // sends due SDY tokens (vested + locked)
    IERC20(SDY).safeTransfer(userAddress, SDYAmount + pairedSDYAmount);

    // burns SDY excess if any
    ISDY(SDY).burn(SDYExcess);
    IesSDY(esSDY).burn(esSDYAmount);

    emit FinalizeRedeem(userAddress, esSDYAmount, SDYAmount, pairedSDYAmount);
  }

  /**
    * @notice Allocates "userAddress" user's "amount" of available esSDY to "usageAddress" contract
    * @param userAddress address of user
    * @param usageAddress address of plugin
    * @param amount amount of esSDY in 1e18
  */
  function _allocate(address userAddress, address usageAddress, uint256 amount) internal {
     if (amount == 0) revert Errors.InvalidAmount();

    esSDYBalance storage balance = esSDYBalances[userAddress];

    // checks if allocation request amount has been approved by userAddress to be allocated to this usageAddress
    uint256 approvedesSDY = usageApprovals[userAddress][usageAddress];
    if (approvedesSDY < amount) revert Errors.UnauthorisedAllocateAmount();

    // remove allocated amount from usage's approved amount
    usageApprovals[userAddress][usageAddress] = approvedesSDY - (amount);

    // update usage's allocatedAmount for userAddress
    usageAllocations[userAddress][usageAddress] = usageAllocations[userAddress][usageAddress] + (amount);

    // adjust user's esSDY balances
    balance.allocatedAmount = balance.allocatedAmount + (amount);
    IERC20(esSDY).safeTransferFrom(userAddress, address(this), amount);

    emit Allocate(userAddress, usageAddress, amount);
  }

  /**
    * @notice Deallocates "amount" of available esSDY to "usageAddress" contract
    * @param userAddress address of user
    * @param usageAddress address of plugin
    * @param amount amount of esSDY in 1e18
  */
  function _deallocate(address userAddress, address usageAddress, uint256 amount) internal {
    if (amount == 0) revert Errors.InvalidAmount();

    // check if there is enough allocated esSDY to this usage to deallocate
    uint256 allocatedAmount = usageAllocations[userAddress][usageAddress];
    if (allocatedAmount < amount) revert Errors.UnauthorisedAllocateAmount();

    // remove deallocated amount from usage's allocation
    usageAllocations[userAddress][usageAddress] = allocatedAmount - (amount);

    uint256 deallocationFeeAmount = amount * (usagesDeallocationFee[usageAddress]) / SAFE_MULTIPLIER;

    // adjust user's esSDY balances
    esSDYBalance storage balance = esSDYBalances[userAddress];
    balance.allocatedAmount = balance.allocatedAmount - (amount);
    IERC20(esSDY).safeTransfer(userAddress, amount - (deallocationFeeAmount));
    // burn corresponding SDY and esSDY
    ISDY(SDY).burn(deallocationFeeAmount);
    IesSDY(esSDY).burn(deallocationFeeAmount);

    emit Deallocate(userAddress, usageAddress, amount, deallocationFeeAmount);
  }

  /**
    * @notice Deletes redemption entry
    * @param _index index of redemption
  */
  function _deleteRedeemEntry(uint256 _index) internal {
    userRedeems[msg.sender][_index] = userRedeems[msg.sender][userRedeems[msg.sender].length - 1];
    userRedeems[msg.sender].pop();
  }

  /* ================= RESTRICTED FUNCTIONS ================== */

  /**
    * @notice Updates all redeem ratios and durations
    * @param newMinRedeemRatio min redemption ratio in 1e18
    * @param newMaxRedeemRatio max redemption ratio in 1e18
    * @param newMinRedeemDuration min redemption duration in timestamp
    * @param newMaxRedeemDuration max redemption duration in timestamp
  */
  function updateRedeemSettings(
    uint256 newMinRedeemRatio,
    uint256 newMaxRedeemRatio,
    uint256 newMinRedeemDuration,
    uint256 newMaxRedeemDuration
  ) external onlyOwner {
    if (newMinRedeemRatio > newMaxRedeemRatio || newMaxRedeemRatio > MAX_FIXED_RATIO)
      revert Errors.InvalidRatioValues();
    if (newMinRedeemDuration >= newMaxRedeemDuration)
      revert Errors.InvalidRedeemAmount();

    minRedeemRatio = newMinRedeemRatio;
    maxRedeemRatio = newMaxRedeemRatio;
    minRedeemDuration = newMinRedeemDuration;
    maxRedeemDuration = newMaxRedeemDuration;

    emit UpdateRedeemSettings(newMinRedeemRatio, newMaxRedeemRatio, newMinRedeemDuration, newMaxRedeemDuration);
  }

  /**
    * @notice Updates fee paid by users when deallocating from "usageAddress"
    * @param usageAddress address of plugin
    * @param fee deallocation fee in 1e18
  */
  function updateDeallocationFee(address usageAddress, uint256 fee) external onlyOwner {
    if (fee > MAX_DEALLOCATION_FEE) revert Errors.DeallocationFeeTooHigh();

    usagesDeallocationFee[usageAddress] = fee;

    emit UpdateDeallocationFee(usageAddress, fee);
  }

  /**
    * @notice Update whether pairing of SDY is required for redemption of esSDY
    * @param required Boolean of whether pairing of SDY is required
  */
  function updatePairingSDYRequired(bool required) external onlyOwner {
    pairingSDYRequired = required;

    emit UpdatePairingSDYRequired(required);
  }

  /**
    * @notice Pause contract not allowing for redemption
  */
  function pause() external onlyOwner {
    _pause();
  }

  /**
    * @notice Unpause contract allowing for redemption
  */
  function unpause() external onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Errors {

  /* ===================== AUTHORIZATION ===================== */

  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();
  error OnlyBorrowerAllowed();
  error OnlyYieldBoosterAllowed();
  error OnlyMinterAllowed();
  error OnlyTokenManagerAllowed();

  /* ======================== GENERAL ======================== */

  error ZeroAddressNotAllowed();
  error TokenDecimalsMustBeLessThan18();
  error ReceiverNotApproved();

  /* ========================= ORACLE ======================== */

  error NoTokenPriceFeedAvailable();
  error FrozenTokenPriceFeed();
  error BrokenTokenPriceFeed();
  error TokenPriceFeedMaxDelayMustBeGreaterOrEqualToZero();
  error TokenPriceFeedMaxDeviationMustBeGreaterOrEqualToZero();
  error InvalidTokenInLPPool();
  error InvalidReservesInLPPool();
  error OrderAmountOutMustBeGreaterThanZero();
  error SequencerDown();
  error GracePeriodNotOver();

  /* ======================== LENDING ======================== */

  error InsufficientBorrowAmount();
  error InsufficientRepayAmount();
  error BorrowerAlreadyApproved();
  error BorrowerAlreadyRevoked();
  error InsufficientLendingLiquidity();
  error InsufficientAssetsBalance();
  error InterestRateModelExceeded();

  /* ===================== VAULT GENERAL ===================== */

  error InvalidExecutionFeeAmount();
  error InsufficientExecutionFeeAmount();
  error InsufficientVaultSlippageAmount();
  error NotAllowedInCurrentVaultStatus();
  error AddressIsBlocked();

  /* ===================== VAULT DEPOSIT ===================== */

  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InsufficientDepositValue();
  error ExcessiveDepositValue();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error OnlyNonNativeDepositToken();
  error InvalidNativeTokenAddress();
  error DepositNotAllowedWhenEquityIsZero();
  error DepositAndExecutionFeeDoesNotMatchMsgValue();
  error DepositCancellationCallback();

  /* ===================== VAULT WITHDRAW ==================== */

  error EmptyWithdrawAmount();
  error InvalidWithdrawToken();
  error InsufficientWithdrawAmount();
  error ExcessiveWithdrawValue();
  error InsufficientWithdrawBalance();
  error InvalidEquityAfterWithdraw();
  error InsufficientAssetsReceived();
  error WithdrawNotAllowedInSameDepositBlock();
  error WithdrawalCancellationCallback();
  error NoAssetsToEmergencyRefund();

  /* ==================== VAULT REBALANCE ==================== */

  error InvalidDebtRatio();
  error InvalidDelta();
  error InsufficientLPTokensMinted();
  error InsufficientLPTokensBurned();
  error InvalidRebalancePreConditions();
  error InvalidRebalanceParameters();

  /* ==================== VAULT CALLBACKS ==================== */

  error InvalidCallbackHandler();

  /* ========================= FARMS ========================== */

  error FarmDoesNotExist();
  error FarmNotActive();
  error EndTimeMustBeGreaterThanCurrentTime();
  error MaxMultiplierMustBeGreaterThan1x();
  error InsufficientRewardsBalance();
  error InvalidRate();
  error InvalidEsSDYSplit();

  /* ========================= TOKENS ========================= */

  error RedeemEntryDoesNotExist();
  error InvalidRedeemAmount();
  error InvalidRedeemDuration();
  error VestingPeriodNotOver();
  error InvalidAmount();
  error UnauthorisedAllocateAmount();
  error InvalidRatioValues();
  error DeallocationFeeTooHigh();
  error TransferNotAllowed();
  error InvalidUpdateTransferWhitelistAddress();

  /* ========================= BRIDGE ========================= */

  error OnlyNetworkAllowed();
  error InvalidFeeToken();
  error InsufficientFeeTokenBalance();

  /* ========================= CLAIMS ========================= */

  error AddressAlreadyClaimed();
  error MerkleVerificationFailed();

  /* ========================= DISITRBUTOR ========================= */

  error InvalidNumberOfVaults();
}