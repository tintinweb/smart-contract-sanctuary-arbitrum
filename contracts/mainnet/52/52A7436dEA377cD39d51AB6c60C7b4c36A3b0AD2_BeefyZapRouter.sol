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

pragma solidity 0.8.19;

import { IBeefyZapRouter } from "./IBeefyZapRouter.sol";

/**
 * @title Token manager interface
 * @author kexley, Beefy
 * @notice Interface for the token manager
 */
interface IBeefyTokenManager {
    /**
     * @notice Pull tokens from a user
     * @param _user Address of user to transfer tokens from
     * @param _inputs Addresses and amounts of tokens to transfer
     */
    function pullTokens(address _user, IBeefyZapRouter.Input[] calldata _inputs) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IPermit2 } from "./IPermit2.sol";

/**
 * @title Zap router interface
 * @author kexley, Beefy
 * @notice Interface for zap router that contains the structs for orders and routes
 */
interface IBeefyZapRouter {
    /**
     * @dev Input token and amount used in a step of the zap
     * @param token Address of token
     * @param amount Amount of token
     */
    struct Input {
        address token;
        uint256 amount;
    }

    /**
     * @dev Output token and amount from the end of the zap
     * @param token Address of token
     * @param minOutputAmount Minimum amount of token received
     */
    struct Output {
        address token;
        uint256 minOutputAmount;
    }

    /**
     * @dev External call at the end of zap
     * @param target Target address to be called
     * @param value Ether value of the call
     * @param data Payload to call target address with
     */
    struct Relay {
        address target;
        uint256 value;
        bytes data;
    }

    /**
     * @dev Token relevant to the current step of the route
     * @param token Address of token
     * @param index Location in the data that the balance of the token should be inserted
     */
    struct StepToken {
        address token;
        int32 index;
    }

    /**
     * @dev Step in a route
     * @param target Target address to be called
     * @param value Ether value to call the target address with
     * @param data Payload to call target address with
     * @param tokens Tokens relevant to the step that require approvals or their balances inserted
     * into the data
     */
    struct Step {
        address target;
        uint256 value;
        bytes data;
        StepToken[] tokens;
    }

    /**
     * @dev Order created by the user
     * @param inputs Tokens and amounts to be pulled from the user
     * @param outputs Tokens and minimums to be sent to recipient
     * @param relay External call to make after zap is completed
     * @param user Source of input tokens
     * @param recipient Destination of output tokens
     */
    struct Order {
        Input[] inputs;
        Output[] outputs;
        Relay relay;
        address user;
        address recipient;
    }

    /**
     * @notice Execute an order directly
     * @param _order Order created by the user
     * @param _route Route supplied by user
     */
    function executeOrder(Order calldata _order, Step[] calldata _route) external payable;

    /**
     * @notice Execute an order on behalf of a user
     * @param _permit Token permits from Permit2 with the order as witness data signed by user
     * @param _order Order created by user that was signed in the permit
     * @param _signature Signature from user of combined permit and order
     * @param _route Route supplied by user or third-party
     */
    function executeOrder(
        IPermit2.PermitBatchTransferFrom calldata _permit,
        Order calldata _order,
        bytes calldata _signature,
        Step[] calldata _route
    ) external;

    /**
     * @notice Pause the contract from carrying out any more zaps
     * @dev Only owner can pause
     */
    function pause() external;

    /**
     * @notice Unpause the contract to allow new zaps
     * @dev Only owner can unpause
     */
    function unpause() external;

    /**
     * @notice Permit2 immutable address
     */
    function permit2() external view returns (address);

    /**
     * @notice Token manager immutable address
     */
    function tokenManager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title Permit2 interface
 * @author kexley, Beefy
 * @notice Interface for Permit2
 */
interface IPermit2 {
    /**
     * @dev Token and amount in a permit message
     * @param token Address of token to transfer
     * @param amount Amount of token to transfer
     */
    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    /**
     * @dev Batched permit with the unique nonce and deadline
     * @param permitted Tokens and corresponding amounts permitted for a transfer
     * @param nonce Unique value for every token owner's signature to prevent signature replays
     * @param deadline Deadline on the permit signature
     */
    struct PermitBatchTransferFrom {
        TokenPermissions[] permitted;
        uint256 nonce;
        uint256 deadline;
    }

