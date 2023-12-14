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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

interface ISparkSwapRouter01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address caller
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        address caller
    ) external view returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path,
        address caller
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path,
        address caller
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "./ISparkSwapRouter01.sol";

interface ISparkSwapRouter02 is ISparkSwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;


interface IUniswapV2Pair {

    function MINIMUM_LIQUIDITY() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function MAX_PROTOCOL_SHARE() external view returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint256 blockTimestampLast);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

interface IWrapped {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/ISparkSwapRouter02.sol";
import "./interfaces/IWrapped.sol";
// import "hardhat/console.sol";

contract SparklerEvo is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable depositToken;
    IERC20 public rewardToken;

    struct Stake {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        uint256 claimed;
        uint256 shares;
        uint256 accPoints;
    }
    struct Action {
        ActionType actionType;
        address target;
        address[] tokens;
        uint256 slippageBp;
        bytes otherData;
    }
    enum ActionType {
        OTHER,
        SWAP,
        LP_REMOVE,
        LP_ADD,
        BURN
    }

    mapping(address => mapping(uint256 => Stake)) public stakes;
    mapping(address => uint256) public stakeCounts;
    address[] public stakeAddresses;
    mapping(uint256 => Action) public actions;
    uint256 public numActions;

    uint256 public total_shares;
    uint256 public total_balance;
    uint256 public total_claimed;
    uint256 public total_rewards;
    uint256 public totalAccPoints;
    uint256 public minStake;
    uint256 public maxStake;
    uint256 public minLockTime;
    uint256 public maxLockTime;
    uint256 public lockTimeBonusDenominator = 912.5 days;
    uint256 public shareMultiplierBp = 10000 * 10000;
    uint256 public constant MULTIPLIER = 10e18;
    address public feeAddress;
    uint256 public feeBp;
    uint256 public fee_rewards;
    uint256 public lastRewardTime;
    uint256 public rewardsPerSecond;
    address public wplsAddress;
    uint256 public minSwapAndLiquifyWPLS;
    uint256 public liquifySwapFeeMultiplier;
    bool public swapAndLiquifyBiDirectional;

    address public sparkSwapRouter;

    constructor(IERC20 _depositToken, IERC20 _rewardToken, address _wplsAddress, uint256 _minSwapAndLiquifyWPLS, uint256 _liquifySwapFeeMultiplier) {
        require(address(_depositToken) != address(_rewardToken), "Cannot reward deposit token");
        depositToken = _depositToken;
        rewardToken = _rewardToken;
        wplsAddress = _wplsAddress;
        minSwapAndLiquifyWPLS = _minSwapAndLiquifyWPLS;
        liquifySwapFeeMultiplier = _liquifySwapFeeMultiplier;
        swapAndLiquifyBiDirectional = true;
        minStake = 0.1 ether;
        maxStake = 1e18 ether;
        minLockTime = 60 seconds;
        maxLockTime = 5475 days;
        lastRewardTime = block.timestamp;

        feeBp = 50;
        feeAddress = _msgSender();
    }

    receive() external payable {}

