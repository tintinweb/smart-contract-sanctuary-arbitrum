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
interface IERC20PermitUpgradeable {
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
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

library PythErrors {
    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    error PriceFeedNotFound();
    // Requested price is stale.
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    error InvalidGovernanceDataSource();
    // Governance message is old.
    error OldGovernanceMessage();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// D8X, 2022

pragma solidity 0.8.21;

/**
 * This is a modified version of the OpenZeppelin ownable contract
 * Modifications
 * - instead of an owner, we have two actors: maintainer and governance
 * - maintainer can have certain priviledges but cannot transfer maintainer mandate
 * - governance can exchange maintainer and exchange itself
 * - renounceOwnership is removed
 *
 *
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
abstract contract Maintainable {
    address private _maintainer;
    address private _governance;

    event MaintainerTransferred(address indexed previousMaintainer, address indexed newMaintainer);
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @dev Initializes the contract setting the deployer as the initial maintainer.
     */
    constructor() {
        _transferMaintainer(msg.sender);
        _transferGovernance(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function maintainer() public view virtual returns (address) {
        return _maintainer;
    }

    /**
     * @dev Returns the address of the governance.
     */
    function governance() public view virtual returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMaintainer() {
        require(maintainer() == msg.sender, "only maintainer");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(governance() == msg.sender, "only governance");
        _;
    }

    /**
     * @dev Transfers maintainer mandate of the contract to a new account (`newMaintainer`).
     * Can only be called by the governance.
     */
    function transferMaintainer(address newMaintainer) public virtual {
        require(msg.sender == _governance, "only governance");
        require(newMaintainer != address(0), "zero address");
        _transferMaintainer(newMaintainer);
    }

    /**
     * @dev Transfers governance mandate of the contract to a new account (`newGovernance`).
     * Can only be called by the governance.
     */
    function transferGovernance(address newGovernance) public virtual {
        require(msg.sender == _governance, "only governance");
        require(newGovernance != address(0), "zero address");
        _transferGovernance(newGovernance);
    }

    /**
     * @dev Transfers maintainer of the contract to a new account (`newMaintainer`).
     * Internal function without access restriction.
     */
    function _transferMaintainer(address newMaintainer) internal virtual {
        address oldM = _maintainer;
        _maintainer = newMaintainer;
        emit MaintainerTransferred(oldM, newMaintainer);
    }

    /**
     * @dev Transfers governance of the contract to a new account (`newGovernance`).
     * Internal function without access restriction.
     */
    function _transferGovernance(address newGovernance) internal virtual {
        address oldG = _governance;
        _governance = newGovernance;
        emit GovernanceTransferred(oldG, newGovernance);
    }
}

// SPDX-License-Identifier: GPL-3.0

// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity >=0.5.0;

/// @notice ERC4626 interface
/// @author OpenZeppelin
/// @dev In this implementation, the interface only contains the functions that the IERC4626 interface adds on top of
/// the IERC20 interface
interface IERC4626 {
    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title ISwapper
/// @author Angle Labs, Inc.
interface ISwapper {
    /// @notice Swaps (that is to say mints or burns) an exact amount of `tokenIn` for an amount of `tokenOut`
    /// @param amountIn Amount of `tokenIn` to bring
    /// @param amountOutMin Minimum amount of `tokenOut` to get: if `amountOut` is inferior to this amount, the
    /// function will revert
    /// @param tokenIn Token to bring for the swap
    /// @param tokenOut Token to get out of the swap
    /// @param to Address to which `tokenOut` must be sent
    /// @param deadline Timestamp before which the transaction must be executed
    /// @return amountOut Amount of `tokenOut` obtained through the swap
    function swapExactInput(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    /// @notice Same as `swapExactInput`, but using Permit2 signatures for `tokenIn`
    /// @dev Can only be used to mint, hence `tokenOut` is not needed
    function swapExactInputWithPermit(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address to,
        uint256 deadline,
        bytes calldata permitData
    ) external returns (uint256 amountOut);

    /// @notice Swaps (that is to say mints or burns) an amount of `tokenIn` for an exact amount of `tokenOut`
    /// @param amountOut Amount of `tokenOut` to obtain from the swap
    /// @param amountInMax Maximum amount of `tokenIn` to bring in order to get `amountOut` of `tokenOut`
    /// @param tokenIn Token to bring for the swap
    /// @param tokenOut Token to get out of the swap
    /// @param to Address to which `tokenOut` must be sent
    /// @param deadline Timestamp before which the transaction must be executed
    /// @return amountIn Amount of `tokenIn` used to perform the swap
    function swapExactOutput(
        uint256 amountOut,
        uint256 amountInMax,
        address tokenIn,
        address tokenOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountIn);

    /// @notice Same as `swapExactOutput`, but using Permit2 signatures for `tokenIn`
    /// @dev Can only be used to mint, hence `tokenOut` is not needed
    function swapExactOutputWithPermit(
        uint256 amountOut,
        uint256 amountInMax,
        address tokenIn,
        address to,
        uint256 deadline,
        bytes calldata permitData
    ) external returns (uint256 amountIn);

    /// @notice Simulates what a call to `swapExactInput` with `amountIn` of `tokenIn` for `tokenOut` would give.
    /// If called right before and at the same block, the `amountOut` outputted by this function is exactly the
    /// amount that will be obtained with `swapExactInput`
    function quoteIn(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut);

    /// @notice Simulates what a call to `swapExactOutput` for `amountOut` of `tokenOut` with `tokenIn` would give.
    /// If called right before and at the same block, the `amountIn` outputted by this function is exactly the
    /// amount that will be obtained with `swapExactOutput`
    function quoteOut(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/**
 * @title
 * @notice Reduced version of AngleProtocol transmuter
 * https://github.com/AngleProtocol/angle-transmuter/blob/d592dd9106c97bd8864532bb3001bba5afa511db/contracts/interfaces/ITransmuter.sol
 */

import { ISwapper } from "./ISwapper.sol";

interface ITransmuter is ISwapper {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IShareTokenFactory {
    function createShareToken(uint8 _poolId, address _marginTokenAddr) external returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

interface ISpotOracle {
    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external view returns (bool);

    function setMarketClosed(bool _marketClosed) external;

    /**
     *  Spot price.
     */
    function getSpotPrice() external view returns (int128, uint256);

    /**
     * Get base currency symbol.
     */
    function getBaseCurrency() external view returns (bytes4);

    /**
     * Get quote currency symbol.
     */
    function getQuoteCurrency() external view returns (bytes4);

    /**
     * Price Id
     */
    function priceId() external view returns (bytes32);

    /**
     * Address of the underlying feed.
     */
    function priceFeed() external view returns (address);

    /**
     * Conservative update period of this feed in seconds.
     */
    function feedPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.8.21;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF, "ABDK.fromInt");
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return int64(x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(x <= 0x7FFFFFFFFFFFFFFF, "ABDK.fromUInt");
        return int128(int256(x << 64));
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        require(x >= 0, "ABDK.toUInt");
        return uint64(uint128(x >> 64));
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        int256 result = x >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.from128x128");
        return int128(result);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return int256(x) << 64;
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) + y;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.add");
        return int128(result);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.sub");
        return int128(result);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = (int256(x) * y) >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.mul");
        return int128(result);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        if (x == MIN_64x64) {
            require(
                y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                    y <= 0x1000000000000000000000000000000000000000000000000,
                "ABDK.muli-1"
            );
            return -y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = -x;
                negativeResult = true;
            }
            if (y < 0) {
                y = -y;
                // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu(x, uint256(y));
            if (negativeResult) {
                require(
                    absoluteResult <=
                        0x8000000000000000000000000000000000000000000000000000000000000000,
                    "ABDK.muli-2"
                );
                return -int256(absoluteResult);
                // We rely on overflow behavior here
            } else {
                require(
                    absoluteResult <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                    "ABDK.muli-3"
                );
                return int256(absoluteResult);
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0, "ABDK.mulu-1");

        uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256(int256(x)) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.mulu-2");
        hi <<= 64;

        require(
            hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo,
            "ABDK.mulu-3"
        );
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        require(y != 0, "ABDK.div-1");
        int256 result = (int256(x) << 64) / y;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.div-2");
        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        require(y != 0, "ABDK.divi-1");

        bool negativeResult = false;
        if (x < 0) {
            x = -x;
            // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = -y;
            // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu(uint256(x), uint256(y));
        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000, "ABDK.divi-2");
            return -int128(absoluteResult);
            // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.divi-3");
            return int128(absoluteResult);
            // We rely on overflow behavior here
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        require(y != 0, "ABDK.divu-1");
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64), "ABDK.divu-2");
        return int128(result);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64, "ABDK.neg");
        return -x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64, "ABDK.abs");
        return x < 0 ? -x : x;
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        require(x != 0, "ABDK.inv-1");
        int256 result = int256(0x100000000000000000000000000000000) / x;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.inv-2");
        return int128(result);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return int128((int256(x) + int256(y)) >> 1);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        int256 m = int256(x) * int256(y);
        require(m >= 0, "ABDK.gavg-1");
        require(
            m < 0x4000000000000000000000000000000000000000000000000000000000000000,
            "ABDK.gavg-2"
        );
        return int128(sqrtu(uint256(m)));
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        bool negative = x < 0 && y & 1 == 1;

        uint256 absX = uint128(x < 0 ? -x : x);
        uint256 absResult;
        absResult = 0x100000000000000000000000000000000;

        if (absX <= 0x10000000000000000) {
            absX <<= 63;
            while (y != 0) {
                if (y & 0x1 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                if (y & 0x2 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                if (y & 0x4 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                if (y & 0x8 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                y >>= 4;
            }

            absResult >>= 64;
        } else {
            uint256 absXShift = 63;
            if (absX < 0x1000000000000000000000000) {
                absX <<= 32;
                absXShift -= 32;
            }
            if (absX < 0x10000000000000000000000000000) {
                absX <<= 16;
                absXShift -= 16;
            }
            if (absX < 0x1000000000000000000000000000000) {
                absX <<= 8;
                absXShift -= 8;
            }
            if (absX < 0x10000000000000000000000000000000) {
                absX <<= 4;
                absXShift -= 4;
            }
            if (absX < 0x40000000000000000000000000000000) {
                absX <<= 2;
                absXShift -= 2;
            }
            if (absX < 0x80000000000000000000000000000000) {
                absX <<= 1;
                absXShift -= 1;
            }

            uint256 resultShift;
            while (y != 0) {
                require(absXShift < 64, "ABDK.pow-1");

                if (y & 0x1 != 0) {
                    absResult = (absResult * absX) >> 127;
                    resultShift += absXShift;
                    if (absResult > 0x100000000000000000000000000000000) {
                        absResult >>= 1;
                        resultShift += 1;
                    }
                }
                absX = (absX * absX) >> 127;
                absXShift <<= 1;
                if (absX >= 0x100000000000000000000000000000000) {
                    absX >>= 1;
                    absXShift += 1;
                }

                y >>= 1;
            }

            require(resultShift < 64, "ABDK.pow-2");
            absResult >>= 64 - resultShift;
        }
        int256 result = negative ? -int256(absResult) : int256(absResult);
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.pow-3");
        return int128(result);
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        require(x >= 0, "ABDK.sqrt");
        return int128(sqrtu(uint256(int256(x)) << 64));
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0, "ABDK.log_2");

        int256 msb;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1;
        // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(int256(x)) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0, "ABDK.ln");

            return
                int128(
                    int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128)
                );
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000, "ABDK.exp_2-1");
        // Overflow

        if (x < -0x400000000000000000) return 0;
        // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
        if (x & 0x4000000000000000 > 0)
            result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
        if (x & 0x2000000000000000 > 0)
            result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
        if (x & 0x1000000000000000 > 0)
            result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
        if (x & 0x800000000000000 > 0)
            result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
        if (x & 0x400000000000000 > 0)
            result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
        if (x & 0x200000000000000 > 0)
            result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
        if (x & 0x100000000000000 > 0)
            result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
        if (x & 0x80000000000000 > 0)
            result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
        if (x & 0x40000000000000 > 0)
            result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
        if (x & 0x20000000000000 > 0)
            result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
        if (x & 0x10000000000000 > 0)
            result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
        if (x & 0x8000000000000 > 0)
            result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
        if (x & 0x4000000000000 > 0)
            result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
        if (x & 0x2000000000000 > 0)
            result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
        if (x & 0x1000000000000 > 0)
            result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
        if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
        if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
        if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
        if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
        if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
        if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
        if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
        if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
        if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
        if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
        if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
        if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
        if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
        if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
        if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
        if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
        if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
        if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
        if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
        if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
        if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
        if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
        if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
        if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
        if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
        if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
        if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
        if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
        if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
        if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
        if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
        if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
        if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
        if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
        if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
        if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
        if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
        if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
        if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
        if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
        if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
        if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
        if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
        if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
        if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
        if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
        if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
        if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

        result >>= uint256(int256(63 - (x >> 64)));
        require(result <= uint256(int256(MAX_64x64)), "ABDK.exp_2-2");

        return int128(int256(result));
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000, "ABDK.exp");
        // Overflow

        if (x < -0x400000000000000000) return 0;
        // Underflow

        return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        require(y != 0, "ABDK.divuu-1");

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1;
            // No need to shift xc anymore

            result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.divuu-2");

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.divuu-3");
        return uint128(result);
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ABDKMath64x64.sol";

library ConverterDec18 {
    using ABDKMath64x64 for int128;
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    int256 private constant DECIMALS = 10**18;

    int128 private constant ONE_64x64 = 0x010000000000000000;

    int128 public constant HALF_TBPS = 92233720368548; //1e-5 * 0.5 * 2**64

    // convert tenth of basis point to dec 18:
    uint256 public constant TBPSTODEC18 = 0x9184e72a000; // hex(10^18 * 10^-5)=(10^13)
    // convert tenth of basis point to ABDK 64x64:
    int128 public constant TBPSTOABDK = 0xa7c5ac471b48; // hex(2^64 * 10^-5)
    // convert two-digit integer reprentation to ABDK
    int128 public constant TDRTOABDK = 0x28f5c28f5c28f5c; // hex(2^64 * 10^-2)

    function tbpsToDec18(uint16 Vtbps) internal pure returns (uint256) {
        return TBPSTODEC18 * uint256(Vtbps);
    }

    function tbpsToABDK(uint16 Vtbps) internal pure returns (int128) {
        return int128(uint128(TBPSTOABDK) * uint128(Vtbps));
    }

    function TDRToABDK(uint16 V2Tdr) internal pure returns (int128) {
        return int128(uint128(TDRTOABDK) * uint128(V2Tdr));
    }

    function ABDKToTbps(int128 Vabdk) internal pure returns (uint16) {
        // add 0.5 * 1e-5 to ensure correct rounding to tenth of bps
        return uint16(uint128(Vabdk.add(HALF_TBPS) / TBPSTOABDK));
    }

    function fromDec18(int256 x) internal pure returns (int128) {
        int256 result = (x * ONE_64x64) / DECIMALS;
        require(x >= MIN_64x64 && x <= MAX_64x64, "result out of range");
        return int128(result);
    }

    function toDec18(int128 x) internal pure returns (int256) {
        return (int256(x) * DECIMALS) / ONE_64x64;
    }

    function toUDec18(int128 x) internal pure returns (uint256) {
        require(x >= 0, "negative value");
        return uint256(toDec18(x));
    }

    function toUDecN(int128 x, uint8 decimals) internal pure returns (uint256) {
        require(x >= 0, "negative value");
        return uint256((int256(x) * int256(10**decimals)) / ONE_64x64);
    }

    function fromDecN(int256 x, uint8 decimals) internal pure returns (int128) {
        int256 result = (x * ONE_64x64) / int256(10**decimals);
        require(x >= MIN_64x64 && x <= MAX_64x64, "result out of range");
        return int128(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Library for managing loan sets.
 *
 * @notice Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * Include with `using EnumerableBytes4Set for EnumerableBytes4Set.Bytes4Set;`.
 * */
library EnumerableBytes4Set {
    struct Bytes4Set {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes4 => uint256) index;
        bytes4[] values;
    }

    /**
     * @notice Add a value to a set. O(1).
     *
     * @param set The set of values.
     * @param value The new value to add.
     *
     * @return False if the value was already in the set.
     */
    function addBytes4(Bytes4Set storage set, bytes4 value) internal returns (bool) {
        if (!contains(set, value)) {
            set.values.push(value);
            set.index[value] = set.values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Remove a value from a set. O(1).
     *
     * @param set The set of values.
     * @param value The value to remove.
     *
     * @return False if the value was not present in the set.
     */
    function removeBytes4(Bytes4Set storage set, bytes4 value) internal returns (bool) {
        if (contains(set, value)) {
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            /// If the element we're deleting is the last one,
            /// we can just remove it without doing a swap.
            if (lastIndex != toDeleteIndex) {
                bytes4 lastValue = set.values[lastIndex];

                /// Move the last value to the index where the deleted value is.
                set.values[toDeleteIndex] = lastValue;

                /// Update the index for the moved value.
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            /// Delete the index entry for the deleted value.
            delete set.index[value];

            /// Delete the old entry for the moved value.
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Find out whether a value exists in the set.
     *
     * @param set The set of values.
     * @param value The value to find.
     *
     * @return True if the value is in the set. O(1).
     */
    function contains(Bytes4Set storage set, bytes4 value) internal view returns (bool) {
        return set.index[value] != 0;
    }

    /**
     * @notice Get all set values.
     *
     * @param set The set of values.
     * @param start The offset of the returning set.
     * @param count The limit of number of values to return.
     *
     * @return output An array with all values in the set. O(N).
     *
     * @dev Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(
        Bytes4Set storage set,
        uint256 start,
        uint256 count
    ) internal view returns (bytes4[] memory output) {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes4[](end - start);
        for (uint256 i; i < end - start; i++) {
            output[i] = set.values[i + start];
        }
        return output;
    }

    /**
     * @notice Get the legth of the set.
     *
     * @param set The set of values.
     *
     * @return the number of elements on the set. O(1).
     */
    function length(Bytes4Set storage set) internal view returns (uint256) {
        return set.values.length;
    }

    /**
     * @notice Get an item from the set by its index.
     *
     * @dev Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     *
     * @param set The set of values.
     * @param index The index of the value to return.
     *
     * @return the element stored at position `index` in the set. O(1).
     */
    function get(Bytes4Set storage set, uint256 index) internal view returns (bytes4) {
        return set.values[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: idx out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function enumerate(
        AddressSet storage set,
        uint256 start,
        uint256 count
    ) internal view returns (address[] memory output) {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        uint256 len = length(set);
        end = len < end ? len : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new address[](end - start);
        for (uint256 i; i < end - start; i++) {
            output[i] = at(set, i + start);
        }
        return output;
    }

    function enumerateAll(AddressSet storage set) internal view returns (address[] memory output) {
        return enumerate(set, 0, length(set));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library OrderFlags {
    uint32 internal constant MASK_CLOSE_ONLY = 0x80000000;
    uint32 internal constant MASK_MARKET_ORDER = 0x40000000;
    uint32 internal constant MASK_STOP_ORDER = 0x20000000;
    uint32 internal constant MASK_FILL_OR_KILL = 0x10000000;
    uint32 internal constant MASK_KEEP_POS_LEVERAGE = 0x08000000;
    uint32 internal constant MASK_LIMIT_ORDER = 0x04000000;

    /**
     * @dev Check if the flags contain close-only flag
     * @param flags The flags
     * @return bool True if the flags contain close-only flag
     */
    function isCloseOnly(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_CLOSE_ONLY) > 0;
    }

    /**
     * @dev Check if the flags contain market flag
     * @param flags The flags
     * @return bool True if the flags contain market flag
     */
    function isMarketOrder(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_MARKET_ORDER) > 0;
    }

    /**
     * @dev Check if the flags contain fill-or-kill flag
     * @param flags The flags
     * @return bool True if the flags contain fill-or-kill flag
     */
    function isFillOrKill(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_FILL_OR_KILL) > 0;
    }

    /**
     * @dev We keep the position leverage for a closing position, if we have
     * an order with the flag MASK_KEEP_POS_LEVERAGE, or if we have
     * a limit or stop order.
     * @param flags The flags
     * @return bool True if we should keep the position leverage on close
     */
    function keepPositionLeverageOnClose(uint32 flags) internal pure returns (bool) {
        return (flags & (MASK_KEEP_POS_LEVERAGE | MASK_STOP_ORDER | MASK_LIMIT_ORDER)) > 0;
    }

    /**
     * @dev Check if the flags contain stop-loss flag
     * @param flags The flags
     * @return bool True if the flags contain stop-loss flag
     */
    function isStopOrder(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_STOP_ORDER) > 0;
    }

    /**
     * @dev Check if the flags contain limit-order flag
     * @param flags The flags
     * @return bool True if the flags contain limit-order flag
     */
    function isLimitOrder(uint32 flags) internal pure returns (bool) {
        return (flags & MASK_LIMIT_ORDER) > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/angle/ITransmuter.sol";
import "../interface/angle/IERC4626.sol";

/**
 * @title SwapLib to handle USDC<->stUSD conversions
 */
library SwapLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Arbitrum
    address public constant transmuter = 0xD253b62108d1831aEd298Fc2434A5A8e4E418053; //for USDA
    address public constant STUSD = 0x0022228a2cc5E7eF0274A7Baa600d44da5aB5776; //stUSD, savings
    address public constant USDA = 0x0000206329b97DB379d5E1Bf586BbDB969C63274; //USDA, 18 decimals
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; //USDC, 6 decimals
    uint256 public constant slippageTolDec9 = 500_000; //=0.0005*1e9

    /**
     * Swap token owned by this contract (_tokenInAddr) into token out and
     * send to receiver. stUSD -> USDC
     * @param _amountIn amount of the token to swap in token's decimal convention
     * @param _tokenInAddr address of the token that we send out
     * @param _tokenOutAddr address of the token we receive
     * @param _receiver the token is sent from this contract to the router. Eventually
     * the target token should end up in the receiver's wallet
     */
    function swapExactInputTo(
        uint256 _amountIn,
        address _tokenInAddr,
        address _tokenOutAddr,
        address _receiver
    ) internal {
        uint256 amountOutFirstSwap;
        // redeem stUSD to get USDA
        require(_tokenInAddr == SwapLib.STUSD, "stUSD in required");
        require(_tokenOutAddr == SwapLib.USDC, "USDC out required");
        amountOutFirstSwap = IERC4626(SwapLib.STUSD).redeem(
            _amountIn,
            address(this), //receiver
            address(this) //owner
        );
        require(amountOutFirstSwap > 0, "first swap must>0");
        IERC20Upgradeable(SwapLib.USDA).safeIncreaseAllowance(
            SwapLib.transmuter,
            amountOutFirstSwap
        );
        // swap USDA into USDC. Second argument (min amount out) must be dec 6
        // 21 = 9 + (18-6) -> USDA is in Dec 18, USDC Dec 6, Slippage Dec 9
        ITransmuter(SwapLib.transmuter).swapExactInput(
            amountOutFirstSwap,
            (amountOutFirstSwap * (1e9 - SwapLib.slippageTolDec9)) / 1e21,
            SwapLib.USDA,
            SwapLib.USDC,
            _receiver,
            block.timestamp
        );
    }

    /**
     * The user needs to deposit '_amountOut' of the token with _tokenOutAddr
     * into this contract. USDC -> stUSD
     * @param _amountOut amount the contract receives
     * @param _tokenInAddr token the user has
     * @param _tokenOutAddr token the contract receives
     * @param _sender the user address
     */
    function swapExactOutputFrom(
        uint256 _amountOut,
        address _tokenInAddr,
        address _tokenOutAddr,
        address _sender
    ) internal {
        // The user (trader or LP) gives allowance to spend their tokenIn on
        // this contract.
        // We first determine the required amount of tokenIn to receive
        // '_amountOut' of token out, then we transfer token in from the sender to this contract,
        // then we swap token in via router to token out and require that
        // token out is as specified
        require(_tokenInAddr == SwapLib.USDC, "USDC in required");
        require(_tokenOutAddr == SwapLib.STUSD, "stUSD out required");

        uint256 amountUSDA = IERC4626(SwapLib.STUSD).previewMint(_amountOut);
        uint256 amountIn = ITransmuter(SwapLib.transmuter).quoteOut(
            amountUSDA,
            SwapLib.USDC,
            SwapLib.USDA
        );
        IERC20Upgradeable(SwapLib.USDC).safeTransferFrom(_sender, address(this), amountIn);
        IERC20Upgradeable(SwapLib.USDC).safeIncreaseAllowance(SwapLib.transmuter, amountIn);
        IERC20Upgradeable(SwapLib.USDA).safeIncreaseAllowance(SwapLib.STUSD, amountUSDA);
        ISwapper(SwapLib.transmuter).swapExactInput(
            amountIn,
            amountUSDA,
            SwapLib.USDC,
            SwapLib.USDA,
            address(this),
            block.timestamp
        );
        IERC4626(SwapLib.STUSD).deposit(amountUSDA, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

library Utils {
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/ISpotOracle.sol";
import "./OracleInterfaceID.sol";

abstract contract AbstractOracle is Ownable, ERC165Storage, OracleInterfaceID, ISpotOracle {
    constructor() {
        _registerInterface(_getOracleInterfaceID());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythErrors.sol";
import "../libraries/ABDKMath64x64.sol";
import "./SpotOracle.sol";

contract OracleFactory is Ownable, OracleInterfaceID {
    using ERC165Checker for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ABDKMath64x64 for int128;

    // solhint-disable-next-line const-name-snakecase
    int128 internal constant ONE_64x64 = 0x10000000000000000; // 2^64

    uint256 internal immutable maxFeedTimeGapSec;

    address public immutable pyth;
    address public immutable onDemandFeed;

    struct OracleData {
        address oracle;
        bool isInverse;
    }

    // baseCurrency => quoteCurrency => oracles' addresses
    mapping(bytes4 => mapping(bytes4 => OracleData[])) internal routes;
    // price Id => address of spot oracle with that id
    mapping(bytes32 => address) internal oracles;

    event OracleCreated(bytes4 baseCurrency, bytes4 quoteCurrency, address oracle);
    event OracleAdded(bytes4 baseCurrency, bytes4 quoteCurrency, address oracle);
    event ShortRouteAdded(bytes4 baseCurrency, bytes4 quoteCurrency, address oracle);
    event RouteAdded(
        bytes4 baseCurrency,
        bytes4 quoteCurrency,
        address[] oracle,
        bool[] isInverse
    );
    event SetMarketClosed(
        bytes4 baseCurrency,
        bytes4 quoteCurrency,
        address oracle,
        bool marketClosed
    );

    /**
     * @param _maxFeedTimeGapSec Maximum time difference between two feed updates until they are considered out of sync
     */
    constructor(
        uint256 _maxFeedTimeGapSec,
        address _pythFeedAddress,
        address _onDemandfeedAddress
    ) {
        require(_maxFeedTimeGapSec > 0, "max feed time> 0");
        maxFeedTimeGapSec = _maxFeedTimeGapSec;
        pyth = _pythFeedAddress;
        onDemandFeed = _onDemandfeedAddress;
    }

    /**
     * @notice Deploys Oracle contract for currency pair.
     * @dev The route for the given pair will be set (CANNOT BE overwritten if it was already set).
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _tradingBreakMins delay after which we consider mkt closed
     */
    function createOracle(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        uint16 _tradingBreakMins,
        address _feedAddress,
        bytes32 _priceId,
        uint256 _feedPeriod
    ) external virtual onlyOwner returns (address) {
        require(_baseCurrency != "", "invalid base currency");
        require(_quoteCurrency != 0, "invalid quote currency");
        require(_baseCurrency != _quoteCurrency, "base and quote should differ");
        require(_feedAddress == pyth || _feedAddress == onDemandFeed, "invalid feed");
        address oracle = address(
            new SpotOracle(
                _baseCurrency,
                _quoteCurrency,
                _tradingBreakMins,
                _feedAddress,
                _priceId,
                _feedPeriod
            )
        );
        oracles[_priceId] = oracle;
        //note: we don't transfer the ownership of the oracle, factory
        //      remains owner
        _setRoute(_baseCurrency, _quoteCurrency, oracle);

        //checks that price can be calculated
        _getSpotPrice(_baseCurrency, _quoteCurrency);

        emit OracleCreated(_baseCurrency, _quoteCurrency, oracle);

        return oracle;
    }

    /**
     * @notice Sets Oracle contract for currency pair.
     * @dev The route for the given pair will be set (overwritten if it was already set).
     *
     * @param   _oracle   The Oracle contract (should implement ISpotOracle interface).
     */
    function addOracle(address _oracle) external onlyOwner {
        require(_oracle.supportsInterface(_getOracleInterfaceID()), "invalid oracle");

        bytes4 baseCurrency = ISpotOracle(_oracle).getBaseCurrency();
        bytes4 quoteCurrency = ISpotOracle(_oracle).getQuoteCurrency();
        _setRoute(baseCurrency, quoteCurrency, _oracle);

        //checks that price can be calculated
        _getSpotPrice(baseCurrency, quoteCurrency);
        emit OracleAdded(baseCurrency, quoteCurrency, _oracle);
    }

    /**
     * @notice Sets Oracle as a shortest route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _oracle         The Oracle contract (should implement ISpotOracle interface).
     */
    function _setRoute(bytes4 _baseCurrency, bytes4 _quoteCurrency, address _oracle) internal {
        require(routes[_baseCurrency][_quoteCurrency].length == 0, "route exists");
        delete routes[_baseCurrency][_quoteCurrency];
        delete oracles[ISpotOracle(_oracle).priceId()];
        routes[_baseCurrency][_quoteCurrency].push(OracleData(address(_oracle), false));
        oracles[ISpotOracle(_oracle).priceId()] = _oracle;
        emit ShortRouteAdded(_baseCurrency, _quoteCurrency, _oracle);
    }

    /**
     * setMarketClosed of short-route oracle
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _marketClosed   market closed or re-open
     */
    function setMarketClosed(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        bool _marketClosed
    ) external onlyOwner {
        require(routes[_baseCurrency][_quoteCurrency].length == 1, "only short routes");
        address spotOracle = routes[_baseCurrency][_quoteCurrency][0].oracle;
        ISpotOracle(spotOracle).setMarketClosed(_marketClosed);
        emit SetMarketClosed(_baseCurrency, _quoteCurrency, spotOracle, _marketClosed);
    }

    /**
     * @notice Sets the given array of oracles as a route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _oracles        The array Oracle contracts.
     * @param   _isInverse      The array of flags whether price is inverted.
     */
    function addRoute(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        address[] calldata _oracles,
        bool[] calldata _isInverse
    ) external onlyOwner {
        _validateRoute(_baseCurrency, _quoteCurrency, _oracles, _isInverse);

        uint256 length = _oracles.length;
        require(routes[_baseCurrency][_quoteCurrency].length == 0, "route exists");
        for (uint256 i = 0; i < length; i++) {
            routes[_baseCurrency][_quoteCurrency].push(OracleData(_oracles[i], _isInverse[i]));
            oracles[ISpotOracle(_oracles[i]).priceId()] = _oracles[i];
        }

        //checks that price can be calculated
        _getSpotPrice(_baseCurrency, _quoteCurrency);

        emit RouteAdded(_baseCurrency, _quoteCurrency, _oracles, _isInverse);
    }

    /**
     * @notice Validates the given array of oracles as a route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _oracles        The array Oracle contracts.
     * @param   _isInverse      The array of flags whether price is inverted.
     */
    function _validateRoute(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        address[] calldata _oracles,
        bool[] calldata _isInverse
    ) internal view {
        uint256 length = _oracles.length;
        require(length > 0, "no oracles");
        require(length == _isInverse.length, "arrays mismatch");

        bytes4 srcCurrency;
        bytes4 destCurrency;
        require(_oracles[0].supportsInterface(_getOracleInterfaceID()), "invalid oracle [1]");
        if (!_isInverse[0]) {
            srcCurrency = ISpotOracle(_oracles[0]).getBaseCurrency();
            require(_baseCurrency == srcCurrency, "invalid route [1]");
            destCurrency = ISpotOracle(_oracles[0]).getQuoteCurrency();
        } else {
            srcCurrency = ISpotOracle(_oracles[0]).getQuoteCurrency();
            require(_baseCurrency == srcCurrency, "invalid route [2]");
            destCurrency = ISpotOracle(_oracles[0]).getBaseCurrency();
        }
        for (uint256 i = 1; i < length; i++) {
            require(_oracles[i].supportsInterface(_getOracleInterfaceID()), "invalid oracle [2]");
            bytes4 oracleBaseCurrency = ISpotOracle(_oracles[i]).getBaseCurrency();
            bytes4 oracleQuoteCurrency = ISpotOracle(_oracles[i]).getQuoteCurrency();
            if (!_isInverse[i]) {
                require(destCurrency == oracleBaseCurrency, "invalid route [3]");
                destCurrency = oracleQuoteCurrency;
            } else {
                require(destCurrency == oracleQuoteCurrency, "invalid route [4]");
                destCurrency = oracleBaseCurrency;
            }
        }
        require(_quoteCurrency == destCurrency, "invalid route [5]");
    }

    /**
     * @notice Returns the route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     */
    function getRoute(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency
    ) external view returns (OracleData[] memory) {
        return routes[_baseCurrency][_quoteCurrency];
    }

    /**
     * @notice Calculates spot price.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     */
    function getSpotPrice(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency
    ) external view returns (int128, uint256) {
        return _getSpotPrice(_baseCurrency, _quoteCurrency);
    }

    /**
     * @notice Determines if a route from _baseCurrency to _quoteCurrency exists
     * @param _baseCurrency The base currency symbol
     * @param _quoteCurrency The quote currency symbol
     */
    function existsRoute(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency
    ) external view returns (bool) {
        OracleData[] storage routeOracles = routes[_baseCurrency][_quoteCurrency];
        return routeOracles.length > 0;
    }

    /**
     * @notice Returns the spot price of one _baseCurrency in _quoteCurrency.
     *
     * @dev Price can be zero which needs to be captured outside this function
     * @param _baseCurrency in bytes4 representation
     * @param _quoteCurrency in bytes4 representation
     * @return fPrice Oracle price
     * @return timestamp Oracle timestamp
     */
    function _getSpotPrice(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency
    ) internal view returns (int128 fPrice, uint256 timestamp) {
        OracleData[] storage routeOracles = routes[_baseCurrency][_quoteCurrency];
        uint256 length = routeOracles.length;
        bool isInverse;
        if (length == 0) {
            routeOracles = routes[_quoteCurrency][_baseCurrency];
            length = routeOracles.length;
            require(length > 0, "route not found");
            isInverse = true;
        }

        fPrice = ONE_64x64;
        int128 oraclePrice;
        uint256 oracleTimestamp;
        for (uint256 i = 0; i < length; i++) {
            OracleData storage oracleData = routeOracles[i];
            (oraclePrice, oracleTimestamp) = ISpotOracle(oracleData.oracle).getSpotPrice();
            timestamp = oracleTimestamp < timestamp || timestamp == 0
                ? oracleTimestamp
                : timestamp;
            if (oraclePrice == 0) {
                //e.g. market closed
                return (0, timestamp);
            }
            if (!oracleData.isInverse) {
                fPrice = fPrice.mul(oraclePrice);
            } else {
                fPrice = fPrice.div(oraclePrice);
            }
        }
        if (isInverse) {
            fPrice = ONE_64x64.div(fPrice);
        }
    }

    /**
     * @notice Returns the ids used to determine the price of a given currency pair
     * @param _baseQuote Currency pair
     */
    function getRouteIds(
        bytes4[2] calldata _baseQuote
    ) external view returns (bytes32[] memory, bool[] memory) {
        // try direct route first
        OracleData[] storage route = routes[_baseQuote[0]][_baseQuote[1]];
        uint256 numFeeds = route.length;
        if (numFeeds == 0) {
            // inverse
            route = routes[_baseQuote[1]][_baseQuote[0]];
            numFeeds = route.length;
        }
        // slice
        bytes32[] memory id = new bytes32[](numFeeds);
        bool[] memory isPyth = new bool[](numFeeds);
        for (uint256 i = 0; i < numFeeds; i++) {
            address oracle = route[i].oracle;
            id[i] = ISpotOracle(oracle).priceId();
            isPyth[i] = ISpotOracle(oracle).priceFeed() == pyth;
        }
        return (id, isPyth);
    }

    /**
     * @dev Checks that the time submitted satisfies the age requirement, with the necessary overrides
     * @param _publishTime Timestamp in seconds
     * @param _maxAcceptableFeedAge Maximal age that the caller would accept (in seconds)
     * @param _oracle Address of the spot oracle
     */
    function _checkPublishTime(
        uint64 _publishTime,
        uint256 _maxAcceptableFeedAge,
        address _oracle
    ) internal view returns (address priceFeed) {
        priceFeed = ISpotOracle(_oracle).priceFeed();
        // check age of updates:
        // 1) max age set by Oracle
        uint256 maxAgeSec = IPyth(priceFeed).getValidTimePeriod();
        // 2) caller's required feed age in seconds
        // choose feed's age if _maxAcceptableFeedAge not given (0), else use _maxAcceptableFeedAge capped at feed's valid age
        maxAgeSec = _maxAcceptableFeedAge == 0 || _maxAcceptableFeedAge > maxAgeSec
            ? maxAgeSec
            : _maxAcceptableFeedAge;
        // some feeds (e.g. USDC) might be updating slower than requested,
        // hence maxAgeSec can be overruled by the slower time from the feed
        uint256 overrideAge = ISpotOracle(_oracle).feedPeriod();
        overrideAge = maxAgeSec < overrideAge ? overrideAge : maxAgeSec;
        require(_publishTime + overrideAge >= block.timestamp, "updt too old");
    }

    /**
     * @dev Performs the actual price submission to the price feed.
     * Feed addresses are determined at deploy-time and are not arbitrary.
     * @param _isPyth True if shold submit the updates to the pyth proxy
     * @param _fee how much fee to send
     * @param _updates update data
     * @param _ids price ids to update
     * @param _times publish times of updates
     */
    function _submitUpdates(
        bool _isPyth,
        uint256 _fee,
        bytes[] memory _updates,
        bytes32[] memory _ids,
        uint64[] memory _times
    ) internal returns (bool needed) {
        address feed = _isPyth ? pyth : onDemandFeed;
        // slither-disable-next-line arbitrary-send-eth
        try IPyth(feed).updatePriceFeedsIfNecessary{ value: _fee }(_updates, _ids, _times) {
            needed = true;
        } catch (bytes memory _err) {
            if (PythErrors.NoFreshUpdate.selector == bytes32(_err)) {
                // reverted because no update is needed
                needed = false;
            } else {
                revert("invalid updt");
            }
        }
    }

    /**
     * @notice Update price feeds.
     *
     * @dev Reverts if update is invalid, not paid for, or unnecessary.
     * 1) if _blockAge is zero, publish times only need to be compatible with the price feed requirements,
     * 2) if _blockAge > 0, the update data should not be older than the given age based on the minimal blocktime:
     *     publish TS + maximum age >= current TS
     * 3) publish TSs must be close to each other (within 2 blocktimes)
     * @param _updateData Update data
     * @param _priceIds Ids of the feeds to update
     * @param _publishTimes Timestamps of each update
     * @param _maxAcceptableFeedAge maximal age that the caller of this function would accept (in seconds) can be
     *  overriden to an older age by ISpotOracle(oracle).feedPeriod()
     */
    function updatePriceFeeds(
        bytes[] calldata _updateData,
        bytes32[] calldata _priceIds,
        uint64[] calldata _publishTimes,
        uint256 _maxAcceptableFeedAge
    ) external payable {
        // check data size
        require(_updateData.length > 0, "no data");
        require(
            _priceIds.length == _updateData.length && _updateData.length == _publishTimes.length,
            "array mismatch"
        );

        // check publish times, and count how many pyth oracles there are
        uint256 numPythOracles;
        {
            // first oracle
            uint256 oldest = _publishTimes[0];
            uint256 latest = _publishTimes[0];
            address oracle = oracles[_priceIds[0]];
            require(oracle != address(0), "no oracle for price id");
            if (_checkPublishTime(_publishTimes[0], _maxAcceptableFeedAge, oracle) == pyth) {
                numPythOracles = 1;
            }
            // all others (if any)
            for (uint256 i = 1; i < _publishTimes.length; i++) {
                // check we know the id
                oracle = oracles[_priceIds[i]];
                require(oracle != address(0), "no oracle for price id");
                // checlk publish times and age
                if (_checkPublishTime(_publishTimes[i], _maxAcceptableFeedAge, oracle) == pyth) {
                    numPythOracles += 1;
                }
                // track latest and oldest publish times
                oldest = oldest < _publishTimes[i] ? oldest : _publishTimes[i];
                latest = latest > _publishTimes[i] ? latest : _publishTimes[i];
            }
            require(latest <= oldest + maxFeedTimeGapSec, "not in sync");
        }

        // if all pyth or not-pyth, pass-through to the corresponding feed
        if (numPythOracles == _priceIds.length || numPythOracles == 0) {
            address priceFeed = numPythOracles == 0 ? onDemandFeed : pyth;
            // we send the whole msg.value
            uint256 fee = IPyth(priceFeed).getUpdateFee(_updateData);
            require(fee <= msg.value, "insufficient fee");
            if (!_submitUpdates(numPythOracles > 0, fee, _updateData, _priceIds, _publishTimes)) {
                revert("not needed");
            }
        } else {
            // it's a mix, so we need to do two rounds of submissions
            bool needed;
            uint256 pythFee;
            {
                // pyth first
                bytes[] memory updates = new bytes[](numPythOracles);
                bytes32[] memory ids = new bytes32[](numPythOracles);
                uint64[] memory times = new uint64[](numPythOracles);

                uint256 j;
                for (uint256 i = 0; j < numPythOracles && i < _priceIds.length; i++) {
                    if (ISpotOracle(oracles[_priceIds[i]]).priceFeed() == pyth) {
                        updates[j] = _updateData[i];
                        ids[j] = _priceIds[i];
                        times[j] = _publishTimes[i];
                        j++;
                    }
                }
                pythFee = IPyth(pyth).getUpdateFee(updates);
                require(pythFee < msg.value, "insufficient fee");
                needed = _submitUpdates(true, pythFee, updates, ids, times);
            }
            {
                // remaining oracles
                // note: variable is reused to save storage, but this is NOT pyth
                numPythOracles = _priceIds.length - numPythOracles;
                bytes[] memory updates = new bytes[](numPythOracles);
                bytes32[] memory ids = new bytes32[](numPythOracles);
                uint64[] memory times = new uint64[](numPythOracles);
                uint256 j;
                for (uint256 i = 0; j < numPythOracles && i < _priceIds.length; i++) {
                    if (ISpotOracle(oracles[_priceIds[i]]).priceFeed() == onDemandFeed) {
                        updates[j] = _updateData[i];
                        ids[j] = _priceIds[i];
                        times[j] = _publishTimes[i];
                        j++;
                    }
                }
                uint256 onDemandFee = IPyth(onDemandFeed).getUpdateFee(updates);
                require(onDemandFee + pythFee <= msg.value, "insufficient fee");
                bool t = _submitUpdates(false, onDemandFee, updates, ids, times);
                needed = needed || t;
            }
            if (!needed) revert("not needed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../interface/ISpotOracle.sol";

contract OracleInterfaceID {
    function _getOracleInterfaceID() internal pure returns (bytes4) {
        ISpotOracle i;
        return
            i.isMarketClosed.selector ^
            i.getSpotPrice.selector ^
            i.getBaseCurrency.selector ^
            i.getQuoteCurrency.selector ^
            i.priceFeed.selector ^
            i.priceId.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "./AbstractOracle.sol";
import "../libraries/ConverterDec18.sol";

/**
 *  Spot oracle has different states:
 *  - market is closed: if explicitely set, the price returns 0
 *  - the price can return 0 at any point in time. This is considered as "market closed" and
 *    must be handled outside the oracle
 */
contract SpotOracle is AbstractOracle {
    using ConverterDec18 for int256;
    using ERC165Checker for address;

    bytes4 private immutable baseCurrency;
    bytes4 private immutable quoteCurrency;

    // @dev either pyth or on-demand, not both at the same time
    address public immutable priceFeed;
    bytes32 public immutable priceId;
    uint256 public immutable feedPeriod;

    uint64 private timestampClosed;

    // if a price is older than tradingBreakMins, the market is considered
    // closed and the price returns zero.
    // For example, if equities trade weekdays from 9am to 5pm, the trading break
    // is 16 hours (from 5pm to 9am) and we could set _tradingBreakMins
    // to 8 hours * 60. For crypto that trades 24/7 we could set it to 1h.
    uint16 private immutable tradingBreakMins;

    bool private marketClosed;

    constructor(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        uint16 _tradingBreakMins,
        address _priceFeed,
        bytes32 _priceId,
        uint256 _period
    ) {
        require(_tradingBreakMins > 1, "too small");
        require(_priceFeed != address(0), "invalid price feed");
        require(_period < 60 * _tradingBreakMins, "period too long");
        baseCurrency = _baseCurrency;
        quoteCurrency = _quoteCurrency;
        tradingBreakMins = _tradingBreakMins;
        priceFeed = _priceFeed;
        priceId = _priceId;
        feedPeriod = _period;
    }

    /**
     * @dev Sets the market is closed flag.
     */
    function setMarketClosed(bool _marketClosed) external override onlyOwner {
        marketClosed = _marketClosed;
        timestampClosed = uint64(block.timestamp);
    }

    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external view override returns (bool) {
        (int128 price, ) = getSpotPrice();
        return price == 0;
    }

    /**
     *  Spot price.
     *  Returns 0 if market is closed
     */
    function getSpotPrice() public view virtual override returns (int128 fPrice, uint256 ts) {
        if (marketClosed) {
            return (0, timestampClosed);
        }
        PythStructs.Price memory pythPrice = IPyth(priceFeed).getPriceUnsafe(priceId);
        ts = pythPrice.publishTime;
        // price is zero unless the market on break and feed price is not positive
        if (pythPrice.price > 0 && ts + tradingBreakMins * 60 >= block.timestamp) {
            // price = pythPrice.price * 10 ^ pythPrice.expo;
            int256 price = int256(pythPrice.price) * int256(0x010000000000000000); // x * 2^64
            int256 decimals = int256(
                pythPrice.expo < 0 ? 10 ** uint32(-pythPrice.expo) : 10 ** uint32(pythPrice.expo)
            );
            price = pythPrice.expo < 0 ? price / decimals : price * decimals;
            fPrice = int128(price);
            require(fPrice > 0, "price overflow");
        }
    }

    /**
     * Get base currency symbol.
     */
    function getBaseCurrency() external view override returns (bytes4) {
        return baseCurrency;
    }

    /**
     * Get quote currency symbol.
     */
    function getQuoteCurrency() external view override returns (bytes4) {
        return quoteCurrency;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../../interface/IShareTokenFactory.sol";
import "../../libraries/ABDKMath64x64.sol";
import "./../functions/AMMPerpLogic.sol";
import "../../libraries/EnumerableSetUpgradeable.sol";
import "../../libraries/EnumerableBytes4Set.sol";
import "../../governance/Maintainable.sol";

/* solhint-disable max-states-count */
contract PerpStorage is Maintainable, Pausable, ReentrancyGuard {
    using ABDKMath64x64 for int128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableBytes4Set for EnumerableBytes4Set.Bytes4Set; // enumerable map of bytes4 or addresses
    /**
     * @notice  Perpetual state:
     *          - INVALID:      Uninitialized or not non-existent perpetual.
     *          - INITIALIZING: Only when LiquidityPoolData.isRunning == false. Traders cannot perform operations.
     *          - NORMAL:       Full functional state. Traders are able to perform all operations.
     *          - EMERGENCY:    Perpetual is unsafe and the perpetual needs to be settled.
     *          - SETTLE:       Perpetual ready to be settled
     *          - CLEARED:      All margin accounts are cleared. Traders can withdraw remaining margin balance.
     */
    enum PerpetualState {
        INVALID,
        INITIALIZING,
        NORMAL,
        EMERGENCY,
        SETTLE,
        CLEARED
    }

    // margin and liquidity pool are held in 'collateral currency' which can be either of
    // quote currency, base currency, or quanto currency
    // solhint-disable-next-line const-name-snakecase
    int128 internal constant ONE_64x64 = 0x10000000000000000; // 2^64
    int128 internal constant FUNDING_INTERVAL_SEC = 0x70800000000000000000; //3600 * 8 * 0x10000000000000000 = 8h in seconds scaled by 2^64 for ABDKMath64x64
    int128 internal constant MIN_NUM_LOTS_PER_POSITION = 0x0a0000000000000000; // 10, minimal position size in number of lots
    uint8 internal constant MASK_ORDER_CANCELLED = 0x1;
    uint8 internal constant MASK_ORDER_EXECUTED = 0x2;
    // at target, 1% of missing amount is transferred
    // at every rebalance
    uint8 internal iPoolCount;
    // delay required for trades to mitigate oracle front-running in seconds
    uint8 internal iTradeDelaySec;
    address internal ammPerpLogic;

    IShareTokenFactory internal shareTokenFactory;

    //pool id (incremental index, starts from 1) => pool data
    mapping(uint8 => LiquidityPoolData) internal liquidityPools;

    //perpetual id  => pool id
    mapping(uint24 => uint8) internal perpetualPoolIds;

    address internal orderBookFactory;

    /**
     * @notice  Data structure to store oracle price data.
     */
    struct PriceTimeData {
        int128 fPrice;
        uint64 time;
    }

    /**
     * @notice  Data structure to store user margin information.
     */
    struct MarginAccount {
        int128 fLockedInValueQC; // unrealized value locked-in when trade occurs
        int128 fCashCC; // cash in collateral currency (base, quote, or quanto)
        int128 fPositionBC; // position in base currency (e.g., 1 BTC for BTCUSD)
        int128 fUnitAccumulatedFundingStart; // accumulated funding rate
    }

    /**
     * @notice  Store information for a given perpetual market.
     */
    struct PerpetualData {
        // ------ 0
        uint8 poolId;
        uint24 id;
        int32 fInitialMarginRate; //parameter: initial margin
        int32 fSigma2; // parameter: volatility of base-quote pair
        uint32 iLastFundingTime; //timestamp since last funding rate payment
        int32 fDFCoverNRate; // parameter: cover-n rule for default fund. E.g., fDFCoverNRate=0.05 -> we try to cover 5% of active accounts with default fund
        int32 fMaintenanceMarginRate; // parameter: maintenance margin
        PerpetualState state; // Perpetual AMM state
        AMMPerpLogic.CollateralCurrency eCollateralCurrency; //parameter: in what currency is the collateral held?
        // uint16 minimalSpreadTbps; //parameter: minimal spread between long and short perpetual price
        // ------ 1
        bytes4 S2BaseCCY; //base currency of S2
        bytes4 S2QuoteCCY; //quote currency of S2
        uint16 incentiveSpreadTbps; //parameter: maximum spread added to the PD
        uint16 minimalSpreadTbps; //parameter: minimal spread between long and short perpetual price
        bytes4 S3BaseCCY; //base currency of S3
        bytes4 S3QuoteCCY; //quote currency of S3
        int32 fSigma3; // parameter: volatility of quanto-quote pair
        int32 fRho23; // parameter: correlation of quanto/base returns
        uint16 liquidationPenaltyRateTbps; //parameter: penalty if AMM closes the position and not the trader
        //------- 2
        PriceTimeData currentMarkPremiumRate; //relative diff to index price EMA, used for markprice.
        //------- 3
        int128 premiumRatesEMA; // EMA of premium rate
        int128 fUnitAccumulatedFunding; //accumulated funding in collateral currency
        //------- 4
        int128 fOpenInterest; //open interest is the larger of the amount of long and short positions in base currency
        int128 fTargetAMMFundSize; //target liquidity pool funds to allocate to the AMM
        //------- 5
        int128 fCurrentTraderExposureEMA; // trade amounts (storing absolute value)
        int128 fCurrentFundingRate; // current instantaneous funding rate
        //------- 6
        int128 fLotSizeBC; //parameter: minimal trade unit (in base currency) to avoid dust positions
        int128 fReferralRebateCC; //parameter: referral rebate in collateral currency
        //------- 7
        int128 fTargetDFSize; // target default fund size
        int128 fkStar; // signed trade size that minimizes the AMM risk
        //------- 8
        int128 fAMMTargetDD; // parameter: target distance to default (=inverse of default probability)
        int128 perpFlags; // flags for the perpetual
        //------- 9
        int128 fMinimalTraderExposureEMA; // parameter: minimal value for fCurrentTraderExposureEMA that we don't want to undershoot
        int128 fMinimalAMMExposureEMA; // parameter: minimal abs value for fCurrentAMMExposureEMA that we don't want to undershoot
        //------- 10
        int128 fSettlementS3PriceData; //quanto index
        int128 fSettlementS2PriceData; //base-quote pair. Used as last price in normal state.
        //------- 11
        int128 fTotalMarginBalance; //calculated for settlement, in collateral currency
        int32 fMarkPriceEMALambda; // parameter: Lambda parameter for EMA used in mark-price for funding rates
        int32 fFundingRateClamp; // parameter: funding rate clamp between which we charge 1bps
        int32 fMaximalTradeSizeBumpUp; // parameter: >1, users can create a maximal position of size fMaximalTradeSizeBumpUp*fCurrentAMMExposureEMA
        uint32 iLastTargetPoolSizeTime; //timestamp (seconds) since last update of fTargetDFSize and fTargetAMMFundSize
        //------- 12

        //-------
        int128[2] fStressReturnS3; // parameter: negative and positive stress returns for quanto-quote asset
        int128[2] fDFLambda; // parameter: EMA lambda for AMM and trader exposure K,k: EMA*lambda + (1-lambda)*K. 0 regular lambda, 1 if current value exceeds past
        int128[2] fCurrentAMMExposureEMA; // 0: negative aggregated exposure (storing negative value), 1: positive
        int128[2] fStressReturnS2; // parameter: negative and positive stress returns for base-quote asset
        // -----
    }

    address internal oracleFactoryAddress;

    // users
    mapping(uint24 => EnumerableSetUpgradeable.AddressSet) internal activeAccounts; //perpetualId => traderAddressSet
    // accounts
    mapping(uint24 => mapping(address => MarginAccount)) internal marginAccounts;
    // delegates
    mapping(address => address) internal delegates;

    // broker maps: poolId -> brokeraddress-> lots contributed
    // contains non-zero entries for brokers. Brokers pay default fund contributions.
    mapping(uint8 => mapping(address => uint32)) internal brokerMap;

    struct LiquidityPoolData {
        bool isRunning; // state
        uint8 iPerpetualCount; // state
        uint8 id; // parameter: index, starts from 1
        int32 fCeilPnLShare; // parameter: cap on the share of PnL allocated to liquidity providers
        uint8 marginTokenDecimals; // parameter: decimals of margin token, inferred from token contract
        uint16 iTargetPoolSizeUpdateTime; //parameter: timestamp in seconds. How often we update the pool's target size
        address marginTokenAddress; //parameter: address of the margin token
        // -----
        uint64 prevAnchor; // state: keep track of timestamp since last withdrawal was initiated
        int128 fRedemptionRate; // state: used for settlement in case of AMM default
        address shareTokenAddress; // parameter
        // -----
        int128 fPnLparticipantsCashCC; // state: addLiquidity/withdrawLiquidity + profit/loss - rebalance
        int128 fTargetAMMFundSize; // state: target liquidity for all perpetuals in pool (sum)
        // -----
        int128 fDefaultFundCashCC; // state: profit/loss
        int128 fTargetDFSize; // state: target default fund size for all perpetuals in pool
        // -----
        int128 fBrokerCollateralLotSize; // param:how much collateral do brokers deposit when providing "1 lot" (not trading lot)
        uint128 prevTokenAmount; // state
        // -----
        uint128 nextTokenAmount; // state
        uint128 totalSupplyShareToken; // state
        // -----
        int128 fBrokerFundCashCC; // state: amount of cash in broker fund
    }

    address internal treasuryAddress; // address for the protocol treasury

    //pool id => perpetual id list
    mapping(uint8 => uint24[]) internal perpetualIds;

    //pool id => perpetual id => data
    mapping(uint8 => mapping(uint24 => PerpetualData)) internal perpetuals;

    /// @dev flag whether MarginTradeOrder was already executed or cancelled
    mapping(bytes32 => uint8) internal executedOrCancelledOrders;

    //proxy
    mapping(bytes32 => EnumerableBytes4Set.Bytes4Set) internal moduleActiveFuncSignatureList;
    mapping(bytes32 => address) internal moduleNameToAddress;
    mapping(address => bytes32) internal moduleAddressToModuleName;

    // fee structure
    struct VolumeEMA {
        int128 fTradingVolumeEMAusd; //trading volume EMA in usd
        uint64 timestamp; // timestamp of last trade
    }

    uint256[] public traderVolumeTiers; // dec18, regardless of token
    uint256[] public brokerVolumeTiers; // dec18, regardless of token
    uint16[] public traderVolumeFeesTbps;
    uint16[] public brokerVolumeFeesTbps;
    mapping(uint24 => address) public perpBaseToUSDOracle;
    mapping(uint24 => int128) public perpToLastBaseToUSD;
    mapping(uint8 => mapping(address => VolumeEMA)) public traderVolumeEMA;
    mapping(uint8 => mapping(address => VolumeEMA)) public brokerVolumeEMA;
    uint64 public lastBaseToUSDUpdateTs;

    // liquidity withdrawals
    struct WithdrawRequest {
        address lp;
        uint256 shareTokens;
        uint64 withdrawTimestamp;
    }

    mapping(address => mapping(uint8 => WithdrawRequest)) internal lpWithdrawMap;

    // users who initiated withdrawals are registered here
    mapping(uint8 => EnumerableSetUpgradeable.AddressSet) internal activeWithdrawals; //poolId => lpAddressSet

    mapping(uint8 => bool) public liquidityProvisionIsPaused;
}
/* solhint-enable max-states-count */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../../libraries/ABDKMath64x64.sol";
import "../../libraries/ConverterDec18.sol";
import "../../perpetual/interfaces/IAMMPerpLogic.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AMMPerpLogic is Ownable, IAMMPerpLogic {
    using ABDKMath64x64 for int128;
    /* solhint-disable const-name-snakecase */
    int128 internal constant ONE_64x64 = 0x10000000000000000; // 2^64
    int128 internal constant TWO_64x64 = 0x20000000000000000; // 2*2^64
    int128 internal constant FOUR_64x64 = 0x40000000000000000; //4*2^64
    int128 internal constant HALF_64x64 = 0x8000000000000000; //0.5*2^64
    int128 internal constant TWENTY_64x64 = 0x140000000000000000; //20*2^64
    int128 private constant CDF_CONST_0 = 0x023a6ce358298c;
    int128 private constant CDF_CONST_1 = -0x216c61522a6f3f;
    int128 private constant CDF_CONST_2 = 0xc9320d9945b6c3;
    int128 private constant CDF_CONST_3 = -0x01bcfd4bf0995aaf;
    int128 private constant CDF_CONST_4 = -0x086de76427c7c501;
    int128 private constant CDF_CONST_5 = 0x749741d084e83004;
    int128 private constant CDF_CONST_6 = 0xcc42299ea1b28805;
    int128 private constant CDF_CONST_7 = 0x0281b263fec4e0a007;
    int128 private constant EXPM1_Q0 = 0x0a26c00000000000000000;
    int128 private constant EXPM1_Q1 = 0x0127500000000000000000;
    int128 private constant EXPM1_P0 = 0x0513600000000000000000;
    int128 private constant EXPM1_P1 = 0x27600000000000000000;
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /* solhint-enable const-name-snakecase */

    enum CollateralCurrency {
        QUOTE,
        BASE,
        QUANTO
    }

    struct AMMVariables {
        // all variables are
        // signed 64.64-bit fixed point number
        int128 fLockedValue1; // L1 in quote currency
        int128 fPoolM1; // M1 in quote currency
        int128 fPoolM2; // M2 in base currency
        int128 fPoolM3; // M3 in quanto currency
        int128 fAMM_K2; // AMM exposure (positive if trader long)
        int128 fCurrentTraderExposureEMA; // current average unsigned trader exposure
    }

    struct MarketVariables {
        int128 fIndexPriceS2; // base index
        int128 fIndexPriceS3; // quanto index
        int128 fSigma2; // standard dev of base currency
        int128 fSigma3; // standard dev of quanto currency
        int128 fRho23; // correlation base/quanto currency
    }

    /**
     * Calculate a EWMA when the last observation happened n periods ago
     * @dev Given is x_t = (1 - lambda) * mean + lambda * x_t-1, and x_0 = _newObs
     * it returns the value of x_deltaTime
     * @param _mean long term mean
     * @param _newObs observation deltaTime periods ago
     * @param _fLambda lambda of the EWMA
     * @param _deltaTime number of periods elapsed
     * @return result EWMA at deltaPeriods
     */
    function _emaWithTimeJumps(
        uint16 _mean,
        uint16 _newObs,
        int128 _fLambda,
        uint256 _deltaTime
    ) internal pure returns (int128 result) {
        _fLambda = _fLambda.pow(_deltaTime);
        result = ConverterDec18.tbpsToABDK(_mean).mul(ONE_64x64.sub(_fLambda));
        result = result.add(_fLambda.mul(ConverterDec18.tbpsToABDK(_newObs)));
    }

    /**
     *  Calculate the normal CDF value of _fX, i.e.,
     *  k=P(X<=_fX), for X~normal(0,1)
     *  The approximation is of the form
     *  Phi(x) = 1 - phi(x) / (x + exp(p(x))),
     *  where p(x) is a polynomial of degree 6
     *  @param _fX signed 64.64-bit fixed point number
     *  @return fY approximated normal-cdf evaluated at X
     */
    function _normalCDF(int128 _fX) internal pure returns (int128 fY) {
        bool isNegative = _fX < 0;
        if (isNegative) {
            _fX = _fX.neg();
        }
        if (_fX > FOUR_64x64) {
            fY = int128(0);
        } else {
            fY = _fX.mul(CDF_CONST_0).add(CDF_CONST_1);
            fY = _fX.mul(fY).add(CDF_CONST_2);
            fY = _fX.mul(fY).add(CDF_CONST_3);
            fY = _fX.mul(fY).add(CDF_CONST_4);
            fY = _fX.mul(fY).add(CDF_CONST_5).mul(_fX).neg().exp();
            fY = fY.mul(CDF_CONST_6).add(_fX);
            fY = _fX.mul(_fX).mul(HALF_64x64).neg().exp().div(CDF_CONST_7).div(fY);
        }
        if (!isNegative) {
            fY = ONE_64x64.sub(fY);
        }
        return fY;
    }

    /**
     *  Calculate the target size for the default fund
     *
     *  @param _fK2AMM       signed 64.64-bit fixed point number, Conservative negative[0]/positive[1] AMM exposure
     *  @param _fk2Trader    signed 64.64-bit fixed point number, Conservative (absolute) trader exposure
     *  @param _fCoverN      signed 64.64-bit fixed point number, cover-n rule for default fund parameter
     *  @param fStressRet2   signed 64.64-bit fixed point number, negative[0]/positive[1] stress returns for base/quote pair
     *  @param fStressRet3   signed 64.64-bit fixed point number, negative[0]/positive[1] stress returns for quanto/quote currency
     *  @param fIndexPrices  signed 64.64-bit fixed point number, spot price for base/quote[0] and quanto/quote[1] pairs
     *  @param _eCCY         enum that specifies in which currency the collateral is held: QUOTE, BASE, QUANTO
     *  @return approximated normal-cdf evaluated at X
     */
    function calculateDefaultFundSize(
        int128[2] memory _fK2AMM,
        int128 _fk2Trader,
        int128 _fCoverN,
        int128[2] memory fStressRet2,
        int128[2] memory fStressRet3,
        int128[2] memory fIndexPrices,
        AMMPerpLogic.CollateralCurrency _eCCY
    ) external pure override returns (int128) {
        require(_fK2AMM[0] < 0, "_fK2AMM[0] must be negative");
        require(_fK2AMM[1] > 0, "_fK2AMM[1] must be positive");
        require(_fk2Trader > 0, "_fk2Trader must be positive");

        int128[2] memory fEll;
        // downward stress scenario
        fEll[0] = (_fK2AMM[0].abs().add(_fk2Trader.mul(_fCoverN))).mul(
            ONE_64x64.sub((fStressRet2[0].exp()))
        );
        // upward stress scenario
        fEll[1] = (_fK2AMM[1].abs().add(_fk2Trader.mul(_fCoverN))).mul(
            (fStressRet2[1].exp().sub(ONE_64x64))
        );
        int128 fIstar;
        if (_eCCY == AMMPerpLogic.CollateralCurrency.BASE) {
            fIstar = fEll[0].div(fStressRet2[0].exp());
            int128 fI2 = fEll[1].div(fStressRet2[1].exp());
            if (fI2 > fIstar) {
                fIstar = fI2;
            }
        } else if (_eCCY == AMMPerpLogic.CollateralCurrency.QUANTO) {
            fIstar = fEll[0].div(fStressRet3[0].exp());
            int128 fI2 = fEll[1].div(fStressRet3[1].exp());
            if (fI2 > fIstar) {
                fIstar = fI2;
            }
            fIstar = fIstar.mul(fIndexPrices[0].div(fIndexPrices[1]));
        } else {
            assert(_eCCY == AMMPerpLogic.CollateralCurrency.QUOTE);
            if (fEll[0] > fEll[1]) {
                fIstar = fEll[0].mul(fIndexPrices[0]);
            } else {
                fIstar = fEll[1].mul(fIndexPrices[0]);
            }
        }
        return fIstar;
    }

    /**
     *  Calculate the risk neutral Distance to Default (Phi(DD)=default probability) when
     *  there is no quanto currency collateral.
     *  We assume r=0 everywhere.
     *  The underlying distribution is log-normal, hence the log below.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param fSigma2 current Market variables (price&params)
     *  @param _fSign signed 64.64-bit fixed point number, sign of denominator of distance to default
     *  @return _fThresh signed 64.64-bit fixed point number, number for which the log is the unnormalized distance to default
     */
    function _calculateRiskNeutralDDNoQuanto(
        int128 fSigma2,
        int128 _fSign,
        int128 _fThresh
    ) internal pure returns (int128) {
        require(_fThresh > 0, "argument to log must be >0");
        int128 _fLogTresh = _fThresh.ln();
        int128 fSigma2_2 = fSigma2.mul(fSigma2);
        int128 fMean = fSigma2_2.div(TWO_64x64).neg();
        int128 fDistanceToDefault = ABDKMath64x64.sub(_fLogTresh, fMean).div(fSigma2);
        // because 1-Phi(x) = Phi(-x) we change the sign if _fSign<0
        // now we would like to get the normal cdf of that beast
        if (_fSign < 0) {
            fDistanceToDefault = fDistanceToDefault.neg();
        }
        return fDistanceToDefault;
    }

    /**
     *  Calculate the standard deviation for the random variable
     *  evolving when quanto currencies are involved.
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _mktVars current Market variables (price&params)
     *  @param _fC3 signed 64.64-bit fixed point number current AMM/Market variables
     *  @param _fC3_2 signed 64.64-bit fixed point number, squared fC3
     *  @return fSigmaZ standard deviation, 64.64-bit fixed point number
     */
    function _calculateStandardDeviationQuanto(
        MarketVariables memory _mktVars,
        int128 _fC3,
        int128 _fC3_2
    ) internal pure returns (int128 fSigmaZ) {
        // fVarA = (exp(sigma2^2) - 1)
        int128 fVarA = _mktVars.fSigma2.mul(_mktVars.fSigma2);

        // fVarB = 2*(exp(sigma2*sigma3*rho) - 1)
        int128 fVarB = _mktVars.fSigma2.mul(_mktVars.fSigma3).mul(_mktVars.fRho23).mul(TWO_64x64);

        // fVarC = exp(sigma3^2) - 1
        int128 fVarC = _mktVars.fSigma3.mul(_mktVars.fSigma3);

        // sigmaZ = fVarA*C^2 + fVarB*C + fVarC
        fSigmaZ = fVarA.mul(_fC3_2).add(fVarB.mul(_fC3)).add(fVarC).sqrt();
    }

    /**
     *  Calculate the risk neutral Distance to Default (Phi(DD)=default probability) when
     *  presence of quanto currency collateral.
     *
     *  We approximate the distribution with a normal distribution
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number
     *  @param _ammVars current AMM/Market variables
     *  @param _mktVars current Market variables (price&params)
     *  @param _fSign 64.64-bit fixed point number, current AMM/Market variables
     *  @return fDistanceToDefault signed 64.64-bit fixed point number
     */
    function _calculateRiskNeutralDDWithQuanto(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fSign,
        int128 _fThresh
    ) internal pure returns (int128 fDistanceToDefault) {
        require(_fSign > 0, "no sign in quanto case");
        // 1) Calculate C3
        int128 fC3 = _mktVars.fIndexPriceS2.mul(_ammVars.fPoolM2.sub(_ammVars.fAMM_K2)).div(
            _ammVars.fPoolM3.mul(_mktVars.fIndexPriceS3)
        );
        int128 fC3_2 = fC3.mul(fC3);

        // 2) Calculate Variance
        int128 fSigmaZ = _calculateStandardDeviationQuanto(_mktVars, fC3, fC3_2);

        // 3) Calculate mean
        int128 fMean = fC3.add(ONE_64x64);
        // 4) Distance to default
        fDistanceToDefault = _fThresh.sub(fMean).div(fSigmaZ);
    }

    function calculateRiskNeutralPD(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fTradeAmount,
        bool _withCDF
    ) external view virtual override returns (int128, int128) {
        return _calculateRiskNeutralPD(_ammVars, _mktVars, _fTradeAmount, _withCDF);
    }

    /**
     *  Calculate the risk neutral default probability (>=0).
     *  Function decides whether pricing with or without quanto CCY is chosen.
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars         current AMM variables.
     *  @param _mktVars         current Market variables (price&params)
     *  @param _fTradeAmount    Trade amount (can be 0), hence amounts k2 are not already factored in
     *                          that is, function will set K2:=K2+k2, L1:=L1+k2*s2 (k2=_fTradeAmount)
     *  @param _withCDF         bool. If false, the normal-cdf is not evaluated (in case the caller is only
     *                          interested in the distance-to-default, this saves calculations)
     *  @return (default probabilit, distance to default) ; 64.64-bit fixed point numbers
     */
    function _calculateRiskNeutralPD(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fTradeAmount,
        bool _withCDF
    ) internal pure returns (int128, int128) {
        int128 dL = _fTradeAmount.mul(_mktVars.fIndexPriceS2);
        int128 dK = _fTradeAmount;
        _ammVars.fLockedValue1 = _ammVars.fLockedValue1.add(dL);
        _ammVars.fAMM_K2 = _ammVars.fAMM_K2.add(dK);
        // -L1 - k*s2 - M1
        int128 fNumerator = (_ammVars.fLockedValue1.neg()).sub(_ammVars.fPoolM1);
        // s2*(M2-k2-K2) if no quanto, else M3 * s3
        int128 fDenominator = _ammVars.fPoolM3 == 0
            ? (_ammVars.fPoolM2.sub(_ammVars.fAMM_K2)).mul(_mktVars.fIndexPriceS2)
            : _ammVars.fPoolM3.mul(_mktVars.fIndexPriceS3);
        // handle edge sign cases first
        int128 fThresh;
        if (_ammVars.fPoolM3 == 0) {
            if (fNumerator < 0) {
                if (fDenominator >= 0) {
                    // P( den * exp(x) < 0) = 0
                    return (int128(0), TWENTY_64x64.neg());
                } else {
                    // num < 0 and den < 0, and P(exp(x) > infty) = 0
                    int256 result = (int256(fNumerator) << 64) / fDenominator;
                    if (result > MAX_64x64) {
                        return (int128(0), TWENTY_64x64.neg());
                    }
                    fThresh = int128(result);
                }
            } else if (fNumerator > 0) {
                if (fDenominator <= 0) {
                    // P( exp(x) >= 0) = 1
                    return (int128(ONE_64x64), TWENTY_64x64);
                } else {
                    // num > 0 and den > 0, and P(exp(x) < infty) = 1
                    int256 result = (int256(fNumerator) << 64) / fDenominator;
                    if (result > MAX_64x64) {
                        return (int128(ONE_64x64), TWENTY_64x64);
                    }
                    fThresh = int128(result);
                }
            } else {
                return
                    fDenominator >= 0
                        ? (int128(0), TWENTY_64x64.neg())
                        : (int128(ONE_64x64), TWENTY_64x64);
            }
        } else {
            // denom is O(M3 * S3), div should not overflow
            fThresh = fNumerator.div(fDenominator);
        }
        // if we're here fDenominator !=0 and fThresh did not overflow
        // sign tells us whether we consider norm.cdf(f(threshold)) or 1-norm.cdf(f(threshold))
        // we recycle fDenominator to store the sign since it's no longer used
        fDenominator = fDenominator < 0 ? ONE_64x64.neg() : ONE_64x64;
        int128 dd = _ammVars.fPoolM3 == 0
            ? _calculateRiskNeutralDDNoQuanto(_mktVars.fSigma2, fDenominator, fThresh)
            : _calculateRiskNeutralDDWithQuanto(_ammVars, _mktVars, fDenominator, fThresh);

        int128 q;
        if (_withCDF) {
            q = _normalCDF(dd);
        }
        return (q, dd);
    }

    /**
     *  Calculate additional/non-risk based slippage.
     *  Ensures slippage is bounded away from zero for small trades,
     *  and plateaus for larger-than-average trades, so that price becomes risk based.
     *
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars current AMM variables - we need the current average exposure per trader
     *  @param _fTradeAmount 64.64-bit fixed point number, signed size of trade
     *  @return 64.64-bit fixed point number, a number between minus one and one
     */
    function _calculateBoundedSlippage(
        AMMVariables memory _ammVars,
        int128 _fTradeAmount
    ) internal pure returns (int128) {
        int128 fTradeSizeEMA = _ammVars.fCurrentTraderExposureEMA;
        int128 fSlippageSize = ONE_64x64;
        if (_fTradeAmount.abs() < fTradeSizeEMA) {
            fSlippageSize = fSlippageSize.sub(_fTradeAmount.abs().div(fTradeSizeEMA));
            fSlippageSize = ONE_64x64.sub(fSlippageSize.mul(fSlippageSize));
        }
        return _fTradeAmount > 0 ? fSlippageSize : fSlippageSize.neg();
    }

    /**
     *  Calculate AMM price.
     *
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars current AMM variables.
     *  @param _mktVars current Market variables (price&params)
     *                 Trader amounts k2 must already be factored in
     *                 that is, K2:=K2+k2, L1:=L1+k2*s2
     *  @param _fTradeAmount 64.64-bit fixed point number, signed size of trade
     *  @param _fHBidAskSpread half bid-ask spread, 64.64-bit fixed point number
     *  @return 64.64-bit fixed point number, AMM price
     */
    function calculatePerpetualPrice(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fTradeAmount,
        int128 _fHBidAskSpread,
        int128 _fIncentiveSpread
    ) external view virtual override returns (int128) {
        // add minimal spread in quote currency
        _fHBidAskSpread = _fTradeAmount > 0 ? _fHBidAskSpread : _fHBidAskSpread.neg();
        if (_fTradeAmount == 0) {
            _fHBidAskSpread = 0;
        }
        // get risk-neutral default probability (always >0)
        {
            int128 fQ;
            int128 dd;
            int128 fkStar = _ammVars.fPoolM2.sub(_ammVars.fAMM_K2);
            (fQ, dd) = _calculateRiskNeutralPD(_ammVars, _mktVars, _fTradeAmount, true);
            if (_ammVars.fPoolM3 != 0) {
                // amend K* (see whitepaper)
                int128 nominator = _mktVars.fRho23.mul(_mktVars.fSigma2.mul(_mktVars.fSigma3));
                int128 denom = _mktVars.fSigma2.mul(_mktVars.fSigma2);
                int128 h = nominator.div(denom).mul(_ammVars.fPoolM3);
                h = h.mul(_mktVars.fIndexPriceS3).div(_mktVars.fIndexPriceS2);
                fkStar = fkStar.add(h);
            }
            // decide on sign of premium
            if (_fTradeAmount < fkStar) {
                fQ = fQ.neg();
            }
            // no rebate if exposure increases
            if (_fTradeAmount > 0 && _ammVars.fAMM_K2 > 0) {
                fQ = fQ > 0 ? fQ : int128(0);
            } else if (_fTradeAmount < 0 && _ammVars.fAMM_K2 < 0) {
                fQ = fQ < 0 ? fQ : int128(0);
            }
            // handle discontinuity at zero
            if (
                _fTradeAmount == 0 &&
                ((fQ < 0 && _ammVars.fAMM_K2 > 0) || (fQ > 0 && _ammVars.fAMM_K2 < 0))
            ) {
                fQ = fQ.div(TWO_64x64);
            }
            _fHBidAskSpread = _fHBidAskSpread.add(fQ);
        }
        // get additional slippage
        if (_fTradeAmount != 0) {
            _fIncentiveSpread = _fIncentiveSpread.mul(
                _calculateBoundedSlippage(_ammVars, _fTradeAmount)
            );
            _fHBidAskSpread = _fHBidAskSpread.add(_fIncentiveSpread);
        }
        // s2*(1 + sign(qp-q)*q + sign(k)*minSpread)
        return _mktVars.fIndexPriceS2.mul(ONE_64x64.add(_fHBidAskSpread));
    }

    /**
     *  Calculate target collateral M1 (Quote Currency), when no M2, M3 is present
     *  The targeted default probability is expressed using the inverse
     *  _fTargetDD = Phi^(-1)(targetPD)
     *  _fK2 in absolute terms must be 'reasonably large'
     *  sigma3, rho23, IndexpriceS3 not relevant.
     *  @param _fK2 signed 64.64-bit fixed point number, !=0, EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number, >0, EWMA of actual L.
     *  @param  _mktVars contains 64.64 values for fIndexPriceS2*, fIndexPriceS3, fSigma2*, fSigma3, fRho23
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M1Star signed 64.64-bit fixed point number, >0
     */
    function getTargetCollateralM1(
        int128 _fK2,
        int128 _fL1,
        MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) external pure virtual override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 == 0);
        assert(_mktVars.fIndexPriceS3 == 0);
        assert(_mktVars.fRho23 == 0);
        int128 fMu2 = HALF_64x64.neg().mul(_mktVars.fSigma2).mul(_mktVars.fSigma2);
        int128 ddScaled = _fK2 < 0
            ? _mktVars.fSigma2.mul(_fTargetDD)
            : _mktVars.fSigma2.mul(_fTargetDD).neg();
        int128 A1 = ABDKMath64x64.exp(fMu2.add(ddScaled));
        return _fK2.mul(_mktVars.fIndexPriceS2).mul(A1).sub(_fL1);
    }

    /**
     *  Calculate target collateral *M2* (Base Currency), when no M1, M3 is present
     *  The targeted default probability is expressed using the inverse
     *  _fTargetDD = Phi^(-1)(targetPD)
     *  _fK2 in absolute terms must be 'reasonably large'
     *  sigma3, rho23, IndexpriceS3 not relevant.
     *  @param _fK2 signed 64.64-bit fixed point number, EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number, EWMA of actual L.
     *  @param _mktVars contains 64.64 values for fIndexPriceS2, fIndexPriceS3, fSigma2, fSigma3, fRho23
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M2Star signed 64.64-bit fixed point number
     */
    function getTargetCollateralM2(
        int128 _fK2,
        int128 _fL1,
        MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) external pure virtual override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 == 0);
        assert(_mktVars.fIndexPriceS3 == 0);
        assert(_mktVars.fRho23 == 0);
        int128 fMu2 = HALF_64x64.mul(_mktVars.fSigma2).mul(_mktVars.fSigma2).neg();
        int128 ddScaled = _fL1 < 0
            ? _mktVars.fSigma2.mul(_fTargetDD)
            : _mktVars.fSigma2.mul(_fTargetDD).neg();
        int128 A1 = ABDKMath64x64.exp(fMu2.add(ddScaled)).mul(_mktVars.fIndexPriceS2);
        return _fK2.sub(_fL1.div(A1));
    }

    /**
     *  Calculate target collateral M3 (Quanto Currency), when no M1, M2 not present
     *  @param _fK2 signed 64.64-bit fixed point number. EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number.  EWMA of actual L.
     *  @param  _mktVars contains 64.64 values for
     *           fIndexPriceS2, fIndexPriceS3, fSigma2, fSigma3, fRho23 - all required
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M2Star signed 64.64-bit fixed point number
     */
    function getTargetCollateralM3(
        int128 _fK2,
        int128 _fL1,
        MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) external pure override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 != 0);
        assert(_mktVars.fIndexPriceS3 != 0);
        // we solve the quadratic equation A x^2 + Bx + C = 0
        // B = 2 * [X + Y * target_dd^2 * (exp(rho*sigma2*sigma3) - 1) ]
        // C = X^2  - Y^2 * target_dd^2 * (exp(sigma2^2) - 1)
        // where:
        // X = L1 / S3 - Y and Y = K2 * S2 / S3
        // we re-use L1 for X and K2 for Y to save memory since they don't enter the equations otherwise
        _fK2 = _fK2.mul(_mktVars.fIndexPriceS2).div(_mktVars.fIndexPriceS3); // Y
        _fL1 = _fL1.div(_mktVars.fIndexPriceS3).sub(_fK2); // X
        // we only need the square of the target DD
        _fTargetDD = _fTargetDD.mul(_fTargetDD);
        // and we only need B/2
        int128 fHalfB = _fL1.add(
            _fK2.mul(_fTargetDD.mul(_mktVars.fRho23.mul(_mktVars.fSigma2.mul(_mktVars.fSigma3))))
        );
        int128 fC = _fL1.mul(_fL1).sub(
            _fK2.mul(_fK2).mul(_fTargetDD).mul(_mktVars.fSigma2.mul(_mktVars.fSigma2))
        );
        // A = 1 - (exp(sigma3^2) - 1) * target_dd^2
        int128 fA = ONE_64x64.sub(_mktVars.fSigma3.mul(_mktVars.fSigma3).mul(_fTargetDD));
        // we re-use C to store the discriminant: D = (B/2)^2 - A * C
        fC = fHalfB.mul(fHalfB).sub(fA.mul(fC));
        if (fC < 0) {
            // no solutions -> AMM is in profit, probability is smaller than target regardless of capital
            return int128(0);
        }
        // we want the larger of (-B/2 + sqrt((B/2)^2-A*C)) / A and (-B/2 - sqrt((B/2)^2-A*C)) / A
        // so it depends on the sign of A, or, equivalently, the sign of sqrt(...)/A
        fC = ABDKMath64x64.sqrt(fC).div(fA);
        fHalfB = fHalfB.div(fA);
        return fC > 0 ? fC.sub(fHalfB) : fC.neg().sub(fHalfB);
    }

    /**
     *  Calculate the required deposit for a new position
     *  of size _fPosition+_fTradeAmount and leverage _fTargetLeverage,
     *  having an existing position with balance fBalance0 and size _fPosition.
     *  This is the amount to be added to the margin collateral and can be negative (hence remove).
     *  Fees not factored-in.
     *  @param _fPosition0   signed 64.64-bit fixed point number. Position in base currency
     *  @param _fBalance0   signed 64.64-bit fixed point number. Current balance.
     *  @param _fTradeAmount signed 64.64-bit fixed point number. Trade amt in base currency
     *  @param _fTargetLeverage signed 64.64-bit fixed point number. Desired leverage
     *  @param _fPrice signed 64.64-bit fixed point number. Price for the trade of size _fTradeAmount
     *  @param _fS2Mark signed 64.64-bit fixed point number. Mark-price
     *  @param _fS3 signed 64.64-bit fixed point number. Collateral 2 quote conversion
     *  @return signed 64.64-bit fixed point number. Required cash_cc
     */
    function getDepositAmountForLvgPosition(
        int128 _fPosition0,
        int128 _fBalance0,
        int128 _fTradeAmount,
        int128 _fTargetLeverage,
        int128 _fPrice,
        int128 _fS2Mark,
        int128 _fS3,
        int128 _fS2
    ) external pure override returns (int128) {
        // calculation has to be aligned with _getAvailableMargin and _executeTrade
        // calculation
        // otherwise the calculated deposit might not be enough to declare
        // the margin to be enough
        // aligned with get available margin balance
        int128 fPremiumCash = _fTradeAmount.mul(_fPrice.sub(_fS2));
        int128 fDeltaLockedValue = _fTradeAmount.mul(_fS2);
        int128 fPnL = _fTradeAmount.mul(_fS2Mark);
        // we replace _fTradeAmount * price/S3 by
        // fDeltaLockedValue + fPremiumCash to be in line with
        // _executeTrade
        fPnL = fPnL.sub(fDeltaLockedValue).sub(fPremiumCash);
        int128 fLvgFrac = _fPosition0.add(_fTradeAmount).abs();
        fLvgFrac = fLvgFrac.mul(_fS2Mark).div(_fTargetLeverage);
        fPnL = fPnL.sub(fLvgFrac).div(_fS3);
        _fBalance0 = _fBalance0.add(fPnL);
        return _fBalance0.neg();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../core/PerpStorage.sol";
import "../interfaces/ILibraryEvents.sol";
import "../../libraries/ConverterDec18.sol";
import "../../libraries/EnumerableSetUpgradeable.sol";
import "../interfaces/IPerpetualRebalanceLogic.sol";
import "../interfaces/IPerpetualBrokerFeeLogic.sol";
import "../interfaces/IPerpetualUpdateLogic.sol";
import "../interfaces/IPerpetualMarginViewLogic.sol";
import "../interfaces/IPerpetualTradeLogic.sol";
import "../interfaces/IPerpetualTreasury.sol";
import "../interfaces/IPerpetualGetter.sol";
import "../interfaces/IPerpetualSetter.sol";
import "../../oracle/OracleFactory.sol";

import "../../libraries/SwapLib.sol";

contract PerpetualBaseFunctions is PerpStorage, ILibraryEvents {
    using ABDKMath64x64 for int128;
    using ConverterDec18 for int128;
    using ConverterDec18 for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    uint64 internal constant WITHDRAWAL_DELAY_TIME_SEC = 1 * 86400; // 1 day
    int128 internal constant MASK_USDC_TO_STUSD = 0x1;

    /**
     * @dev Get LiquidityPool storage reference corresponding to a given perpetual id
     * @param _iPerpetualId Perpetual id, unique across liquidity pools
     * @return LiquidityPoolData
     */
    function _getLiquidityPoolFromPerpetual(
        uint24 _iPerpetualId
    ) internal view returns (LiquidityPoolData storage) {
        uint8 poolId = perpetualPoolIds[_iPerpetualId];
        return liquidityPools[poolId];
    }

    /**
     * @dev Get id of the LiquidityPool corresponding to a given perpetual id
     * @param _iPerpetualId Perpetual id, unique across liquidity pools
     * @return Liquidity Pool id
     */
    function _getPoolIdFromPerpetual(uint24 _iPerpetualId) internal view returns (uint8) {
        return perpetualPoolIds[_iPerpetualId];
    }

    /**
     * @dev Get perpetual reference from its 'globally' unique id
     * @param _iPerpetualId Perpetual id, unique across liquidity pools
     * @return PerpetualData
     */
    function _getPerpetual(uint24 _iPerpetualId) internal view returns (PerpetualData storage) {
        uint8 poolId = perpetualPoolIds[_iPerpetualId];
        require(poolId > 0, "perp not found");

        return perpetuals[poolId][_iPerpetualId];
    }

    /**
     * @dev Check if the account of the trader is empty in the perpetual, which means fCashCC = 0 and fPositionBC = 0
     * @param _perpetual The perpetual object
     * @param _traderAddr The address of the trader
     * @return True if the account of the trader is empty in the perpetual
     */
    function _isEmptyAccount(
        PerpetualData storage _perpetual,
        address _traderAddr
    ) internal view returns (bool) {
        MarginAccount storage account = marginAccounts[_perpetual.id][_traderAddr];
        return account.fCashCC == 0 && account.fPositionBC == 0;
    }

    /**
     * @dev Update the trader's cash in the margin account (trader can also be the AMM)
     * The 'cash' is denominated in collateral currency.
     * @param _perpetual   The perpetual struct
     * @param _traderAddr The address of the trader
     * @param _fDeltaCash signed 64.64-bit fixed point number.
     *                    Change of trader margin in collateral currency.
     */
    function _updateTraderMargin(
        PerpetualData storage _perpetual,
        address _traderAddr,
        int128 _fDeltaCash
    ) internal {
        if (_fDeltaCash == 0) {
            return;
        }
        MarginAccount storage account = marginAccounts[_perpetual.id][_traderAddr];
        account.fCashCC = account.fCashCC.add(_fDeltaCash);
    }

    /**
     * @dev Transfer from the user to the vault account.
     * Called by perp contracts only, no risk of third party using arbitrary _userAddr.
     * @param   _pool  Liquidity Pool
     * @param   _userAddr       The address of the account
     * @param   _fAmount        The amount of erc20 token to transfer in ABDK64x64 format.
     */
    function _transferFromUserToVault(
        LiquidityPoolData storage _pool,
        address _userAddr,
        int128 _fAmount
    ) internal {
        if (_fAmount <= 0) {
            return;
        }
        uint256 amountWei = _fAmount.toUDecN(_pool.marginTokenDecimals);

        // get the first perpetual's flag of this pool
        uint24 perpId = perpetualIds[_pool.id][0];
        int128 flag = perpetuals[_pool.id][perpId].perpFlags;
        if (flag & MASK_USDC_TO_STUSD > 0) {
            SwapLib.swapExactOutputFrom(amountWei, SwapLib.USDC, SwapLib.STUSD, _userAddr);
        } else {
            IERC20Upgradeable marginToken = IERC20Upgradeable(_pool.marginTokenAddress);
            // slither-disable-next-line arbitrary-send-erc20
            marginToken.safeTransferFrom(_userAddr, address(this), amountWei);
        }
    }

    /**
     * What is the current amount of collateral that we can
     * consider as borrowed?
     * Linear interpolation between prevBlock and nextBlock
     * @param _pool reference to liquidity pool
     * @return collateral amount in ABDK 64.64 format
     */
    function _getCollateralTokenAmountForPricing(
        LiquidityPoolData storage _pool
    ) internal view returns (int128) {
        if (_pool.totalSupplyShareToken == 0) {
            return 0;
        }
        int128 pnlPartCash = _pool.fPnLparticipantsCashCC;
        uint256 shareProportion = (uint256(_getShareTokenAmountForPricing(_pool)) * 10 ** 18) /
            uint256(_pool.totalSupplyShareToken);
        return int256(shareProportion).fromDec18().mul(pnlPartCash);
    }

    /**
     * to simplify testing we write an internal function
     * @return delay for withdrawing
     */
    function _getDelay() internal pure virtual returns (uint64) {
        return WITHDRAWAL_DELAY_TIME_SEC;
    }

    /**
     * Internal implementation of getShareTokenAmountForPricing
     * @param _pool  reference of liquidity pool
     * @return share token number
     */
    function _getShareTokenAmountForPricing(
        LiquidityPoolData storage _pool
    ) internal view returns (uint128) {
        uint64 thisTs = uint64(block.timestamp);
        if (thisTs >= _pool.prevAnchor + _getDelay()) {
            return _pool.nextTokenAmount;
        }
        uint128 ratioDec100 = ((thisTs - _pool.prevAnchor) * 100) / (_getDelay());
        return
            _pool.nextTokenAmount > _pool.prevTokenAmount
                ? _pool.prevTokenAmount +
                    (ratioDec100 * (_pool.nextTokenAmount - _pool.prevTokenAmount)) /
                    100
                : _pool.prevTokenAmount -
                    (ratioDec100 * (_pool.prevTokenAmount - _pool.nextTokenAmount)) /
                    100;
    }

    /**
     * Transfer from the vault to the user account.
     * @param   _pool Liquidity pool
     * @param   _traderAddr    The address of the account
     * @param   _fAmount       The amount of erc20 token to transfer
     */
    function _transferFromVaultToUser(
        LiquidityPoolData storage _pool,
        address _traderAddr,
        int128 _fAmount
    ) internal {
        if (_fAmount <= 0) {
            return;
        }
        uint256 amountWei = _fAmount.toUDecN(_pool.marginTokenDecimals);
        if (amountWei == 0) {
            return;
        }
        // get the first perpetual's flag of this pool
        uint24 perpId = perpetualIds[_pool.id][0];
        int128 flag = perpetuals[_pool.id][perpId].perpFlags;
        if (flag & MASK_USDC_TO_STUSD > 0) {
            SwapLib.swapExactInputTo(amountWei, SwapLib.STUSD, SwapLib.USDC, _traderAddr);
        } else {
            IERC20Upgradeable marginToken = IERC20Upgradeable(_pool.marginTokenAddress);
            // transfer the margin token to the user
            marginToken.safeTransfer(_traderAddr, amountWei);
        }
    }

    /**
     * @dev Get safe Oracle price of the base index S2 of a given perpetual
     */
    function _getSafeOraclePriceS2(
        PerpetualData storage _perpetual
    ) internal view returns (int128) {
        return
            _getSafeOraclePrice(
                _perpetual.S2BaseCCY,
                _perpetual.S2QuoteCCY,
                _perpetual.fSettlementS2PriceData
            );
    }

    /**
     * @dev Get safe Oracle price of the quanto index S3 of a given perpetual
     * @param _perpetual Perpetual storage reference
     */
    function _getSafeOraclePriceS3(
        PerpetualData storage _perpetual
    ) internal view returns (int128) {
        return
            _getSafeOraclePrice(
                _perpetual.S3BaseCCY,
                _perpetual.S3QuoteCCY,
                _perpetual.fSettlementS3PriceData
            );
    }

    /**
     * @dev Get safe oracle price for a given currency pair and fallback price
     * The fallback or settlement price is used when the market is closed (oracle returns 0 price)
     * @param base Base currency
     * @param quote Quote currency
     * @param _fSettlement Settlement price to default to when markets close
     */
    function _getSafeOraclePrice(
        bytes4 base,
        bytes4 quote,
        int128 _fSettlement
    ) internal view returns (int128) {
        (int128 fPrice, ) = OracleFactory(oracleFactoryAddress).getSpotPrice(base, quote);
        if (fPrice == 0) {
            // return settlement price
            return _fSettlement;
        }
        return fPrice;
    }

    /**
     * @dev Get oracle price for a given currency pair
     * Not safe in the sense that it could return 0 if markets are closed
     * @param _baseQuote Currency pair
     */
    function _getOraclePrice(bytes4[2] memory _baseQuote) internal view returns (int128) {
        (int128 fPrice, ) = OracleFactory(oracleFactoryAddress).getSpotPrice(
            _baseQuote[0],
            _baseQuote[1]
        );
        return fPrice;
    }

    /**
     * Get the multiplier that converts <base> into
     * the value of <collateralcurrency>
     * Hence 1 if collateral currency = base currency
     * If the state of the perpetual is not "NORMAL",
     * use the settlement price
     * @param   _perpetual           The reference of perpetual storage.
     * @param   _isMarkPriceRequest  If true, get the conversion for the mark-price. If false for spot.
     * @param   _bUseOracle If false, the settlement price is used to compute the B2Q conversion
     * @return  The index price of the collateral for the given perpetual.
     */
    function _getBaseToCollateralConversionMultiplier(
        PerpetualData storage _perpetual,
        bool _isMarkPriceRequest,
        bool _bUseOracle
    ) internal view returns (int128) {
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        /*
        Quote: Pos * markprice --> quote currency
        Base: Pos * markprice / indexprice; E.g., 0.1 BTC * 36500 / 36000
        Quanto: Pos * markprice / index3price. E.g., 0.1 BTC * 36500 / 2000 = 1.83 ETH
        where markprice is replaced by indexprice if _isMarkPriceRequest=FALSE
        */
        int128 fPx2;
        int128 fPxIndex2;
        if (!_bUseOracle || _perpetual.state != PerpetualState.NORMAL) {
            fPxIndex2 = _perpetual.fSettlementS2PriceData;
            require(fPxIndex2 > 0, "settl px S2 not set");
        } else {
            fPxIndex2 = _getSafeOraclePriceS2(_perpetual);
        }

        if (_isMarkPriceRequest) {
            fPx2 = _getPerpetualMarkPrice(_perpetual, _bUseOracle);
        } else {
            fPx2 = fPxIndex2;
        }

        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            // equals ONE if _isMarkPriceRequest=FALSE
            return fPx2.div(fPxIndex2);
        }
        if (ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            // Example: 0.5 contracts of ETHUSD paid in BTC
            //  the rate is ETHUSD * 1/BTCUSD
            //  BTCUSD = 31000 => 0.5/31000 = 0.00003225806452 BTC
            return
                _bUseOracle && _perpetual.state == PerpetualState.NORMAL
                    ? fPx2.div(_getSafeOraclePriceS3(_perpetual))
                    : fPx2.div(_perpetual.fSettlementS3PriceData);
        } else {
            // Example: 0.5 contracts of ETHUSD paid in USD
            //  the rate is ETHUSD
            //  ETHUSD = 2000 => 0.5 * 2000 = 1000
            require(ccy == AMMPerpLogic.CollateralCurrency.QUOTE, "unknown state");
            return fPx2;
        }
    }

    /**
     * Get the mark price of the perpetual. If the state of the perpetual is not "NORMAL",
     * return the settlement price
     * @param   _perpetual The perpetual in the liquidity pool
     * @param   _bUseOracle If false, the mark premium is applied to the current settlement price.
     * @return  markPrice  The mark price of current perpetual.
     */
    function _getPerpetualMarkPrice(
        PerpetualData storage _perpetual,
        bool _bUseOracle
    ) internal view returns (int128) {
        int128 fPremiumRate = _perpetual.currentMarkPremiumRate.fPrice;
        int128 markPrice = _bUseOracle && _perpetual.state == PerpetualState.NORMAL
            ? (_getSafeOraclePriceS2(_perpetual)).mul(ONE_64x64.add(fPremiumRate))
            : (_perpetual.fSettlementS2PriceData).mul(ONE_64x64.add(fPremiumRate));
        return markPrice;
    }

    /**
     * Get the multiplier that converts <collateralcurrency> into
     * the value of <quotecurrency>
     * Hence 1 if collateral currency = quote currency
     * If the state of the perpetual is not "NORMAL",
     * use the settlement price
     * @param   _perpetual           The reference of perpetual storage.
     * @param   _bUseOracle          If false, the settlement price is used to compute the B2Q conversion
     * @return  The index price of the collateral for the given perpetual.
     */
    function _getCollateralToQuoteConversionMultiplier(
        PerpetualData storage _perpetual,
        bool _bUseOracle
    ) internal view returns (int128) {
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        /*
            Quote: 1
            Base: S2, e.g. we hold 1 BTC -> 36000 USD
            Quanto: S3, e.g., we hold 1 ETH -> 2000 USD
        */
        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            return
                _bUseOracle && _perpetual.state == PerpetualState.NORMAL
                    ? _getSafeOraclePriceS2(_perpetual)
                    : _perpetual.fSettlementS2PriceData;
        }
        if (ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            return
                _bUseOracle && _perpetual.state == PerpetualState.NORMAL
                    ? _getSafeOraclePriceS3(_perpetual)
                    : _perpetual.fSettlementS3PriceData;
        } else {
            return ONE_64x64;
        }
    }

    /**
     * Determines the amount of funds allocated to a given perpetual from its corresponding liquidity pool
     * @dev These are the funds that are used for:
     *  - Risk calculations: e.g. pricing and k star
     *  - Settlement: insufficient allocated funds can cause the perpetual to enter emergency state
     * The funds are determined by allocating to each perpetual either its target amount,
     * or a pro-rated amount if the total funds in the pool are below its overall target
     * @param _perpetual Perpetual reference
     * @return fFunds Amount of funds in collateral currency
     */
    function _getPerpetualAllocatedFunds(
        PerpetualData storage _perpetual
    ) internal view returns (int128 fFunds) {
        if (_perpetual.fTargetAMMFundSize <= 0) {
            return 0;
        }
        LiquidityPoolData storage pool = liquidityPools[_perpetual.poolId];
        int128 fPricingCash = _getCollateralTokenAmountForPricing(pool);
        if (fPricingCash <= 0) {
            return 0;
        }
        if (fPricingCash > pool.fTargetAMMFundSize) {
            fFunds = _perpetual.fTargetAMMFundSize;
        } else {
            fFunds = fPricingCash.mul(_perpetual.fTargetAMMFundSize.div(pool.fTargetAMMFundSize));
        }
    }

    /**
     * Prepare data for pricing functions (AMMPerpModule)
     * @param   _perpetual The reference of perpetual storage.
     * @param   _bUseOracle Should the oracle price be used? If false or market is closed, the settlement price is used
     */
    function _prepareAMMAndMarketData(
        PerpetualData storage _perpetual,
        bool _bUseOracle
    )
        internal
        view
        returns (AMMPerpLogic.AMMVariables memory, AMMPerpLogic.MarketVariables memory)
    {
        // prepare data
        AMMPerpLogic.AMMVariables memory ammState;
        AMMPerpLogic.MarketVariables memory marketState;

        marketState.fIndexPriceS2 = _bUseOracle
            ? _getSafeOraclePriceS2(_perpetual)
            : _perpetual.fSettlementS2PriceData;
        marketState.fSigma2 = int128(_perpetual.fSigma2) << 35;
        MarginAccount storage AMMMarginAcc = marginAccounts[_perpetual.id][address(this)];
        // get current locked-in value
        ammState.fLockedValue1 = AMMMarginAcc.fLockedInValueQC.neg();

        // get current position of all traders (= - AMM position)
        ammState.fAMM_K2 = AMMMarginAcc.fPositionBC.neg();
        // get cash from PnL fund that we can use when pricing
        int128 fPricingPnLCashCC = _getPerpetualAllocatedFunds(_perpetual);
        // add cash from AMM margin account
        fPricingPnLCashCC = fPricingPnLCashCC.add(AMMMarginAcc.fCashCC);
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            ammState.fPoolM2 = fPricingPnLCashCC;
        } else if (ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            ammState.fPoolM3 = fPricingPnLCashCC;
            // additional parameters for quanto case
            int128 fPx = _bUseOracle
                ? _getSafeOraclePriceS3(_perpetual)
                : _perpetual.fSettlementS3PriceData;
            marketState.fIndexPriceS3 = fPx;
            marketState.fSigma3 = int128(_perpetual.fSigma3) << 35;
            marketState.fRho23 = int128(_perpetual.fRho23) << 35;
        } else {
            assert(ccy == AMMPerpLogic.CollateralCurrency.QUOTE);
            ammState.fPoolM1 = fPricingPnLCashCC;
        }
        ammState.fCurrentTraderExposureEMA = _perpetual.fCurrentTraderExposureEMA;
        return (ammState, marketState);
    }

    /**
     * @dev     Select an arbitrary perpetual that will be processed
     *
     * @param   _iPoolIdx       pool index of that perpetual
     */
    function _selectPerpetualIds(uint8 _iPoolIdx) internal view returns (uint24) {
        require(_iPoolIdx > 0, "pool not found");
        LiquidityPoolData storage liquidityPool = liquidityPools[_iPoolIdx];
        require(liquidityPool.iPerpetualCount > 0, "no perp in pool");
        // idx doesn't have to be random
        // slither-disable-next-line weak-prng
        uint16 idx = uint16(block.timestamp % uint64(liquidityPool.iPerpetualCount));
        return perpetualIds[liquidityPool.id][idx];
    }

    /*
     * Check if two numbers have the same sign. Zero has the same sign with any number
     * @param   _fX 64.64 fixed point number
     * @param   _fY 64.64 fixed point number
     * @return  True if the numbers have the same sign or one of them is zero.
     */
    function _hasTheSameSign(int128 _fX, int128 _fY) internal pure returns (bool) {
        if (_fX == 0 || _fY == 0) {
            return true;
        }
        return (_fX ^ _fY) >> 127 == 0;
    }

    /**
     * Calculate Exponentially Weighted Moving Average.
     * Returns updated EMA based on
     * _fEMA = _fLambda * _fEMA + (1-_fLambda)* _fCurrentObs
     * @param _fEMA signed 64.64-bit fixed point number
     * @param _fCurrentObs signed 64.64-bit fixed point number
     * @param _fLambda signed 64.64-bit fixed point number
     * @return fNewEMA updated EMA, signed 64.64-bit fixed point number
     */
    function _ema(
        int128 _fEMA,
        int128 _fCurrentObs,
        int128 _fLambda
    ) internal pure returns (int128 fNewEMA) {
        require(_fLambda > 0, "EMALambda must be gt 0");
        require(_fLambda < ONE_64x64, "EMALambda must be st 1");
        // result must be between the two values _fCurrentObs and _fEMA, so no overflow
        fNewEMA = ABDKMath64x64.add(
            _fEMA.mul(_fLambda),
            ABDKMath64x64.mul(ONE_64x64.sub(_fLambda), _fCurrentObs)
        );
    }

    function _getTradeLogic() internal view returns (IPerpetualTradeLogic) {
        return IPerpetualTradeLogic(address(this));
    }

    function _getAMMPerpLogic() internal view returns (IAMMPerpLogic) {
        return IAMMPerpLogic(address(ammPerpLogic));
    }

    function _getRebalanceLogic() internal view returns (IPerpetualRebalanceLogic) {
        return IPerpetualRebalanceLogic(address(this));
    }

    function _getBrokerFeeLogic() internal view returns (IPerpetualBrokerFeeLogic) {
        return IPerpetualBrokerFeeLogic(address(this));
    }

    function _getUpdateLogic() internal view returns (IPerpetualUpdateLogic) {
        return IPerpetualUpdateLogic(address(this));
    }

    function _getMarginViewLogic() internal view returns (IPerpetualMarginViewLogic) {
        return IPerpetualMarginViewLogic(address(this));
    }

    function _getPerpetualGetter() internal view returns (IPerpetualGetter) {
        return IPerpetualGetter(address(this));
    }

    function _getPerpetualSetter() internal view returns (IPerpetualSetter) {
        return IPerpetualSetter(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./PerpetualBaseFunctions.sol";
import "../interfaces/IPerpetualMarginLogic.sol";

contract PerpetualRebalanceFunctions is PerpetualBaseFunctions {
    using ABDKMath64x64 for int128;
    int128 internal constant NINETY_FIVE_PERCENT = 0xf333333333333333;

    /**
     * @dev     Modifier can be called with a 0 perpId.
     *
     * @param   _iPerpetualId   perpetual id
     */
    modifier updateFundingAndPrices(uint24 _iPerpetualId) {
        _getUpdateLogic().updateFundingAndPricesBefore(_iPerpetualId, true);
        _;
        _getUpdateLogic().updateFundingAndPricesAfter(_iPerpetualId);
    }

    /**
     * @dev     To re-balance the AMM margin to the initial margin.
     *          Transfer margin between the perpetual and the various cash pools, then
     *          update the AMM's cash in perpetual margin account.
     *
     * @param   _perpetual The perpetual in the liquidity pool
     */
    function _rebalance(PerpetualData storage _perpetual) internal {
        if (_perpetual.state != PerpetualState.NORMAL) {
            return;
        }
        _equalizeAMMMargin(_perpetual);
        _getUpdateLogic().updateAMMTargetFundSize(_perpetual.id);
        // updating the mark price changes the markprice that is
        // used for margin calculation and hence the AMM initial
        // margin will not be exactly at initial margin rate
        _updateMarkPrice(_perpetual);

        // update trade size that minimizes AMM risk
        _updateKStar(_perpetual);
    }

    /**
     * @dev Brings the AMM margin acount back to its initial margin by
     * transferring funds to or from the AMM and PnL participation pools
     */
    function _equalizeAMMMargin(PerpetualData storage _perpetual) internal {
        int128 fMarginBalance;
        int128 fInitialBalance;
        (fMarginBalance, fInitialBalance) = _getRebalanceMargin(_perpetual);
        // Only equalize if change is above 10% or AMM position is zero
        // abs(fMarginBalance-fInitialBalance)/fInitialBalance > 10%
        // -> abs(fMarginBalance-fInitialBalance) > 10% fInitialBalance
        if (
            fMarginBalance.sub(fInitialBalance).abs() < fInitialBalance.mul(1844674407370955162) &&
            fInitialBalance.abs() > 0
        ) {
            // no moving of funds
            return;
        }

        if (fMarginBalance > fInitialBalance) {
            // from margin to pool
            _transferFromAMMMarginToPool(_perpetual, fMarginBalance.sub(fInitialBalance));
        } else {
            // from pool to margin
            // It's possible that there are not enough funds to draw from
            // in this case not the full margin will be replenished
            // (and emergency state is raised)
            _transferFromPoolToAMMMargin(
                _perpetual,
                fInitialBalance.sub(fMarginBalance),
                fMarginBalance
            );
        }
    }

    /**
     * @dev Update k*, the trade that would minimize the AMM risk.
     * Set 0 in quanto case.
     * @param _perpetual  The reference of perpetual storage.
     */
    function _updateKStar(PerpetualData storage _perpetual) internal {
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        MarginAccount storage AMMMarginAcc = marginAccounts[_perpetual.id][address(this)];
        int128 K2 = AMMMarginAcc.fPositionBC.neg();
        //M1/M2/M3  = LP cash allocted + margin cash
        int128 fM = _getPerpetualAllocatedFunds(_perpetual).add(AMMMarginAcc.fCashCC);

        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            _perpetual.fkStar = fM.sub(K2);
        } else if (ccy == AMMPerpLogic.CollateralCurrency.QUOTE) {
            _perpetual.fkStar = K2.neg();
        } else {
            int128 fB2C = _getBaseToCollateralConversionMultiplier(_perpetual, false, false); // s2 / s3
            int128 nominator = (int128(_perpetual.fRho23) << 35)
                .mul(int128(_perpetual.fSigma2) << 35)
                .mul(int128(_perpetual.fSigma3) << 35);
            int128 denom = (int128(_perpetual.fSigma2) << 35).mul(
                int128(_perpetual.fSigma2) << 35
            );
            _perpetual.fkStar = nominator.div(denom).div(fB2C).mul(fM).sub(K2);
        }
    }

    /**
     * @dev Get the margin to rebalance the AMM in the perpetual.
     * Margin to rebalance = margin - initial margin
     * @param   _perpetual The perpetual in the liquidity pool
     * @return  The margin to rebalance in the perpetual
     */
    function _getRebalanceMargin(
        PerpetualData storage _perpetual
    ) internal view returns (int128, int128) {
        int128 fInitialMargin = _getMarginViewLogic().getInitialMargin(
            _perpetual.id,
            address(this)
        );
        int128 fMarginBalance = _getMarginViewLogic().getMarginBalance(
            _perpetual.id,
            address(this)
        );
        return (fMarginBalance, fInitialMargin);
    }

    /**
     * @dev Transfer a given amount from the AMM margin account to the
     * liq pools (AMM pool, participation fund).
     * @param   _perpetual   The reference of perpetual storage.
     * @param   _fAmount            signed 64.64-bit fixed point number.
     */
    function _transferFromAMMMarginToPool(
        PerpetualData storage _perpetual,
        int128 _fAmount
    ) internal {
        if (_fAmount == 0) {
            return;
        }
        require(_fAmount > 0, "transferFromAMMMgnToPool >0");
        LiquidityPoolData storage pool = liquidityPools[_perpetual.poolId];
        // update margin of AMM
        _updateTraderMargin(_perpetual, address(this), _fAmount.neg());

        int128 fPnLparticipantAmount;
        int128 fDFAmount;
        // split amount ensures PnL part and DF split profits according to their relative sizes
        (fPnLparticipantAmount, fDFAmount) = _splitAmount(pool, _fAmount, false);
        _increasePoolCash(pool, fPnLparticipantAmount);
        pool.fDefaultFundCashCC = pool.fDefaultFundCashCC.add(fDFAmount);
    }

    /**
     * @dev Transfer a given amount from the liquidity pools
     * (broker pool + default fund+PnLparticipant)
     * into the AMM margin account.
     * Margin to rebalance = margin - initial margin
     * @param   _perpetual   The reference of perpetual storage.
     * @param   _fAmount     Amount to transfer. Signed 64.64-bit fixed point number.
     * @param   _fMarginBalance perpetual margin balance
     * @return  The amount that could be drawn from the pools.
     */
    function _transferFromPoolToAMMMargin(
        PerpetualData storage _perpetual,
        int128 _fAmount,
        int128 _fMarginBalance
    ) internal returns (int128) {
        // transfer from pool to AMM: amount >= 0
        if (_fAmount == 0) {
            return 0;
        }
        require(_fAmount > 0, "transferFromPoolToAMM>0");
        // perpetual state cannot be normal with 0 cash
        LiquidityPoolData storage pool = liquidityPools[_perpetual.poolId];
        int128 fPnLPartFunds = _getCollateralTokenAmountForPricing(pool);
        require(
            pool.fDefaultFundCashCC > 0 ||
                fPnLPartFunds > 0 ||
                _perpetual.state != PerpetualState.NORMAL,
            "state abnormal: 0 DF Cash"
        );
        // we first withdraw from the broker fund
        int128 fBrokerAmount = _withdrawFromBrokerPool(_fAmount, pool);
        int128 fFeasibleMargin = fBrokerAmount;
        if (fBrokerAmount < _fAmount) {
            // now we aim to withdraw _fAmount - fBrokerAmount from the liquidity pools
            // fDFAmount, fLPAmount will give us the amount that can be withdrawn
            int128 fDFAmount;
            int128 fLPAmount;
            (fDFAmount, fLPAmount) = _getFeasibleTransferFromPoolToAMMMargin(
                _fAmount.sub(fBrokerAmount),
                _fMarginBalance,
                fPnLPartFunds,
                _perpetual,
                pool
            );
            fFeasibleMargin = fFeasibleMargin.add(fLPAmount).add(fDFAmount);
        }
        // update margin
        _updateTraderMargin(_perpetual, address(this), fFeasibleMargin);
        return fFeasibleMargin;
    }

    /**
     * We aim to withdraw _fAmount from the default fund and P&L participation funds.
     * This function determines what can be withdrawn from the two funds, fDFAmount and fLPAmount
     * respectively, so that ideally _fAmount = fDFAmount + fLPAmount if we have enough cash
     * in the pools.
     * @param _fAmount amount we aim to withdraw from P&L-participation-fund and Default fund
     * @param _fMarginBalance perpetual margin balance
     * @param _fPnLPartFunds available P&L funds
     * @param _perpetual    reference to the perpetual data
     * @param _pool reference to the pool data
     * @return fDFAmount amount we can withdraw from the default fund
     * @return fLPAmount amount we can withdraw from the p&l participation fund
     */
    function _getFeasibleTransferFromPoolToAMMMargin(
        int128 _fAmount,
        int128 _fMarginBalance,
        int128 _fPnLPartFunds,
        PerpetualData storage _perpetual,
        LiquidityPoolData storage _pool
    ) internal returns (int128 fDFAmount, int128 fLPAmount) {
        // perp funds coming from the liquidity pool
        int128 fPoolFunds = _getPerpetualAllocatedFunds(_perpetual);

        if (fPoolFunds.add(_fMarginBalance) > 0) {
            // the AMM has a positive margin balance when accounting for all allocated funds
            // -> funds are transferred to the margin, capped at:
            // 1) available amount, and  2) no more than to keep AMM at initial margin
            (fLPAmount, fDFAmount) = _splitAmount(
                _pool,
                fPoolFunds > _fAmount ? _fAmount : fPoolFunds,
                true
            );
        } else {
            // AMM has lost all its allocated funds: emergency state
            // 1) all LP funds are used, 2) DF covers what if left
            fLPAmount = fPoolFunds;
            fDFAmount = fPoolFunds.add(_fMarginBalance).neg();
            if (_fPnLPartFunds > _pool.fTargetAMMFundSize) {
                // there are some LP funds allocated to the DF -> split what DF pays
                int128 fDFWeight = _pool.fDefaultFundCashCC.div(
                    _pool.fDefaultFundCashCC.add(_fPnLPartFunds).sub(_pool.fTargetAMMFundSize)
                );
                fLPAmount = fLPAmount.add(fDFAmount.mul(ONE_64x64.sub(fDFWeight)));
                fDFAmount = fDFAmount.mul(fDFWeight);
            }
            _getUpdateLogic().setEmergencyState(_perpetual.id);
        }
        // ensure DF is not depleted: PnL sharing cap may cause DF to overc-contribute
        //-> PnL participants cover the rest
        if (fDFAmount > _pool.fDefaultFundCashCC) {
            fLPAmount = fLPAmount.add(fDFAmount.sub(_pool.fDefaultFundCashCC));
            fDFAmount = _pool.fDefaultFundCashCC;
        }
        // ensure LPs can cover total: otherwise stop the pool
        if (fLPAmount >= _fPnLPartFunds) {
            // liquidity pool is depleted
            fLPAmount = _fPnLPartFunds;
            _setLiqPoolEmergencyState(_pool);
        }
        _decreaseDefaultFundCash(_pool, fDFAmount);
        _decreasePoolCash(_pool, fLPAmount);
        // this function returns (fDFAmount, fLPAmount);
    }

    /**
     * Try to withdraw from broker pool (to replenish margin).
     * @param _fAmount amount we aim to withdraw from the broker fund of this pool
     * @param _pool liquidity pool
     * @return amount we can withdraw from broker fund (int128, ABDK)
     */
    function _withdrawFromBrokerPool(
        int128 _fAmount,
        LiquidityPoolData storage _pool
    ) internal returns (int128) {
        // pre-condition: require(_fAmount > 0, "withdraw amount must>0");
        int128 fBrokerPoolCC = _pool.fBrokerFundCashCC;
        if (fBrokerPoolCC == 0) {
            return 0;
        }
        int128 withdraw = _fAmount > fBrokerPoolCC ? fBrokerPoolCC : _fAmount;
        _pool.fBrokerFundCashCC = fBrokerPoolCC.sub(withdraw);
        return withdraw;
    }

    /**
     * @dev Split amount in relation to pool sizes.
     * If withdrawing and ratio cannot be met, funds are withdrawn from the other pool.
     * Precondition: (_fAmount < available PnLparticipantCash + dfCash) || !_isWithdrawn
     * @param   _liquidityPool    reference to liquidity pool
     * @param   _fAmount          Signed 64.64-bit fixed point number. The amount to be split
     * @param   _isWithdrawn      If true, the function re-distributes the amounts so that the pool
     *                            funds remain non-negative.
     * @return  Signed 64.64-bit fixed point number x 2. Amounts for PnL participants and AMM
     */
    function _splitAmount(
        LiquidityPoolData storage _liquidityPool,
        int128 _fAmount,
        bool _isWithdrawn
    ) internal view returns (int128, int128) {
        if (_fAmount == 0) {
            return (0, 0);
        }
        int128 fAmountPnLparticipants;
        int128 fAmountDF;
        {
            // will divide this by fAvailCash below
            int128 fWeightPnLparticipants = _getCollateralTokenAmountForPricing(_liquidityPool);
            int128 fAvailCash = fWeightPnLparticipants.add(_liquidityPool.fDefaultFundCashCC);
            require(_fAmount > 0, ">0 amount expected");
            require(!_isWithdrawn || fAvailCash >= _fAmount, "pre-cond not met");
            fWeightPnLparticipants = fWeightPnLparticipants.div(fAvailCash);
            int128 fCeilPnLShare = int128(_liquidityPool.fCeilPnLShare) << 35;
            // ceiling for PnL participant share of PnL
            if (fWeightPnLparticipants > fCeilPnLShare) {
                fWeightPnLparticipants = fCeilPnLShare;
            }

            fAmountPnLparticipants = fWeightPnLparticipants.mul(_fAmount);
            fAmountDF = _fAmount.sub(fAmountPnLparticipants);
        }

        // ensure we have have non-negative funds when withdrawing
        // re-distribute otherwise
        if (_isWithdrawn) {
            // pre-condition: _fAmount<available PnLparticipantCash+dfcash
            // because of CEIL_PNL_SHARE we might allocate too much to DF
            // fix this here
            int128 fSpillover = _liquidityPool.fDefaultFundCashCC.sub(fAmountDF);
            if (fSpillover < 0) {
                fSpillover = fSpillover.neg();
                fAmountDF = fAmountDF.sub(fSpillover);
                fAmountPnLparticipants = fAmountPnLparticipants.add(fSpillover);
            }
        }

        return (fAmountPnLparticipants, fAmountDF);
    }

    /**
     * @dev Increase the participation fund's cash(collateral).
     * @param   _liquidityPool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to increase.
     */
    function _increasePoolCash(
        LiquidityPoolData storage _liquidityPool,
        int128 _fAmount
    ) internal {
        require(_fAmount >= 0, "inc neg pool cash");
        _liquidityPool.fPnLparticipantsCashCC = _liquidityPool.fPnLparticipantsCashCC.add(
            _fAmount
        );
    }

    /**
     * Decrease the participation fund pool's cash(collateral).
     * @param   _pool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to decrease.
     *                       Will not decrease to negative
     */
    function _decreasePoolCash(LiquidityPoolData storage _pool, int128 _fAmount) internal {
        require(_fAmount >= 0, "dec neg pool cash");
        _pool.fPnLparticipantsCashCC = _pool.fPnLparticipantsCashCC.sub(_fAmount);
    }

    /**
     * @dev     Decrease default fund cash
     * @param   _liquidityPool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to decrease.
     */
    function _decreaseDefaultFundCash(
        LiquidityPoolData storage _liquidityPool,
        int128 _fAmount
    ) internal {
        require(_fAmount >= 0, "dec neg pool cash");
        _liquidityPool.fDefaultFundCashCC = _liquidityPool.fDefaultFundCashCC.sub(_fAmount);
        require(_liquidityPool.fDefaultFundCashCC >= 0, "DF cash cannot be <0");
    }

    /**
     * @dev Loop through perpetuals of the liquidity pool and set
     * to emergency state
     * @param _liqPool reference to liquidity pool
     */
    function _setLiqPoolEmergencyState(LiquidityPoolData storage _liqPool) internal {
        uint256 length = _liqPool.iPerpetualCount;
        for (uint256 i = 0; i < length; i++) {
            uint24 idx = perpetualIds[_liqPool.id][i];
            PerpetualData storage perpetual = perpetuals[_liqPool.id][idx];
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            _getUpdateLogic().setEmergencyState(perpetual.id);
        }
    }

    /**
     * @dev     Check if the trader has opened position in the trade.
     *          Example: 2, 1 => true; 2, -1 => false; -2, -3 => true
     * @param   _fNewPos    The position of the trader after the trade
     * @param   fDeltaPos   The size of the trade
     * @return  True if the trader has opened position in the trade
     */
    function _hasOpenedPosition(int128 _fNewPos, int128 fDeltaPos) internal pure returns (bool) {
        if (_fNewPos == 0) {
            return false;
        }
        return _hasTheSameSign(_fNewPos, fDeltaPos);
    }

    /**
     * @dev Check if Trader is maintenance margin safe in the perpetual,
     * need to rebalance before checking.
     * @param   _perpetual   Reference to the perpetual
     * @param   _traderAddr  The address of the trader
     * @param   _hasOpened   True if the trader opens, false if they close
     * @return  True if Trader is maintenance margin safe in the perpetual.
     */
    function _isTraderMarginSafe(
        PerpetualData storage _perpetual,
        address _traderAddr,
        bool _hasOpened
    ) internal view returns (bool) {
        return
            _hasOpened
                ? _getMarginViewLogic().isInitialMarginSafe(_perpetual.id, _traderAddr)
                : _getMarginViewLogic().isMarginSafe(_perpetual.id, _traderAddr);
    }

    /**
     * @dev Update mark premium
     * Computes and sets the mark premium given the current AMM and market state
     * @param _perpetual Perpetual storage reference
     */
    function _updateMarkPrice(PerpetualData storage _perpetual) internal {
        int128 fCurrentPremiumRate = _calcInsurancePremium(_perpetual);
        _updatePremiumMarkPrice(_perpetual, fCurrentPremiumRate);
        _perpetual.premiumRatesEMA = int72(
            _ema(
                _perpetual.premiumRatesEMA,
                fCurrentPremiumRate,
                int128(_perpetual.fMarkPriceEMALambda) << 35
            )
        );
    }

    /**
     * Update the EMA of insurance premium used for the mark price
     * @param   _perpetual   The reference of perpetual storage.
     */
    function _updatePremiumMarkPrice(
        PerpetualData storage _perpetual,
        int128 _fCurrentPremiumRate
    ) internal {
        uint64 iCurrentTimeSec = uint64(block.timestamp);
        if (
            _perpetual.currentMarkPremiumRate.time != iCurrentTimeSec &&
            _perpetual.state == PerpetualState.NORMAL
        ) {
            // no update of mark-premium rate if we are in emergency state (we want the mark-premium to be frozen)
            // update mark-price if we are in a new block

            _perpetual.currentMarkPremiumRate.time = iCurrentTimeSec;

            // update only if sufficiently different: 1 basis point
            if (
                _perpetual.currentMarkPremiumRate.fPrice.sub(_perpetual.premiumRatesEMA).abs() <
                1844674407370955
            ) {
                return;
            }
            // now set the mark price to the last EMA of previous block
            _perpetual.currentMarkPremiumRate.fPrice = _perpetual.premiumRatesEMA;
            emit UpdateMarkPrice(
                _perpetual.id,
                _fCurrentPremiumRate,
                _perpetual.currentMarkPremiumRate.fPrice,
                _getSafeOraclePriceS2(_perpetual)
            );
        }
    }

    /*
     * Update the mid-price for the insurance premium. This is used for EMA of perpetual prices
     * (mark-price used in funding payments and rebalance)
     * @param   _perpetual   The reference of perpetual storage.
     * @return current premium rate (=signed relative diff to index price)
     */
    function _calcInsurancePremium(
        PerpetualData storage _perpetual
    ) internal view returns (int128) {
        // prepare data
        AMMPerpLogic.AMMVariables memory ammState;
        AMMPerpLogic.MarketVariables memory marketState;
        // this method is called when rebalancing, which occurs in three cases:
        // 1) trading and liquidations (settlement px is up to date and markets are open)
        // 2) margin withdrawals (settlement px is up to date and markets are open)
        // 3) adding and removing liquidity (checkOracleStatus is called without reverting,
        //    so settlement is updated if possible)
        (ammState, marketState) = _prepareAMMAndMarketData(_perpetual, false);

        // mid price has no minimal spread
        // mid-price parameter obtained using amount k=0
        int128 px_premium = _getAMMPerpLogic().calculatePerpetualPrice(
            ammState,
            marketState,
            0,
            0,
            0
        );
        px_premium = px_premium.sub(marketState.fIndexPriceS2).div(marketState.fIndexPriceS2);
        return px_premium;
    }

    function _getMarginLogic() internal view returns (IPerpetualMarginLogic) {
        return IPerpetualMarginLogic(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../../interface/ISpotOracle.sol";
import "./PerpetualRebalanceFunctions.sol";

contract PerpetualUpdateFunctions is PerpetualBaseFunctions {
    using ABDKMath64x64 for int128;
    using ConverterDec18 for int128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    int128 private constant BASE_RATE = 0x068db8bac710cb; //0.0001 or 1 bps
    int128 internal constant LAMBDA_SPREAD_CONVERGENCE = 16157274282726883980; //0.8758875939388329 * 2^64 (was 0.7671790772159579 * 2^64 for 2s blocks)
    int128 private constant FIVE = 0x50000000000000000;

    /**
     * @dev     Update the funding state of the perpetual. Funding payment of
     *          every account in the perpetual is updated.
     *          Update the fUnitAccumulatedFunding variable in perpetual.
     *          After that, funding payment of every account in the perpetual is updated,
     *
     *          fUnitAccumulatedFunding := fUnitAccumulatedFunding
     *                                    + 'index price' * fundingRate * elapsedTime/fundingInterval
     *                                      * 1/'collateral price'
     * @param   _perpetual   perpetual to be updated
     */
    function _accumulateFundingInPerp(PerpetualData storage _perpetual) internal {
        uint256 iTimeElapsed = _perpetual.iLastFundingTime;
        if (block.timestamp <= iTimeElapsed || _perpetual.state != PerpetualState.NORMAL) {
            // already updated or not running
            return;
        }
        // block.timestamp > iLastFundingTime, so safe:
        unchecked {
            iTimeElapsed = block.timestamp - iTimeElapsed;
        }
        // convert timestamp to ABDK64.64
        int128 fTimeElapsed = ABDKMath64x64.fromUInt(iTimeElapsed);

        // determine payment in collateral currency for 1 unit of base currency \
        // (e.g. USD payment for 1 BTC for BTCUSD)
        int128 fInterestPaymentLong = fTimeElapsed.mul(_perpetual.fCurrentFundingRate).div(
            FUNDING_INTERVAL_SEC
        );
        // fInterestPaymentLong will be applied to 'base currency 1' (multiply with position size)
        // Finally, we convert this payment from base currency into collateral currency
        int128 fConversion = _getBaseToCollateralConversionMultiplier(_perpetual, false, false);
        fInterestPaymentLong = fInterestPaymentLong.mul(fConversion);
        _perpetual.fUnitAccumulatedFunding = _perpetual.fUnitAccumulatedFunding.add(
            fInterestPaymentLong
        );
    }

    /**
     * Get the mark price premium rate. If the state of the perpetual is not "NORMAL",
     * return the settlement price
     * @param   _perpetual   The reference of perpetual storage.
     * @return  The index price for the given perpetual
     */
    function _getMarkPremiumRateEMA(
        PerpetualData storage _perpetual
    ) internal view returns (int128) {
        return _perpetual.currentMarkPremiumRate.fPrice;
    }

    /**
     * Update the funding rate of each perpetual that belongs to the given liquidity pool
     * @param   _perpetual   perpetual to be updated
     */
    function _updateFundingRatesInPerp(PerpetualData storage _perpetual) internal {
        if (
            uint256(_perpetual.iLastFundingTime) >= block.timestamp ||
            _perpetual.state != PerpetualState.NORMAL
        ) {
            // invalid time or not running
            return;
        }
        _updateFundingRate(_perpetual);
        //update iLastFundingTime (we need it in _accumulateFundingInPerp and _updateFundingRatesInPerp)
        _perpetual.iLastFundingTime = uint32(block.timestamp);
    }

    /**
     * Update the funding rate of the perpetual.
     *
     * premium rate = 'EMA of signed insurance premium' / 'spot price'
     * funding rate = max(premium rate, d) + min(premium rate, -d) + sgn(K)*b,
     *      with 'base rate' b = 0.0001, d = 0.0005. See whitepaper.
     * The long pays the funding rate to the short,
     * the short receives. Hence if positive, the short receives,
     * if negative, the short pays.
     *
     * @param  _perpetual   The reference of perpetual storage.
     */
    function _updateFundingRate(PerpetualData storage _perpetual) internal {
        // Get EMA of insurance premium, add to spot price oracle
        // similar to https://www.deribit.com/pages/docs/perpetual
        // and calculate funding rate

        int128 fFundingRate;
        int128 fBase;
        {
            int128 fFundingRateClamp = int128(_perpetual.fFundingRateClamp) << 35;
            int128 fPremiumRate = _getMarkPremiumRateEMA(_perpetual);
            // clamp the rate
            int128 K2 = marginAccounts[_perpetual.id][address(this)].fPositionBC.neg();
            if (fPremiumRate > fFundingRateClamp) {
                // r > 0 applies only if also K2 > 0
                fPremiumRate = K2 > 0 ? fPremiumRate : fFundingRateClamp;
                fFundingRate = fPremiumRate.sub(fFundingRateClamp);
            } else if (fPremiumRate < fFundingRateClamp.neg()) {
                // r < 0 applies only if also K2 < 0
                fPremiumRate = K2 < 0 ? fPremiumRate : fFundingRateClamp.neg();
                fFundingRate = fPremiumRate.add(fFundingRateClamp);
            }
            fBase = K2 >= 0 ? BASE_RATE : BASE_RATE.neg();
        }

        fFundingRate = fFundingRate.add(fBase);
        if (_perpetual.fCurrentFundingRate != fFundingRate) {
            _perpetual.fCurrentFundingRate = fFundingRate;
            emit UpdateFundingRate(_perpetual.id, fFundingRate);
        }
    }

    //== Treasury ==========================================================================================================================

    /**
     * Get the locked-in value of the trader positions in the perpetual
     * @param _perpetual The perpetual object
     * @param _traderAddr The address of the trader
     * @return The locked-in value
     */
    function _getLockedInValue(
        PerpetualData storage _perpetual,
        address _traderAddr
    ) internal view returns (int128) {
        return marginAccounts[_perpetual.id][_traderAddr].fLockedInValueQC;
    }

    /**
     * Updates the target size for AMM pool.
     * See whitepaper for formulas.
     * @param   _perpetual     Reference to the perpetual that needs an updated target size
     */
    function _updateAMMTargetFundSize(PerpetualData storage _perpetual) internal {
        LiquidityPoolData storage liquidityPool = _getLiquidityPoolFromPerpetual(_perpetual.id);
        int128 fOldTarget = _perpetual.fTargetAMMFundSize;
        int128 fNewTarget = _getUpdatedTargetAMMFundSize(
            _perpetual,
            _perpetual.eCollateralCurrency
        );
        // only update target every 1% difference
        if (fOldTarget.sub(fNewTarget).abs() < fOldTarget.mul(184467440737095516)) {
            return;
        }
        _perpetual.fTargetAMMFundSize = fNewTarget;
        // update total target sizes in pool data
        liquidityPool.fTargetAMMFundSize = liquidityPool.fTargetAMMFundSize.sub(fOldTarget).add(
            fNewTarget
        );
    }

    /**
     * Recalculate the target size for the AMM liquidity pool for the given perpetual using
     * the current 'LockedInValue' and 'AMMExposure' (=K in whitepaper)
     * The AMM target fund size will not go below 0.1 * fMinimalAMMExposureEMA * fx
     *
     * @param   _perpetual      Reference to perpetual
     * @param   _ccy            Currency of collateral enum {QUOTE, BASE, QUANTO}
     * @return  Target size in required currency (64.64 fixed point number)
     */
    function _getUpdatedTargetAMMFundSize(
        PerpetualData storage _perpetual,
        AMMPerpLogic.CollateralCurrency _ccy
    ) internal view returns (int128) {
        // loop through perpetuals of this pool and update the
        // pool size
        AMMPerpLogic.MarketVariables memory mv;
        mv.fIndexPriceS2 = _perpetual.fSettlementS2PriceData;
        mv.fSigma2 = int128(_perpetual.fSigma2) << 35;
        int128 fMStar;
        int128 fK = marginAccounts[_perpetual.id][address(this)].fPositionBC.neg();
        int128 fLockedIn = marginAccounts[_perpetual.id][address(this)].fLockedInValueQC.neg();
        // adjust current K and L for EMA trade size:
        // kStarSide = kStar > 0 ? 1 : -1;
        if (_perpetual.fkStar < 0) {
            fK = fK.add(_perpetual.fCurrentTraderExposureEMA);
            fLockedIn = fLockedIn.add(_perpetual.fCurrentTraderExposureEMA.mul(mv.fIndexPriceS2));
        } else {
            fK = fK.sub(_perpetual.fCurrentTraderExposureEMA);
            fLockedIn = fLockedIn.sub(_perpetual.fCurrentTraderExposureEMA.mul(mv.fIndexPriceS2));
        }
        // set fMinSizeCC (former AMMMinSize) to 0.1 * fMinimalAMMExposureEMA;
        // fMinimalAMMExposureEMA is in base currency, conversion of fMinSizeCC to collateral
        // currency further below
        int128 fMinSizeCC = _perpetual.fMinimalAMMExposureEMA.mul(1844674407370955161);
        if (_ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            // get target collateral for current AMM exposure
            if (fK != 0) {
                fMStar = _getAMMPerpLogic().getTargetCollateralM2(
                    fK,
                    fLockedIn,
                    mv,
                    _perpetual.fAMMTargetDD
                );
            }
            // base = collateral currency so no conversion for fMinSizeCC
        } else if (_ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            if (fK != 0) {
                // additional parameters
                mv.fSigma3 = int128(_perpetual.fSigma3) << 35;
                mv.fRho23 = int128(_perpetual.fRho23) << 35;
                mv.fIndexPriceS3 = _perpetual.fSettlementS3PriceData;
                // get target collateral for current AMM exposure
                fMStar = _getAMMPerpLogic().getTargetCollateralM3(
                    fK,
                    fLockedIn,
                    mv,
                    _perpetual.fAMMTargetDD
                );
            }
            // convert fMinSizeCC from base currency to collateral
            int128 fx = _perpetual.fSettlementS2PriceData.div(_perpetual.fSettlementS3PriceData);
            fMinSizeCC = fMinSizeCC.mul(fx);
        } else {
            assert(_ccy == AMMPerpLogic.CollateralCurrency.QUOTE);
            if (fK != 0) {
                // get target collateral for conservative negative AMM exposure
                fMStar = _getAMMPerpLogic().getTargetCollateralM1(
                    fK,
                    fLockedIn,
                    mv,
                    _perpetual.fAMMTargetDD
                );
            }
            // convert fMinSizeCC from base currency to collateral
            fMinSizeCC = fMinSizeCC.mul(_perpetual.fSettlementS2PriceData);
        }
        // M = pool + margin, target is for pool funds only:
        fMStar = fMStar.sub(marginAccounts[_perpetual.id][address(this)].fCashCC);
        if (fMStar < fMinSizeCC) {
            fMStar = fMinSizeCC;
        }
        // EMA: new M* = L x old M* + (1 - L) x spot M*, same speed as DF target (slow)
        fMStar = _ema(_perpetual.fTargetAMMFundSize, fMStar, _perpetual.fDFLambda[0]);
        return fMStar;
    }

    /**
     * Updates the target size for default fund for one random perpetual
     * Update is performed only after 'iTargetPoolSizeUpdateTime' seconds after the
     * last update. See whitepaper for formulas.
     * @param   _iPoolIndex     Reference to liquidity pool
     */
    function _updateDefaultFundTargetSizeRandom(uint8 _iPoolIndex) internal {
        require(_iPoolIndex <= iPoolCount, "pool index out of range");
        LiquidityPoolData storage liquidityPool = liquidityPools[_iPoolIndex];
        // update of Default Fund target size for another perpetual
        // it doesn't have to be random, and it could be the same (nothing would happen)
        // slither-disable-next-line weak-prng
        uint256 idx = uint16(block.timestamp % uint256(liquidityPool.iPerpetualCount));
        uint24 id = perpetualIds[liquidityPool.id][idx];
        _updateDefaultFundTargetSize(id);
    }

    /**
     * Updates the target size for default fund a given perpetual
     * Update is performed only after 'iTargetPoolSizeUpdateTime' seconds after the
     * last update. See whitepaper for formulas.
     * @param   _iPerpetualId     Reference to perpetual
     */
    function _updateDefaultFundTargetSize(uint24 _iPerpetualId) internal {
        PerpetualData storage perpetual = _getPerpetual(_iPerpetualId);
        LiquidityPoolData storage liquidityPool = _getLiquidityPoolFromPerpetual(_iPerpetualId);
        if (
            uint32(block.timestamp) - perpetual.iLastTargetPoolSizeTime >
            uint32(liquidityPool.iTargetPoolSizeUpdateTime) &&
            perpetual.state == PerpetualState.NORMAL
        ) {
            // update of Default Fund target size for given perpetual
            int128 fDelta = perpetual.fTargetDFSize.neg();
            perpetual.fTargetDFSize = _getDefaultFundTargetSize(perpetual);
            fDelta = fDelta.add(perpetual.fTargetDFSize);
            // update the total value in the liquidity pool
            liquidityPool.fTargetDFSize = liquidityPool.fTargetDFSize.add(fDelta);
            // reset update time
            perpetual.iLastTargetPoolSizeTime = uint32(block.timestamp);
        }
    }

    /**
     * @dev Computes the target size for the default fund given the AMM's current state
     * @param   _perpetual      Reference to perpetual
     */
    function _getDefaultFundTargetSize(
        PerpetualData storage _perpetual
    ) internal view returns (int128) {
        int128[2] memory fIndexPrices;
        fIndexPrices[0] = _perpetual.fSettlementS2PriceData;
        fIndexPrices[1] = _perpetual.eCollateralCurrency == AMMPerpLogic.CollateralCurrency.QUANTO
            ? _perpetual.fSettlementS3PriceData
            : int128(0);
        uint256 len = activeAccounts[_perpetual.id].length();
        int128 fCoverN = (int128(_perpetual.fDFCoverNRate) << 35).mul(ABDKMath64x64.fromUInt(len));
        // floor for number of traders:
        if (fCoverN < FIVE) {
            fCoverN = FIVE; // =5
        }

        return
            _getAMMPerpLogic().calculateDefaultFundSize(
                _perpetual.fCurrentAMMExposureEMA,
                _perpetual.fCurrentTraderExposureEMA.mul(
                    int128(_perpetual.fInitialMarginRate) << 35
                ),
                fCoverN,
                _perpetual.fStressReturnS2,
                _perpetual.fStressReturnS3,
                fIndexPrices,
                _perpetual.eCollateralCurrency
            );
    }

    /**
     * @dev     Increase default fund cash
     * @param   _liquidityPool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to increase.
     */
    function _increaseDefaultFundCash(
        LiquidityPoolData storage _liquidityPool,
        int128 _fAmount
    ) internal {
        require(_fAmount >= 0, "increase negative pool cash");
        _liquidityPool.fDefaultFundCashCC = _liquidityPool.fDefaultFundCashCC.add(_fAmount);
    }

    /**
     * @dev Check whether market is closed.
     * Otherwise store settlement prices (if price not zero)
     * @param  _perpetual    reference to perpetual
     * @return isMarketClosed (price is zero)
     */
    function _checkOracleStatus(
        PerpetualData storage _perpetual,
        bool _revertIfClosed
    ) internal returns (bool isMarketClosed) {
        int128 fPrice = _getOraclePrice([_perpetual.S2BaseCCY, _perpetual.S2QuoteCCY]);
        if (fPrice > 0) {
            if (fPrice != _perpetual.fSettlementS2PriceData) {
                // the price was updated
                _perpetual.fSettlementS2PriceData = fPrice;
            }
        } else {
            isMarketClosed = true;
        }
        if (_perpetual.S3BaseCCY != bytes4(0)) {
            fPrice = _getOraclePrice([_perpetual.S3BaseCCY, _perpetual.S3QuoteCCY]);
            if (fPrice > 0) {
                _perpetual.fSettlementS3PriceData = fPrice;
            } else {
                isMarketClosed = true;
            }
        }
        require(!_revertIfClosed || !isMarketClosed, "market is closed");
    }

    /**
     * @dev Set the state of the perpetual to "EMERGENCY".
     * After that the perpetual is not allowed to trade, deposit and withdraw.
     * The price of the perpetual is frozen to the settlement price
     * Settlement price: latest mark price, latest index for S3
     * @param   _perpetual  reference to perpetual
     */
    function _setEmergencyState(PerpetualData storage _perpetual) internal {
        if (_perpetual.state == PerpetualState.EMERGENCY) {
            // done
            return;
        }

        require(_perpetual.state == PerpetualState.NORMAL, "perp should be NORMAL");
        // use mark price as final price when emergency
        // mark premium will no longer be updated when the state is not normal
        int128 _fMarkPremiumRate = _perpetual.currentMarkPremiumRate.fPrice;
        _perpetual.fSettlementS2PriceData = _perpetual.fSettlementS2PriceData.mul(
            ONE_64x64.add(_fMarkPremiumRate)
        );
        // state <- emergency
        _perpetual.state = PerpetualState.EMERGENCY;

        emit SetEmergencyState(
            _perpetual.id,
            _fMarkPremiumRate,
            _perpetual.fSettlementS2PriceData,
            _perpetual.fSettlementS3PriceData
        );
    }

    /**
     * @dev     Set the state of the perpetual to "NORMAL".
     *          The state must be "INITIALIZING" or "INVALID" before
     * @param   _perpetual   The reference of perpetual storage.
     */
    function _setNormalState(PerpetualData storage _perpetual) internal {
        require(
            _perpetual.state == PerpetualState.INITIALIZING ||
                _perpetual.state == PerpetualState.INVALID,
            "state should be INIT/INVALID"
        );
        _perpetual.state = PerpetualState.NORMAL;
        emit SetNormalState(_perpetual.id);
    }

    /**
     * Get the ids and pyth flag for all the price feeds used by this perpetual/
     * @param _iPerpetualId Perpetual Id
     * @return ids Array of price ids
     * @return isPyth Array indicating which ids are from Pyth
     */
    function _getPriceInfo(
        uint24 _iPerpetualId
    ) internal view returns (bytes32[] memory, bool[] memory) {
        PerpetualData storage perpetual = _getPerpetual(_iPerpetualId);
        // S2 first
        (bytes32[] memory feedIdsS2, bool[] memory isPythS2) = OracleFactory(oracleFactoryAddress)
            .getRouteIds([perpetual.S2BaseCCY, perpetual.S2QuoteCCY]);
        if (perpetual.eCollateralCurrency != AMMPerpLogic.CollateralCurrency.QUANTO) {
            // no quanto
            return (feedIdsS2, isPythS2);
        }
        // S3
        (bytes32[] memory feedIdsS3, bool[] memory isPythS3) = OracleFactory(oracleFactoryAddress)
            .getRouteIds([perpetual.S3BaseCCY, perpetual.S3QuoteCCY]);
        // count unique feeds
        // these loops are very short (2 elements tops)
        uint256 numIds = feedIdsS2.length;
        for (uint256 i = 0; i < feedIdsS3.length; i++) {
            bytes32 curId = feedIdsS3[i];
            bool seen = false;
            for (uint256 j = 0; j < feedIdsS2.length && !seen; j++) {
                seen = feedIdsS2[j] == curId || seen;
            }
            // count new ones and remove duplicates so next loop is easier
            if (!seen) {
                numIds++;
            } else {
                feedIdsS3[i] = bytes32(0);
            }
        }
        if (numIds == feedIdsS2.length) {
            // no new Ids in S3
            return (feedIdsS2, isPythS2);
        }
        // union
        bytes32[] memory ids = new bytes32[](numIds);
        bool[] memory isPyth = new bool[](numIds);
        // fill with S2 first
        for (uint256 i = 0; i < feedIdsS2.length; i++) {
            ids[i] = feedIdsS2[i];
            isPyth[i] = isPythS2[i];
        }
        // now with S3
        for (uint256 i = 0; i < feedIdsS3.length && numIds > 0; i++) {
            // all duplicates have been made = 0, we skip them
            if (feedIdsS3[i] != bytes32(0)) {
                numIds--;
                ids[numIds] = feedIdsS3[i];
                isPyth[numIds] = isPythS3[i];
            }
        }
        return (ids, isPyth);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../functions/AMMPerpLogic.sol";

interface IAMMPerpLogic {
    function calculateDefaultFundSize(
        int128[2] memory _fK2AMM,
        int128 _fk2Trader,
        int128 _fCoverN,
        int128[2] memory fStressRet2,
        int128[2] memory fStressRet3,
        int128[2] memory fIndexPrices,
        AMMPerpLogic.CollateralCurrency _eCCY
    ) external pure returns (int128);

    function calculateRiskNeutralPD(
        AMMPerpLogic.AMMVariables memory _ammVars,
        AMMPerpLogic.MarketVariables memory _mktVars,
        int128 _fTradeAmount,
        bool _withCDF
    ) external view returns (int128, int128);

    function calculatePerpetualPrice(
        AMMPerpLogic.AMMVariables memory _ammVars,
        AMMPerpLogic.MarketVariables memory _mktVars,
        int128 _fTradeAmount,
        int128 _fBidAskSpread,
        int128 _fIncentiveSpread
    ) external view returns (int128);

    function getTargetCollateralM1(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getTargetCollateralM2(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getTargetCollateralM3(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getDepositAmountForLvgPosition(
        int128 _fPosition0,
        int128 _fBalance0,
        int128 _fTradeAmount,
        int128 _fTargetLeverage,
        int128 _fPrice,
        int128 _fS2Mark,
        int128 _fS3,
        int128 _fS2
    ) external pure returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IFunctionList {
    function getFunctionList()
        external
        pure
        returns (bytes4[] memory functionSignatures, bytes32 moduleName);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "./IPerpetualOrder.sol";

/**
 * @notice  The libraryEvents defines events that will be raised from modules (contract/modules).
 * @dev     DO REMEMBER to add new events in modules here.
 */
interface ILibraryEvents {
    // PerpetualModule
    event Clear(uint24 indexed perpetualId, address indexed trader);
    event Settle(uint24 indexed perpetualId, address indexed trader, int256 amount);
    event SettlementComplete(uint24 indexed perpetualId);
    event SetNormalState(uint24 indexed perpetualId);
    event SetEmergencyState(
        uint24 indexed perpetualId,
        int128 fSettlementMarkPremiumRate,
        int128 fSettlementS2Price,
        int128 fSettlementS3Price
    );
    event SettleState(uint24 indexed perpetualId);
    event SetClearedState(uint24 indexed perpetualId);

    // Participation pool
    event LiquidityAdded(
        uint8 indexed poolId,
        address indexed user,
        uint256 tokenAmount,
        uint256 shareAmount
    );
    event LiquidityProvisionPaused(bool pauseOn, uint8 poolId);
    event LiquidityRemoved(
        uint8 indexed poolId,
        address indexed user,
        uint256 tokenAmount,
        uint256 shareAmount
    );
    event LiquidityWithdrawalInitiated(
        uint8 indexed poolId,
        address indexed user,
        uint256 shareAmount
    );

    // setters
    // oracles
    event SetOracles(uint24 indexed perpetualId, bytes4[2] baseQuoteS2, bytes4[2] baseQuoteS3);
    // perp parameters
    event SetPerpetualBaseParameters(uint24 indexed perpetualId, int128[7] baseParams);
    event SetPerpetualRiskParameters(
        uint24 indexed perpetualId,
        int128[5] underlyingRiskParams,
        int128[12] defaultFundRiskParams
    );
    event SetParameter(uint24 indexed perpetualId, string name, int128 value);
    event SetParameterPair(uint24 indexed perpetualId, string name, int128 value1, int128 value2);
    // pool parameters
    event SetPoolParameter(uint8 indexed poolId, string name, int128 value);

    event TransferAddressTo(string name, address oldOBFactory, address newOBFactory); // only governance
    event SetBlockDelay(uint8 delay);

    // fee structure parameters
    event SetBrokerDesignations(uint32[] designations, uint16[] fees);
    event SetBrokerTiers(uint256[] tiers, uint16[] feesTbps);
    event SetTraderTiers(uint256[] tiers, uint16[] feesTbps);
    event SetTraderVolumeTiers(uint256[] tiers, uint16[] feesTbps);
    event SetBrokerVolumeTiers(uint256[] tiers, uint16[] feesTbps);
    event SetUtilityToken(address tokenAddr);

    event BrokerLotsTransferred(
        uint8 indexed poolId,
        address oldOwner,
        address newOwner,
        uint32 numLots
    );
    event BrokerVolumeTransferred(
        uint8 indexed poolId,
        address oldOwner,
        address newOwner,
        int128 fVolume
    );

    // brokers
    event UpdateBrokerAddedCash(uint8 indexed poolId, uint32 iLots, uint32 iNewBrokerLots);

    // TradeModule

    event Trade(
        uint24 indexed perpetualId,
        address indexed trader,
        IPerpetualOrder.Order order,
        bytes32 orderDigest,
        int128 newPositionSizeBC,
        int128 price,
        int128 fFeeCC,
        int128 fPnlCC,
        int128 fB2C
    );

    event UpdateMarginAccount(
        uint24 indexed perpetualId,
        address indexed trader,
        int128 fFundingPaymentCC
    );

    event Liquidate(
        uint24 perpetualId,
        address indexed liquidator,
        address indexed trader,
        int128 amountLiquidatedBC,
        int128 liquidationPrice,
        int128 newPositionSizeBC,
        int128 fFeeCC,
        int128 fPnlCC
    );

    event PerpetualLimitOrderCancelled(uint24 indexed perpetualId, bytes32 indexed orderHash);
    event DistributeFees(
        uint8 indexed poolId,
        uint24 indexed perpetualId,
        address indexed trader,
        int128 protocolFeeCC,
        int128 participationFundFeeCC
    );

    // PerpetualManager/factory
    event RunLiquidityPool(uint8 _liqPoolID);
    event LiquidityPoolCreated(
        uint8 id,
        address marginTokenAddress,
        address shareTokenAddress,
        uint16 iTargetPoolSizeUpdateTime,
        int128 fBrokerCollateralLotSize
    );
    event PerpetualCreated(
        uint8 poolId,
        uint24 id,
        int128[7] baseParams,
        int128[5] underlyingRiskParams,
        int128[12] defaultFundRiskParams,
        uint256 eCollateralCurrency
    );

    // emit tokenAddr==0x0 if the token paid is the aggregated token, otherwise the address of the token
    event TokensDeposited(uint24 indexed perpetualId, address indexed trader, int128 amount);
    event TokensWithdrawn(uint24 indexed perpetualId, address indexed trader, int128 amount);

    event UpdateMarkPrice(
        uint24 indexed perpetualId,
        int128 fMidPricePremium,
        int128 fMarkPricePremium,
        int128 fSpotIndexPrice
    );

    event UpdateFundingRate(uint24 indexed perpetualId, int128 fFundingRate);

    event SetDelegate(address indexed trader, address indexed delegate, uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "../interfaces/IPerpetualOrder.sol";
import "../../interface/ISpotOracle.sol";

interface IPerpetualBrokerFeeLogic {
    function determineExchangeFee(IPerpetualOrder.Order memory _order)
        external
        view
        returns (uint16);

    function updateVolumeEMAOnNewTrade(
        uint24 _iPerpetualId,
        address _traderAddr,
        address _brokerAddr,
        int128 _tradeAmountBC
    ) external;

    function queryExchangeFee(
        uint8 _poolId,
        address _traderAddr,
        address _brokerAddr
    ) external view returns (uint16);

    function splitProtocolFee(uint16 fee) external pure returns (int128, int128);

    function setFeesForDesignation(uint32[] calldata _designations, uint16[] calldata _fees)
        external;

    function getLastPerpetualBaseToUSDConversion(uint24 _iPerpetualId)
        external
        view
        returns (int128);

    function getFeeForTraderVolume(uint8 _poolId, address _traderAddr)
        external
        view
        returns (uint16);

    function getFeeForBrokerVolume(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (uint16);

    function setOracleFactoryForPerpetual(uint24 _iPerpetualId, address _oracleAddr) external;

    function setBrokerTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setTraderTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setTraderVolumeTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setBrokerVolumeTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setUtilityTokenAddr(address tokenAddr) external;

    function getBrokerInducedFee(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (uint16);

    function getBrokerDesignation(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (uint32);

    function getFeeForBrokerDesignation(uint32 _brokerDesignation) external view returns (uint16);

    function getFeeForBrokerStake(address brokerAddr) external view returns (uint16);

    function getFeeForTraderStake(address traderAddr) external view returns (uint16);

    function getCurrentTraderVolume(uint8 _poolId, address _traderAddr)
        external
        view
        returns (int128);

    function getCurrentBrokerVolume(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (int128);

    function transferBrokerLots(
        uint8 _poolId,
        address _transferToAddr,
        uint32 _lots
    ) external;

    function transferBrokerOwnership(uint8 _poolId, address _transferToAddr) external;

    function setInitialVolumeForFee(
        uint8 _poolId,
        address _brokerAddr,
        uint16 _feeTbps
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../core/PerpStorage.sol";
import "../../interface/IShareTokenFactory.sol";

interface IPerpetualGetter {
    function getAMMPerpLogic() external view returns (address);

    function getShareTokenFactory() external view returns (IShareTokenFactory);

    function getOracleFactory() external view returns (address);

    function getTreasuryAddress() external view returns (address);

    function getOrderBookFactoryAddress() external view returns (address);

    function getOrderBookAddress(uint24 _perpetualId) external view returns (address);

    function isPerpMarketClosed(uint24 _perpetualId) external view returns (bool isClosed);

    function getOracleUpdateTime(uint24 _perpetualId) external view returns (uint256);

    function isDelegate(address _trader, address _delegate) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IPerpetualOrder.sol";

interface IPerpetualMarginLogic is IPerpetualOrder {
    function depositMarginForOpeningTrade(
        uint24 _iPerpetualId,
        int128 _fDepositRequired,
        Order memory _order
    ) external returns (bool);

    function withdrawDepositFromMarginAccount(uint24 _iPerpetualId, address _traderAddr) external;

    function reduceMarginCollateral(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fAmountToWithdraw
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IPerpetualOrder.sol";

interface IPerpetualMarginViewLogic is IPerpetualOrder {
    function calcMarginForTargetLeverage(
        uint24 _iPerpetualId,
        int128 _fTraderPos,
        int128 _fPrice,
        int128 _fTradeAmountBC,
        int128 _fTargetLeverage,
        address _traderAddr,
        bool _ignorePosBalance
    ) external view returns (int128);

    function getMarginBalance(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (int128);

    function isMaintenanceMarginSafe(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (bool);

    function getAvailableMargin(
        uint24 _iPerpetualId,
        address _traderAddr,
        bool _isInitialMargin
    ) external view returns (int128);

    function isInitialMarginSafe(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (bool);

    function getInitialMargin(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (int128);

    function getMaintenanceMargin(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (int128);

    function isMarginSafe(uint24 _iPerpetualId, address _traderAddr) external view returns (bool);

    function getAvailableCash(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPerpetualOrder {
    struct Order {
        uint16 leverageTDR; // 12.43x leverage is represented by 1243 (two-digit integer representation); 0 if deposit and trade separate
        uint16 brokerFeeTbps; // broker can set their own fee
        uint24 iPerpetualId; // global id for perpetual
        address traderAddr; // address of trader
        uint32 executionTimestamp; // normally set to current timestamp; order will not be executed prior to this timestamp.
        address brokerAddr; // address of the broker or zero
        uint32 submittedTimestamp;
        uint32 flags; // order flags
        uint32 iDeadline; //deadline for price (seconds timestamp)
        address executorAddr; // address of the executor set by contract
        int128 fAmount; // amount in base currency to be traded
        int128 fLimitPrice; // limit price
        int128 fTriggerPrice; //trigger price. Non-zero for stop orders.
        bytes brokerSignature; //signature of broker (or 0)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPerpetualRebalanceLogic {
    function rebalance(uint24 _iPerpetualId) external;

    function decreasePoolCash(uint8 _iPoolIdx, int128 _fAmount) external;

    function increasePoolCash(uint8 _iPoolIdx, int128 _fAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPerpetualSetter {
    function setPerpetualOracles(
        uint24 _iPerpetualId,
        bytes4[2] calldata _baseQuoteS2,
        bytes4[2] calldata _baseQuoteS3
    ) external;

    function setPerpetualBaseParams(uint24 _iPerpetualId, int128[7] calldata _baseParams) external;

    function setPerpetualRiskParams(
        uint24 _iPerpetualId,
        int128[5] calldata _underlyingRiskParams,
        int128[12] calldata _defaultFundRiskParams
    ) external;

    function setPerpetualParam(
        uint24 _iPerpetualId,
        string memory _varName,
        int128 _value
    ) external;

    function setPerpetualParamPair(
        uint24 _iPerpetualId,
        string memory _name,
        int128 _value1,
        int128 _value2
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "../interfaces/IPerpetualOrder.sol";

interface IPerpetualTradeLogic {
    function executeTrade(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fTraderPos,
        int128 _fTradeAmount,
        int128 _fPrice,
        bool _isClose
    ) external returns (int128);

    function preTrade(IPerpetualOrder.Order memory _order) external returns (int128, int128);

    function distributeFeesLiquidation(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fDeltaPositionBC,
        uint16 _protocolFeeTbps
    ) external returns (int128);

    function distributeFees(
        IPerpetualOrder.Order memory _order,
        uint16 _brkrFeeTbps,
        uint16 _protocolFeeTbps,
        bool _hasOpened
    ) external returns (int128);

    function validateStopPrice(
        bool _isLong,
        int128 _fMarkPrice,
        int128 _fTriggerPrice
    ) external pure;

    function getMaxSignedOpenTradeSizeForPos(
        uint24 _perpetualId,
        int128 _fCurrentTraderPos,
        bool _isBuy
    ) external view returns (int128);

    function queryPerpetualPrice(
        uint24 _iPerpetualId,
        int128 _fTradeAmountBC,
        int128[2] calldata _fIndexPrice
    ) external view returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../core/PerpStorage.sol";

interface IPerpetualTreasury {
    function addLiquidity(uint8 _iPoolIndex, uint256 _tokenAmount) external;

    function pauseLiquidityProvision(uint8 _poolId, bool _pauseOn) external;

    function withdrawLiquidity(uint8 _iPoolIndex, uint256 _shareAmount) external;

    function executeLiquidityWithdrawal(uint8 _poolId, address _lpAddr) external;

    function getCollateralTokenAmountForPricing(uint8 _poolId) external view returns (int128);

    function getShareTokenPriceD18(uint8 _poolId) external view returns (uint256 price);

    function getTokenAmountToReturn(
        uint8 _poolId,
        uint256 _shareAmount
    ) external view returns (uint256);

    function getWithdrawRequests(
        uint8 poolId,
        uint256 _fromIdx,
        uint256 numRequests
    ) external view returns (PerpStorage.WithdrawRequest[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPerpetualUpdateLogic {
    function updateAMMTargetFundSize(uint24 _iPerpetualId) external;

    function updateDefaultFundTargetSizeRandom(uint8 _iPoolIndex) external;

    function updateDefaultFundTargetSize(uint24 _iPerpetualId) external;

    function updateFundingAndPricesBefore(uint24 _iPerpetualId, bool _revertIfClosed) external;

    function updateFundingAndPricesAfter(uint24 _iPerpetualId) external;

    function setNormalState(uint24 _iPerpetualId) external;

    /**
     * Set emergency state
     * @param _iPerpetualId Perpetual id
     */
    function setEmergencyState(uint24 _iPerpetualId) external;

    /**
     * @notice Set external treasury (DAO)
     * @param _treasury treasury address
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Set order book factory (DAO)
     * @param _orderBookFactory order book factory address
     */
    function setOrderBookFactory(address _orderBookFactory) external;

    /**
     * @notice Set oracle factory (DAO)
     * @param _oracleFactory oracle factory address
     */
    function setOracleFactory(address _oracleFactory) external;

    /**
     * @notice Set delay for trades to be executed
     * @param _delay    delay in number of blocks
     */
    function setBlockDelay(uint8 _delay) external;

    /**
     * @notice Submits price updates to the feeds used by a given perpetual.
     * @dev Reverts if the submission does not match the perpetual or
     * if the feed rejects it for a reason other than being unnecessary.
     * If this function returns false, sender is not charged msg.value.
     * @param _perpetualId Perpetual Id
     * @param _updateData Data to send to price feeds
     * @param _publishTimes Publish timestamps
     * @param _maxAcceptableFeedAge Maximum age of update in seconds
     */
    function updatePriceFeeds(
        uint24 _perpetualId,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes,
        uint256 _maxAcceptableFeedAge
    ) external payable;

    /**
     * @notice Links the message sender to a delegate to manage orders on their behalf.
     * @param delegate Address of delegate
     * @param index Index to emit with event. A value of zero removes the current delegate.
     */
    function setDelegate(address delegate, uint256 index) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "../../libraries/OrderFlags.sol";
import "./../functions/PerpetualUpdateFunctions.sol";
import "./../interfaces/IFunctionList.sol";
import "./../interfaces/IPerpetualTradeLogic.sol";
import "../../libraries/Utils.sol";

contract PerpetualTradeLogic is PerpetualUpdateFunctions, IFunctionList, IPerpetualTradeLogic {
    using ABDKMath64x64 for int128;
    using OrderFlags for uint32;

    function executeTrade(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fTraderPos,
        int128 _fTradeAmount,
        int128 _fPrice,
        bool _isClose
    ) external virtual override returns (int128) {
        require(msg.sender == address(this), "onlythis");
        PerpetualData storage perpetual = _getPerpetual(_iPerpetualId);
        return
            _executeTrade(perpetual, _traderAddr, _fTraderPos, _fTradeAmount, _fPrice, _isClose);
    }

    function preTrade(
        IPerpetualOrder.Order memory _order
    ) external virtual override returns (int128 fPrice, int128 fAmount) {
        require(msg.sender == address(this), "onlythis");
        PerpetualData storage perpetual = _getPerpetual(_order.iPerpetualId);
        (fPrice, fAmount) = _preTrade(
            perpetual,
            _order.traderAddr,
            _order.fAmount,
            _order.fLimitPrice,
            _order.flags
        );
        return (fPrice, fAmount);
    }

    function distributeFees(
        IPerpetualOrder.Order memory _order,
        uint16 _brkrFeeTbps,
        uint16 _protocolFeeTbps,
        bool _hasOpened
    ) external virtual override returns (int128) {
        require(msg.sender == address(this), "onlythis");
        PerpetualData storage perpetual = _getPerpetual(_order.iPerpetualId);
        return
            _distributeFees(
                perpetual,
                _order.traderAddr,
                _order.executorAddr,
                _order.brokerAddr,
                _order.fAmount,
                _brkrFeeTbps,
                _protocolFeeTbps,
                _hasOpened
            );
    }

    /**
     * Distribution of trading fees in case of liquidation.
     * No executor and broker is involved, only exchange fees.
     * @param _iPerpetualId     perpetual ID
     * @param _traderAddr       trader being liquidated
     * @param _fDeltaPositionBC liquidated amount
     * @param _protocolFeeTbps  protocol fee
     * @return trading fee paid
     */
    function distributeFeesLiquidation(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fDeltaPositionBC,
        uint16 _protocolFeeTbps
    ) external virtual override returns (int128) {
        require(msg.sender == address(this), "onlythis");
        PerpetualData storage perpetual = _getPerpetual(_iPerpetualId);
        return
            _distributeFees(
                perpetual,
                _traderAddr,
                address(0),
                address(0),
                _fDeltaPositionBC,
                0,
                _protocolFeeTbps,
                false
            );
    }

    /**
     * @param   _perpetual          The reference of perpetual storage.
     * @param   _traderAddr         Trader address
     * @param   _fTraderPos         Current trader position (pre-trade, base currency)
     * @param   _fTradeAmount       Amount to be traded (base currency)
     * @param   _fPrice             price (base-quote)
     * @param   _isClose            true if trade (partially) closes position
     * @return  Realized profit (delta cash) in collateral currency
     */
    function _executeTrade(
        PerpetualData storage _perpetual,
        address _traderAddr,
        int128 _fTraderPos,
        int128 _fTradeAmount,
        int128 _fPrice,
        bool _isClose
    ) internal returns (int128) {
        (int128 fDeltaCashCC, int128 fDeltaLockedValue) = _getTradeDeltas(
            _perpetual,
            _traderAddr,
            _fTraderPos,
            _fTradeAmount,
            _fPrice,
            _isClose
        );
        // execute trade: update margin, position, and open interest:
        _updateMargin(
            _perpetual,
            address(this),
            _fTradeAmount.neg(),
            fDeltaCashCC.neg(),
            fDeltaLockedValue.neg()
        );
        _updateMargin(_perpetual, _traderAddr, _fTradeAmount, fDeltaCashCC, fDeltaLockedValue);
        if (!_isClose) {
            // update the average position size for AMM Pool and Default Fund target size.
            // We only account for 'opening trades'
            _updateAverageTradeExposures(_perpetual, _fTradeAmount.add(_fTraderPos));
        }
        return fDeltaCashCC;
    }

    function _getTradeDeltas(
        PerpetualData storage _perpetual,
        address _traderAddr,
        int128 _fTraderPos,
        int128 _fTradeAmount,
        int128 _fPrice,
        bool _isClose
    ) internal view returns (int128, int128) {
        // check that market is open
        int128 fIndexS2 = _perpetual.fSettlementS2PriceData;
        int128 fPremium = _fTradeAmount.mul(_fPrice.sub(fIndexS2));
        int128 fDeltaCashCC = fPremium.neg();
        int128 fC2Q = _getCollateralToQuoteConversionMultiplier(_perpetual, false);
        fDeltaCashCC = fDeltaCashCC.div(fC2Q);
        int128 fDeltaLockedValue = _fTradeAmount.mul(fIndexS2);
        // if we're opening a position, L <- L + delta position * price, and no change in cash account
        // otherwise, we will have a PnL from closing:
        if (_isClose) {
            require(_fTraderPos != 0, "already closed");
            int128 fAvgPrice = _getLockedInValue(_perpetual, _traderAddr);
            require(fAvgPrice != 0, "cannot be closing if no exposure");

            fAvgPrice = fAvgPrice.div(_fTraderPos).abs();
            // PnL = new price*pos - locked-in-price*pos
            //     = avgprice*delta_pos - new_price*delta_pos
            //     = avgprice*delta_pos - _fDeltaLockedValue
            int128 fPnL = fAvgPrice.mul(_fTradeAmount).sub(fDeltaLockedValue);
            // The locked-in-value should change proportionally to the amount that is closed:
            // delta LockedIn = delta position * avg price
            // delta LockedIn = delta position * price + PnL
            // Since we have delta LockedIn = delta position * price up to this point,
            // it suffices to add the PnL from above:
            fDeltaLockedValue = fDeltaLockedValue.add(fPnL);
            // equivalently, L <- L * new position / old position,
            // i.e. if we are selling 10%, then the new locked in value is the 90% remaining
            fDeltaCashCC = fDeltaCashCC.add(fPnL.div(fC2Q));
        }
        return (fDeltaCashCC, fDeltaLockedValue);
    }

    /**
     * Rounds _fAmountBC (0.5 rounded symmetrically)
     * @param   _fAmountBC    64.64 fixed point number, amount to be traded
     * @param   fLotSizeBC    64.64 fixed point number, lot size
     * @return  Rounded amount
     */
    function _roundToLot(int128 _fAmountBC, int128 fLotSizeBC) internal pure returns (int128) {
        int128 rounded = _fAmountBC.div(fLotSizeBC).add(0x8000000000000000) >> 64;
        return (rounded << 64).mul(fLotSizeBC);
    }

    /**
     * Shrinks the order amount to be consistent with lot-size and
     * determines the trade price. If we have a market order and the price
     * does not meet the limit, the function returns a price of zero, i.e., (0, rounded _fAmount)
     * @param   _perpetual    The reference of perpetual storage.
     * @param   _traderAddr   Trader address
     * @param   _fAmount      Amount to be traded (base currency) (negative if trader goes short)
     * @param   _fLimitPrice  Limit price
     * @param   _flags        Order flagisCloseOnly()
     * @return  Change in locked-in value (quote currency) and potentially reduced trade amount
     */
    function _preTrade(
        PerpetualData storage _perpetual,
        address _traderAddr,
        int128 _fAmount,
        int128 _fLimitPrice,
        uint32 _flags
    ) internal view returns (int128, int128) {
        // round the trade amount to the next lot size
        _fAmount = _roundToLot(_fAmount, _perpetual.fLotSizeBC);
        require(_fAmount.abs() > 0, "trade amount too small");

        int128 fTraderPos = marginAccounts[_perpetual.id][_traderAddr].fPositionBC;
        // don't leave dust. If the resulting position is smaller than minimal size,
        // we close the position (if closing) or revert (if opening)
        bool closePos = fTraderPos != 0 && !_hasTheSameSign(fTraderPos, _fAmount);
        if (
            fTraderPos.add(_fAmount).abs() < MIN_NUM_LOTS_PER_POSITION.mul(_perpetual.fLotSizeBC)
        ) {
            if (closePos) {
                // the position size is adjusted to a full close.
                _fAmount = fTraderPos.neg();
            } else {
                // cannot open a position below minimal size
                revert("position too small");
            }
        } else {
            // closing but resulting position is not small enough to be a full close
            closePos = false;
        }
        // handle close only flag or dust
        if (closePos || _flags.isCloseOnly()) {
            _fAmount = _shrinkToMaxPositionToClose(fTraderPos, _fAmount);
            require(_fAmount != 0, "no amount to close");
        }
        // query price from AMM
        int128 fPrice = _queryPriceFromAMM(_perpetual, _fAmount);
        if (!_validatePrice(_fAmount >= 0, fPrice, _fLimitPrice)) {
            if (OrderFlags.isMarketOrder(_flags)) {
                return (0, _fAmount);
            } else {
                revert("price exceeds limit");
            }
        }
        return (fPrice, _fAmount);
    }

    /**
     * Maximal position size calculation. The maximal position size per trader is set to the trader EMA times a
     * scaling factor (e.g, times 1.25).
     * This function is only called for opening trades (e.g., from long to larger long, or from short to long,
     * short to larger short, long to short)
     * @param _perpetual   Reference to perpetual
     * @param isLong       True if trader trades into a long position (new pos after trade is long)
     * @return The maximal position size that is currently allowed for this trader (positive if isLong, negative otherwise)
     *         according to EMA
     */
    function _getMaxSignedPositionSize(
        PerpetualData storage _perpetual,
        bool isLong
    ) internal view returns (int128) {
        int128 fPosSize = _perpetual.fCurrentTraderExposureEMA.mul(
            (int128(_perpetual.fMaximalTradeSizeBumpUp) << 35).abs()
        );
        // maxAbs = emwaTraderK * bumpUp
        fPosSize = isLong ? fPosSize : fPosSize.neg();
        return fPosSize;
    }

    /**
     * Finds the maximal increase in the current aggregated exposure such that
     * the perpetual would not enter emergency state when prices exhibit extreme but plausible
     * movements as defined by the stress return parameters of the perpetual at hand.
     * @param _perpetual Perpetual storage
     * @param _fTradeAmount Signed trade amount to cap
     * @return Potentially shrunk _fTradeAmount
     */
    function _shrinkToMaxExposureIncrease(
        PerpetualData storage _perpetual,
        int128 _fTradeAmount
    ) internal view returns (int128) {
        // amm enters opposite trade (-k) so we solve for:
        // amm_fund + amm_margin + ((amm_pos - k) * S2 - (amm_lockedin - k * S20)) / S3 > 0
        // ==>  funds * S3 -  K2 S2 + L1 > k (S2 - S20)
        MarginAccount storage amm = marginAccounts[_perpetual.id][address(this)];
        int128 fAMMPos = amm.fPositionBC;
        if (
            _hasTheSameSign(fAMMPos, _fTradeAmount) &&
            _hasTheSameSign(fAMMPos, fAMMPos.sub(_fTradeAmount))
        ) {
            // trade reduces exposure without flipping - no need to shrink
            return _fTradeAmount;
        }
        // choose extreme return according to sign of the trade
        uint256 idx = _fTradeAmount > 0 ? 1 : 0; // idx 0 (resp. 1) == negative (resp. positive) S2 return
        // s2(t) = s2(0) * exp(logret s2)
        int128 fS20 = _perpetual.fSettlementS2PriceData;
        int128 fS2 = fS20.mul(_perpetual.fStressReturnS2[idx].exp());
        // s3(t) = 1 if quote, s2(t) if base, s3(0) * exp(logret s3) if quanto
        int128 fCashQC = _getPerpetualAllocatedFunds(_perpetual).add(amm.fCashCC); // cc now, changes to qc below
        AMMPerpLogic.CollateralCurrency cc = _perpetual.eCollateralCurrency;
        if (cc == AMMPerpLogic.CollateralCurrency.BASE) {
            fCashQC = fCashQC.mul(fS2);
        } else if (cc == AMMPerpLogic.CollateralCurrency.QUANTO) {
            fCashQC = fCashQC.mul(_perpetual.fSettlementS3PriceData).mul(
                _perpetual.fStressReturnS3[idx].exp()
            );
        }
        // |k| < (funds * S3 - K2 * S2 + L1) / |S2 - S20|
        int128 fMaxPos = fCashQC.add(fAMMPos.mul(fS2)).sub(amm.fLockedInValueQC).div(
            fS2.sub(fS20).abs()
        );
        fMaxPos = fMaxPos > 0 ? fMaxPos : int128(0);
        return
            fMaxPos > _fTradeAmount.abs()
                ? _fTradeAmount
                : (_fTradeAmount > 0 ? fMaxPos : fMaxPos.neg());
    }

    /**
     * Maximal trade size depends on current position
     * Two constraints:
     * 1) trade size < fCurrentTraderExposureEMA * bumpUp
     * 2) resulting position size so that the AMM survives 1 day under
     *    stress return
     * This function is called only for OPEN trades (increase absolute value of position).
     * @param _perpetualId           id of the perpetual
     * @param _fCurrentTraderPos     position of trader before trade
     * @param _isBuy                 is this a buy or sell order (must be opening direction)
     * perpetual.fTraderExposureEMA    Current trader exposure EMA (perpetual.fCurrentAMMExposureEMA)
     * perpetual.fBumpUp               How much do we allow to increase the trade size above the current
     *                                 fCurrentAMMExposureEMA? (e.g. 0.25)
     * @return maxSignedTradeAmount signed maximal trade size (negative if trade is short, positive otherwise)
     */
    function getMaxSignedOpenTradeSizeForPos(
        uint24 _perpetualId,
        int128 _fCurrentTraderPos,
        bool _isBuy
    ) external view virtual override returns (int128 maxSignedTradeAmount) {
        PerpetualData storage perpetual = _getPerpetual(_perpetualId);
        // having the maximal (signed) position size, we can determine the maximal trade amount
        maxSignedTradeAmount = _getMaxSignedPositionSize(perpetual, _isBuy).sub(
            _fCurrentTraderPos
        );
        if ((_isBuy && maxSignedTradeAmount < 0) || (!_isBuy && maxSignedTradeAmount > 0)) {
            maxSignedTradeAmount = 0;
        } else {
            // shrink by applying cap on resulting exposure
            maxSignedTradeAmount = _shrinkToMaxExposureIncrease(perpetual, maxSignedTradeAmount);
        }
    }

    /**
     * Update the trader's account in the perpetual
     * @param _perpetual  The perpetual object
     * @param _fTraderPos The position size that the trader just initiated
     */
    function _updateAverageTradeExposures(
        PerpetualData storage _perpetual,
        int128 _fTraderPos
    ) internal {
        int128 fCurrentObs;
        uint24 iPerpetualId = _perpetual.id;
        // (neg) AMM exposure (aggregated trader exposure)
        {
            fCurrentObs = marginAccounts[iPerpetualId][address(this)].fPositionBC.neg();
            uint256 iIndex = fCurrentObs > 0 ? 1 : 0;
            int128 fCurrentEMA = _perpetual.fCurrentAMMExposureEMA[iIndex];
            int128 fLambda = fCurrentObs.abs() > fCurrentEMA.abs()
                ? _perpetual.fDFLambda[1]
                : _perpetual.fDFLambda[0];
            int128 fMinEMA = _perpetual.fMinimalAMMExposureEMA;
            if (fCurrentObs.abs() < fMinEMA) {
                fCurrentObs = iIndex == 0 ? fMinEMA.neg() : fMinEMA;
            }
            _perpetual.fCurrentAMMExposureEMA[iIndex] = _ema(fCurrentEMA, fCurrentObs, fLambda);
        }

        // trader exposure
        {
            fCurrentObs = _fTraderPos.abs();
            int128 fCurrentEMA = _perpetual.fCurrentTraderExposureEMA;
            int128 fLambda = fCurrentObs > fCurrentEMA
                ? _perpetual.fDFLambda[1]
                : _perpetual.fDFLambda[0];
            int128 fMinEMA = _perpetual.fMinimalTraderExposureEMA;
            if (fCurrentObs < fMinEMA) {
                fCurrentObs = fMinEMA;
            }
            _perpetual.fCurrentTraderExposureEMA = _ema(fCurrentEMA, fCurrentObs, fLambda);
        }
    }

    /**
     * Update the trader's account in the perpetual
     * @param _perpetual The perpetual object
     * @param _traderAddr The address of the trader
     * @param _fDeltaPosition The update position of the trader's account in the perpetual
     * @param _fDeltaCashCC The update cash(collateral currency) of the trader's account in the perpetual
     * @param _fDeltaLockedInValueQC The update of the locked-in value in quote currency
     */
    function _updateMargin(
        PerpetualData storage _perpetual,
        address _traderAddr,
        int128 _fDeltaPosition,
        int128 _fDeltaCashCC,
        int128 _fDeltaLockedInValueQC
    ) internal {
        MarginAccount storage account = marginAccounts[_perpetual.id][_traderAddr];
        int128 fOldPosition = account.fPositionBC;
        int128 fFundingPayment;
        if (fOldPosition != 0) {
            fFundingPayment = _perpetual
                .fUnitAccumulatedFunding
                .sub(account.fUnitAccumulatedFundingStart)
                .mul(fOldPosition);
        }
        //position
        account.fPositionBC = fOldPosition.add(_fDeltaPosition);
        //cash
        {
            int128 fNewCashCC = account.fCashCC.add(_fDeltaCashCC).sub(fFundingPayment);
            if (_traderAddr != address(this) && fNewCashCC < 0) {
                /* if liquidation happens too late, the trader cash becomes negative (margin used up).
                In this case, we cannot add the full amount to the AMM margin and leave the
                trader margin negative (trader will never pay). Hence we subtract the amount
                the trader cannot pay from the AMM margin (it is added previously to the AMM margin).
                */
                int128 fAmountOwed = fNewCashCC.neg();
                fNewCashCC = 0;
                MarginAccount storage accountAMM = marginAccounts[_perpetual.id][address(this)];
                accountAMM.fCashCC = accountAMM.fCashCC.sub(fAmountOwed);
            }
            account.fCashCC = fNewCashCC;
        }
        // update funding start for potential next funding payment
        account.fUnitAccumulatedFundingStart = _perpetual.fUnitAccumulatedFunding;
        //locked-in value in quote currency
        account.fLockedInValueQC = account.fLockedInValueQC.add(_fDeltaLockedInValueQC);

        // adjust open interest
        {
            int128 fDeltaOpenInterest;
            if (fOldPosition > 0) {
                fDeltaOpenInterest = fOldPosition.neg();
            }
            if (account.fPositionBC > 0) {
                fDeltaOpenInterest = fDeltaOpenInterest.add(account.fPositionBC);
            }
            _perpetual.fOpenInterest = _perpetual.fOpenInterest.add(fDeltaOpenInterest);
        }

        emit UpdateMarginAccount(_perpetual.id, _traderAddr, fFundingPayment);
    }

    /**
     * Pay the broker
     * @param _liqPool       reference to liq pool
     * @param _brokerAddr    address of broker
     * @param _fBrokerFeeCC  broker fee in collateral currency
     */
    function _transferBrokerFee(
        LiquidityPoolData storage _liqPool,
        address _brokerAddr,
        int128 _fBrokerFeeCC
    ) internal {
        if (_fBrokerFeeCC == 0) {
            return;
        }
        _transferFromVaultToUser(_liqPool, _brokerAddr, _fBrokerFeeCC);
    }

    /**
     * Transfer the specified fee amounts to the stakeholders
     * executor gets margin token (no choice of other tokens)
     * @param   _liqPool                    Reference to liquidity pool
     * @param   _executorAddr               The address of executor who will get rebate from the deal.
     * @param   _fPnLparticipantFee         amount to be sent to PnL participants
     * @param   _fReferralRebate            amount to be sent to executor
     * @param   _fTreasuryFee               amount for treasury to be split AMM/DF
     */
    function _transferProtocolFee(
        LiquidityPoolData storage _liqPool,
        address _executorAddr,
        int128 _fPnLparticipantFee,
        int128 _fReferralRebate,
        int128 _fTreasuryFee
    ) internal {
        require(_fPnLparticipantFee >= 0, "PnL participant should earn fee");
        require(_fReferralRebate >= 0, "executor should earn fee");

        //update PnL participant balance, AMM Cash balance, default fund balance
        if (_liqPool.fPnLparticipantsCashCC != 0) {
            _liqPool.fPnLparticipantsCashCC = _liqPool.fPnLparticipantsCashCC.add(
                _fPnLparticipantFee
            );
        } else {
            // currently no pnl participant funds, hence add the fee to the AMM fee
            _fTreasuryFee = _fTreasuryFee.add(_fPnLparticipantFee);
        }

        // contribution to DF
        _liqPool.fDefaultFundCashCC = _liqPool.fDefaultFundCashCC.add(_fTreasuryFee);

        // executor gets margin token
        _transferFromVaultToUser(_liqPool, _executorAddr, _fReferralRebate);
    }

    /**
     * Get the price for a given trade amount and market data
     * @param   _iPerpetualId  id of the perpetual
     * @param   _fTradeAmountBC  Amount to be traded (negative if trader goes short)
     * @param   _fIndexPrice spot prices of index S2 and S3. Send 0 to use the latest on-chain prices.
     * @return  _fPrice the price for the queried amount
     */
    function queryPerpetualPrice(
        uint24 _iPerpetualId,
        int128 _fTradeAmountBC,
        int128[2] calldata _fIndexPrice
    ) external view override returns (int128 _fPrice) {
        PerpetualData storage perpetual = _getPerpetual(_iPerpetualId);
        // prepare data
        AMMPerpLogic.AMMVariables memory ammState;
        AMMPerpLogic.MarketVariables memory marketState;
        // useOracle = true so that the oracle price can be used when no index price is given (not used internally)
        (ammState, marketState) = _prepareAMMAndMarketData(perpetual, true);
        // override with user values, if given
        if (_fIndexPrice[0] > 0) {
            marketState.fIndexPriceS2 = _fIndexPrice[0];
        }
        if (_fIndexPrice[1] > 0) {
            marketState.fIndexPriceS3 = _fIndexPrice[1];
        }
        _fPrice = _queryPriceGivenAMMAndMarketData(
            perpetual,
            _fTradeAmountBC,
            ammState,
            marketState
        );
    }

    /**
     * Prepare data for pricing functions in AMMPerpModule and get the price from the module
     * @param   _perpetual     The reference of perpetual storage.
     * @param   _fTradeAmount  Amount to be traded (negative if trader goes short)
     * @return  _fPrice the price for the queried amount
     */
    function _queryPriceFromAMM(
        PerpetualData storage _perpetual,
        int128 _fTradeAmount
    ) internal view returns (int128 _fPrice) {
        AMMPerpLogic.AMMVariables memory ammState;
        AMMPerpLogic.MarketVariables memory marketState;
        // useOracle = false because this method is called when trading or liquidating, which call _checkOracleStatus:
        // --> the settlement price is up to date and markets are open
        (ammState, marketState) = _prepareAMMAndMarketData(_perpetual, false);
        _fPrice = _queryPriceGivenAMMAndMarketData(
            _perpetual,
            _fTradeAmount,
            ammState,
            marketState
        );
    }

    function _queryPriceGivenAMMAndMarketData(
        PerpetualData storage _perpetual,
        int128 _fTradeAmount,
        AMMPerpLogic.AMMVariables memory _ammState,
        AMMPerpLogic.MarketVariables memory _marketState
    ) internal view returns (int128) {
        require(_perpetual.fCurrentTraderExposureEMA > 0, "pos size EMA is non-positive");

        // funding status
        int128 fMinSpread;
        int128 fIncentiveSpread;
        if (_fTradeAmount != 0) {
            fMinSpread = ConverterDec18.tbpsToABDK(_perpetual.minimalSpreadTbps);
            fIncentiveSpread = ConverterDec18.tbpsToABDK(_perpetual.incentiveSpreadTbps);
        }
        return
            _getAMMPerpLogic().calculatePerpetualPrice(
                _ammState,
                _marketState,
                _fTradeAmount,
                fMinSpread,
                fIncentiveSpread
            );
    }

    /**
     * Check if the price is better than the limit price.
     * @param   _isLong      True if the side is long.
     * @param   _fPrice       The price to be validate.
     * @param   _fPriceLimit  The limit price.
     */
    function _validatePrice(
        bool _isLong,
        int128 _fPrice,
        int128 _fPriceLimit
    ) internal pure returns (bool) {
        require(_fPrice > 0, "price must be positive");
        return _isLong ? _fPrice <= _fPriceLimit : _fPrice >= _fPriceLimit;
    }

    /**
     * Check if the mark price meets condition for stop order
     * Stop buy : buy if mark price >= trigger
     * Stop sell: sell if mark price <= trigger
     * @param   _isLong         True if the side is long.
     * @param   _fMarkPrice     Mark-price
     * @param   _fTriggerPrice  The trigger price.
     */
    function validateStopPrice(
        bool _isLong,
        int128 _fMarkPrice,
        int128 _fTriggerPrice
    ) external pure override {
        if (_fTriggerPrice == 0) {
            return;
        }
        // if stop order, mark price must meet trigger price condition
        bool isTriggerSatisfied = _isLong
            ? _fMarkPrice >= _fTriggerPrice
            : _fMarkPrice <= _fTriggerPrice;
        require(isTriggerSatisfied, "trigger cond not met");
    }

    /**
     * Get the max position amount of trader will be closed in the trade.
     * @param   _fPosition            Current position of trader.
     * @param   _fAmount              The trading amount of position.
     * @return  maxPositionToClose    The max position amount of trader will be closed in the trade.
     */
    function _shrinkToMaxPositionToClose(
        int128 _fPosition,
        int128 _fAmount
    ) internal pure returns (int128) {
        require(_fPosition != 0, "trader has no position to close");
        require(!_hasTheSameSign(_fPosition, _fAmount), "trade is close only");
        return _fAmount.abs() > _fPosition.abs() ? _fPosition.neg() : _fAmount;
    }

    /**
     * If the trader has opened position in the trade, his account should be
     * initial margin safe after the trade. If not, his account should be margin safe
     * @param   _perpetual          reference perpetual.
     * @param   _traderAddr         The address of trader.
     * @param   _executorAddr       The address of executor who will get rebate from the deal.
     * @param   _brokerAddr         The address of the broker
     * @param   _fDeltaPositionBC   The signed trade size(in base currency).
     * @param   _brkrFeeTbps        Broker fee in Tbps
     * @param   _protocolFeeTbps    Protocol fee in Tbps
     * @param   _hasOpened          Does the trader open a position or close?
     * @return  fee      The total fee collected from the trader after the trade
     */
    function _distributeFees(
        PerpetualData storage _perpetual,
        address _traderAddr,
        address _executorAddr,
        address _brokerAddr,
        int128 _fDeltaPositionBC,
        uint16 _brkrFeeTbps,
        uint16 _protocolFeeTbps,
        bool _hasOpened
    ) internal returns (int128) {
        // fees
        int128 fTreasuryFee;
        int128 fPnLparticipantFee;
        int128 fReferralRebate;
        int128 fBrokerFee;

        {
            (fPnLparticipantFee, fTreasuryFee, fReferralRebate, fBrokerFee) = _calculateFees(
                _perpetual,
                _traderAddr,
                _executorAddr,
                _brkrFeeTbps,
                _protocolFeeTbps,
                _fDeltaPositionBC.abs(),
                _hasOpened
            );
        }
        LiquidityPoolData storage liqPool = _getLiquidityPoolFromPerpetual(_perpetual.id);
        int128 fTotalFee = fPnLparticipantFee.add(fTreasuryFee).add(fReferralRebate).add(
            fBrokerFee
        );
        _updateTraderMargin(_perpetual, _traderAddr, fTotalFee.neg());

        // send fee to broker
        _transferBrokerFee(liqPool, _brokerAddr, fBrokerFee);
        // transfer protocol fee and referral rebate
        _transferProtocolFee(
            liqPool,
            _executorAddr,
            fPnLparticipantFee,
            fReferralRebate,
            fTreasuryFee
        );
        emit DistributeFees(
            liqPool.id,
            _perpetual.id,
            _traderAddr,
            fTreasuryFee,
            fPnLparticipantFee
        );
        return fTotalFee;
    }

    /**
     * @dev     Get the fees of the trade. If the margin of the trader is not enough for fee:
     *            1. If trader open position, the trade will be reverted.
     *            2. If trader close position, the fee will be decreasing in proportion according to
     *               the margin left in the trader's account
     *          The rebate of referral will only calculate the lpFee and treasuryFee.
     *          The vault fee will not be counted in.
     *
     * @param   _perpetual          The reference of pereptual storage.
     * @param   _traderAddr         The address of trader.
     * @param   _executorAddr       Address of executor.
     * @param   _brkrFeeTbps        Protocol fee in tbps
     * @param   _protocolFeeTbps    Protocol fee in tbps
     * @param   _fDeltaPos          The (abs) trade size in base currency.
     * @param   _hasOpened          true if trader is opening the position
     * @return  fPnLparticipantFee  PnL participant fee earning
     * @return  fTreasuryFee        treasury fee earning in collateral currency
     * @return  fReferralRebate     refferral fee earning in collateral currency
     * @return  fBrokerFee          broker fee in collateral currency
     */
    function _calculateFees(
        PerpetualData storage _perpetual,
        address _traderAddr,
        address _executorAddr,
        uint16 _brkrFeeTbps,
        uint16 _protocolFeeTbps,
        int128 _fDeltaPos,
        bool _hasOpened
    )
        internal
        view
        returns (
            int128 fPnLparticipantFee,
            int128 fTreasuryFee,
            int128 fReferralRebate,
            int128 fBrokerFee
        )
    {
        require(_fDeltaPos >= 0, "absolute trade value required");
        // convert to collateral currency
        _fDeltaPos = _fDeltaPos.mul(
            _getBaseToCollateralConversionMultiplier(_perpetual, false, false)
        );
        (
            fTreasuryFee,
            fPnLparticipantFee,
            fReferralRebate,
            fBrokerFee
        ) = _determineFeeInCollateral(
            _fDeltaPos,
            _perpetual.fReferralRebateCC,
            _brkrFeeTbps,
            _protocolFeeTbps,
            _executorAddr
        );
        int128 fTot = fTreasuryFee.add(fPnLparticipantFee).add(fReferralRebate).add(fBrokerFee);
        int128 factor = _scaleFees(_perpetual.id, _traderAddr, fTot, _hasOpened);
        if (factor != ONE_64x64) {
            fTreasuryFee = fTreasuryFee.mul(factor);
            fPnLparticipantFee = fPnLparticipantFee.mul(factor);
            fReferralRebate = fReferralRebate.mul(factor);
            fBrokerFee = fBrokerFee.mul(factor);
        }
    }

    /**
     * _scaleFees calculates a scaling factor if there is not enough margin to pay the fees
     * @param _iPerpetualId perpetual id
     * @param _traderAddr   trader address
     * @param fTotalFeeCC   total fee in collateral currency
     * @param _hasOpened    true if trader opens a new position
     * @return Scaling factor
     */
    function _scaleFees(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 fTotalFeeCC,
        bool _hasOpened
    ) internal view returns (int128) {
        // if the trader opens the position, 'available margin' is the margin balance - initial margin
        // requirement. If the trader closes, 'available margin' is the remaining margin balance
        if (!_hasOpened) {
            int128 fAvailableMargin = _getMarginViewLogic().getMarginBalance(
                _iPerpetualId,
                _traderAddr
            );
            if (fAvailableMargin <= 0) {
                return 0;
            } else if (fTotalFeeCC > fAvailableMargin) {
                // make sure the sum of fees = available margin
                return fAvailableMargin.div(fTotalFeeCC);
            }
        } else {
            //_hasOpened, get initial margin balance and ensure fees smaller
            int128 fAvailableMargin = _getMarginViewLogic().getAvailableMargin(
                _iPerpetualId,
                _traderAddr,
                true
            );
            // If the margin of the trader is not enough for fee: If trader open position, the trade will be reverted.
            require(fTotalFeeCC <= fAvailableMargin, "margin not enough");
        }
        return ONE_64x64;
    }

    /**
     * @dev This implementation replicates the calculation in PerpetualTradeFunctions::_doMarginCollateralActions
     * @param _fDeltaPosCC absolute value of position change in ABDK 64x64 format
     * @param _fReferralRebate absolute referral rebate in collateral currency (ABDK)
     * @param _brkrFeeTbps broker fee
     * @param _protocolFeeTbps exchange fee
     * @param _executorAddr address of executor, can be 0
     * @return fTreasuryFee fee that goes to protocol
     * @return fPnLparticipantFee fee that goes to pnl participants
     * @return fReferralRebate fixed fee for executor
     * @return fBrokerFee fee for broker (if _hasBroker, 0 otherwise)
     */
    function _determineFeeInCollateral(
        int128 _fDeltaPosCC,
        int128 _fReferralRebate,
        uint16 _brkrFeeTbps,
        uint16 _protocolFeeTbps,
        address _executorAddr
    )
        internal
        view
        returns (
            int128 fTreasuryFee,
            int128 fPnLparticipantFee,
            int128 fReferralRebate,
            int128 fBrokerFee
        )
    {
        int128 fTotalFeeRate;
        {
            fBrokerFee = ConverterDec18.tbpsToABDK(_brkrFeeTbps).mul(_fDeltaPosCC);
            fTotalFeeRate = ConverterDec18.tbpsToABDK(_protocolFeeTbps + _brkrFeeTbps);
            // these are rates, but we save memory by reusing variables
            (fTreasuryFee, fPnLparticipantFee) = _getBrokerFeeLogic().splitProtocolFee(
                _protocolFeeTbps
            );
        }
        // broker fee is accounted for, what's left is protocol = treasury + pnl part
        int128 fTotalFee = _fDeltaPosCC.mul(fTotalFeeRate).sub(fBrokerFee);
        fPnLparticipantFee = fTotalFee.mul(
            fPnLparticipantFee.div(fTreasuryFee.add(fPnLparticipantFee))
        );
        fTreasuryFee = fTotalFee.sub(fPnLparticipantFee);
        fReferralRebate = _executorAddr != address(0) ? _fReferralRebate : int128(0);
    }

    function getFunctionList() external pure virtual override returns (bytes4[] memory, bytes32) {
        bytes32 moduleName = Utils.stringToBytes32("PerpetualTradeLogic");
        bytes4[] memory functionList = new bytes4[](7);
        functionList[0] = this.executeTrade.selector;
        functionList[1] = this.preTrade.selector;
        functionList[2] = this.distributeFees.selector;
        functionList[3] = this.getMaxSignedOpenTradeSizeForPos.selector;
        functionList[4] = this.validateStopPrice.selector;
        functionList[5] = this.distributeFeesLiquidation.selector;
        functionList[6] = this.queryPerpetualPrice.selector;
        return (functionList, moduleName);
    }
}