    /**
     * @dev Transfer details for permitBatchTransferFrom
     * @param to Recipient of tokens
     * @param requestedAmount Amount to transfer
     */
    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    /**
     * @notice Consume a permit2 message and transfer tokens
     * @param permit Batched permit
     * @param transferDetails Recipient and amount of tokens to transfer
     * @param owner Source of tokens
     * @param witness Verified order data that was witnessed in the permit2 signature
     * @param witnessTypeString Order function string used to create EIP-712 type string
     * @param signature Signature from user
     */
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /**
     * @notice Domain separator to differentiate the chain a permit exists on
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IBeefyZapRouter } from "../interfaces/IBeefyZapRouter.sol";
import { ZapErrors } from "./ZapErrors.sol";

/**
 * @title Token manager
 * @author kexley, Beefy
 * @notice Token manager handles the token approvals for the zap router
 * @dev Users should approve this contract instead of the zap router to handle the input ERC20 tokens
 */
contract BeefyTokenManager is ZapErrors {
    using SafeERC20 for IERC20;

    /**
     * @notice Zap router immutable address
     */
    address public immutable zap;

    /**
     * @dev This contract is created in the constructor of the zap router
     */
    constructor() {
        zap = msg.sender;
    }

    /**
     * @notice Pulls tokens from a user and transfers them directly to the zap router
     * @dev Only the token owner can call this function indirectly via the zap router
     * @param _user Address to pull tokens from
     * @param _inputs Token addresses and amounts to pull
     */
    function pullTokens(address _user, IBeefyZapRouter.Input[] calldata _inputs) external {
        if (msg.sender != zap) revert CallerNotZap(msg.sender);
        uint256 inputLength = _inputs.length;
        for (uint256 i; i < inputLength;) {
            IBeefyZapRouter.Input calldata input = _inputs[i];
            unchecked {
                ++i;
            }

            if (input.token == address(0)) continue;
            IERC20(input.token).safeTransferFrom(_user, msg.sender, input.amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IBeefyTokenManager } from "../interfaces/IBeefyTokenManager.sol";
import { IBeefyZapRouter } from "../interfaces/IBeefyZapRouter.sol";
import { IPermit2 } from "../interfaces/IPermit2.sol";
import { BeefyTokenManager} from "./BeefyTokenManager.sol";
import { ZapErrors } from "./ZapErrors.sol";

/**
 * @title Zap router for Beefy vaults
 * @author kexley, Beefy
 * @notice Adaptable router for zapping tokens to and from Beefy vaults
 * @dev Router that allows arbitary calls to external contracts. Users can zap directly or sign 
 * using Permit2 to allow a relayer to execute zaps on their behalf. Do not directly approve this
 * contract for spending your tokens, approve the TokenManager instead
 */
contract BeefyZapRouter is IBeefyZapRouter, ZapErrors, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev Witness string used in signing an order
     */
    string private constant ORDER_STRING =
        "Order order)Order(Input[] inputs,Output[] outputs,Relay relay,address user,address recipient)Input(address token,uint256 amount)Output(address token,uint256 minOutputAmount)Relay(address target,uint256 value,bytes data)TokenPermissions(address token,uint256 amount)";
    /**
     * @dev Witness typehash used in signing an order
     */
    bytes32 private constant ORDER_TYPEHASH = 
        keccak256("Order(Input[] inputs,Output[] outputs,Relay relay,address user,address recipient)Input(address token,uint256 amount)Output(address token,uint256 minOutputAmount)Relay(address target,uint256 value,bytes data)");
    /**
     * @notice Permit2 immutable address
     */
    address public immutable permit2;
    /**
     * @notice Token manager immutable address
     */
    address public immutable tokenManager;

    /**
     * @notice Token and amount sent to the recipient at end of a zap
     * @param token Address of the token sent to recipient
     * @param amount Amount of the token sent to the recipient
     */
    event TokenReturned(address indexed token, uint256 amount);
    /**
     * @notice External relay call at end of zap
     * @param target Address of the target
     * @param value Ether value of the call
     * @param data Payload of the external call
     */
    event RelayData(address indexed target, uint256 value, bytes data);
    /**
     * @notice Completed order
     * @param order Order that has been fulfilled
     * @param caller Address of the order's executor
     * @param recipient Address of the order's recipient
     */
    event FulfilledOrder(Order indexed order, address indexed caller, address indexed recipient);

    /**
     * @dev Initialize permit2 address and create an implementation of the token manager
     * @param _permit2 Address for the permit2 contract
     */
    constructor(address _permit2) {
        permit2 = _permit2;
        tokenManager = address(new BeefyTokenManager());
    }

    /**
     * @notice Execute an order directly
     * @dev The user executes their own order directly. User must have already approved the token
     * manager to move the tokens
     * @param _order Order containing how many tokens to pull and the slippage amounts on outputs
     * @param _route Route containing the steps to reach the output
     */
    function executeOrder(Order calldata _order, Step[] calldata _route) external payable nonReentrant whenNotPaused {
        if (msg.sender != _order.user) revert InvalidCaller(_order.user, msg.sender);

        IBeefyTokenManager(tokenManager).pullTokens(_order.user, _order.inputs);
        _executeOrder(_order, _route);
    }

    /**
     * @notice Execute an order using a signature from the input token owner
     * @dev Execute an order indirectly by passing a signed permit from Permit2 that contains the
     * order as witness data. The user who owns the tokens must have already approved Permit2.
     * Route is supplied at this stage as slippages and amounts are already set in the signed order
     * @param _permit Struct of tokens that have been permitted and the nonce/deadline
     * @param _order Order that details the input/output tokens and amounts
     * @param _signature Resulting string from signing the permit and order data
     * @param _route Actual steps that will transform input tokens to output tokens
     */
    function executeOrder(
        IPermit2.PermitBatchTransferFrom calldata _permit,
        Order calldata _order,
        bytes calldata _signature,
        Step[] calldata _route
    ) external nonReentrant whenNotPaused {
        IPermit2(permit2).permitWitnessTransferFrom(
            _permit,
            _getTransferDetails(_order.inputs),
            _order.user,
            keccak256(abi.encode(ORDER_TYPEHASH, _order)),
            ORDER_STRING,
            _signature
        );

        _executeOrder(_order, _route);
    }

    /**
     * @dev Executes a valid order by executing the steps on the route, validating the output
     * amounts and then sending them to the recipient. A final external call is made to relay
     * data in the order to chain together calls
     * @param _order Order struct with details of inputs and outputs
     * @param _route Actual steps to transform inputs to outputs
     */
    function _executeOrder(Order calldata _order, Step[] calldata _route) private {
        _executeSteps(_route);
        _returnAssets(_order.outputs, _order.recipient, _order.relay.value);
        _executeRelay(_order.relay);

        emit FulfilledOrder(_order, msg.sender, _order.recipient);
    }

    /**
     * @dev Executes various steps to achieve the order outputs by making external calls. Balance
     * data is dynamically inserted into payloads to always move the full balances of this contract
     * @param _route Array of the steps the contract will execute
     */
    function _executeSteps(Step[] calldata _route) private {
        uint256 routeLength = _route.length;
        for (uint256 i; i < routeLength;) {
            Step calldata step = _route[i];
            (
                address stepTarget,
                uint256 value,
                bytes memory callData,
                bytes calldata stepData,
                StepToken[] calldata stepTokens
            ) = (step.target, step.value, step.data, step.data, step.tokens);

            if (stepTarget == permit2 || stepTarget == tokenManager) revert TargetingInvalidContract(stepTarget);

            uint256 balance;

            uint256 stepTokensLength = stepTokens.length;
            for (uint256 j; j < stepTokensLength;) {
                StepToken calldata stepToken = stepTokens[j];
                (address stepTokenAddress, int32 stepTokenIndex) = (stepToken.token, stepToken.index);

                if (stepTokenAddress == address(0)) {
                    value = address(this).balance;
                } else {
                    balance = IERC20(stepTokenAddress).balanceOf(address(this));
                    _approveToken(stepTokenAddress, stepTarget, balance);

                    if (stepTokenIndex >= 0) {
                        uint256 idx = uint256(int256(stepTokenIndex));
                        callData = bytes.concat(stepData[:idx], abi.encode(balance), stepData[idx + 32:]);
                    }
                }

                unchecked {
                    ++j;
                }
            }

            (bool success, bytes memory result) = stepTarget.call{value: value}(callData);
            if (!success) _propagateError(stepTarget, value, callData, result);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Approve a token to be spent by an address if not already approved enough
     * @param _token Address of token to be approved
     * @param _spender Address of spender that will be allowed to move tokens
     * @param _amount Number of tokens that are going to be spent
     */
    function _approveToken(address _token, address _spender, uint256 _amount) private {
        if (IERC20(_token).allowance(address(this), _spender) < _amount) {
            IERC20(_token).forceApprove(_spender, type(uint256).max);
        }
    }

    /**
     * @dev Bubble up an error message from an underlying contract
     * @param _target Address that the call was sent to
     * @param _value Amount of ether sent with the call
     * @param _data Payload data of the call
     * @param _returnedData Returned data from the call
     */
    function _propagateError(address _target, uint256 _value, bytes memory _data, bytes memory _returnedData)
        private
        pure
    {
        if (_returnedData.length == 0) revert CallFailed(_target, _value, _data);
        assembly {
            revert(add(32, _returnedData), mload(_returnedData))
        }
    }

    /**
     * @dev Return the outputs to the recipient address
     * @param _outputs Token addresses and amounts to validate against to ensure no major slippage
     * @param _recipient Address of the receiver of the outputs
     * @param _relayValue Unwrapped native amount that is reserved for calling the relay address
     */
    function _returnAssets(Output[] calldata _outputs, address _recipient, uint256 _relayValue) private {
        uint256 balance;
        uint256 outputsLength = _outputs.length;
        for (uint256 i; i < outputsLength;) {
            Output calldata output = _outputs[i];
            (address outputToken, uint256 outputMinAmount) = (output.token, output.minOutputAmount);
            if (outputToken == address(0)) {
                balance = address(this).balance;
                if (balance < outputMinAmount) {
                    revert Slippage(outputToken, outputMinAmount, balance);
                }
                if (balance > _relayValue) {
                    balance -= _relayValue;
                    (bool success,) = _recipient.call{value: balance}("");
                    if (!success) revert EtherTransferFailed(_recipient);
                }
            } else {
                balance = IERC20(outputToken).balanceOf(address(this));
                if (balance < outputMinAmount) {
                    revert Slippage(outputToken, outputMinAmount, balance);
                } else if (balance > 0) {
                    IERC20(outputToken).safeTransfer(_recipient, balance);
                }
            }

            emit TokenReturned(outputToken, balance);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Call an external contract at the end of a zap with a payload signed in the order
     * @param _relay Target address and payload data in a struct
     */
    function _executeRelay(Relay calldata _relay) private {
        (address relayTarget, uint256 relayValue, bytes calldata relaydata) 
            = (_relay.target, _relay.value, _relay.data);
        if (relayTarget != address(0)) {
            if (relayTarget == permit2 || relayTarget == tokenManager) {
                revert TargetingInvalidContract(relayTarget);
            }

            if (address(this).balance < relayValue) {
                revert InsufficientRelayValue(address(this).balance, relayValue);
            }

            (bool success, bytes memory result) = relayTarget.call{value: relayValue}(relaydata);
            if (!success) _propagateError(relayTarget, relayValue, relaydata, result);

            emit RelayData(relayTarget, relayValue, relaydata);
        }
    }

    /**
     * @dev Parse the token transfer details from the order so it can be supplied to the Permit2
     * transfer from request
     * @param _inputs Token addresses and amounts in a struct
     * @return transferDetails Transformed data
     */
    function _getTransferDetails(Input[] calldata _inputs)
        private
        view
        returns (IPermit2.SignatureTransferDetails[] memory)
    {
        uint256 inputsLength = _inputs.length;
        IPermit2.SignatureTransferDetails[] memory transferDetails =
            new IPermit2.SignatureTransferDetails[](inputsLength);
        
        for (uint256 i; i < inputsLength;) {
            transferDetails[i] =
                IPermit2.SignatureTransferDetails({to: address(this), requestedAmount: _inputs[i].amount});

            unchecked {
                ++i;
            }
        }
        return transferDetails;
    }

    /**
     * @notice Pause the contract from carrying out any more zaps
     * @dev Only owner can pause
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract to allow new zaps
     * @dev Only owner can unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allow receiving of native tokens
     */
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title Zap errors
 * @author kexley, Beefy
 * @notice Custom errors for the zap router
 */
contract ZapErrors {
    error InvalidCaller(address owner, address caller);
    error TargetingInvalidContract(address target);
    error CallFailed(address target, uint256 value, bytes callData);
    error Slippage(address token, uint256 minAmountOut, uint256 balance);
    error EtherTransferFailed(address recipient);
    error CallerNotZap(address caller);
    error InsufficientRelayValue(uint256 balance, uint256 relayValue);
}