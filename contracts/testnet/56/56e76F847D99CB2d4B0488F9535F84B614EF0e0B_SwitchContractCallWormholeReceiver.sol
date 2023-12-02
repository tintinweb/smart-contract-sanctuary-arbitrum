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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import "../interfaces/ISwapRouter.sol";
import "../external/wormhole/WormholeRelayerSDK.sol";

abstract contract SwitchWormholeAbstract is Switch, TokenBase {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    event SwapRouterSet(address swapRouter);

    ISwapRouter public swapRouter;

    // Used when swap required on dest chain
    struct SwapArgsWormhole {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        address recipient;
        address callTo;
        address partner;
        uint256 partnerFeeRate;
        uint256 amount;
        uint256 expectedReturn; // expected bridge token amount on sending chain
        uint256 minReturn; // minimum amount of bridge token
        uint256 bridgeDstAmount; // estimated token amount of bridgeToken
        uint256 estimatedDstTokenAmount; // estimated dest token amount on receiving chain
        uint256[] srcDistribution;
        uint256[] dstDistribution;
        uint16 dstChainId;
        uint256 gasLimit;
        uint32 nonce;
        bytes32 id;
        bytes32 bridge;
        bytes srcParaswapData;
        bytes dstParaswapData;
        DataTypes.SplitSwapInfo[] srcSplitSwapData;
        DataTypes.SplitSwapInfo[] dstSplitSwapData; // Can be empty if dst chain is cosmos
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
    }

    struct WormholeSwapRequest {
        bytes32 id;
        bytes32 bridge;
        address recipient;
        address bridgeToken;
        address dstToken;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        bytes dstParaswapData;
        DataTypes.SplitSwapInfo[] dstSplitSwapData;
        uint256[] dstDistribution;
        uint256 bridgeDstAmount;
        uint256 estimatedDstTokenAmount;
    }

    struct Sc {
        address weth;
        address otherToken;
        uint256[] pathCountAndSplit;
        address[] factories;
        address switchViewAddress;
        address switchEventAddress;
        address paraswapProxy;
        address augustusSwapper;
        address swapRouter;
        address feeCollector;
    }

    struct WormholeArgs {
        address wormholeRelayer;
        address wormhole;
        address tokenBridge;
    }

    constructor(
        Sc memory _sc,
        WormholeArgs memory _wormholeArgs
    )
        Switch(
            _sc.weth,
            _sc.otherToken,
            _sc.pathCountAndSplit[0],
            _sc.pathCountAndSplit[1],
            _sc.factories,
            _sc.switchViewAddress,
            _sc.switchEventAddress,
            _sc.paraswapProxy,
            _sc.augustusSwapper,
            _sc.feeCollector
        )
        TokenBase(
            _wormholeArgs.wormholeRelayer,
            _wormholeArgs.tokenBridge,
            _wormholeArgs.wormhole
        )
    {
        swapRouter = ISwapRouter(_sc.swapRouter);
    }

    receive() external payable {}

    /**
     * set swapRouter address
     * @param _swapRouter new swapRouter address
     */
    function setSwapRouter(address _swapRouter) external onlyOwner {
        swapRouter = ISwapRouter(_swapRouter);
        emit SwapRouterSet(_swapRouter);
    }

    function _swap(
        ISwapRouter.SwapRequest memory swapRequest,
        bool checkUnspent
    ) internal returns (uint256 unspent, uint256 returnAmount) {
        if (address(swapRequest.srcToken) == address(swapRequest.dstToken)) {
            return (0, swapRequest.amountIn);
        } else {
            swapRequest.srcToken.universalApprove(
                address(swapRouter),
                swapRequest.amountIn
            );

            uint256 value = swapRequest.srcToken.isETH()
                ? swapRequest.amountIn
                : 0;
            (unspent, returnAmount) = swapRouter.swap{value: value}(
                ISwapRouter.SwapRequest({
                    srcToken: swapRequest.srcToken,
                    dstToken: swapRequest.dstToken,
                    amountIn: swapRequest.amountIn,
                    amountMinSpend: swapRequest.amountMinSpend,
                    amountOutMin: swapRequest.amountOutMin,
                    useParaswap: swapRequest.useParaswap,
                    paraswapData: swapRequest.paraswapData,
                    splitSwapData: swapRequest.splitSwapData,
                    distribution: swapRequest.distribution,
                    raiseError: swapRequest.raiseError
                })
            );

            require(unspent == 0 || !checkUnspent, "F1");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import {ICallDataExecutor} from "../interfaces/ICallDataExecutor.sol";
import "../abstracts/SwitchWormholeAbstract.sol";
import "../external/wormhole/WormholeRelayerSDK.sol";

contract SwitchContractCallWormholeReceiver is
    SwitchWormholeAbstract,
    TokenReceiver
{
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    event CallDataExecutorSet(address callDataExecutor);

    address public callDataExecutor;

    constructor(
        Sc memory _sc,
        WormholeArgs memory _wormholeArgs
    ) SwitchWormholeAbstract(_sc, _wormholeArgs) {}

    /**
     * set calldataExecutor address
     * @param _newCallDataExecutor new calldataExecutor address
     */
    function setCallDataExecutor(
        address _newCallDataExecutor
    ) external onlyOwner {
        callDataExecutor = _newCallDataExecutor;
        emit CallDataExecutorSet(_newCallDataExecutor);
    }

    function _emitCrosschainContractCallDone(
        WormholeSwapRequest memory swapRequest,
        DataTypes.ContractCallInfo memory callInfo,
        address bridgeToken,
        uint256 srcAmount,
        uint256 dstAmount,
        DataTypes.ContractCallStatus status
    ) internal {
        switchEvent.emitCrosschainContractCallDone(
            swapRequest.id,
            swapRequest.bridge,
            swapRequest.recipient,
            callInfo.toContractAddress,
            callInfo.toApprovalAddress,
            bridgeToken,
            swapRequest.dstToken,
            srcAmount,
            dstAmount,
            status
        );
    }

    function _emitCrosschainSwapDone(
        WormholeSwapRequest memory swapRequest,
        address bridgeToken,
        uint256 srcAmount,
        uint256 dstAmount,
        DataTypes.SwapStatus status
    ) internal {
        switchEvent.emitCrosschainSwapDone(
            swapRequest.id,
            swapRequest.bridge,
            swapRequest.recipient,
            bridgeToken,
            swapRequest.dstToken,
            srcAmount,
            dstAmount,
            status
        );
    }

    /**
     * Call contract function by calldataExecutor contract.
     * This function call be called by this address itself to handle try...catch
     * @param callInfo remote call info
     * @param amount the token amount use during contract call.
     * @param token the token address used during contract call.
     * @param recipient the address to receive receipt token.
     */
    function remoteContractCall(
        DataTypes.ContractCallInfo memory callInfo,
        uint256 amount,
        IERC20 token,
        address recipient
    ) external {
        require(msg.sender == address(this), "S1");

        uint256 value;
        if (token.isETH()) {
            value = amount;
        } else {
            token.universalTransfer(callDataExecutor, amount);
        }

        // execute calldata for contract call
        ICallDataExecutor(callDataExecutor).execute{value: value}(
            IERC20(token),
            callInfo.toContractAddress,
            callInfo.toApprovalAddress,
            callInfo.contractOutputsToken,
            recipient,
            amount,
            callInfo.toContractGasLimit,
            callInfo.toContractCallData
        );
    }

    /**
     * Internal function to handle wormhole execution on destination chain
     */
    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32, // sourceAddress
        uint16,
        bytes32 // deliveryHash
    ) internal override onlyWormholeRelayer {
        uint amount = receivedTokens[0].amount;

        (
            WormholeSwapRequest memory swapRequest,
            bytes memory encodedCallInfo
        ) = abi.decode(payload, (WormholeSwapRequest, bytes));

        address bridgeToken = receivedTokens[0].tokenAddress;

        bool useParaswap = swapRequest.paraswapUsageStatus ==
            DataTypes.ParaswapUsageStatus.Both ||
            swapRequest.paraswapUsageStatus ==
            DataTypes.ParaswapUsageStatus.OnDestChain;

        uint256 returnAmount;

        DataTypes.SwapStatus status;

        if (bridgeToken == swapRequest.dstToken) {
            returnAmount = amount;
        } else {
            uint256 unspent;
            (unspent, returnAmount) = _swap(
                ISwapRouter.SwapRequest({
                    srcToken: IERC20(bridgeToken),
                    dstToken: IERC20(swapRequest.dstToken),
                    amountIn: amount,
                    amountMinSpend: swapRequest.bridgeDstAmount,
                    amountOutMin: 0,
                    useParaswap: useParaswap,
                    paraswapData: swapRequest.dstParaswapData,
                    splitSwapData: swapRequest.dstSplitSwapData,
                    distribution: swapRequest.dstDistribution,
                    raiseError: false
                }),
                false
            );

            if (unspent > 0) {
                // Transfer rest bridge token to user
                IERC20(bridgeToken).universalTransfer(
                    swapRequest.recipient,
                    unspent
                );
            }
        }

        // _emitCrosschainSwapDone(
        //     swapRequest,
        //     bridgeToken,
        //     amount,
        //     returnAmount,
        //     status
        // );

        if (encodedCallInfo.length != 0) {
            DataTypes.ContractCallInfo memory callInfo = abi.decode(
                encodedCallInfo,
                (DataTypes.ContractCallInfo)
            );

            DataTypes.ContractCallStatus contractCallStatus = DataTypes
                .ContractCallStatus
                .Failed;

            if (
                returnAmount >= swapRequest.estimatedDstTokenAmount &&
                callDataExecutor != address(0)
            ) {
                // execute calldata for contract call
                try
                    this.remoteContractCall(
                        callInfo,
                        swapRequest.estimatedDstTokenAmount,
                        IERC20(swapRequest.dstToken),
                        swapRequest.recipient
                    )
                {
                    returnAmount -= swapRequest.estimatedDstTokenAmount;

                    contractCallStatus = DataTypes.ContractCallStatus.Succeeded;
                } catch {}
            }
            // _emitCrosschainContractCallDone(
            //     swapRequest,
            //     callInfo,
            //     bridgeToken,
            //     amount,
            //     swapRequest.estimatedDstTokenAmount,
            //     contractCallStatus
            // );
        }

        if (returnAmount != 0) {
            IERC20(swapRequest.dstToken).universalTransfer(
                swapRequest.recipient,
                returnAmount
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../interfaces/IUniswapFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ISwitchView {

    struct ReturnArgs {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
    }

    struct CalculateArgs {
        IERC20 fromToken;
        IERC20 destToken;
        IUniswapFactory factory;
        uint256 amount;
        uint256 parts;
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
        public
        virtual
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) virtual external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./ISwitchView.sol";
import "./IWETH.sol";
import "../lib/DisableFlags.sol";
import "../lib/UniversalERC20.sol";
import "../interfaces/IUniswapFactory.sol";
import "../lib/UniswapExchangeLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SwitchRoot is Ownable, ISwitchView {
    using DisableFlags for uint256;
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniswapExchangeLib for IUniswapExchange;

    address public ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public ZERO_ADDRESS = address(0);

    uint256 public dexCount;
    uint256 public pathCount;
    uint256 public pathSplit;
    IWETH public weth; // chain's native token
    IWETH public otherToken; //could be weth on a non-eth chain or other mid token(like busd)

    address[] public factories;

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;

    constructor(address _weth, address _otherToken, uint256 _pathCount, uint256 _pathSplit, address[] memory _factories) {
        weth = IWETH(_weth);
        otherToken = IWETH(_otherToken);
        pathCount = _pathCount;
        pathSplit = _pathSplit;
        dexCount = _factories.length;
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.push(_factories[i]);
        }
    }

    event WETHSet(address _weth);
    event OtherTokenSet(address _otherToken);
    event PathCountSet(uint256 _pathCount);
    event PathSplitSet(uint256 _pathSplit);
    event FactoriesSet(address[] _factories);

    function setWETH(address _weth) external onlyOwner {
        weth = IWETH(_weth);
        emit WETHSet(_weth);
    }

    function setOtherToken(address _otherToken) external onlyOwner {
        otherToken = IWETH(_otherToken);
        emit OtherTokenSet(_otherToken);
    }

    function setPathCount(uint256 _pathCount) external onlyOwner {
        pathCount = _pathCount;
        emit PathCountSet(_pathCount);
    }

    function setPathSplit(uint256 _pathSplit) external onlyOwner {
        pathSplit = _pathSplit;
        emit PathSplitSet(_pathSplit);
    }

    function setFactories(address[] memory _factories) external onlyOwner {
        dexCount = _factories.length;
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.push(_factories[i]);
        }
        emit FactoriesSet(_factories);
    }

    function _findBestDistribution(
        uint256 s,                // parts
        int256[][] memory amounts // exchangesReturns
    )
        internal
        view
        returns (
            int256 returnAmount,
            uint256[] memory distribution
        )
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            for (uint i = 1; i < n; i++) {
                answer[i][j] = -1e72;
            }
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](dexCount*pathCount*pathSplit);

        uint256 partsLeft = s;
        unchecked {
            for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
                distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
                partsLeft = parent[curExchange][partsLeft];
            }
        }

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? int256(0) : answer[n - 1][s];
    }

    function _linearInterpolation(
        uint256 value,
        uint256 parts
    )
        internal
        pure
        returns (uint256[] memory rets)
    {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = value * (i + 1) / parts;
        }
    }

    function _tokensEqual(
        IERC20 tokenA,
        IERC20 tokenB
    )
        internal
        pure
        returns (bool)
    {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../core/ISwitchView.sol";
import "../core/SwitchRoot.sol";
import "../interfaces/ISwitchEvent.sol";
import "../interfaces/IFeeCollector.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Switch is Ownable, SwitchRoot, ReentrancyGuard {
    using UniswapExchangeLib for IUniswapExchange;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    ISwitchView public switchView;
    ISwitchEvent public switchEvent;
    address public reward;
    address public paraswapProxy;
    address public augustusSwapper;

    address public feeCollector;
    uint256 public maxPartnerFeeRate = 1000; // max partner fee rate is 10%
    uint256 public defaultSwingCut = 1500; // swing takes a cut of 15% from partner fee by default

    uint256 public constant FEE_BASE = 10000;

    struct SwapArgs {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 expectedReturn;
        uint256 minReturn;
        address partner;
        uint256 partnerFeeRate;
        address recipient;
        uint256[] distribution;
    }

    event RewardSet(address reward);
    event FeeCollectorSet(address feeCollector);
    event MaxPartnerFeeRateSet(uint256 maxPartnerFeeRate);
    event DefaultSwingCutSet(uint256 defaultSwingCut);
    event SwitchEventSet(ISwitchEvent switchEvent);
    event ParaswapProxySet(address paraswapProxy);
    event AugustusSwapperSet(address augustusSwapper);

    constructor(
        address _weth,
        address _otherToken,
        uint256 _pathCount,
        uint256 _pathSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper,
        address _feeCollector
    ) SwitchRoot(_weth, _otherToken, _pathCount, _pathSplit, _factories)
        public
    {
        switchView = ISwitchView(_switchViewAddress);
        switchEvent = ISwitchEvent(_switchEventAddress);
        paraswapProxy = _paraswapProxy;
        augustusSwapper = _augustusSwapper;
        feeCollector = _feeCollector;
        reward = msg.sender;
    }

    fallback() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function setReward(address _reward) external onlyOwner {
        reward = _reward;
        emit RewardSet(_reward);
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
        emit FeeCollectorSet(_feeCollector);
    }

    function setMaxPartnerFeeRate(uint256 _maxPartnerFeeRate) external onlyOwner {
        require(_maxPartnerFeeRate <= 5000, "too large");
        maxPartnerFeeRate = _maxPartnerFeeRate;
        emit MaxPartnerFeeRateSet(_maxPartnerFeeRate);
    }

    function setDefaultSwingCut(uint256 _defaultSwingCut) external onlyOwner {
        defaultSwingCut = _defaultSwingCut;
        emit DefaultSwingCutSet(_defaultSwingCut);
    }

    function setSwitchEvent(ISwitchEvent _switchEvent) external onlyOwner {
        switchEvent = _switchEvent;
        emit SwitchEventSet(_switchEvent);
    }

    function setParaswapProxy(address _paraswapProxy) external onlyOwner {
        paraswapProxy = _paraswapProxy;
        emit ParaswapProxySet(_paraswapProxy);
    }

    function setAugustusSwapper(address _augustusSwapper) external onlyOwner {
        augustusSwapper = _augustusSwapper;
        emit AugustusSwapperSet(_augustusSwapper);
    }

    function getTokenBalance(address token) external view onlyOwner returns(uint256 amount) {
        amount = IERC20(token).universalBalanceOf(address(this));
    }

    function transferToken(address token, uint256 amount, address recipient) external onlyOwner {
        IERC20(token).universalTransfer(recipient, amount);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
        public
        override
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, distribution) = switchView.getExpectedReturn(fromToken, destToken, amount, parts);
    }

    function swap(
        SwapArgs calldata swapArgs
    )
        public
        payable
        nonReentrant
        returns (uint256 returnAmount)
    {
        require(swapArgs.expectedReturn >= swapArgs.minReturn, "expectedReturn must be equal or larger than minReturn");
        if (swapArgs.fromToken == swapArgs.destToken) {
            revert("it's not allowed to swap with same token");
        }

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < swapArgs.distribution.length; i++) {
            if (swapArgs.distribution[i] > 0) {
                parts += swapArgs.distribution[i];
                lastNonZeroIndex = i;
            }
        }

        if (parts == 0) {
            if (swapArgs.fromToken.isETH()) {
                payable(msg.sender).transfer(msg.value);
                return msg.value;
            }
            return swapArgs.amount;
        }

        swapArgs.fromToken.universalTransferFrom(msg.sender, address(this), swapArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(swapArgs.fromToken, swapArgs.amount, swapArgs.partner, swapArgs.partnerFeeRate);
        returnAmount = _swapInternalForSingleSwap(swapArgs.distribution, amountAfterFee, parts, lastNonZeroIndex, swapArgs.fromToken, swapArgs.destToken);
        if (returnAmount > 0) {
            require(returnAmount >= swapArgs.minReturn, "Switch: Return amount was not enough");

            if (returnAmount > swapArgs.expectedReturn) {
                swapArgs.destToken.universalTransfer(swapArgs.recipient, swapArgs.expectedReturn);
                swapArgs.destToken.universalTransfer(reward, returnAmount - swapArgs.expectedReturn);
                switchEvent.emitSwapped(msg.sender, swapArgs.recipient, swapArgs.fromToken, swapArgs.destToken, swapArgs.amount, swapArgs.expectedReturn, returnAmount - swapArgs.expectedReturn);
            } else {
                swapArgs.destToken.universalTransfer(swapArgs.recipient, returnAmount);
                switchEvent.emitSwapped(msg.sender, swapArgs.recipient, swapArgs.fromToken, swapArgs.destToken, swapArgs.amount, returnAmount, 0);
            }
        } else {
            if (swapArgs.fromToken.universalBalanceOf(address(this)) > swapArgs.amount) {
                swapArgs.fromToken.universalTransfer(msg.sender, swapArgs.amount);
            } else {
                swapArgs.fromToken.universalTransfer(msg.sender, swapArgs.fromToken.universalBalanceOf(address(this)));
            }
        }
    }

    function swapWithParaswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 destAmount,
        address partner,
        uint256 partnerFeeRate,
        address recipient,
        bytes memory callData
    )
        public
        payable
        nonReentrant
    {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }
        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(fromToken), amount, partner, partnerFeeRate);
        _swapInternalWithParaSwap(fromToken, destToken, amountAfterFee, callData);
    }


    function getFeeInfo(
        uint256 amount,
        address partner,
        uint256 partnerFeeRate
    )
        public
        view
        returns (
            uint256 partnerFee,
            uint256 remainAmount
        )
    {
        partnerFee = partnerFeeRate * amount / FEE_BASE;
        remainAmount = amount - partnerFee;
    }

    function _swapInternalWithParaSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        bytes memory callData
    )
        internal
        returns (
            uint256 totalAmount
        )
    {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }

        _callParaswap(fromToken, amount, callData);
        totalAmount = destToken.universalBalanceOf(address(this));
        switchEvent.emitSwapped(msg.sender, address(this), fromToken, destToken, amount, totalAmount, 0);
    }

    function _callParaswap(
        IERC20 token,
        uint256 amount,
        bytes memory callData
    )
        internal
    {
        uint256 ethAmountToTransfert = 0;
        if (token.isETH()) {
            require(address(this).balance >= amount, "ETH balance is insufficient");
            ethAmountToTransfert = amount;
        } else {
            token.universalApprove(paraswapProxy, amount);
        }

        (bool success,) = augustusSwapper.call{ value: ethAmountToTransfert }(callData);
        require(success, "Paraswap execution failed");
    }

    function _swapInternalForSingleSwap(
        uint256[] memory distribution,
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        IERC20 fromToken,
        IERC20 destToken
    )
        internal
        returns (
            uint256 totalAmount
        )
    {
        require(distribution.length <= dexCount*pathCount, "Switch: Distribution array should not exceed factories array size");

        uint256 remainingAmount = amount;
        uint256 swappedAmount = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }
            uint256 swapAmount = amount * distribution[i] / parts;
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            if (i % pathCount == 0) {
                swappedAmount = _swap(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            } else if (i % pathCount == 1) {
                swappedAmount = _swapETH(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            } else {
                swappedAmount = _swapOtherToken(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            }
            totalAmount += swappedAmount;
        }
    }

    function _getAmountAfterFee(
        IERC20 token,
        uint256 amount,
        address partner,
        uint256 partnerFeeRate
    )
        internal
        returns (
            uint256 amountAfterFee
        )
    {
        require(partnerFeeRate <= maxPartnerFeeRate, "partnerFeeRate too large");
        amountAfterFee = amount;
        if (partnerFeeRate > 0) {
            uint256 swingCut = IFeeCollector(feeCollector).getPartnerSwingCut(partner) == 0 ? defaultSwingCut : IFeeCollector(feeCollector).getPartnerSwingCut(partner);
            uint256 swingFee = partnerFeeRate * amount * defaultSwingCut / (FEE_BASE * FEE_BASE);
            uint256 partnerFee = partnerFeeRate * amount / FEE_BASE - swingFee;
            if (IERC20(token).isETH()) {
                IFeeCollector(feeCollector).collectTokenFees{ value: partnerFee + swingFee }(address(token), partnerFee, swingFee, partner);
            } else {
                IERC20(token).safeApprove(feeCollector, 0);
                IERC20(token).safeApprove(feeCollector, partnerFee + swingFee);
                IFeeCollector(feeCollector).collectTokenFees(address(token), partnerFee, swingFee, partner);
            }
            amountAfterFee = amount - partnerFeeRate * amount / FEE_BASE;
        }
    }

    // Swap helpers
    function _swapInternal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        if (fromToken.isETH()) {
            weth.deposit{value: amount}();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapExchange exchange = factory.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(0x46Fd07da395799F113a7584563b8cB886F33c2bc);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint160(address(fromTokenReal)) < uint160(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternal(
            midToken,
            destToken,
            _swapInternal(
                fromToken,
                midToken,
                amount,
                factory
            ),
            factory
        );
    }

    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternal(
            fromToken,
            destToken,
            amount,
            factory
        );
    }

    function _swapETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapOverMid(
            fromToken,
            weth,
            destToken,
            amount,
            factory
        );
    }

    function _swapOtherToken(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapOverMid(
            fromToken,
            otherToken,
            destToken,
            amount,
            factory
        );
    }
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;
        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(
        address indexed sender,
        uint64 sequence,
        uint32 nonce,
        bytes payload,
        uint8 consistencyLevel
    );
    event ContractUpgraded(
        address indexed oldContract,
        address indexed newContract
    );
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(
        bytes calldata encodedVM
    ) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(
        VM memory vm
    ) external view returns (bool valid, string memory reason);

    function verifySignatures(
        bytes32 hash,
        Signature[] memory signatures,
        GuardianSet memory guardianSet
    ) external pure returns (bool valid, string memory reason);

    function parseVM(
        bytes memory encodedVM
    ) external pure returns (VM memory vm);

    function quorum(
        uint256 numGuardians
    ) external pure returns (uint256 numSignaturesRequiredForQuorum);

    function getGuardianSet(
        uint32 index
    ) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(
        bytes32 hash
    ) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(
        bytes memory encodedUpgrade
    ) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(
        bytes memory encodedUpgrade
    ) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(
        bytes memory encodedSetMessageFee
    ) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(
        bytes memory encodedTransferFees
    ) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(
        bytes memory encodedRecoverChainId
    ) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @notice Interface for a contract which can receive Wormhole messages.
 */
