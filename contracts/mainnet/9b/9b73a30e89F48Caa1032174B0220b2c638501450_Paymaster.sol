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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable reason-string */

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPaymaster.sol";
import "../interfaces/IEntryPoint.sol";
import "./Helpers.sol";

/**
 * Helper class for creating a paymaster.
 * provides helper methods for staking.
 * Validates that the postOp is called only by the entryPoint.
 */
abstract contract BasePaymaster is IPaymaster, Ownable {
  IEntryPoint public immutable entryPoint;

  constructor(IEntryPoint _entryPoint) {
    entryPoint = _entryPoint;
  }

  /// @inheritdoc IPaymaster
  function validatePaymasterUserOp(
    UserOperation calldata userOp,
    bytes32 userOpHash,
    uint256 maxCost
  ) external override returns (bytes memory context, uint256 validationData) {
    _requireFromEntryPoint();
    return _validatePaymasterUserOp(userOp, userOpHash, maxCost);
  }

  /**
   * Validate a user operation.
   * @param userOp     - The user operation.
   * @param userOpHash - The hash of the user operation.
   * @param maxCost    - The maximum cost of the user operation.
   */
  function _validatePaymasterUserOp(
    UserOperation calldata userOp,
    bytes32 userOpHash,
    uint256 maxCost
  ) internal virtual returns (bytes memory context, uint256 validationData);

  /// @inheritdoc IPaymaster
  function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external override {
    _requireFromEntryPoint();
    _postOp(mode, context, actualGasCost);
  }

  /**
   * Post-operation handler.
   * (verified to be called only through the entryPoint)
   * @dev If subclass returns a non-empty context from validatePaymasterUserOp,
   *      it must also implement this method.
   * @param mode          - Enum with the following options:
   *                        opSucceeded - User operation succeeded.
   *                        opReverted  - User op reverted. still has to pay for gas.
   *                        postOpReverted - User op succeeded, but caused postOp (in mode=opSucceeded) to revert.
   *                                         Now this is the 2nd call, after user's op was deliberately reverted.
   * @param context       - The context value returned by validatePaymasterUserOp
   * @param actualGasCost - Actual gas used so far (without this postOp call).
   */
  function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal virtual {
    (mode, context, actualGasCost); // unused params
    // subclass must override this method if validatePaymasterUserOp returns a context
    revert("must override");
  }

  /**
   * Add a deposit for this paymaster, used for paying for transaction fees.
   */
  function deposit() public payable {
    entryPoint.depositTo{ value: msg.value }(address(this));
  }

  /**
   * Withdraw value from the deposit.
   * @param withdrawAddress - Target to send to.
   * @param amount          - Amount to withdraw.
   */
  function withdrawTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
    entryPoint.withdrawTo(withdrawAddress, amount);
  }

  /**
   * Add stake for this paymaster.
   * This method can also carry eth value to add to the current stake.
   * @param unstakeDelaySec - The unstake delay for this paymaster. Can only be increased.
   */
  function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
    entryPoint.addStake{ value: msg.value }(unstakeDelaySec);
  }

  /**
   * Return current paymaster's deposit on the entryPoint.
   */
  function getDeposit() public view returns (uint256) {
    return entryPoint.balanceOf(address(this));
  }

  /**
   * Unlock the stake, in order to withdraw it.
   * The paymaster can't serve requests once unlocked, until it calls addStake again
   */
  function unlockStake() external onlyOwner {
    entryPoint.unlockStake();
  }

  /**
   * Withdraw the entire paymaster's stake.
   * stake must be unlocked first (and then wait for the unstakeDelay to be over)
   * @param withdrawAddress - The address to send withdrawn value.
   */
  function withdrawStake(address payable withdrawAddress) external onlyOwner {
    entryPoint.withdrawStake(withdrawAddress);
  }

  /**
   * Validate the call is made from a valid entrypoint
   */
  function _requireFromEntryPoint() internal virtual {
    require(msg.sender == address(entryPoint), "Sender not EntryPoint");
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * Returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and
 * parsed by `_parseValidationData`.
 * @param aggregator  - address(0) - The account validated the signature by itself.
 *                      address(1) - The account failed to validate the signature.
 *                      otherwise - This is an address of a signature aggregator that must
 *                                  be used to validate the signature.
 * @param validAfter  - This UserOp is valid only after this timestamp.
 * @param validaUntil - This UserOp is valid only up to this timestamp.
 */
struct ValidationData {
  address aggregator;
  uint48 validAfter;
  uint48 validUntil;
}

/**
 * Extract sigFailed, validAfter, validUntil.
 * Also convert zero validUntil to type(uint48).max.
 * @param validationData - The packed validation data.
 */
function _parseValidationData(uint validationData) pure returns (ValidationData memory data) {
  address aggregator = address(uint160(validationData));
  uint48 validUntil = uint48(validationData >> 160);
  if (validUntil == 0) {
    validUntil = type(uint48).max;
  }
  uint48 validAfter = uint48(validationData >> (48 + 160));
  return ValidationData(aggregator, validAfter, validUntil);
}

/**
 * Intersect account and paymaster ranges.
 * @param validationData          - The packed validation data of the account.
 * @param paymasterValidationData - The packed validation data of the paymaster.
 */
function _intersectTimeRange(
  uint256 validationData,
  uint256 paymasterValidationData
) pure returns (ValidationData memory) {
  ValidationData memory accountValidationData = _parseValidationData(validationData);
  ValidationData memory pmValidationData = _parseValidationData(paymasterValidationData);
  address aggregator = accountValidationData.aggregator;
  if (aggregator == address(0)) {
    aggregator = pmValidationData.aggregator;
  }
  uint48 validAfter = accountValidationData.validAfter;
  uint48 validUntil = accountValidationData.validUntil;
  uint48 pmValidAfter = pmValidationData.validAfter;
  uint48 pmValidUntil = pmValidationData.validUntil;

  if (validAfter < pmValidAfter) validAfter = pmValidAfter;
  if (validUntil > pmValidUntil) validUntil = pmValidUntil;
  return ValidationData(aggregator, validAfter, validUntil);
}

/**
 * Helper to pack the return value for validateUserOp.
 * @param data - The ValidationData to pack.
 */
function _packValidationData(ValidationData memory data) pure returns (uint256) {
  return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
}

/**
 * Helper to pack the return value for validateUserOp, when not using an aggregator.
 * @param sigFailed  - True for signature failure, false for success.
 * @param validUntil - Last timestamp this UserOperation is valid (or zero for infinite).
 * @param validAfter - First timestamp this UserOperation is valid.
 */
function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256) {
  return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48));
}

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
  assembly {
    let mem := mload(0x40)
    let len := data.length
    calldatacopy(mem, data.offset, len)
    ret := keccak256(mem, len)
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {
  /**
   * Validate aggregated signature.
   * Revert if the aggregated signature does not match the given list of operations.
   * @param userOps   - Array of UserOperations to validate the signature for.
   * @param signature - The aggregated signature.
   */
  function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;

  /**
   * Validate signature of a single userOp.
   * This method is should be called by bundler after EntryPoint.simulateValidation() returns (reverts) with ValidationResultWithAggregation
   * First it validates the signature over the userOp. Then it returns data to be used when creating the handleOps.
   * @param userOp        - The userOperation received from the user.
   * @return sigForUserOp - The value to put into the signature field of the userOp when calling handleOps.
   *                        (usually empty, unless account and aggregator support some kind of "multisig".
   */
  function validateUserOpSignature(UserOperation calldata userOp) external view returns (bytes memory sigForUserOp);

  /**
   * Aggregate multiple signatures into a single value.
   * This method is called off-chain to calculate the signature to pass with handleOps()
   * bundler MAY use optimized custom code perform this aggregation.
   * @param userOps              - Array of UserOperations to collect the signatures from.
   * @return aggregatedSignature - The aggregated signature.
   */
  function aggregateSignatures(
    UserOperation[] calldata userOps
  ) external view returns (bytes memory aggregatedSignature);
}

/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./UserOperation.sol";
import "./IStakeManager.sol";
import "./IAggregator.sol";
import "./INonceManager.sol";

interface IEntryPoint is IStakeManager, INonceManager {
  /***
   * An event emitted after each successful request.
   * @param userOpHash    - Unique identifier for the request (hash its entire content, except signature).
   * @param sender        - The account that generates this request.
   * @param paymaster     - If non-null, the paymaster that pays for this request.
   * @param nonce         - The nonce value from the request.
   * @param success       - True if the sender transaction succeeded, false if reverted.
   * @param actualGasCost - Actual amount paid (by account or paymaster) for this UserOperation.
   * @param actualGasUsed - Total gas used by this UserOperation (including preVerification, creation,
   *                        validation and execution).
   */
  event UserOperationEvent(
    bytes32 indexed userOpHash,
    address indexed sender,
    address indexed paymaster,
    uint256 nonce,
    bool success,
    uint256 actualGasCost,
    uint256 actualGasUsed
  );

  /**
   * Account "sender" was deployed.
   * @param userOpHash - The userOp that deployed this account. UserOperationEvent will follow.
   * @param sender     - The account that is deployed
   * @param factory    - The factory used to deploy this account (in the initCode)
   * @param paymaster  - The paymaster used by this UserOp
   */
  event AccountDeployed(bytes32 indexed userOpHash, address indexed sender, address factory, address paymaster);

  /**
   * An event emitted if the UserOperation "callData" reverted with non-zero length.
   * @param userOpHash   - The request unique identifier.
   * @param sender       - The sender of this request.
   * @param nonce        - The nonce used in the request.
   * @param revertReason - The return bytes from the (reverted) call to "callData".
   */
  event UserOperationRevertReason(
    bytes32 indexed userOpHash,
    address indexed sender,
    uint256 nonce,
    bytes revertReason
  );

  /**
   * An event emitted by handleOps(), before starting the execution loop.
   * Any event emitted before this event, is part of the validation.
   */
  event BeforeExecution();

  /**
   * Signature aggregator used by the following UserOperationEvents within this bundle.
   * @param aggregator - The aggregator used for the following UserOperationEvents.
   */
  event SignatureAggregatorChanged(address indexed aggregator);

  /**
   * A custom revert error of handleOps, to identify the offending op.
   * Should be caught in off-chain handleOps simulation and not happen on-chain.
   * Useful for mitigating DoS attempts against batchers or for troubleshooting of factory/account/paymaster reverts.
   * NOTE: If simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
   * @param opIndex - Index into the array of ops to the failed one (in simulateValidation, this is always zero).
   * @param reason  - Revert reason. The string starts with a unique code "AAmn",
   *                  where "m" is "1" for factory, "2" for account and "3" for paymaster issues,
   *                  so a failure can be attributed to the correct entity.
   */
  error FailedOp(uint256 opIndex, string reason);

  /**
   * Error case when a signature aggregator fails to verify the aggregated signature it had created.
   * @param aggregator The aggregator that failed to verify the signature
   */
  error SignatureValidationFailed(address aggregator);

  // Return value of getSenderAddress.
  error SenderAddressResult(address sender);

  // UserOps handled, per aggregator.
  struct UserOpsPerAggregator {
    UserOperation[] userOps;
    // Aggregator address
    IAggregator aggregator;
    // Aggregated signature
    bytes signature;
  }

  /**
   * Execute a batch of UserOperations.
   * No signature aggregator is used.
   * If any account requires an aggregator (that is, it returned an aggregator when
   * performing simulateValidation), then handleAggregatedOps() must be used instead.
   * @param ops         - The operations to execute.
   * @param beneficiary - The address to receive the fees.
   */
  function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

  /**
   * Execute a batch of UserOperation with Aggregators
   * @param opsPerAggregator - The operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts).
   * @param beneficiary      - The address to receive the fees.
   */
  function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary) external;

  /**
   * Generate a request Id - unique identifier for this request.
   * The request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
   * @param userOp - The user operation to generate the request ID for.
   */
  function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);

  /**
   * Gas and return values during simulation.
   * @param preOpGas         - The gas used for validation (including preValidationGas)
   * @param prefund          - The required prefund for this operation
   * @param sigFailed        - ValidateUserOp's (or paymaster's) signature check failed
   * @param validAfter       - First timestamp this UserOp is valid (merging account and paymaster time-range)
   * @param validUntil       - Last timestamp this UserOp is valid (merging account and paymaster time-range)
   * @param paymasterContext - Returned by validatePaymasterUserOp (to be passed into postOp)
   */
  struct ReturnInfo {
    uint256 preOpGas;
    uint256 prefund;
    bool sigFailed;
    uint48 validAfter;
    uint48 validUntil;
    bytes paymasterContext;
  }

  /**
   * Returned aggregated signature info:
   * The aggregator returned by the account, and its current stake.
   */
  struct AggregatorStakeInfo {
    address aggregator;
    StakeInfo stakeInfo;
  }

  /**
   * Get counterfactual sender address.
   * Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
   * This method always revert, and returns the address in SenderAddressResult error
   * @param initCode - The constructor code to be passed into the UserOperation.
   */
  function getSenderAddress(bytes memory initCode) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface INonceManager {
  /**
   * Return the next nonce for this sender.
   * Within a given key, the nonce values are sequenced (starting with zero, and incremented by one on each userop)
   * But UserOp with different keys can come with arbitrary order.
   *
   * @param sender the account address
   * @param key the high 192 bit of the nonce
   * @return nonce a full nonce to pass for next UserOp with this sender.
   */
  function getNonce(address sender, uint192 key) external view returns (uint256 nonce);

  /**
   * Manually increment the nonce of the sender.
   * This method is exposed just for completeness..
   * Account does NOT need to call it, neither during validation, nor elsewhere,
   * as the EntryPoint will update the nonce regardless.
   * Possible use-case is call it with various keys to "initialize" their nonces to one, so that future
   * UserOperations will not pay extra for the first transaction with a given key.
   */
  function incrementNonce(uint192 key) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * The interface exposed by a paymaster contract, who agrees to pay the gas for user's operations.
 * A paymaster must hold a stake to cover the required entrypoint stake and also the gas for the transaction.
 */
interface IPaymaster {
  enum PostOpMode {
    // User op succeeded.
    opSucceeded,
    // User op reverted. Still has to pay for gas.
    opReverted,
    // User op succeeded, but caused postOp to revert.
    // Now it's a 2nd call, after user's op was deliberately reverted.
    postOpReverted
  }

  /**
   * Payment validation: check if paymaster agrees to pay.
   * Must verify sender is the entryPoint.
   * Revert to reject this request.
   * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted).
   * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
   * @param userOp          - The user operation.
   * @param userOpHash      - Hash of the user's request data.
   * @param maxCost         - The maximum cost of this transaction (based on maximum gas and gas price from userOp).
   * @return context        - Value to send to a postOp. Zero length to signify postOp is not required.
   * @return validationData - Signature and time-range of this operation, encoded the same as the return
   *                          value of validateUserOperation.
   *                          <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
   *                                                    otherwise, an address of an "authorizer" contract.
   *                          <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
   *                          <6-byte> validAfter - first timestamp this operation is valid
   *                          Note that the validation code cannot use block.timestamp (or block.number) directly.
   */
  function validatePaymasterUserOp(
    UserOperation calldata userOp,
    bytes32 userOpHash,
    uint256 maxCost
  ) external returns (bytes memory context, uint256 validationData);

  /**
   * Post-operation handler.
   * Must verify sender is the entryPoint.
   * @param mode          - Enum with the following options:
   *                        opSucceeded - User operation succeeded.
   *                        opReverted  - User op reverted. still has to pay for gas.
   *                        postOpReverted - User op succeeded, but caused postOp (in mode=opSucceeded) to revert.
   *                                         Now this is the 2nd call, after user's op was deliberately reverted.
   * @param context       - The context value returned by validatePaymasterUserOp
   * @param actualGasCost - Actual gas used so far (without this postOp call).
   */
  function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

/**
 * Manage deposits and stakes.
 * Deposit is just a balance used to pay for UserOperations (either by a paymaster or an account).
 * Stake is value locked for at least "unstakeDelay" by the staked entity.
 */
interface IStakeManager {
  event Deposited(address indexed account, uint256 totalDeposit);

  event Withdrawn(address indexed account, address withdrawAddress, uint256 amount);

  // Emitted when stake or unstake delay are modified.
  event StakeLocked(address indexed account, uint256 totalStaked, uint256 unstakeDelaySec);

  // Emitted once a stake is scheduled for withdrawal.
  event StakeUnlocked(address indexed account, uint256 withdrawTime);

  event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 amount);

  /**
   * @param deposit         - The entity's deposit.
   * @param staked          - True if this entity is staked.
   * @param stake           - Actual amount of ether staked for this entity.
   * @param unstakeDelaySec - Minimum delay to withdraw the stake.
   * @param withdrawTime    - First block timestamp where 'withdrawStake' will be callable, or zero if already locked.
   * @dev Sizes were chosen so that (deposit,staked, stake) fit into one cell (used during handleOps)
   *      and the rest fit into a 2nd cell.
   *      - 112 bit allows for 10^15 eth
   *      - 48 bit for full timestamp
   *      - 32 bit allows 150 years for unstake delay
   */
  struct DepositInfo {
    uint112 deposit;
    bool staked;
    uint112 stake;
    uint32 unstakeDelaySec;
    uint48 withdrawTime;
  }

  // API struct used by getStakeInfo and simulateValidation.
  struct StakeInfo {
    uint256 stake;
    uint256 unstakeDelaySec;
  }

  /**
   * Get deposit info.
   * @param account - The account to query.
   * @return info   - Full deposit information of given account.
   */
  function getDepositInfo(address account) external view returns (DepositInfo memory info);

  /**
   * Get account balance.
   * @param account - The account to query.
   * @return        - The deposit (for gas payment) of the account.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * Add to the deposit of the given account.
   * @param account - The account to add to.
   */
  function depositTo(address account) external payable;

  /**
   * Add to the account's stake - amount and delay
   * any pending unstake is first cancelled.
   * @param _unstakeDelaySec - The new lock duration before the deposit can be withdrawn.
   */
  function addStake(uint32 _unstakeDelaySec) external payable;

  /**
   * Attempt to unlock the stake.
   * The value can be withdrawn (using withdrawStake) after the unstake delay.
   */
  function unlockStake() external;

  /**
   * Withdraw from the (unlocked) stake.
   * Must first call unlockStake and wait for the unstakeDelay to pass.
   * @param withdrawAddress - The address to send withdrawn value.
   */
  function withdrawStake(address payable withdrawAddress) external;

  /**
   * Withdraw from the deposit.
   * @param withdrawAddress - The address to send withdrawn value.
   * @param withdrawAmount  - The amount to withdraw.
   */
  function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import { calldataKeccak } from "../core/Helpers.sol";

/**
 * User Operation struct
 * @param sender                - The sender account of this request.
 * @param nonce                 - Unique value the sender uses to verify it is not a replay.
 * @param initCode              - If set, the account contract will be created by this constructor/
 * @param callData              - The method call to execute on this account.
 * @param callGasLimit          - The gas limit passed to the callData method call.
 * @param verificationGasLimit  - Gas used for validateUserOp and validatePaymasterUserOp.
 * @param preVerificationGas    - Gas not calculated by the handleOps method, but added to the gas paid.
 *                                Covers batch overhead.
 * @param maxFeePerGas          - Same as EIP-1559 gas parameter.
 * @param maxPriorityFeePerGas  - Same as EIP-1559 gas parameter.
 * @param paymasterAndData      - If set, this field holds the paymaster address and paymaster-specific data.
 *                                The paymaster will pay for the transaction instead of the sender.
 * @param signature             - Sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct UserOperation {
  address sender;
  uint256 nonce;
  bytes initCode;
  bytes callData;
  uint256 callGasLimit;
  uint256 verificationGasLimit;
  uint256 preVerificationGas;
  uint256 maxFeePerGas;
  uint256 maxPriorityFeePerGas;
  bytes paymasterAndData;
  bytes signature;
}

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {
  /**
   * Get sender from user operation data.
   * @param userOp - The user operation data.
   */
  function getSender(UserOperation calldata userOp) internal pure returns (address) {
    address data;
    //read sender from userOp, which is first userOp member (saves 800 gas...)
    assembly {
      data := calldataload(userOp)
    }
    return address(uint160(data));
  }

  /**
   * Relayer/block builder might submit the TX with higher priorityFee,
   * but the user should not pay above what he signed for.
   * @param userOp - The user operation data.
   */
  function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
      uint256 maxFeePerGas = userOp.maxFeePerGas;
      uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
      if (maxFeePerGas == maxPriorityFeePerGas) {
        //legacy mode (for networks that don't support basefee opcode)
        return maxFeePerGas;
      }
      return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
  }

  /**
   * Pack the user operation data into bytes for hashing.
   * @param userOp - The user operation data.
   */
  function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
    address sender = getSender(userOp);
    uint256 nonce = userOp.nonce;
    bytes32 hashInitCode = calldataKeccak(userOp.initCode);
    bytes32 hashCallData = calldataKeccak(userOp.callData);
    uint256 callGasLimit = userOp.callGasLimit;
    uint256 verificationGasLimit = userOp.verificationGasLimit;
    uint256 preVerificationGas = userOp.preVerificationGas;
    uint256 maxFeePerGas = userOp.maxFeePerGas;
    uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
    bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

    return
      abi.encode(
        sender,
        nonce,
        hashInitCode,
        hashCallData,
        callGasLimit,
        verificationGasLimit,
        preVerificationGas,
        maxFeePerGas,
        maxPriorityFeePerGas,
        hashPaymasterAndData
      );
  }

  /**
   * Hash the user operation data.
   * @param userOp - The user operation data.
   */
  function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
    return keccak256(pack(userOp));
  }

  /**
   * The minimum of two numbers.
   * @param a - First number.
   * @param b - Second number.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Import the required libraries and contracts
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IEntryPoint.sol";
import "./core/BasePaymaster.sol";
import "./utils/UniswapHelper.sol";
import "./utils/OracleHelper.sol";
import "./utils/IOracle.sol";

struct PaymasterParams {
  address signer;
  IEntryPoint entryPoint;
  IERC20Metadata wrappedNative;
  ISwapRouter uniswap;
  IOracle nativeOracle;
  address treasury;
}

struct PaymasterAndData {
  address paymaster;
  IERC20Metadata token;
  bool postTransfer;
  bool userCheck;
  uint48 validUntil;
  uint48 validAfter;
  uint256 preCharge;
  uint256 preFee;
  uint256 userBalance;
}

contract Paymaster is BasePaymaster, UniswapHelper, OracleHelper, ReentrancyGuard {
  using ECDSA for bytes32;
  using UserOperationLib for UserOperation;
  using SafeERC20 for IERC20Metadata;

  enum TokenStatus {
    ADDED,
    REMOVED
  }

  struct TokenPaymasterConfig {
    /// @notice The price markup percentage applied to the token price (1e6 = 100%)
    uint256 priceMarkup;
    /// @notice Estimated gas cost for refunding tokens after the transaction is completed
    uint256 refundPostopCost;
    /// @notice Transactions are only valid as long as the cached price is not older than this value
    uint256 priceMaxAge;
    /// @notice The Oracle contract used to fetch the latest Token prices
    IOracle oracle;
    bool toNative;
  }

  /// @notice The fee percentage (1e6 = 100%)
  uint256 private constant FEE = 300;

  /// @notice All 'price' variables are multiplied by this value to avoid rounding up
  uint256 private constant PRICE_DENOMINATOR = 1e26;

  uint256 private constant FEE_DENOMINATOR = 1e6;

  uint256 private constant TOKEN_OFFSET = 20;

  uint256 private constant VALID_TIMESTAMP_OFFSET = 40;

  uint256 private constant SIGNATURE_OFFSET = 264;

  IOracle private constant NULL_ORACLE = IOracle(address(0));

  address public verifyingSigner;
  address public treasury;

  IERC20Metadata[] public tokenList;

  mapping(IERC20Metadata => TokenPaymasterConfig) public configs;

  /// @notice The balance (in token/eth) represent the debts or the remaining of the balance
  mapping(IERC20Metadata => mapping(address => int256)) public balances;

  event PostOpReverted(address indexed user, uint256 preCharge, uint256 actualGasCost, int256 debt, uint256 fee, uint256 actualChargeNative);

  event Pay(address indexed user, IERC20Metadata token, uint256 actualTokenCharge, uint256 fee);

  event Token(IERC20Metadata indexed token, TokenStatus status);

  event Debug1(uint256 cachedPriceWithMarkup, uint256 actualTokenNeeded, uint256 preCharge, uint256 preFee, bool postTrasfer);
  event Debug2(uint256 allowance);
  event Debug3(uint256 cachedPriceWithMarkup, uint256 actualTokenNeeded, uint256 preCharge, uint256 preFee, bool postTrasfer);

  /// @notice Initializes the Paymaster contract with the given parameters.
  constructor(
    PaymasterParams memory params
  )
    BasePaymaster(params.entryPoint)
    UniswapHelper(params.wrappedNative, params.uniswap)
    OracleHelper(params.nativeOracle)
  {
    verifyingSigner = params.signer;
    treasury = params.treasury;
  }

  function setVerifyingSigner(address _verifyingSigner) external onlyOwner {
    verifyingSigner = _verifyingSigner;
  }

  function setTresury(address _treasury) external {
    require(treasury == msg.sender, "Invalid sender");

    for (uint16 i = 0; i < tokenList.length; i++) {
      IERC20Metadata token = tokenList[i];
      int256 tmpBalance = balances[token][treasury];

      if (tmpBalance > 0) {
        balances[token][treasury] = 0;
        balances[token][_treasury] = tmpBalance;
      }
    }

    treasury = _treasury;
  }

  /// @notice Allows the contract owner to add a new tokens.
  /// @param tokens The token to deposit.
  function addTokens(
    IERC20Metadata[] calldata tokens,
    TokenPaymasterConfig[] calldata tokenPaymasterConfigs
  ) external onlyOwner {
    require(tokens.length == tokenPaymasterConfigs.length, "Invalid tokens and configs length");

    for (uint i = 0; i < tokens.length; i++) {
      IOracle oracle = configs[tokens[i]].oracle;
      if (oracle != NULL_ORACLE) continue;

      IERC20Metadata token = tokens[i];
      TokenPaymasterConfig memory config = tokenPaymasterConfigs[i];

      if (config.oracle == NULL_ORACLE) continue;
      if (config.priceMarkup <= 2 * PRICE_DENOMINATOR && config.priceMarkup >= PRICE_DENOMINATOR) {
        configs[token] = config;
        tokenList.push(token);

        emit Token(token, TokenStatus.ADDED);
      }
    }
  }

  /// @notice Allows the contract owner to delete the token.
  /// @param tokens The tokens to be removed.
  function removeTokens(IERC20Metadata[] calldata tokens) external onlyOwner {
    for (uint i = 0; i < tokens.length; i++) {
      IERC20Metadata token = tokens[i];
      int tokenIndex = _tokenIndex(token);

      if (tokenIndex >= 0 && configs[token].oracle != NULL_ORACLE) {
        tokenList[uint256(tokenIndex)] = tokenList[tokenList.length - 1];

        delete configs[token];
        tokenList.pop();
        emit Token(token, TokenStatus.REMOVED);
      }
    }
  }

  /// @notice Allows the user to withdraw a specified amount of tokens from the contract.
  /// @param token The token to withdraw.
  /// @param amount The amount of tokens to transfer.
  function withdrawToken(IERC20Metadata token, uint256 amount) external nonReentrant {
    require(address(token) != address(0), "Invalid token contract");

    int256 balance = balances[token][msg.sender];

    require(int(amount) <= balance, "Insufficient balance");

    balances[token][msg.sender] = balance - int(amount);

    token.transfer(msg.sender, amount);
  }

  function depositToken(IERC20Metadata token, uint256 amount, address to) external payable nonReentrant {
    require(address(token) != address(0), "Invalid token contract");

    int256 balance = balances[token][to];
    int256 debts = type(int256).max;

    if (balance < 0) {
      debts = -balance;
    }

    if (int(amount) > debts) {
      balances[token][owner()] += debts;
    } else if (int(amount) < debts) {
      balances[token][owner()] += int(amount);
    }

    balances[token][to] = balance + int(amount);

    token.transferFrom(msg.sender, address(this), amount);
  }

  /// @notice Allows the contract owner to refill entry point deposit with a specified amount of tokens
  function refillEntryPointDeposit(IERC20Metadata token, uint256 amount) external canSwap onlyOwner {
    require(address(token) != address(0), "Invalid token contract");

    int256 balance = balances[token][owner()];

    require(amount <= uint256(balance), "Insufficient balance");

    balances[token][owner()] = balance - int256(amount);

    TokenPaymasterConfig memory config = configs[token];
    IOracle oracle = config.oracle;
    uint256 swappedWNative = amount;

    if (token != wrappedNative) {
      require(oracle != NULL_ORACLE, "Unsupported token");

      uint256 cachedPrice = _updateCachedPrice(token, oracle, config.toNative, false);
      swappedWNative = _maybeSwapTokenToWNative(token, amount, cachedPrice);
    }

    unwrapWeth(swappedWNative);

    entryPoint.depositTo{ value: address(this).balance }(address(this));
  }

  function updateTokenPrice(IERC20Metadata token) external {
    TokenPaymasterConfig memory config = configs[token];
    require(config.oracle != NULL_ORACLE, "Invalid oracle address");
    _updateCachedPrice(token, config.oracle, config.toNative, true);
  }

  receive() external payable {}

  /// @notice Validates a paymaster user operation and calculates the required token amount for the transaction.
  /// @param userOp The user operation data.
  /// @param requiredPreFund The amount of tokens required for pre-funding.
  /// @return context The context containing the token amount and user sender address (if applicable).
  /// @return validationResult A uint256 value indicating the result of the validation (always 0 in this implementation).
  function _validatePaymasterUserOp(
    UserOperation calldata userOp,
    bytes32,
    uint256 requiredPreFund
  ) internal override returns (bytes memory context, uint256 validationResult) {
    (bool verified, PaymasterAndData memory paymasterAndData) = _verifySignature(userOp);

    IERC20Metadata token = paymasterAndData.token;

    require(address(token) != address(0), "Invalid token address");

    TokenPaymasterConfig memory config = configs[token];

    require(config.oracle != NULL_ORACLE, "Invalid oracle address");
    require(balances[token][userOp.sender] >= 0, "Still have debts");

    uint48 validUntil = paymasterAndData.validUntil;
    uint48 validAfter = paymasterAndData.validAfter;

    if (!verified) {
      return ("", _packValidationData(true, validUntil, validAfter));
    }

    // Could be in eth or token
    uint256 preCharge = paymasterAndData.preCharge;
    uint256 preFee = paymasterAndData.preFee;
    uint256 totalPreCharge = preCharge + preFee;

    if (paymasterAndData.preCharge <= 0) {
      uint256 preChargeNative = requiredPreFund + (config.refundPostopCost * userOp.maxFeePerGas);

      if (token != wrappedNative) {
        uint256 cachedPriceWithMarkup = _cachedPriceWithMarkup(token, config);

        preCharge = weiToToken(token, preChargeNative, cachedPriceWithMarkup);
        preFee = (preCharge * FEE) / FEE_DENOMINATOR;
        totalPreCharge = preCharge + preFee;
        validUntil = uint48(getCachedPriceTimestamp(token) + config.priceMaxAge);
        validAfter = 0;
      }
    }

    validationResult = _packValidationData(false, validUntil, validAfter);
    context = abi.encode(
      token,
      paymasterAndData.postTransfer,
      preCharge,
      preFee,
      totalPreCharge,
      userOp.maxFeePerGas,
      userOp.maxPriorityFeePerGas,
      config.refundPostopCost,
      userOp.sender
    );

    // Charge the user/sender on postOp()
    if (paymasterAndData.postTransfer) {
      uint256 balance = paymasterAndData.userCheck ? token.balanceOf(userOp.sender) : paymasterAndData.userBalance;
      require(balance >= totalPreCharge, "Insufficient balance");

      return (context, validationResult);
    }

    token.safeTransferFrom(userOp.sender, address(this), totalPreCharge);

    balances[token][treasury] += int256(preFee);
  }

  /// @notice Performs post-operation tasks, such as updating the token price and refunding excess tokens.
  /// @dev This function is called after a user operation has been executed or reverted.
  /// @param mode The post-operation mode (either successful or reverted).
  /// @param context The context containing the token amount and user sender address.
  /// @param actualGasCost The actual gas cost of the transaction.
  function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
    (
      address tokenAddress,
      bool postTransfer,
      uint256 preCharge,
      uint256 preFee,
      uint256 totalPreCharge,
      uint256 maxFeePerGas,
      uint256 maxPriorityFeePerGas,
      uint256 refundPostopCost,
      address userOpSender
    ) = abi.decode(context, (address, bool, uint256, uint256, uint256, uint256, uint256, uint256, address));

    IERC20Metadata token = IERC20Metadata(tokenAddress);
    uint256 gasPrice = _gasPrice(maxFeePerGas, maxPriorityFeePerGas);
    uint256 actualChargeNative = actualGasCost + (refundPostopCost * gasPrice);

    if (mode == PostOpMode.postOpReverted) {
      int256 debt = _tokenDebt(token, postTransfer, preCharge, actualChargeNative, preFee);
      balances[token][userOpSender] -= debt;

      emit PostOpReverted(userOpSender, totalPreCharge, actualGasCost, debt, preFee, actualChargeNative);
    } else {
      _payWithToken(token, userOpSender, postTransfer, preCharge, preFee, actualChargeNative);
    }
  }

  function _verifySignature(
    UserOperation calldata userOp
  ) internal view returns (bool verified, PaymasterAndData memory data) {
    require(userOp.paymasterAndData.length >= SIGNATURE_OFFSET, "Invalid paymaster and data length");

    (PaymasterAndData memory paymasterAndData, bytes calldata signature) = _parsePaymasterAndData(
      userOp.paymasterAndData
    );

    require(signature.length == 64 || signature.length == 65, "Invalid signature length in paymasterAndData");

    bytes32 hash = ECDSA.toEthSignedMessageHash(_hash(userOp, paymasterAndData));

    verified = verifyingSigner == ECDSA.recover(hash, signature);
    data = paymasterAndData;
  }

  function _parsePaymasterAndData(
    bytes calldata data
  ) internal pure returns (PaymasterAndData memory paymasterAndData, bytes calldata signature) {
    address paymaster = address(bytes20(data[:TOKEN_OFFSET]));
    IERC20Metadata token = IERC20Metadata(address(bytes20(data[TOKEN_OFFSET:VALID_TIMESTAMP_OFFSET])));

    (
      bool postTransfer,
      bool userCheck,
      uint48 validUntil,
      uint48 validAfter,
      uint256 preCharge,
      uint256 preFee,
      uint256 userBalance
    ) = abi.decode(
        data[VALID_TIMESTAMP_OFFSET:SIGNATURE_OFFSET],
        (bool, bool, uint48, uint48, uint256, uint256, uint256)
      );

    signature = data[SIGNATURE_OFFSET:];
    paymasterAndData = PaymasterAndData(
      paymaster,
      token,
      postTransfer,
      userCheck,
      validUntil,
      validAfter,
      preCharge,
      preFee,
      userBalance
    );
  }

  function _hash(
    UserOperation calldata userOp,
    PaymasterAndData memory paymasterAndData
  ) internal view returns (bytes32) {
    address sender = userOp.getSender();

    return
      keccak256(
        abi.encode(
          sender,
          userOp.nonce,
          keccak256(userOp.initCode),
          keccak256(userOp.callData),
          userOp.callGasLimit,
          userOp.verificationGasLimit,
          userOp.preVerificationGas,
          userOp.maxFeePerGas,
          userOp.maxPriorityFeePerGas,
          block.chainid,
          paymasterAndData.paymaster,
          paymasterAndData.token,
          paymasterAndData.postTransfer,
          paymasterAndData.validUntil,
          paymasterAndData.validAfter,
          paymasterAndData.preCharge,
          paymasterAndData.preFee
        )
      );
  }

  function _cachedPriceWithMarkup(IERC20Metadata token, TokenPaymasterConfig memory config) internal returns (uint256) {
    uint256 cachedPrice = _updateCachedPrice(token, config.oracle, config.toNative, false);
    return (cachedPrice * PRICE_DENOMINATOR) / config.priceMarkup;
  }

  function _gasPrice(uint256 maxFeePerGas, uint256 maxPriorityFeePerGas) internal view returns (uint256) {
    if (maxFeePerGas == maxPriorityFeePerGas) {
      //legacy mode (for networks that don't support basefee opcode)
      return maxFeePerGas;
    }
    return _min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function _payWithToken(
    IERC20Metadata token,
    address sender,
    bool postTransfer,
    uint256 preCharge,
    uint256 preFee,
    uint256 actualGas
  ) internal {
    int256 balance = balances[token][sender];

    require(balance >= 0, "Still have debts");

    TokenPaymasterConfig memory config = configs[token];

    uint256 cachedPriceWithMarkup = _cachedPriceWithMarkup(token, config);
    uint256 actualTokenNeeded = weiToToken(token, actualGas, cachedPriceWithMarkup);

    emit Debug1(cachedPriceWithMarkup, actualTokenNeeded, preCharge, preFee, postTransfer);

    uint256 allowance = token.allowance(sender, address(this));

    emit Debug2(allowance);

    if (postTransfer) {
      token.safeTransferFrom(sender, address(this), actualTokenNeeded + preFee);
      balances[token][treasury] += int256(preFee);
    } else {
      if (preCharge > actualTokenNeeded) {
        balances[token][sender] += int256(preCharge - actualTokenNeeded);
      } else if (actualTokenNeeded > preCharge) {
        token.safeTransferFrom(sender, address(this), actualTokenNeeded - preCharge);
      }
    }

    emit Pay(sender, token, actualTokenNeeded, preFee);

    balances[token][owner()] += int256(actualTokenNeeded);
  }

  function _tokenDebt(
    IERC20Metadata token,
    bool postTransfer,
    uint256 preCharge,
    uint256 actualGas,
    uint256 preFee
  ) internal returns (int256 debts) {
    TokenPaymasterConfig memory config = configs[token];

    uint256 cachedPriceWithMarkup = _cachedPriceWithMarkup(token, config);
    uint256 actualTokenNeeded = weiToToken(token, actualGas, cachedPriceWithMarkup);

    emit Debug3(cachedPriceWithMarkup, actualTokenNeeded, preCharge, preFee, postTransfer);

    if (postTransfer) {
      debts = int256(actualTokenNeeded + preFee);
    } else {
      if (actualTokenNeeded > preCharge) {
        debts = int256(actualTokenNeeded - preCharge);
      }
    }
  }

  function _tokenIndex(IERC20Metadata token) internal view returns (int index) {
    index = -1;

    IERC20Metadata[] memory _tokenList = tokenList;

    for (uint i; i < _tokenList.length; i++) {
      if (_tokenList[i] == token) {
        return int(i);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
  /**
   * return amount of tokens that are required to receive that much eth.
   */
  function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable not-rely-on-time */

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IOracle.sol";

