// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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

// SPDX-License-Identifier: GLP-v3.0

pragma solidity ^0.8.4;

import "../libraries/GnosisSafeStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/crosschain/IStargateRouter.sol";
import "../interfaces/crosschain/IStargateReceiver.sol";
import "../interfaces/crosschain/IGnosisSafe.sol";
import "../interfaces/crosschain/IGnosisSafeProxyFactory.sol";
import "../interfaces/crosschain/UserOperation.sol";
import "../interfaces/crosschain/IStargateEthVault.sol";
import "../interfaces/crosschain/IModule.sol";
import "../interfaces/crosschain/IAvaultRouter.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '../libraries/BytesLib.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/crosschain/PermitStruct.sol";

contract AvaultRouter_ARBITRUM is GnosisSafeStorage, IStargateReceiver, IAvaultRouter, Ownable {
    using SafeERC20 for IERC20;
    using BytesLib for bytes;

    mapping (address=>address) public userSafe; // cache use's safe address
    mapping (uint=>bytes) public chainIdToSGReceiver; // destChainId => sgReceiver, constrain for safety

    // SAFEPROXY_CREATIONCODE: https://arbiscan.io/address/0xa6b71e26c5e0845f74c812102ca7114b6a896ab2#readContract#F1
    // bytes public constant SAFEPROXY_CREATIONCODE = 0x60806040523480156100105760....70726f7669646564;
    // keccak256(abi.encodePacked(SAFEPROXY_CREATIONCODE, abi.encode(SAFE_SINGLETON)))
    bytes32 private constant BYTECODE_HASH = 0xcaf2dc2f91b804b2fcf1ed3a965a1ff4404b840b80c124277b00a43b4634b2ce;
    address private constant SAFE_SINGLETON = 0x3E5c63644E683549055b9Be8653de26E0B4CD36E;
    address private constant SAFE_FACTORY = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;
    address private constant SAFE_CALLBACK = 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4;
    address private constant SGETH = 0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0;
    address private constant STARGATE_ROUTER = 0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614;
    ISwapRouter private constant UNISWAP_ROUTER = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    address private constant MODULE = 0x0Aaf347F50b766cA85dB70f9e2B0E178E9a16F4D;
    bytes private constant ENABLE_MODULE_ENCODED = hex"610b59250000000000000000000000000Aaf347F50b766cA85dB70f9e2B0E178E9a16F4D"; //abi.encodeWithSelector(IGnosisSafe.enableModule.selector, MODULE)

    uint private constant ADDRESS_ENCODE_LENGTH = 32;
    uint private constant ADDR_SIZE = 20;
    uint private constant ETH_POOL_ID = 13;
    address private constant SENTINEL_MODULES = address(0x1);
    uint private constant MAX_SLIPPAGE = 10000;

    uint public constant SALT_NONCE = 0;
    uint private constant UNISWAP_MIN_OUTPUT = 100000; // refer to 0.1 USDC

    event EXEC_ERROR(address srcAddress, string reason);
    event EXEC_PANIC(address srcAddress, uint errorCode);
    event EXEC_REVERT(address srcAddress, bytes lowLevelData);
    event SET_SGRECEIVER(uint indexed _chainId, address _sgReceiver);
    event EnabledModule(address module);

    // this contract needs to accept ETH
    receive() external payable {}

    function crossAssetCallNative(
        uint dstChainId,                      // Stargate/LayerZero chainId
        address payable _refundAddress,                     // message refund address if overpaid
        uint amountIn,                    // exact amount of native token coming in on source
        uint _maxSlippagePercent,              //  bridge slippage, 1 = 0.01%. Could be set arbitrary
        uint _dstGasForCall,             // gas for destination Stargate Router (including sgReceive). get from Config.
        bytes memory payload            // (address _srcAddress, UserOperation memory _uo) = abi.decode(_payload, (address, UserOperation));
    )external payable{
        require(amountIn > 0, "amountIn must be greater than 0");
        require(msg.value > amountIn, "stargate requires fee to pay crosschain message");
        
        // wrap the ETH into SGETH
        IStargateEthVault(SGETH).deposit{value: amountIn}();
        IStargateEthVault(SGETH).approve(STARGATE_ROUTER, amountIn);

        // messageFee is the remainder of the msg.value after wrap
        // STARGATE_ROUTER.quoteLayerZeroFee(..._dstGasForCall...)
        uint256 messageFee = msg.value - amountIn;
        // compose a stargate swap() using the WETH that was just wrapped
        bytes memory _sgReceiver = chainIdToSGReceiver[dstChainId];
        require(_sgReceiver.length > 0, "invalid chainId");
        IStargateRouter(STARGATE_ROUTER).swap{value: messageFee}(
            uint16(dstChainId),                        // destination Stargate chainId
            ETH_POOL_ID,                             // WETH Stargate poolId on source
            ETH_POOL_ID,                             // WETH Stargate poolId on destination
            _refundAddress,                     // message refund address if overpaid
            amountIn,                          // the amount in Local Decimals to swap()
            amountIn * (MAX_SLIPPAGE - _maxSlippagePercent) / MAX_SLIPPAGE,  // < amountIn - StargateFeeLibraryV02.getFees(...)
            IStargateRouter.lzTxObj(_dstGasForCall, 0, ""),
            _sgReceiver,         // destination address, the sgReceive() implementer
            payload                           // empty payload, since sending to EOA
        );
        
    }

    function crossAssetCallWithPermit(
        bytes memory _path,             //uniswap exactIn path. e.g. abi.enodePacked(UNI, 0.3%, WETH, 0.05%, USDC) or abi.encodePacked(USDC)
        uint dstChainId,                      // Stargate/LayerZero chainId
        uint srcPoolId,                       // stargate poolId, scrToken should be USDC or USDT...
        uint dstPoolId,                       // stargate destination poolId, destToken could be USDC, USDT, BUSD or other stablecoin.
        address payable _refundAddress,                     // message refund address if overpaid
        uint amountIn,                    // exact amount of native token coming in on source
        uint _maxSlippagePercent,              //  1 = 0.01%. Could be set arbitrary
        uint _dstGasForCall,             // gas for destination Stargate Router (including sgReceive)
        bytes memory payload,        // (address _srcAddress, UserOperation memory _uo) = abi.decode(_payload, (address, UserOperation));
        PermitStruct calldata _permit
    ) external payable{
        IERC20Permit(_path.toAddress(0)).permit(msg.sender, address(this), amountIn, _permit.deadline, _permit.v, _permit.r, _permit.s);
        crossAssetCall(
            _path,             //uniswap exactIn path. e.g. abi.enodePacked(UNI, 0.3%, WETH, 0.05%, USDC) or abi.encodePacked(USDC)
            dstChainId,                      // Stargate/LayerZero chainId
            srcPoolId,                       // stargate poolId, scrToken should be USDC or USDT...
            dstPoolId,                       // stargate destination poolId, destToken could be USDC, USDT, BUSD or other stablecoin.
            _refundAddress,                     // message refund address if overpaid
            amountIn,                    // exact amount of native token coming in on source
            _maxSlippagePercent,              //  1 = 0.01%. Could be set arbitrary
            _dstGasForCall,             // gas for destination Stargate Router (including sgReceive)
            payload        // (address _srcAddress, UserOperation memory _uo) = abi.decode(_payload, (address, UserOperation));
        );
    }

    //-----------------------------------------------------------------------------------------------------------------------
    // bridge asset and calldata, DO NOT call this if you don't know its meaning.
    function crossAssetCall(
        bytes memory _path,             //uniswap exactIn path. e.g. abi.enodePacked(UNI, 0.3%, WETH, 0.05%, USDC) or abi.encodePacked(USDC)
        uint dstChainId,                      // Stargate/LayerZero chainId
        uint srcPoolId,                       // stargate poolId, scrToken should be USDC or USDT...
        uint dstPoolId,                       // stargate destination poolId, destToken could be USDC, USDT, BUSD or other stablecoin.
        address payable _refundAddress,                     // message refund address if overpaid
        uint amountIn,                    // exact amount of native token coming in on source
        uint _maxSlippagePercent,              //  1 = 0.01%. Could be set arbitrary
        uint _dstGasForCall,             // gas for destination Stargate Router (including sgReceive)
        bytes memory payload        // (address _srcAddress, UserOperation memory _uo) = abi.decode(_payload, (address, UserOperation));
    ) public payable{
        require(msg.value > 0, "gas fee required");
        require(amountIn > 0, 'amountIn == 0');

        address _srcBridgeToken;
        uint _srcBridgeTokenAmount;
        {
            // user approved token
            address _userToken = _path.toAddress(0);
            IERC20(_userToken).safeTransferFrom(msg.sender, address(this), amountIn);
            
            //swap if need
            _srcBridgeToken = _path.toAddress(_path.length - ADDR_SIZE);
            if(_srcBridgeToken != _userToken){
                IERC20(_userToken).safeIncreaseAllowance(address(UNISWAP_ROUTER), amountIn);
                ISwapRouter.ExactInputParams memory _t = ISwapRouter.ExactInputParams(_path, address(this), block.timestamp + 10, amountIn, UNISWAP_MIN_OUTPUT);
                _srcBridgeTokenAmount = UNISWAP_ROUTER.exactInput(_t);
            }else{
                _srcBridgeTokenAmount = amountIn;
            }
        }

        IERC20(_srcBridgeToken).approve(STARGATE_ROUTER, _srcBridgeTokenAmount);
        IStargateRouter.lzTxObj memory _lzTxObj = IStargateRouter.lzTxObj(_dstGasForCall, 0, "0x");
        bytes memory _sgReceiver = chainIdToSGReceiver[dstChainId];
        require(_sgReceiver.length > 0, "invalid chainId");
        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(STARGATE_ROUTER).swap{value:msg.value}(
            uint16(dstChainId),                                     // the destination chain id
            srcPoolId,                                      // the source Stargate poolId
            dstPoolId,                                      // the destination Stargate poolId
            _refundAddress,                            // refund adddress. if msg.sender pays too much gas, return extra eth
            _srcBridgeTokenAmount,                                   // total tokens to send to destination chain
            _srcBridgeTokenAmount * (MAX_SLIPPAGE - _maxSlippagePercent) / MAX_SLIPPAGE,  // minimum
            _lzTxObj,       // 500,000 for the sgReceive()
            _sgReceiver,         // destination address, the sgReceive() implementer
            payload                                            // bytes payload
        );
    }

    //-----------------------------------------------------------------------------------------------------------------------
    // sgReceive() - the destination contract must implement this function to receive the tokens and payload
    function sgReceive(uint16 /*_chainId*/, bytes memory /*_sgBridgeAddress*/, uint /*_nonce*/, address _token, uint amountLD, bytes memory _payload) override external {
        require(msg.sender == STARGATE_ROUTER, "only stargate router can call sgReceive!");

        address _srcAddress;
        UserOperation memory _uo;
        if(_payload.length <= ADDRESS_ENCODE_LENGTH){
            (_srcAddress) = abi.decode(_payload, (address));
        }else{
            (_srcAddress, _uo) = abi.decode(_payload, (address, UserOperation));
        }
        
        address _safe = userSafe[_srcAddress];
        if(_safe == address(0)){
            //calculate safe address
            bytes memory _initializer;
            (_safe, _initializer) = computeSafeAddress(_srcAddress);

            uint _size;
            assembly {
                _size := extcodesize(_safe)
            }
            if(_size == 0){
                //the _safe hasn't created, create it
                address _s = IGnosisSafeProxyFactory(SAFE_FACTORY).createProxyWithNonce(SAFE_SINGLETON, _initializer, SALT_NONCE);
                require(_safe == _s, "create safe error");
            }
            userSafe[_srcAddress] = _safe;
        }
        
        //transfer token to _safe
        if(_token == SGETH){
            (bool _success,) = _safe.call{value: amountLD}("");
            require(_success, "ETH transfer fail");
        }else{
            IERC20(_token).safeTransfer(_safe, amountLD);
        }

        if(_payload.length > ADDRESS_ENCODE_LENGTH){
            //try exec UO to _safe
            try IModule(MODULE).exec(_safe, _srcAddress, _uo){

            } catch Error(string memory reason) {
                // This is executed in case
                // revert was called inside execUO
                // and a reason string was provided.
                emit EXEC_ERROR(_srcAddress, reason);
            } catch Panic(uint errorCode) {
                // This is executed in case of a panic,
                // i.e. a serious error like division by zero
                // or overflow. The error code can be used
                // to determine the kind of error.
                emit EXEC_PANIC(_srcAddress, errorCode);
            } catch (bytes memory lowLevelData) {
                // This is executed in case revert() was used.
                emit EXEC_REVERT(_srcAddress, lowLevelData);
            }
        }
    }

    function computeSafeAddress(address _srcAddress) public view returns (address _safeAddr, bytes memory _initializer){
        address[] memory _owners = new address[](1);
        _owners[0] = _srcAddress;
        _initializer = abi.encodeWithSelector(IGnosisSafe.setup.selector, _owners, uint256(1), address(this), ENABLE_MODULE_ENCODED, SAFE_CALLBACK, address(0), 0, address(0));
        bytes32 _salt = keccak256(abi.encodePacked(keccak256(_initializer), SALT_NONCE));
        _safeAddr = computeAddress(_salt, BYTECODE_HASH, SAFE_FACTORY);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) public pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }

    function setSGReceiver(uint _chainId, address _sgReceiver) external onlyOwner{
        chainIdToSGReceiver[_chainId] = abi.encodePacked(_sgReceiver);
        emit SET_SGRECEIVER(_chainId, _sgReceiver);
    }

    function getStuckToken(address _token) external onlyOwner{
        if(_token == address(0)){
            //native token
            payable(msg.sender).transfer(address(this).balance);
        }else{
            IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
        }
    }

    /// @dev Allows to add a module to the safe's whitelist.
    ///      This can only be done via the Safe's delegatecall
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) external {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "AGS101");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: GLP-v3.0