interface IWormholeReceiver {
    /**
     * @notice When a `send` is performed with this contract as the target, this function will be
     *     invoked by the WormholeRelayer contract
     *
     * NOTE: This function should be restricted such that only the Wormhole Relayer contract can call it.
     *
     * We also recommend that this function:
     *   - Stores all received `deliveryHash`s in a mapping `(bytes32 => bool)`, and
     *       on every call, checks that deliveryHash has not already been stored in the
     *       map (This is to prevent other users maliciously trying to relay the same message)
     *   - Checks that `sourceChain` and `sourceAddress` are indeed who
     *       you expect to have requested the calling of `send` on the source chain
     *
     * The invocation of this function corresponding to the `send` request will have msg.value equal
     *   to the receiverValue specified in the send request.
     *
     * If the invocation of this function reverts or exceeds the gas limit
     *   specified by the send requester, this delivery will result in a `ReceiverFailure`.
     *
     * @param payload - an arbitrary message which was included in the delivery by the
     *     requester.
     * @param additionalVaas - Additional VAAs which were requested to be included in this delivery.
     *   They are guaranteed to all be included and in the same order as was specified in the
     *     delivery request.
     * @param sourceAddress - the (wormhole format) address on the sending chain which requested
     *     this delivery.
     * @param sourceChain - the wormhole chain ID where this delivery was requested.
     * @param deliveryHash - the VAA hash of the deliveryVAA.
     *
     * NOTE: These signedVaas are NOT verified by the Wormhole core contract prior to being provided
     *     to this call. Always make sure `parseAndVerify()` is called on the Wormhole core contract
     *     before trusting the content of a raw VAA, otherwise the VAA may be invalid or malicious.
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @title WormholeRelayer
 * @author
 * @notice This project allows developers to build cross-chain applications powered by Wormhole without needing to
 * write and run their own relaying infrastructure
 *
 * We implement the IWormholeRelayer interface that allows users to request a delivery provider to relay a payload (and/or additional VAAs)
 * to a chain and address of their choice.
 */

/**
 * @notice VaaKey identifies a wormhole message
 *
 * @custom:member chainId Wormhole chain ID of the chain where this VAA was emitted from
 * @custom:member emitterAddress Address of the emitter of the VAA, in Wormhole bytes32 format
 * @custom:member sequence Sequence number of the VAA
 */
struct VaaKey {
    uint16 chainId;
    bytes32 emitterAddress;
    uint64 sequence;
}

interface IWormholeRelayerBase {
    event SendEvent(uint64 indexed sequence, uint256 deliveryQuote, uint256 paymentForExtraReceiverValue);