    function setPaused(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function resetRewardRateTracker() external onlyOwner {
        lastRewardTime = block.timestamp;
        rewardsPerSecond = 0;
    }

    function setFeeSettings(address _feeAddress, uint256 _feeBp) external onlyOwner {
        feeAddress = _feeAddress;
        feeBp = _feeBp;
    }

    function setSwapAndLiquifyParams(
        bool _swapAndLiquifyBiDirectional,
        address _wplsAddress,
        uint256 _minSwapAndLiquifyWPLS,
        uint256 _liquifySwapFeeMultiplier
    ) external onlyOwner {
        swapAndLiquifyBiDirectional = _swapAndLiquifyBiDirectional;
        wplsAddress = _wplsAddress;
        minSwapAndLiquifyWPLS = _minSwapAndLiquifyWPLS;
        liquifySwapFeeMultiplier = _liquifySwapFeeMultiplier;
    }

    function setShareMultiplierBp(uint256 _shareMultiplierBp) external onlyOwner {
        shareMultiplierBp = _shareMultiplierBp;
    }

    function claimFeeRewards() external {
        uint256 _fee_rewards = fee_rewards;
        if (_fee_rewards > 0) {
            fee_rewards = 0;
            rewardToken.safeTransfer(feeAddress, _fee_rewards);
        }
    }

    function withdraw(IERC20 token, address to, uint256 amnt) external onlyOwner {
        if (address(token) == address(0)) {
            payable(to).transfer(amnt);
        } else {
            token.safeTransfer(to, amnt);
        }
    }

    function getStakesMany(address a, uint256 start, uint256 count) external view returns (Stake[] memory) {
        count = Math.min(stakeCounts[a], count);
        Stake[] memory stakeArray = new Stake[](count);
        for (uint256 i = start; i < count; i++) {
            stakeArray[i] = stakes[a][i];
        }
        return stakeArray;
    }

    function getStakesAll(address a) external view returns (Stake[] memory) {
        uint256 _count = stakeCounts[a];
        Stake[] memory stakeArray = new Stake[](_count);
        for (uint256 i = 0; i < _count; i++) {
            stakeArray[i] = stakes[a][i];
        }
        return stakeArray;
    }

    function setMins(uint256 _minStake, uint256 _minLockTime) external onlyOwner {
        minStake = _minStake;
        minLockTime = _minLockTime;
    }

    function setMaxs(uint256 _maxStake, uint256 _maxLockTime) external onlyOwner {
        maxStake = _maxStake;
        maxLockTime = _maxLockTime;
    }

    function setLockTimeBonusDenominator(uint256 _lockTimeBonusDenominator) external onlyOwner {
        lockTimeBonusDenominator = _lockTimeBonusDenominator;
    }

    function migrateGlobals(
        uint256 _total_balance,
        uint256 _total_shares,
        uint256 _total_claimed,
        uint256 _total_rewards,
        uint256 _totalAccPoints
    ) external onlyOwner {
        total_balance = _total_balance;
        total_shares = _total_shares;
        total_claimed = _total_claimed;
        total_rewards = _total_rewards;
        totalAccPoints = _totalAccPoints;
    }

    function migrateStake(address a, Stake memory u) public onlyOwner {
        uint256 _count = stakeCounts[a];
        if (_count == 0) stakeAddresses.push(a);
        stakes[a][_count] = u;
        stakeCounts[a] = _count + 1;
    }

    function migrateStakes(address[] calldata _addresses, Stake[][] memory _stakes) external onlyOwner {
        require(_addresses.length == _stakes.length, "Invalid params");
        for (uint256 i = 0; i < _addresses.length; i++) {
            address account = _addresses[i];
            if (stakeCounts[account] == 0) {
                for (uint256 j = 0; j < _stakes[i].length; j++) {
                    migrateStake(account, _stakes[i][j]);
                }
            }
        }
    }

    function setStake(address _account, uint256 _id, Stake memory _newStake) external onlyOwner {
        Stake memory _stake = stakes[_account][_id];
        require(_stake.amount > 0, "No user");
        total_claimed = total_claimed.sub(_stake.claimed).add(_newStake.claimed);
        total_balance = total_balance.sub(_stake.amount).add(_newStake.amount);
        total_shares = total_shares.sub(_stake.shares).add(_newStake.shares);
        stakes[_account][_id] = _newStake;
    }

    function addActions(Action[] memory _actions) external onlyOwner {
        for (uint256 i = 0; i < _actions.length; i++) {
            actions[numActions + i] = _actions[i];
        }
        numActions = numActions.add(_actions.length);
    }

    function setActions(Action[] memory _actions) external onlyOwner {
        for (uint256 i = 0; i < _actions.length; i++) {
            actions[i] = _actions[i];
        }
        numActions = _actions.length;
    }

    function clearActions() public onlyOwner {
        for (uint256 i = 0; i < numActions; i++) {
            delete actions[i];
        }
        numActions = 0;
    }

    function listActions() external view returns (Action[] memory) {
        Action[] memory _actions = new Action[](numActions);

        for (uint256 i = 0; i < numActions; i++) {
            _actions[i] = actions[i];
        }
        return _actions;
    }

    function isUnlocked(address _account, uint256 _id) public view returns (bool) {
        return block.timestamp >= getUnlockTime(_account, _id);
    }

    function getUnlockTime(address _account, uint256 _id) public view returns (uint256) {
        return stakes[_account][_id].endTime;
    }

    function getTimeToUnlock(address _account, uint256 _id) external view returns (uint256) {
        Stake memory _stake = stakes[_account][_id];
        return _stake.endTime > block.timestamp ? _stake.endTime.sub(block.timestamp) : 0;
    }

    function getLockTime(address _account, uint256 _id) external view returns (uint256) {
        Stake memory _stake = stakes[_account][_id];
        return _stake.endTime.sub(_stake.startTime);
    }

    function getDistributionRewards(address _account, uint256 _id) public view returns (uint256) {
        Stake memory _stake = stakes[_account][_id];
        return _stake.shares.mul(totalAccPoints.sub(_stake.accPoints)).div(MULTIPLIER);
    }

    function getRewards(address _user, uint256 _id) public view returns (uint256) {
        Stake memory _stake = stakes[_user][_id];
        return _stake.shares > 0 ? getDistributionRewards(_user, _id).add(getRewardBalancePool().mul(_stake.shares).div(total_shares)) : 0;
    }

    function getShare(address _user, uint256 _id) external view returns (uint256) {
        uint256 _shares = stakes[_user][_id].shares;
        return _shares > 0 ? _shares.mul(MULTIPLIER).div(total_shares) : 0;
    }

    function getTotalRewards(address _user) public view returns (uint256) {
        uint256 _totalRewards = 0;
        uint256 _count = stakeCounts[_user];
        for (uint256 i = 0; i < _count; i++) {
            _totalRewards = _totalRewards.add(getRewards(_user, i));
        }
        return _totalRewards;
    }

    function listRewards(address _user) public view returns (uint256[] memory) {
        uint256 _count = stakeCounts[_user];
        uint256[] memory _rewardsArr = new uint256[](_count);
        for (uint256 i = 0; i < _count; i++) {
            _rewardsArr[i] = getRewards(_user, i);
        }
        return _rewardsArr;
    }

    function stake(uint256 _amount, uint256 _lockTime) external whenNotPaused nonReentrant {
        require(_amount >= minStake, "< min stake");
        require(_lockTime >= minLockTime, "< min lock time");
        require(_amount <= maxStake, "> max stake");
        require(_lockTime <= maxLockTime, "> max lock time");
        address _sender = _msgSender();
        uint256 _id = stakeCounts[_sender];

        if (_id == 0) {
            stakeAddresses.push(_sender); // New user
        }

        Stake storage _stake = stakes[_sender][_id];
        _stake.accPoints = totalAccPoints;

        depositToken.safeTransferFrom(_sender, address(this), _amount);

        _stake.amount = _amount;
        total_balance = total_balance.add(_amount);

        _stake.shares = _amount.mul(lockTimeBonusDenominator.add(_lockTime)).mul(shareMultiplierBp).div(lockTimeBonusDenominator).div(10000);
        total_shares = total_shares.add((_amount.mul(lockTimeBonusDenominator.add(_lockTime))).mul(shareMultiplierBp).div(lockTimeBonusDenominator).div(10000));

        _stake.startTime = block.timestamp;
        _stake.endTime = block.timestamp + _lockTime;

        stakeCounts[_sender] = stakeCounts[_sender].add(1);

        _invokeActions(false);
        _dripRewards();

        if (stakes[_sender][_id].accPoints != totalAccPoints) stakes[_sender][_id].accPoints = totalAccPoints;
    }

    function unstake(uint256 _id) external whenNotPaused nonReentrant {
        _unstake(_msgSender(), _id, true);
    }

    function unstakeAll() external whenNotPaused nonReentrant {
        _invokeActions(false);
        _dripRewards();

        address _sender = _msgSender();
        uint256 _stakeCount = stakeCounts[_sender];

        for (uint256 i = 0; i < _stakeCount; i++) {
            _unstake(_sender, i, false);
        }

        _invokeActions(false);
        _dripRewards();
    }

    function _unstake(address _sender, uint256 _id, bool _actions) internal {
        if (stakes[_sender][_id].amount > 0 && isUnlocked(_sender, _id)) {
            if (getRewards(_sender, _id) > 0) {
                _claim(_sender, _id, _actions, true);
            }

            Stake storage _stake = stakes[_sender][_id];
            uint256 _amount = _stake.amount;

            total_balance -= _amount;
            total_shares -= _stake.shares;

            _stake.amount = 0;
            _stake.shares = 0;

            depositToken.safeTransfer(_sender, _amount);

            if (_actions) {
                _invokeActions(false);
                _dripRewards();
            }

            if (stakes[_sender][_id].accPoints != totalAccPoints) stakes[_sender][_id].accPoints = totalAccPoints;
        }
    }

    function claimAll() external whenNotPaused nonReentrant {
        _invokeActions(false);
        _dripRewards();

        address _sender = _msgSender();
        uint256 _stakeCount = stakeCounts[_sender];

        for (uint256 i = 0; i < _stakeCount; i++) {
            _claim(_sender, i, false, false);
        }
    }

    function claim(uint256 _id) external whenNotPaused nonReentrant {
        _claim(_msgSender(), _id, true, false);
    }

    function _claim(address _sender, uint256 _id, bool _actions, bool _unstaking) internal {
        if (_actions) {
            _invokeActions(false);
            _dripRewards();
        }

        uint256 _rewards = getDistributionRewards(_sender, _id);

        if (_rewards > 0) {
            Stake storage _stake = stakes[_sender][_id];
            _stake.claimed += _rewards;
            total_claimed += _rewards;

            total_rewards -= _rewards;
            _stake.accPoints = totalAccPoints;

            // 1% Bounty
            if (_sender != _msgSender()) {
                rewardToken.safeTransfer(_msgSender(), _rewards / 100);
                rewardToken.safeTransfer(_sender, _rewards - (_rewards / 100));
            } else {
                rewardToken.safeTransfer(_sender, _rewards);
            }
        }

        if (!_unstaking && isUnlocked(_sender, _id)) {
            total_shares -= stakes[_sender][_id].shares;
            stakes[_sender][_id].shares = 0;

            _invokeActions(false);
            _dripRewards();

            if (stakes[_sender][_id].accPoints != totalAccPoints) stakes[_sender][_id].accPoints = totalAccPoints;
        }
    }

    function listExpiredStakes(uint _start, uint _end) external view returns (address[] memory, uint256[][] memory) {
        uint256 _count = Math.min(_end, stakeAddresses.length) - _start + 1;
        address[] memory _addresses = new address[](_count);
        uint256[][] memory _ids = new uint256[][](_count);

        for (uint256 i = _start; i < _count; i++) {
            address _sender = stakeAddresses[i];
            uint256 _stakeCount = stakeCounts[_sender];
            uint256 _expiredCount = 0;

            for (uint256 j = 0; j < _stakeCount; j++) {
                if (isUnlocked(_sender, j)) {
                    _expiredCount++;
                }
            }

            if (_expiredCount > 0) {
                uint256[] memory _expiredIds = new uint256[](_expiredCount);
                uint256 _index = 0;

                for (uint256 j = 0; j < _stakeCount; j++) {
                    if (isUnlocked(_sender, j)) {
                        _expiredIds[_index] = j;
                        _index++;
                    }
                }

                _addresses[i] = _sender;
                _ids[i] = _expiredIds;
            }
        }

        return (_addresses, _ids);
    }

    function goodAccounting(address _sender) external nonReentrant whenNotPaused {
        _invokeActions(false);
        _dripRewards();

        uint256 _count = stakeCounts[_sender];
        for (uint256 i = 0; i < _count; i++) {
            if (isUnlocked(_sender, i)) {
                _claim(_sender, i, false, false);
            }
        }
    }

    function _dripRewards() internal {
        uint256 _amount = getRewardBalancePool();
        if (_amount > 0 && total_shares > 0) {
            if (feeBp > 0) {
                uint256 _feeAmount = (_amount * feeBp) / 10000;
                fee_rewards += _feeAmount;
                _amount -= _feeAmount;
            }

            total_rewards += _amount;
            totalAccPoints += (_amount * MULTIPLIER) / total_shares;

            if (block.timestamp > lastRewardTime) {
                rewardsPerSecond = _amount / (block.timestamp - lastRewardTime);
                lastRewardTime = block.timestamp;
            } else {
                rewardsPerSecond += _amount;
            }
        }
    }

    function dripRewards() external {
        _dripRewards();
    }

    function total_users() external view returns (uint256) {
        return stakeAddresses.length;
    }

    function listUsers() external view returns (address[] memory) {
        return stakeAddresses;
    }

    function getRewardBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function getRewardBalancePool() public view returns (uint256) {
        return getRewardBalance() - total_rewards - fee_rewards;
    }

    function excessDepositTokens() public view returns (uint256) {
        return depositToken.balanceOf(address(this)).sub(total_balance);
    }

    function setTokenApproval(address _token, address _spender, bool _approved) external onlyOwner {
        IERC20(_token).approve(_spender, _approved ? type(uint256).max : 0);
    }

    function _swapAndLiquifyWPLS(address _router, address _lpToken, uint256 _slippageBp, bool _requireSuccess) internal {
        address _wplsAddress = wplsAddress;
        uint256 _wplsBalance = IERC20(_wplsAddress).balanceOf(address(this));

        if (_wplsBalance >= minSwapAndLiquifyWPLS) {
            address _otherAddress = address(depositToken);
            uint256 _otherBalance = IERC20(_otherAddress).balanceOf(address(this));
            address[] memory _path = new address[](2);
            _path[0] = _wplsAddress;
            _path[1] = _otherAddress;
            uint256 _swapAmountNegatingFee = ((_wplsBalance / 2) * liquifySwapFeeMultiplier) / 10000;
            _swap(_router, _swapAmountNegatingFee, _slippageBp, _path, _requireSuccess);
            _otherBalance = IERC20(_otherAddress).balanceOf(address(this)) - _otherBalance;
            _wplsBalance -= _swapAmountNegatingFee;

            _addLiquidityBasedOnQuote(_router, _lpToken, _wplsAddress, _otherAddress, _wplsBalance, _otherBalance, _slippageBp, _requireSuccess);
        }
    }

    function _swapAndLiquify(address _router, address _lpToken, uint256 _slippageBp, bool _requireSuccess) internal {
        address _depositToken = address(depositToken);
        address _token0 = IUniswapV2Pair(_lpToken).token0();
        address _token1 = IUniswapV2Pair(_lpToken).token1();
        uint256 _amount0 = _token0 == address(_depositToken)
            ? IERC20(_token0).balanceOf(address(this)).sub(total_balance)
            : IERC20(_token0).balanceOf(address(this));
        uint256 _amount1 = _token1 == address(_depositToken)
            ? IERC20(_token1).balanceOf(address(this)).sub(total_balance)
            : IERC20(_token1).balanceOf(address(this));
        address[] memory _path = new address[](2);
        _path[0] = _token0;
        _path[1] = _token1;

        if (_amount0 > 0 && (_amount1 == 0 || _getAmountOut(_router, _amount0 / 2, _path, _requireSuccess) >= _amount1 / 2)) {
            uint256 _swapAmountNegatingFee0 = ((_amount0 / 2) * liquifySwapFeeMultiplier) / 10000;
            _swap(_router, _swapAmountNegatingFee0, _slippageBp, _path, _requireSuccess);

            _amount1 = _token1 == address(_depositToken)
                ? IERC20(_token1).balanceOf(address(this)).sub(total_balance).sub(_amount1)
                : IERC20(_token1).balanceOf(address(this)).sub(_amount1);
            _amount0 -= _swapAmountNegatingFee0;
        } else {
            _path[0] = _token1;
            _path[1] = _token0;

            uint256 _swapAmountNegatingFee1 = ((_amount1 / 2) * liquifySwapFeeMultiplier) / 10000;
            _swap(_router, _swapAmountNegatingFee1, _slippageBp, _path, _requireSuccess);

            _amount0 = _token0 == address(_depositToken)
                ? IERC20(_token0).balanceOf(address(this)).sub(total_balance).sub(_amount0)
                : IERC20(_token0).balanceOf(address(this)).sub(_amount0);
            _amount1 -= _swapAmountNegatingFee1;
        }

        if (_amount0 > 0 && _amount1 > 0) {
            _addLiquidityBasedOnQuote(_router, _lpToken, _token0, _token1, _amount0, _amount1, _slippageBp, _requireSuccess);
        }
    }

    function _getReservesOrdered(address _lpToken, address _firstToken) internal view returns (uint, uint) {
        (uint _reserve0, uint _reserve1, ) = IUniswapV2Pair(_lpToken).getReserves();
        return IUniswapV2Pair(_lpToken).token0() == _firstToken ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
    }

    function _getAmountOut(address _router, uint256 _amountIn, address[] memory _path, bool _requireSuccess) internal view returns (uint) {
        if (_router == sparkSwapRouter) {
            try ISparkSwapRouter02(_router).getAmountsOut(_amountIn, _path, address(this)) returns (uint[] memory _amounts) {
                return _amounts.length > 0 ? _amounts[_amounts.length - 1] : 0;
            } catch Error(string memory errorMessage) {
                if (_requireSuccess) revert(errorMessage);
            } catch {
                if (_requireSuccess) revert("getAmountsOut failed");
            }
            return 0;
        } else {
            try IUniswapV2Router(_router).getAmountsOut(_amountIn, _path) returns (uint[] memory _amounts) {
                return _amounts.length > 0 ? _amounts[_amounts.length - 1] : 0;
            } catch Error(string memory errorMessage) {
                if (_requireSuccess) revert(errorMessage);
            } catch {
                if (_requireSuccess) revert("getAmountsOut failed");
            }
            return 0;
        }
    }
    
    function _quote(address _router, uint amountA, uint reserveA, uint reserveB, bool _requireSuccess) internal pure returns (uint) {
        try IUniswapV2Router(_router).quote(amountA, reserveA, reserveB) returns (uint _amountB) {
            return _amountB;
        } catch Error(string memory errorMessage) {
            if (_requireSuccess) revert(errorMessage);
        } catch {
            if (_requireSuccess) revert("getAmountsOut failed");
        }
        return 0;
    }

    function _swap(address _router, uint256 _amountIn, uint256 _slippageBp, address[] memory _path, bool _requireSuccess) internal {
        try
            IUniswapV2Router(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountIn,
                (_getAmountOut(_router, _amountIn, _path, _requireSuccess) * (10000 - _slippageBp)) / 10000,
                _path,
                address(this),
                block.timestamp + 600
            )
        {} catch Error(string memory errorMessage) {
            if (_requireSuccess) revert(errorMessage);
        } catch {
            if (_requireSuccess) revert("Swap failed");
        }
    }

    function _addLiquidityBasedOnQuote(
        address _router,
        address _lpToken,
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _slippageBp,
        bool _requireSuccess
    ) internal {
        (uint256 _reserve0, uint256 _reserve1) = _getReservesOrdered(_lpToken, _token0);
        uint256 _quoteOther = _quote(_router, _amount0, _reserve0, _reserve1, _requireSuccess);

        if (_quoteOther > _amount1) {
            _amount0 = _quote(_router, _amount1, _reserve1, _reserve0, _requireSuccess);
        } else {
            _amount1 = _quoteOther;
        }

        try
            IUniswapV2Router(_router).addLiquidity(
                _token0,
                _token1,
                _amount0,
                _amount1,
                (_amount0 * (10000 - _slippageBp)) / 10000,
                (_amount1 * (10000 - _slippageBp)) / 10000,
                address(this),
                block.timestamp + 600
            )
        {} catch Error(string memory errorMessage) {
            if (_requireSuccess) revert(errorMessage);
        } catch {
            if (_requireSuccess) revert("LP_ADD failed");
        }
    }

    function _invokeActions(bool _requireSuccess) internal {
        for (uint256 i = 0; i < numActions; i++) {
            Action memory action = actions[i];
            address token0 = action.tokens[0];
            uint256 amount = token0 == address(0) ? address(this).balance : IERC20(token0).balanceOf(address(this));

            // if (token0 == address(rewardToken)) continue; // Cannot swap from reward token
            if (token0 == address(depositToken)) {
                // if (address(depositToken) == address(rewardToken)) continue;
                amount = amount.sub(total_balance);
            }

            if (amount > 0 || action.actionType == ActionType.LP_ADD) {
                if (address(this).balance > 0) {
                    IWrapped(IUniswapV2Router(action.target).WETH()).deposit{value: address(this).balance}();
                }

                if (action.actionType == ActionType.SWAP) {
                    _swap(action.target, amount, action.slippageBp, action.tokens, _requireSuccess);
                } else if (action.actionType == ActionType.LP_REMOVE) {
                    try
                        IUniswapV2Router(action.target).removeLiquidity(
                            IUniswapV2Pair(token0).token0(),
                            IUniswapV2Pair(token0).token1(),
                            amount,
                            0,
                            0,
                            address(this),
                            block.timestamp + 600
                        )
                    {} catch Error(string memory errorMessage) {
                        if (_requireSuccess) revert(errorMessage);
                    } catch {
                        if (_requireSuccess) revert("Liquidity remove failed");
                    }
                } else if (action.actionType == ActionType.LP_ADD) {
                    if (swapAndLiquifyBiDirectional) {
                        _swapAndLiquify(action.target, token0, action.slippageBp, _requireSuccess);
                    } else {
                        _swapAndLiquifyWPLS(action.target, token0, action.slippageBp, _requireSuccess);
                    }
                } else if (action.actionType == ActionType.BURN) {
                    try IERC20(token0).transfer(address(0), amount) {} catch Error(string memory errorMessage) {
                        if (_requireSuccess) revert(errorMessage);
                    } catch {
                        if (_requireSuccess) revert("Burn failed");
                    }
                } else {
                    (bool success, ) = action.target.call{value: 0}(action.otherData);
                    if (_requireSuccess && !success) {
                        // solhint-disable-next-line no-inline-assembly
                        assembly {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }
                    }
                }
            }
        }
    }

    function invokeActions(bool _requireSuccess) external onlyOwner {
        _invokeActions(_requireSuccess);
        _dripRewards();
    }

    function invoke(address[] calldata _targetArr, uint256[] calldata _valueArr, bytes[] memory _dataArr, bool _requireSuccess) external onlyOwner {
        for (uint256 i = 0; i < _targetArr.length; i++) {
            (bool success, ) = _targetArr[i].call{value: _valueArr[i]}(_dataArr[i]);
            if (_requireSuccess && !success) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        _dripRewards();
    }



    function setRewardToken(IERC20 _rewardToken) external onlyOwner returns (bool) {
        require(address(_rewardToken) != address(0) && address(_rewardToken) != address(depositToken), "Wrong rewardToken address");
        rewardToken = _rewardToken;
        return true;
    }

    function setRewardsPerSecond(uint256 _amount) external onlyOwner returns (bool) {
        rewardsPerSecond = _amount;
        return true;
    }

    function setLastRewardTime(uint256 _lastRewardTime) external onlyOwner returns (bool) {
        lastRewardTime = _lastRewardTime;
        return true;

    }

    function setFeeRewards(uint256 _feeRewards) external onlyOwner returns (bool) {
        fee_rewards = _feeRewards;
        return true;
    }

    function setSparkSwapRouter(address _sparkSwapRouter) external onlyOwner returns (bool) {
        require(address(_sparkSwapRouter) != address(0), "SparkSwap router address is zero");
        sparkSwapRouter = _sparkSwapRouter;
        return true;
    }

}