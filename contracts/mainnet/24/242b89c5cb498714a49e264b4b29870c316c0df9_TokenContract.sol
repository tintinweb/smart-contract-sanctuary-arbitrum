/**
 *Submitted for verification at Arbiscan.io on 2023-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit(uint256 amount) external;

    function process(uint256 gas) external;

    function purge(address receiver) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeERC20 for IERC20;

    address public immutable _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 public immutable REWARD;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public constant dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 30 * 60;
    uint256 public minDistribution = 1 * (10**9);

    uint256 public currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token, "caller is not the token contract");
        _;
    }

    constructor(address rewardToken) {
        _token = msg.sender;
        REWARD = IERC20(rewardToken);
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        require(_minPeriod <= minPeriod && _minPeriod != 0, "can not be greater than defined period");
        require(_minDistribution <= minDistribution && _minDistribution != 0, "can not be greater than defined distribution amount");
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function purge(
        address receiver
    ) external override onlyToken {
        require(receiver != address(0), "receiver can not be zero address");
        uint256 balance = REWARD.balanceOf(address(this));
        REWARD.safeTransfer(receiver, balance);
    }

    event SetShare(address indexed shareholder, uint256 amount);
    function setShare(
        address shareholder, 
        uint256 amount
    ) external override onlyToken{
        require(shareholder != address(0), "shareholder can not be zero address");

        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        emit SetShare(shareholder, amount);
    }

    event Deposit(uint256 amount);
    function deposit(
        uint256 amount
    ) external override onlyToken {
        totalDividends = totalDividends + amount;
        if(totalShares != 0 ) {
            /** 
            * dividendsPerShare is increasing and is only possible to change
            * when ERC20 token amount is deposited into this contract
            * @notice the equal distribution of the dividends will not be hampered as the distribution
            * is based on different parameters of shareholder like totalRealised, totalExcluded,
            * totalDividends 
            */
            dividendsPerShare = dividendsPerShare + ((dividendsPerShareAccuracyFactor * amount) / totalShares);
        }
        emit Deposit(amount);
    }

    event CurrentIndex(uint256 _currentIndex);
    function process(
        uint256 gas
    ) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 minGasRequired;

        uint256 iterations = 0; 

        uint256 _currentIndex = currentIndex;

        while (gasUsed < gas && gasLeft >= minGasRequired && iterations < shareholderCount) {
            if (_currentIndex >= shareholderCount) {
                _currentIndex = 0;
            }

            if (shouldDistribute(shareholders[_currentIndex])) {
                distributeDividend(shareholders[_currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            minGasRequired = gasLeft - gasleft();
            gasLeft = gasleft();
            _currentIndex++;
            iterations++;
        }

        currentIndex = _currentIndex;
        emit CurrentIndex(currentIndex);
    }

    function shouldDistribute(
        address shareholder
    )internal view returns (bool){
        return shareholderClaims[shareholder] + minPeriod < block.timestamp &&
                getUnpaidEarnings(shareholder) > minDistribution;
    }

    event DistributionIncomplete(address indexed account, uint256 amount);
    function distributeDividend(
        address shareholder
    ) internal {

        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed + amount;
            try REWARD.transfer(shareholder, amount){} catch {
                emit DistributionIncomplete(shareholder, amount);
            }
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend(address shareHolder) external {
        distributeDividend(shareHolder);
    }

    function getUnpaidEarnings(
        address shareholder
    ) public view returns (uint256){
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getHolderDetails(
        address holder
    ) public view returns (uint256 lastClaim,uint256 unpaidEarning,uint256 totalReward,uint256 holderIndex){
        lastClaim = shareholderClaims[holder];
        unpaidEarning = getUnpaidEarnings(holder);
        totalReward = shares[holder].totalRealised;
        holderIndex = shareholderIndexes[holder];
    }

    function getCumulativeDividends(
        uint256 share
    )internal view returns (uint256) {
        return
            (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return shareholders.length;
    }
    
    function getShareHoldersList() external view returns (address[] memory) {
        return shareholders;
    }

    function addShareholder(
        address shareholder
    ) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(
        address shareholder
    ) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        distributeDividend(shareholders[shareholders.length - 1]);
        shareholders.pop();
        delete(shareholderIndexes[shareholder]);
    }
}

interface ISmartRouter {
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

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract TokenContract is IERC20, Ownable {
    using SafeERC20 for IERC20;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant REWARD = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    ISmartRouter public SROUTER = ISmartRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    uint16 public smartPoolFee = 500;

    string private _name;
    string private _symbol;
    uint8 constant _decimals = 18;

    uint256 constant _totalSupply = 1_000_000_000 * (10 **_decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isDividendExempt;

    // buy fees
    uint256 public buyDividendRewardsFee = 5;
    uint256 public buyMarketingFee = 3;
    uint256 public buyDevFee = 2;
    uint256 public buyBurnFee = 0;
    uint256 public buyTotalFees = 10;
    // sell fees
    uint256 public sellDividendRewardsFee = 5;
    uint256 public sellMarketingFee = 3;
    uint256 public sellDevFee = 2;
    uint256 public sellBurnFee = 0;
    uint256 public sellTotalFees = 10;

    uint256 public transferFee = 0;

    address public marketingFeeReceiver = 0xC39b080AF11E8F221523059F5d55F10b505882Ed;
    address public devFeeReceiver = 0xfF7663C3865c25325DCc93935F0e7B617a1c1164;

    IUniswapV2Router02 public router;
    address public pair;

    DividendDistributor public immutable dividendDistributor;
    uint256 distributorGas = 700_000;

    event SendFeesInToken(address wallet, uint256 amount);
    event IncludeInReward(address holder);

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 10) / 100_000;//0.01%
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        router = IUniswapV2Router02(0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        dividendDistributor = new DividendDistributor(REWARD);
        isFeeExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(
        address account
    ) public view override returns (uint256) {
        return _balances[account];
    }

    // tracker dashboard functions
    function getHolderDetails(
        address holder
    ) external view returns (uint256,uint256,uint256,uint256){
        return dividendDistributor.getHolderDetails(holder);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendDistributor.currentIndex();
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return dividendDistributor.getNumberOfTokenHolders();
    }

    function totalDistributedRewards() external view returns (uint256) {
        return dividendDistributor.totalDistributed();
    }

    function allowance(
        address holder, 
        address spender
    ) external view override returns (uint256){
        return _allowances[holder][spender];
    }

    function approve(
        address spender, 
        uint256 amount
    ) public override returns (bool){
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address _owner, 
        address spender, 
        uint256 amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function transfer(
        address recipient, 
        uint256 amount
    ) external override returns (bool){
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) external override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        return _transferFrom(sender, recipient, amount);
    }

    event ProcessFailed(uint256 gas);
    function _transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "sender can not be zero address");
        require(recipient != address(0), "recipient can not be zero address");
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (shouldSwapBack()) {
            swapBackInETH();
        }
        //Exchange tokens
        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount, recipient) : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;
        // Dividend tracker
        if (!isDividendExempt[sender]) {
            dividendDistributor.setShare(sender, _balances[sender]);
        }
        if (!isDividendExempt[recipient]) {
            dividendDistributor.setShare(recipient, _balances[recipient]);
        }
        try dividendDistributor.process(distributorGas) {} catch {emit ProcessFailed(distributorGas);}
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender, 
        address recipient, 
        uint256 amount
    ) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(
        address sender, 
        address recipient
    ) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function takeFee(
        address sender, 
        uint256 amount, 
        address to
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        uint256 burnFee = 0;
        if (to == pair) {
            feeAmount = (amount * sellTotalFees) / 100;
            if (sellBurnFee > 0 && sellTotalFees != 0) {
                burnFee = (feeAmount * sellBurnFee) / sellTotalFees;
                _balances[DEAD] = _balances[DEAD] + burnFee;
                emit Transfer(sender, DEAD, burnFee);
            }
        } else if(sender == pair){
            feeAmount = (amount * buyTotalFees) / 100;
            if (buyBurnFee > 0 && buyTotalFees != 0) {
                burnFee = (feeAmount * buyBurnFee) / buyTotalFees;
                _balances[DEAD] = _balances[DEAD] + burnFee;
                emit Transfer(sender, DEAD, burnFee);
            }
        } else {
            feeAmount = (amount * transferFee) / 100;
        }
        if(feeAmount > 0) {
            uint256 feesToContract = feeAmount - burnFee;
            _balances[address(this)] = _balances[address(this)] + feesToContract;
            emit Transfer(sender, address(this), feesToContract);
        }
        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    event ClearStuckBalance(uint256 amountPercentage);
    function clearStuckBalance(
        uint256 amountPercentage
    ) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
        emit ClearStuckBalance(amountPercentage);
    }

    event UpdateBuyFees(uint256 reward, uint256 marketing, uint256 dev, uint256 burn);
    function updateBuyFees(
        uint256 reward, 
        uint256 marketing, 
        uint256 dev, 
        uint256 burn
    ) external onlyOwner {
        uint256 _buyTotalFees = reward + marketing + dev + burn;
        require(_buyTotalFees <= 10, "total fee exceeds 10%");
        buyTotalFees = _buyTotalFees;
        buyDividendRewardsFee = reward;
        buyMarketingFee = marketing;
        buyDevFee = dev;
        buyBurnFee = burn;
        emit UpdateBuyFees(reward, marketing, dev, dev);
    }

    event UpdateSellFees(uint256 reward, uint256 marketing, uint256 dev, uint256 burn);
    function updateSellFees(
        uint256 reward, 
        uint256 marketing, 
        uint256 dev, 
        uint256 burn
    ) external onlyOwner {
        uint256 _sellTotalFees = reward + marketing + dev + burn;
        require(_sellTotalFees <= 10, "total fee exceeds 10%");
        sellTotalFees = _sellTotalFees;
        sellDividendRewardsFee = reward;
        sellMarketingFee = marketing;
        sellDevFee = dev;
        sellBurnFee = burn;
        emit UpdateSellFees(reward, marketing, dev, burn);
    }

    event Purged(address indexed purgedBy, uint256 timestamp);
    function purgeBeforeSwitch() external onlyOwner {
        dividendDistributor.purge(msg.sender);
        emit Purged(msg.sender, block.timestamp);
    }

    function includeMeinRewards() external {
        require(
            !isDividendExempt[msg.sender],
            "You are not allowed to get rewards"
        );
        try
            dividendDistributor.setShare(msg.sender, _balances[msg.sender])
        {} catch {}
        emit IncludeInReward(msg.sender);
    }

    // manual claim for the greedy humans
    event UpdateRewardClaimed(address indexed account);
    function claimRewards(
        bool tryAll
    ) external {
        dividendDistributor.claimDividend(msg.sender);
        if (tryAll) {
            try dividendDistributor.process(distributorGas) {} catch {emit ProcessFailed(distributorGas);}
        }

        emit UpdateRewardClaimed(msg.sender);
    }

    // manually clear the queue
    event UpdateClaimProcessed(address indexed by);
    function claimProcess() external {
        try dividendDistributor.process(distributorGas) {} catch {emit ProcessFailed(distributorGas);}
        emit UpdateClaimProcessed(msg.sender);
    }

    function swapBackInETH() internal swapping {
        uint256 contractTokenBalance = _balances[address(this)];
        uint256 tokensToReward;
        if(sellTotalFees != 0) {
            tokensToReward = (contractTokenBalance * sellDividendRewardsFee) / sellTotalFees;
        }
        // calculate tokens amount to swap
        uint256 tokensToSwap = contractTokenBalance - tokensToReward;
        // swap the tokens
        if(tokensToSwap != 0) {
            swapTokensForEth(tokensToSwap);
        }
        // get swapped ETH amount
        uint256 swappedETHAmount = address(this).balance;
        uint256 totalSwapFee = sellMarketingFee + sellDevFee;
        uint256 marketingFeeETH;
        if(totalSwapFee != 0) {
            marketingFeeETH = (swappedETHAmount * sellMarketingFee) / totalSwapFee;
        }
        uint256 devFeeETH = swappedETHAmount - marketingFeeETH;
        if (marketingFeeETH != 0) {
            (bool success_mar, ) = marketingFeeReceiver.call{value: marketingFeeETH}("");
            require(success_mar, "ETH transfer to marketing wallet failed.");
        }
        if (devFeeETH != 0) {
            (bool success_dev, ) = devFeeReceiver.call{value: devFeeETH}("");
            require(success_dev, "ETH transfer to dev wallet failed"); 
        }

        // calculate reward ETH amount
        if (tokensToReward != 0) {
            swapUsingSmartRouter(tokensToReward);
            uint256 swappedTokensAmount = IERC20(REWARD).balanceOf(address(this));
            // send ETH to reward
            if(swappedTokensAmount != 0) {
                IERC20(REWARD).safeTransfer(address(dividendDistributor),swappedTokensAmount);
                dividendDistributor.deposit(swappedTokensAmount);
            }
        }
    }

    function swapTokensForEth(
        uint256 tokenAmount
    ) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    event SetDividendExempt(address indexed holder, bool exempt);
    function setIsDividendExempt(
        address holder, 
        bool exempt
    ) external onlyOwner{
        require(
            holder != address(this) && 
            holder != pair && 
            holder != address(0), 
            "holder can not be any of token, pair and zero address"
        );

        require(holder != DEAD, "holder is a dead address");
        isDividendExempt[holder] = exempt;
        if (exempt) {
            dividendDistributor.setShare(holder, 0);
        } else {
            dividendDistributor.setShare(holder, _balances[holder]);
        }

        emit SetDividendExempt(holder, exempt);
    }

    event SetFeeExempt(address indexed holder, bool exempt);
    function setIsFeeExempt(
        address holder, 
        bool exempt
    ) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetFeeExempt(holder, exempt);
    }

    event UpdateFeeReceivers(address _marketingFeeReceiver, address _devFeeReceiver);
    function setFeeReceivers(
        address _marketingFeeReceiver, 
        address _devFeeReceiver
    ) external onlyOwner {
        require(_marketingFeeReceiver != address(0), "wallet can not be 0 address");
        require(_devFeeReceiver != address(0), "wallet can not be 0 address");
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
        emit UpdateFeeReceivers(_marketingFeeReceiver, _devFeeReceiver);
    }

    event UpdateSwapBackSettings(bool _enable, uint256 _amount);
    function setSwapBackSettings(
        bool _enabled, 
        uint256 _amount
    ) external onlyOwner{
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit UpdateSwapBackSettings(_enabled, _amount);
    }

    event UpdateDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution);
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        dividendDistributor.setDistributionCriteria(_minPeriod, _minDistribution);
        emit UpdateDistributionCriteria(_minPeriod, _minDistribution);
    }

    event UpdateDistributorSettings(uint256 gas);
    function setDistributorSettings(
        uint256 gas
    ) external onlyOwner {
        require(gas < 3_000_000, "gas must be less than defined amount");
        distributorGas = gas;
        emit UpdateDistributorSettings(gas);
    }

    event UpdateTransferFee(uint256 _transferfee);
    function updateTransferFee(
        uint256 _transferfee
    ) external onlyOwner {
        require(_transferfee <= 10, "transfer fee limit");
        transferFee = _transferfee;
        emit UpdateTransferFee(_transferfee);
    }

    function swapUsingSmartRouter(
        uint256 rewardTokenAmount
    ) internal {
        swapTokensForEth(rewardTokenAmount);
        uint256 amountEthToSwap = address(this).balance;
        if(amountEthToSwap != 0) {
            ISmartRouter.ExactInputSingleParams memory params = ISmartRouter.ExactInputSingleParams(
                WETH,
                REWARD,
                smartPoolFee,
                address(this),
                block.timestamp,
                amountEthToSwap,
                0,
                0
            );
            uint256 swapedAmount = SROUTER.exactInputSingle{value: amountEthToSwap}(params);
            require(swapedAmount != 0, "Swapped reward token is zero");
        }
        
    }

    event SetSmartRouter(address indexed _routerAddress, uint16 _smartFee);
    function setSmartRouter(
        address _routerAddress,
        uint16 _smartPoolFee
    ) external onlyOwner {
        SROUTER = ISmartRouter(_routerAddress);
        smartPoolFee = _smartPoolFee;
        emit SetSmartRouter(_routerAddress, _smartPoolFee);
    }

}