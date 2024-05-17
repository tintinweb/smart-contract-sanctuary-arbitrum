// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IChainlinkAggregator is AggregatorV2V3Interface {
    function maxAnswer() external view returns (int192);

    function minAnswer() external view returns (int192);

    function aggregator() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

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

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router is IUniswapV3SwapCallback {
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
        uint160 sqrtPriceLimitX96;
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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

interface IVault {
    function isSupportedToken(address _token) external view returns (bool);

    function getTokenOracle(address _token) external view returns (address);

    function convertToUSDC(
        address _token,
        uint256 _amount
    ) external view returns (uint256);

    function strategist() external view returns (address);

    function universalOracle() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

import {Math} from "../utils/Math.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSetUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/utils/structs/EnumerableSetUpgradeable.sol";
import {UniversalOracle} from "../oracles/UniversalOracle.sol";
import {IUniswapV2Router02 as IUniswapV2Router} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV3Router} from "../interfaces/IUniswapV3Router.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {IVault} from "../interfaces/IVault.sol";

contract UniswapSwapModule {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeTransferLib for ERC20;
    using Math for uint256;
    using Address for address;

    /// @notice uniswapV2Router is the Uniswap V2 router contract.
    IUniswapV2Router public immutable uniswapV2Router;
    /// @notice uniswapV3Router is the Uniswap V3 router contract.
    IUniswapV3Router public immutable uniswapV3Router;
    /// @notice nativeWrapper is the WETH contract.
    IWETH9 public immutable nativeWrapper;

    /// @notice Construct the UniswapSwapModule contract.
    /// @param _v2Router The address of the Uniswap V2 router contract.
    /// @param _v3Router The address of the Uniswap V3 router contract.
    /// @param _nativeWrapper The address of the WETH contract.
    constructor(address _v2Router, address _v3Router, address _nativeWrapper) {
        uniswapV2Router = IUniswapV2Router(_v2Router);
        uniswapV3Router = IUniswapV3Router(_v3Router);
        nativeWrapper = IWETH9(_nativeWrapper);
    }

    /// @notice Function perform logic of transfer ERC20 token from strategist to Vault.
    /// and vice versa.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of ERC20 token to transfer.
    /// @param isFromVaultBalance The flag to check if the amount is from Vault balance.
    function transferERC20(
        address token,
        uint256 amount,
        bool isFromVaultBalance
    ) external {
        address strategist = IVault(address(this)).strategist();
        address sender = isFromVaultBalance ? address(this) : strategist;
        if (amount == 0) revert("Zero amount");
        amount = isFromVaultBalance
            ? _maxAvailable(ERC20(address(token)), amount, address(this))
            : _maxAvailable(ERC20(address(token)), amount, strategist);

        if (sender == address(this)) {
            ERC20(token).safeTransfer(strategist, amount);
        } else {
            ERC20(token).safeTransferFrom(strategist, address(this), amount);
        }
    }

    /// @notice Function perform logic of transfer native token from strategist to Vault.
    /// and vice versa.
    /// @param amount The amount of native token to transfer.
    /// @param isFromVaultBalance The flag to check if the amount is from Vault balance.
    function transferNative(
        uint256 amount,
        bool isFromVaultBalance
    ) external payable {
        address strategist = IVault(address(this)).strategist();
        if (amount == 0) revert("Zero amount");
        if (amount == type(uint256).max) {
            amount = address(this).balance;
        }
        if (isFromVaultBalance) {
            SafeTransferLib.safeTransferETH(strategist, amount);
        }
    }

    /// @notice Function perform logic of wrap native token to WETH.
    /// @param amount The amount of native token to wrap.
    /// @param isToVaultBalance The flag to check if the amount is to Vault balance.
    function wrap(
        uint256 amount,
        bool isToVaultBalance
    ) external payable virtual {
        address strategist = IVault(address(this)).strategist();
        if (amount == 0) revert("Zero amount");

        if (amount == type(uint256).max) {
            amount = address(this).balance;
        }

        nativeWrapper.deposit{value: amount}();

        if (!isToVaultBalance) {
            ERC20(address(nativeWrapper)).safeTransfer(strategist, amount);
        }
    }

    /**
     * @notice Allows a strategist to unwrap a wrapped native asset.
     * @param amount the amount of wrapped native to unwrap
     * @param isFromVaultBalance the flag to check if the amount is from Vault balance
     * @param isToVaultBalance the flag to check if the amount is to Vault balance
     */
    function unwrap(
        uint256 amount,
        bool isFromVaultBalance,
        bool isToVaultBalance
    ) external virtual {
        if (amount == 0) revert("Zero amount");
        address strategist = IVault(address(this)).strategist();

        amount = isFromVaultBalance
            ? _maxAvailable(
                ERC20(address(nativeWrapper)),
                amount,
                address(this)
            )
            : _maxAvailable(ERC20(address(nativeWrapper)), amount, strategist);
        if (!isFromVaultBalance) {
            ERC20(address(nativeWrapper)).safeTransferFrom(
                strategist,
                address(this),
                amount
            );
        }

        nativeWrapper.withdraw(amount);

        if (!isToVaultBalance) {
            SafeTransferLib.safeTransferETH(strategist, amount);
        }
    }

    /**
     * @notice Perform a swap using Uniswap V2.
     * @dev Allows for a blind swap, if type(uint256).max is used for the amount.
     * @param path The path of the swap.
     * @param amount The amount of the token to swap.
     * @param amountOutMin The minimum amount of the output token.
     * @param isFromVaultBalance The flag to check if the amount is from Vault balance.
     * @param isToVaultBalance The flag to check if the amount is to Vault balance.
     */
    function swapWithUniV2(
        address[] memory path,
        uint256 amount,
        uint256 amountOutMin,
        bool isFromVaultBalance,
        bool isToVaultBalance
    ) public {
        UniversalOracle universalOracle = UniversalOracle(
            IVault(address(this)).universalOracle()
        );
        ERC20 tokenIn = ERC20(path[0]);
        ERC20 tokenOut = ERC20(path[path.length - 1]);
        address strategist = IVault(address(this)).strategist();

        amount = isFromVaultBalance
            ? _maxAvailable(tokenIn, amount, address(this))
            : _maxAvailable(tokenIn, amount, strategist);

        if (!isFromVaultBalance) {
            tokenIn.safeTransferFrom(strategist, address(this), amount);
        }
        tokenIn.safeApprove(address(uniswapV2Router), amount);

        if (universalOracle.isSupported(tokenIn)) {
            if (!universalOracle.isSupported(tokenOut))
                revert("Unsupported token out");
            uint256 tokenInBalance = tokenIn.balanceOf(address(this));

            uint256[] memory amountsOut = uniswapV2Router
                .swapExactTokensForTokens(
                    amount,
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp + 60
                );
            uint256 tokenOutAmountOut = amountsOut[amountsOut.length - 1];

            uint256 tokenInAmountIn = tokenInBalance -
                tokenIn.balanceOf(address(this));

            uint256 tokenInValueOut = universalOracle.getValue(
                tokenOut,
                tokenOutAmountOut,
                tokenIn
            );

            if (tokenInValueOut < tokenInAmountIn.mulDivDown(slippage(), 1e4))
                revert("Slippage");
            if (!isToVaultBalance) {
                tokenOut.safeTransfer(
                    strategist,
                    amountsOut[amountsOut.length - 1]
                );
            }
        } else {
            uniswapV2Router.swapExactTokensForTokens(
                amount,
                amountOutMin,
                path,
                isToVaultBalance ? address(this) : strategist,
                block.timestamp + 60
            );
        }

        _revokeExternalApproval(tokenIn, address(uniswapV2Router));
    }

    /**
     * @notice Perform a swap using Uniswap V3.
     * @dev Allows for a blind swap, if type(uint256).max is used for the amount.
     * @param path The path of the swap.
     * @param poolFees The pool fees of the swap.
     * @param amount The amount of the token to swap.
     * @param amountOutMin The minimum amount of the output token.
     * @param isFromVaultBalance The flag to check if the amount is from Vault balance.
     * @param isToVaultBalance The flag to check if the amount is to Vault balance.
     */
    function swapWithUniV3(
        address[] memory path,
        uint24[] memory poolFees,
        uint256 amount,
        uint256 amountOutMin,
        bool isFromVaultBalance,
        bool isToVaultBalance
    ) public {
        UniversalOracle universalOracle = UniversalOracle(
            IVault(address(this)).universalOracle()
        );
        ERC20 tokenIn = ERC20(path[0]);
        ERC20 tokenOut = ERC20(path[path.length - 1]);
        address strategist = IVault(address(this)).strategist();

        amount = isFromVaultBalance
            ? _maxAvailable(tokenIn, amount, address(this))
            : _maxAvailable(tokenIn, amount, strategist);

        if (!isFromVaultBalance) {
            tokenIn.safeTransferFrom(strategist, address(this), amount);
        }

        tokenIn.safeApprove(address(uniswapV3Router), amount);

        bytes memory encodePackedPath = abi.encodePacked(address(path[0]));
        for (uint256 i = 1; i < path.length; i++)
            encodePackedPath = abi.encodePacked(
                encodePackedPath,
                poolFees[i - 1],
                path[i]
            );

        if (universalOracle.isSupported(tokenIn)) {
            if (!universalOracle.isSupported(tokenOut))
                revert("Unsupported token out");
            uint256 tokenInBalance = tokenIn.balanceOf(address(this));

            uint256 tokenOutAmountOut = uniswapV3Router.exactInput(
                IUniswapV3Router.ExactInputParams({
                    path: encodePackedPath,
                    recipient: address(this),
                    deadline: block.timestamp + 60,
                    amountIn: amount,
                    amountOutMinimum: amountOutMin
                })
            );

            uint256 tokenInAmountIn = tokenInBalance -
                tokenIn.balanceOf(address(this));

            uint256 tokenInValueOut = universalOracle.getValue(
                tokenOut,
                tokenOutAmountOut,
                tokenIn
            );

            if (tokenInValueOut < tokenInAmountIn.mulDivDown(slippage(), 1e4))
                revert("Slippage");

            if (!isToVaultBalance) {
                tokenOut.safeTransfer(strategist, tokenOutAmountOut);
            }
        } else {
            uniswapV3Router.exactInput(
                IUniswapV3Router.ExactInputParams({
                    path: encodePackedPath,
                    recipient: isToVaultBalance ? address(this) : strategist,
                    deadline: block.timestamp + 60,
                    amountIn: amount,
                    amountOutMinimum: amountOutMin
                })
            );
        }

        _revokeExternalApproval(tokenIn, address(uniswapV3Router));
    }

    /// @notice Function to get the maximum available amount of ERC20 token.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of ERC20 token.
    /// @param spender The address of the spender.
    /// @return The maximum available amount of ERC20 token.
    function _maxAvailable(
        ERC20 token,
        uint256 amount,
        address spender
    ) internal view virtual returns (uint256) {
        if (amount == type(uint256).max) return token.balanceOf(spender);
        else return amount;
    }

    /// @notice Function to revoke external approval.
    /// @param token The address of the ERC20 token.
    /// @param spender The address of the spender.
    function _revokeExternalApproval(ERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) > 0)
            token.safeApprove(spender, 0);
    }

    /// @notice Function to get the slippage.
    function slippage() public pure returns (uint32) {
        return 0.9e4;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {UniversalOracle} from "./UniversalOracle.sol";
import {Math} from "../utils/Math.sol";

abstract contract AdditionalSource {
    error AdditionalSource__UniversalOracle();

    modifier onlyUniversalOracle() {
        if (msg.sender != address(universalOracle))
            revert AdditionalSource__UniversalOracle();
        _;
    }

    UniversalOracle public immutable universalOracle;

    constructor(UniversalOracle _universalOracle) {
        universalOracle = _universalOracle;
    }

    function setupSource(ERC20 asset, bytes memory sourceData) external virtual;

    function getPriceInUSD(ERC20 asset) external view virtual returns (uint256);
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "../utils/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AdditionalSource} from "./AdditionalSource.sol";

/**
 * @notice Attempted to set a minimum price below the Chainlink minimum price (with buffer).
 * @param minPrice minimum price attempted to set
 * @param bufferedMinPrice minimum price that can be set including buffer
 */
error UniversalOracle__InvalidMinPrice(
    uint256 minPrice,
    uint256 bufferedMinPrice
);

/**
 * @notice Attempted to set a maximum price above the Chainlink maximum price (with buffer).
 * @param maxPrice maximum price attempted to set
 * @param bufferedMaxPrice maximum price that can be set including buffer
 */
error UniversalOracle__InvalidMaxPrice(
    uint256 maxPrice,
    uint256 bufferedMaxPrice
);

/**
 * @notice Attempted to add an invalid asset.
 * @param asset address of the invalid asset
 */
error UniversalOracle__InvalidAsset(address asset);

/**
 * @notice Attempted to add an asset that is already supported.
 */
error UniversalOracle__AssetAlreadyAdded(address asset);

/**
 * @notice Attempted to edit an asset that is not supported.
 */
error UniversalOracle__AssetNotAdded(address asset);

/**
 * @notice Attempted to edit an asset that is not editable.
 */
error UniversalOracle__AssetNotEditable(address asset);

/**
 * @notice Attempted to cancel the editing of an asset that is not pending edit.
 */
error UniversalOracle__AssetNotPendingEdit(address asset);

/**
 * @notice Attempted to add an asset, but actual answer was outside range of expectedAnswer.
 */
error UniversalOracle__BadAnswer(uint256 answer, uint256 expectedAnswer);

/**
 * @notice Attempted to perform an operation using an unknown derivative.
 */
error UniversalOracle__UnknownDerivative(uint8 unknownDerivative);

/**
 * @notice Attempted to add an asset with invalid min/max prices.
 * @param min price
 * @param max price
 */
error UniversalOracle__MinPriceGreaterThanMaxPrice(uint256 min, uint256 max);
/**
 * @notice Attempted to update the asset to one that is not supported by the platform.
 * @param asset address of the unsupported asset
 */
error UniversalOracle__UnsupportedAsset(address asset);
/**
 * @notice Attempted an operation to price an asset that under its minimum valid price.
 * @param asset address of the asset that is under its minimum valid price
 * @param price price of the asset
 * @param minPrice minimum valid price of the asset
 */
error UniversalOracle__AssetBelowMinPrice(
    address asset,
    uint256 price,
    uint256 minPrice
);

/**
 * @notice Attempted an operation to price an asset that under its maximum valid price.
 * @param asset address of the asset that is under its maximum valid price
 * @param price price of the asset
 * @param maxPrice maximum valid price of the asset
 */
error UniversalOracle__AssetAboveMaxPrice(
    address asset,
    uint256 price,
    uint256 maxPrice
);

/**
 * @notice Attempted to fetch a price for an asset that has not been updated in too long.
 * @param asset address of the asset thats price is stale
 * @param timeSinceLastUpdate seconds since the last price update
 * @param heartbeat maximum allowed time between price updates
 */
error UniversalOracle__StalePrice(
    address asset,
    uint256 timeSinceLastUpdate,
    uint256 heartbeat
);
/**
 * @notice Buffered min price exceedes 80 bits of data.
 */
error UniversalOracle__BufferedMinOverflow();
/**
 * @notice Attempted an operation with arrays of unequal lengths that were expected to be equal length.
 */
error UniversalOracle__LengthMismatch();

contract UniversalOracle is Ownable {
    using SafeTransferLib for ERC20;
    using SafeCast for int256;
    using Math for uint256;
    using Address for address;

    /**
     * @notice Bare minimum settings all derivatives support.
     * @param derivative the derivative used to price the asset
     * @param source the address used to price the asset
     */
    struct AssetSettings {
        uint8 derivative;
        address source;
    }

    /**
     * @notice Stores data for Chainlink derivative assets.
     * @param max the max valid price of the asset
     * @param min the min valid price of the asset
     * @param heartbeat the max amount of time between price updates
     * @param inETH bool indicating whether the price feed is
     *        denominated in ETH(true) or USD(false)
     */
    struct ChainlinkDerivativeStorage {
        uint144 max;
        uint80 min;
        uint24 heartbeat;
        bool inETH;
    }

    ERC20 public immutable WETH;
    /**
     * @notice Mapping between an asset to price and its `AssetSettings`.
     */
    mapping(ERC20 => AssetSettings) public getAssetSettings;
    /**
     * @notice The allowed deviation between the expected answer vs the actual answer.
     */
    uint256 public constant EXPECTED_ANSWER_DEVIATION = 0.02e18;

    /**
     * @notice Returns Chainlink Derivative Storage
     */
    mapping(ERC20 => ChainlinkDerivativeStorage)
        public getChainlinkDerivativeStorage;

    /**
     * @notice If zero is specified for a Chainlink asset heartbeat, this value is used instead.
     */
    uint24 public constant DEFAULT_HEART_BEAT = 1 days;

    event AddAsset(address indexed asset);
    event EditAssetComplete(address asset, bytes32 editHash);

    constructor(address newOwner, ERC20 _weth) {
        WETH = _weth;
        transferOwnership(newOwner);
    }

    /**
     * @notice Allows owner to add assets to the universal oracle.
     * @dev Performs a sanity check by comparing the universal oracle computed price to
     * a user input `_expectedAnswer`.
     * @param _asset the asset to add to the pricing router
     * @param _settings the settings for `_asset`
     *        @dev The `derivative` value in settings MUST be non zero.
     * @param _storage arbitrary bytes data used to configure `_asset` pricing
     * @param _expectedAnswer the expected answer for the asset from  `_getPriceInUSD`
     */
    function addAsset(
        ERC20 _asset,
        AssetSettings memory _settings,
        bytes memory _storage,
        uint256 _expectedAnswer
    ) external onlyOwner {
        // Check that asset is not already added.
        if (getAssetSettings[_asset].derivative > 0)
            revert UniversalOracle__AssetAlreadyAdded(address(_asset));

        _updateAsset(_asset, _settings, _storage, _expectedAnswer);

        emit AddAsset(address(_asset));
    }

    /**
     * @notice editAsset.
     * @param _asset the asset to finish editing in the pricing router
     * @param _settings the settings for `_asset`
     *        @dev The `derivative` value in settings MUST be non zero.
     * @param _storage arbitrary bytes data used to configure `_asset` pricing
     */
    function editAsset(
        ERC20 _asset,
        AssetSettings memory _settings,
        bytes memory _storage,
        uint256 _expectedAnswer
    ) external onlyOwner {
        bytes32 editHash = keccak256(abi.encode(_asset, _settings, _storage));
        // Edit the asset.
        _updateAsset(_asset, _settings, _storage, _expectedAnswer);

        emit EditAssetComplete(address(_asset), editHash);
    }

    /**
     * @notice Helper function to update an `_asset`s configuration.
     * @param _asset the asset to update in the pricing router
     * @param _settings the settings for `_asset`
     *        @dev The `derivative` value in settings MUST be non zero.
     * @param _storage arbitrary bytes data used to configure `_asset` pricing
     */
    function _updateAsset(
        ERC20 _asset,
        AssetSettings memory _settings,
        bytes memory _storage,
        uint256 _expectedAnswer
    ) internal {
        if (address(_asset) == address(0))
            revert UniversalOracle__InvalidAsset(address(_asset));

        // Zero is an invalid derivative.
        if (_settings.derivative == 0)
            revert UniversalOracle__UnknownDerivative(_settings.derivative);

        // Call setup function for appropriate derivative.
        if (_settings.derivative == 1) {
            _setupPriceForChainlinkDerivative(
                _asset,
                _settings.source,
                _storage
            );
        } else if (_settings.derivative == 2) {
            AdditionalSource(_settings.source).setupSource(_asset, _storage);
        } else revert UniversalOracle__UnknownDerivative(_settings.derivative);

        // Check `_getPriceInUSD` against `_expectedAnswer`.
        uint256 minAnswer = _expectedAnswer.mulWadDown(
            (1e18 - EXPECTED_ANSWER_DEVIATION)
        );
        uint256 maxAnswer = _expectedAnswer.mulWadDown(
            (1e18 + EXPECTED_ANSWER_DEVIATION)
        );

        getAssetSettings[_asset] = _settings;
        uint256 answer = _getPriceInUSD(_asset, _settings);
        if (answer < minAnswer || answer > maxAnswer)
            revert UniversalOracle__BadAnswer(answer, _expectedAnswer);
    }

    /**
     * @notice return bool indicating whether or not an asset has been set up.
     * @dev Since `addAsset` enforces the derivative is non zero, checking if the stored setting
     *      is nonzero is sufficient to see if the asset is set up.
     */
    function isSupported(ERC20 asset) external view returns (bool) {
        return getAssetSettings[asset].derivative > 0;
    }

    // ======================================= PRICING OPERATIONS =======================================

    /**
     * @notice Get `asset` price in USD.
     * @dev Returns price in USD with 8 decimals.
     */
    function getPriceInUSD(ERC20 asset) external view returns (uint256) {
        AssetSettings memory assetSettings = getAssetSettings[asset];
        return _getPriceInUSD(asset, assetSettings);
    }

    /**
     * @notice Get multiple `asset` prices in USD.
     * @dev Returns array of prices in USD with 8 decimals.
     */
    function getPricesInUSD(
        ERC20[] calldata assets
    ) external view returns (uint256[] memory prices) {
        prices = new uint256[](assets.length);
        for (uint256 i; i < assets.length; ++i) {
            AssetSettings memory assetSettings = getAssetSettings[assets[i]];
            prices[i] = _getPriceInUSD(assets[i], assetSettings);
        }
    }

    /**
     * @notice Get the value of an asset in terms of another asset.
     * @param baseAsset address of the asset to get the price of in terms of the quote asset
     * @param amount amount of the base asset to price
     * @param quoteAsset address of the asset that the base asset is priced in terms of
     * @return value value of the amount of base assets specified in terms of the quote asset
     */
    function getValue(
        ERC20 baseAsset,
        uint256 amount,
        ERC20 quoteAsset
    ) external view returns (uint256 value) {
        AssetSettings memory baseSettings = getAssetSettings[baseAsset];
        AssetSettings memory quoteSettings = getAssetSettings[quoteAsset];
        if (baseSettings.derivative == 0)
            revert UniversalOracle__UnsupportedAsset(address(baseAsset));
        if (quoteSettings.derivative == 0)
            revert UniversalOracle__UnsupportedAsset(address(quoteAsset));
        uint256 priceBaseUSD = _getPriceInUSD(baseAsset, baseSettings);
        uint256 priceQuoteUSD = _getPriceInUSD(quoteAsset, quoteSettings);
        value = _getValueInQuote(
            priceBaseUSD,
            priceQuoteUSD,
            baseAsset.decimals(),
            quoteAsset.decimals(),
            amount
        );
    }

    /**
     * @notice Helper function that compares `_getValues` between input 0 and input 1.
     */
    function getValuesDelta(
        ERC20[] calldata baseAssets0,
        uint256[] calldata amounts0,
        ERC20[] calldata baseAssets1,
        uint256[] calldata amounts1,
        ERC20 quoteAsset
    ) external view returns (uint256) {
        uint256 value0 = _getValues(baseAssets0, amounts0, quoteAsset);
        uint256 value1 = _getValues(baseAssets1, amounts1, quoteAsset);
        return value0 - value1;
    }

    /**
     * @notice Helper function that determines the value of assets using `_getValues`.
     */
    function getValues(
        ERC20[] calldata baseAssets,
        uint256[] calldata amounts,
        ERC20 quoteAsset
    ) external view returns (uint256) {
        return _getValues(baseAssets, amounts, quoteAsset);
    }

    /**
     * @notice Get the exchange rate between two assets.
     * @param baseAsset address of the asset to get the exchange rate of in terms of the quote asset
     * @param quoteAsset address of the asset that the base asset is exchanged for
     * @return exchangeRate rate of exchange between the base asset and the quote asset
     */
    function getExchangeRate(
        ERC20 baseAsset,
        ERC20 quoteAsset
    ) public view returns (uint256 exchangeRate) {
        AssetSettings memory baseSettings = getAssetSettings[baseAsset];
        AssetSettings memory quoteSettings = getAssetSettings[quoteAsset];
        if (baseSettings.derivative == 0)
            revert UniversalOracle__UnsupportedAsset(address(baseAsset));
        if (quoteSettings.derivative == 0)
            revert UniversalOracle__UnsupportedAsset(address(quoteAsset));

        exchangeRate = _getExchangeRate(
            baseAsset,
            baseSettings,
            quoteAsset,
            quoteSettings,
            quoteAsset.decimals()
        );
    }

    /**
     * @notice Get the exchange rates between multiple assets and another asset.
     * @param baseAssets addresses of the assets to get the exchange rates of in terms of the quote asset
     * @param quoteAsset address of the asset that the base assets are exchanged for
     * @return exchangeRates rate of exchange between the base assets and the quote asset
     */
    function getExchangeRates(
        ERC20[] memory baseAssets,
        ERC20 quoteAsset
    ) external view returns (uint256[] memory exchangeRates) {
        uint8 quoteAssetDecimals = quoteAsset.decimals();
        AssetSettings memory quoteSettings = getAssetSettings[quoteAsset];
        if (quoteSettings.derivative == 0)
            revert UniversalOracle__UnsupportedAsset(address(quoteAsset));

        uint256 numOfAssets = baseAssets.length;
        exchangeRates = new uint256[](numOfAssets);
        for (uint256 i; i < numOfAssets; ++i) {
            AssetSettings memory baseSettings = getAssetSettings[baseAssets[i]];
            if (baseSettings.derivative == 0)
                revert UniversalOracle__UnsupportedAsset(
                    address(baseAssets[i])
                );
            exchangeRates[i] = _getExchangeRate(
                baseAssets[i],
                baseSettings,
                quoteAsset,
                quoteSettings,
                quoteAssetDecimals
            );
        }
    }

    // =========================================== HELPER FUNCTIONS ===========================================

    /**
     * @notice Gets the exchange rate between a base and a quote asset
     * @param baseAsset the asset to convert into quoteAsset
     * @param quoteAsset the asset base asset is converted into
     * @return exchangeRate value of base asset in terms of quote asset
     */
    function _getExchangeRate(
        ERC20 baseAsset,
        AssetSettings memory baseSettings,
        ERC20 quoteAsset,
        AssetSettings memory quoteSettings,
        uint8 quoteAssetDecimals
    ) internal view returns (uint256) {
        uint256 basePrice = _getPriceInUSD(baseAsset, baseSettings);
        uint256 quotePrice = _getPriceInUSD(quoteAsset, quoteSettings);
        uint256 exchangeRate = basePrice.mulDivDown(
            10 ** quoteAssetDecimals,
            quotePrice
        );
        return exchangeRate;
    }

    /**
     * @notice Helper function to get an assets price in USD.
     * @dev Returns price in USD with 8 decimals.
     */
    function _getPriceInUSD(
        ERC20 asset,
        AssetSettings memory settings
    ) internal view returns (uint256) {
        _runPreFlightCheck();
        // Call get price function using appropriate derivative.
        uint256 price;
        if (settings.derivative == 1) {
            price = _getPriceForChainlinkDerivative(asset, settings.source);
        } else if (settings.derivative == 2) {
            price = AdditionalSource(settings.source).getPriceInUSD(asset);
        } else revert UniversalOracle__UnknownDerivative(settings.derivative);

        return price;
    }

    /**
     * @notice If any safety checks needs to be run before pricing operations, they should be added here.
     */
    function _runPreFlightCheck() internal view virtual {}

    /**
     * @notice math function that preserves precision by multiplying the amountBase before dividing.
     * @param priceBaseUSD the base asset price in USD
     * @param priceQuoteUSD the quote asset price in USD
     * @param baseDecimals the base asset decimals
     * @param quoteDecimals the quote asset decimals
     * @param amountBase the amount of base asset
     */
    function _getValueInQuote(
        uint256 priceBaseUSD,
        uint256 priceQuoteUSD,
        uint8 baseDecimals,
        uint8 quoteDecimals,
        uint256 amountBase
    ) internal pure returns (uint256 valueInQuote) {
        // Get value in quote asset, but maintain as much precision as possible.
        // Cleaner equations below.
        // baseToUSD = amountBase * priceBaseUSD / 10**baseDecimals.
        // valueInQuote = baseToUSD * 10**quoteDecimals / priceQuoteUSD
        valueInQuote = amountBase.mulDivDown(
            (priceBaseUSD * 10 ** quoteDecimals),
            (10 ** baseDecimals * priceQuoteUSD)
        );
    }

    /**
     * @notice Get the total value of multiple assets in terms of another asset.
     * @param baseAssets addresses of the assets to get the price of in terms of the quote asset
     * @param amounts amounts of each base asset to price
     * @param quoteAsset address of the assets that the base asset is priced in terms of
     * @return value total value of the amounts of each base assets specified in terms of the quote asset
     */
    function _getValues(
        ERC20[] calldata baseAssets,
        uint256[] calldata amounts,
        ERC20 quoteAsset
    ) internal view returns (uint256) {
        if (baseAssets.length != amounts.length)
            revert UniversalOracle__LengthMismatch();
        uint256 quotePrice;
        {
            AssetSettings memory quoteSettings = getAssetSettings[quoteAsset];
            if (quoteSettings.derivative == 0)
                revert UniversalOracle__UnsupportedAsset(address(quoteAsset));
            quotePrice = _getPriceInUSD(quoteAsset, quoteSettings);
        }
        uint256 valueInQuote;
        uint8 quoteDecimals = quoteAsset.decimals();

        for (uint256 i = 0; i < baseAssets.length; ++i) {
            // Skip zero amount values.
            if (amounts[i] == 0) continue;
            ERC20 baseAsset = baseAssets[i];
            if (baseAsset == quoteAsset) valueInQuote += amounts[i];
            else {
                uint256 basePrice;
                {
                    AssetSettings memory baseSettings = getAssetSettings[
                        baseAsset
                    ];
                    if (baseSettings.derivative == 0)
                        revert UniversalOracle__UnsupportedAsset(
                            address(baseAsset)
                        );
                    basePrice = _getPriceInUSD(baseAsset, baseSettings);
                }
                valueInQuote += _getValueInQuote(
                    basePrice,
                    quotePrice,
                    baseAsset.decimals(),
                    quoteDecimals,
                    amounts[i]
                );
            }
        }
        return valueInQuote;
    }

    // =========================================== CHAINLINK PRICE DERIVATIVE ===========================================\

    /**
     * @notice Setup function for pricing Chainlink derivative assets.
     * @dev _source The address of the Chainlink Data feed.
     * @dev _storage A ChainlinkDerivativeStorage value defining valid prices.
     */
    function _setupPriceForChainlinkDerivative(
        ERC20 _asset,
        address _source,
        bytes memory _storage
    ) internal {
        ChainlinkDerivativeStorage memory parameters = abi.decode(
            _storage,
            (ChainlinkDerivativeStorage)
        );

        // Use Chainlink to get the min and max of the asset.
        IChainlinkAggregator aggregator = IChainlinkAggregator(
            IChainlinkAggregator(_source).aggregator()
        );
        uint256 minFromChainklink = uint256(uint192(aggregator.minAnswer()));
        uint256 maxFromChainlink = uint256(uint192(aggregator.maxAnswer()));

        // Add a ~10% buffer to minimum and maximum price from Chainlink because Chainlink can stop updating
        // its price before/above the min/max price.
        uint256 bufferedMinPrice = (minFromChainklink * 1.1e18) / 1e18;
        uint256 bufferedMaxPrice = (maxFromChainlink * 0.9e18) / 1e18;

        if (parameters.min == 0) {
            // Revert if bufferedMinPrice overflows because uint80 is too small to hold the minimum price,
            // and lowering it to uint80 is not safe because the price feed can stop being updated before
            // it actually gets to that lower price.
            if (bufferedMinPrice > type(uint80).max)
                revert UniversalOracle__BufferedMinOverflow();
            parameters.min = uint80(bufferedMinPrice);
        } else {
            if (parameters.min < bufferedMinPrice)
                revert UniversalOracle__InvalidMinPrice(
                    parameters.min,
                    bufferedMinPrice
                );
        }

        if (parameters.max == 0) {
            //Do not revert even if bufferedMaxPrice is greater than uint144, because lowering it to uint144 max is more conservative.
            parameters.max = bufferedMaxPrice > type(uint144).max
                ? type(uint144).max
                : uint144(bufferedMaxPrice);
        } else {
            if (parameters.max > bufferedMaxPrice)
                revert UniversalOracle__InvalidMaxPrice(
                    parameters.max,
                    bufferedMaxPrice
                );
        }

        if (parameters.min >= parameters.max)
            revert UniversalOracle__MinPriceGreaterThanMaxPrice(
                parameters.min,
                parameters.max
            );

        parameters.heartbeat = parameters.heartbeat != 0
            ? parameters.heartbeat
            : DEFAULT_HEART_BEAT;

        getChainlinkDerivativeStorage[_asset] = parameters;
    }

    /**
     * @notice Get the price of a Chainlink derivative in terms of USD.
     */
    function _getPriceForChainlinkDerivative(
        ERC20 _asset,
        address _source
    ) internal view returns (uint256) {
        ChainlinkDerivativeStorage
            memory parameters = getChainlinkDerivativeStorage[_asset];
        IChainlinkAggregator aggregator = IChainlinkAggregator(_source);
        (, int256 _price, , uint256 _timestamp, ) = aggregator
            .latestRoundData();
        uint256 price = _price.toUint256();
        _checkPriceFeed(
            address(_asset),
            price,
            _timestamp,
            parameters.max,
            parameters.min,
            parameters.heartbeat
        );
        // If price is in ETH, then convert price into USD.
        if (parameters.inETH) {
            uint256 _ethToUsd = _getPriceInUSD(WETH, getAssetSettings[WETH]);
            price = price.mulWadDown(_ethToUsd);
        }
        return price;
    }

    /**
     * @notice helper function to validate a price feed is safe to use.
     * @param asset ERC20 asset price feed data is for.
     * @param value the price value the price feed gave.
     * @param timestamp the last timestamp the price feed was updated.
     * @param max the upper price bound
     * @param min the lower price bound
     * @param heartbeat the max amount of time between price updates
     */
    function _checkPriceFeed(
        address asset,
        uint256 value,
        uint256 timestamp,
        uint144 max,
        uint88 min,
        uint24 heartbeat
    ) internal view {
        if (value < min)
            revert UniversalOracle__AssetBelowMinPrice(
                address(asset),
                value,
                min
            );

        if (value > max)
            revert UniversalOracle__AssetAboveMaxPrice(
                address(asset),
                value,
                max
            );

        uint256 timeSinceLastUpdate = block.timestamp - timestamp;
        if (timeSinceLastUpdate > heartbeat)
            revert UniversalOracle__StalePrice(
                address(asset),
                timeSinceLastUpdate,
                heartbeat
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.24;

library Math {
    /**
     * @notice Substract with a floor of 0 for the result.
     */
    function subMinZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x - y : 0;
    }

    /**
     * @notice Used to change the decimals of precision used for an amount.
     */
    function changeDecimals(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return amount;
        } else if (fromDecimals < toDecimals) {
            return amount * 10 ** (toDecimals - fromDecimals);
        } else {
            return amount / 10 ** (fromDecimals - toDecimals);
        }
    }

    // ===================================== OPENZEPPELIN'S MATH =====================================

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // ================================= SOLMATE's FIXEDPOINTMATHLIB =================================

    uint256 public constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
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
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 value => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
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

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
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
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}