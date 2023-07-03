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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

library ErrorsV1 {
    //OrangeAlphaVault
    string public constant ONLY_HELPER = "101";
    string public constant ONLY_STRATEGISTS = "103";
    string public constant ONLY_CALLBACK_CALLER = "104";
    string public constant INVALID_TICKS = "105";
    string public constant INVALID_AMOUNT = "106";
    string public constant INVALID_DEPOSIT_AMOUNT = "107";
    string public constant SURPLUS_ZERO = "108";
    string public constant LESS_AMOUNT = "109";
    string public constant LESS_LIQUIDITY = "110";
    string public constant HIGH_SLIPPAGE = "111";
    string public constant EQUAL_COLLATERAL_OR_DEBT = "112";
    string public constant NO_NEED_FLASH = "113";
    string public constant ONLY_BALANCER_VAULT = "114";
    string public constant INVALID_FLASHLOAN_HASH = "115";
    string public constant LESS_MAX_ASSETS = "116";

    //OrangeValidationChecker
    string public constant MERKLE_ALLOWLISTED = "201";
    string public constant CAPOVER = "202";
    string public constant LOCKUP = "203";

    //OrangeStrategyImplV1

    //OrangeAlphaParameters
    string public constant INVALID_PARAM = "301";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

/// @notice Modern and gas efficient ERC20 implementation.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract OrangeERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function decimals() external view virtual returns (uint8);

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {IERC20} from "../libs/BalancerFlashloan.sol";
import {IOrangeParametersV1} from "../interfaces/IOrangeParametersV1.sol";
import {IOrangeStorageV1} from "../interfaces/IOrangeStorageV1.sol";
import {OrangeERC20, IERC20Decimals} from "./OrangeERC20.sol";

abstract contract OrangeStorageV1 is IOrangeStorageV1, OrangeERC20 {
    struct DepositType {
        uint256 assets;
        uint40 timestamp;
    }

    //OrangeVault
    int24 public lowerTick;
    int24 public upperTick;
    bool public hasPosition;
    bytes32 public flashloanHash; //cache flashloan hash to check validity

    /* ========== PARAMETERS ========== */
    address public liquidityPool;
    address public lendingPool;
    IERC20 public token0; //collateral and deposited currency by users
    IERC20 public token1; //debt and hedge target token
    IOrangeParametersV1 public params;
    address public router;
    uint24 public routerFee;
    address public balancer;

    function decimals() public view override returns (uint8) {
        return IERC20Decimals(address(token0)).decimals();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {OrangeStorageV1, OrangeERC20} from "./OrangeStorageV1.sol";

//interafaces
import {IOrangeParametersV1} from "../interfaces/IOrangeParametersV1.sol";
import {IOrangeVaultV1} from "../interfaces/IOrangeVaultV1.sol";
import {ILiquidityPoolManager} from "../interfaces/ILiquidityPoolManager.sol";
import {ILendingPoolManager} from "../interfaces/ILendingPoolManager.sol";

//libraries
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UniswapRouterSwapper, ISwapRouter} from "../libs/UniswapRouterSwapper.sol";
import {BalancerFlashloan, IBalancerVault, IBalancerFlashLoanRecipient, IERC20} from "../libs/BalancerFlashloan.sol";
import {ErrorsV1} from "./ErrorsV1.sol";

contract OrangeStrategyImplV1 is OrangeStorageV1 {
    using SafeERC20 for IERC20;
    using UniswapRouterSwapper for ISwapRouter;
    using BalancerFlashloan for IBalancerVault;

    constructor() OrangeERC20("OrangeStrategyImplV1", "OrangeStrategyImplV1") {}

    /* ========== EXTERNAL FUNCTIONS ========== */
    function rebalance(
        int24 _newLowerTick,
        int24 _newUpperTick,
        IOrangeVaultV1.Positions memory _targetPosition,
        uint128 _minNewLiquidity
    ) external {
        int24 _currentLowerTick = lowerTick;
        int24 _currentUpperTick = upperTick;

        // update storage of ranges
        lowerTick = _newLowerTick;
        upperTick = _newUpperTick;
        hasPosition = true;

        // validation of tickSpacing
        ILiquidityPoolManager(liquidityPool).validateTicks(_newLowerTick, _newUpperTick);

        // 1. burn and collect fees
        uint128 _liquidity = ILiquidityPoolManager(liquidityPool).getCurrentLiquidity(
            _currentLowerTick,
            _currentUpperTick
        );
        ILiquidityPoolManager(liquidityPool).burnAndCollect(_currentLowerTick, _currentUpperTick, _liquidity);

        // 2. get current position
        IOrangeVaultV1.Positions memory _currentPosition = IOrangeVaultV1.Positions(
            ILendingPoolManager(lendingPool).balanceOfCollateral(),
            ILendingPoolManager(lendingPool).balanceOfDebt(),
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );

        // 3. execute hedge
        _executeHedgeRebalance(_currentPosition, _targetPosition);

        // 4. add liquidity
        uint128 _addedLiquidity = _addLiquidityInRebalance(
            _newLowerTick,
            _newUpperTick,
            _targetPosition.token0Balance, // amount of token0 to be added to Uniswap
            _targetPosition.token1Balance // amount of token1 to be added to Uniswap
        );

        // check if rebalance has done as expected or not
        if (_addedLiquidity < _minNewLiquidity) {
            revert(ErrorsV1.LESS_LIQUIDITY);
        }

        // emit event
        IOrangeVaultV1(address(this)).emitAction(IOrangeVaultV1.ActionType.REBALANCE);
    }

    function stoploss(int24 _inputTick) external {
        _checkTickSlippage(ILiquidityPoolManager(liquidityPool).getCurrentTick(), _inputTick);

        hasPosition = false;

        // 1. Remove liquidity & Collect Fees
        uint128 liquidity = ILiquidityPoolManager(liquidityPool).getCurrentLiquidity(lowerTick, upperTick);
        if (liquidity > 0) {
            ILiquidityPoolManager(liquidityPool).burnAndCollect(lowerTick, upperTick, liquidity);
        }

        (uint256 _withdrawingToken0, uint256 _repayingToken1) = ILendingPoolManager(lendingPool).balances();
        uint256 _vaultAmount1 = token1.balanceOf(address(this));

        // 2. Flashloan token1 to repay the Debt (Token1)
        uint256 _flashLoanAmount1;
        if (_repayingToken1 > _vaultAmount1) {
            unchecked {
                _flashLoanAmount1 = _repayingToken1 - _vaultAmount1;
            }
        }

        // execute flashloan (repay Token1 and withdraw Token0 in callback function `receiveFlashLoan`)
        bytes memory _userData = abi.encode(IOrangeVaultV1.FlashloanType.STOPLOSS, _repayingToken1, _withdrawingToken0);
        flashloanHash = keccak256(_userData); //set stroage for callback
        IBalancerVault(balancer).makeFlashLoan(
            IBalancerFlashLoanRecipient(address(this)),
            token1,
            _flashLoanAmount1,
            _userData
        );

        // 3. Swap remaining all Token1 for Token0
        _vaultAmount1 = token1.balanceOf(address(this));
        if (_vaultAmount1 > 0) {
            ISwapRouter(router).swapAmountIn(
                address(token1), //In
                address(token0), //Out
                routerFee,
                _vaultAmount1
            );
        }

        // emit event
        IOrangeVaultV1(address(this)).emitAction(IOrangeVaultV1.ActionType.STOPLOSS);
    }

    /* ========== WRITE FUNCTIONS(INTERNAL) ========== */
    ///@notice Check slippage by tick
    function _checkTickSlippage(int24 _currentTick, int24 _inputTick) internal view {
        if (
            _currentTick > _inputTick + int24(params.tickSlippageBPS()) ||
            _currentTick < _inputTick - int24(params.tickSlippageBPS())
        ) {
            revert(ErrorsV1.HIGH_SLIPPAGE);
        }
    }

    /// @notice execute hedge by changing collateral or debt amount
    /// @dev called by rebalance.
    /// @dev currently, rebalance doesn't support flashloan, so this may swap multiple times.
    function _executeHedgeRebalance(
        IOrangeVaultV1.Positions memory _currentPosition,
        IOrangeVaultV1.Positions memory _targetPosition
    ) internal {
        // skip special situation below to keep the code simple.
        if (
            _currentPosition.collateralAmount0 == _targetPosition.collateralAmount0 ||
            _currentPosition.debtAmount1 == _targetPosition.debtAmount1
        ) {
            // if originally collateral is 0, through this function
            if (_currentPosition.collateralAmount0 == 0) return;
            revert(ErrorsV1.EQUAL_COLLATERAL_OR_DEBT);
        }

        // start rebalance.
        unchecked {
            if (
                _currentPosition.collateralAmount0 < _targetPosition.collateralAmount0 &&
                _currentPosition.debtAmount1 < _targetPosition.debtAmount1
            ) {
                // Case1: Supply & Borrow

                // 1.supply
                uint256 _supply0 = _targetPosition.collateralAmount0 - _currentPosition.collateralAmount0;

                // swap (if necessary)
                if (_supply0 > _currentPosition.token0Balance) {
                    ISwapRouter(router).swapAmountOut(
                        address(token1),
                        address(token0),
                        routerFee,
                        _supply0 - _currentPosition.token0Balance
                    );
                }

                ILendingPoolManager(lendingPool).supply(_supply0);

                // 2.borrow
                uint256 _borrow1 = _targetPosition.debtAmount1 - _currentPosition.debtAmount1;
                ILendingPoolManager(lendingPool).borrow(_borrow1);
            } else {
                if (_currentPosition.debtAmount1 > _targetPosition.debtAmount1) {
                    // Case2: Repay & (Supply or Withdraw)

                    // 1. Repay
                    uint256 _repay1 = _currentPosition.debtAmount1 - _targetPosition.debtAmount1;

                    // swap (if necessary)
                    if (_repay1 > _currentPosition.token1Balance) {
                        ISwapRouter(router).swapAmountOut(
                            address(token0), //In
                            address(token1), //Out
                            routerFee,
                            _repay1 - _currentPosition.token1Balance
                        );
                    }
                    ILendingPoolManager(lendingPool).repay(_repay1);

                    // check which of supply or withdraw comes after
                    if (_currentPosition.collateralAmount0 < _targetPosition.collateralAmount0) {
                        // 2. Supply

                        uint256 _supply0 = _targetPosition.collateralAmount0 - _currentPosition.collateralAmount0;
                        ILendingPoolManager(lendingPool).supply(_supply0);
                    } else {
                        // 2. Withdraw
                        uint256 _withdraw0 = _currentPosition.collateralAmount0 - _targetPosition.collateralAmount0;
                        ILendingPoolManager(lendingPool).withdraw(_withdraw0);
                    }
                } else {
                    // Case3: Borrow and Withdraw

                    // 1. borrow
                    uint256 _borrow1 = _targetPosition.debtAmount1 - _currentPosition.debtAmount1;
                    ILendingPoolManager(lendingPool).borrow(_borrow1);

                    // 2. withdraw
                    uint256 _withdraw0 = _currentPosition.collateralAmount0 - _targetPosition.collateralAmount0;
                    ILendingPoolManager(lendingPool).withdraw(_withdraw0);
                }
            }
        }
    }

    /// @notice Add liquidity to Uniswap after swapping surplus amount if necessary
    /// @dev called by rebalance
    function _addLiquidityInRebalance(
        int24 _lowerTick,
        int24 _upperTick,
        uint256 _targetAmount0,
        uint256 _targetAmount1
    ) internal returns (uint128 targetLiquidity_) {
        uint256 _balance0 = token0.balanceOf(address(this));
        uint256 _balance1 = token1.balanceOf(address(this));

        //swap surplus amount
        if (_balance0 >= _targetAmount0 && _balance1 >= _targetAmount1) {
            //no need to swap
        } else {
            unchecked {
                if (_balance0 > _targetAmount0) {
                    ISwapRouter(router).swapAmountIn(
                        address(token0),
                        address(token1),
                        routerFee,
                        _balance0 - _targetAmount0
                    );
                } else if (_balance1 > _targetAmount1) {
                    ISwapRouter(router).swapAmountIn(
                        address(token1),
                        address(token0),
                        routerFee,
                        _balance1 - _targetAmount1
                    );
                }
            }
        }

        targetLiquidity_ = ILiquidityPoolManager(liquidityPool).getLiquidityForAmounts(
            _lowerTick,
            _upperTick,
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
        if (targetLiquidity_ > 0) {
            ILiquidityPoolManager(liquidityPool).mint(_lowerTick, _upperTick, targetLiquidity_);
        }
    }

    /* ========== FLASHLOAN CALLBACK ========== */
    // For stoploss. This function is delegateCalled by Vault.
    function receiveFlashLoan(
        IERC20[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory,
        bytes memory _userData
    ) external {
        uint8 _flashloanType = abi.decode(_userData, (uint8));
        if (_flashloanType == uint8(IOrangeVaultV1.FlashloanType.STOPLOSS)) {
            (, uint256 _amount1, uint256 _amount0) = abi.decode(_userData, (uint8, uint256, uint256));

            // Repay Token1
            ILendingPoolManager(lendingPool).repay(_amount1);
            // Withdraw Token0 as collateral
            ILendingPoolManager(lendingPool).withdraw(_amount0);

            // Swap to repay the flashloaned token
            if (_amounts[0] > 0) {
                (address _tokenAnother, address _tokenFlashLoaned) = (address(_tokens[0]) == address(token0))
                    ? (address(token1), address(token0))
                    : (address(token0), address(token1));

                ISwapRouter(router).swapAmountOut(
                    _tokenAnother,
                    _tokenFlashLoaned,
                    routerFee,
                    _amounts[0] //uncheckable
                );
            }
        }
        //repay flashloan
        IERC20(_tokens[0]).safeTransfer(balancer, _amounts[0]);
    }
}

// SPDX-License-Identifier: GPL-3.0
// Forked and minimized from https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/vault/IVault.sol
// Forked and minimized from https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/interfaces/contracts/vault/IFlashLoanRecipient.sol
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalancerVault {
    function flashLoan(
        IBalancerFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

interface IBalancerFlashLoanRecipient {
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ILendingPoolManager {
    function balances() external view returns (uint256, uint256);

    function balanceOfCollateral() external view returns (uint256);

    function balanceOfDebt() external view returns (uint256);

    function supply(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function borrow(uint256 amount) external;

    function repay(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// forked and modified from https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/pool/IUniswapV3PoolActions.sol
interface ILiquidityPoolManager {
    function getTwap(uint32 _minute) external view returns (int24 avgTick);

    function getCurrentTick() external view returns (int24 tick);

    function getCurrentLiquidity(int24 lowerTick, int24 upperTick) external view returns (uint128 liquidity);

    function getFeesEarned(int24 lowerTick, int24 upperTick) external view returns (uint256 fee0, uint256 fee1);

    function getAmountsForLiquidity(
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity
    ) external view returns (uint256 amount0, uint256 amount1);

    function getLiquidityForAmounts(
        int24 lowerTick,
        int24 upperTick,
        uint256 amount0,
        uint256 amount1
    ) external view returns (uint128 liquidity);

    function validateTicks(int24 _lowerTick, int24 _upperTick) external view;

    function mint(
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(int24 lowerTick, int24 upperTick) external returns (uint128 amount0, uint128 amount1);

    function burn(
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity
    ) external returns (uint256 amount0, uint256 amount1);

    function burnAndCollect(int24 _lowerTick, int24 _upperTick, uint128 _liquidity) external returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IOrangeParametersV1 {
    /// @notice Get the slippage tolerance
    function slippageBPS() external view returns (uint16);

    /// @notice Get the slippage tolerance of tick
    function tickSlippageBPS() external view returns (uint24);

    /// @notice Get the slippage interval of twap
    function twapSlippageInterval() external view returns (uint32);

    /// @notice Get the maximum LTV
    function maxLtv() external view returns (uint32);

    /// @notice Get true/false of allowlist
    function allowlistEnabled() external view returns (bool);

    /// @notice Get the merkle root
    function merkleRoot() external view returns (bytes32);

    /// @notice Get the total amount of USDC deposited by the user
    function depositCap() external view returns (uint256 assets);

    /// @notice Get the minimum amount of USDC to deposit at only initial deposit
    function minDepositAmount() external view returns (uint256 minDepositAmount);

    /// @notice Get true/false of strategist
    function helper() external view returns (address);

    /// @notice Get the strategy implementation contract
    function strategyImpl() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IOrangeParametersV1} from "./IOrangeParametersV1.sol";
import {IERC20} from "../libs/BalancerFlashloan.sol";

interface IOrangeStorageV1 {
    /* ========== VIEW FUNCTIONS ========== */

    function lowerTick() external view returns (int24);

    function upperTick() external view returns (int24);

    function token0() external view returns (IERC20 token0);

    function token1() external view returns (IERC20 token1);

    function liquidityPool() external view returns (address);

    function lendingPool() external view returns (address);

    function params() external view returns (IOrangeParametersV1);

    function hasPosition() external view returns (bool);

    /// @notice Get router fee
    function routerFee() external view returns (uint24);

    /// @notice Get the router contract
    function router() external view returns (address);

    /// @notice Get the balancer contract
    function balancer() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IOrangeParametersV1} from "./IOrangeParametersV1.sol";
import {IOrangeStorageV1} from "./IOrangeStorageV1.sol";

// import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IOrangeVaultV1 is IOrangeStorageV1 {
    enum ActionType {
        MANUAL,
        DEPOSIT,
        REDEEM,
        REBALANCE,
        STOPLOSS
    }

    enum FlashloanType {
        DEPOSIT_OVERHEDGE,
        DEPOSIT_UNDERHEDGE,
        REDEEM,
        STOPLOSS
    }

    /* ========== STRUCTS ========== */
    struct Positions {
        uint256 collateralAmount0; //collateral amount of token1 on Lending
        uint256 debtAmount1; //debt amount of token0 on Lending
        uint256 token0Balance; //balance of token0
        uint256 token1Balance; //balance of token1
    }

    struct UnderlyingAssets {
        uint256 liquidityAmount0; //liquidity amount of token0 on Uniswap
        uint256 liquidityAmount1; //liquidity amount of token1 on Uniswap
        uint256 accruedFees0; //fees of token0 on Uniswap
        uint256 accruedFees1; //fees of token1 on Uniswap
        uint256 vaultAmount0; //balance of token0 in the vault
        uint256 vaultAmount1; //balance of token1 in the vault
    }

    /* ========== EVENTS ========== */

    event BurnAndCollectFees(uint256 burn0, uint256 burn1, uint256 fee0, uint256 fee1);

    event Action(
        ActionType indexed actionType,
        address indexed caller,
        uint256 collateralAmount0,
        uint256 debtAmount1,
        uint256 liquidityAmount0,
        uint256 liquidityAmount1,
        uint256 accruedFees0,
        uint256 accruedFees1,
        uint256 vaultAmount0,
        uint256 vaultAmount1,
        uint256 totalAssets,
        uint256 totalSupply
    );

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice convert assets to shares(shares is the amount of vault token)
     * @param assets amount of assets
     * @return shares
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice convert shares to assets
     * @param shares amount of vault token
     * @return assets
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @notice get total assets
     * @return totalManagedAssets
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @notice get underlying assets
     * @return underlyingAssets amount0Current, amount1Current, accruedFees0, accruedFees1, amount0Balance, amount1Balance
     */
    function getUnderlyingBalances() external view returns (UnderlyingAssets memory underlyingAssets);

    /* ========== EXTERNAL FUNCTIONS ========== */
    /**
     * @notice deposit assets and get vault token
     * @param _shares amount of vault token
     * @param _maxAssets maximum amount of assets. excess amount will be transfer back to the msg.sender
     * @param _merkleProof merkle proof
     * @return shares
     * @dev increase all position propotionally. e.g. when share = totalSupply, the Vault is doubling up the all position.
     * Position including
     * - Aave USDC Collateral
     * - Aave ETH Debt
     * - Uniswap USDC Liquidity
     * - Uniswap ETH Liquidity
     * - USDC balance in Vault
     * - ETH balance in Vault
     */
    function deposit(
        uint256 _shares,
        uint256 _maxAssets,
        bytes32[] calldata _merkleProof
    ) external returns (uint256 shares);

    /**
     * @notice redeem vault token to assets
     * @param shares amount of vault token
     * @param minAssets minimum amount of returned assets
     * @return assets
     */
    function redeem(uint256 shares, uint256 minAssets) external returns (uint256 assets);

    /**
     * @notice Remove all positions only when current price is out of range
     * @param inputTick Input tick for slippage checking
     */
    function stoploss(int24 inputTick) external;

    function rebalance(
        int24 _newLowerTick,
        int24 _newUpperTick,
        Positions memory _targetPosition,
        uint128 _minNewLiquidity
    ) external;

    /**
     * @notice emit action event
     */
    function emitAction(ActionType _actionType) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IBalancerVault, IBalancerFlashLoanRecipient, IERC20} from "../interfaces/IBalancerFlashloan.sol";

library BalancerFlashloan {
    ///@notice make parameters and execute Flashloan
    function makeFlashLoan(
        IBalancerVault _vault,
        IBalancerFlashLoanRecipient _receiver,
        IERC20 _token,
        uint256 _amount,
        bytes memory _userData
    ) internal {
        IERC20[] memory _tokensFlashloan = new IERC20[](1);
        _tokensFlashloan[0] = _token;
        uint256[] memory _amountsFlashloan = new uint256[](1);
        _amountsFlashloan[0] = _amount;
        _vault.flashLoan(_receiver, _tokensFlashloan, _amountsFlashloan, _userData);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

library UniswapRouterSwapper {
    ///@notice Swap exact amount in
    function swapAmountIn(
        ISwapRouter router,
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountIn
    ) internal returns (uint256 amountOut_) {
        if (_amountIn == 0) return 0;

        ISwapRouter.ExactInputSingleParams memory _params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        amountOut_ = router.exactInputSingle(_params);
    }

    ///@notice Swap exact amount out
    function swapAmountOut(
        ISwapRouter router,
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountOut
    ) internal returns (uint256 amountIn_) {
        if (_amountOut == 0) return 0;

        ISwapRouter.ExactOutputSingleParams memory _params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: _amountOut,
            amountInMaximum: type(uint256).max,
            sqrtPriceLimitX96: 0
        });
        amountIn_ = router.exactOutputSingle(_params);
    }
}