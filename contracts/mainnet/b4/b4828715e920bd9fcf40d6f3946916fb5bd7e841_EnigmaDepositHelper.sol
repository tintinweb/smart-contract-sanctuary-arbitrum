// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

//openzeppelin
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

//Enigma imports
import {IEnigmaFactory} from "./interfaces/IEnigmaFactory.sol";
import {IWrappedNative} from "./interfaces/IWrappedNative.sol";
import {IEnigma} from "./interfaces/IEnigma.sol";
import {DepositParams} from "./types/EnigmaStructs.sol";

/// @title Enigma Deposit Helper contract
/// @notice allows native token to be used for deposits into enigma pool
/// @notice Next generation liquidity management protocol ontop of Uniswap v3
/// @author by SteakHut Labs © 2023
contract EnigmaDepositHelper is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address private immutable _wnative;

    /// -----------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------
    error EnigmaDepHelper__InvalidNativeAmount();
    error EnigmaDepHelper__NoNativeToken();

    /// @dev Receive function that only accept Native from the Native contract
    receive() external payable {
        require(msg.sender == address(_wnative), "VaultNative: Sender not Native contract");
    }

    /// -----------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------

    constructor(address wnative) {
        require(wnative != address(0), "WN:!0");
        _wnative = wnative;
    }

    /// -----------------------------------------------------------
    /// External Functions
    /// -----------------------------------------------------------

    function depositNative(DepositParams calldata params, address _enigma)
        external
        payable
        nonReentrant
        returns (uint256 shares, uint256 amount0, uint256 amount1)
    {
        //deposit native token into the underlying enigma
        IEnigma enigma = IEnigma(_enigma);

        //cache the token addresses
        address token0 = address(enigma.token0());
        address token1 = address(enigma.token1());

        //check that this enigma has a native token otherwise reverts
        _onlyVaultWithNativeToken(token0, token1);

        bool isNativeToken0 = address(enigma.token0()) == _wnative;

        // Check that the native token amount matches the amount of native tokens sent.
        if (
            isNativeToken0 && params.amount0Desired != msg.value
                || !isNativeToken0 && params.amount1Desired != msg.value
        ) {
            revert EnigmaDepHelper__InvalidNativeAmount();
        }

        //transfer into this contract and then execute enigma deposit
        //wrap the required amount of Native
        _nativeDepositAndTransfer(address(this), msg.value);

        //transfer non native token into this contract
        if (isNativeToken0) {
            //token0 is native so we need to transfer token 1 into this contract
            IERC20(token1).safeTransferFrom(msg.sender, address(this), params.amount1Desired);
        } else {
            //token1 is native so we need to transfer token 0 into this contract
            IERC20(token0).safeTransferFrom(msg.sender, address(this), params.amount0Desired);
        }

        //approve tokens
        IERC20(token0).safeApprove(_enigma, params.amount0Desired);
        IERC20(token1).safeApprove(_enigma, params.amount1Desired);

        //deposit into the underlying enigma pool
        (shares, amount0, amount1) = IEnigma(enigma).deposit(params);

        uint256 bal0After = IERC20(token0).balanceOf(address(this));
        uint256 bal1After = IERC20(token1).balanceOf(address(this));

        //refund left over amounts back to the user
        if (isNativeToken0) {
            //token0 is native so we need to transfer token 1 into this contract
            if (bal1After > 0) {
                IERC20(token1).safeTransfer(msg.sender, bal1After);
            }
            if (bal0After > 0) {
                _nativeWithdraw(bal0After);
                _safeTransferNative(msg.sender, bal0After);
            }
        } else {
            //token1 is native so we need to transfer token 0 into this contract
            if (bal0After > 0) {
                IERC20(token0).safeTransfer(msg.sender, bal0After);
            }

            if (bal1After > 0) {
                _nativeWithdraw(bal1After);
                _safeTransferNative(msg.sender, bal1After);
            }
        }

        //reset token approvals
        IERC20(token0).safeApprove(_enigma, 0);
        IERC20(token1).safeApprove(_enigma, 0);
    }

    /// -----------------------------------------------------------
    /// helpers
    /// -----------------------------------------------------------

    /// @dev function to check if one of the two vault tokens is the wrapped native token.
    function _onlyVaultWithNativeToken(address token0, address token1) internal view {
        if (token0 != _wnative && token1 != _wnative) revert EnigmaDepHelper__NoNativeToken();
    }

    /// -----------------------------------------------------------
    /// Internal / Private
    /// -----------------------------------------------------------

    /// @notice Helper function to transfer native token
    /// @param _to The address of the recipient
    /// @param _amount The native amount to send
    function _safeTransferNative(address _to, uint256 _amount) private {
        (bool success,) = _to.call{value: _amount}("");
        require(success, "Failed to Send Native");
    }

    /// @notice Helper function to deposit
    /// @param _amount The Native amount to wrap
    function _nativeDeposit(uint256 _amount) private {
        IWrappedNative(_wnative).deposit{value: _amount}();
    }

    /// @notice Helper function to deposit
    /// @param _amount The Native amount to wrap
    function _nativeWithdraw(uint256 _amount) private {
        IWrappedNative(_wnative).withdraw(_amount);
    }

    /// @notice Helper function to deposit and transfer wavax
    /// @param _to The address of the recipient
    /// @param _amount The Native amount to wrap
    function _nativeDepositAndTransfer(address _to, uint256 _amount) private {
        IWrappedNative(_wnative).deposit{value: _amount}();
        IERC20(address(_wnative)).safeTransfer(_to, _amount);
    }

    /// -----------------------------------------------------------
    /// Owner Functions
    /// -----------------------------------------------------------

    /// @notice Rescues funds stuck
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /// -----------------------------------------------------------
    /// END Enigma Deposit Helper by SteakHut Labs
    /// -----------------------------------------------------------
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
//pragma abicoder v2;