/// @title Helper functions for dealing with various forms of price feed oracles.
/// @notice Maintains a price cache and updates the current price if needed.
/// In the best case scenario we have a direct oracle from the token to the native asset.
/// Also support tokens that have no direct price oracle to the native asset.
/// Sometimes oracles provide the price in the opposite direction of what we need in the moment.
abstract contract OracleHelper {
  struct TokenPrice {
    /// @notice The cached token price from the Oracle, always in (ether-per-token) * PRICE_DENOMINATOR format
    uint256 cachedPrice;
    /// @notice The timestamp of a block when the cached price was updated
    uint256 cachedPriceTimestamp;
  }

  uint256 private constant PRICE_DENOMINATOR = 1e26;

  /// @notice The price cache will be returned without even fetching the oracles for this number of seconds
  uint256 private constant cacheTimeToLive = 1 days;

  /// @notice The Oracle contract used to fetch the latest ETH prices
  IOracle private nativeOracle;

  mapping(IERC20 => TokenPrice) public prices;

  event TokenPriceUpdated(uint256 currentPrice, uint256 previousPrice, uint256 cachedPriceTimestamp);

  constructor(IOracle _nativeOracle) {
    nativeOracle = _nativeOracle;
  }

  /// @notice Updates the token price by fetching the latest price from the Oracle.
  function _updateCachedPrice(
    IERC20 token,
    IOracle tokenOracle,
    bool toNative,
    bool force
  ) public returns (uint256 newPrice) {
    TokenPrice memory tokenPrice = prices[token];

    uint256 oldPrice = tokenPrice.cachedPrice;
    uint256 cacheAge = block.timestamp - tokenPrice.cachedPriceTimestamp;

    if (!force && cacheAge <= cacheTimeToLive) {
      return oldPrice;
    }

    uint256 price = calculatePrice(tokenOracle, toNative);

    newPrice = price;
    tokenPrice.cachedPrice = newPrice;
    tokenPrice.cachedPriceTimestamp = block.timestamp;

    prices[token] = tokenPrice;

    emit TokenPriceUpdated(newPrice, oldPrice, tokenPrice.cachedPriceTimestamp);
  }

  function _removeTokenPrice(IERC20 token) internal {
    delete prices[token];
  }

  function calculatePrice(IOracle tokenOracle, bool toNative) public view returns (uint256 price) {
    // dollar per token (or native per token)
    uint256 tokenPrice = fetchPrice(tokenOracle);
    uint256 tokenOracleDecimalPower = 10 ** tokenOracle.decimals();

    if (toNative) {
      return (PRICE_DENOMINATOR * tokenPrice) / tokenOracleDecimalPower;
    }

    // dollar per native
    uint256 nativePrice = fetchPrice(nativeOracle);
    uint256 nativeOracleDecimalPower = 10 ** nativeOracle.decimals();

    // nativePrice is normalized as native per dollar
    nativePrice = (PRICE_DENOMINATOR * nativeOracleDecimalPower) / nativePrice;

    // multiplying by nativeAssetPrice that is  ethers-per-dollar
    // => result = (native / dollar) * (dollar / token) = native / token
    price = (nativePrice * tokenPrice) / tokenOracleDecimalPower;
  }

  /// @notice Fetches the latest price from the given Oracle.
  /// @dev This function is used to get the latest price from the tokenOracle or nativeOracle.
  /// @param _oracle The Oracle contract to fetch the price from.
  /// @return price The latest price fetched from the Oracle.
  function fetchPrice(IOracle _oracle) internal view returns (uint256 price) {
    (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = _oracle.latestRoundData();
    require(answer > 0, "TPM: Chainlink price <= 0");
    // 2 days old price is considered stale since the price is updated every 24 hours
    require(updatedAt >= block.timestamp - 60 * 60 * 24 * 2, "TPM: Incomplete round");
    require(answeredInRound >= roundId, "TPM: Stale price");
    price = uint256(answer);
  }

  function getCachedPrice(IERC20 token) internal view returns (uint256 price) {
    return prices[token].cachedPrice;
  }

  function getCachedPriceTimestamp(IERC20 token) internal view returns (uint256) {
    return prices[token].cachedPriceTimestamp;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable not-rely-on-time */

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";

abstract contract UniswapHelper {
  event UniswapReverted(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin);

  uint256 private constant PRICE_DENOMINATOR = 1e26;

  /// @notice 0.3% of pool fee
  uint24 private constant poolFee = 3000;

  uint8 private constant slippage = 50;

  /// @notice Minimum native asset amount to receive from a single swap, 0.01 wei
  uint256 private constant minSwapAmount = 1e16;

  /// @notice The Uniswap V3 SwapRouter contract
  ISwapRouter public immutable uniswap;

  /// @notice The ERC-20 token that wraps the native asset for current chain
  IERC20Metadata public immutable wrappedNative;

  constructor(IERC20Metadata _wrappedNative, ISwapRouter _uniswap) {
    wrappedNative = _wrappedNative;
    uniswap = _uniswap;
  }

  modifier canSwap() {
    require(address(uniswap) != address(0), "Not supported to swap");
    _;
  }

  function _maybeSwapTokenToWNative(IERC20Metadata tokenIn, uint256 amount, uint256 quote) internal returns (uint256) {
    tokenIn.approve(address(uniswap), amount);

    IERC20Metadata token = IERC20Metadata(address(tokenIn));
    uint256 amountOutMin = addSlippage(tokenToWei(token, amount, quote), slippage);
    if (amountOutMin < minSwapAmount) {
      return 0;
    }
    // note: calling 'swapToToken' but destination token is Wrapped Ether
    return swapToToken(address(tokenIn), address(wrappedNative), amount, amountOutMin, poolFee);
  }

  function addSlippage(uint256 amount, uint8 _slippage) private pure returns (uint256) {
    return (amount * (1000 - _slippage)) / 1000;
  }

  function tokenToWei(IERC20Metadata token, uint256 amount, uint256 price) public view returns (uint256) {
    uint256 nativeDecimal = 10 ** 18;
    uint256 tokenDecimal = 10 ** token.decimals();
    return (amount * nativeDecimal * price) / (PRICE_DENOMINATOR * tokenDecimal);
  }

  function weiToToken(IERC20Metadata token, uint256 amount, uint256 price) public view returns (uint256) {
    uint256 nativeDecimal = 10 ** 18;
    uint256 tokenDecimal = 10 ** token.decimals();
    return (amount * tokenDecimal * PRICE_DENOMINATOR) / (price * nativeDecimal);
  }

  // turn ERC-20 tokens into wrapped ETH at market price
  function swapToWeth(
    address tokenIn,
    address wethOut,
    uint256 amountOut,
    uint24 fee
  ) internal returns (uint256 amountIn) {
    ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
      tokenIn,
      wethOut, //tokenOut
      fee,
      address(uniswap), //recipient - keep WETH at SwapRouter for withdrawal
      block.timestamp, //deadline
      amountOut,
      type(uint256).max,
      0
    );
    amountIn = uniswap.exactOutputSingle(params);
  }

  function unwrapWeth(uint256 amount) internal {
    IPeripheryPayments(address(uniswap)).unwrapWETH9(amount, address(this));
  }

  // swap ERC-20 tokens at market price
  function swapToToken(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    uint24 fee
  ) internal returns (uint256 amountOut) {
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
      tokenIn, //tokenIn
      tokenOut, //tokenOut
      fee,
      address(uniswap),
      block.timestamp, //deadline
      amountIn,
      amountOutMin,
      0
    );
    try uniswap.exactInputSingle(params) returns (uint256 _amountOut) {
      amountOut = _amountOut;
    } catch {
      emit UniswapReverted(tokenIn, tokenOut, amountIn, amountOutMin);
      amountOut = 0;
    }
  }
}