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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IShareToken is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function setTransferRestricted(address _account) external;

    function burn(address _account, uint256 _amount) external;
}

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
        int128 fReferralRebateCC; //parameter: referall rebate in collateral currency
        //------- 7
        int128 fTargetDFSize; // target default fund size
        int128 fkStar; // signed trade size that minimizes the AMM risk
        //------- 8
        int128 fAMMTargetDD; // parameter: target distance to default (=inverse of default probability)
        int128 fAMMMinSizeCC; // parameter: minimal size of AMM pool, regardless of current exposure
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

contract PerpetualBaseFunctions is PerpStorage, ILibraryEvents {
    using ABDKMath64x64 for int128;
    using ConverterDec18 for int128;
    using ConverterDec18 for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    uint64 internal constant WITHDRAWAL_DELAY_TIME_SEC = 1 * 86400; // 1 day

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
        IERC20Upgradeable marginToken = IERC20Upgradeable(_pool.marginTokenAddress);
        // slither-disable-next-line arbitrary-send-erc20
        marginToken.safeTransferFrom(_userAddr, address(this), amountWei);
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
        IERC20Upgradeable marginToken = IERC20Upgradeable(_pool.marginTokenAddress);
        // transfer the margin token to the user
        marginToken.safeTransfer(_traderAddr, amountWei);
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

import "../../libraries/ConverterDec18.sol";
import "../../interface/IShareToken.sol";
import "../functions/PerpetualBaseFunctions.sol";
import "../interfaces/IPerpetualTreasury.sol";
import "../interfaces/IFunctionList.sol";
import "../../libraries/Utils.sol";
import "../../libraries/EnumerableSetUpgradeable.sol";

/**
 *
 * Add liquidity: share tokens are minted immediately. The liquidity is not considered
 * to be protocol owned yet until WITHDRAWAL_DELAY_TIME_SEC seconds passed. The amount
 * considered protocol owned is a linear interpolation between when it was added and
 * that time plus the delay.
 *
 * Remove liquidity: the liquidity provider calls remove liquidity upon which the
 * smart contract stores the amount that is to be removed (lpWithdrawMap).
 * The liquidity can be withdrawn by the liquidity provider after
 * WITHDRAWAL_DELAY_TIME_SEC time.
 *
 */
contract PerpetualTreasury is PerpetualBaseFunctions, IFunctionList, IPerpetualTreasury {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for int256;
    using ConverterDec18 for int128;
    using ConverterDec18 for int256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    int128 internal constant ONE_PERCENT = 184467440737095516;

    function _adjustAnchorOnLiquidityAdd(
        LiquidityPoolData storage _pool,
        uint128 _newShares
    ) internal {
        _pool.prevTokenAmount = _getShareTokenAmountForPricing(_pool);
        _pool.prevAnchor = uint64(block.timestamp);
        _pool.nextTokenAmount = _pool.nextTokenAmount + _newShares;
    }

    function _adjustAnchorOnLiquidityRemove(
        LiquidityPoolData storage _pool,
        uint128 _sharesToRemove
    ) internal {
        _pool.prevTokenAmount = _getShareTokenAmountForPricing(_pool);
        _pool.prevAnchor = uint64(block.timestamp);
        _pool.nextTokenAmount = _pool.nextTokenAmount - _sharesToRemove;
    }

    function getCollateralTokenAmountForPricing(uint8 _poolId) external view returns (int128) {
        LiquidityPoolData storage pool = liquidityPools[_poolId];
        return _getCollateralTokenAmountForPricing(pool);
    }

    /**
     * Pause pauseLiquidityProvision (withdrawing, adding) by maintainer in emergency situations
     * @param _poolId id of the pool to be paused
     * @param _pauseOn true to pause, false to allow withdrawals
     */
    function pauseLiquidityProvision(uint8 _poolId, bool _pauseOn) external onlyMaintainer {
        if (_pauseOn) {
            liquidityProvisionIsPaused[_poolId] = true;
        } else {
            delete liquidityProvisionIsPaused[_poolId];
        }
        emit LiquidityProvisionPaused(_pauseOn, _poolId);
    }

    /**
     * @notice  Adds liquidity to the liquidity pool.
     *          Liquidity provider deposits collateral and retrieves share tokens in exchange.
     *          The ratio of added cash to share token is determined by current liquidity.
     *          Can only called when the pool is running and there are perpetuals in normal state.
     *          Minimal amount equals broker collateral lot size
     * @param   _poolId        Reference to liquidity pool
     * @param   _tokenAmount   The amount of tokens in collateral currency to add, in margin token unit (dec N)
     */
    function addLiquidity(
        uint8 _poolId,
        uint256 _tokenAmount
    ) external override nonReentrant whenNotPaused {
        require(!liquidityProvisionIsPaused[_poolId], "LP paused");

        //inlines the modifier updateFundingAndPrices: updateFundingAndPrices
        uint24 iPerpetualId = _selectPerpetualIds(_poolId);
        _getUpdateLogic().updateFundingAndPricesBefore(iPerpetualId, false);

        // main
        _validateLiquidityData(_poolId, _tokenAmount);
        LiquidityPoolData storage pool = liquidityPools[_poolId];
        int128 fTokenAmount = int256(_tokenAmount).fromDecN(pool.marginTokenDecimals);
        require(fTokenAmount >= pool.fBrokerCollateralLotSize, "amt too small");

        _checkPoolState(pool);

        _rebalance(pool);

        _transferFromUserToVault(pool, msg.sender, fTokenAmount);

        int128 fShareToMint = _getShareAmountToMint(pool, fTokenAmount);
        IShareToken(pool.shareTokenAddress).mint(msg.sender, fShareToMint.toUDec18());
        pool.totalSupplyShareToken = uint128(IShareToken(pool.shareTokenAddress).totalSupply());
        _getRebalanceLogic().increasePoolCash(pool.id, fTokenAmount);

        _adjustAnchorOnLiquidityAdd(pool, uint128(fShareToMint.toUDec18()));
        emit LiquidityAdded(_poolId, msg.sender, _tokenAmount, fShareToMint.toUDec18());

        //inlines the modifier updateFundingAndPrices:
        _getUpdateLogic().updateFundingAndPricesAfter(iPerpetualId);
    }

    /**
     * @notice  Initiates removal of liquidity from the liquidity pool.
     *          After delay it can be withdrawn using executeLiquidityWithdrawal.
     *          Liquidity providers redeems share token then gets collateral back.
     *          The amount of collateral retrieved differs from the amount when liquidity was added,
     *          due to profit and loss.
     *          Can only be called if there is no perpetual in emergency state.
     *          Pool must be running at least one perpetual in CLEARED or NORMAL state.
     *
     * @param   _poolId            Reference to liquidity pool
     * @param   _shareAmount       The amount of share token to remove, in wei
     */
    function withdrawLiquidity(
        uint8 _poolId,
        uint256 _shareAmount
    ) external override nonReentrant whenNotPaused {
        require(!liquidityProvisionIsPaused[_poolId], "LP paused");
        address user = msg.sender;
        require(lpWithdrawMap[user][_poolId].shareTokens == 0, "removal in queue");
        //inlines the modifier updateFundingAndPrices: updateFundingAndPrices(uint24(0), _poolId)
        uint24 iPerpetualId = _selectPerpetualIds(_poolId);
        _getUpdateLogic().updateFundingAndPricesBefore(iPerpetualId, false);

        // main part
        _validateLiquidityData(_poolId, _shareAmount);
        LiquidityPoolData storage pool = liquidityPools[_poolId];
        _isLPWithdrawValid(pool);
        _rebalance(pool);

        // shareToken always has 18 decimals (created by ShareTokenFactory)
        IShareToken shareToken = IShareToken(pool.shareTokenAddress);
        shareToken.setTransferRestricted(msg.sender);

        // Ensure the users don't end up with dust positions
        // How many shares do we need for a lot?
        int128 fShareTknsForLot = _getShareAmountToMint(pool, pool.fBrokerCollateralLotSize);
        // user requested amount is less than half a lot -> set it to half a lot
        uint256 halfLotD18 = fShareTknsForLot.mul(0x8000000000000000).toUDec18();
        if (_shareAmount < halfLotD18) {
            _shareAmount = halfLotD18;
        }
        // 1) user has less share tokens than 1 lot left -> withdraw entire balance
        // 2) user wants to withdraw more than their balance -> withdraw the balance
        if (
            shareToken.balanceOf(user) < fShareTknsForLot.toUDec18() ||
            _shareAmount > shareToken.balanceOf(user)
        ) {
            _shareAmount = shareToken.balanceOf(user);
        }

        require(_shareAmount > 0, "nothing to withdraw");
        _adjustAnchorOnLiquidityRemove(pool, uint128(_shareAmount));
        lpWithdrawMap[user][_poolId].shareTokens = _shareAmount;
        lpWithdrawMap[user][_poolId].withdrawTimestamp = uint64(block.timestamp);
        activeWithdrawals[_poolId].add(user);
        emit LiquidityWithdrawalInitiated(_poolId, user, _shareAmount);
        //inlines the modifier updateFundingAndPrices:
        _getUpdateLogic().updateFundingAndPricesAfter(iPerpetualId);
    }

    /**
     * Execute liquidity withdrawal that has previously been initiated via
     * function withdrawLiquidity
     * Anyone can start the withdrawal and earn a fee so that LPs are incentivized to remove
     * the liquidity after announcing and not lose that fee
     * @param _poolId pool id from which we want to withdraw
     * @param _lpAddr address of the liquidity provider that initiated a withdrawal request
     */
    function executeLiquidityWithdrawal(
        uint8 _poolId,
        address _lpAddr
    ) external override nonReentrant whenNotPaused {
        require(!liquidityProvisionIsPaused[_poolId], "LP paused");
        require(lpWithdrawMap[_lpAddr][_poolId].shareTokens > 0, "init withdrwl");
        require(
            block.timestamp >= lpWithdrawMap[_lpAddr][_poolId].withdrawTimestamp + _getDelay(),
            "too early"
        );
        //inlines the modifier updateFundingAndPrices: updateFundingAndPrices
        uint24 iPerpetualId = _selectPerpetualIds(_poolId);
        _getUpdateLogic().updateFundingAndPricesBefore(iPerpetualId, false);

        // main part
        LiquidityPoolData storage pool = liquidityPools[_poolId];
        _isLPWithdrawValid(pool);
        uint256 shareAmount = lpWithdrawMap[_lpAddr][_poolId].shareTokens;

        int128 fTokenAmountToReturn = _getTokenAmountToReturn(
            pool,
            int256(shareAmount).fromDec18() // share tokens always have 18 decimals
        );
        IShareToken(pool.shareTokenAddress).burn(_lpAddr, shareAmount);
        pool.totalSupplyShareToken = uint128(IShareToken(pool.shareTokenAddress).totalSupply());
        _getRebalanceLogic().decreasePoolCash(pool.id, fTokenAmountToReturn);
        if (
            msg.sender != _lpAddr &&
            block.timestamp >= lpWithdrawMap[_lpAddr][_poolId].withdrawTimestamp + 2 * _getDelay()
        ) {
            // the lp waited too long, hence the one who executes earns 1% of the LP return
            int128 fFee = fTokenAmountToReturn.mul(ONE_PERCENT);
            if (fFee > pool.fBrokerCollateralLotSize) {
                // fee is capped at 1 broker lot size
                fFee = pool.fBrokerCollateralLotSize;
            }
            fTokenAmountToReturn = fTokenAmountToReturn.sub(fFee);
            _transferFromVaultToUser(pool, msg.sender, fFee);
        }
        _transferFromVaultToUser(pool, _lpAddr, fTokenAmountToReturn);
        activeWithdrawals[_poolId].remove(_lpAddr);
        delete lpWithdrawMap[_lpAddr][_poolId];
        uint256 tokenAmountDecN = fTokenAmountToReturn.toUDecN(pool.marginTokenDecimals);
        emit LiquidityRemoved(_poolId, _lpAddr, tokenAmountDecN, shareAmount);

        //inlines the modifier updateFundingAndPrices:
        _getUpdateLogic().updateFundingAndPricesAfter(iPerpetualId);
    }

    /**
     * @notice  Validates input data.
     *
     * @param   _poolId      Reference to liquidity pool
     * @param   _amount      The amount of token to add. dec18
     */
    function _validateLiquidityData(uint8 _poolId, uint256 _amount) internal view {
        require(_poolId > 0 && _poolId <= iPoolCount, "pool index out of range");
        require(_amount > 0, "invalid amount");
    }

    /**
     * @notice Checks pool state.
     * @dev throws error if pool isn't running or doesn't have active perpetuals
     *
     * @param   _pool    Reference to liquidity pool
     */
    function _checkPoolState(LiquidityPoolData storage _pool) internal view {
        require(_pool.isRunning, "not running");
        uint256 length = perpetualIds[_pool.id].length;
        bool isActivePerpetuals;
        for (uint256 i = 0; i < length; i++) {
            uint24 id = perpetualIds[_pool.id][i];
            PerpetualData storage perpetual = perpetuals[_pool.id][id];
            if (perpetual.state == PerpetualState.NORMAL) {
                isActivePerpetuals = true;
                break;
            }
        }
        require(isActivePerpetuals, "no active perpetual");
    }

    /**
     * @notice Checks whether LP can remove liquidity: no pool in emergency
     * and at least one pool cleared or normal
     * @dev throws error if pool isn't running or doesn't have active perpetuals
     *
     * @param   _pool    Reference to liquidity pool
     */
    function _isLPWithdrawValid(LiquidityPoolData storage _pool) internal view {
        require(_pool.isRunning, "not running");
        uint256 length = perpetualIds[_pool.id].length;
        bool isWithdrawValid;
        for (uint256 i = 0; i < length; i++) {
            uint24 id = perpetualIds[_pool.id][i];
            PerpetualData storage perpetual = perpetuals[_pool.id][id];
            require(perpetual.state != PerpetualState.EMERGENCY, "no withdraw in emergency");
            if (
                perpetual.state == PerpetualState.NORMAL ||
                perpetual.state == PerpetualState.CLEARED
            ) {
                isWithdrawValid = true;
            }
        }
        require(isWithdrawValid, "no active perpetual");
    }

    /**
     * @notice  Calculates amount of share tokens to be minted.
     *
     * @param   _pool        Reference to liquidity pool
     * @param   _fAmount     The amount of token to add. 64.64 float
     * @return shares to mint for the given token amount in ABDK64.64 format
     */
    function _getShareAmountToMint(
        LiquidityPoolData storage _pool,
        int128 _fAmount
    ) internal view returns (int128) {
        int128 fShareTotalSupply = int256(IERC20(_pool.shareTokenAddress).totalSupply())
            .fromDec18();
        int128 fShareToMint;
        if (fShareTotalSupply == 0) {
            fShareToMint = _fAmount;
        } else {
            fShareToMint = _fAmount.mul(fShareTotalSupply).div(_pool.fPnLparticipantsCashCC);
        }
        return fShareToMint;
    }

    /**
     * @notice  Calculates amount of tokens to be returned.
     *
     * @param   _pool        Reference to liquidity pool
     * @param   _fShareAmount     The amount of share token to burn. 64.64 float
     */
    function _getTokenAmountToReturn(
        LiquidityPoolData storage _pool,
        int128 _fShareAmount
    ) internal view returns (int128) {
        int128 fShareTotalSupply = int256(IERC20(_pool.shareTokenAddress).totalSupply())
            .fromDec18();
        int128 fTokenAmountToReturn;
        if (_pool.fPnLparticipantsCashCC > 0) {
            fTokenAmountToReturn = _fShareAmount.mul(_pool.fPnLparticipantsCashCC).div(
                fShareTotalSupply
            );
        }
        return fTokenAmountToReturn;
    }

    /**
     * Get the current share-token price for the given pool.
     * Price is in decimal 18 format
     * @param _poolId id of the pool
     * @return price in decimal-18 format
     */
    function getShareTokenPriceD18(uint8 _poolId) external view override returns (uint256 price) {
        PerpStorage.LiquidityPoolData storage pool = liquidityPools[_poolId];
        int128 fShareTotalSupply = int256(IERC20(pool.shareTokenAddress).totalSupply())
            .fromDec18();
        if (fShareTotalSupply > 0) {
            price = (pool.fPnLparticipantsCashCC).div(fShareTotalSupply).toUDec18();
        } else {
            price = 1e18; //=1
        }
    }

    /**
     * To re-balance the AMM margin to the initial margin for a maximum of 10 perpetuals
     * in the given pool.
     * @dev test in moduloLoop.py
     * @param   _pool Reference to liquidity pool
     */
    function _rebalance(LiquidityPoolData storage _pool) internal {
        uint256 length = _pool.iPerpetualCount;
        // restrict to a maximum of 10 perpetuals selected using block.number to avoid gas issues
        uint256 start = length > 10 ? (block.number % (length - 9)) : 0;
        uint256 end = length > 10 ? start + 10 : length;
        for (uint256 i = start; i < end; i++) {
            uint24 id = perpetualIds[_pool.id][i];
            _getRebalanceLogic().rebalance(id);
        }
    }

    /**
     * For a given amount of shares, we calculate the amount of
     * collateral tokens to return
     * @param _poolId id of the liquidity pool
     * @param _shareAmount amount of shares
     */
    function getTokenAmountToReturn(
        uint8 _poolId,
        uint256 _shareAmount
    ) external view override returns (uint256) {
        PerpStorage.LiquidityPoolData storage pool = liquidityPools[_poolId];
        return _getTokenAmountToReturn(pool, int256(_shareAmount).fromDec18()).toUDec18();
    }

    /**
     * Getter function to retrieve a given number of liquidity-provider WithdrawRequests for a poolId
     * @param _poolId id of the pool
     * @param _fromIdx start the address array at this index
     * @param _numRequests maximal number of responses
     */
    function getWithdrawRequests(
        uint8 _poolId,
        uint256 _fromIdx,
        uint256 _numRequests
    ) external view returns (WithdrawRequest[] memory) {
        // Get the addresses from activeWithdrawals
        address[] memory addresses = activeWithdrawals[_poolId].enumerateAll();
        WithdrawRequest[] memory requests = new WithdrawRequest[](_numRequests); // Create an array to store the WithdrawRequest structs
        uint256 counter = 0;
        for (uint256 i = _fromIdx; i < addresses.length && counter < _numRequests; i++) {
            // Get the WithdrawRequest for the address and poolId
            WithdrawRequest memory request = lpWithdrawMap[addresses[i]][_poolId];
            request.lp = addresses[i];
            requests[counter] = request; // Store the WithdrawRequest in the array
            counter++;
        }
        return requests;
    }

    function getFunctionList() external pure virtual override returns (bytes4[] memory, bytes32) {
        bytes32 moduleName = Utils.stringToBytes32("PerpetualTreasury");
        bytes4[] memory functionList = new bytes4[](8);
        functionList[0] = this.addLiquidity.selector;
        functionList[1] = this.withdrawLiquidity.selector;
        functionList[2] = this.executeLiquidityWithdrawal.selector;
        functionList[3] = this.getTokenAmountToReturn.selector;
        functionList[4] = this.getCollateralTokenAmountForPricing.selector;
        functionList[5] = this.pauseLiquidityProvision.selector;
        functionList[6] = this.getShareTokenPriceD18.selector;
        functionList[7] = this.getWithdrawRequests.selector;
        return (functionList, moduleName);
    }
}