import {Range, Rebalance, DepositParams} from "../types/EnigmaStructs.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IEnigma {
    /// -----------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------

    /// @notice Emitted when a deposit is made to the enigma pool
    event Log_Deposit(address indexed sender, uint256 shares, uint256 amount0, uint256 amount1);
    /// @notice Emitted when a withdrawal is made to the enigma pool
    event Log_Withdraw(address indexed recipient, uint256 shares, uint256 amount0, uint256 amount1);
    /// @notice Emitted when a fee is collected from the underlying uniswap pool
    event Log_CollectFees(uint256 feeAmount0, uint256 feeAmount1);
    /// @notice Logs the distributed fees to the operator and enigma protocol
    event Log_DistributeFees(uint256 operatorFee0, uint256 operatorFee1, uint256 enigmaFee0, uint256 enigmaFee1);
    /// @notice Logs the rebalance of the enigmaPool
    event Log_Rebalance(Rebalance _params, uint256 balance0After, uint256 balance1After);
    /// @notice Logs if deposit caps have been set on the enigmaPool
    event Log_DepositMaxSet(uint256 deposit0Max, uint256 deposit1Max);
    /// @notice Logs if deposit caps have been set on the enigmaPool namely max total supply of lp tokens
    event Log_MaxTotalSupplySet(uint256 _maxTotalSupply);
    /// @notice Logs if the selected fee for the enigma has been updated
    event Log_SetEnigmaFee(uint256 _maxTotalSupply);
    /// @notice Logs if the enigmaPool isPrivate
    event Log_IsPrivate(bool);
    /// @notice Logs operator address
    event Log_SetOperator(address operator);
    /// @notice Logs whitelist status of address
    event Log_SetIsWhitelisted(address, bool isWhitelisted);
    /// -----------------------------------------------------------
    /// INTERFACE FUNCTIONS
    /// -----------------------------------------------------------

    //function ENIGMA_TREASURY_FEE() external view returns (uint256);
    function FEE_LIMIT() external view returns (uint256);
    function SELECTED_FEE() external view returns (uint256);
    function appendList(address[] memory listed) external;
    function deposit(DepositParams memory params) external returns (uint256 shares, uint256 amount0, uint256 amount1);
    function getFactory() external view returns (address factory_);
    function getPools() external view returns (address[] memory);
    function getRangeLength() external view returns (uint256);
    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);
    function isPrivate() external view returns (bool);
    function maxTotalSupply() external view returns (uint256);
    function operatorAddress() external view returns (address);
    function privateList(address) external view returns (bool);
    function ranges(uint256) external view returns (int24 tickLower, int24 tickUpper, int24 feeTier);
    function rebalance(Rebalance memory rebalanceData) external;
    function removeListed(address listed) external;
    function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external;
    function setMaxTotalSupply(uint256 _maxTotalSupply) external;
    function setOperator(address _operator) external;
    function setSelectedFee(uint256 _newSelectedFee) external;
    function togglePrivate() external;
    function withdraw(uint256 shares, address to, uint256 deadline)
        external
        returns (uint256 amount0, uint256 amount1);
    function inCaseTokensGetStuck(address _token) external;
    function getRanges() external view returns (Range[] memory ranges_);
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);
    function harvest() external;

    /// -----------------------------------------------------------
    /// END IEnigma.sol by SteakHut Labs
    /// -----------------------------------------------------------
}

// SPDX-License-Identifier: MIT

import "./IEnigma.sol";

pragma solidity 0.8.19;
//pragma abicoder v2;

interface IEnigmaFactory {
    /// -----------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------
    error EnigaFactory__SameImplementation(address EnigmaImplementation);
    error EnigmaFactory__SameFeeRecipient(address);
    error EnigmaFactory__AddressZero();
    error EnigmaFactory__EnigmaPoolSafetyCheckFailed(address newEnigmaImplementation);
    error EnigmaFactory__InvalidFee(uint256 invalidFee);
    /// @notice router is already whitelisted
    error Enigma__RouterWhitelisted(address _router);
    /// @notice factory cap limit is reached
    error Enigma__FactoryCap();
    /// -----------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------

