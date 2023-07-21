/**
 *Submitted for verification at Arbiscan on 2023-07-20
*/

// Sources flattened with hardhat v2.16.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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

interface IDexPool {
    /* 
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    
    function owner() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    */
    function fees() external view returns(uint);
    function swap(uint _amountOut, address _to, address _tokenIn) external;
    function addLiquidity(address _to) external returns (uint shares);
    function removeLiquidity(address _to) external returns (uint amount0, uint amount1);
    function getLatestReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function getReserves(address _tokenIn) external view returns (IERC20 tokenIn, IERC20 tokenOut, uint reserveIn, uint reserveOut);
    function getTokensOutAmount(address _tokenIn, uint _amountIn) external view returns (uint amountOut);
    function getTokenPairRatio(address _tokenIn, uint _amountIn) external view returns (uint tokenOut);
    function transferFrom(address from, address to, uint256 amount ) external returns (bool);

}

interface IPoolFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function owner() external view returns (address);
    function getPairAddress(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB, uint fees) external returns (address pair);
}


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract DexRouter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    IPoolFactory public factory;
    address public immutable WETH;
    uint private constant factor = 10000;
    uint public constant _ownerFees = 10; //.1%

    event LogSwapETHForTokens(address _sender, uint _amountIn, address _tokenOut, address _poolAddress);
    event LogSwapTokensForETH(address _sender, uint _amountIn, address _tokenIn, address _poolAddress);
    event LogAddLiquidityETH(address _sender, address _token, uint _amountToken, address _poolAddress, uint _shares);
    event LogRemoveLiquidity(address _sender, address _tokenA, address _tokenB, uint _shares, uint _amountA, uint _amountB, address poolAddress);
    event LogRemoveLiquidityETH(address _sender, address _token, uint _shares, uint _amountToken, uint _amountETH);
    event LogAddTokenToTokenLiquidity(
        address _sender, 
        address _tokenA, 
        address _tokenB, 
        uint amountA, 
        uint amountB, 
        address poolAddress
    );

    event LogSwapTokensWithFees(
        address _sender, 
        address _tokenIn, 
        address _tokenOut, 
        address _poolAddress,
        uint _fees,
        uint _amountIn, 
        uint _amountOut
    );

    constructor(address _factory, address _weth) {
        require(_weth != address(0), "not valid weth address!");
        factory = IPoolFactory(_factory);
        WETH = _weth;
    }

    function setNewPoolFactory(address _factory)
        external
        onlyOwner
    {
        require(_factory != address(0), "zero address not allowed!");
        factory = IPoolFactory(_factory);
    }

    function _swapTokensWithFees(address _poolAddress, address _to, address _tokenIn, uint _amountIn) 
        internal
    {
        uint amountOut;

        amountOut = IDexPool(_poolAddress).getTokensOutAmount(_tokenIn, _amountIn);
        IDexPool(_poolAddress).swap(amountOut, _to, _tokenIn);
    }

    function swapTokensWithFees(
        address _tokenIn, 
        address _tokenOut, 
        uint _amountIn, 
        uint _minAmountOut
    )
        external
        nonReentrant
    {
        address to = msg.sender;
        require(_tokenIn != _tokenOut, "tokens should be different!");
        require(_tokenIn != address(0) && _tokenOut != address(0), "tokens should not be zero!");
        require(_amountIn > 0, "amount in should not be zero");

        address poolAddress = getPairAddress(_tokenIn, _tokenOut);

        uint _amountInWithOwnerFees = (_amountIn * _ownerFees)/factor;

        IERC20(_tokenIn).safeTransferFrom(to, owner(), _amountInWithOwnerFees);

        IERC20(_tokenIn).safeTransferFrom(to, poolAddress, (_amountIn - _amountInWithOwnerFees));

        uint balanceBefore = IERC20(_tokenOut).balanceOf(to);

        _swapTokensWithFees(poolAddress, to, _tokenIn, _amountIn);
        
        uint balanceAfter = IERC20(_tokenOut).balanceOf(to);
        uint amountOut = balanceAfter - balanceBefore;
        require( amountOut >= _minAmountOut, 'insufficient output amount');

        uint _fees = IDexPool(poolAddress).fees();
        emit LogSwapTokensWithFees(msg.sender, _tokenIn, _tokenOut, poolAddress, _fees, _amountIn, amountOut);
    }

    function swapETHForTokens(
        address _tokenOut,
        uint _minAmountOut
    )
        external
        payable
        nonReentrant
    {
        address to = msg.sender;
        require(_tokenOut != address(0), 'Zero address not allowed!');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value : amountIn}();

        address poolAddress = getPairAddress(WETH, _tokenOut);

        require(IWETH(WETH).transfer( poolAddress, amountIn), "weth transfer failed!");

        uint balanceBefore = IERC20(_tokenOut).balanceOf(to);

        _swapTokensWithFees(poolAddress, to, WETH, amountIn);

        uint balanceAfter = IERC20(_tokenOut).balanceOf(to);

        uint amountOut = balanceAfter - balanceBefore;

        require( amountOut >= _minAmountOut, 'insufficient output amount');

        emit LogSwapETHForTokens(msg.sender, msg.value, _tokenOut, poolAddress);
    }

    function swapTokensForETH(
        address _tokenIn,
        uint _amountIn,
        uint _minAmountOut
    )
        external
        nonReentrant
    {
        address to = msg.sender;
        require(_tokenIn != address(0), 'Zero address not allowed!');
        
        address poolAddress = getPairAddress(_tokenIn, WETH);

        IERC20(_tokenIn).safeTransferFrom(to, poolAddress, _amountIn);

        _swapTokensWithFees(poolAddress, address(this), _tokenIn, _amountIn);
        
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require( amountOut > 0, "amountOut is zero!");
        require( amountOut >= _minAmountOut, "insufficient output amount");

        IWETH(WETH).withdraw(amountOut);

        (bool success, ) = to.call{value: amountOut}("");
        require(success, "ETH transfer failed!");

        emit LogSwapTokensForETH(msg.sender, _amountIn, _tokenIn, poolAddress);
    }

    function addTokenToTokenLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountADesired,
        uint _amountBDesired,
        uint _amountAMin,
        uint _amountBMin
    ) 
        external
        nonReentrant
        returns (uint amountA, uint amountB, uint liquidity)
    {
        require(_tokenA != _tokenB, "tokens should be different!");
        require(_tokenA != address(0) && _tokenB != address(0), "token address should not be zero!");
        require(_amountADesired > 0, "TokenA amount is zero!");
        require(_amountBDesired > 0, "TokenB amount is zero!");

        address poolAddress = getPairAddress(_tokenA, _tokenB);
        require(poolAddress != address(0), "Token pool does not exist!");
        
        (amountA, amountB) = _getOptimalLiquidityAmount(_tokenA, _tokenB, _amountADesired, _amountBDesired, _amountAMin, _amountBMin);

        IERC20(_tokenA).safeTransferFrom(msg.sender, poolAddress, amountA);
        IERC20(_tokenB).safeTransferFrom(msg.sender, poolAddress, amountB);

        liquidity = IDexPool(poolAddress).addLiquidity(msg.sender);

        emit LogAddTokenToTokenLiquidity(msg.sender, _tokenA, _tokenB, amountA, amountB, poolAddress);
    }

    function addLiquidityETH(
            address _token,
            uint _amountTokenDesired,
            uint _amountTokenMin,
            uint _amountETHMin
        ) 
            external 
            payable
            nonReentrant
            returns (uint amountToken, uint amountETH, uint shares)
        {
        require(_amountTokenDesired > 0, "amount desired not equal to zero!");
        require(_token != address(0), "token address should not be zero!");
        require(msg.value > 0, "ether amount not equal to zero!");
        address to = msg.sender;
        address poolAddress = getPairAddress(_token, WETH);
        require(poolAddress != address(0), "Token pool does not exist!");

        (amountToken, amountETH) = _getOptimalLiquidityAmount(
            _token,
            WETH,
            _amountTokenDesired,
            msg.value,
            _amountTokenMin,
            _amountETHMin
        );
        
        IERC20(_token).safeTransferFrom(to, poolAddress, amountToken);
        IWETH(WETH).deposit{value : amountETH}();

        require(IWETH(WETH).transfer( poolAddress, amountETH), "weth transfer failed!");

        shares = IDexPool(poolAddress).addLiquidity(msg.sender);
        
        if (msg.value > amountETH){
            (bool status, ) = to.call{value: msg.value - amountETH}("");
            require(status, "transfer failed!");
        }

        emit LogAddLiquidityETH(msg.sender, _token, amountToken, poolAddress, shares);
    }

    function _getOptimalLiquidityAmount(
        address _tokenA,
        address _tokenB,
        uint _amountADesired,
        uint _amountBDesired,
        uint _amountAMin,
        uint _amountBMin
    ) internal view returns (uint amountA, uint amountB) {
        
        address poolAddress = getPairAddress(_tokenA, _tokenB);
        (,, uint reserveA, uint reserveB) = IDexPool(poolAddress).getReserves(_tokenA);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (_amountADesired, _amountBDesired);
        } else {
            uint amountBOptimal = getTokenPairRatio(_tokenA, _tokenB, _amountADesired);

            if (amountBOptimal <= _amountBDesired) {
                require(amountBOptimal >= _amountBMin, 'Insufficient TokenB amount!');
                (amountA, amountB) = (_amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = getTokenPairRatio(_tokenA, _tokenB, _amountBDesired);
                assert(amountAOptimal <= _amountADesired);
                require(amountAOptimal >= _amountAMin, 'Insufficient TokenB amount!');
                (amountA, amountB) = (amountAOptimal, _amountBDesired);
            }
        }
    }

    // **** Remove Liquidity ****
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint _shares,
        uint _amountAMin,
        uint _amountBMin,
        address _to
        ) 
            public 
            returns (uint amountA, uint amountB) 
    {

        address poolAddress = getPairAddress(_tokenA, _tokenB);
        require(poolAddress != address(0), "Token pool does not exist!");

        bool status = IDexPool(poolAddress).transferFrom(msg.sender, poolAddress, _shares);
        require(status, "transfer failed!");

        (uint amount0, uint amount1) = IDexPool(poolAddress).removeLiquidity(_to);

        (address token0, address token1) = sortTokens(_tokenA, _tokenB);

        (amountA, amountB) = _tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountA >= _amountAMin, 'TokenA amount not enough!');
        require(amountB >= _amountBMin, 'TokenB amount not enough!');

        emit LogRemoveLiquidity(msg.sender, token0, token1, _shares, amountA, amountB, poolAddress);
    }

    function removeLiquidityETH(
        address _token,
        uint _shares,
        uint _amountTokenMin,
        uint _amountETHMin,
        address _to
    )   
        external
        nonReentrant
        returns (uint amountToken, uint amountETH) 
    {
        (amountToken, amountETH) = removeLiquidity(
            _token,
            WETH,
            _shares,
            _amountTokenMin,
            _amountETHMin,
            address(this)
        );
        require(IERC20(_token).transfer(_to, amountToken), "transfer failed!");

        IWETH(WETH).withdraw(amountETH);
        
        (bool status, ) = _to.call{value: amountETH}("");
        require(status, "transfer failed!");

        emit LogRemoveLiquidityETH(msg.sender, _token, _shares, amountToken, amountETH);
    }

    function getTokenPairRatio(address _tokenA, address _tokenB, uint _amountIn)
        public
        view
        returns (uint amountOut)
    {
        address poolAddress = getPairAddress(_tokenA, _tokenB);
        (,, uint reserveIn, uint reserveOut) = IDexPool(poolAddress).getReserves(_tokenA);
        
        amountOut = reserveIn == 0 ? 0 : (reserveOut * _amountIn) / reserveIn;
    }

    function getTokenPairReserves(address _token0, address _token1)
        external
        view
        returns(uint amount0, uint amount1)
    {
        address poolAddress = getPairAddress(_token0, _token1);
        require(poolAddress != address(0), "pool does not exist!");

        (amount0, amount1, ) = IDexPool(poolAddress).getLatestReserves();
    }

    function sortTokens(address tokenA, address tokenB) 
        internal 
        pure 
        returns (address token0, address token1) 
    {
        require(tokenA != tokenB, 'tokens should be different!');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'zero address not allowed!');
    }

    function getTokenAmountOut(address _tokenIn, address _tokenOut, uint _amountIn) 
        external
        view
        returns (uint amountOut)
    {
        address poolAddress = getPairAddress(_tokenIn, _tokenOut);
        require(poolAddress != address(0), "pool does not exist!");

        amountOut = IDexPool(poolAddress).getTokensOutAmount(_tokenIn, _amountIn);
    }

    function getPairAddress(address _token0, address _token1)
        internal
        view
        returns(address poolAddress)
    {
        (address token0, address token1) = sortTokens(_token0, _token1);
        poolAddress = IPoolFactory(factory).getPairAddress(token0, token1);
        require(poolAddress != address(0), "pool does not exist!");
    }

    receive() 
        external 
        payable 
    {
        require(msg.sender == WETH);
    }
}