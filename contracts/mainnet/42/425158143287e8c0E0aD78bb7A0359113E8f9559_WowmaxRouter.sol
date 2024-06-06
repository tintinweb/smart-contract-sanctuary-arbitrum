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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Wrapped Ether contract interface
 */
interface IWETH is IERC20 {
    /**
     * @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH token balance.
     */
    function deposit() external payable;

    /**
     * @dev Burn WETH token from caller account and withdraw matching ETH to the same.
     * @param wad Amount of WETH token to burn.
     */
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;
import "./IWowmaxRouterBase.sol";

/**
 * @title IWowmaxRouter
 * @notice Interface for the Wowmax Router, describes the functions that can be called from the router
 * and corresponding data structures
 */
interface IWowmaxRouter is IWowmaxRouterBase {

    /**
     * @notice Executes a token swap
     * @dev if from token is address(0) and amountIn is 0,
     * then chain native token is used as a source token, and value is used as an input amount
     * @param request Exchange request to be executed
     * @return amountsOut Array of output amounts that were received for each target token
     */
    function swap(ExchangeRequest calldata request) external payable returns (uint256[] memory amountsOut);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

/**
 * @title IWowmaxRouterBase
 * @notice Interface for the Wowmax Router Base, describes data structures
 */
interface IWowmaxRouterBase {

    /**
     * @notice Swap operation details structure
     * @param to Target token address
     * @param part Part of the currently owned tokens to be swapped. Total number of parts
     * is defined in the ExchangeRoute structure
     * @param addr Contract address that performs the swap
     * @param family Contract DEX family
     * @param data Additional data that is required for a specific DEX protocol
     */
    struct Swap {
        address to;
        uint256 part;
        address addr;
        bytes32 family;
        bytes data;
    }

    /**
     * @notice Exchange route details structure
     * @param from Source token address
     * @param parts Total number of parts of the currently owned tokens
     * @param swaps Array of swaps for a specified token
     */
    struct ExchangeRoute {
        address from;
        uint256 parts;
        Swap[] swaps;
    }

    /**
     * @notice Exchange request details structure
     * @param from Source token address
     * @param amountIn Source token amount to swap
     * @param to Array of target token addresses
     * @param exchangeRoutes Array of exchange routes
     * @param slippage Array of slippage tolerance values for each target token
     * @param amountOutExpected Array fo expected output amounts for each target token
     */
    struct ExchangeRequest {
        address from;
        uint256 amountIn;
        address[] to;
        ExchangeRoute[] exchangeRoutes;
        uint256[] slippage;
        uint256[] amountOutExpected;
    }