    function getRegisteredWormholeRelayerContract(uint16 chainId) external view returns (bytes32);
}

/**
 * @title IWormholeRelayerSend
 * @notice The interface to request deliveries
 */
interface IWormholeRelayerSend is IWormholeRelayerBase {
    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendPayloadToEvm` function
     * with `refundChain` and `refundAddress` as parameters
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendVaasToEvm` function
     * with `refundChain` and `refundAddress` as parameters
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, receiverValue, encodedExecutionParameters, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Requests a previously published delivery instruction to be redelivered
     * (e.g. with a different delivery provider)
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, newReceiverValue, newGasLimit, newDeliveryProviderAddress)
     *
     *  @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     *
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newGasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider, to the refund chain and address specified in the original request
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     *
     * @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function resendToEvm(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        uint256 newGasLimit,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Requests a previously published delivery instruction to be redelivered
     *
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, newReceiverValue, newEncodedExecutionParameters, newDeliveryProviderAddress)
     *
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newEncodedExecutionParameters new encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     *
     *  @notice *** This will only be able to succeed if the following is true **
     *         - (For EVM_V1) newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - (For EVM_V1) newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        bytes memory newEncodedExecutionParameters,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using the default delivery provider
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused,
     *         if a refundAddress is specified
     */
    function quoteEVMDeliveryPrice(uint16 targetChain, uint256 receiverValue, uint256 gasLimit)
        external
        view
        returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused,
     *         if a refundAddress is specified
     */
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit,
        address deliveryProviderAddress
    ) external view returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return encodedExecutionInfo encoded information on how the delivery will be executed
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` and `targetChainRefundPerGasUnused`
     *             (which is the amount of target chain currency that will be refunded per unit of gas unused,
     *              if a refundAddress is specified)
     */
    function quoteDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        bytes memory encodedExecutionParameters,
        address deliveryProviderAddress
    ) external view returns (uint256 nativePriceQuote, bytes memory encodedExecutionInfo);

    /**
     * @notice Returns the (extra) amount of target chain currency that `targetAddress`
     * will be called with, if the `paymentForExtraReceiverValue` field is set to `currentChainAmount`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param currentChainAmount The value that `paymentForExtraReceiverValue` will be set to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return targetChainAmount The amount such that if `targetAddress` will be called with `msg.value` equal to
     *         receiverValue + targetChainAmount
     */
    function quoteNativeForChain(uint16 targetChain, uint256 currentChainAmount, address deliveryProviderAddress)
        external
        view
        returns (uint256 targetChainAmount);

    /**
     * @notice Returns the address of the current default delivery provider
     * @return deliveryProvider The address of (the default delivery provider)'s contract on this source
     *   chain. This must be a contract that implements IDeliveryProvider.
     */
    function getDefaultDeliveryProvider() external view returns (address deliveryProvider);
}

/**
 * @title IWormholeRelayerDelivery
 * @notice The interface to execute deliveries. Only relevant for Delivery Providers
 */
interface IWormholeRelayerDelivery is IWormholeRelayerBase {
    enum DeliveryStatus {
        SUCCESS,
        RECEIVER_FAILURE
    }

    enum RefundStatus {
        REFUND_SENT,
        REFUND_FAIL,
        CROSS_CHAIN_REFUND_SENT,
        CROSS_CHAIN_REFUND_FAIL_PROVIDER_NOT_SUPPORTED,
        CROSS_CHAIN_REFUND_FAIL_NOT_ENOUGH
    }

    /**
     * @custom:member recipientContract - The target contract address
     * @custom:member sourceChain - The chain which this delivery was requested from (in wormhole
     *     ChainID format)
     * @custom:member sequence - The wormhole sequence number of the delivery VAA on the source chain
     *     corresponding to this delivery request
     * @custom:member deliveryVaaHash - The hash of the delivery VAA corresponding to this delivery
     *     request
     * @custom:member gasUsed - The amount of gas that was used to call your target contract
     * @custom:member status:
     *   - RECEIVER_FAILURE, if the target contract reverts
     *   - SUCCESS, if the target contract doesn't revert 
     * @custom:member additionalStatusInfo:
     *   - If status is SUCCESS, then this is empty.
     *   - If status is RECEIVER_FAILURE, this is `RETURNDATA_TRUNCATION_THRESHOLD` bytes of the
     *       return data (i.e. potentially truncated revert reason information).
     * @custom:member refundStatus - Result of the refund. REFUND_SUCCESS or REFUND_FAIL are for
     *     refunds where targetChain=refundChain; the others are for targetChain!=refundChain,
     *     where a cross chain refund is necessary
     * @custom:member overridesInfo:
     *   - If not an override: empty bytes array
     *   - Otherwise: An encoded `DeliveryOverride`
     */
    event Delivery(
        address indexed recipientContract,
        uint16 indexed sourceChain,
        uint64 indexed sequence,
        bytes32 deliveryVaaHash,
        DeliveryStatus status,
        uint256 gasUsed,
        RefundStatus refundStatus,
        bytes additionalStatusInfo,
        bytes overridesInfo
    );

    /**
     * @notice The delivery provider calls `deliver` to relay messages as described by one delivery instruction
     *
     * The delivery provider must pass in the specified (by VaaKeys[]) signed wormhole messages (VAAs) from the source chain
     * as well as the signed wormhole message with the delivery instructions (the delivery VAA)
     *
     * The messages will be relayed to the target address (with the specified gas limit and receiver value) iff the following checks are met:
     * - the delivery VAA has a valid signature
     * - the delivery VAA's emitter is one of these WormholeRelayer contracts
     * - the delivery provider passed in at least enough of this chain's currency as msg.value (enough meaning the maximum possible refund)
     * - the instruction's target chain is this chain
     * - the relayed signed VAAs match the descriptions in container.messages (the VAA hashes match, or the emitter address, sequence number pair matches, depending on the description given)
     *
     * @param encodedVMs - An array of signed wormhole messages (all from the same source chain
     *     transaction)
     * @param encodedDeliveryVAA - Signed wormhole message from the source chain's WormholeRelayer
     *     contract with payload being the encoded delivery instruction container
     * @param relayerRefundAddress - The address to which any refunds to the delivery provider
     *     should be sent
     * @param deliveryOverrides - Optional overrides field which must be either an empty bytes array or
     *     an encoded DeliveryOverride struct
     */
    function deliver(
        bytes[] memory encodedVMs,
        bytes memory encodedDeliveryVAA,
        address payable relayerRefundAddress,
        bytes memory deliveryOverrides
    ) external payable;
}

interface IWormholeRelayer is IWormholeRelayerDelivery, IWormholeRelayerSend {}

/*
 *  Errors thrown by IWormholeRelayer contract
 */

// Bound chosen by the following formula: `memoryWord * 4 + selectorSize`.
// This means that an error identifier plus four fixed size arguments should be available to developers.
// In the case of a `require` revert with error message, this should provide 2 memory word's worth of data.
uint256 constant RETURNDATA_TRUNCATION_THRESHOLD = 132;

//When msg.value was not equal to `delivery provider's quoted delivery price` + `paymentForExtraReceiverValue`
error InvalidMsgValue(uint256 msgValue, uint256 totalFee);

