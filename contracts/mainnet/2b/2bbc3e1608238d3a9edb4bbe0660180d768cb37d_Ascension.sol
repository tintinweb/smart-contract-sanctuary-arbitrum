/**
 *Submitted for verification at Arbiscan.io on 2024-02-10
*/

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;




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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: smartcontracts/ReleaseCandidates/IRandomizer.sol


pragma solidity ^0.8.0;

interface IRandomizer {

    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns(uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns(bool);
}
// File: smartcontracts/NFT/NFTContracts/SoulStone/ISoulStone.sol


pragma solidity ^0.8.21;


interface ISoulStone {
    /**
     * @dev Mints the next Soul Stone
    */
    function mintNext(address to) external;
    /**
     * @dev returns the actual bonus value for a Soul Stone
    */    
    function getBonusValueHarvest(address _wallet) external view returns (uint256);
    /**
     * @dev returns the actual bonus value for a Soul Stone
    */    
    function getBonusValueSkirmish(address _wallet) external view returns (uint256);
    /**
     * @dev checks a Wallet for a Soul Stone
    */    
    function hasSoulStone(address _wallet) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function soulStoneEngravings(uint256 ID) external view returns( uint256, uint256, uint256, bool, bool, bool);
    
    function ownerOf(uint256 ID) external view returns (address);
}   

// File: smartcontracts/ReleaseCandidates/Ascension.sol


pragma solidity ^0.8.22;









pragma solidity ^0.8.23;

contract Ascension is Ownable(msg.sender), Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public token;
    IRandomizer public randomizer;
    ISoulStone public SoulStone;

    uint256 public burnPercent;
    uint256 public blessingSharePercent;
    uint256 public minimumAmount;
    uint256 public nrOfAllTickets;
    uint256 public maxEntries;

    uint256 public totalAmount;
    uint256 public blessingAmountActual;
    uint256 public blessingAmountNext;
    uint256 public blessingWinChance;
    uint256 public blessingDistribution;

    uint256 public unlockTime;
    uint256 public rampupDuration;

    uint256 lastRequest;
    uint256 lastBlessingRequest;

    struct entry{
        address _address;
        uint256 _start;
        uint256 _end;
        uint256 _balance;
    }

    struct lastWinner {
        address winner;
        uint256 reward;
        uint256 balance;
        uint256 chance;
        uint256 blessed;
        uint256 blessedWinChance;
    }

    struct blessedOne {
        address winner;
        uint256 reward;
        uint256 chance;
    }

    lastWinner[] public lastWinners;
    blessedOne[] public blessed;
    entry[]public entries;

    event TokensDeposited(address indexed account, uint256 amount);
    event WinnerDrawn(address indexed account, uint256 amount,uint256 totalAmount, uint256 tickets, uint256 ticketDrawn);
    event BlessedDrawn(address indexed account, uint256 winChance, uint256 blessedAmount);

    constructor() {
        token = IERC20(0x6C35Ec8df04d1417D3B02f2476c02E65b6D3B94C);
        burnPercent = 5000;                 // 5000 initial
        blessingSharePercent = 15000;       // 15000 initial
        blessingDistribution = 30000;       // 30000 initial - share for actual (30%) vs upcomming blessing (70%)
        minimumAmount = 50000 * 10**18;     // 10000 initial
        blessingWinChance = 150;            // Base Chance 0.15% for everyone
        rampupDuration = 240;               // Time until raffle can be started in minutes
        maxEntries = 100;                   // Maximum Number of users per Round
        randomizer = IRandomizer(0x8e79c8607a28fe1EC3527991C89F1d9E36D1bAd9);
        SoulStone = ISoulStone(0xd93548037c8E77b4E5a070994f3dEA709c9001F9);

    }

    function depositSoulAndStart(uint256 amount) public nonReentrant whenNotPaused{
        require(amount >= minimumAmount, "Amount must be greater than minimum Amount for this Ascension!");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient Soul balance");
        require(!findUser(msg.sender),"Keeper has already entered the current Ascension!");
        require(entries.length >= 1, "You shouldn't play around with yourself!");

        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 refundAmount = amount % minimumAmount;
        if(refundAmount > 0 ){token.safeTransfer(msg.sender, refundAmount); amount-=refundAmount;}

        totalAmount += amount;

        uint256 nrOftickets = amount / minimumAmount;
       
        entries.push(entry(msg.sender,nrOfAllTickets, nrOfAllTickets + nrOftickets - 1,amount));

        nrOfAllTickets += nrOftickets;

        emit TokensDeposited(msg.sender, amount);
        startAscension();
      
    }
    function depositSoul(uint256 amount) public nonReentrant whenNotPaused{
        require(amount >= minimumAmount, "Amount must be greater than minimum Amount for this Ascension!");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient Soul balance");
        require(!findUser(msg.sender),"Keeper has already entered the current Ascension!");

        if(entries.length == 0){requestNumber(); unlockTime = block.timestamp + rampupDuration * 1 minutes;}

        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 refundAmount = amount % minimumAmount;
        if(refundAmount > 0 ){token.safeTransfer(msg.sender, refundAmount); amount-=refundAmount;}

        totalAmount += amount;

        uint256 nrOftickets = amount / minimumAmount;

        entries.push(entry(msg.sender,nrOfAllTickets, nrOfAllTickets + nrOftickets - 1,amount));

        nrOfAllTickets += nrOftickets;
        
        emit TokensDeposited(msg.sender, amount);

        if(entries.length >= maxEntries){startAscension();}
      
    }