    /**
     * @notice Emitted when a swap is executed
     * @param account Account that initiated the swap
     * @param from Source token address
     * @param amountIn Source token amount that was swapped
     * @param to Array of target token addresses
     * @param amountOut Array of amounts that were received for each target token
     */
    event SwapExecuted(
        address indexed account,
        address indexed from,
        uint256 amountIn,
        address[] to,
        uint256[] amountOut
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Algebra V1 pool interface
 */
interface IAlgebraV1Pool {
    /**
     * @notice Swap token0 for token1, or token1 for token0
     * @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
     * @param recipient The address to receive the output of the swap
     * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
     * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
     * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
     * value after the swap. If one for zero, the price cannot be greater than this value after the swap
     * @param data Any data to be passed through to the callback. If using the Router it should contain
     * SwapRouter#SwapCallbackData
     * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
     * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
     */
    function swap(
        address recipient,
        bool zeroToOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
     * @dev Returns the address of the first token of the Uniswap v3 based pair
     * @return Address of the first token of the pair
     */
    function token0() external view returns (address);

    /**
     * @dev Returns the address of the second token of the Uniswap v3 based pair
     * @return Address of the second token of the pair
     */
    function token1() external view returns (address);
}

/**
 * @title Algebra V1 library
 * @notice Functions to swap tokens on Algebra V1 based protocols
 */
library AlgebraV1 {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Algebra V1 based protocol contract
     * @param from Address of token to swap from
     * @param amountIn Amount of token to swap
     * @param swapData Swap operation details. The `data` field should contain two int128 values,
     * which are the indices of the tokens to swap from and to
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        bool zeroToOne = from == IAlgebraV1Pool(swapData.addr).token0();
        uint160 sqrtPriceLimitX96 = zeroToOne ? 4295128740 : 1461446703485210103287273052203988822378723970341;
        (int256 amount0, int256 amount1) = IAlgebraV1Pool(swapData.addr).swap(
            address(this),
            zeroToOne,
            int256(amountIn),
            sqrtPriceLimitX96,
            new bytes(0)
        );
        amountOut = uint(zeroToOne ? -amount1 : -amount0);
    }

    /**
     * @dev Performs Algebra V1 callback, sends required amounts of tokens to the pair
     * @param amount0Delta Amount of the first token to send
     * @param amount1Delta Amount of the second token to send
     */
    function invokeCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata /*_data*/) internal {
        if (amount0Delta > 0 && amount1Delta < 0) {
            IERC20(IAlgebraV1Pool(msg.sender).token0()).safeTransfer(msg.sender, uint256(amount0Delta));
        } else if (amount0Delta < 0 && amount1Delta > 0) {
            IERC20(IAlgebraV1Pool(msg.sender).token1()).safeTransfer(msg.sender, uint256(amount1Delta));
        } else {
            revert("WOWMAX: Algebra V1 invariant violation");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Balancer Asset interface
 */
interface IBalancerAsset {
    // solhint-disable-previous-line no-empty-blocks
}

/**
 * @title Balancer vault interface
 */
interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IBalancerAsset assetIn;
        IBalancerAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}

/**
 * @title Balancer library
 * @notice Functions to swap tokens on Balancer and compatible protocols
 */
library BalancerV2 {
    using SafeERC20 for IERC20;

    /**
     * @dev Performs a swap through a Balancer based vault
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should contain poolId and vault address
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        (bytes32 poolId, address vaultAddress) = abi.decode(swapData.data, (bytes32, address));

        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
            poolId: poolId,
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: IBalancerAsset(from),
            assetOut: IBalancerAsset(swapData.to),
            amount: amountIn,
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        IERC20(from).safeIncreaseAllowance(vaultAddress, amountIn);

        amountOut = IBalancerVault(vaultAddress).swap(singleSwap, funds, 0, type(uint256).max);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Curve pool interface
 */
interface ICurvePool {
    /**
     * @dev Swaps tokens on a Curve based protocol contract
     * @param i Index of token to swap from
     * @param j Index of token to swap to
     * @param dx Amount of token to swap
     * @param min_dy Minimum amount of tokens to receive
     */
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

/**
 * @title Curve library
 * @notice Functions to swap tokens on Curve based protocols
 */
library Curve {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Curve based protocol contract
     * @param from Address of token to swap from
     * @param amountIn Amount of token to swap
     * @param swapData Swap operation details. The `data` field should contain two int128 values,
     * which are the indices of the tokens to swap from and to
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        (int128 i, int128 j) = abi.decode(swapData.data, (int128, int128));
        uint256 balanceBefore = IERC20(swapData.to).balanceOf(address(this));
        //slither-disable-next-line unused-return //it's safe to ignore
        IERC20(from).safeIncreaseAllowance(swapData.addr, amountIn);
        ICurvePool(swapData.addr).exchange(i, j, amountIn, 0);
        amountOut = IERC20(swapData.to).balanceOf(address(this)) - balanceBefore;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title DODO v1 pool interface
 */
interface IDODOV1Pool {
    /**
     * @dev Sells base token for quote token
     * @param amount Amount of base token to sell
     * @param minReceiveQuote Minimum amount of quote token to receive
     * @param data Additional data to be used in callback hook
     * @return amountOut Amount of quote token received
     */
    function sellBaseToken(uint256 amount, uint256 minReceiveQuote, bytes calldata data) external returns (uint256);

    /**
     * @dev Buys base token with quote token
     * @param amount Amount of base token to buy
     * @param maxPayQuote Maximum amount of quote token to pay
     * @param data Additional data to be used in callback hook
     * @return amountOut Amount of base token received
     */
    function buyBaseToken(uint256 amount, uint256 maxPayQuote, bytes calldata data) external returns (uint256);
}

/**
 * @title DODO v1 library
 * @notice Functions to swap tokens on DODO v1 protocol
 */
library DODOV1 {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Curve based protocol contract
     * @param from Address of token to swap from
     * @param amountIn Amount of token to swap
     * @param swapData Swap operation details. The `data` field should contain two int128 values, i and j,
     * which are the indexes of the tokens to swap
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        //slither-disable-next-line unused-return //it's safe to ignore
        IERC20(from).safeIncreaseAllowance(swapData.addr, amountIn);
        amountOut = IDODOV1Pool(swapData.addr).sellBaseToken(amountIn, 0, "");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title DODO v2 pool interface
 */
interface IDODOV2Pool {
    /**
     * @dev Swaps tokens on a DODO v2 based protocol contract
     * @param to Address of token to swap to
     * @return amountOut Amount of tokens received
     */
    function sellBase(address to) external returns (uint256);

    /**
     * @dev Swaps tokens on a DODO v2 based protocol contract
     * @param to Address of token to swap to
     * @return amountOut Amount of tokens received
     */
    function sellQuote(address to) external returns (uint256);
}

/**
 * @title DODO v2 library
 * @notice Functions to swap tokens on DODO v2 protocol
 */
library DODOV2 {
    uint8 internal constant BASE_TO_QUOTE = 0;

    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a DODO v2 pool contract
     * @param from Address of token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should contain one uint8 value,
     * which is the direction of the swap
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeTransfer(swapData.addr, amountIn);
        uint8 direction = abi.decode(swapData.data, (uint8));

        if (direction == BASE_TO_QUOTE) {
            amountOut = IDODOV2Pool(swapData.addr).sellBase(address(this));
        } else {
            amountOut = IDODOV2Pool(swapData.addr).sellQuote(address(this));
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title DODO v3 pool interface
 */
interface IDODOV3Pool {
    /**
     * @dev Swaps tokens on a DODO v3 based protocol contract
     * @param to Address to send swapped tokens to
     * @param fromToken Address of a token to swap from
     * @param toToken Address of a token to swap to
     * @param fromAmount Amount of tokens to swap
     * @param minReceiveAmount Minimal amount of tokens to receive
     * @param data Data to be passed to the Dodo V3 Swap Callback contract
     * @return Amount of tokens received
     */
    function sellToken(
        address to,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minReceiveAmount,
        bytes calldata data
    ) external returns (uint256);
}

/**
 * @title DODO v3 library
 * @notice Functions to swap tokens on DODO v3 protocol
 */
library DODOV3 {
    uint8 internal constant BASE_TO_QUOTE = 0;

    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a DODO v3 pool contract
     * @param from Address of token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should be empty
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        return IDODOV3Pool(swapData.addr).sellToken(address(this), from, swapData.to, amountIn, 0, "");
    }

    /**
     * @dev Callback function to receive tokens from DODO v3 pool contract
     * @param token Address of token to receive
     * @param amount Amount of tokens to receive
     */
    function invokeCallback(address token, uint256 amount, bytes calldata /*data*/) internal {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Elastic pool interface
 */
interface IElasticPool {
    /**
     * @notice Swap token0 -> token1, or vice versa
     * @dev This method's caller receives a callback in the form of ISwapCallback#swapCallback
     * @dev swaps will execute up to limitSqrtP or swapQty is fully used
     * @param recipient The address to receive the swap output
     * @param swapQty The swap quantity, which implicitly configures the swap as exact input (>0), or exact output (<0)
     * @param isToken0 Whether the swapQty is specified in token0 (true) or token1 (false)
     * @param limitSqrtP the limit of sqrt price after swapping
     * could be MAX_SQRT_RATIO-1 when swapping 1 -> 0 and MIN_SQRT_RATIO+1 when swapping 0 -> 1 for no limit swap
     * @param data Any data to be passed through to the callback
     * @return qty0 Exact token0 qty sent to recipient if < 0. Minimally received quantity if > 0.
     * @return qty1 Exact token1 qty sent to recipient if < 0. Minimally received quantity if > 0.
     */
    function swap(
        address recipient,
        int256 swapQty,
        bool isToken0,
        uint160 limitSqrtP,
        bytes calldata data
    ) external returns (int256 qty0, int256 qty1);

    /**
     * @dev Returns the address of the first token of the Uniswap v3 based pair
     * @return Address of the first token of the pair
     */
    function token0() external view returns (address);

    /**
     * @dev Returns the address of the second token of the Uniswap v3 based pair
     * @return Address of the second token of the pair
     */
    function token1() external view returns (address);
}

/**
 * @title Elastic library
 * @notice Functions to swap tokens on Elastic based protocols
 */
library Elastic {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on Elastic based protocol contract
     * @param from Address of token to swap from
     * @param amountIn Amount of token to swap
     * @param swapData Swap operation details. The `data` field should contain two int128 values,
     * which are the indices of the tokens to swap from and to
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        bool isToken0 = from == IElasticPool(swapData.addr).token0();
        uint160 sqrtPriceLimitX96 = isToken0 ? 4295128740 : 1461446703485210103287273052203988822378723970341;
        (int256 amount0, int256 amount1) = IElasticPool(swapData.addr).swap(
            address(this),
            int256(amountIn),
            isToken0,
            sqrtPriceLimitX96,
            new bytes(0)
        );
        amountOut = uint(isToken0 ? -amount1 : -amount0);
    }

    /**
     * @dev Performs Elastic callback, sends required amounts of tokens to the pair
     * @param deltaQty0 Amount of the first token to send
     * @param deltaQty1 Amount of the second token to send
     */
    function invokeCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata /*_data*/) internal {
        if (deltaQty0 > 0 && deltaQty1 < 0) {
            IERC20(IElasticPool(msg.sender).token0()).safeTransfer(msg.sender, uint256(deltaQty0));
        } else if (deltaQty0 < 0 && deltaQty1 > 0) {
            IERC20(IElasticPool(msg.sender).token1()).safeTransfer(msg.sender, uint256(deltaQty1));
        } else {
            revert("WOWMAX: Elastic invariant violation");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Fulcrom pool interface
 */
interface IFulcromPool {
    /**
     * @dev Swaps tokens on a Fulcrom based protocol contract
     * @param _tokenIn Address of a token to swap from
     * @param _tokenOut Address of a token to swap to
     * @param _receiver Address to send swapped tokens to
     * @return amountOut Amount of tokens received
     */
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
}

/**
 * @title Fulcrom library
 * @notice Functions to swap tokens on Fulcrom protocol
 */
library Fulcrom {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Fulcrom pool contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should be empty
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeTransfer(swapData.addr, amountIn);
        amountOut = IFulcromPool(swapData.addr).swap(from, swapData.to, address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Hashflow Router interface
 */
interface IHashflowRouter {
    struct RFQTQuote {
        /// @notice The address of the HashflowPool to trade against.
        address pool;
        /**
         * @notice The external account linked to the HashflowPool.
         * If the HashflowPool holds funds, this should be address(0).
         */
        address externalAccount;
        /// @notice The recipient of the quoteToken at the end of the trade.
        address trader;
        /**
         * @notice The account "effectively" making the trade (ultimately receiving the funds).
         * This is commonly used by aggregators, where a proxy contract (the 'trader')
         * receives the quoteToken, and the effective trader is the user initiating the call.
         *
         * This field DOES NOT influence movement of funds. However, it is used to check against
         * quote replay.
         */
        address effectiveTrader;
        /// @notice The token that the trader sells.
        address baseToken;
        /// @notice The token that the trader buys.
        address quoteToken;
        /**
         * @notice The amount of baseToken sold in this trade. The exchange rate
         * is going to be preserved as the quoteTokenAmount / baseTokenAmount ratio.
         *
         * Most commonly, effectiveBaseTokenAmount will == baseTokenAmount.
         */
        uint256 effectiveBaseTokenAmount;
        /// @notice The max amount of baseToken sold.
        uint256 baseTokenAmount;
        /// @notice The amount of quoteToken bought when baseTokenAmount is sold.
        uint256 quoteTokenAmount;
        /// @notice The Unix timestamp (in seconds) when the quote expires.
        /// @dev This gets checked against block.timestamp.
        uint256 quoteExpiry;
        /// @notice The nonce used by this effectiveTrader. Nonces are used to protect against replay.
        uint256 nonce;
        /// @notice Unique identifier for the quote.
        /// @dev Generated off-chain via a distributed UUID generator.
        bytes32 txid;
        /// @notice Signature provided by the market maker (EIP-191).
        bytes signature;
    }

    /**
     * @notice Executes an intra-chain RFQ-T trade.
     * @param quote The quote data to be executed.
     */
    function tradeRFQT(RFQTQuote memory quote) external payable;
}

// @title Hashflow library
// @notice Functions to swap tokens on Hashflow protocol
library Hashflow {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Hashflow router contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should contain encoded RFQTQuote structure
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IHashflowRouter.RFQTQuote memory quote = abi.decode(swapData.data, (IHashflowRouter.RFQTQuote));
        //slither-disable-next-line unused-return //it's safe to ignore
        IERC20(from).safeIncreaseAllowance(swapData.addr, amountIn);
        if (amountIn < quote.baseTokenAmount) {
            quote.effectiveBaseTokenAmount = amountIn;
        }
        uint256 balanceBefore = IERC20(swapData.to).balanceOf(address(this));
        IHashflowRouter(swapData.addr).tradeRFQT(quote);
        amountOut = IERC20(swapData.to).balanceOf(address(this)) - balanceBefore;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Iziswap pool interface
 */
interface IIziswapPool {
    /**
     * @notice Swap tokenX for tokenY, given max amount of tokenX user willing to pay.
     * @param recipient the address to receive tokenY
     * @param amount the max amount of tokenX user willing to pay
     * @param lowPt the lowest point(price) of x/y during swap
     * @param data any data to be passed through to the callback
     * @return amountX amount of tokenX acquired
     * @return amountY amount of tokenY payed
     */
    function swapX2Y(
        address recipient,
        uint128 amount,
        int24 lowPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY);

    /**
     * @notice Swap tokenY for tokenX, given max amount of tokenY user willing to pay.
     * @param recipient the address to receive tokenX
     * @param amount the max amount of tokenY user willing to pay
     * @param highPt the highest point(price) of x/y during swap
     * @param data any data to be passed through to the callback
     * @return amountX amount of tokenX payed
     * @return amountY amount of tokenY acquired
     */
    function swapY2X(
        address recipient,
        uint128 amount,
        int24 highPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY);
}

/**
 * @title Iziswap library
 * @notice Functions to swap tokens on Iziswap based protocols
 */
library Iziswap {
    uint256 constant X2Y = 0;
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Iziswap based protocol contract
     * @param from Address of token to swap from
     * @param amountIn Amount of token to swap
     * @param swapData Swap operation details. The `data` field should contain two int128 values,
     * which are the indices of the tokens to swap from and to
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        int24 pt = abi.decode(swapData.data, (int24));
        //slither-disable-next-line unused-return //it's safe to ignore
        bytes memory data = abi.encode(from);

        if (from < swapData.to) {
            (, amountOut) = IIziswapPool(swapData.addr).swapX2Y(address(this), uint128(amountIn), pt, data);
        } else {
            (amountOut, ) = IIziswapPool(swapData.addr).swapY2X(address(this), uint128(amountIn), pt, data);
        }
    }

    function transferTokens(uint256 amount, bytes calldata data) internal {
        address token = abi.decode(data, (address));
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Level pool interface
 */
interface ILevelPool {
    /**
     * @dev Swaps tokens on a Level based protocol contract
     * @param _tokenIn Address of a token to swap from
     * @param _tokenOut Address of a token to swap to
     * @param _minOut Minimal amount of tokens to receive
     * @param _to Address to send swapped tokens to
     * @param extradata Data to be used in callback
     */
    function swap(address _tokenIn, address _tokenOut, uint256 _minOut, address _to, bytes calldata extradata) external;
}

/**
 * @title Level library
 * @notice Functions to swap tokens on Level protocol
 */
library Level {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Level pool contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should be empty
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeTransfer(swapData.addr, amountIn);
        uint256 balanceBefore = IERC20(swapData.to).balanceOf(address(this));
        ILevelPool(swapData.addr).swap(from, swapData.to, 0, address(this), new bytes(0));
        amountOut = IERC20(swapData.to).balanceOf(address(this)) - balanceBefore;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Maverick V1 pool interface
 */
interface IMaverickV1Pool {
    /**
     * @dev Swaps tokens on a Maverick v1 based pool
     * @param recipient Address to send swapped tokens to
     * @param amount Amount of tokens to swap
     * @param tokenAIn Flag that indicates token direction. True for tokenA to tokenB direction,
     * false for tokenB to tokenA
     * @param exactOutput Flag that indicates whether the amount is exact output or input
     * @param sqrtPriceLimit Price limit within which swap is processed
     * @param data Additional data to be send in callback function
     * @return amountIn Amount of the input token to be paid
     * @return amountOut Amount of the output token to be received
     */
    function swap(
        address recipient,
        uint256 amount,
        bool tokenAIn,
        bool exactOutput,
        uint256 sqrtPriceLimit,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut);

    /**
     * @dev Returns the address of the first token of the Maverick v1 based pair
     * @return Address of the first token of the pair
     */
    function tokenA() external view returns (address);

    /**
     * @dev Returns the address of the second token of the Maverick v1 based pair
     * @return Address of the second token of the pair
     */
    function tokenB() external view returns (address);
}

/**
 * @title Maverick v1 library
 * @notice Functions to swap tokens on Maverick v1 and compatible protocol
 */
library MaverickV1 {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Maverick v1 based pair
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap data. The `data` field should contain zeroForOne flag
     * @return amountOut Amount of tokens received
     */
    function swap(uint256 amountIn, IWowmaxRouter.Swap memory swapData) internal returns (uint256 amountOut) {
        bool tokenAIn = abi.decode(swapData.data, (bool));
        (, amountOut) = IMaverickV1Pool(swapData.addr).swap(address(this), amountIn, tokenAIn, false, 0, swapData.data);
    }

    /**
     * @dev Performs Maverick v1 callback, sends required amounts of tokens to the pool
     * @param amountToPay amount to pay
     * @param _data encoded swap direction
     */
    function invokeCallback(uint256 amountToPay, uint256 /*amountOut*/, bytes calldata _data) internal {
        bool tokenAIn = abi.decode(_data, (bool));
        if (tokenAIn) {
            IERC20(IMaverickV1Pool(msg.sender).tokenA()).safeTransfer(msg.sender, amountToPay);
        } else {
            IERC20(IMaverickV1Pool(msg.sender).tokenB()).safeTransfer(msg.sender, amountToPay);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title PancakeSwap pool interface
 */
interface IPancakeStablePool {
    /**
     * @notice Exchange `dx` amount of `i` token to at least `min_dy` amount of `j` token
     * @dev Same as Curve but uses uint256 instead of int128
     * @param i Index of token to swap from
     * @param j Index of token to swap to
     * @param dx Amount of `i` token to swap from
     * @param min_dy Minimum amount of `j` token to receive
     */
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
}

/**
 * @title PancakeSwap library
 * @notice Functions to swap tokens on PancakeSwap like protocols
 */
library PancakeSwapStable {
    using SafeERC20 for IERC20;

    /**
     * @notice Swaps tokens on a PancakeSwap Stable like protocol contract
     * @param from Address of token to swap from
     * @param amountIn Amount of token to swap
     * @param swapData Swap operation details. The `data` field should contain two int128 values,
     * which are the indices of the tokens to swap from and to
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        (int128 i, int128 j) = abi.decode(swapData.data, (int128, int128));
        uint256 balanceBefore = IERC20(swapData.to).balanceOf(address(this));
        //slither-disable-next-line unused-return //it's safe to ignore
        IERC20(from).safeIncreaseAllowance(swapData.addr, amountIn);
        IPancakeStablePool(swapData.addr).exchange(uint256(uint128(i)), uint256(uint128(j)), amountIn, 0);
        amountOut = IERC20(swapData.to).balanceOf(address(this)) - balanceBefore;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Saddle pool interface
 */
interface ISaddlePool {
    /**
     * @dev Swaps tokens on a Saddle based protocol contract
     * @param tokenIndexFrom Index of a token to swap from
     * @param tokenIndexTo Index of a token to swap to
     * @param dx Amount of tokens to swap
     * @param minDy Minimum amount of tokens to receive
     * @param deadline Timestamp after which transaction will revert
     */
    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external;
}

/**
 * @title Saddle library
 * @notice Functions to swap tokens on Saddle protocol
 */
library Saddle {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Saddle pool contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should contain two uint8 values,
     * which are tokenIndexFrom and tokenIndexTo
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        (uint8 tokenIndexFrom, uint8 tokenIndexTo) = abi.decode(swapData.data, (uint8, uint8));
        uint256 balanceBefore = IERC20(swapData.to).balanceOf(address(this));
        //slither-disable-next-line unused-return //it's safe to ignore
        IERC20(from).safeIncreaseAllowance(swapData.addr, amountIn);
        ISaddlePool(swapData.addr).swap(tokenIndexFrom, tokenIndexTo, amountIn, 0, type(uint256).max);
        amountOut = IERC20(swapData.to).balanceOf(address(this)) - balanceBefore;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title SyncSwap pool interface
 */
interface ISyncSwapPool {
    /**
     * @dev Token amount structure
     * @param token Address of a token
     * @param amount Amount of tokens
     */
    struct TokenAmount {
        address token;
        uint amount;
    }

    /**
     * @dev Swaps between tokens.
     * @param data Swap operation details
     * @param sender Address of the sender
     * @param callback Callback address
     * @param callbackData Callback data
     * @return tokenAmount Amount of tokens received
     */
    function swap(
        bytes calldata data,
        address sender,
        address callback,
        bytes calldata callbackData
    ) external returns (TokenAmount memory tokenAmount);

    /**
     * @dev Returns the address of the SyncSwap pool vault
     * @return Vault address
     */
    function vault() external view returns (address);
}

/**
 * @title SyncSwap vault interface
 */
interface ISyncSwapVault {
    /**
     * @dev Deposits tokens to the SyncSwap vault
     * @param token Address of a token to deposit
     * @param to SyncSwap pool address
     * @return amount Amount of tokens deposited
     */
    function deposit(address token, address to) external payable returns (uint amount);
}

/**
 * @title SyncSwap library
 * @notice Functions to swap tokens on SyncSwap protocol
 */
library SyncSwap {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a SyncSwap pool contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should be empty
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        ISyncSwapVault vault = ISyncSwapVault(ISyncSwapPool(swapData.addr).vault());
        IERC20(from).safeTransfer(address(vault), amountIn);
        vault.deposit(from, swapData.addr);
        bytes memory data = abi.encode(from, address(this), uint8(2)); // from, to, withdrawMode (0 - default, 1 - unwrapped, 2 - wrapped)
        ISyncSwapPool.TokenAmount memory out = ISyncSwapPool(swapData.addr).swap(
            data,
            address(0x0),
            address(0x0),
            new bytes(0)
        );
        return out.amount;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Uniswap v2 pair interface
 */
interface IUniswapV2Pair {
    /**
     * @dev Returns the address of the first token of the Uniswap v2 based pair
     * @return Address of the first token of the pair
     */
    function token0() external view returns (address);

    /**
     * @dev Returns the address of the second token of the Uniswap v2 based pair
     * @return Address of the second token of the pair
     */
    function token1() external view returns (address);

    /**
     * @dev Returns the Uniswap v2 based pair reserves
     * @return _reserve0 Reserve of the first token in the pair
     * @return _reserve1 Reserve of the second token in the pair
     * @return _blockTimestampLast Block timestamp of the last reserve update
     */
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    /**
     * @dev Swaps tokens on a Uniswap v2 based pair
     * @param amount0Out Amount of the first token to receive
     * @param amount1Out Amount of the second token to receive
     * @param to Address to send tokens to
     * @param data Data to be send in callback function, if any
     */
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    /**
     * @dev Returns the address of the Uniswap v2 based pair router
     * @return Router address
     */
    function router() external returns (address);
}

/**
 * @title Uniswap v2 router interface
 */
interface IUniswapV2Router {
    /**
     * @dev Swaps tokens on a Uniswap v2 based router
     * @param amountIn Amount of tokens to swap
     * @param amountOutMin Minimal amount of tokens to receive
     * @param path Sequence of tokens to perform swap through
     * @param to Address to send swapped tokens to
     * @param deadline Timestamp after which the transaction will revert,
     * 0 if it is not defined
     * @return amounts Amounts of tokens received for each swap step
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/**
 * @title Uniswap v2 library
 * @notice Functions to swap tokens on Uniswap v2 and compatible protocols
 */
library UniswapV2 {
    /**
     * @dev Common fee denominator
     */
    uint256 private constant FEE_DENOMINATOR = 10000;

    using SafeERC20 for IERC20;

    /**
     * @dev Performs a direct swap through a Uniswap v2 based pair
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should contain the fee value specific for the pair
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeTransfer(swapData.addr, amountIn);
        uint256 fee = abi.decode(swapData.data, (uint256));
        bool directSwap = IUniswapV2Pair(swapData.addr).token0() == from;
        (uint112 reserveIn, uint112 reserveOut) = getReserves(swapData.addr, directSwap);
        amountOut = getAmountOut(amountIn, reserveIn, reserveOut, fee);
        if (amountOut > 0) {
            IUniswapV2Pair(swapData.addr).swap(
                directSwap ? 0 : amountOut,
                directSwap ? amountOut : 0,
                address(this),
                new bytes(0)
            );
        }
    }

    /**
     * @dev Performs a swap through a Uniswap v2 based protocol using a router contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details
     * data field should be empty
     * @return amountOut Amount of tokens received
     */
    function routerSwap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IUniswapV2Router router = IUniswapV2Router(IUniswapV2Pair(swapData.addr).router());
        IERC20(from).safeIncreaseAllowance(address(router), amountIn);
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = swapData.to;
        return router.swapExactTokensForTokens(amountIn, 0, path, address(this), type(uint256).max)[1];
    }

    /**
     * @dev Returns the reserves of a Uniswap v2 based pair ordered according to swap direction
     * @param pair Address of a Uniswap v2 based pair
     * @param directSwap True if the first token of the pair is the token to swap from, false otherwise
     * @return reserveIn Reserve of the token to swap from
     * @return reserveOut Reserve of the token to swap to
     */
    function getReserves(address pair, bool directSwap) private view returns (uint112 reserveIn, uint112 reserveOut) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        return directSwap ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @dev Returns the amount of tokens to be received for a given input amount and pair reserves
     * @param amountIn Amount of tokens to swap
     * @param reserveIn Reserve of the token to swap from
     * @param reserveOut Reserve of the token to swap to
     * @param fee Fee of the Uniswap v2 based pair. This value is specific for the pair
     * and/or it's DEX, and should be provided externally
     * @return amountOut Amount of tokens received
     */
    function getAmountOut(
        uint256 amountIn,
        uint112 reserveIn,
        uint112 reserveOut,
        uint256 fee
    ) private pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - fee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        amountOut = numerator / denominator;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Uniswap v2 pair interface
 */
interface IUniswapV3Pool {
    /**
     * @dev Swaps tokens on a Uniswap v3 based pair
     * @param recipient Address to send swapped tokens to
     * @param zeroForOne Flag that indicates token direction. True for token0 to token1 direction,
     * false for token1 to token0
     * @param amountSpecified Amount of tokens to swap
     * @param sqrtPriceLimitX96 Price limit within which swap is processed
     * @param data Additional data to be send in callback function
     * @return amount0 Amount of the first token received
     * @return amount1 Amount of the second token received
     */
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
     * @dev Returns the address of the first token of the Uniswap v3 based pair
     * @return Address of the first token of the pair
     */
    function token0() external view returns (address);

    /**
     * @dev Returns the address of the second token of the Uniswap v3 based pair
     * @return Address of the second token of the pair
     */
    function token1() external view returns (address);
}

/**
 * @title Uniswap v3 library
 * @notice Functions to swap tokens on Uniswap v3 and compatible protocol
 */
library UniswapV3 {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Uniswap v3 based pair
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap data. The `data` field should contain zeroForOne flag
     * @return amountOut Amount of tokens received
     */
    function swap(uint256 amountIn, IWowmaxRouter.Swap memory swapData) internal returns (uint256 amountOut) {
        bool zeroForOne = abi.decode(swapData.data, (bool));
        uint160 sqrtPriceLimitX96 = zeroForOne ? 4295128740 : 1461446703485210103287273052203988822378723970341;
        (int256 amount0, int256 amount1) = IUniswapV3Pool(swapData.addr).swap(
            address(this),
            zeroForOne,
            int256(amountIn),
            sqrtPriceLimitX96,
            new bytes(0)
        );
        amountOut = uint(zeroForOne ? -amount1 : -amount0);
    }

    /**
     * @dev Performs Uniswap v3 callback, sends required amounts of tokens to the pair
     * @param amount0Delta Amount of the first token to send
     * @param amount1Delta Amount of the second token to send
     */
    function invokeCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata /*_data*/) internal {
        if (amount0Delta > 0 && amount1Delta < 0) {
            IERC20(IUniswapV3Pool(msg.sender).token0()).safeTransfer(msg.sender, uint256(amount0Delta));
        } else if (amount0Delta < 0 && amount1Delta > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token1()).safeTransfer(msg.sender, uint256(amount1Delta));
        } else {
            revert("WOWMAX: Uniswap v3 invariant violation");
        }
    }

    /**
     * @notice Try to decode provided "dataWithSelector" as Uniswap V3 callback.
     * @return Flag indicating whether decoding succeeded, followed by decoded amount0Delta, amount1Delta and data.
     */
    function decodeCallback(
        bytes calldata dataWithSelector
    ) internal pure returns (bool, int256, int256, bytes calldata) {
        int256 amount0Delta;
        int256 amount1Delta;
        bytes calldata data;

        assembly {
            amount0Delta := calldataload(add(dataWithSelector.offset, 4))
            amount1Delta := calldataload(add(dataWithSelector.offset, 36))

            // get offset of bytes length: selector + (amount0Delta | amount1Delta | data length offset | data length | data).
            // "length offset" is relative to start of first parameter in data.
            let dataLenOffset := add(add(dataWithSelector.offset, 4), calldataload(add(dataWithSelector.offset, 68)))
            data.length := calldataload(dataLenOffset)
            data.offset := add(dataLenOffset, 32)
        }

        // validate that what we got matches what we expect
        unchecked {
            // account for padding in 32-byte word unaligned data
            uint256 paddedDataLen = data.length;
            uint256 remainder = data.length % 32;
            if (remainder > 0) {
                paddedDataLen = paddedDataLen + (32 - remainder);
            }
            // 132 = 4 (selector) + 64 ("sender", "amount0Delta", "amount1Delta" offsets) + 64 ("length offset" + "length" offsets)
            if (dataWithSelector.length != (paddedDataLen + 132)) {
                return (false, 0, 0, emptyBytesCalldata());
            }
        }

        return (true, amount0Delta, amount1Delta, data);
    }

    function emptyBytesCalldata() private pure returns (bytes calldata) {
        bytes calldata empty;
        assembly {
            empty.length := 0
            empty.offset := 0
        }
        return empty;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";
import "../interfaces/IWETH.sol";

/**
 * @title Velocore vault interface
 */
interface IVelocoreVault {
    /**
     * @dev Swaps tokens on a Velocore based protocol
     * @param pool Address of a Velocore pool contract
     * @param method Swap method
     * @param t1 Address of a token to swap from
     * @param m1 Swap method for the first token
     * @param a1 Amount of the first token to swap
     * @param t2 Address of a token to swap to
     * @param m2 Swap method for the second token
     * @param a2 Amount of the second token to swap
     * @param data Additional data to be used in swap
     * @return amounts Amounts of tokens received
     */
    function execute2(
        address pool,
        uint8 method,
        address t1,
        uint8 m1,
        int128 a1,
        address t2,
        uint8 m2,
        int128 a2,
        bytes memory data
    ) external payable returns (int128[] memory);

    function getPair(address tokenA, address tokenB) external view returns (address);
}

/**
 * @title Velocore library
 * @notice Functions to swap tokens on Velocore protocol
 */
library VelocoreV2 {
    uint8 constant SWAP = 0;
    uint8 constant EXACTLY = 0;
    uint8 constant AT_MOST = 1;
    address constant NATIVE_TOKEN = address(0x0);

    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Velocore pool contract
     * @param wrappedNativeToken Address of a wrapped native token
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should contain vault address
     * @return amountOut Amount of tokens received
     */
    function swap(
        address wrappedNativeToken,
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        address vaultAddress = abi.decode(swapData.data, (address));
        IVelocoreVault vault = IVelocoreVault(vaultAddress);

        address fromToken = from == wrappedNativeToken ? NATIVE_TOKEN : from;
        address toToken = swapData.to == wrappedNativeToken ? NATIVE_TOKEN : swapData.to;
        int128[] memory result;

        if (fromToken == NATIVE_TOKEN) {
            IWETH(wrappedNativeToken).withdraw(amountIn);
            result = vault.execute2{ value: amountIn }(
                swapData.addr,
                SWAP,
                fromToken,
                EXACTLY,
                int128(int256(amountIn)),
                toToken,
                AT_MOST,
                0,
                ""
            );
        } else {
            IERC20(fromToken).safeIncreaseAllowance(address(vault), amountIn);
            result = vault.execute2(
                swapData.addr,
                SWAP,
                fromToken,
                EXACTLY,
                int128(int256(amountIn)),
                toToken,
                AT_MOST,
                0,
                ""
            );
        }

        amountOut = uint256(int256(result[1]));

        if (toToken == NATIVE_TOKEN) {
            IWETH(wrappedNativeToken).deposit{ value: amountOut }();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Velodrome pair interface
 */
interface IVelodromePair {
    /**
     * @dev Returns the Velodrome based pair amount out
     * @param amountIn Amount to swap
     * @param from Address of the token to swap from
     * @return Amount of tokens to receive
     */
    function getAmountOut(uint256 amountIn, address from) external view returns (uint256);

    /**
     * @dev Swaps tokens on a Velodrome based pair
     * @param amount0Out Amount of the first token to receive
     * @param amount1Out Amount of the second token to receive
     * @param to Address to send tokens to
     * @param data Data to be send in callback function, if any
     */
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

/**
 * @title Velodrome library
 * @notice Functions to swap tokens on Velodrome and compatible protocols
 */
library Velodrome {
    using SafeERC20 for IERC20;

    /**
     * @dev Performs a swap through a Velodrome based pair
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should contain from token index
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        uint256 fromIndex = abi.decode(swapData.data, (uint256));
        amountOut = IVelodromePair(swapData.addr).getAmountOut(amountIn, from);
        if (amountOut > 0) {
            IERC20(from).safeTransfer(swapData.addr, amountIn);
            IVelodromePair(swapData.addr).swap(
                fromIndex == 0 ? 0 : amountOut,
                fromIndex == 0 ? amountOut : 0,
                address(this),
                new bytes(0)
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Vooi pool interface
 */
interface IVooiPool {
    /**
     * @notice Swap fromToken for toToken, ensures deadline and minimumToAmount and sends quoted amount to `to` address
     * @dev This function assumes tax free token.
     * @param _fromID The token being inserted into Pool by user for swap
     * @param _toID The token wanted by user, leaving the Pool
     * @param _fromAmount The amount of from token inserted
     * @param _minToAmount The minimum amount that will be accepted by user as result
     * @param _to The user receiving the result of swap
     * @param _deadline The deadline to be respected
     */
    function swap(
        uint256 _fromID,
        uint256 _toID,
        uint256 _fromAmount,
        uint256 _minToAmount,
        address _to,
        uint256 _deadline
    ) external returns (uint256 actualToAmount, uint256 lpFeeAmount);
}

/**
 * @title Vooi library
 * @notice Functions to swap tokens on Vooi protocol
 */
library Vooi {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Vooi pool contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should be empty
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        (uint8 fromID, uint8 toID) = abi.decode(swapData.data, (uint8, uint8));
        IERC20(from).safeIncreaseAllowance(swapData.addr, amountIn);
        (amountOut, ) = IVooiPool(swapData.addr).swap(fromID, toID, amountIn, 0, address(this), type(uint256).max);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title Wombat pool interface
 */
interface IWombatPool {
    /**
     * @dev Swaps tokens on a Wombat based protocol contract
     * @param fromToken Address of a token to swap from
     * @param toToken Address of a token to swap to
     * @param fromAmount Amount of tokens to swap
     * @param minimumToAmount Minimal amount of tokens to receive
     * @param to Address to send swapped tokens to
     * @param deadline Timestamp after which the transaction will revert
     * @return actualToAmount Actual amount of tokens received
     * @return haircut Amount of tokens taken as fee
     */
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);
}

/**
 * @title Wombat library
 * @notice Functions to swap tokens on Wombat protocol
 */
library Wombat {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a Wombat pool contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should be empty
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeIncreaseAllowance(swapData.addr, amountIn);
        (amountOut, ) = IWombatPool(swapData.addr).swap(
            from,
            swapData.to,
            amountIn,
            0,
            address(this),
            type(uint256).max
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

/**
 * @title WooFi pool interface
 */
interface IWooFiPool {
    /**
     * @dev Swaps tokens on a WooFi based protocol contract
     * @param fromToken Address of a token to swap from
     * @param toToken Address of a token to swap to
     * @param fromAmount Amount of tokens to swap
     * @param minToAmount Minimal amount of tokens to receive
     * @param to Address to send swapped tokens to
     * @param rebateTo The rebate address (optional, can be address ZERO)
     * @return realToAmount Amount of tokens received
     */
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external returns (uint256 realToAmount);
}

/**
 * @title WooFi library
 * @notice Functions to swap tokens on WooFi protocol
 */
library WooFi {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a WooFi pool contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should be empty
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeTransfer(swapData.addr, amountIn);
        amountOut = IWooFiPool(swapData.addr).swap(from, swapData.to, amountIn, 0, address(this), address(0x0));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWowmaxRouter.sol";
import "../interfaces/IWETH.sol";

/**
 * @title WETH library
 * @notice Functions to swap tokens on WETH contract
 */
library WrappedNative {
    using SafeERC20 for IERC20;

    /**
     * @dev Swaps tokens on a WETH contract
     * @param from Address of a token to swap from
     * @param amountIn Amount of tokens to swap
     * @param swapData Swap operation details. The `data` field should be empty
     * @return amountOut Amount of tokens received
     */
    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        if (from == swapData.addr) {
            IWETH(swapData.addr).withdraw(amountIn);
        } else {
            IWETH(swapData.addr).deposit{ value: amountIn }();
        }
        amountOut = amountIn;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.7;

import "./interfaces/IWETH.sol";
import "./interfaces/IWowmaxRouter.sol";

import "./libraries/UniswapV2.sol";
import "./libraries/UniswapV3.sol";
import "./libraries/Curve.sol";
import "./libraries/PancakeSwapStable.sol";
import "./libraries/DODOV2.sol";
import "./libraries/DODOV1.sol";
import "./libraries/DODOV3.sol";
import "./libraries/Hashflow.sol";
import "./libraries/Saddle.sol";
import "./libraries/Wombat.sol";
import "./libraries/Level.sol";
import "./libraries/Fulcrom.sol";
import "./libraries/WooFi.sol";
import "./libraries/Elastic.sol";
import "./libraries/AlgebraV1.sol";
import "./libraries/SyncSwap.sol";
import "./libraries/Vooi.sol";
import "./libraries/VelocoreV2.sol";
import "./libraries/Iziswap.sol";
import "./libraries/Velodrome.sol";
import "./libraries/BalancerV2.sol";
import "./libraries/MaverickV1.sol";
import "./libraries/WrappedNative.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WowmaxSwapReentrancyGuard.sol";

/**
 * @title WOWMAX Router
 * @notice Router for stateless execution of swaps against multiple DEX protocols.
 *
 * The WowmaxRouter contract encompasses three primary responsibilities:
 * 1. Facilitating the exchange of user tokens based on a provided exchange route.
 * 2. Ensuring validation of the received output amounts for users, guaranteeing their alignment
 * within the designated slippage range.
 * 3. Transferring any surplus amounts to the treasury, thereby functioning as a service fee.
 *
 * The WowmaxRouter contract does not hold any tokens between swap operations. Tokens should not be transferred directly
 * to the contract. If, by any chance, tokens are transferred directly to the contract, they are most likely to be lost.
 */
contract WowmaxRouter is IWowmaxRouter, Ownable, WowmaxSwapReentrancyGuard {
    /**
     * @dev WETH contract
     */
    IWETH public WETH;

    /**
     * @dev Treasury address
     */
    address public treasury;

    /**
     * @dev Max fee percentage. All contract percentage values have two extra digits for precision. Default value is 1%
     */
    uint256 public maxFeePercentage = 100;

    /**
     * @dev Max allowed slippage percentage, default value is 20%
     */
    uint256 public maxSlippage = 2000;

    // Mapping of protocol names
    bytes32 internal constant UNISWAP_V2 = "UNISWAP_V2";
    bytes32 internal constant UNISWAP_V3 = "UNISWAP_V3";
    bytes32 internal constant UNISWAP_V2_ROUTER = "UNISWAP_V2_ROUTER";
    bytes32 internal constant CURVE = "CURVE";
    bytes32 internal constant DODO_V1 = "DODO_V1";
    bytes32 internal constant DODO_V2 = "DODO_V2";
    bytes32 internal constant DODO_V3 = "DODO_V3";
    bytes32 internal constant HASHFLOW = "HASHFLOW";
    bytes32 internal constant PANCAKESWAP_STABLE = "PANCAKESWAP_STABLE";
    bytes32 internal constant SADDLE = "SADDLE";
    bytes32 internal constant WOMBAT = "WOMBAT";
    bytes32 internal constant LEVEL = "LEVEL";
    bytes32 internal constant FULCROM = "FULCROM";
    bytes32 internal constant WOOFI = "WOOFI";
    bytes32 internal constant ELASTIC = "ELASTIC";
    bytes32 internal constant ALGEBRA_V1 = "ALGEBRA_V1";
    bytes32 internal constant ALGEBRA_V1_9 = "ALGEBRA_V1_9";
    bytes32 internal constant SYNCSWAP = "SYNCSWAP";
    bytes32 internal constant VOOI = "VOOI";
    bytes32 internal constant VELOCORE_V2 = "VELOCORE_V2";
    bytes32 internal constant IZISWAP = "IZISWAP";
    bytes32 internal constant VELODROME = "VELODROME";
    bytes32 internal constant BALANCER_V2 = "BALANCER_V2";
    bytes32 internal constant MAVERICK_V1 = "MAVERICK_V1";
    bytes32 internal constant WRAPPED_NATIVE = "WRAPPED_NATIVE";

    using SafeERC20 for IERC20;

    /**
     * @dev sets the WETH and treasury addresses
     */
    constructor(address _weth, address _treasury) {
        require(_weth != address(0), "WOWMAX: Wrong WETH address");
        require(_treasury != address(0), "WOWMAX: Wrong treasury address");

        WETH = IWETH(_weth);
        treasury = _treasury;
    }

    /**
     * @dev fallback function to receive native tokens
     */
    receive() external payable {}

    /**
     * @dev fallback function to process various protocols callback functions
     */
    fallback() external onlyDuringSwap {
        (bool success, int256 amount0Delta, int256 amount1Delta, bytes calldata data) = UniswapV3.decodeCallback({
            dataWithSelector: msg.data
        });
        require(success, "WOWMAX: unsupported callback");
        UniswapV3.invokeCallback(amount0Delta, amount1Delta, data);
    }

    // Admin functions

    /**
     * @dev withdraws tokens from a contract, in case of leftovers after a swap, invalid swap requests,
     * or direct transfers. Only callable by the owner.
     * @param token Token to be withdrawn
     * @param amount Amount to be withdrawn
     */
    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(treasury, amount);
    }

    /**
     * @dev withdraws native tokens from a contract, in case of leftovers after a swap or invalid swap requests.
     * Only callable by the owner.
     * @param amount Amount to be withdrawn
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        (bool sent, ) = payable(treasury).call{ value: amount }("");
        require(sent, "Wowmax: Failed to send native tokens");
    }

    /**
     * @dev sets the max fee percentage. Only callable by the owner.
     * @param _maxFeePercentage Max fee percentage
     */
    function setMaxFeePercentage(uint256 _maxFeePercentage) external onlyOwner {
        maxFeePercentage = _maxFeePercentage;
    }

    /**
     * @dev sets the max allowed slippage. Only callable by the owner.
     * @param _maxSlippage Max allowed slippage percentage
     */
    function setMaxSlippage(uint256 _maxSlippage) external onlyOwner {
        maxSlippage = _maxSlippage;
    }

    // Callbacks

    /**
     * @dev callback for Maverick V1 pools. Not allowed to be executed outside of a swap operation
     * @param amountToPay Amount to be paid
     * @param amountOut Amount to be received
     * @param data Additional data to be passed to the callback function
     */
    function swapCallback(uint256 amountToPay, uint256 amountOut, bytes calldata data) external onlyDuringSwap {
        MaverickV1.invokeCallback(amountToPay, amountOut, data);
    }

    /**
     * @dev callback for Algebra V1 pairs. Not allowed to be executed outside of a swap operation
     * @param amount0Delta Amount of token0 to be transferred to the caller
     * @param amount1Delta Amount of token1 to be transferred to the caller
     * @param data Additional data to be passed to the callback function
     */
    function algebraSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external onlyDuringSwap {
        AlgebraV1.invokeCallback(amount0Delta, amount1Delta, data);
    }

    /**
     * @notice Called to msg.sender in iZiSwapPool#swapX2Y(DesireY) call
     * @param x Amount of tokenX trader will pay
     * @param data Any dadta passed though by the msg.sender via the iZiSwapPool#swapX2Y(DesireY) call
     */
    function swapX2YCallback(uint256 x, uint256 /*y*/, bytes calldata data) external onlyDuringSwap {
        Iziswap.transferTokens(x, data);
    }

    /**
     * @notice Called to msg.sender in iZiSwapPool#swapY2X(DesireX) call
     * @param y Amount of tokenY trader will pay
     * @param data Any dadta passed though by the msg.sender via the iZiSwapPool#swapY2X(DesireX) call
     */
    function swapY2XCallback(uint256 /*x*/, uint256 y, bytes calldata data) external onlyDuringSwap {
        Iziswap.transferTokens(y, data);
    }

    /**
     * @notice Callback for DODO v3 Pools
     * @param token Token to be transferred to the caller
     * @param value Amount of tokens to be transferred to the caller
     * @param data Additional data to be passed to the callback function
     */
    function d3MMSwapCallBack(address token, uint256 value, bytes calldata data) external {
        DODOV3.invokeCallback(token, value, data);
    }

    // Swap functions

    /**
     * @inheritdoc IWowmaxRouter
     */
    function swap(
        ExchangeRequest calldata request
    ) external payable virtual override reentrancyProtectedSwap returns (uint256[] memory amountsOut) {
        amountsOut = _swap(request);
    }

    /**
     * @dev swap inner logic
     */
    function _swap(ExchangeRequest calldata request) internal returns (uint256[] memory amountsOut) {
        checkRequest(request);
        uint256 amountIn = receiveTokens(request);
        for (uint256 i = 0; i < request.exchangeRoutes.length; i++) {
            exchange(request.exchangeRoutes[i]);
        }
        amountsOut = sendTokens(request);

        emit SwapExecuted(
            msg.sender,
            request.from == address(0) ? address(WETH) : request.from,
            amountIn,
            request.to,
            amountsOut
        );
    }

    /**
     * @dev receives tokens from the caller
     * @param request Exchange request that contains the token to be received parameters.
     */
    function receiveTokens(ExchangeRequest calldata request) private returns (uint256) {
        uint256 amountIn;
        if (msg.value > 0 && request.from == address(0) && request.amountIn == 0) {
            amountIn = msg.value;
            WETH.deposit{ value: amountIn }();
        } else {
            if (request.amountIn > 0) {
                amountIn = request.amountIn;
                IERC20(request.from).safeTransferFrom(msg.sender, address(this), amountIn);
            }
        }
        return amountIn;
    }

    /**
     * @dev sends swapped received tokens to the caller and treasury
     * @param request Exchange request that contains output tokens parameters
     */
    function sendTokens(ExchangeRequest calldata request) private returns (uint256[] memory amountsOut) {
        amountsOut = new uint256[](request.to.length);
        uint256 amountOut;
        IERC20 token;
        for (uint256 i = 0; i < request.to.length; i++) {
            token = IERC20(request.to[i]);
            amountOut = token.balanceOf(address(this));

            uint256 feeAmount;
            if (amountOut > request.amountOutExpected[i]) {
                feeAmount = amountOut - request.amountOutExpected[i];
                uint256 maxFeeAmount = (amountOut * maxFeePercentage) / 10000;
                if (feeAmount > maxFeeAmount) {
                    feeAmount = maxFeeAmount;
                    amountsOut[i] = amountOut - feeAmount;
                } else {
                    amountsOut[i] = request.amountOutExpected[i];
                }
            } else {
                require(
                    amountOut >= (request.amountOutExpected[i] * (10000 - request.slippage[i])) / 10000,
                    "WOWMAX: Insufficient output amount"
                );
                amountsOut[i] = amountOut;
            }

            if (address(token) == address(WETH)) {
                WETH.withdraw(amountOut);
            }

            transfer(token, treasury, feeAmount);
            transfer(token, msg.sender, amountsOut[i]);
        }
    }

    /**
     * @dev transfers token to the recipient
     * @param token Token to be transferred
     * @param to Recipient address
     * @param amount Amount to be transferred
     */
    function transfer(IERC20 token, address to, uint256 amount) private {
        //slither-disable-next-line incorrect-equality
        if (amount == 0) {
            return;
        }
        if (address(token) == address(WETH)) {
            //slither-disable-next-line arbitrary-send-eth //recipient is either a msg.sender or a treasury
            (bool sent, ) = payable(to).call{ value: amount }("");
            require(sent, "Wowmax: Failed to send native tokens");
        } else {
            token.safeTransfer(to, amount);
        }
    }

    /**
     * @dev executes an exchange operation according to the provided route
     * @param exchangeRoute Route to be executed
     */
    function exchange(ExchangeRoute calldata exchangeRoute) private returns (uint256) {
        uint256 amountIn = IERC20(exchangeRoute.from).balanceOf(address(this));
        uint256 amountOut;
        for (uint256 i = 0; i < exchangeRoute.swaps.length; i++) {
            amountOut += executeSwap(
                exchangeRoute.from,
                (amountIn * exchangeRoute.swaps[i].part) / exchangeRoute.parts,
                exchangeRoute.swaps[i]
            );
        }
        return amountOut;
    }

    /**
     * @dev executes a swap operation according to the provided parameters
     * @param from Token to be swapped
     * @param amountIn Amount to be swapped
     * @param swapData Swap data that contains the swap parameters
     */
    function executeSwap(address from, uint256 amountIn, Swap calldata swapData) private returns (uint256) {
        if (swapData.family == UNISWAP_V3) {
            return UniswapV3.swap(amountIn, swapData);
        } else if (swapData.family == HASHFLOW) {
            return Hashflow.swap(from, amountIn, swapData);
        } else if (swapData.family == WOMBAT) {
            return Wombat.swap(from, amountIn, swapData);
        } else if (swapData.family == LEVEL) {
            return Level.swap(from, amountIn, swapData);
        } else if (swapData.family == DODO_V2) {
            return DODOV2.swap(from, amountIn, swapData);
        } else if (swapData.family == DODO_V3) {
            return DODOV3.swap(from, amountIn, swapData);
        } else if (swapData.family == WOOFI) {
            return WooFi.swap(from, amountIn, swapData);
        } else if (swapData.family == UNISWAP_V2) {
            return UniswapV2.swap(from, amountIn, swapData);
        } else if (swapData.family == CURVE) {
            return Curve.swap(from, amountIn, swapData);
        } else if (swapData.family == PANCAKESWAP_STABLE) {
            return PancakeSwapStable.swap(from, amountIn, swapData);
        } else if (swapData.family == DODO_V1) {
            return DODOV1.swap(from, amountIn, swapData);
        } else if (swapData.family == BALANCER_V2) {
            return BalancerV2.swap(from, amountIn, swapData);
        } else if (swapData.family == MAVERICK_V1) {
            return MaverickV1.swap(amountIn, swapData);
        } else if (swapData.family == SADDLE) {
            return Saddle.swap(from, amountIn, swapData);
        } else if (swapData.family == FULCROM) {
            return Fulcrom.swap(from, amountIn, swapData);
        } else if (swapData.family == UNISWAP_V2_ROUTER) {
            return UniswapV2.routerSwap(from, amountIn, swapData);
        } else if (swapData.family == ELASTIC) {
            return Elastic.swap(from, amountIn, swapData);
        } else if (swapData.family == ALGEBRA_V1) {
            return AlgebraV1.swap(from, amountIn, swapData);
        } else if (swapData.family == ALGEBRA_V1_9) {
            return AlgebraV1.swap(from, amountIn, swapData);
        } else if (swapData.family == SYNCSWAP) {
            return SyncSwap.swap(from, amountIn, swapData);
        } else if (swapData.family == VOOI) {
            return Vooi.swap(from, amountIn, swapData);
        } else if (swapData.family == VELOCORE_V2) {
            return VelocoreV2.swap(address(WETH), from, amountIn, swapData);
        } else if (swapData.family == IZISWAP) {
            return Iziswap.swap(from, amountIn, swapData);
        } else if (swapData.family == VELODROME) {
            return Velodrome.swap(from, amountIn, swapData);
        } else if (swapData.family == WRAPPED_NATIVE) {
            return WrappedNative.swap(from, amountIn, swapData);
        } else {
            revert("WOWMAX: Unknown DEX family");
        }
    }

    // Checks and verifications

    /**
     * @dev checks the swap request parameters
     * @param request Exchange request to be checked
     */
    function checkRequest(ExchangeRequest calldata request) private view {
        require(request.to.length > 0, "WOWMAX: No output tokens specified");
        require(request.to.length == request.amountOutExpected.length, "WOWMAX: Wrong amountOutExpected length");
        require(request.to.length == request.slippage.length, "WOWMAX: Wrong slippage length");
        for (uint256 i = 0; i < request.to.length; i++) {
            require(request.to[i] != address(0), "WOWMAX: Wrong output token address");
            require(request.amountOutExpected[i] > 0, "WOWMAX: Wrong amountOutExpected value");
            require(request.slippage[i] <= maxSlippage, "WOWMAX: Slippage is too high");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

/**
 * @dev Contract module that helps prevent reentrant swaps. Based on OpenZeppelin Contracts (last updated v4.8.0)
 * (security/ReentrancyGuard.sol)
 */
abstract contract WowmaxSwapReentrancyGuard {
    uint256 private constant _SWAP_IN_PROGRESS = 1;
    uint256 private constant _SWAP_NOT_IN_PROGRESS = 2;

    uint256 private _swapStatus;

    /**
     * @dev Prevents a contract from calling swap function again from within swap
     */
    modifier reentrancyProtectedSwap() {
        _beforeSwap();
        _;
        _afterSwap();
    }

    /**
     * @dev Prevents operation from being called outside of swap
     */
    modifier onlyDuringSwap() {
        require(_swapStatus == _SWAP_IN_PROGRESS, "WOWMAX: not allowed outside of swap");
        _;
    }

    constructor() {
        _swapStatus = _SWAP_NOT_IN_PROGRESS;
    }

    /**
     * @dev checks if swap is in progress and prevents reentrant calls
     */
    function _beforeSwap() private {
        require(_swapStatus != _SWAP_IN_PROGRESS, "WOWMAX: reentrant swap not allowed");
        _swapStatus = _SWAP_IN_PROGRESS;
    }

    /**
     * @dev sets swap status to not in progress
     */
    function _afterSwap() private {
        _swapStatus = _SWAP_NOT_IN_PROGRESS;
    }
}