error RequestedGasLimitTooLow();

error DeliveryProviderDoesNotSupportTargetChain(address relayer, uint16 chainId);
error DeliveryProviderCannotReceivePayment();

//When calling `delivery()` a second time even though a delivery is already in progress
error ReentrantDelivery(address msgSender, address lockedBy);

error InvalidPayloadId(uint8 parsed, uint8 expected);
error InvalidPayloadLength(uint256 received, uint256 expected);
error InvalidVaaKeyType(uint8 parsed);

error InvalidDeliveryVaa(string reason);
//When the delivery VAA (signed wormhole message with delivery instructions) was not emitted by the
//  registered WormholeRelayer contract
error InvalidEmitter(bytes32 emitter, bytes32 registered, uint16 chainId);
error VaaKeysLengthDoesNotMatchVaasLength(uint256 keys, uint256 vaas);
error VaaKeysDoNotMatchVaas(uint8 index);
//When someone tries to call an external function of the WormholeRelayer that is only intended to be
//  called by the WormholeRelayer itself (to allow retroactive reverts for atomicity)
error RequesterNotWormholeRelayer();

//When trying to relay a `DeliveryInstruction` to any other chain but the one it was specified for
error TargetChainIsNotThisChain(uint16 targetChain);
//When a `DeliveryOverride` contains a gas limit that's less than the original
error InvalidOverrideGasLimit();
//When a `DeliveryOverride` contains a receiver value that's less than the original
error InvalidOverrideReceiverValue();
//When a `DeliveryOverride` contains a 'refund per unit of gas unused' that's less than the original
error InvalidOverrideRefundPerGasUnused();