    function drawWinner(uint256 _randomNumber) internal view returns(address winner){

        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i]._start <= _randomNumber && entries[i]._end >= _randomNumber){
                return entries[i]._address;
            }
        }       
    }

    function startAscension() internal {
        require(block.timestamp >= unlockTime, "Ascension is still in preparation!");

        uint256 randomNumber = drawNumber(nrOfAllTickets); 
       
        address winner = drawWinner(randomNumber);
        uint256 blessingShare = ((totalAmount - getUserBalance(winner)) * blessingSharePercent) / 100000;
        uint256 blessingShareActual = blessingShare * blessingDistribution / 100000;

        uint256 burnAmount = ((totalAmount - getUserBalance(winner)) * burnPercent) / 100000;
        uint256 winnerAmount = totalAmount - burnAmount - blessingShare;
 
        blessingAmountActual += blessingShareActual;
        blessingAmountNext += (blessingShare - blessingShareActual);

        // Blessing Draw 
        uint256 winChance = getBlessingSumChance(winner);
        uint256 gotBlessed;


        if (drawBlessing(winChance)){
            gotBlessed = blessingAmountActual;
            winnerAmount += blessingAmountActual;

            blessingAmountActual = blessingAmountNext;
            blessingAmountNext = 0;

            emit BlessedDrawn(winner, winChance, gotBlessed);
            blessed.push(blessedOne(winner, gotBlessed,winChance));
        }

        token.safeTransfer(winner, winnerAmount);
        token.safeTransfer(address(0), burnAmount);
        
        // updates and events
        emit WinnerDrawn(winner,winnerAmount,totalAmount,nrOfAllTickets,randomNumber);
        lastWinners.push(lastWinner(winner,winnerAmount,getUserBalance(winner),getChanceForWallet(winner),gotBlessed,winChance));

        // clean up

        totalAmount = 0;
        nrOfAllTickets = 0;
        delete entries;

    }
    function addToBlessing(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount can not be 0!");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient Soul balance");

        token.safeTransferFrom(msg.sender, address(this), _amount);
        blessingAmountActual += _amount;
    }

    function getBlessingSumChance(address _wallet) public view returns(uint256 sumChance){
            sumChance = blessingWinChance;
            if(SoulStone.hasSoulStone(_wallet)){
                sumChance = sumChance * (100 + SoulStone.getBonusValueHarvest(_wallet)) / 100;
            }
            return sumChance;
    }

    function getChanceForWallet(address _wallet) public view returns (uint256 chance){
        chance = 0;

        if (totalAmount > 0){
            chance = getUserBalance(_wallet) * 100000 / totalAmount;
        }
        
        return chance;
    }

    function getCurrentNrOfEntries() public view returns (uint256){return entries.length;}
    
    function sendRemainingTokens() public onlyOwner {
        uint256 remainingTokens = token.balanceOf(address(this));
        require(remainingTokens > 0, "Amount must be greater than zero");
        token.safeTransfer(msg.sender, remainingTokens);
        
        blessingAmountActual = 0;
        blessingAmountNext = 0;

        totalAmount = 0;
        nrOfAllTickets = 0;
        delete entries;

    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        token = IERC20(_tokenAddress);
    }
    function setRampupDuration(uint256 _newRampupDuration) public onlyOwner {
        rampupDuration = _newRampupDuration;
    }

    function setBlessingBaseChance(uint256 _newBaseChance)public onlyOwner{
        require(_newBaseChance <= 100000 && _newBaseChance >= 0,"Chance exeeds the bounds!");

        blessingWinChance = _newBaseChance;
    }

    function setBlessingDistribution(uint256 _newBlessingDistribution)public onlyOwner{
        require(_newBlessingDistribution <= 100000 && _newBlessingDistribution >= 0,"Share exeeds the bounds!");

        blessingDistribution = _newBlessingDistribution;
    }

    function setBlessingSharePercent(uint256 _blessingSharePercent) public onlyOwner {
        require(_blessingSharePercent <= (100000 - burnPercent) && _blessingSharePercent >= 0,"Share exeeds the bounds!");

        blessingSharePercent = _blessingSharePercent;
    }

    function setBurnPercent(uint256 _burnPercent) public onlyOwner {
        require(_burnPercent <= (100000 - blessingSharePercent) && _burnPercent >= 0,"Burn exeeds the bounds!");

        burnPercent = _burnPercent;
    }

    function setMinimumAmount(uint256 _minimumAmount) public onlyOwner {
        require(_minimumAmount > 0,"Amount has to be greater than 0!");

        minimumAmount = _minimumAmount;
    }

    function setMaxEntries(uint256 _maxEntries) public onlyOwner {
        require(_maxEntries > 0,"Maximum Player has to be greater than 0!");

        maxEntries = _maxEntries;
    }
    
    function transferOwnership(address _newOwner) public override onlyOwner {
        _transferOwnership(_newOwner);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function getTopEntries(uint256 numberOfTopEntries) public view returns (entry[] memory) {
        if(numberOfTopEntries >= entries.length){numberOfTopEntries = entries.length;}
        entry[] memory returnEntries = new entry[](numberOfTopEntries);

        // Sort users by score
        entry[] memory sortedEntries = sortEntriesByActualAmount();

        for (uint256 i = 0; i < numberOfTopEntries; i++) {
            entry memory temp = sortedEntries[i];
            returnEntries[i]._address = temp._address;
            returnEntries[i]._balance = temp._balance;
        }
        return (returnEntries);
    }

    function sortEntriesByActualAmount() internal view returns (entry[] memory) {
        entry[] memory unSortedEntries = entries;

        for (uint256 i = 0; i < unSortedEntries.length; i++) {
            for (uint256 j = i + 1; j < unSortedEntries.length; j++) {
                if (unSortedEntries[i]._balance < unSortedEntries[j]._balance) {
                    entry memory temp = unSortedEntries[i];
                    unSortedEntries[i] = unSortedEntries[j];
                    unSortedEntries[j] = temp;
                }
            }
        }

        return unSortedEntries;
    }
    function findUser(address _userAddress) internal view returns (bool) {
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i]._address == _userAddress) {
                return true;
            }
        }
        return false; // Not found
    }
    function getUserBalance(address _userAddress) public view returns (uint256) {
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i]._address == _userAddress) {
                return entries[i]._balance;
            }
        }
        return 0; // Not found
    }

    function getWinners(uint256 numberOfLastWinner) public view returns (lastWinner[] memory) {

        if(numberOfLastWinner >= lastWinners.length){numberOfLastWinner = lastWinners.length;}
        lastWinner[] memory returnLastWinner = new lastWinner[](numberOfLastWinner);

        for (uint256 i = 0; i < numberOfLastWinner; i++) {
            returnLastWinner[i] = lastWinners[lastWinners.length - 1 - i];
        }

        return (returnLastWinner);
    }

    function getLastWinner() public view returns (lastWinner memory returnLastWinner){
        if (lastWinners.length > 0){returnLastWinner = lastWinners[lastWinners.length - 1];}
        return (returnLastWinner);
    }

    function getBlessedWinners(uint256 numberOfBlessedOnes) public view returns (blessedOne[] memory){
        if(numberOfBlessedOnes >= blessed.length){numberOfBlessedOnes = blessed.length;}
        blessedOne[] memory returnBlessed = new blessedOne[](numberOfBlessedOnes);

        for (uint256 i = 0; i < numberOfBlessedOnes; i++) {
            returnBlessed[i] = blessed[blessed.length - 1 - i];
        }

        return (returnBlessed);    
        
    }

    /**
     * @dev Draws a "random" number including 0
     */
    function drawNumber(uint256 range) internal view returns (uint256) {
        require(randomizer.isRandomReady(lastRequest),"Randomizer not ready yet!");
        return (randomizer.revealRandomNumber(lastRequest) % range);
    }

    function drawBlessing(uint256 _chance) internal view returns (bool) {
        require(randomizer.isRandomReady(lastBlessingRequest),"Randomizer not ready yet!");
        if (((randomizer.revealRandomNumber(lastBlessingRequest) % 100000) + 1) <= _chance) {
            return true;
        }
        return false;
    }

    function requestNumber() internal {
        lastRequest = randomizer.requestRandomNumber();
        lastBlessingRequest = randomizer.requestRandomNumber();
    } 

    }