    event Blacklist(address enigmaAddress, bool isBlacklisted);
    event EnigmaImplementationSet(address oldEnigmaImplementation, address newEnigmaImplementation);
    event FeeRecipientSet(address oldFeeRecipient, address feeRecipient);
    event Whitelist(address enigmaAddress, bool isWhitelisted);
    event SetEnigmaTreasuryFee(uint256 newFee);
    event EnigmaCreated(
        address enigmaAddress,
        address token0,
        address token1,
        uint256 selectedFee,
        uint24[] feeTiers,
        bool isPrivate,
        address operator
    );
    event RouterAllowed(address router, bool isAllowed);
    event Log__IsOpen(bool isOpen);
    event Log__FactoryCap(uint256 cap);
    event Log__PositionCap(uint256 cap);
    event Log__InCaseTokensStuck(uint256 amount, address token);

    /// -----------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------

    /// Shall be contained in structs dir

    /// -----------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------
    function blacklistAtIndex(uint256 _index) external view returns (address enigmaAddress);
    function blacklistEnigma(address _enigmaAddress, bool isBlacklisted) external;
    function blacklistPositionNumber() external view returns (uint256);
    function deployEnigmaPool(
        address _token0,
        address _token1,
        uint24[] memory _feeTiers,
        uint256 _selectedFee,
        bool _isPrivate,
        address _operator
    ) external returns (IEnigma pool_);
    function enigmaAtIndex(uint256 _index) external view returns (address enigmaAddress);
    function enigmaPools(address, address, address) external view returns (address);
    function enigmaPositionNumber() external view returns (uint256);
    function enigmaTreasury() external view returns (address);
    function getEnigmaImplementation() external view returns (address enigmaImplementation);
    function setEnigmaImplementation(address newEnigmaImplementation) external;
    function setFeeRecipient(address feeRecipient) external;
    function whitelistAtIndex(uint256 _index) external view returns (address enigmaAddress);
    function whitelistEnigma(address _enigmaAddress, bool isWhitelisted) external;
    function whitelistPositionNumber() external view returns (uint256);
    function ENIGMA_TREASURY_FEE() external view returns (uint256);
    function ENIGMA_MAX_POS() external view returns (uint256);
    function isRouterAllowed(address _router) external view returns (bool isAllowed);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IWrappedNative {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// -----------------------------------------------------------
/// ENIGMA STRUCTS
/// -----------------------------------------------------------

/// @param tickLower lower tick of the uniV3 position
/// @param tickUpper upper tick of the uniV3 position
/// @param feeTier upper tick of the uniV3 position
struct Range {
    int24 tickLower;
    int24 tickUpper;
    int24 feeTier;
}

/// @param liquidity amount of liquidity to allocate
/// @param range details of the range
struct Position {
    uint128 liquidity;
    Range range;
}

/// @param payload the swap payload to execute
/// @param router the swap router to use to perform swaps
/// @param amountIn the amount to input to swap
/// @param expectedMinReturn allows for slippage control
/// @param zeroForOne is token0 is swapped for token1
struct SwapPayload {
    bytes payload;
    address router;
    uint256 amountIn;
    uint256 expectedMinReturn;
    bool zeroForOne;
}

/// @notice struct for performing rebalances of underlying liquidity
/// contains slippage control parameters
struct Rebalance {
    Position[] burns;
    Position[] mints;
    SwapPayload swap;
    uint256 minBurn0;
    uint256 minBurn1;
    uint256 minDeposit0;
    uint256 minDeposit1;
}

/// @notice stores the params when a withdraw takes place
/// @param fee0 total fees in token0
/// @param fee1 total fees in token1
/// @param burn0 total token0 redeemed from burn
/// @param burn1 total token1 redeemed from burn
struct WithdrawParams {
    uint256 fee0;
    uint256 fee1;
    uint256 burn0;
    uint256 burn1;
}

/// @param amount0Desired The desired amount of token0 to be spent,
/// @param amount1Desired The desired amount of token1 to be spent,
/// @param minSharesToMint The minimum amount of shares expected
/// @param deadline The time by which the transaction must be included to effect the change
/// @param recipient The recipient of the minted share tokens
struct DepositParams {
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 minSharesToMint;
    uint256 deadline;
    address recipient;
}

/// @param _pool uniswapV3 pool to burn from
/// @param tickLower lower tick of the v3 pool
/// @param tickUpper lower tick of the v3 pool
/// @param liquidity liquidity to burn
/// @param to address to send the redeemed tokens
/// @param isZeroBurn isZeroBurn to recompute and collect fees
struct BurnParams {
    address _pool;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidity;
    address to;
    bool isZeroBurn;
}

/// -----------------------------------------------------------
/// END STRUCTS
/// -----------------------------------------------------------