//When the delivery provider doesn't pass in sufficient funds (i.e. msg.value does not cover the
// maximum possible refund to the user)
error InsufficientRelayerFunds(uint256 msgValue, uint256 minimum);

//When a bytes32 field can't be converted into a 20 byte EVM address, because the 12 padding bytes
//  are non-zero (duplicated from Utils.sol)
error NotAnEvmAddress(bytes32);

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.9;

import "../../../core/IWETH.sol";
import "./IWormhole.sol";

interface IWormholeTokenBridge {
    struct Transfer {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        uint256 fee;
    }

    struct TransferWithPayload {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        bytes32 fromAddress;
        bytes payload;
    }

    struct AssetMeta {
        uint8 payloadID;
        bytes32 tokenAddress;
        uint16 tokenChain;
        uint8 decimals;
        bytes32 symbol;
        bytes32 name;
    }

    struct RegisterChain {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        uint16 emitterChainID;
        bytes32 emitterAddress;
    }

    struct UpgradeContract {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        bytes32 newContract;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;
        uint256 evmChainId;
        uint16 newChainId;
    }

    event ContractUpgraded(
        address indexed oldContract,
        address indexed newContract
    );

    function _parseTransferCommon(
        bytes memory encoded
    ) external pure returns (Transfer memory transfer);