pragma solidity ^0.8.4;


interface IAvaultRouter{
    function SALT_NONCE() external view returns(uint);
    function computeSafeAddress(address _srcAddress) external view returns (address _safeAddr, bytes memory _initializer);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./Enum.sol";

interface IGnosisSafe {
    function isOwner(address owner) external view returns (bool);

    function getThreshold() external view returns (uint256);

    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool);

    function enableModule(address module) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface IGnosisSafeProxyFactory {
    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) external returns (address proxy);
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.
pragma solidity >=0.7.0 <0.9.0;

import "./Enum.sol";
import "./UserOperation.sol";

interface IModule {
    function exec(
        address avatar,
        address srcAddress,
        UserOperation calldata uo
    ) external returns (bool success);

    function nonces(address avatar) external view returns (uint256);

}

pragma solidity ^0.8.0;

interface IStargateEthVault {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address guy, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.4;

struct PermitStruct{
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./Enum.sol";

struct UserOperation{
        uint256 toChainId;
        address to;
        uint256 value;
        bytes data;
        address gasToken;
        uint256 gasTokenAmount;
        Enum.Operation operation;
        uint8 v;
        bytes32 r;
        bytes32 s;
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.9.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title GnosisSafeStorage - Storage layout of the Safe contracts to be used in libraries
/// @author Richard Meissner - <[email protected]>
contract GnosisSafeStorage {
    // From /common/Singleton.sol
    address internal singleton;
    // From /common/ModuleManager.sol
    mapping(address => address) internal modules;
    // From /common/OwnerManager.sol
    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    // From /GnosisSafe.sol
    uint256 internal nonce;
    bytes32 internal _deprecatedDomainSeparator;
    mapping(bytes32 => uint256) internal signedMessages;
    mapping(address => mapping(bytes32 => uint256)) internal approvedHashes;
}