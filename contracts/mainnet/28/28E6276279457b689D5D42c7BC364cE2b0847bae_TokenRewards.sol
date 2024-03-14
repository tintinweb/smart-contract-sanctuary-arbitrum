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
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#swap
/// @notice Any contract that calls IAlgebraPoolActions#swap must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraSwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
  /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
  /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
  /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
  /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
  function algebraSwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDecentralizedIndex is IERC20 {
  enum IndexType {
    WEIGHTED,
    UNWEIGHTED
  }

  struct Config {
    address partner;
    bool hasTransferTax;
    bool blacklistTKNpTKNPoolV2;
  }

  // all fees: 1 == 0.01%, 10 == 0.1%, 100 == 1%
  struct Fees {
    uint16 burn;
    uint16 bond;
    uint16 debond;
    uint16 buy;
    uint16 sell;
    uint16 partner;
  }

  struct IndexAssetInfo {
    address token;
    uint256 weighting;
    uint256 basePriceUSDX96;
    address c1; // arbitrary contract/address field we can use for an index
    uint256 q1; // arbitrary quantity/number field we can use for an index
  }

  event Create(address indexed newIdx, address indexed wallet);
  event Initialize(address indexed wallet, address v2Pool);
  event Bond(
    address indexed wallet,
    address indexed token,
    uint256 amountTokensBonded,
    uint256 amountTokensMinted
  );
  event Debond(address indexed wallet, uint256 amountDebonded);
  event AddLiquidity(
    address indexed wallet,
    uint256 amountTokens,
    uint256 amountDAI
  );
  event RemoveLiquidity(address indexed wallet, uint256 amountLiquidity);
  event SetPartner(address indexed wallet, address newPartner);
  event SetPartnerFee(address indexed wallet, uint16 newFee);

  function BOND_FEE() external view returns (uint16);

  function DEBOND_FEE() external view returns (uint16);

  function FLASH_FEE_AMOUNT_DAI() external view returns (uint256);

  function PAIRED_LP_TOKEN() external view returns (address);

  function indexType() external view returns (IndexType);

  function created() external view returns (uint256);

  function lpStakingPool() external view returns (address);

  function lpRewardsToken() external view returns (address);

  function partner() external view returns (address);

  function getIdxPriceUSDX96() external view returns (uint256, uint256);

  function isAsset(address token) external view returns (bool);

  function getAllAssets() external view returns (IndexAssetInfo[] memory);

  function getInitialAmount(
    address sToken,
    uint256 sAmount,
    address tToken
  ) external view returns (uint256);

  function getTokenPriceUSDX96(address token) external view returns (uint256);

  function processPreSwapFeesAndSwap() external;

  function bond(address token, uint256 amount, uint256 amountMintMin) external;

  function debond(
    uint256 amount,
    address[] memory token,
    uint8[] memory percentage
  ) external;

  function addLiquidityV2(
    uint256 idxTokens,
    uint256 daiTokens,
    uint256 slippage,
    uint256 deadline
  ) external;

  function removeLiquidityV2(
    uint256 lpTokens,
    uint256 minTokens,
    uint256 minDAI,
    uint256 deadline
  ) external;

  function flash(
    address recipient,
    address token,
    uint256 amount,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPEAS is IERC20 {
  event Burn(address indexed user, uint256 amount);

  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './IProtocolFees.sol';

interface IProtocolFeeRouter {
  function protocolFees() external view returns (IProtocolFees);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IProtocolFees {
  event SetYieldAdmin(uint256 newFee);
  event SetYieldBurn(uint256 newFee);

  function DEN() external view returns (uint256);

  function yieldAdmin() external view returns (uint256);

  function yieldBurn() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRewardsWhitelister {
  function whitelist(address token) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IAlgebraSwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface ISwapRouterAlgebra is IAlgebraSwapCallback {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 limitSqrtPrice;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInputSingle(
    ExactInputSingleParams calldata params
  ) external payable returns (uint256 amountOut);

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
  function exactInput(
    ExactInputParams calldata params
  ) external payable returns (uint256 amountOut);

  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 limitSqrtPrice;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another token
  /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutputSingle(
    ExactOutputSingleParams calldata params
  ) external payable returns (uint256 amountIn);

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
  function exactOutput(
    ExactOutputParams calldata params
  ) external payable returns (uint256 amountIn);

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
  /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInputSingleSupportingFeeOnTransferTokens(
    ExactInputSingleParams calldata params
  ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITokenRewards {
  event AddShares(address indexed wallet, uint256 amount);

  event RemoveShares(address indexed wallet, uint256 amount);

  event ClaimReward(address indexed wallet);

  event DistributeReward(
    address indexed wallet,
    address indexed token,
    uint256 amount
  );

  event DepositRewards(
    address indexed wallet,
    address indexed token,
    uint256 amount
  );

  function totalShares() external view returns (uint256);

  function totalStakers() external view returns (uint256);

  function rewardsToken() external view returns (address);

  function trackingToken() external view returns (address);

  function depositFromPairedLpToken(
    uint256 amount,
    uint256 slippageOverride
  ) external;

  function depositRewards(address token, uint256 amount) external;

  function claimReward(address wallet) external;

  function setShares(
    address wallet,
    uint256 amount,
    bool sharesRemoving
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IV3TwapUtilities {
  function getV3Pool(
    address v3Factory,
    address token0,
    address token1
  ) external view returns (address);

  function getV3Pool(
    address v3Factory,
    address token0,
    address token1,
    uint24 poolFee
  ) external view returns (address);

  function getPoolPriceUSDX96(
    address pricePool,
    address nativeStablePool,
    address WETH9
  ) external view returns (uint256);

  function sqrtPriceX96FromPoolAndInterval(
    address pool
  ) external view returns (uint160);

  function priceX96FromSqrtPriceX96(
    uint160 sqrtPriceX96
  ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
  uint constant SECONDS_PER_DAY = 24 * 60 * 60;
  int constant OFFSET19700101 = 2440588;

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(
    uint _days
  ) internal pure returns (uint year, uint month, uint day) {
    int __days = int(_days);

    int L = __days + 68569 + OFFSET19700101;
    int N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int _month = (80 * L) / 2447;
    int _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint(_year);
    month = uint(_month);
    day = uint(_day);
  }

  function timestampToDate(
    uint timestamp
  ) internal pure returns (uint year, uint month, uint day) {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';
import './interfaces/IDecentralizedIndex.sol';
import './interfaces/IPEAS.sol';
import './interfaces/IRewardsWhitelister.sol';
import './interfaces/IProtocolFees.sol';
import './interfaces/IProtocolFeeRouter.sol';
import './interfaces/ISwapRouterAlgebra.sol';
import './interfaces/ITokenRewards.sol';
import './interfaces/IV3TwapUtilities.sol';
import './libraries/BokkyPooBahsDateTimeLibrary.sol';

contract TokenRewards is ITokenRewards, Context {
  using SafeERC20 for IERC20;

  uint256 constant PRECISION = 10 ** 36;
  uint24 constant REWARDS_POOL_FEE = 10000; // 1%
  address immutable V3_ROUTER;
  address immutable INDEX_FUND;
  address immutable PAIRED_LP_TOKEN;
  IProtocolFeeRouter immutable PROTOCOL_FEE_ROUTER;
  IRewardsWhitelister immutable REWARDS_WHITELISTER;
  IV3TwapUtilities immutable V3_TWAP_UTILS;

  struct Reward {
    uint256 excluded;
    uint256 realized;
  }

  address public immutable override trackingToken;
  address public immutable override rewardsToken; // main rewards token
  uint256 public override totalShares;
  uint256 public override totalStakers;
  mapping(address => uint256) public shares;
  // reward token => user => Reward
  mapping(address => mapping(address => Reward)) public rewards;

  uint256 _rewardsSwapSlippage = 20; // 2%
  // reward token => amount
  mapping(address => uint256) _rewardsPerShare;
  // reward token => amount
  mapping(address => uint256) public rewardsDistributed;
  // reward token => amount
  mapping(address => uint256) public rewardsDeposited;
  // reward token => month => amount
  mapping(address => mapping(uint256 => uint256)) public rewardsDepMonthly;
  // all deposited rewards tokens
  address[] _allRewardsTokens;
  mapping(address => bool) _depositedRewardsToken;

  constructor(
    IProtocolFeeRouter _feeRouter,
    IRewardsWhitelister _rewardsWhitelist,
    IV3TwapUtilities _v3TwapUtilities,
    address _v3Router,
    address _indexFund,
    address _pairedLpToken,
    address _trackingToken,
    address _rewardsToken
  ) {
    PROTOCOL_FEE_ROUTER = _feeRouter;
    REWARDS_WHITELISTER = _rewardsWhitelist;
    V3_TWAP_UTILS = _v3TwapUtilities;
    V3_ROUTER = _v3Router;
    INDEX_FUND = _indexFund;
    PAIRED_LP_TOKEN = _pairedLpToken;
    trackingToken = _trackingToken;
    rewardsToken = _rewardsToken;
  }

  function setShares(
    address _wallet,
    uint256 _amount,
    bool _sharesRemoving
  ) external override {
    require(_msgSender() == trackingToken, 'UNAUTHORIZED');
    _setShares(_wallet, _amount, _sharesRemoving);
  }

  function _setShares(
    address _wallet,
    uint256 _amount,
    bool _sharesRemoving
  ) internal {
    _processFeesIfApplicable();
    if (_sharesRemoving) {
      _removeShares(_wallet, _amount);
      emit RemoveShares(_wallet, _amount);
    } else {
      _addShares(_wallet, _amount);
      emit AddShares(_wallet, _amount);
    }
  }

  function _addShares(address _wallet, uint256 _amount) internal {
    if (shares[_wallet] > 0) {
      _distributeReward(_wallet);
    }
    uint256 sharesBefore = shares[_wallet];
    totalShares += _amount;
    shares[_wallet] += _amount;
    if (sharesBefore == 0 && shares[_wallet] > 0) {
      totalStakers++;
    }
  }

  function _removeShares(address _wallet, uint256 _amount) internal {
    require(shares[_wallet] > 0 && _amount <= shares[_wallet], 'REMOVE');
    _distributeReward(_wallet);
    totalShares -= _amount;
    shares[_wallet] -= _amount;
    if (shares[_wallet] == 0) {
      totalStakers--;
    }
  }

  function _processFeesIfApplicable() internal {
    IDecentralizedIndex(INDEX_FUND).processPreSwapFeesAndSwap();
  }

  function depositFromPairedLpToken(
    uint256 _amountTknDepositing,
    uint256 _slippageOverride
  ) public override {
    require(PAIRED_LP_TOKEN != rewardsToken, 'R');
    require(_slippageOverride <= 200, 'MS'); // 20%
    if (_amountTknDepositing > 0) {
      IERC20(PAIRED_LP_TOKEN).safeTransferFrom(
        _msgSender(),
        address(this),
        _amountTknDepositing
      );
    }
    uint256 _amountTkn = IERC20(PAIRED_LP_TOKEN).balanceOf(address(this));
    require(_amountTkn > 0, 'A');
    uint256 _adminAmt;
    (uint256 _yieldAdminFee, ) = _getYieldFees();
    if (_yieldAdminFee > 0) {
      _adminAmt =
        (_amountTkn * _yieldAdminFee) /
        PROTOCOL_FEE_ROUTER.protocolFees().DEN();
      _amountTkn -= _adminAmt;
    }
    (address _token0, address _token1) = PAIRED_LP_TOKEN < rewardsToken
      ? (PAIRED_LP_TOKEN, rewardsToken)
      : (rewardsToken, PAIRED_LP_TOKEN);
    address _pool;
    if (block.chainid == 42161) {
      _pool = V3_TWAP_UTILS.getV3Pool(
        IPeripheryImmutableState(V3_ROUTER).factory(),
        _token0,
        _token1
      );
    } else {
      _pool = V3_TWAP_UTILS.getV3Pool(
        IPeripheryImmutableState(V3_ROUTER).factory(),
        _token0,
        _token1,
        REWARDS_POOL_FEE
      );
    }
    uint160 _rewardsSqrtPriceX96 = V3_TWAP_UTILS
      .sqrtPriceX96FromPoolAndInterval(_pool);
    uint256 _rewardsPriceX96 = V3_TWAP_UTILS.priceX96FromSqrtPriceX96(
      _rewardsSqrtPriceX96
    );
    uint256 _amountOut = _token0 == PAIRED_LP_TOKEN
      ? (_rewardsPriceX96 * _amountTkn) / FixedPoint96.Q96
      : (_amountTkn * FixedPoint96.Q96) / _rewardsPriceX96;

    IERC20(PAIRED_LP_TOKEN).safeIncreaseAllowance(V3_ROUTER, _amountTkn);
    uint256 _slippage = _slippageOverride > 0
      ? _slippageOverride
      : _rewardsSwapSlippage;
    _swapForRewards(
      _amountTkn,
      _amountOut,
      _slippage,
      _slippageOverride > 0,
      _adminAmt
    );
  }

  function depositRewards(address _token, uint256 _amount) external override {
    require(_amount > 0, 'A');
    require(_isValidRewardsToken(_token), 'V');
    if (!_depositedRewardsToken[_token]) {
      _depositedRewardsToken[_token] = true;
      _allRewardsTokens.push(_token);
    }
    uint256 _rewardsBalBefore = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
    _depositRewards(
      _token,
      IERC20(_token).balanceOf(address(this)) - _rewardsBalBefore
    );
  }

  function _depositRewards(address _token, uint256 _amountTotal) internal {
    if (_amountTotal == 0) {
      return;
    }
    if (totalShares == 0) {
      require(_token == rewardsToken, 'R');
      _burnRewards(_amountTotal);
      return;
    }

    uint256 _depositAmount = _amountTotal;
    if (_token == rewardsToken) {
      (, uint256 _yieldBurnFee) = _getYieldFees();
      if (_yieldBurnFee > 0) {
        uint256 _burnAmount = (_amountTotal * _yieldBurnFee) /
          PROTOCOL_FEE_ROUTER.protocolFees().DEN();
        if (_burnAmount > 0) {
          _burnRewards(_burnAmount);
          _depositAmount -= _burnAmount;
        }
      }
    }
    rewardsDeposited[_token] += _depositAmount;
    rewardsDepMonthly[_token][
      beginningOfMonth(block.timestamp)
    ] += _depositAmount;
    _rewardsPerShare[_token] += (PRECISION * _depositAmount) / totalShares;
    emit DepositRewards(_msgSender(), _token, _depositAmount);
  }

  function _distributeReward(address _wallet) internal {
    if (shares[_wallet] == 0) {
      return;
    }
    for (uint256 _i; _i < _allRewardsTokens.length; _i++) {
      address _token = _allRewardsTokens[_i];
      uint256 _amount = getUnpaid(_token, _wallet);
      rewards[_token][_wallet].realized += _amount;
      rewards[_token][_wallet].excluded = _cumulativeRewards(
        _token,
        shares[_wallet]
      );
      if (_amount > 0) {
        rewardsDistributed[_token] += _amount;
        IERC20(_token).safeTransfer(_wallet, _amount);
        emit DistributeReward(_wallet, _token, _amount);
      }
    }
  }

  function _burnRewards(uint256 _burnAmount) internal {
    try IPEAS(rewardsToken).burn(_burnAmount) {} catch {
      IERC20(rewardsToken).safeTransfer(address(0xdead), _burnAmount);
    }
  }

  function _isValidRewardsToken(address _token) internal view returns (bool) {
    return _token == rewardsToken || REWARDS_WHITELISTER.whitelist(_token);
  }

  function _getYieldFees()
    internal
    view
    returns (uint256 _admin, uint256 _burn)
  {
    IProtocolFees _fees = PROTOCOL_FEE_ROUTER.protocolFees();
    if (address(_fees) != address(0)) {
      _admin = _fees.yieldAdmin();
      _burn = _fees.yieldBurn();
    }
  }

  function _swapForRewards(
    uint256 _amountIn,
    uint256 _amountOut,
    uint256 _slippage,
    bool _isSlipOverride,
    uint256 _adminAmt
  ) internal {
    uint256 _rewardsBalBefore = IERC20(rewardsToken).balanceOf(address(this));
    if (block.chainid == 42161) {
      try
        ISwapRouterAlgebra(V3_ROUTER).exactInputSingle(
          ISwapRouterAlgebra.ExactInputSingleParams({
            tokenIn: PAIRED_LP_TOKEN,
            tokenOut: rewardsToken,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: (_amountOut * (1000 - _slippage)) / 1000,
            limitSqrtPrice: 0
          })
        )
      {
        if (_adminAmt > 0) {
          IERC20(PAIRED_LP_TOKEN).safeTransfer(
            Ownable(address(V3_TWAP_UTILS)).owner(),
            _adminAmt
          );
        }
        _rewardsSwapSlippage = 20;
        _depositRewards(
          rewardsToken,
          IERC20(rewardsToken).balanceOf(address(this)) - _rewardsBalBefore
        );
      } catch {
        if (!_isSlipOverride && _rewardsSwapSlippage < 200) {
          _rewardsSwapSlippage += 10;
        }
        IERC20(PAIRED_LP_TOKEN).safeDecreaseAllowance(V3_ROUTER, _amountIn);
      }
    } else {
      try
        ISwapRouter(V3_ROUTER).exactInputSingle(
          ISwapRouter.ExactInputSingleParams({
            tokenIn: PAIRED_LP_TOKEN,
            tokenOut: rewardsToken,
            fee: REWARDS_POOL_FEE,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: (_amountOut * (1000 - _slippage)) / 1000,
            sqrtPriceLimitX96: 0
          })
        )
      {
        if (_adminAmt > 0) {
          IERC20(PAIRED_LP_TOKEN).safeTransfer(
            Ownable(address(V3_TWAP_UTILS)).owner(),
            _adminAmt
          );
        }
        _rewardsSwapSlippage = 10;
        _depositRewards(
          rewardsToken,
          IERC20(rewardsToken).balanceOf(address(this)) - _rewardsBalBefore
        );
      } catch {
        if (_rewardsSwapSlippage < 200) {
          _rewardsSwapSlippage += 10;
        }
        IERC20(PAIRED_LP_TOKEN).safeDecreaseAllowance(V3_ROUTER, _amountIn);
      }
    }
  }

  function beginningOfMonth(uint256 _timestamp) public pure returns (uint256) {
    (, , uint256 _dayOfMonth) = BokkyPooBahsDateTimeLibrary.timestampToDate(
      _timestamp
    );
    return _timestamp - ((_dayOfMonth - 1) * 1 days) - (_timestamp % 1 days);
  }

  function claimReward(address _wallet) external override {
    _distributeReward(_wallet);
    emit ClaimReward(_wallet);
  }

  function getUnpaid(address _wallet) external view returns (uint256) {
    if (shares[_wallet] == 0) {
      return 0;
    }
    uint256 earnedRewards = _cumulativeRewards(rewardsToken, shares[_wallet]);
    uint256 rewardsExcluded = rewards[rewardsToken][_wallet].excluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }
    return earnedRewards - rewardsExcluded;
  }

  function getUnpaid(
    address _token,
    address _wallet
  ) public view returns (uint256) {
    if (shares[_wallet] == 0) {
      return 0;
    }
    uint256 earnedRewards = _cumulativeRewards(_token, shares[_wallet]);
    uint256 rewardsExcluded = rewards[_token][_wallet].excluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }
    return earnedRewards - rewardsExcluded;
  }

  function _cumulativeRewards(
    address _token,
    uint256 _share
  ) internal view returns (uint256) {
    return (_share * _rewardsPerShare[_token]) / PRECISION;
  }
}