    function attestToken(
        address tokenAddress,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function wrapAndTransferETH(
        uint16 recipientChain,
        bytes32 recipient,
        uint256 arbiterFee,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function wrapAndTransferETHWithPayload(
        uint16 recipientChain,
        bytes32 recipient,
        uint32 nonce,
        bytes memory payload
    ) external payable returns (uint64 sequence);

    function transferTokens(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint256 arbiterFee,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function transferTokensWithPayload(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint32 nonce,
        bytes memory payload
    ) external payable returns (uint64 sequence);

    function updateWrapped(
        bytes memory encodedVm
    ) external returns (address token);

    function createWrapped(
        bytes memory encodedVm
    ) external returns (address token);

    function completeTransferWithPayload(
        bytes memory encodedVm
    ) external returns (bytes memory);

    function completeTransferAndUnwrapETHWithPayload(
        bytes memory encodedVm
    ) external returns (bytes memory);

    function completeTransfer(bytes memory encodedVm) external;

    function completeTransferAndUnwrapETH(bytes memory encodedVm) external;

    function encodeAssetMeta(
        AssetMeta memory meta
    ) external pure returns (bytes memory encoded);

    function encodeTransfer(
        Transfer memory transfer
    ) external pure returns (bytes memory encoded);

    function encodeTransferWithPayload(
        TransferWithPayload memory transfer
    ) external pure returns (bytes memory encoded);

    function parsePayloadID(
        bytes memory encoded
    ) external pure returns (uint8 payloadID);

    function parseAssetMeta(
        bytes memory encoded
    ) external pure returns (AssetMeta memory meta);

    function parseTransfer(
        bytes memory encoded
    ) external pure returns (Transfer memory transfer);

    function parseTransferWithPayload(
        bytes memory encoded
    ) external pure returns (TransferWithPayload memory transfer);

    function governanceActionIsConsumed(
        bytes32 hash
    ) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function isTransferCompleted(bytes32 hash) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function evmChainId() external view returns (uint256);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function wrappedAsset(
        uint16 tokenChainId,
        bytes32 tokenAddress
    ) external view returns (address);

    function bridgeContracts(uint16 chainId_) external view returns (bytes32);

    function tokenImplementation() external view returns (address);

    function WETH() external view returns (IWETH);

    function outstandingBridged(address token) external view returns (uint256);

    function isWrappedAsset(address token) external view returns (bool);

    function finality() external view returns (uint8);

    function implementation() external view returns (address);

    function initialize() external;

    function registerChain(bytes memory encodedVM) external;

    function upgrade(bytes memory encodedVM) external;

    function submitRecoverChainId(bytes memory encodedVM) external;

    function parseRegisterChain(
        bytes memory encoded
    ) external pure returns (RegisterChain memory chain);

    function parseUpgrade(
        bytes memory encoded
    ) external pure returns (UpgradeContract memory chain);

    function parseRecoverChainId(
        bytes memory encodedRecoverChainId
    ) external pure returns (RecoverChainId memory rci);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import "./interfaces/IWormholeRelayer.sol";

function toWormholeFormat(address addr) pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
}

function fromWormholeFormat(bytes32 whFormatAddress) pure returns (address) {
    if (uint256(whFormatAddress) >> 160 != 0) {
        revert NotAnEvmAddress(whFormatAddress);
    }
    return address(uint160(uint256(whFormatAddress)));
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/IWormholeRelayer.sol";
import "./interfaces/IWormholeTokenBridge.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Utils.sol";

abstract contract Base {
    IWormholeRelayer public immutable wormholeRelayer;
    IWormhole public immutable wormhole;

    mapping(bytes32 => bool) public seenDeliveryVaaHashes;

    address registrationOwner;
    mapping(uint16 => bytes32) registeredSenders;

    constructor(address _wormholeRelayer, address _wormhole) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        wormhole = IWormhole(_wormhole);
        registrationOwner = msg.sender;
    }

    modifier onlyWormholeRelayer() {
        require(
            msg.sender == address(wormholeRelayer),
            "Msg.sender is not Wormhole Relayer"
        );
        _;
    }

    modifier replayProtect(bytes32 deliveryHash) {
        require(
            !seenDeliveryVaaHashes[deliveryHash],
            "Message already processed"
        );
        seenDeliveryVaaHashes[deliveryHash] = true;
        _;
    }

    modifier isRegisteredSender(uint16 sourceChain, bytes32 sourceAddress) {
        require(
            registeredSenders[sourceChain] == sourceAddress,
            "Not registered sender"
        );
        _;
    }

    /**
     * Sets the registered address for 'sourceChain' to 'sourceAddress'
     * So that for messages from 'sourceChain', only ones from 'sourceAddress' are valid
     *
     * Assumes only one sender per chain is valid
     * Sender is the address that called 'send' on the Wormhole Relayer contract on the source chain)
     */
    function setRegisteredSender(
        uint16 sourceChain,
        bytes32 sourceAddress
    ) public {
        require(
            msg.sender == registrationOwner,
            "Not allowed to set registered sender"
        );
        registeredSenders[sourceChain] = sourceAddress;
    }
}

abstract contract TokenBase is Base {
    IWormholeTokenBridge public immutable tokenBridge;

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole
    ) Base(_wormholeRelayer, _wormhole) {
        tokenBridge = IWormholeTokenBridge(_tokenBridge);
    }

    function getDecimals(
        address tokenAddress
    ) internal view returns (uint8 decimals) {
        // query decimals
        (, bytes memory queriedDecimals) = address(tokenAddress).staticcall(
            abi.encodeWithSignature("decimals()")
        );
        decimals = abi.decode(queriedDecimals, (uint8));
    }

    function getTokenAddressOnThisChain(
        uint16 tokenHomeChain,
        bytes32 tokenHomeAddress
    ) internal view returns (address tokenAddressOnThisChain) {
        return
            tokenHomeChain == wormhole.chainId()
                ? fromWormholeFormat(tokenHomeAddress)
                : tokenBridge.wrappedAsset(tokenHomeChain, tokenHomeAddress);
    }
}

abstract contract TokenSender is TokenBase {
    /**
     * transferTokens wraps common boilerplate for sending tokens to another chain using IWormholeRelayer
     * - approves tokenBridge to spend 'amount' of 'token'
     * - emits token transfer VAA
     * - returns VAA key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this function uses transferTokensWithPayload instead of transferTokens since the former requires that only the targetAddress
     *       can redeem transfers. Otherwise it's possible for another address to redeem the transfer before the targetContract is invoked by
     *       the offchain relayer and the target contract would have to be hardened against this.
     *
     */
    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress
    ) internal returns (VaaKey memory) {
        return
            transferTokens(
                token,
                amount,
                targetChain,
                targetAddress,
                bytes("")
            );
    }

    /**
     * transferTokens wraps common boilerplate for sending tokens to another chain using IWormholeRelayer.
     * A payload can be included in the transfer vaa. By including a payload here instead of the deliveryVaa,
     * fewer trust assumptions are placed on the WormholeRelayer contract.
     *
     * - approves tokenBridge to spend 'amount' of 'token'
     * - emits token transfer VAA
     * - returns VAA key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this function uses transferTokensWithPayload instead of transferTokens since the former requires that only the targetAddress
     *       can redeem transfers. Otherwise it's possible for another address to redeem the transfer before the targetContract is invoked by
     *       the offchain relayer and the target contract would have to be hardened against this.
     */
    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress,
        bytes memory payload
    ) internal returns (VaaKey memory) {
        IERC20(token).approve(address(tokenBridge), amount);
        uint64 sequence = tokenBridge.transferTokensWithPayload{
            value: wormhole.messageFee()
        }(
            token,
            amount,
            targetChain,
            toWormholeFormat(targetAddress),
            0,
            payload
        );
        return
            VaaKey({
                emitterAddress: toWormholeFormat(address(tokenBridge)),
                chainId: wormhole.chainId(),
                sequence: sequence
            });
    }

    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        address token,
        uint256 amount
    ) internal returns (uint64) {
        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = transferTokens(token, amount, targetChain, targetAddress);

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );
        return
            wormholeRelayer.sendVaasToEvm{value: cost}(
                targetChain,
                targetAddress,
                payload,
                receiverValue,
                gasLimit,
                vaaKeys
            );
    }

    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        address token,
        uint256 amount,
        uint16 refundChain,
        address refundAddress
    ) internal returns (uint64) {
        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = transferTokens(token, amount, targetChain, targetAddress);

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );
        return
            wormholeRelayer.sendVaasToEvm{value: cost}(
                targetChain,
                targetAddress,
                payload,
                receiverValue,
                gasLimit,
                vaaKeys,
                refundChain,
                refundAddress
            );
    }
}

