// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';


/**
 * @notice Main storage structs
 */
struct AppStorage { 
    //Contracts
    address tricrypto;
    address crvTricrypto; 
    address mimPool;
    address crv2Pool;
    address yTriPool;
    address fraxPool;
    address executor;

    //ERC20s
    address USDT;
    address WBTC;
    address USDC;
    address MIM;
    address WETH;
    address FRAX;
    address ETH;

    //Token infrastructure
    address oz20;
    OZLERC20 oz;

    //System config
    uint protocolFee;
    uint defaultSlippage;
    mapping(address => bool) tokenDatabase;
    mapping(address => address) tokenL1ToTokenL2;

    //Internal accounting vars
    uint totalVolume;
    uint ozelIndex;
    uint feesVault;
    uint failedFees;
    mapping(address => uint) usersPayments;
    mapping(address => uint) accountPayments;
    mapping(address => address) accountToUser;
    mapping(address => bool) isAuthorized;

    //Curve swaps config
    TradeOps mimSwap;
    TradeOps usdcSwap;
    TradeOps fraxSwap;
    TradeOps[] swaps;

    //Mutex locks
    mapping(uint => uint) bitLocks;

    //Stabilizing mechanism (for ozelIndex)
    uint invariant;
    uint invariant2;
    uint indexRegulator;
    uint invariantRegulator;
    bool indexFlag;
    uint stabilizer;
    uint invariantRegulatorLimit;
    uint regulatorCounter;

    //Revenue vars
    ISwapRouter swapRouter;
    AggregatorV3Interface priceFeed;
    address revenueToken;
    uint24 poolFee;
    uint[] revenueAmounts;

    //Misc vars
    bool isEnabled;
    bool l1Check;
    bytes checkForRevenueSelec;
    address nullAddress;

}

/// @dev Reference for oz20Facet storage
struct OZLERC20 {
    mapping(address => mapping(address => uint256)) allowances;
    string  name;
    string  symbol;
}

/// @dev Reference for swaps and the addition/removal of account tokens
struct TradeOps {
    int128 tokenIn;
    int128 tokenOut;
    address baseToken;
    address token;  
    address pool;
}

