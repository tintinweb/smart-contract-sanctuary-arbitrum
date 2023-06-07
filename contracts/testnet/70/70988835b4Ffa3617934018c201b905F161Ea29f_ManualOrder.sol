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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 * ```solidity
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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ExactInputParams} from "./StructList.sol";

interface MultiDexRouter {
    function swapExactTokensForToken(ExactInputParams memory params) external payable returns (uint256 amountOut);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address[] memory _routerAddressList,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    )
    external returns (uint256 _amountOut);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address[] calldata _routerAddressList,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256 _amountOut);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address[] calldata _routerAddressList,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;

    function balanceOf(address guy) external returns (uint);

    function approve(address guy, uint wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20Metadata as IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {taskInfoItem,Module, OrderType, ModuleData, TxItem, UserInfoItem, TokenInfoItem, TokenInfoItem2, LimitItem, TccItemV2, TcdItem, TaskConfig, BalanceItem, TokenItem, FeeItem, FeeItem2, SwapTokenItem, SwapEventItem, OrderEventItem, CreateItem, GasItem, GasItemList, ExactInputParams} from "./StructList.sol";
import {MultiDexRouter} from "./IMultiDexRouter.sol";
import {OrderBase} from "./OrderBase.sol";
import {IWETH} from "./IWETH.sol";

contract ManualOrder is OrderBase {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    EnumerableSet.Bytes32Set private activeManualOrderSet;
    mapping(address => EnumerableSet.Bytes32Set) private userAllLimitOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userActiveLimitOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userAllSwapOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userActiveSwapOrderList;
    mapping(address => EnumerableSet.AddressSet) private userTokenSet;
    mapping(address => EnumerableSet.UintSet) private userTxSet;

    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        address _USDTPoolAddress,
        address _WETH,
        address _USDT
    ) OrderBase (_approveAmount, _ops, _fundsOwner, _USDTPoolAddress, _WETH, _USDT){}

    function createManualOrder(TccItemV2 calldata _tcc, uint256 _tokenAmount) external nonReentrant payable {
        address _user = msg.sender;
        //uint256 _wethAmount;
        //        TccItem memory _tcc = _tccList[0];
        CreateItem memory _y = new CreateItem[](1)[0];
        //兼容单向兑换
        //        if (_tcc._swapRouter2.length > 0) {
        //            require(checkManualOrder(_tcc._swapRouter, _tcc._swapRouter2), "U02");
        //        }
        require(_tcc._type != OrderType.LimitOrder, "U03");
        require(!taskNameList[_tcc._taskName], "U04");
        taskNameList[_tcc._taskName] = true;
        _y.md5 = keccak256(abi.encodePacked(_tcc._taskName));
        require(!md5List[_y.md5], "U05");
        md5List[_y.md5] = true;
        if (_tcc._interval <= 20) {
            _y.execData = abi.encodeCall(this.doManualOrder, (_user, _y.md5));
            _y.moduleData = ModuleData({
                modules: new Module[](1),
                args: new bytes[](1)
            });
            _y.moduleData.modules[0] = Module.PROXY;
            _y.moduleData.args[0] = abi.encodePacked(_y.md5);
        } else {
            _y.execData = abi.encodeCall(this.doManualOrder, (_user, _y.md5));
            _y.moduleData = ModuleData({
                modules: new Module[](2),
                args: new bytes[](2)
            });
            _y.moduleData.modules[0] = Module.TIME;
            _y.moduleData.modules[1] = Module.PROXY;
            _y.moduleData.args[0] = _timeModuleArg(block.timestamp, _tcc._interval);
            _y.moduleData.args[1] = abi.encodePacked(_y.md5);
        }
        _y.taskId = _createTask(address(this), _y.execData, _y.moduleData, ETH);
        if (_tcc._type == OrderType.ManualOrder) {
            activeManualOrderSet.add(_y.taskId);
        }
        require(!taskIdStatusList[_y.taskId], "U06");
        taskIdStatusList[_y.taskId] = true;
        taskList[taskAmount] = _y.taskId;
        userTaskList[_user].push(_y.taskId);
        md5TaskList[_y.md5] = _y.taskId;
        _y._taskConfig = new TaskConfig[](1)[0];
        _y._taskConfig.tcc = _tcc;
        _y.swapInToken = _tcc._swapPathConfig1._swapPathList[0];
        _y.swapOutToken = _tcc._swapPathConfig1._swapPathList[_tcc._swapPathConfig1._swapPathList.length - 1];
        if (!userTokenSet[_user].contains(_y.swapInToken)) {
            userTokenSet[_user].add(_y.swapInToken);
        }
        if (_y.swapInToken != weth) {
            _y.tokenAmount0 = IERC20(_y.swapInToken).balanceOf(address(this));
            IERC20(_y.swapInToken).transferFrom(_user, address(this), _tokenAmount);
            _y.tokenAmount1 = IERC20(_y.swapInToken).balanceOf(address(this));
            _y.tokenAmount = _y.tokenAmount1.sub(_y.tokenAmount0);
            emit FundsEvent(block.number, block.timestamp, _user, _y.swapInToken, IERC20(_y.swapInToken).decimals(), _y.tokenAmount, "depositToken");
            require(msg.value > 0, "e001");
            uint256 _ethAmount = msg.value;
            userInfoList[_user].ethDepositAmount = userInfoList[_user].ethDepositAmount.add(_ethAmount);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.add(_ethAmount);
            emit FundsEvent(block.number, block.timestamp, _user, weth, 18, _ethAmount, "depositGas");
        } else {
            require(msg.value > _tokenAmount, "e001");
            _y.tokenAmount = _tokenAmount;
            IWETH(weth).deposit{value: _y.tokenAmount}();
            //            try IWETH(weth).deposit{value: _y.tokenAmount}(){} catch(string memory e){}
            // emit FundsEvent(block.number, block.timestamp, _user, _y.swapInToken, IERC20(_y.swapInToken).decimals(), _y.tokenAmount, "depositToken");
            uint256 _ethAmount = msg.value.sub(_tokenAmount);
            userInfoList[_user].ethDepositAmount = userInfoList[_user].ethDepositAmount.add(_ethAmount);
            userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.add(_ethAmount);
            //emit FundsEvent(block.number, block.timestamp, _user, weth, 18, _ethAmount, "depositGas");

        }
        userTokenAmountList[_user][_y.swapInToken].depositAmount = userTokenAmountList[_user][_y.swapInToken].depositAmount.add(_y.tokenAmount);
        userTokenAmountList[_user][_y.swapInToken].leftAmount = userTokenAmountList[_user][_y.swapInToken].leftAmount.add(_y.tokenAmount);
        //        _y._taskConfig = new TaskConfig[](1)[0];
        //        _y._taskConfig.tcc._taskName = _tcc._taskName;
        //        _y._taskConfig.tcc._routerAddressList = _tcc._routerAddressList;
        //        _y._taskConfig.tcc._swapRouter = _tcc._swapRouter;
        //        _y.swapInToken = _tcc._swapRouter[0];
        //        _y.swapOutToken = _tcc._swapRouter[_tcc._swapRouter.length - 1];
        //        if (_y.swapInToken != weth) {
        //            _y.tokenAmount0 = IERC20(_y.swapInToken).balanceOf(address(this));
        //            IERC20(_y.swapInToken).transferFrom(_user, address(this), _tcc._limitItem._swapInAmount);
        //            _y.tokenAmount1 = IERC20(_y.swapInToken).balanceOf(address(this));
        //            _y.tokenAmount = _y.tokenAmount1.sub(_y.tokenAmount0);
        //        } else {
        //            _y.tokenAmount = _tcc._limitItem._swapInAmount;
        //        }
        //        if (!userTokenSet[_user].contains(_y.swapInToken)) {
        //            userTokenSet[_user].add(_y.swapInToken);
        //        }
        //        if (_y.swapInToken == weth) {
        //            //将eth转换为weth
        //            IWETH(weth).deposit{value: _y.tokenAmount}();
        //            _wethAmount = _wethAmount.add(_y.tokenAmount);
        //        }
        //        userTokenAmountList[_user][_y.swapInToken].depositAmount = userTokenAmountList[_user][_y.swapInToken].depositAmount.add(_y.tokenAmount);
        //        userTokenAmountList[_user][_y.swapInToken].leftAmount = userTokenAmountList[_user][_y.swapInToken].leftAmount.add(_y.tokenAmount);
        //        emit FundsEvent(block.number, block.timestamp, _user, _y.swapInToken, IERC20(_y.swapInToken).decimals(), _y.tokenAmount, "depositToken");
        //        _y._taskConfig.tcc._limitItem._swapInAmount = _y.tokenAmount;
        //        _y._taskConfig.tcc._limitItem._swapInDecimals = IERC20(_y.swapInToken).decimals();
        //        _y._taskConfig.tcc._limitItem._swapOutDecimals = IERC20(_y.swapOutToken).decimals();
        //        if (_tcc._limitItem._swapPriceZone.length == 2) {
        //            require(_tcc._limitItem._swapPriceZone[1] > _tcc._limitItem._swapPriceZone[0]);
        //            _y._taskConfig.tcc._limitItem._swapPriceZone = _tcc._limitItem._swapPriceZone;
        //        }
        //        _y._taskConfig.tcc._start_end_Time = _tcc._start_end_Time;
        //        _y._taskConfig.tcc._maxFeePerTx = _tcc._maxFeePerTx;
        //        _y._taskConfig.tcc._type = _tcc._type;
        //        _y._taskConfig.tcc._swapRouter2 = _tcc._swapRouter2;
        //        _y._taskConfig.tcc._interval = _tcc._interval;
        //        _y._taskConfig.tcc._timeList = _tcc._timeList;
        //        _y._taskConfig.tcc._timeIntervalList = _tcc._timeIntervalList;
        //        _y._taskConfig.tcc._swapAmountList = _tcc._swapAmountList;
        //        _y._taskConfig.tcc._maxtxAmount = _tcc._maxtxAmount;
        //        _y._taskConfig.tcc._maxSpendTokenAmount = _tcc._maxSpendTokenAmount;
        //        _y._taskConfig.tcc._swapAmountList = _tcc._swapAmountList;
        _y._taskConfig.tcd = TcdItem({
            _index: taskAmount,
            _owner: _user,
            _execAddress: address(this),
            _execDataOrSelector: _y.execData,
            _moduleData: _y.moduleData,
            _feeToken: ETH,
            _status: true,
            _taskExTimes: 0,
            _totalFee: 0,
            _md5: _y.md5,
            _taskId: _y.taskId,
            _swapInToken: _y.swapInToken,
            _swapOutToken: _y.swapOutToken,
            _maxSpendTokenAmount: 0, //限价单用到
            _completed: false //限价单用到
        });
        taskConfigList[_y.taskId] = _y._taskConfig;
        userAllSwapOrderList[_user].add(_y.taskId);
        userActiveSwapOrderList[_user].add(_y.taskId);
        //emit CreateTaskEvent(block.number, block.timestamp, _user, _y.md5, taskAmount, _y.taskId, _tcc._type, _tcc);
        taskAmount = taskAmount.add(1);
        //        }
        //require(msg.value == _ethAmount.add(_wethAmount), "U01");
        //        userInfoList[_user].ethDepositAmount = userInfoList[_user].ethDepositAmount.add(_ethAmount);
        //        userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.add(_ethAmount);
        //        emit FundsEvent(block.number, block.timestamp, _user, weth, 18, _ethAmount, "depositGas");
    }

    function doManualOrder(address _user, bytes32 _md5) external nonReentrant {
        uint256 gas0 = gasleft();
        //gasItemList memory _gasList = new gasItemList[](1)[0];
        //要求触发者是白名单
        //require(msg.sender == dedicatedMsgSender || dedicatedMsgSenderList[msg.sender], "U08");
        SwapTokenItem memory x = new SwapTokenItem[](1)[0];
        //或者当天日期
        x.day = getYearMonthDay(block.timestamp);
        //得到taskId
        x.taskId = md5TaskList[_md5];
        TaskConfig storage y = taskConfigList[x.taskId];
        //要求gasPrice不能过高
        if (y.tcc._type == OrderType.ManualOrder) {
            require(tx.gasprice <= gasPriceLimitForManual, "U07");
        } else {
            require(tx.gasprice <= gasPriceLimitForAutomate, "U07");
            require(msg.sender == dedicatedMsgSender || dedicatedMsgSenderList[msg.sender], "U08");
        }
        //要求当前时间戳距离上次执行时间超过执行的时间差
        require(block.timestamp >= (lastExecutedTimeList[_md5]).add(y.tcc._timeIntervalList[lastTimeIntervalIndexList[x.taskId]]), "U08");
        //要求当前时间戳在指定区间
        require(getInTimeZone(y.tcc._start_end_Time, y.tcc._timeList), "U09");
        //要求当前类型是刷单模式
        require(y.tcc._type != OrderType.LimitOrder, "U10");
        //获取当前刷单的代币swapInToken,swapOutToken
        x._TokenItem.swapInToken = y.tcd._swapInToken;
        x._TokenItem.swapOutToken = y.tcd._swapOutToken;
        //当前要刷单的数量
        x.claimAmount = y.tcc._swapAmountList[lastSwapAmountIndexList[x.taskId]];
        require(x.claimAmount > 0, "U13");
        //要求当天刷单次数不超标
        require(txHistoryList[x.taskId][x.day]._totalTx.add(1) <= y.tcc._maxtxAmount, "U11");
        //要求当天刷单金额不超标
        require(txHistoryList[x.taskId][x.day]._totalSpendTokenAmount.add(x.claimAmount) <= y.tcc._maxSpendTokenAmount, "U12");
        //要求用户剩余代币足够用于交易
        require(userTokenAmountList[_user][x._TokenItem.swapInToken].leftAmount >= x.claimAmount, "U14");
        //第一步交易代币A的数量
        x.swapInAmount = x.claimAmount;
        //判断是否有授权额度,如果没有则授权
        if (!y.tcc.isV3) {
            if (IERC20(x._TokenItem.swapInToken).allowance(address(this), multiDexRouterAddress) < x.swapInAmount) {
                IERC20(x._TokenItem.swapInToken).approve(multiDexRouterAddress, approveAmount);
            }
        } else {
            if (IERC20(x._TokenItem.swapInToken).allowance(address(this), V3Dex) < x.swapInAmount) {
                IERC20(x._TokenItem.swapInToken).approve(V3Dex, approveAmount);
            }
        }
        //完成第一次交易,得到代币B x.swapInAmount
        address _to = y.tcc._swapPathConfig2._swapPathList.length > 0 ? address(this) : _user;
        //如果是刷单模式
        if (y.tcc._swapPathConfig2._swapPathList.length > 0) {
            if (!y.tcc.isV3) {
                x.swapInAmount = MultiDexRouter(multiDexRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    y.tcc._swapPathConfig1._routerAddressListV2,
                    x.swapInAmount,
                    0,
                    y.tcc._swapPathConfig1._swapPathList,
                    _to,
                    block.timestamp
                );
            } else {
                x.swapInAmount = MultiDexRouter(V3Dex).swapExactTokensForToken(
                    ExactInputParams({
                        factory: y.tcc._swapPathConfig1._factoryV3[0],
                        tokenList: y.tcc._swapPathConfig1._swapPathList,
                        feeList: y.tcc._swapPathConfig1._feeListV3,
                        recipient: _to,
                        amountIn: x.swapInAmount,
                        amountOutMinimum: 0,
                        sqrtPriceLimitX96: 0,
                        forceUseWETH: true
                    })
                );
            }
        } else {
            //            if (y.tcc._swapRouter[0] == weth) {
            //                x.swapInAmount = MultiDexRouter(multiDexRouterAddress).swapExactETHForTokensSupportingFeeOnTransferTokens{value : x.swapInAmount}(
            //                    y.tcc._routerAddressList,
            //                    0,
            //                    y.tcc._swapRouter,
            //                    _to,
            //                    block.timestamp
            //                );
            //            }
            //            else
            uint256 _in = x.swapInAmount;
            if (y.tcc._swapPathConfig1._swapPathList[y.tcc._swapPathConfig1._swapPathList.length - 1] == weth) {
                if (!y.tcc.isV3) {
                    x.swapInAmount = MultiDexRouter(multiDexRouterAddress).swapExactTokensForETHSupportingFeeOnTransferTokens(
                        y.tcc._swapPathConfig1._routerAddressListV2,
                        x.swapInAmount,
                        0,
                        y.tcc._swapPathConfig1._swapPathList,
                        _to,
                        block.timestamp
                    );
                } else {
                    x.swapInAmount = MultiDexRouter(V3Dex).swapExactTokensForToken(
                        ExactInputParams({
                            factory: y.tcc._swapPathConfig1._factoryV3[0],
                            tokenList: y.tcc._swapPathConfig1._swapPathList,
                            feeList: y.tcc._swapPathConfig1._feeListV3,
                            recipient: _to,
                            amountIn: x.swapInAmount,
                            amountOutMinimum: 0,
                            sqrtPriceLimitX96: 0,
                            forceUseWETH: false
                        })
                    );
                }
            } else {
                if (!y.tcc.isV3) {
                    x.swapInAmount = MultiDexRouter(multiDexRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        y.tcc._swapPathConfig1._routerAddressListV2,
                        x.swapInAmount,
                        0,
                        y.tcc._swapPathConfig1._swapPathList,
                        _to,
                        block.timestamp
                    );
                } else {
                    x.swapInAmount = MultiDexRouter(V3Dex).swapExactTokensForToken(
                        ExactInputParams({
                            factory: y.tcc._swapPathConfig1._factoryV3[0],
                            tokenList: y.tcc._swapPathConfig1._swapPathList,
                            feeList: y.tcc._swapPathConfig1._feeListV3,
                            recipient: _to,
                            amountIn: x.swapInAmount,
                            amountOutMinimum: 0,
                            sqrtPriceLimitX96: 0,
                            forceUseWETH: true
                        })
                    );
                }
            }
            //成交在执行的价格区间
            require(x.swapInAmount.mul(10 ** 18) > y.tcc._swapPathConfig1._swapPriceZone[0].mul(_in) && x.swapInAmount.mul(10 ** 18) < y.tcc._swapPathConfig1._swapPriceZone[1].mul(_in), "P09");
        }
        //兼容单向兑换
        if (y.tcc._swapPathConfig2._swapPathList.length > 0) {
            //收取一部分代币B
            x.swapFee = x.swapInAmount.mul(feeRate).div(feeAllRate);
            IERC20(x._TokenItem.swapOutToken).transfer(usdtPoolAddress, x.swapFee);
            //得到下一步交易代币B的数量
            x.swapInAmount = x.swapInAmount.sub(x.swapFee);
            //判断是否有授权额度,如果没有则授权
            if (!y.tcc.isV3) {
                if (IERC20(x._TokenItem.swapOutToken).allowance(address(this), multiDexRouterAddress) < x.swapInAmount) {
                    IERC20(x._TokenItem.swapOutToken).approve(multiDexRouterAddress, approveAmount);
                }
            } else {
                if (IERC20(x._TokenItem.swapOutToken).allowance(address(this), V3Dex) < x.swapInAmount) {
                    IERC20(x._TokenItem.swapOutToken).approve(V3Dex, approveAmount);
                }
            }
            //完成第二次交易,得到代币A的数量
            uint256 out;
            if (!y.tcc.isV3) {
                out = MultiDexRouter(multiDexRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    y.tcc._swapPathConfig2._routerAddressListV2,
                    x.swapInAmount,
                    0,
                    y.tcc._swapPathConfig2._swapPathList,
                    address(this),
                    block.timestamp
                );
            } else {
                out = MultiDexRouter(V3Dex).swapExactTokensForToken(
                    ExactInputParams({
                        factory: y.tcc._swapPathConfig2._factoryV3[0],
                        tokenList: y.tcc._swapPathConfig2._swapPathList,
                        feeList: y.tcc._swapPathConfig2._feeListV3,
                        recipient: _to,
                        amountIn: x.swapInAmount,
                        amountOutMinimum: 0,
                        sqrtPriceLimitX96: 0,
                        forceUseWETH: true
                    })
                );
            }
            //得到消耗的代币数量
            x.spendSwapInToken = x.claimAmount.sub(out);
        } else {
            x.spendSwapInToken = x.claimAmount;
        }
        //要求用户剩余的代币A足够交易消耗
        require(userTokenAmountList[_user][x._TokenItem.swapInToken].leftAmount >= x.spendSwapInToken, "U15");
        //用户的代币剩余额度和使用额度进行累计
        userTokenAmountList[_user][x._TokenItem.swapInToken].leftAmount = userTokenAmountList[_user][x._TokenItem.swapInToken].leftAmount.sub(x.spendSwapInToken);
        userTokenAmountList[_user][x._TokenItem.swapInToken].usedAmount = userTokenAmountList[_user][x._TokenItem.swapInToken].usedAmount.add(x.spendSwapInToken);
        //交易完成当天刷单次数+1
        txHistoryList[x.taskId][x.day]._totalTx = txHistoryList[x.taskId][x.day]._totalTx.add(1);
        //交易完成当天刷单金额累计
        txHistoryList[x.taskId][x.day]._totalSpendTokenAmount = txHistoryList[x.taskId][x.day]._totalSpendTokenAmount.add(x.claimAmount);
        //交易完成后,任务的执行次数+1
        y.tcd._taskExTimes = y.tcd._taskExTimes.add(1);
        //交易完成后记录本次执行时间
        lastExecutedTimeList[_md5] = block.timestamp;
        //推算下次的时间间隔
        lastTimeIntervalIndexList[x.taskId] = lastTimeIntervalIndexList[x.taskId].add(1);
        if (lastTimeIntervalIndexList[x.taskId] >= y.tcc._timeIntervalList.length) {
            lastTimeIntervalIndexList[x.taskId] = 0;
        }
        //推算下次的交易数量
        lastSwapAmountIndexList[x.taskId] = lastSwapAmountIndexList[x.taskId].add(1);
        if (lastSwapAmountIndexList[x.taskId] >= y.tcc._swapAmountList.length) {
            lastSwapAmountIndexList[x.taskId] = 0;
        }
        //预留使用平台币收费
        // if (devFee > 0 && address(devToken) != address(0)) {
        //     require(userInfoList[_user].devAmount >= devFee, "U16");
        //     devToken.transfer(USDTPoolAddress, devFee);
        //     userInfoList[_user].devAmount = userInfoList[_user].devAmount.sub(devFee);
        //     userInfoList[_user].devUsedAmount = userInfoList[_user].devUsedAmount.add(devFee);
        // }
        uint256 gas1 = gasleft();
        uint256 gasUsed = gas0.sub(gas1);
        if (y.tcc._type == OrderType.ManualOrder) {
            x._feeItem2.fee = gasUsed.add(takeFeeGas).mul(gasRate).mul(tx.gasprice).div(100);
        }
        else if (y.tcc._type == OrderType.AutomateOrder) {
            (x._feeItem2.fee, x._feeItem2.feeToken) = _getFeeDetails();
        }
        x._feeItem.poolFee = x._feeItem2.fee.mul(swapRate).div(swapAllRate);
        x._feeItem.allFee = x._feeItem2.fee.add(x._feeItem.poolFee);
        require(x._feeItem.allFee <= y.tcc._maxFeePerTx, "U17");
        require(x._feeItem.allFee <= userInfoList[_user].ethAmount, "U18");
        if (y.tcc._type == OrderType.ManualOrder) {
            payable(msg.sender).transfer(x._feeItem2.fee);
        }
        else if (y.tcc._type == OrderType.AutomateOrder) {
            _transfer(x._feeItem2.fee, x._feeItem2.feeToken);
        }
        payable(usdtPoolAddress).transfer(x._feeItem.poolFee);
        //txHistoryList[x.taskId][x.day]._totalFee = txHistoryList[x.taskId][x.day]._totalFee.add(x._feeItem.allFee);
        userInfoList[_user].ethAmount = userInfoList[_user].ethAmount.sub(x._feeItem.allFee);
        userInfoList[_user].ethUsedAmount = userInfoList[_user].ethUsedAmount.add(x._feeItem.allFee);
        //平台总触发流水累计
        totalFee = totalFee.add(x._feeItem.allFee);
        //用户触发费用累计
        usertotalFeeList[tx.origin] = usertotalFeeList[tx.origin].add(x._feeItem2.fee);
        y.tcd._totalFee = y.tcd._totalFee.add(x._feeItem2.fee);
        SwapEventItem memory t = SwapEventItem(x._TokenItem.swapInToken, x._TokenItem.swapOutToken, IERC20(x._TokenItem.swapInToken).decimals(), IERC20(x._TokenItem.swapOutToken).decimals(), x.claimAmount, x.spendSwapInToken, x._feeItem.poolFee, x.claimAmount, 0, x.swapInAmount);

        //本次交易细节上链,可选
        //orderInfoList[txAmount] = OrderEventItem(block.number, block.timestamp, y.tcc._type, _user, x.taskId, tx.origin, x._feeItem.allFee, t);
        //用户的交易,可选
        //userTxSet[tx.origin].add(txAmount);

        //平台触发次数+1
        txAmount = txAmount.add(1);
        //用户触发次数+1
        userTxAmountList[tx.origin] = userTxAmountList[tx.origin].add(1);
        emit OrderEvent(block.number, block.timestamp, y.tcc._type, _user, x.taskId, tx.origin, x._feeItem.allFee, t);
        if (devToken != address(0) && devFee > 0) {
            require(userInfoList[_user].devAmount >= devFee, "U19");
            IERC20(devToken).transfer(usdtPoolAddress, devFee);
            userInfoList[_user].devAmount = userInfoList[_user].devAmount.sub(devFee);
            userInfoList[_user].devUsedAmount = userInfoList[_user].devUsedAmount.add(devFee);
        }
    }

    function checkManualOrder(address[] memory _swapRouter, address[] memory _swapRouter2) private view returns (bool) {
        uint256 k = 0;
        if (_swapRouter.length == _swapRouter2.length) {
            k = k + 1;
        }
        if (_swapRouter[0] == _swapRouter2[_swapRouter2.length - 1] && _swapRouter[_swapRouter.length - 1] == _swapRouter2[0]) {
            k = k + 1;
        }
        if (_swapRouter2[0] == usdt || _swapRouter2[0] == weth) {
            k = k + 1;
        }
        return k == 3;
    }

    function getInTimeZone(uint256[] memory _start_end_Time, uint256[] memory _timeList) private view returns (bool _inTimeZone) {
        _inTimeZone = false;
        uint256 all = (block.timestamp + 3600 * 8) % (3600 * 24);
        uint256 TimeListLength = _timeList.length / 2;
        for (uint256 i = 0; i < TimeListLength; i++) {
            if (all >= _timeList[i * 2] && all < _timeList[i * 2 + 1] && block.timestamp >= _start_end_Time[0] && block.timestamp <= _start_end_Time[1]) {
                _inTimeZone = true;
                break;
            }
        }
    }

    struct _DateTime {
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hour;
        uint256 minute;
        uint256 second;
        uint256 weekday;
    }

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;
    uint256 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint256 year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) private pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint256 month, uint256 year) private pure returns (uint256) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (isLeapYear(year)) {
            return 29;
        }
        else {
            return 28;
        }
    }

    function getYearMonthDay(uint256 _timestamp) internal pure returns (uint256) {
        _DateTime memory dt = parseTimestamp(_timestamp + 3600 * 8);
        return dt.year * (10 ** 6) + dt.month * (10 ** 4) + dt.day * 10;
    }

    function parseTimestamp(uint256 timestamp) private pure returns (_DateTime memory dt) {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint256 i;

        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
        dt.hour = getHour(timestamp);
        dt.minute = getMinute(timestamp);
        dt.second = getSecond(timestamp);
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) private pure returns (uint256) {
        uint256 secondsAccountedFor = 0;
        uint256 year;
        uint256 numLeapYears;

        year = uint256(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint256(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) private pure returns (uint256) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) private pure returns (uint256) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) private pure returns (uint256) {
        return uint256((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) private pure returns (uint256) {
        return uint256((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) private pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) private pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Module, ModuleData} from "./StructList.sol";
import {IERC20Metadata as IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address public immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value : _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

abstract contract OpsTaskCreator is OpsReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _ops, address _fundsOwner)
    OpsReady(_ops, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = ops.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value : ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
        ops.createTask(
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    function _cancelTask(bytes32 _taskId) internal {
        ops.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
    internal
    pure
    returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OpsTaskCreator} from "./OpsTaskCreator.sol";
import {OrderEventItem, UserInfoItem, TaskConfig, TxItem, TokenInfoItem, OrderType, TccItem, TccItemV2, SwapEventItem, GasItemList} from "./StructList.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OrderBase is OpsTaskCreator, Ownable, ReentrancyGuard {
    //address internal multiDexRouterAddress = 0xb557e9651ae445d2EA6507Ee16D344e2A3d0DFB7;
    address internal multiDexRouterAddress = 0xdBCA47a05324b06f31C5920923E66669ef210dD7;
    address internal V3Dex = 0x9E19784E77e13ac2Ca22E9E33C8a6bEF62774D2E;
    address internal usdtPoolAddress;
    address public weth;
    address internal usdt;
    address internal devToken;

    uint256 internal devFee;
    uint256 internal swapRate = 100;
    uint256 internal swapAllRate = 1000;
    uint256 internal feeRate = 1;
    uint256 internal feeAllRate = 1000;
    uint256 internal takeFeeGas = 100000;
    uint256 internal gasRate = 110;
    uint256 internal gasPriceLimitForManual = 4 * 10 ** 9;
    uint256 internal gasPriceLimitForAutomate = 4 * 10 ** 9;
    uint256 internal approveAmount;
    uint256 internal taskAmount;
    uint256 internal txAmount;
    uint256 internal totalFee;

    mapping(address => uint256) internal userTxAmountList;
    mapping(uint256 => OrderEventItem) internal orderInfoList;
    mapping(address => uint256) internal usertotalFeeList;
    mapping(uint256 => bytes32) internal taskList;
    mapping(bytes32 => bool) internal taskIdStatusList;
    mapping(address => UserInfoItem) internal userInfoList;
    mapping(address => bytes32[]) internal userTaskList;
    mapping(bytes32 => bool) internal md5List;
    mapping(bytes32 => bytes32) internal md5TaskList;
    mapping(bytes32 => TaskConfig) public taskConfigList;
    mapping(bytes32 => uint256) internal lastExecutedTimeList;
    mapping(bytes32 => uint256) internal lastTimeIntervalIndexList;
    mapping(bytes32 => uint256) internal lastSwapAmountIndexList;
    mapping(bytes32 => mapping(uint256 => TxItem)) internal txHistoryList;
    mapping(address => bool) internal dedicatedMsgSenderList;
    mapping(string => bool) internal taskNameList;
    mapping(address => mapping(address => TokenInfoItem)) internal userTokenAmountList;

    event CreateTaskEvent(uint256 _blockNumber, uint256 _timestamp, address indexed _user, bytes32 indexed _md5, uint256 _taskAmount, bytes32 indexed _taskId, OrderType _type, TccItemV2 _tcc);
    event OrderEvent(uint256 _blockNumber, uint256 _timestamp, OrderType _type, address indexed _user, bytes32 indexed _taskId, address _caller, uint256 _fee, SwapEventItem _swapEventItem);
    event FundsEvent(uint256 _blockNumber, uint256 _timestamp, address _user, address _token, uint256 _tokenDecimals, uint256 _amount, string _fundsType);
    event GasEvent(uint256 _gas0, GasItemList _gasList);

    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        address _usdtPoolAddress,
        address _weth,
        address _usdt
    ) OpsTaskCreator(_ops, _fundsOwner){
        approveAmount = _approveAmount;
        usdtPoolAddress = _usdtPoolAddress;
        weth = _weth;
        usdt = _usdt;
        dedicatedMsgSenderList[dedicatedMsgSender] = true;
        dedicatedMsgSenderList[msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    struct ExactInputParams {
        address factory;
        address[] tokenList;
        uint24[] feeList;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        bool forceUseWETH;
    }

    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    enum OrderType{
        AutomateOrder,
        LimitOrder,
        ManualOrder
    }

    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

    struct TxItem {
        uint256 _totalTx;
        uint256 _totalSpendTokenAmount;
        uint256 _totalFee;
    }

    struct UserInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 ethUsedAmount;
        uint256 ethWithdrawAmount;
        uint256 devDepositAmount;
        uint256 devAmount;
        uint256 devUsedAmount;
        uint256 devWithdrawAmount;
    }

    struct TokenInfoItem {
        uint256 depositAmount;
        uint256 leftAmount;
        uint256 usedAmount;
        uint256 withdrawAmount;
    }

    struct TokenInfoItem2 {
        address token;
        uint256 decimals;
        string symbol;
        TokenInfoItem info;
    }

    struct LimitItem {
        uint256 _swapInDecimals;
        uint256 _swapInAmount;
        uint256 _swapInAmountOld;
        uint256 _swapOutDecimals;
        uint256 _swapOutStandardAmount;
        uint256 _minswapOutAmount;
        uint256 _swapOutAmount;
        uint256[] _swapPriceZone;
    }

    struct TccItem {
        string _taskName; //任务名字 (刷单/限价单)
        address[] _routerAddressList; //路由地址(刷单/限价单)
        address[] _swapRouter;  //usdt买代币(刷单/限价单)
        address[] _swapRouter2; //代币换USDT
        uint256 _interval; //触发频率,小于20每个区块都检测,大于20按指定的时间间隔检测条件
        uint256[] _start_end_Time; //开始和结束时间(刷单/限价单)
        uint256[] _timeList; //设置的交易时间段,两个一组(刷单)
        uint256[] _timeIntervalList; //交易的时间间隔列表(刷单)
        uint256[] _swapAmountList; //交易的USDT数量列表(刷单)
        uint256 _maxtxAmount; //每天的交易次数上限(刷单)
        uint256 _maxSpendTokenAmount; //每天刷单消耗USDT的总量上限(刷单)
        uint256 _maxFeePerTx; //每笔刷单消耗的GAS上限(刷单/限价单)
        LimitItem _limitItem; //(限价单)
        OrderType _type;
    }

    struct TcdItem {
        bool _status;
        bool _completed;
        uint256 _index;
        uint256 _taskExTimes;
        uint256 _totalFee;
        uint256 _maxSpendTokenAmount; //要交易的代币数量
        address _owner;
        address _execAddress;
        address _feeToken;
        address _swapInToken;
        address _swapOutToken;
        bytes _execDataOrSelector;
        bytes32 _md5;
        bytes32 _taskId;
        ModuleData _moduleData;
    }

    struct TaskConfig {
        TccItemV2 tcc;
        TcdItem tcd;
    }

    struct BalanceItem {
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
    }

    struct TokenItem {
        address swapInToken;
        address swapOutToken;
    }

    struct FeeItem {
        uint256 poolFee;
        uint256 allFee;
    }

    struct FeeItem2 {
        uint256 fee;
        address feeToken;
    }

    struct SwapTokenItem {
        uint256 day;
        uint256 claimAmount;
        uint256 swapInAmount;
        uint256 swapFee;
        uint256 spendSwapInToken;
        bytes32 taskId;
        TokenItem _TokenItem;
        BalanceItem _balanceItem;
        FeeItem _feeItem;
        FeeItem2 _feeItem2;
    }

    struct SwapEventItem {
        address _swapInToken;
        address _swapOutToken;
        uint256 _swapInDecimals;
        uint256 _swapOutDecimals;
        uint256 _usdtAmount;
        uint256 _spendUsdtAmount;
        uint256 _poolFee;
        uint256 _swapInAmount;
        uint256 _minswapOutAmount;
        uint256 _swapOutAmount;
    }

    struct OrderEventItem {
        uint256 _blockNumber;
        uint256 _timestamp;
        OrderType _type;
        address _user;
        bytes32 _taskId;
        address _caller;
        uint256 _fee;
        SwapEventItem _swapEventItem;
    }

    struct CreateItem {
        bytes32 md5;
        bytes execData;
        ModuleData moduleData;
        TaskConfig _taskConfig;
        bytes32 taskId;
        address swapInToken;
        address swapOutToken;
        uint256 tokenAmount0;
        uint256 tokenAmount1;
        uint256 tokenAmount;
    }

    struct GasItem {
        uint256 _gas0;
        uint256 _gas1;
        uint256 _gas2;
        uint256 _gas3;
        uint256 _gas4;
        uint256 _gas5;
        uint256 _gas6;
        uint256 _gas7;
        uint256 _gas8;
        uint256 _gas9;
        uint256 _gas10;
        uint256 _gas11;
        uint256 _gas12;
    }

    struct GasItemList {
        GasItem _gasItem0;
        GasItem _gasItem1;
        GasItem _gasItem2;
        GasItem _gasItem3;
        GasItem _gasItem4;
        GasItem _gasItem5;
    }

    struct taskInfoItem {
        TaskConfig _config;
        uint256 _lastExecutedTime;
        uint256 _nextTimeIntervalIndex;
        uint256 _nextSwapAmountIndex;
        uint256 _day;
        uint256 _userEthAmount;
        uint256 _userTokenAmount;
        TxItem _txInfo;
    }

    struct swapPathItem {
        address[] _swapPathList;
        address[] _routerAddressListV2;
        address[] _factoryV3;
        uint24[] _feeListV3;
        uint256[] _swapPriceZone; //成交区间
    }

    struct TccItemV2 {
        string _taskName; //任务名字 (刷单/限价单)
        uint256 _interval; //触发频率,小于20每个区块都检测,大于20按指定的时间间隔检测条件
        uint256[] _start_end_Time; //开始和结束时间(刷单/限价单)
        uint256[] _timeList; //设置的交易时间段,两个一组(刷单)
        uint256[] _timeIntervalList; //交易的时间间隔列表(刷单)
        uint256[] _swapAmountList; //交易的USDT数量列表(刷单)
        uint256 _maxtxAmount; //每天的交易次数上限(刷单)
        uint256 _maxSpendTokenAmount; //每天刷单消耗USDT的总量上限(刷单)
        uint256 _maxFeePerTx; //每笔刷单消耗的GAS上限(刷单/限价单)
        OrderType _type;
        swapPathItem _swapPathConfig1; //第一次兑换数据
        swapPathItem _swapPathConfig2; //第二次兑换数据
        bool isV3; //使用V3模式
        //        LimitItem _limitItem; //(限价单)
    }

////    //限价单
//    struct TccItemV3 {
//        string _taskName; //任务名字 (刷单/限价单)
//        uint256 _interval; //触发频率,小于20每个区块都检测,大于20按指定的时间间隔检测条件
//        uint256[] _start_end_Time; //开始和结束时间(刷单/限价单)
//        uint256 _maxSpendTokenAmount; //要交易的代币数量
//        uint256 _maxFeePerTx; //每笔刷单消耗的GAS上限(刷单/限价单)
//        OrderType _type;
//        swapPathItem _swapPathConfig1; //第一次兑换数据
//        bool isV3; //使用V3模式
//        LimitItem _limitItem; //(限价单)
//    }