abstract contract TokenReceiver is TokenBase {
    struct TokenReceived {
        bytes32 tokenHomeAddress;
        uint16 tokenHomeChain;
        address tokenAddress; // wrapped address if tokenHomeChain !== this chain, else tokenHomeAddress (in evm address format)
        uint256 amount;
        uint256 amountNormalized; // if decimals > 8, normalized to 8 decimal places
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable {
        TokenReceived[] memory receivedTokens = new TokenReceived[](
            additionalVaas.length
        );

        for (uint256 i = 0; i < additionalVaas.length; ++i) {
            IWormhole.VM memory parsed = wormhole.parseVM(additionalVaas[i]);
            require(
                parsed.emitterAddress ==
                    tokenBridge.bridgeContracts(parsed.emitterChainId),
                "Not a Token Bridge VAA"
            );
            IWormholeTokenBridge.TransferWithPayload
                memory transfer = tokenBridge.parseTransferWithPayload(
                    parsed.payload
                );
            require(
                transfer.to == toWormholeFormat(address(this)) &&
                    transfer.toChain == wormhole.chainId(),
                "Token was not sent to this address"
            );

            tokenBridge.completeTransferWithPayload(additionalVaas[i]);

            address thisChainTokenAddress = getTokenAddressOnThisChain(
                transfer.tokenChain,
                transfer.tokenAddress
            );
            uint8 decimals = getDecimals(thisChainTokenAddress);
            uint256 denormalizedAmount = transfer.amount;
            if (decimals > 8)
                denormalizedAmount *= uint256(10) ** (decimals - 8);

            receivedTokens[i] = TokenReceived({
                tokenHomeAddress: transfer.tokenAddress,
                tokenHomeChain: transfer.tokenChain,
                tokenAddress: thisChainTokenAddress,
                amount: denormalizedAmount,
                amountNormalized: transfer.amount
            });
        }

        // call into overriden method
        receivePayloadAndTokens(
            payload,
            receivedTokens,
            sourceAddress,
            sourceChain,
            deliveryHash
        );
    }

    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal virtual {}
}

pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ICallDataExecutor {
    function execute(
        IERC20 token,
        address addr,
        address approveAddress,
        address contractOutputsToken,
        address recipient,
        uint256 amount,
        uint256 gasLimit,
        bytes memory payload
    ) external payable;

    function sendNativeAndExecute(
        IERC20 token,
        address callTo,
        address approveAddress,
        address contractOutputsToken,
        address recipient,
        uint256 amount,
        uint256 gasLimit,
        bytes memory payload
    ) external payable;

    function sendAndExecute(
        IERC20 token,
        address callTo,
        address approveAddress,
        address contractOutputsToken,
        address recipient,
        uint256 amount,
        uint256 gasLimit,
        bytes memory payload
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IFeeCollector {
    function collectTokenFees(
        address tokenAddress,
        uint256 partnerFee,
        uint256 swingFee,
        address partnerAddress
    ) payable external;
    function getPartnerSwingCut(address partnerAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/DataTypes.sol";

interface ISwapRouter {
    struct SwapRequest {
        IERC20 srcToken; // Source token address
        IERC20 dstToken; // Destination token address
        uint256 amountIn; // Source token amount to swap
        uint256 amountMinSpend; // Minimum token amount to be swapped by aggregator.
        //If this is lower than amountIn, it will skip dex aggregator swap.
        uint256 amountOutMin; // Minimum output amount in desitnation token.
        bool useParaswap; // Flag to use paraswap or not.
        bytes paraswapData; // Paraswap calldata
        DataTypes.SplitSwapInfo[] splitSwapData; // Split swap data array for using several dex aggregators
        uint256[] distribution; // internal swap params at uni v2 like amms.
        bool raiseError; // true to revert, false to continue without reverting.
    }

    /**
     * Swap source token to destination token by dex aggreagors and internal swap.
     * Sometimes, we couldn't swap all src token amount. This happens when dex aggreagator
     * payload amount is lower than amountIn.
     * @param swapRequest SwapRequest struct param
     * @return unspent unswapped source token amount
     * @return returnAmount received destination token amount
     */
    function swap(SwapRequest memory swapRequest)
        external
        payable
        returns (uint256 unspent, uint256 returnAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/DataTypes.sol";

interface ISwitchEvent {
    function emitSwapped(
        address from,
        address recipient,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 fromAmount,
        uint256 destAmount,
        uint256 reward
    ) external;

    function emitParaswapSwapped(
        address from,
        IERC20 fromToken,
        uint256 fromAmount
    ) external;

    function emitCrosschainSwapRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address fromToken, // source token on sending chain
        address bridgeToken, // bridge token on sending chain
        address destToken, // dest token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 bridgeAmount, // swapped amount on sending chain
        uint256 dstAmount, // estimated amount of dest token on receiving chain
        DataTypes.SwapStatus status
    ) external;

    function emitCrosschainContractCallRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address fromToken, // source token on sending chain
        address callToken, // contract call token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 estimatedCallAmount, // estimated amount of contract call token on receiving chain
        DataTypes.ContractCallStatus status
    ) external;

    function emitCrosschainSwapDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address bridgeToken, // source token on receiving chain
        address destToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 destAmount, //dest token amount on receiving chain
        DataTypes.SwapStatus status
    ) external;

    function emitCrosschainContractCallDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address bridgeToken, // source token on receiving chain
        address callToken, // call token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 estimatedCallAmount, //dest token amount on receiving chain
        DataTypes.ContractCallStatus status
    ) external;

    function emitSingleChainContractCallDone(
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address fromToken, // source token on receiving chain
        address callToken, // call token on receiving chain
        uint256 fromAmount, // from token amount on receiving chain
        uint256 callAmount, //dest token amount on receiving chain
        DataTypes.ContractCallStatus status
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IUniswapExchange {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapExchange.sol";

interface IUniswapFactory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapExchange pair);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
/**
 * @title DataTypes
 * @dev Definition of shared types
 */
library DataTypes {
    /// @notice Type for representing a swapping status type
    enum SwapStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    enum ContractCallStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    /// @notice Type for representing a paraswap usage status
    enum ParaswapUsageStatus {
        None,
        OnSrcChain,
        OnDestChain,
        Both
    }

    /// @notice Split Swap params
    struct SplitSwapInfo {
        uint256 amount;
        address swapContract;
        address spender;
        bytes swapData;
    }

    /// @notice Swap params
    struct SwapInfo {
        address srcToken;
        address dstToken;
    }

    struct ContractCallInfo {
        address toContractAddress; // The address of the contract to interact with.
        address toApprovalAddress; // the approval address for contract call
        address contractOutputsToken; // Some contract interactions will output a token (e.g. staking)
        uint32 toContractGasLimit; // The estimated gas used by the destination call.
        bytes toContractCallData; // The callData to be sent to the contract for the interaction on the destination chain.
    }

    struct ContractCallRequest {
        bytes32 id;
        bytes32 bridge;
        address srcToken;
        address bridgeToken;
        address callToken;
        address recipient;
        uint256 srcAmount;
        uint256 bridgeDstAmount;
        uint256 estimatedCallAmount;
        uint256[] dstDistribution;
        bytes dstParaswapData;
        ContractCallInfo callInfo;
        ParaswapUsageStatus paraswapUsageStatus;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

library DisableFlags {
    function check(
        uint256 flags,
        uint256 flag
    )
        internal
        pure
        returns (bool)
    {
        return (flags & flag) != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../interfaces/IUniswapExchange.sol";
import "./Math.sol";
import "./UniversalERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library UniswapExchangeLib {
    using Math for uint256;
    using UniversalERC20 for IERC20;

    function getReturn(
        IUniswapExchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint amountIn
    )
        internal
        view
        returns (uint256 result, bool needSync, bool needSkim)
    {
        uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
        uint256 reserveOut = destToken.universalBalanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1,) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);
        needSkim = !needSync && (reserveIn > reserve0 || reserveOut > reserve1);

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * Math.min(reserveOut, reserve1);
        uint256 denominator = Math.min(reserveIn, reserve0) * 1000 + amountInWithFee;
        result = (denominator == 0) ? 0 : numerator / denominator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniversalERC20 {

    using SafeERC20 for IERC20;

    address private constant ZERO_ADDRESS = address(0x0000000000000000000000000000000000000000);
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    )
        internal
        returns (bool)
    {
        if (amount == 0) {
            return true;
        }
        if (isETH(token)) {
            payable(to).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                payable(to).transfer(amount);
            }
            // commented following lines for passing celer fee properly.
//            if (msg.value > amount) {
//                payable(msg.sender).transfer(msg.value - amount);
//            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(
        IERC20 token,
        uint256 amount
    )
        internal
    {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                payable(msg.sender).transfer(msg.value - amount);
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    )
        internal
    {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 approvedAmount = token.allowance(address(this), to);
            if (approvedAmount > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    // function notExist(IERC20 token) internal pure returns(bool) {
    //     return (address(token) == address(-1));
    // }
}