/// @dev Reference for the details of each account
struct AccountConfig { 
    address user;
    address token;
    uint16 slippage; 
    string name;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import './AppStorage.sol';


/**
 * @notice Access control methods implemented on bitmaps
 */
abstract contract Bits {

    AppStorage s;

    /**
     * @dev Queries if bit at index_ in bitmap_ is higher than 0
     */
    function _getBit(uint bitmap_, uint index_) internal view returns(bool) {
        uint bit = s.bitLocks[bitmap_] & (1 << index_);
        return bit > 0;
    }

    /**
     * @dev Flips bit at index_ from bitmap_
     */
    function _toggleBit(uint bitmap_, uint index_) internal {
        s.bitLocks[bitmap_] ^= (1 << index_);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IMulCurv } from '../../interfaces/arbitrum/ICurve.sol';
import { ModifiersARB } from '../Modifiers.sol';
import '../../interfaces/arbitrum/ozIExecutorFacet.sol';


/**
 * @title Executor of main system functions
 * @notice In charge of swapping to the account's stablecoin and modifying 
 * state for pegged OZL rebase
 */
contract ozExecutorFacet is ozIExecutorFacet, ModifiersARB { 

    using FixedPointMathLib for uint;

    //@inheritdoc ozIExecutorFacet
    function executeFinalTrade( 
        TradeOps calldata swap_, 
        uint slippage_,
        address user_,
        uint lockNum_
    ) external payable isAuthorized(lockNum_) noReentrancy(3) {
        address pool = swap_.pool;
        int128 tokenIn = swap_.tokenIn;
        int128 tokenOut = swap_.tokenOut;
        address baseToken = swap_.baseToken;
        uint inBalance = IERC20(baseToken).balanceOf(address(this));
        uint minOut;
        uint slippage;

        IERC20(s.USDT).approve(pool, inBalance);

        for (uint i=1; i <= 2; i++) {
            if (pool == s.crv2Pool) {
                
                minOut = IMulCurv(pool).get_dy(
                    tokenIn, tokenOut, inBalance / i
                );
                slippage = calculateSlippage(minOut, slippage_ * i);

                try IMulCurv(pool).exchange(
                    tokenIn, tokenOut, inBalance / i, slippage
                ) {
                    if (i == 2) {
                        try IMulCurv(pool).exchange(
                            tokenIn, tokenOut, inBalance / i, slippage
                        ) {
                            break;
                        } catch {
                            IERC20(baseToken).transfer(user_, inBalance / 2); 
                        }
                    }
                    break;
                } catch {
                    if (i == 1) {
                        continue;
                    } else {
                        IERC20(baseToken).transfer(user_, inBalance); 
                    }
                }
            } else {
                minOut = IMulCurv(pool).get_dy_underlying(
                    tokenIn, tokenOut, inBalance / i
                );
                slippage = calculateSlippage(minOut, slippage_ * i);
                
                try IMulCurv(pool).exchange_underlying(
                    tokenIn, tokenOut, inBalance / i, slippage
                ) {
                    if (i == 2) {
                        try IMulCurv(pool).exchange_underlying(
                            tokenIn, tokenOut, inBalance / i, slippage
                        ) {
                            break;
                        } catch {
                            IERC20(baseToken).transfer(user_, inBalance / 2);
                        }
                    }
                    break;
                } catch {
                    if (i == 1) {
                        continue;
                    } else {
                        IERC20(baseToken).transfer(user_, inBalance); 
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                    Updates state for OZL calculations
    //////////////////////////////////////////////////////////////*/

    //@inheritdoc ozIExecutorFacet
    function updateExecutorState(
        uint amount_, 
        address user_,
        uint lockNum_
    ) external payable isAuthorized(lockNum_) noReentrancy(2) {
        s.usersPayments[user_] += amount_;
        s.totalVolume += amount_;
        _updateIndex();
    }

    /**
     * @dev Balances the Ozel Index using different invariants and regulators, based 
     *      in the amount of volume have flowed through the system.
     */
    function _updateIndex() private { 
        uint oneETH = 1 ether;

        if (s.ozelIndex < 20 * oneETH && s.ozelIndex != 0) { 
            uint nextInQueueRegulator = s.invariantRegulator * 2; 

            if (nextInQueueRegulator <= s.invariantRegulatorLimit) { 
                s.invariantRegulator = nextInQueueRegulator; 
                s.indexRegulator++; 
            } else {
                s.invariantRegulator /= (s.invariantRegulatorLimit / 2);
                s.indexRegulator = 1; 
                s.indexFlag = s.indexFlag ? false : true;
                s.regulatorCounter++;
            }
        } 

        s.ozelIndex = 
            s.totalVolume != 0 ? 
            oneETH.mulDivDown((s.invariant2 * s.invariantRegulator), s.totalVolume) * (s.invariant * s.invariantRegulator) : 
            0; 

        s.ozelIndex = s.indexFlag ? s.ozelIndex : s.ozelIndex * s.stabilizer;
    }

    //@inheritdoc ozIExecutorFacet
    function modifyPaymentsAndVolumeExternally(
        address user_, 
        uint newAmount_,
        uint lockNum_
    ) external isAuthorized(lockNum_) noReentrancy(5) {
        s.usersPayments[user_] -= newAmount_;
        s.totalVolume -= newAmount_;
        _updateIndex();
    }

    //@inheritdoc ozIExecutorFacet
    function transferUserAllocation( 
        address sender_, 
        address receiver_, 
        uint amount_, 
        uint senderBalance_,
        uint lockNum_
    ) external isAuthorized(lockNum_) noReentrancy(7) { 
        uint percentageToTransfer = (amount_ * 10000) / senderBalance_;
        uint amountToTransfer = percentageToTransfer.mulDivDown(s.usersPayments[sender_] , 10000);

        s.usersPayments[sender_] -= amountToTransfer;
        s.usersPayments[receiver_] += amountToTransfer;
    }

    /*///////////////////////////////////////////////////////////////
                    Updates state for OZL calculations
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculates the minimum amount to receive on swaps based on a given slippage
     * @param amount_ Amount of tokens in
     * @param basisPoint_ Slippage in basis point
     * @return minAmountOut Minimum amount to receive
     */
    function calculateSlippage(
        uint amount_, 
        uint basisPoint_
    ) public pure returns(uint minAmountOut) {
        minAmountOut = amount_ - amount_.mulDivDown(basisPoint_, 10000);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { ITri } from '../../interfaces/arbitrum/ICurve.sol';
import { ModifiersARB } from '../Modifiers.sol';
import '../../libraries/LibCommon.sol';
import '../../interfaces/arbitrum/IOZLFacet.sol';
import '../../interfaces/arbitrum/IYtri.sol';
import '../../interfaces/common/IWETH.sol';
import './ozExecutorFacet.sol';
import '../../Errors.sol';


/**
 * @title Entry L2 contract for swaps 
 * @notice Receiver of the bridge tx from L1 containing the account's ETH. 
 * It's also in charge of conducting the core swaps, depositing the system's fees 
 * and token database config.
 */
contract OZLFacet is IOZLFacet, ModifiersARB { 

    using SafeERC20 for IERC20;
    using Address for address;

    event NewToken(address token);
    event TokenRemoved(address token);


    /*///////////////////////////////////////////////////////////////
                                Main methods
    //////////////////////////////////////////////////////////////*/  

    //@inheritdoc IOZLFacet.sol
    function exchangeToAccountToken(
        bytes memory accData_,
        uint amountToSend_,
        address account_
    ) external payable noReentrancy(0) onlyAuthorized { 
        (address user, address token, uint slippage) = _filter(accData_);

        if (msg.value <= 0) revert CantBeZero('msg.value');
        if (s.failedFees > 0) _depositFeesInDeFi(s.failedFees, true); 
        
        s.accountPayments[account_] += amountToSend_; 
        if (s.accountToUser[account_] == address(0)) s.accountToUser[account_] = user; 

        IWETH(s.WETH).deposit{value: msg.value}();
        uint wethIn = IWETH(s.WETH).balanceOf(address(this));
        wethIn = s.failedFees == 0 ? wethIn : wethIn - s.failedFees;

        //Mutex bitmap lock
        _toggleBit(1, 0);

        bytes memory data = abi.encodeWithSignature(
            'deposit(uint256,address,uint256)', 
            wethIn, user, 0
        );

        LibDiamond.callFacet(data);

        (uint netAmountIn, uint fee) = _getFee(wethIn);

        uint baseTokenOut = token == s.WBTC ? 1 : 0;

        /// @dev: Base tokens: USDT (route -> MIM-USDC-FRAX) / WBTC 
        _swapsForBaseToken(
            netAmountIn, baseTokenOut, slippage, user, token
        );
      
        uint toUser = IERC20(token).balanceOf(address(this));
        if (toUser > 0) IERC20(token).safeTransfer(user, toUser);

        _depositFeesInDeFi(fee, false);
    }


    //@inheritdoc IOZLFacet.sol
    function withdrawUserShare(
        bytes memory accData_,
        address receiver_,
        uint shares_
    ) external onlyWhenEnabled { 
        (address user, address token, uint slippage) = _filter(accData_);

        if (receiver_ == address(0)) revert CantBeZero('address');
        if (shares_ <= 0) revert CantBeZero('shares');

        //Queries if there are failed fees. If true, it deposits them
        if (s.failedFees > 0) _depositFeesInDeFi(s.failedFees, true);

        _toggleBit(1, 3);

        bytes memory data = abi.encodeWithSignature(
            'redeem(uint256,address,address,uint256)', 
            shares_, receiver_, user, 3
        );

        data = LibDiamond.callFacet(data);

        uint assets = abi.decode(data, (uint));
        IYtri(s.yTriPool).withdraw(assets);

        uint tokenAmountIn = ITri(s.tricrypto).calc_withdraw_one_coin(assets, 0); 
        
        uint minOut = ozExecutorFacet(s.executor).calculateSlippage(
            tokenAmountIn, slippage
        ); 

        ITri(s.tricrypto).remove_liquidity_one_coin(assets, 0, minOut);

        _tradeWithExecutor(token, user, slippage); 

        uint userTokens = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(receiver_, userTokens); 
    } 
    

    /**
     * @dev Deposit in DeFi the fees charged by the system on each tx. If it failed to 
     * deposit them (due to slippage), it leaves the option to retry the deposit on a 
     * future tx. 
     * @param fee_ System fee
     * @param isRetry_ Boolean to determine if the call is for retrying a failed fee deposit
     */
    function _depositFeesInDeFi(uint fee_, bool isRetry_) private { 
        /// @dev Into Curve's Tricrypto
        (uint tokenAmountIn, uint[3] memory amounts) = _calculateTokenAmountCurve(fee_);

        IERC20(s.WETH).approve(s.tricrypto, tokenAmountIn);

        for (uint i=1; i <= 2; i++) {
            uint minAmount = ozExecutorFacet(s.executor).calculateSlippage(tokenAmountIn, s.defaultSlippage * i);

            try ITri(s.tricrypto).add_liquidity(amounts, minAmount) {
                /// @dev Into Yearn's crvTricrypto
                IERC20(s.crvTricrypto).approve(
                    s.yTriPool, IERC20(s.crvTricrypto).balanceOf(address(this))
                );

                IYtri(s.yTriPool).deposit(IERC20(s.crvTricrypto).balanceOf(address(this)));

                /// @dev Internal fees accounting
                if (s.failedFees > 0) s.failedFees = 0;
                s.feesVault += fee_;
                
                break;
            } catch {
                if (i == 1) {
                    continue;
                } else {
                    if (!isRetry_) s.failedFees += fee_; 
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Secondary swap functions
    //////////////////////////////////////////////////////////////*/

   /**
    * @notice Swaps account's WETH for the base token of its designated internal swap.
    * @dev If the account token is not a base token (USDT or WBTC), it'll forward the action
    * to the next call.
    * @param amountIn_ amount of WETH being swapped
    * @param baseTokenOut_ Curve's token code to filter between the system's base token or the others 
    * @param slippage_ Slippage of the Account
    * @param user_ Owner of the Account
    * @param token_ Token of the Account
    */
    function _swapsForBaseToken(
        uint amountIn_, 
        uint baseTokenOut_, 
        uint slippage_,
        address user_,
        address token_
    ) private {
        IERC20(s.WETH).approve(s.tricrypto, amountIn_);

        /**
            Exchanges the amount using the account slippage. 
            If it fails, it doubles the slippage, divides the amount between two and tries again.
            If none works, sends WETH back to the user.
        **/ 
        
        for (uint i=1; i <= 2; i++) {
            uint minOut = ITri(s.tricrypto).get_dy(2, baseTokenOut_, amountIn_ / i);
            uint slippage = ozExecutorFacet(s.executor).calculateSlippage(minOut, slippage_ * i);
            
            try ITri(s.tricrypto).exchange(2, baseTokenOut_, amountIn_ / i, slippage, false) {
                if (i == 2) {
                    try ITri(s.tricrypto).exchange(2, baseTokenOut_, amountIn_ / i, slippage, false) {
                        break;
                    } catch {
                        IERC20(s.WETH).transfer(user_, amountIn_ / 2);
                        break;
                    }
                }
                break;
            } catch {
                if (i == 1) {
                    continue;
                } else {
                    IERC20(s.WETH).transfer(user_, amountIn_);
                }
            }
        }
        
        uint baseBalance = IERC20(baseTokenOut_ == 0 ? s.USDT : s.WBTC).balanceOf(address(this));

        if ((token_ != s.USDT && token_ != s.WBTC) && baseBalance > 0) { 
            _tradeWithExecutor(token_, user_, slippage_); 
        }
    }

    /**
     * @dev Forwards the call for a final swap from base token to the account token
     * @param token_ Token of the Account
     * @param user_ Owner of the Account
     * @param slippage_ Slippage of the Account
     */
    function _tradeWithExecutor(address token_, address user_, uint slippage_) private { 
        _toggleBit(1, 2);
        uint length = s.swaps.length;

        for (uint i=0; i < length;) {
            if (s.swaps[i].token == token_) {
                bytes memory data = abi.encodeWithSignature(
                    'executeFinalTrade((int128,int128,address,address,address),uint256,address,uint256)', 
                    s.swaps[i], slippage_, user_, 2
                );

                LibDiamond.callFacet(data);
                break;
            }
            unchecked { ++i; }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Token database config
    //////////////////////////////////////////////////////////////*/

    //@inheritdoc IOZLFacet
    function addTokenToDatabase(
        TradeOps calldata newSwap_, 
        LibDiamond.Token calldata token_
    ) external { 
        LibDiamond.enforceIsContractOwner();
        address l2Address = token_.l2Address;
        address l1Address = token_.l1Address;

        if (s.tokenDatabase[l2Address]) revert TokenAlreadyInDatabase(l2Address);
        if (!s.l1Check && l1Address != s.nullAddress) revert L1TokenDisabled(l1Address);

        s.tokenDatabase[l2Address] = true;
        s.tokenL1ToTokenL2[l1Address] = l2Address;
        s.swaps.push(newSwap_);
        emit NewToken(l2Address);
    }

    //@inheritdoc IOZLFacet
    function removeTokenFromDatabase(
        TradeOps calldata swapToRemove_, 
        LibDiamond.Token calldata token_
    ) external {
        LibDiamond.enforceIsContractOwner();
        address l2Address = token_.l2Address;
        if(!s.tokenDatabase[l2Address] && _l1TokenCheck(l2Address)) revert TokenNotInDatabase(l2Address);

        s.tokenDatabase[l2Address] = false;
        s.tokenL1ToTokenL2[token_.l1Address] = s.nullAddress;
        LibCommon.remove(s.swaps, swapToRemove_);
        emit TokenRemoved(l2Address);
    }

    /*///////////////////////////////////////////////////////////////
                                Helpers
    //////////////////////////////////////////////////////////////*/

    /// @dev Charges the system fee to the user's ETH (WETH internally) L1 transfer
    function _getFee(uint amount_) private view returns(uint, uint) {
        uint fee = amount_ - ozExecutorFacet(s.executor).calculateSlippage(amount_, s.protocolFee);
        uint netAmount = amount_ - fee;
        return (netAmount, fee);
    }

    /// @dev Formats params needed for a specific Curve interaction
    function _calculateTokenAmountCurve(uint wethAmountIn_) private view returns(uint, uint[3] memory) {
        uint[3] memory amounts;
        amounts[0] = 0;
        amounts[1] = 0;
        amounts[2] = wethAmountIn_;
        uint tokenAmount = ITri(s.tricrypto).calc_token_amount(amounts, true);
        return (tokenAmount, amounts);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import '../libraries/AddressAliasHelper.sol';
import '../libraries/LibCommon.sol';
import '../Errors.sol';
import './Bits.sol';


/**
 * @title Modifiers for the L2 contracts
 */
abstract contract ModifiersARB is Bits {

    /**
     * @dev Protector against reentrancy using bitmaps and bitwise operations
     * @param index_ Index of the bit to be flipped 
     */
    modifier noReentrancy(uint index_) { 
        if (!(_getBit(0, index_))) revert NoReentrance();
        _toggleBit(0, index_);
        _;
        _toggleBit(0, index_);
    }

    /**
     * @dev Access control using bitmaps and bitwise operations
     * @param index_ Index of the bit to be flipped 
     */
    modifier isAuthorized(uint index_) {
        if (_getBit(1, index_)) revert NotAuthorized(msg.sender);
        _;
        _toggleBit(1, index_);
    }

    /**
     * @dev Allows/disallows redeemptions of OZL for AUM 
     */
    modifier onlyWhenEnabled() {
        if (!(s.isEnabled)) revert NotEnabled();
        _;
    }

    /**
     * @dev Checks that the sender can call exchangeToAccountToken
     */
    modifier onlyAuthorized() {
        address l1Address = AddressAliasHelper.undoL1ToL2Alias(msg.sender);
        if (!s.isAuthorized[l1Address]) revert NotAuthorized(msg.sender);
        _;
    }

    /**
     * @dev Does primery checks on the details of an account
     * @param data_ Details of account/proxy
     * @return address Owner of the Account
     * @return address Token of the Account
     * @return uint256 Slippage of the Account
     */
    function _filter(bytes memory data_) internal view returns(address, address, uint) {
        (address user, address token, uint16 slippage) = LibCommon.extract(data_);

        if (user == address(0) || token == address(0)) revert CantBeZero('address'); 
        if (slippage <= 0) revert CantBeZero('slippage');

        if (!s.tokenDatabase[token] && _l1TokenCheck(token)) {
            revert TokenNotInDatabase(token);
        } else if (!s.tokenDatabase[token]) {
            token = s.tokenL1ToTokenL2[token];
        }

        return (user, token, uint(slippage));
    }

    /**
     * @dev Checks if an L1 address exists in the database
     * @param token_ L1 address
     * @return bool Returns false if token_ exists
     */
    function _l1TokenCheck(address token_) internal view returns(bool) {
        if (s.l1Check) {
            if (s.tokenL1ToTokenL2[token_] == s.nullAddress) return true;
            return false;
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14; 


/// @dev Thrown when comparisson has a zero value
/// @param nonZeroValue Type of the zero value
error CantBeZero(string nonZeroValue);

/// @dev When a low-level call fails
/// @param errorMsg Custom error message
error CallFailed(string errorMsg); 

/// @dev Thrown when the queried token is not in the database
/// @param token Address of queried token
error TokenNotInDatabase(address token);

/// @dev For when the queried token is in the database
/// @param token Address of queried token
error TokenAlreadyInDatabase(address token);

/// @dev Thrown when an user is not in the database
/// @param user Address of the queried user
error UserNotInDatabase(address user);

/// @dev Thrown when the call is done by a non-account/proxy
error NotAccount();

/// @dev Thrown when a custom condition is not fulfilled
/// @param errorMsg Custom error message
error ConditionNotMet(string errorMsg);

/// @dev Thrown when an unahoritzed user makes the call
/// @param unauthorizedUser Address of the msg.sender
error NotAuthorized(address unauthorizedUser);

/// @dev When reentrance occurs
error NoReentrance();

/// @dev When a particular action hasn't been enabled yet
error NotEnabled();

/// @dev Thrown when the account name is too long
error NameTooLong();

/// @dev Thrown when the queried Gelato task is invalid
/// @param taskId Gelato task
error InvalidTask(bytes32 taskId);

/// @dev Thrown if an attempt to add a L1 token is done after it's been disabled
/// @param l1Token L1 token address
error L1TokenDisabled(address l1Token);

/// @dev Thrown when a Gelato's task ID doesn't exist
error NoTaskId();

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


/**
 * @dev Multiple interfaces that integrates 2Crv, MIM and Frax pools
 */
interface IMulCurv {
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external;

  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external returns (uint256);

  function get_dy(int128 i, int128 j, uint256 dx) external returns(uint256);
  function get_dy_underlying(int128 i, int128 j, uint dx) external returns(uint256);
  function calc_withdraw_one_coin(uint256 token_amount, int128 i) external returns(uint256);
  function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;
  function calc_token_amount(uint256[2] calldata amounts, bool deposit) external returns(uint256);
  function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  
}


interface ITri { 
  function exchange(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy,
    bool use_eth
  ) external payable;

  function get_virtual_price() external view returns (uint256);
  function get_dy(uint i, uint j, uint dx) external view returns(uint256);
  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;
  function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns(uint256);
  function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external;
  function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external view returns(uint256);
  function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import { AccountConfig, TradeOps } from '../../arbitrum/AppStorage.sol';
import '../../libraries/LibDiamond.sol';


interface IOZLFacet {

    /**
     * @notice Main bridge function on L2
     * @dev Receives the ETH coming from L1, initiates L2 swaps, and 
     * deposits the system's fees.
     * @param accData_ Details of the account that received the L1 transfer
     * @param amountToSend_ Amount of ETH received by the Account in L1
     * @param account_ The Account
     */
    function exchangeToAccountToken(
        bytes memory accData_,
        uint amountToSend_,
        address account_
    ) external payable;

    /**
     * @dev Allow an OZL holder to withdraw their share of AUM by redeeming them.
     * Once redeemption has occurred, it rebalances OZL's totalySupply (aka rebases it back 100)
     * @param accData_ Details of the account through which the redeemption of AUM will occur
     * @param receiver_ Receiver of the redeemed funds
     * @param shares_ OZL balance to redeem
     */
    function withdrawUserShare(
        bytes memory accData_,
        address receiver_,
        uint shares_
    ) external;

    /**
     * @dev Adds a new token to be swapped into to the token database
     * @param newSwap_ Swap Curve config -as infra- that will allow swapping into the new token
     * @param token_ L1 & L2 addresses of the token to add
     */
    function addTokenToDatabase(
        TradeOps calldata newSwap_, 
        LibDiamond.Token calldata token_
    ) external;

    /**
     * @dev Removes a token from the token database
     * @param swapToRemove_ Remove the swap Curve config that allows swapping into
     * the soon-to-be-removed token.
     * @param token_ L1 & L2 addresses of the token to add
     */
    function removeTokenFromDatabase(
        TradeOps calldata swapToRemove_, 
        LibDiamond.Token calldata token_
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


interface IYtri {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function pricePerShare() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import '../../arbitrum/AppStorage.sol';


interface ozIExecutorFacet {

    /**
     * @notice Final swap
     * @dev Exchanges the amount using the account's slippage.
     * If it fails, it doubles the slippage, divides the amount between two and tries again.
     * If none works, sends the swap's baseToken instead to the user.
     * @param swap_ Struct containing the swap configuration depending on the
     * relation of the account's stablecoin and its Curve pool.
     * @param slippage_ Slippage of the account
     * @param user_ Owner of the account where the emergency transfers will occur in case 
     * any of the swaps can't be completed due to slippage.
     * @param lockNum_ Index of the bit which authorizes the function call
     */
    function executeFinalTrade( 
        TradeOps calldata swap_, 
        uint slippage_,
        address user_,
        uint lockNum_
    ) external payable;

    /**
     * @dev Updates the two main variables that will be used on the calculation
     * of the Ozel Index.
     * @param amount_ ETH (WETH internally) sent to the account (after fee discount)
     * @param user_ Owner of the account
     * @param lockNum_ Index of the bit which authorizes the function call
     */
    function updateExecutorState(
        uint amount_, 
        address user_,
        uint lockNum_
    ) external payable;

    /**
     * @notice Helper for burn() on oz20Facet when redeeming OZL for funds
     * @dev Allows the modification of the system state, and the user's interaction
     * with it, outside this main contract.
     * @param user_ Owner of account
     * @param newAmount_ ETH (WETH internally) transacted
     * @param lockNum_ Index of the bit which authorizes the function call
     */
    function modifyPaymentsAndVolumeExternally(
        address user_, 
        uint newAmount_,
        uint lockNum_
    ) external;

    /**
     * @notice Helper for _transfer() on oz420Facet
     * @dev Executes the logic that will cause the transfer of OZL from one user to another
     * @param sender_ Sender of OZL tokens
     * @param receiver_ Receiver of sender_'s transfer
     * @param amount_ OZL tokens to send to receiver_
     * @param senderBalance_ Sender_'s total OZL balance
     * @param lockNum_ Index of the bit which authorizes the function call
     */
    function transferUserAllocation( 
        address sender_, 
        address receiver_, 
        uint amount_, 
        uint senderBalance_,
        uint lockNum_
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


interface IWETH {
    function deposit() external payable;
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;


library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import { TradeOps } from '../arbitrum/AppStorage.sol';


/**
 * @notice Library of common methods using in both L1 and L2 contracts
 */
library LibCommon {

    /**
     * @notice L1 removal method
     * @dev Removes a token from the token database
     * @param tokensDB_ Array of addresses where the removal will occur
     * @param toRemove_ Token to remove
     */
    function remove(address[] storage tokensDB_, address toRemove_) internal {
        uint index;
        for (uint i=0; i < tokensDB_.length;) {
            if (tokensDB_[i] == toRemove_)  {
                index = i;
                break;
            }
            unchecked { ++i; }
        }
        for (uint i=index; i < tokensDB_.length - 1;){
            tokensDB_[i] = tokensDB_[i+1];
            unchecked { ++i; }
        }
        delete tokensDB_[tokensDB_.length-1];
        tokensDB_.pop();
    }

    /**
     * @notice Overloaded L2 removal method
     * @dev Removes a token and its swap config from the token database
     * @param swaps_ Array of structs where the removal will occur
     * @param swapToRemove_ Config struct to be removed
     */
    function remove(
        TradeOps[] storage swaps_, 
        TradeOps memory swapToRemove_
    ) internal {
        uint index;
        for (uint i=0; i < swaps_.length;) {
            if (swaps_[i].token == swapToRemove_.token)  {
                index = i;
                break;
            }
            unchecked { ++i; }
        }
        for (uint i=index; i < swaps_.length - 1;){
            swaps_[i] = swaps_[i+1];
            unchecked { ++i; }
        }
        delete swaps_[swaps_.length-1];
        swaps_.pop();
    }

    /**
     * @dev Extracts the details of an Account
     * @param data_ Bytes array containing the details
     * @return user Owner of the Account
     * @return token Token of the Account
     * @return slippage Slippage of the Account
     */
    function extract(bytes memory data_) internal pure returns(
        address user, 
        address token, 
        uint16 slippage
    ) {
        assembly {
            user := shr(96, mload(add(data_, 32)))
            token := shr(96, mload(add(data_, 52)))
            slippage := and(0xff, mload(add(mload(data_), data_)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/arbitrum/IDiamondCut.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct Facets {
        bytes4[][] selectors;
        address[] addresses;
    }

    struct Token {
        address l1Address;
        address l2Address;
    }

    struct VarsAndAddresses { 
        address[] contracts;
        address[] erc20s;
        Token[] tokensDb;
        address ETH;
        uint[] appVars;
        uint[] revenueAmounts;
        string[] ozlVars;
    }


    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner; 
        //facets that don't check revenue
        address[] nonRevenueFacets;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    /*///////////////////////////////////////////////////////////////
                               Custom methods
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Determines which facet to call depending on the selector
     * @param data_ Calldata of function to call
     * @return bytes Return data
     */
    function callFacet(bytes memory data_) internal returns(bytes memory) {
        DiamondStorage storage ds = diamondStorage();
        address facet = ds.selectorToFacetAndPosition[bytes4(data_)].facetAddress;
        (bool success, bytes memory data) = facet.delegatecall(data_);
        require(success, 'LibDiamond: callFacet() failed');
        return data;
    }

    /**
     * @dev Sets the facets that don't call for a revenue check (the owner's)
     * @param nonRevenueFacets_ Facets that don't call for revenue check
     */
    function setNonRevenueFacets(address[] memory nonRevenueFacets_) internal {
        DiamondStorage storage ds = diamondStorage();
        uint length = nonRevenueFacets_.length;
        for (uint i=0; i < length;) {
            ds.nonRevenueFacets.push(nonRevenueFacets_[i]);
            unchecked { ++i; }
        }
    }
}