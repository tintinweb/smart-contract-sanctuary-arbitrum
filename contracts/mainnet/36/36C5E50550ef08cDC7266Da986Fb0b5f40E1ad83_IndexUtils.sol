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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import './interfaces/IDecentralizedIndex.sol';
import './interfaces/IERC20Metadata.sol';
import './interfaces/IStakingPoolToken.sol';
import './interfaces/ITokenRewards.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV3Pool.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IWETH.sol';
import './Zapper.sol';

contract IndexUtils is Context, Zapper {
  using SafeERC20 for IERC20;

  constructor(
    address _v2Router,
    IV3TwapUtilities _v3TwapUtilities
  ) Zapper(_v2Router, _v3TwapUtilities) {}

  function bond(
    IDecentralizedIndex _indexFund,
    address _token,
    uint256 _amount,
    uint256 _amountMintMin
  ) external {
    IDecentralizedIndex.IndexAssetInfo[] memory _assets = _indexFund
      .getAllAssets();
    uint256[] memory _balsBefore = new uint256[](_assets.length);

    uint256 _tokenCurSupply = IERC20(_token).balanceOf(address(_indexFund));
    uint256 _tokenAmtSupplyRatioX96 = _indexFund.totalSupply() == 0
      ? FixedPoint96.Q96
      : (_amount * FixedPoint96.Q96) / _tokenCurSupply;
    uint256 _al = _assets.length;
    for (uint256 _i; _i < _al; _i++) {
      uint256 _amountNeeded = _indexFund.totalSupply() == 0
        ? _indexFund.getInitialAmount(_token, _amount, _assets[_i].token)
        : (IERC20(_assets[_i].token).balanceOf(address(_indexFund)) *
          _tokenAmtSupplyRatioX96) / FixedPoint96.Q96;
      _balsBefore[_i] = IERC20(_assets[_i].token).balanceOf(address(this));
      IERC20(_assets[_i].token).safeTransferFrom(
        _msgSender(),
        address(this),
        _amountNeeded
      );
      IERC20(_assets[_i].token).safeIncreaseAllowance(
        address(_indexFund),
        _amountNeeded
      );
    }
    uint256 _idxBalBefore = IERC20(_indexFund).balanceOf(address(this));
    _indexFund.bond(_token, _amount, _amountMintMin);
    IERC20(_indexFund).safeTransfer(
      _msgSender(),
      IERC20(_indexFund).balanceOf(address(this)) - _idxBalBefore
    );

    // refund any excess tokens to user we didn't use to bond
    for (uint256 _i; _i < _al; _i++) {
      _checkAndRefundERC20(_msgSender(), _assets[_i].token, _balsBefore[_i]);
    }
  }

  function bondWeightedFromNative(
    IDecentralizedIndex _indexFund,
    uint256 _assetIdx,
    uint256 _amountTokensForAssetIdx,
    uint256 _amountMintMin,
    uint256 _amountPairedLpTokenMin,
    uint256 _slippage, // 1 == 0.1%, 10 == 1%, 1000 == 100%
    uint256 _deadline,
    bool _stakeAsWell
  ) external payable {
    require(msg.value > 0, 'NATIVE');
    uint256 _ethBalBefore = address(this).balance - msg.value;
    IDecentralizedIndex.IndexAssetInfo[] memory _assets = _indexFund
      .getAllAssets();
    (
      uint256[] memory _balancesBefore,
      uint256[] memory _amountsReceived
    ) = _swapNativeForTokensWeightedV2(
        _indexFund,
        _stakeAsWell ? msg.value / 2 : msg.value,
        _assets,
        _assetIdx,
        _amountTokensForAssetIdx
      );

    // allowance for _assetIdx is increased in _bondToRecipient below,
    // we just need to increase allowance for any other index tokens here first
    for (uint256 _i; _i < _assets.length; _i++) {
      if (_i == _assetIdx) {
        continue;
      }
      IERC20(_assets[_i].token).safeIncreaseAllowance(
        address(_indexFund),
        _amountsReceived[_i]
      );
    }
    uint256 _idxTokensGained = _bondToRecipient(
      _indexFund,
      _assets[_assetIdx].token,
      _amountsReceived[_assetIdx],
      _amountMintMin,
      _stakeAsWell ? address(this) : _msgSender()
    );

    if (_stakeAsWell) {
      _zapIndexTokensAndNative(
        _msgSender(),
        _indexFund,
        _idxTokensGained,
        msg.value / 2,
        _amountPairedLpTokenMin,
        _slippage,
        _deadline
      );
    }

    // refund any excess tokens to user we didn't use to bond
    for (uint256 _i; _i < _assets.length; _i++) {
      _checkAndRefundERC20(
        _msgSender(),
        _assets[_i].token,
        _balancesBefore[_i]
      );
    }

    // refund excess ETH
    if (address(this).balance > _ethBalBefore) {
      (bool _s, ) = payable(_msgSender()).call{
        value: address(this).balance - _ethBalBefore
      }('');
      require(_s, 'ETHREFUND');
    }
  }

  function addLPAndStake(
    IDecentralizedIndex _indexFund,
    uint256 _amountIdxTokens,
    address _pairedLpTokenProvided,
    uint256 _amtPairedLpTokenProvided,
    uint256 _amountPairedLpTokenMin,
    uint256 _slippage,
    uint256 _deadline
  ) external payable {
    address _v2Pool = IUniswapV2Factory(V2_FACTORY).getPair(
      address(_indexFund),
      _indexFund.PAIRED_LP_TOKEN()
    );
    uint256 _idxTokensBefore = IERC20(address(_indexFund)).balanceOf(
      address(this)
    );
    uint256 _pairedLpTokenBefore = IERC20(_indexFund.PAIRED_LP_TOKEN())
      .balanceOf(address(this));
    uint256 _ethBefore = address(this).balance - msg.value;
    uint256 _v2PoolBefore = IERC20(_v2Pool).balanceOf(address(this));
    IERC20(address(_indexFund)).safeTransferFrom(
      _msgSender(),
      address(this),
      _amountIdxTokens
    );
    if (_pairedLpTokenProvided == address(0)) {
      require(msg.value > 0, 'NEEDETH');
      _amtPairedLpTokenProvided = msg.value;
    } else {
      IERC20(_pairedLpTokenProvided).safeTransferFrom(
        _msgSender(),
        address(this),
        _amtPairedLpTokenProvided
      );
    }
    if (_pairedLpTokenProvided != _indexFund.PAIRED_LP_TOKEN()) {
      _zap(
        _pairedLpTokenProvided,
        _indexFund.PAIRED_LP_TOKEN(),
        _amtPairedLpTokenProvided,
        _amountPairedLpTokenMin
      );
    }

    IERC20(_indexFund.PAIRED_LP_TOKEN()).safeIncreaseAllowance(
      address(_indexFund),
      IERC20(_indexFund.PAIRED_LP_TOKEN()).balanceOf(address(this)) -
        _pairedLpTokenBefore
    );
    _indexFund.addLiquidityV2(
      IERC20(address(_indexFund)).balanceOf(address(this)) - _idxTokensBefore,
      IERC20(_indexFund.PAIRED_LP_TOKEN()).balanceOf(address(this)) -
        _pairedLpTokenBefore,
      _slippage,
      _deadline
    );

    IERC20(_v2Pool).safeIncreaseAllowance(
      _indexFund.lpStakingPool(),
      IERC20(_v2Pool).balanceOf(address(this)) - _v2PoolBefore
    );
    IStakingPoolToken(_indexFund.lpStakingPool()).stake(
      _msgSender(),
      IERC20(_v2Pool).balanceOf(address(this)) - _v2PoolBefore
    );

    // refunds if needed for index tokens and pairedLpToken
    if (address(this).balance > _ethBefore) {
      (bool _s, ) = payable(_msgSender()).call{
        value: address(this).balance - _ethBefore
      }('');
      require(_s && address(this).balance >= _ethBefore, 'TOOMUCH');
    }
    _checkAndRefundERC20(_msgSender(), address(_indexFund), _idxTokensBefore);
    _checkAndRefundERC20(
      _msgSender(),
      _indexFund.PAIRED_LP_TOKEN(),
      _pairedLpTokenBefore
    );
  }

  function unstakeAndRemoveLP(
    IDecentralizedIndex _indexFund,
    uint256 _amountStakedTokens,
    uint256 _minLPTokens,
    uint256 _minPairedLpToken,
    uint256 _deadline
  ) external {
    address _stakingPool = _indexFund.lpStakingPool();
    address _pairedLpToken = _indexFund.PAIRED_LP_TOKEN();
    uint256 _stakingBalBefore = IERC20(_stakingPool).balanceOf(address(this));
    uint256 _pairedLpTokenBefore = IERC20(_pairedLpToken).balanceOf(
      address(this)
    );
    IERC20(_stakingPool).safeTransferFrom(
      _msgSender(),
      address(this),
      _amountStakedTokens
    );
    uint256 _indexBalBefore = _unstakeAndRemoveLP(
      _indexFund,
      _stakingPool,
      IERC20(_stakingPool).balanceOf(address(this)) - _stakingBalBefore,
      _minLPTokens,
      _minPairedLpToken,
      _deadline
    );
    if (
      IERC20(address(_indexFund)).balanceOf(address(this)) > _indexBalBefore
    ) {
      IERC20(address(_indexFund)).safeTransfer(
        _msgSender(),
        IERC20(address(_indexFund)).balanceOf(address(this)) - _indexBalBefore
      );
    }
    if (
      IERC20(_pairedLpToken).balanceOf(address(this)) > _pairedLpTokenBefore
    ) {
      IERC20(_pairedLpToken).safeTransfer(
        _msgSender(),
        IERC20(_pairedLpToken).balanceOf(address(this)) - _pairedLpTokenBefore
      );
    }
  }

  function claimRewardsMulti(address[] memory _rewards) external {
    uint256 _rl = _rewards.length;
    for (uint256 _i; _i < _rl; _i++) {
      ITokenRewards(_rewards[_i]).claimReward(_msgSender());
    }
  }

  function _swapNativeForTokensWeightedV2(
    IDecentralizedIndex _indexFund,
    uint256 _amountNative,
    IDecentralizedIndex.IndexAssetInfo[] memory _assets,
    uint256 _poolIdx,
    uint256 _amountForPoolIdx
  ) internal returns (uint256[] memory, uint256[] memory) {
    uint256[] memory _amountBefore = new uint256[](_assets.length);
    uint256[] memory _amountReceived = new uint256[](_assets.length);
    uint256 _tokenCurSupply = IERC20(_assets[_poolIdx].token).balanceOf(
      address(_indexFund)
    );
    uint256 _tokenAmtSupplyRatioX96 = _indexFund.totalSupply() == 0
      ? FixedPoint96.Q96
      : (_amountForPoolIdx * FixedPoint96.Q96) / _tokenCurSupply;
    uint256 _nativeLeft = _amountNative;
    uint256 _al = _assets.length;
    for (uint256 _i; _i < _al; _i++) {
      (_nativeLeft, _amountBefore[_i], _amountReceived[_i]) = _swapForIdxToken(
        _indexFund,
        _assets[_poolIdx].token,
        _amountForPoolIdx,
        _assets[_i].token,
        _tokenAmtSupplyRatioX96,
        _nativeLeft
      );
    }
    return (_amountBefore, _amountReceived);
  }

  function _swapForIdxToken(
    IDecentralizedIndex _indexFund,
    address _initToken,
    uint256 _initTokenAmount,
    address _outToken,
    uint256 _tokenAmtSupplyRatioX96,
    uint256 _nativeLeft
  )
    internal
    returns (
      uint256 _newNativeLeft,
      uint256 _amountBefore,
      uint256 _amountReceived
    )
  {
    uint256 _nativeBefore = address(this).balance;
    _amountBefore = IERC20(_outToken).balanceOf(address(this));
    uint256 _amountOut = _indexFund.totalSupply() == 0
      ? _indexFund.getInitialAmount(_initToken, _initTokenAmount, _outToken)
      : (IERC20(_outToken).balanceOf(address(_indexFund)) *
        _tokenAmtSupplyRatioX96) / FixedPoint96.Q96;
    address[] memory _path = new address[](2);
    _path[0] = IUniswapV2Router02(V2_ROUTER).WETH();
    _path[1] = _outToken;
    IUniswapV2Router02(V2_ROUTER).swapETHForExactTokens{ value: _nativeLeft }(
      _amountOut,
      _path,
      address(this),
      block.timestamp
    );
    _newNativeLeft = _nativeLeft - (_nativeBefore - address(this).balance);
    _amountReceived =
      IERC20(_outToken).balanceOf(address(this)) -
      _amountBefore;
  }

  function _unstakeAndRemoveLP(
    IDecentralizedIndex _indexFund,
    address _stakingPool,
    uint256 _unstakeAmount,
    uint256 _minLPTokens,
    uint256 _minPairedLpTokens,
    uint256 _deadline
  ) internal returns (uint256 _fundTokensBefore) {
    address _pairedLpToken = _indexFund.PAIRED_LP_TOKEN();
    address _v2Pool = IUniswapV2Factory(V2_FACTORY).getPair(
      address(_indexFund),
      _pairedLpToken
    );
    uint256 _v2TokensBefore = IERC20(_v2Pool).balanceOf(address(this));
    IStakingPoolToken(_stakingPool).unstake(_unstakeAmount);

    _fundTokensBefore = _indexFund.balanceOf(address(this));
    IERC20(_v2Pool).safeIncreaseAllowance(
      address(_indexFund),
      IERC20(_v2Pool).balanceOf(address(this)) - _v2TokensBefore
    );
    _indexFund.removeLiquidityV2(
      IERC20(_v2Pool).balanceOf(address(this)) - _v2TokensBefore,
      _minLPTokens,
      _minPairedLpTokens,
      _deadline
    );
  }

  function _bondToRecipient(
    IDecentralizedIndex _indexFund,
    address _indexToken,
    uint256 _bondTokens,
    uint256 _amountMintMin,
    address _recipient
  ) internal returns (uint256) {
    uint256 _idxTokensBefore = IERC20(address(_indexFund)).balanceOf(
      address(this)
    );
    IERC20(_indexToken).safeIncreaseAllowance(address(_indexFund), _bondTokens);
    _indexFund.bond(_indexToken, _bondTokens, _amountMintMin);
    uint256 _idxTokensGained = IERC20(address(_indexFund)).balanceOf(
      address(this)
    ) - _idxTokensBefore;
    if (_recipient != address(this)) {
      IERC20(address(_indexFund)).safeTransfer(_recipient, _idxTokensGained);
    }
    return _idxTokensGained;
  }

  function _zapIndexTokensAndNative(
    address _user,
    IDecentralizedIndex _indexFund,
    uint256 _amountTokens,
    uint256 _amountETH,
    uint256 _amtPairedLpTokenMin,
    uint256 _slippage,
    uint256 _deadline
  ) internal {
    address _pairedLpToken = _indexFund.PAIRED_LP_TOKEN();
    uint256 _tokensBefore = IERC20(address(_indexFund)).balanceOf(
      address(this)
    ) - _amountTokens;
    uint256 _pairedLpTokenBefore = IERC20(_pairedLpToken).balanceOf(
      address(this)
    );
    address _stakingPool = _indexFund.lpStakingPool();

    _zap(address(0), _pairedLpToken, _amountETH, _amtPairedLpTokenMin);

    address _v2Pool = IUniswapV2Factory(V2_FACTORY).getPair(
      address(_indexFund),
      _pairedLpToken
    );
    uint256 _lpTokensBefore = IERC20(_v2Pool).balanceOf(address(this));
    IERC20(_pairedLpToken).safeIncreaseAllowance(
      address(_indexFund),
      IERC20(_pairedLpToken).balanceOf(address(this)) - _pairedLpTokenBefore
    );
    _indexFund.addLiquidityV2(
      _amountTokens,
      IERC20(_pairedLpToken).balanceOf(address(this)) - _pairedLpTokenBefore,
      _slippage,
      _deadline
    );
    IERC20(_v2Pool).safeIncreaseAllowance(
      _stakingPool,
      IERC20(_v2Pool).balanceOf(address(this)) - _lpTokensBefore
    );
    IStakingPoolToken(_stakingPool).stake(
      _user,
      IERC20(_v2Pool).balanceOf(address(this)) - _lpTokensBefore
    );

    // check & refund excess tokens from LPing as needed
    if (IERC20(address(_indexFund)).balanceOf(address(this)) > _tokensBefore) {
      IERC20(address(_indexFund)).safeTransfer(
        _user,
        IERC20(address(_indexFund)).balanceOf(address(this)) - _tokensBefore
      );
    }
    if (
      IERC20(_pairedLpToken).balanceOf(address(this)) > _pairedLpTokenBefore
    ) {
      IERC20(_pairedLpToken).safeTransfer(
        _user,
        IERC20(_pairedLpToken).balanceOf(address(this)) - _pairedLpTokenBefore
      );
    }
  }

  function _checkAndRefundERC20(
    address _user,
    address _asset,
    uint256 _beforeBal
  ) internal {
    uint256 _curBal = IERC20(_asset).balanceOf(address(this));
    if (_curBal > _beforeBal) {
      IERC20(_asset).safeTransfer(_user, _curBal - _beforeBal);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICurvePool {
  function coins(uint256 _idx) external returns (address);

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 minDy,
    address receiver
  ) external returns (uint256);
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

interface IERC20Metadata {
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC4626 {
  function deposit(
    uint256 assets,
    address receiver
  ) external returns (uint256 shares);

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external returns (uint256 shares);

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStakingPoolToken {
  event Stake(address indexed executor, address indexed user, uint256 amount);

  event Unstake(address indexed user, uint256 amount);

  function indexFund() external view returns (address);

  function stakingToken() external view returns (address);

  function poolRewards() external view returns (address);

  function stakeUserRestriction() external view returns (address);

  function stake(address user, uint256 amount) external;

  function unstake(uint256 amount) external;
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

interface IUniswapV2Factory {
  function createPair(
    address tokenA,
    address tokenB
  ) external returns (address pair);

  function getPair(
    address tokenA,
    address tokenB
  ) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniswapV2Router02 {
  function factory() external view returns (address);

  function WETH() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniswapV3Pool {
  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (address);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (address);

  /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
  /// @return The fee
  function fee() external view returns (uint24);

  /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
  /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
  /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
  /// you must call it with secondsAgos = [3600, 0].
  /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
  /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
  /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
  /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
  /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
  /// timestamp
  function observe(
    uint32[] calldata secondsAgos
  )
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulativeX128s
    );

  /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
  /// when accessed externally.
  /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
  /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
  /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
  /// boundary.
  /// observationIndex The index of the last oracle observation that was written,
  /// observationCardinality The current maximum number of observations stored in the pool,
  /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
  /// feeProtocol The protocol fee for both tokens of the pool.
  /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
  /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
  /// unlocked Whether the pool is currently locked to reentrancy
  function slot0()
    external
    view
    returns (
      uint160 sqrtPriceX96,
      int24 tick,
      uint16 observationIndex,
      uint16 observationCardinality,
      uint16 observationCardinalityNext,
      uint8 feeProtocol,
      bool unlocked
    );
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

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IZapper {
  enum PoolType {
    CURVE,
    V2,
    V3
  }

  struct Pools {
    PoolType poolType; // assume same for both pool1 and pool2
    address pool1;
    address pool2;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import './interfaces/ICurvePool.sol';
import './interfaces/IDecentralizedIndex.sol';
import './interfaces/IERC4626.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV3Pool.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IV3TwapUtilities.sol';
import './interfaces/IWETH.sol';
import './interfaces/IZapper.sol';

contract Zapper is IZapper, Context, Ownable {
  using SafeERC20 for IERC20;

  address constant OHM = 0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5;
  address constant STYETH = 0x583019fF0f430721aDa9cfb4fac8F06cA104d0B4;
  address constant YETH = 0x1BED97CBC3c24A4fb5C069C6E311a967386131f7;
  address constant WETH_YETH_POOL = 0x69ACcb968B19a53790f43e57558F5E443A91aF22;
  address constant V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address immutable V2_ROUTER;
  address immutable V2_FACTORY;
  address immutable WETH;
  IV3TwapUtilities immutable V3_TWAP_UTILS;

  uint256 _slippage = 30; // 3%

  address public pOHM;

  // token in => token out => swap pool(s)
  mapping(address => mapping(address => Pools)) public zapMap;
  // curve pool => token => idx
  mapping(address => mapping(address => int128)) public curveTokenIdx;

  constructor(address _v2Router, IV3TwapUtilities _v3TwapUtilities) {
    V2_ROUTER = _v2Router;
    V2_FACTORY = IUniswapV2Router02(_v2Router).factory();
    V3_TWAP_UTILS = _v3TwapUtilities;
    WETH = IUniswapV2Router02(_v2Router).WETH();

    if (block.chainid == 1) {
      // WETH/YETH
      _setZapMapFromPoolSingle(
        PoolType.CURVE,
        0x69ACcb968B19a53790f43e57558F5E443A91aF22
      );
      // WETH/DAI
      _setZapMapFromPoolSingle(
        PoolType.V3,
        0x60594a405d53811d3BC4766596EFD80fd545A270
      );
      // WETH/USDC
      _setZapMapFromPoolSingle(
        PoolType.V3,
        0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640
      );
      // WETH/OHM
      _setZapMapFromPoolSingle(
        PoolType.V3,
        0x88051B0eea095007D3bEf21aB287Be961f3d8598
      );
      // USDC/OHM
      _setZapMapFromPoolSingle(
        PoolType.V3,
        0x893f503FaC2Ee1e5B78665db23F9c94017Aae97D
      );
    }
  }

  function _zap(
    address _in,
    address _out,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) internal returns (uint256 _amountOut) {
    if (_in == address(0)) {
      _amountIn = _ethToWETH(_amountIn);
      _in = WETH;
    }
    // handle pOHM separately through pod, modularize later
    bool _isOutPOHM;
    if (pOHM == _out) {
      _isOutPOHM = true;
      _out = OHM;
    }
    // handle yETH and st-yETH special through curve pool, modularize later
    if (_out == YETH || _out == STYETH) {
      require(_in == WETH, 'YETHIN');
      return _wethToYeth(_amountIn, _amountOutMin, _out == STYETH);
    } else if (_in == YETH || _in == STYETH) {
      require(_out == WETH, 'YETHOUT');
      return _styethToWeth(_amountIn, _amountOutMin, _in == YETH);
    }
    Pools memory _poolInfo = zapMap[_in][_out];
    // no pool so just try to swap over one path univ2
    if (_poolInfo.pool1 == address(0)) {
      address[] memory _path = new address[](2);
      _path[0] = _in;
      _path[1] = _out;
      _amountOut = _swapV2(_path, _amountIn, _amountOutMin);
    } else {
      bool _twoHops = _poolInfo.pool2 != address(0);
      if (_poolInfo.poolType == PoolType.CURVE) {
        // curve
        _amountOut = _swapCurve(
          _poolInfo.pool1,
          curveTokenIdx[_poolInfo.pool1][_in],
          curveTokenIdx[_poolInfo.pool1][_out],
          _amountIn,
          _amountOutMin
        );
      } else if (_poolInfo.poolType == PoolType.V2) {
        // univ2
        address _token0 = IUniswapV2Pair(_poolInfo.pool1).token0();
        address[] memory _path = new address[](_twoHops ? 3 : 2);
        _path[0] = _in;
        _path[1] = !_twoHops ? _out : _token0 == _in
          ? IUniswapV2Pair(_poolInfo.pool1).token1()
          : _token0;
        if (_twoHops) {
          _path[2] = _out;
        }
        _amountOut = _swapV2(_path, _amountIn, _amountOutMin);
      } else {
        // univ3
        if (_twoHops) {
          address _t0 = IUniswapV3Pool(_poolInfo.pool1).token0();
          _amountOut = _swapV3Multi(
            _in,
            IUniswapV3Pool(_poolInfo.pool1).fee(),
            _t0 == _in ? IUniswapV3Pool(_poolInfo.pool1).token1() : _t0,
            IUniswapV3Pool(_poolInfo.pool2).fee(),
            _out,
            _amountIn,
            _amountOutMin
          );
        } else {
          _amountOut = _swapV3Single(
            _in,
            IUniswapV3Pool(_poolInfo.pool1).fee(),
            _out,
            _amountIn,
            _amountOutMin
          );
        }
      }
    }
    if (!_isOutPOHM) {
      return _amountOut;
    }
    uint256 _pOHMBefore = IERC20(pOHM).balanceOf(address(this));
    IERC20(OHM).safeIncreaseAllowance(pOHM, _amountOut);
    IDecentralizedIndex(pOHM).bond(OHM, _amountOut, 0);
    return IERC20(pOHM).balanceOf(address(this)) - _pOHMBefore;
  }

  function _ethToWETH(uint256 _amountETH) internal returns (uint256) {
    uint256 _wethBal = IERC20(WETH).balanceOf(address(this));
    IWETH(WETH).deposit{ value: _amountETH }();
    return IERC20(WETH).balanceOf(address(this)) - _wethBal;
  }

  function _swapV3Single(
    address _in,
    uint24 _fee,
    address _out,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) internal returns (uint256) {
    if (_amountOutMin == 0) {
      address _v3Pool;
      try
        V3_TWAP_UTILS.getV3Pool(
          IPeripheryImmutableState(V3_ROUTER).factory(),
          _in,
          _out,
          _fee
        )
      returns (address __v3Pool) {
        _v3Pool = __v3Pool;
      } catch {
        _v3Pool = V3_TWAP_UTILS.getV3Pool(
          IPeripheryImmutableState(V3_ROUTER).factory(),
          _in,
          _out
        );
      }
      address _token0 = _in < _out ? _in : _out;
      uint256 _poolPriceX96 = V3_TWAP_UTILS.priceX96FromSqrtPriceX96(
        V3_TWAP_UTILS.sqrtPriceX96FromPoolAndInterval(_v3Pool)
      );
      _amountOutMin = _in == _token0
        ? (_poolPriceX96 * _amountIn) / FixedPoint96.Q96
        : (_amountIn * FixedPoint96.Q96) / _poolPriceX96;
    }

    uint256 _outBefore = IERC20(_out).balanceOf(address(this));
    IERC20(_in).safeIncreaseAllowance(V3_ROUTER, _amountIn);
    ISwapRouter(V3_ROUTER).exactInputSingle(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: _in,
        tokenOut: _out,
        fee: _fee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amountIn,
        amountOutMinimum: (_amountOutMin * (1000 - _slippage)) / 1000,
        sqrtPriceLimitX96: 0
      })
    );
    return IERC20(_out).balanceOf(address(this)) - _outBefore;
  }

  function _swapV3Multi(
    address _in,
    uint24 _fee1,
    address _in2,
    uint24 _fee2,
    address _out,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) internal returns (uint256) {
    uint256 _outBefore = IERC20(_out).balanceOf(address(this));
    IERC20(_in).safeIncreaseAllowance(V3_ROUTER, _amountIn);
    bytes memory _path = abi.encodePacked(_in, _fee1, _in2, _fee2, _out);
    ISwapRouter(V3_ROUTER).exactInput(
      ISwapRouter.ExactInputParams({
        path: _path,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amountIn,
        amountOutMinimum: _amountOutMin
      })
    );
    return IERC20(_out).balanceOf(address(this)) - _outBefore;
  }

  function _swapV2(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) internal returns (uint256) {
    address _out = _path.length == 3 ? _path[2] : _path[1];
    uint256 _outBefore = IERC20(_out).balanceOf(address(this));
    IERC20(_path[0]).safeIncreaseAllowance(V2_ROUTER, _amountIn);
    IUniswapV2Router02(V2_ROUTER)
      .swapExactTokensForTokensSupportingFeeOnTransferTokens(
        _amountIn,
        _amountOutMin,
        _path,
        address(this),
        block.timestamp
      );
    return IERC20(_out).balanceOf(address(this)) - _outBefore;
  }

  function _swapCurve(
    address _pool,
    int128 _i,
    int128 _j,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) internal returns (uint256) {
    IERC20(ICurvePool(_pool).coins(uint128(_i))).safeIncreaseAllowance(
      _pool,
      _amountIn
    );
    return
      ICurvePool(_pool).exchange(
        _i,
        _j,
        _amountIn,
        _amountOutMin,
        address(this)
      );
  }

  function _wethToYeth(
    uint256 _ethAmount,
    uint256 _minYethAmount,
    bool _stakeToStyeth
  ) internal returns (uint256) {
    uint256 _boughtYeth = _swapCurve(
      WETH_YETH_POOL,
      0,
      1,
      _ethAmount,
      _minYethAmount
    );
    if (_stakeToStyeth) {
      IERC20(YETH).safeIncreaseAllowance(STYETH, _boughtYeth);
      return IERC4626(STYETH).deposit(_boughtYeth, address(this));
    }
    return _boughtYeth;
  }

  function _styethToWeth(
    uint256 _stYethAmount,
    uint256 _minWethAmount,
    bool _isYethOnly
  ) internal returns (uint256) {
    uint256 _yethAmount;
    if (_isYethOnly) {
      _yethAmount = _stYethAmount;
    } else {
      _yethAmount = IERC4626(STYETH).redeem(
        _stYethAmount,
        address(this),
        address(this)
      );
    }
    return _swapCurve(WETH_YETH_POOL, 1, 0, _yethAmount, _minWethAmount);
  }

  function _setZapMapFromPoolSingle(PoolType _type, address _pool) internal {
    address _t0;
    address _t1;
    if (_type == PoolType.CURVE) {
      _t0 = ICurvePool(_pool).coins(0);
      _t1 = ICurvePool(_pool).coins(1);
      curveTokenIdx[_pool][_t0] = 0;
      curveTokenIdx[_pool][_t1] = 1;
    } else {
      _t0 = IUniswapV3Pool(_pool).token0();
      _t1 = IUniswapV3Pool(_pool).token1();
    }
    Pools memory _poolConf = Pools({
      poolType: _type,
      pool1: _pool,
      pool2: address(0)
    });
    zapMap[_t0][_t1] = _poolConf;
    zapMap[_t1][_t0] = _poolConf;
  }

  function setPOHM(address _pOHM) external onlyOwner {
    pOHM = _pOHM;
  }

  function setSlippage(uint256 _slip) external onlyOwner {
    require(_slip >= 0 && _slip <= 1000, 'BOUNDS');
    _slippage = _slip;
  }

  function setZapMap(
    address _in,
    address _out,
    Pools memory _pools
  ) external onlyOwner {
    zapMap[_in][_out] = _pools;
  }

  function setZapMapFromPoolSingle(
    PoolType _type,
    address _pool
  ) external onlyOwner {
    _setZapMapFromPoolSingle(_type, _pool);
  }

  function rescueETH() external onlyOwner {
    (bool _sent, ) = payable(owner()).call{ value: address(this).balance }('');
    require(_sent);
  }

  function rescueERC20(IERC20 _token) external onlyOwner {
    require(_token.balanceOf(address(this)) > 0);
    _token.safeTransfer(owner(), _token.balanceOf(address(this)));
  }

  receive() external payable {}
}