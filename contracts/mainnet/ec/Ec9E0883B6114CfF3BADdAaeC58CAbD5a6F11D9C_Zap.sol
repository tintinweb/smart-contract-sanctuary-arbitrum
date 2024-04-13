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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Querier is IERC20 {
    function decimals() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for WETH9
interface IWETH9 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZap {
    /// @dev get zap data
    function slippageToleranceNumerator() external view returns (uint24);

    function getSwapInfo(
        address inputToken,
        address outputToken
    )
        external
        view
        returns (
            bool isPathDefined,
            address[] memory swapPathArray,
            uint24[] memory swapTradeFeeArray
        );

    function getTokenExchangeRate(
        address inputToken,
        address outputToken
    )
        external
        view
        returns (
            address token0,
            address token1,
            uint256 tokenPriceWith18Decimals
        );

    function getMinimumSwapOutAmount(
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) external view returns (uint256 minimumSwapOutAmount);

    /// @dev swapToken
    function swapToken(
        bool isETH,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        address recipient
    ) external payable returns (uint256 outputAmount);

    function swapTokenWithMinimumOutput(
        bool isETH,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 minimumSwapOutAmount,
        address recipient
    ) external payable returns (uint256 outputAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZapEvent {
    event UpdateSlippageTolerance(uint24 slippageTolerance);

    event UpdateSwapTradeFee(
        address indexed inputToken,
        address indexed outputToken,
        uint24 swapTradeFee
    );

    event UpdateSwapPath(
        address indexed inputToken,
        address indexed outputToken,
        address[] newSwapPath
    );

    event SingleSwap(
        address indexed recipient,
        bool isETH,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 outputAmount,
        address[] swapPath,
        uint24[] swapTradeFee
    );

    event MultiSwap(
        address indexed recipient,
        bool isETH,
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 outputAmount,
        address[] swapPath,
        uint24[] swapTradeFee
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface ISwapRouter {
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IUniswapV3Pool {
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

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Constants {
    /// @dev ArbiturmOne & Goerli uniswap V3
    address public constant UNISWAP_V3_FACTORY_ADDRESS =
        address(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address public constant NONFUNGIBLE_POSITION_MANAGER_ADDRESS =
        address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address public constant SWAP_ROUTER_ADDRESS =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @dev ArbiturmOne token address
    address public constant WETH_ADDRESS =
        address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public constant ARB_ADDRESS =
        address(0x912CE59144191C1204E64559FE8253a0e49E6548);
    address public constant WBTC_ADDRESS =
        address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    address public constant USDC_ADDRESS =
        address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    address public constant USDCE_ADDRESS =
        address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address public constant USDT_ADDRESS =
        address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    address public constant RDNT_ADDRESS =
        address(0x3082CC23568eA640225c2467653dB90e9250AaA0);
    address public constant LINK_ADDRESS =
        address(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4);

    /// @dev black hole address
    address public constant BLACK_HOLE_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ZapConstants {
    /// @dev decimal precision
    uint256 public constant DECIMALS_PRECISION = 18;

    /// @dev denominator
    uint24 public constant SLIPPAGE_TOLERANCE_DENOMINATOR = 1000000;
    uint24 public constant SWAP_TRADE_FEE_DENOMINATOR = 1000000;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ParameterVerificationHelper {
    function verifyNotZeroAddress(address inputAddress) internal pure {
        require(inputAddress != address(0), "input zero address");
    }

    function verifyGreaterThanZero(uint256 inputNumber) internal pure {
        require(inputNumber > 0, "input 0");
    }

    function verifyGreaterThanZero(int24 inputNumber) internal pure {
        require(inputNumber > 0, "input 0");
    }

    function verifyGreaterThanOne(int24 inputNumber) internal pure {
        require(inputNumber > 1, "input <= 1");
    }

    function verifyGreaterThanOrEqualToZero(int24 inputNumber) internal pure {
        require(inputNumber >= 0, "input less than 0");
    }

    function verifyPairTokensHaveWeth(
        address token0Address,
        address token1Address,
        address wethAddress
    ) internal pure {
        require(
            token0Address == wethAddress || token1Address == wethAddress,
            "pair token not have WETH"
        );
    }

    function verifyMsgValueEqualsInputAmount(
        uint256 inputAmount
    ) internal view {
        require(msg.value == inputAmount, "msg.value != inputAmount");
    }

    function verifyPairTokensHaveInputToken(
        address token0Address,
        address token1Address,
        address inputToken
    ) internal pure {
        require(
            token0Address == inputToken || token1Address == inputToken,
            "pair token not have inputToken"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/external/IERC20Querier.sol";
import "../interfaces/uniswapV3/IUniswapV3Factory.sol";
import "../interfaces/uniswapV3/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library PoolHelper {
    using SafeMath for uint256;

    function getPoolAddress(
        address uniswapV3FactoryAddress,
        address tokenA,
        address tokenB,
        uint24 poolFee
    ) internal view returns (address poolAddress) {
        return
            IUniswapV3Factory(uniswapV3FactoryAddress).getPool(
                tokenA,
                tokenB,
                poolFee
            );
    }

    function getPoolInfo(
        address poolAddress
    )
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 poolFee,
            int24 tick,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        )
    {
        (sqrtPriceX96, tick, , , , , ) = IUniswapV3Pool(poolAddress).slot0();
        token0 = IUniswapV3Pool(poolAddress).token0();
        token1 = IUniswapV3Pool(poolAddress).token1();
        poolFee = IUniswapV3Pool(poolAddress).fee();
        decimal0 = IERC20Querier(token0).decimals();
        decimal1 = IERC20Querier(token1).decimals();
    }

    /// @dev formula explanation
    /*
    [Original formula (without decimal precision)]
    (token1 * (10^decimal1)) / (token0 * (10^decimal0)) = (sqrtPriceX96 / (2^96))^2   
    tokenPrice = token1/token0 = (sqrtPriceX96 / (2^96))^2 * (10^decimal0) / (10^decimal1)

    [Formula with decimal precision & decimal adjustment]
    tokenPriceWithDecimalAdj = tokenPrice * (10^decimalPrecision)
        = (sqrtPriceX96 * (10^decimalPrecision) / (2^96))^2 
            / 10^(decimalPrecision + decimal1 - decimal0)
    */
    function getTokenPriceWithDecimalsByPool(
        address poolAddress,
        uint256 decimalPrecision
    ) internal view returns (uint256 tokenPriceWithDecimals) {
        (
            ,
            ,
            ,
            ,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        ) = getPoolInfo(poolAddress);

        // when decimalPrecision is 18,
        // calculation restriction: 79228162514264337594 <= sqrtPriceX96 <= type(uint160).max
        uint256 scaledPriceX96 = uint256(sqrtPriceX96)
            .mul(10 ** decimalPrecision)
            .div(2 ** 96);
        uint256 tokenPriceWithoutDecimalAdj = scaledPriceX96.mul(
            scaledPriceX96
        );
        uint256 decimalAdj = decimalPrecision.add(decimal1).sub(decimal0);
        uint256 result = tokenPriceWithoutDecimalAdj.div(10 ** decimalAdj);
        require(result > 0, "token price too small");
        tokenPriceWithDecimals = result;
    }

    function getTokenDecimalAdjustment(
        address token
    ) internal view returns (uint256 decimalAdjustment) {
        uint256 tokenDecimalStandard = 18;
        uint256 decimal = IERC20Querier(token).decimals();
        return tokenDecimalStandard.sub(decimal);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/external/IERC20Querier.sol";
import "./interfaces/external/IWETH9.sol";
import "./interfaces/IZap.sol";
import "./interfaces/IZapEvent.sol";
import "./interfaces/uniswapV3/ISwapRouter.sol";
import "./libraries/constants/ZapConstants.sol";
import "./libraries/constants/Constants.sol";
import "./libraries/uniswapV3/TransferHelper.sol";
import "./libraries/ParameterVerificationHelper.sol";
import "./libraries/PoolHelper.sol";
import "./ZapInitializer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @dev verified, public contract
/// @dev ceratin functions only owner callable
contract Zap is IZap, IZapEvent, Ownable, ZapInitializer {
    using SafeMath for uint256;
    uint24 public override slippageToleranceNumerator;

    address public WETH;

    constructor(uint24 _slippageToleranceNumerator) {
        // initialize pre-defined swapPath and swapTradeFeeNumerator
        initializeSwapTradeFeeNumerator();
        initializeSwapPath();
        slippageToleranceNumerator = _slippageToleranceNumerator;
        WETH = Constants.WETH_ADDRESS;
    }

    function getSwapInfo(
        address inputToken,
        address outputToken
    )
        public
        view
        override
        returns (
            bool isPathDefined,
            address[] memory swapPathArray,
            uint24[] memory swapTradeFeeArray
        )
    {
        // parameter verification
        ParameterVerificationHelper.verifyNotZeroAddress(inputToken);
        ParameterVerificationHelper.verifyNotZeroAddress(outputToken);

        // verify inputToken is not outputToken
        require(inputToken != outputToken, "inputToken == outputToken");

        // get swapPath
        address[] memory _swapPathArray = swapPath[inputToken][outputToken];
        uint256 pathLength = _swapPathArray.length;

        if (pathLength >= 2) {
            // statement for "single swap path" & "multiple swap path"
            bool _isPathDefined = true;
            uint24[] memory _swapTradeFeeArray = new uint24[](pathLength - 1);

            for (uint i = 0; i < (pathLength - 1); i++) {
                uint24 tradeFee = swapTradeFeeNumerator[_swapPathArray[i]][
                    _swapPathArray[i + 1]
                ];
                if (tradeFee == 0) {
                    // path not defined if tradeFee is 0
                    _isPathDefined = false;
                }
                _swapTradeFeeArray[i] = tradeFee;
            }
            return (_isPathDefined, _swapPathArray, _swapTradeFeeArray);
        } else {
            // statement for "path is not defined"
            return (false, new address[](0), new uint24[](0));
        }
    }

    function setSlippageToleranceNumerator(
        uint24 slippageTolerance
    ) public onlyOwner {
        // parameter verification
        ParameterVerificationHelper.verifyGreaterThanZero(slippageTolerance);

        // verify slippageTolerance is less than SLIPPAGE_TOLERANCE_DENOMINATOR
        require(
            slippageTolerance < ZapConstants.SLIPPAGE_TOLERANCE_DENOMINATOR,
            "slippageTolerance too big"
        );

        // update slippageToleranceNumerator
        slippageToleranceNumerator = slippageTolerance;

        // emit UpdateSlippageTolerance event
        emit UpdateSlippageTolerance(slippageTolerance);
    }

    function setSwapTradeFeeNumerator(
        address inputToken,
        address outputToken,
        uint24 swapTradeFee
    ) public onlyOwner {
        // parameter verification
        ParameterVerificationHelper.verifyNotZeroAddress(inputToken);
        ParameterVerificationHelper.verifyNotZeroAddress(outputToken);
        ParameterVerificationHelper.verifyGreaterThanZero(swapTradeFee);

        // verify inputToken is not outputToken
        require(inputToken != outputToken, "inputToken == outputToken");

        // verify pool is exist
        address poolAddress = PoolHelper.getPoolAddress(
            Constants.UNISWAP_V3_FACTORY_ADDRESS,
            inputToken,
            outputToken,
            swapTradeFee
        );
        require(poolAddress != address(0), "pool not exist");

        // update swapTradeFeeNumerator
        swapTradeFeeNumerator[inputToken][outputToken] = swapTradeFee;

        // emit UpdateSwapTradeFee event
        emit UpdateSwapTradeFee(inputToken, outputToken, swapTradeFee);
    }

    function setSwapPath(
        address inputToken,
        address outputToken,
        address[] memory newSwapPath
    ) public onlyOwner {
        // parameter verification
        ParameterVerificationHelper.verifyNotZeroAddress(inputToken);
        ParameterVerificationHelper.verifyNotZeroAddress(outputToken);
        uint256 pathLength = newSwapPath.length;
        for (uint i = 0; i < pathLength; i++) {
            ParameterVerificationHelper.verifyNotZeroAddress(newSwapPath[i]);
        }

        // verify inputToken is not outputToken
        require(inputToken != outputToken, "inputToken == outputToken");

        // verify input path is valid swap path
        require(pathLength >= 2, "path too short");

        // verify first token in newSwapPath is inputToken
        require(newSwapPath[0] == inputToken, "path not start from inputToken");

        // verify last token in newSwapPath is outputToken
        require(
            newSwapPath[(pathLength - 1)] == outputToken,
            "path not end with outputToken"
        );

        // verify each swap’s fee is defined
        for (uint i = 0; i < (pathLength - 1); i++) {
            uint24 tradeFee = swapTradeFeeNumerator[newSwapPath[i]][
                newSwapPath[i + 1]
            ];
            require(tradeFee != 0, "tradefee not defined");
        }

        // update Swap Path
        swapPath[inputToken][outputToken] = newSwapPath;

        // emit UpdateSwapPath event
        emit UpdateSwapPath(inputToken, outputToken, newSwapPath);
    }

    function getTokenExchangeRate(
        address inputToken,
        address outputToken
    )
        public
        view
        override
        returns (
            address token0,
            address token1,
            uint256 tokenPriceWith18Decimals
        )
    {
        // parameter verification
        ParameterVerificationHelper.verifyNotZeroAddress(inputToken);
        ParameterVerificationHelper.verifyNotZeroAddress(outputToken);

        // verify inputToken is not outputToken
        require(inputToken != outputToken, "inputToken == outputToken");

        // verify swap trade fee is defined
        uint24 tradeFee = swapTradeFeeNumerator[inputToken][outputToken];
        require(tradeFee != 0, "tradeFee not define");

        // verify pool is exist
        address poolAddress = PoolHelper.getPoolAddress(
            Constants.UNISWAP_V3_FACTORY_ADDRESS,
            inputToken,
            outputToken,
            tradeFee
        );
        require(poolAddress != address(0), "pool not exist");

        // query pool info
        (token0, token1, , , , , ) = PoolHelper.getPoolInfo(poolAddress);

        // calculate token price with 18 decimal precision
        tokenPriceWith18Decimals = PoolHelper.getTokenPriceWithDecimalsByPool(
            poolAddress,
            ZapConstants.DECIMALS_PRECISION
        );
    }

    function getMinimumSwapOutAmount(
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) public view override returns (uint256 minimumSwapOutAmount) {
        uint256 estimateSwapOutAmount = getEstimateSwapOutAmount(
            inputToken,
            outputToken,
            inputAmount
        );

        // calculate price include slippage tolerance
        uint256 _minimumSwapOutAmount = estimateSwapOutAmount
            .mul(
                uint256(ZapConstants.SLIPPAGE_TOLERANCE_DENOMINATOR).sub(
                    slippageToleranceNumerator
                )
            )
            .div(ZapConstants.SLIPPAGE_TOLERANCE_DENOMINATOR);

        minimumSwapOutAmount = _minimumSwapOutAmount;
    }

    function getEstimateSwapOutAmount(
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) public view returns (uint256 estimateSwapOutAmount) {
        // parameter verification
        ParameterVerificationHelper.verifyNotZeroAddress(inputToken);
        ParameterVerificationHelper.verifyNotZeroAddress(outputToken);
        ParameterVerificationHelper.verifyGreaterThanZero(inputAmount);

        // variable verification
        require(
            slippageToleranceNumerator > 0,
            "slippageToleranceNumerator is 0"
        );

        // verify inputToken is not outputToken
        require(inputToken != outputToken, "inputToken == outputToken");

        // verify swap info is defined
        (
            bool isPathDefined,
            address[] memory swapPathArray,
            uint24[] memory swapTradeFeeArray
        ) = getSwapInfo(inputToken, outputToken);
        require(isPathDefined == true, "path not define");

        // get swap path length as loop end index
        uint256 pathLength = swapPathArray.length;

        // intput token decimal adjustment
        uint256 calcAmount = inputAmount.mul(
            10 ** (PoolHelper.getTokenDecimalAdjustment(inputToken))
        );
        // Loop calculate minimum swap out amount
        for (uint i = 0; i < (pathLength - 1); i++) {
            address tokenIn = swapPathArray[i];
            address tokenOut = swapPathArray[i + 1];
            (
                address token0,
                address token1,
                uint256 tokenPriceWith18Decimals // (token1/token0) * 10**DECIMALS_PRECISION
            ) = getTokenExchangeRate(tokenIn, tokenOut);

            // deduct trade fee
            calcAmount = calcAmount
                .mul(
                    uint256(ZapConstants.SWAP_TRADE_FEE_DENOMINATOR).sub(
                        swapTradeFeeArray[i]
                    )
                )
                .div(ZapConstants.SWAP_TRADE_FEE_DENOMINATOR);

            // get swap out amount without slippage
            require(tokenIn == token0 || tokenIn == token1);
            if (tokenIn == token0) {
                calcAmount = calcAmount.mul(tokenPriceWith18Decimals).div(
                    10 ** ZapConstants.DECIMALS_PRECISION
                );
            } else {
                calcAmount = calcAmount
                    .mul(10 ** ZapConstants.DECIMALS_PRECISION)
                    .div(tokenPriceWith18Decimals);
            }
        }

        // output token decimal adjustment
        estimateSwapOutAmount = calcAmount.div(
            10 ** (PoolHelper.getTokenDecimalAdjustment(outputToken))
        );
    }

    /// @notice caller need to approve inputToken to Zap contract in inputAmount amount
    function swapToken(
        bool isETH,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        address recipient
    ) public payable override returns (uint256 outputAmount) {
        // get minimum swap out amount
        uint256 minimumSwapOutAmount = getMinimumSwapOutAmount(
            inputToken,
            outputToken,
            inputAmount
        );

        outputAmount = swapTokenWithMinimumOutput(
            isETH,
            inputToken,
            outputToken,
            inputAmount,
            minimumSwapOutAmount,
            recipient
        );
    }

    /// @notice caller need to approve inputToken to Zap contract in inputAmount amount
    function swapTokenWithMinimumOutput(
        bool isETH,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 minimumSwapOutAmount,
        address recipient
    ) public payable override returns (uint256 outputAmount) {
        // parameter verification
        ParameterVerificationHelper.verifyNotZeroAddress(inputToken);
        ParameterVerificationHelper.verifyNotZeroAddress(outputToken);
        ParameterVerificationHelper.verifyNotZeroAddress(recipient);
        ParameterVerificationHelper.verifyGreaterThanZero(inputAmount);

        // verify inputToken is not outputToken
        require(inputToken != outputToken, "inputToken == outputToken");

        // verify swap info is defined
        (
            bool isPathDefined,
            address[] memory swapPathArray,
            uint24[] memory swapTradeFeeArray
        ) = getSwapInfo(inputToken, outputToken);
        require(isPathDefined == true, "path not define");

        if (isETH) {
            // verify input ETH is the same as inputAmount
            ParameterVerificationHelper.verifyMsgValueEqualsInputAmount(
                inputAmount
            );
            require(
                inputToken == WETH,
                "input ETH must have swap path from WETH"
            );

            // prepare WETH for swap
            IWETH9(WETH).deposit{value: inputAmount}();
        } else {
            // verify caller inputToken allowance is more or equal to inputAmount
            require(
                IERC20Querier(inputToken).allowance(
                    msg.sender,
                    address(this)
                ) >= inputAmount,
                "allowance insufficient"
            );

            // transfer inputToken in inputAmount from caller to Zap contract
            TransferHelper.safeTransferFrom(
                inputToken,
                msg.sender,
                address(this),
                inputAmount
            );
        }

        // approve inputToken to SmartRouter in inputAmount amount
        TransferHelper.safeApprove(
            inputToken,
            Constants.SWAP_ROUTER_ADDRESS,
            inputAmount
        );

        uint256 pathLength = swapPathArray.length;
        if (pathLength == 2) {
            // statement for "single swap path", swap by exactInputSingle function
            outputAmount = ISwapRouter(Constants.SWAP_ROUTER_ADDRESS)
                .exactInputSingle(
                    ISwapRouter.ExactInputSingleParams(
                        inputToken,
                        outputToken,
                        swapTradeFeeArray[0],
                        recipient,
                        block.timestamp.add(transactionDeadlineDuration),
                        inputAmount,
                        minimumSwapOutAmount,
                        0
                    )
                );
            // emit SingleSwap event
            emit SingleSwap(
                recipient,
                isETH,
                inputToken,
                inputAmount,
                outputToken,
                outputAmount,
                swapPathArray,
                swapTradeFeeArray
            );
        } else {
            // statement for "multiple swap path", swap by exactInput function
            bytes memory path = abi.encodePacked(swapPathArray[0]);
            for (uint i = 0; i < (pathLength - 1); i++) {
                path = abi.encodePacked(
                    path,
                    swapTradeFeeArray[i],
                    swapPathArray[i + 1]
                );
            }

            outputAmount = ISwapRouter(Constants.SWAP_ROUTER_ADDRESS)
                .exactInput(
                    ISwapRouter.ExactInputParams(
                        path,
                        recipient,
                        block.timestamp.add(transactionDeadlineDuration),
                        inputAmount,
                        minimumSwapOutAmount
                    )
                );
            // emit MultiSwap event
            emit MultiSwap(
                recipient,
                isETH,
                inputToken,
                inputAmount,
                outputToken,
                outputAmount,
                swapPathArray,
                swapTradeFeeArray
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/constants/Constants.sol";

contract ZapInitializer {
    /// @dev Uniswap-Transaction-related Variable
    uint256 public transactionDeadlineDuration = 300;

    // inputToken => outputToken => swapPath
    mapping(address => mapping(address => address[])) internal swapPath;

    // inputToken => outputToken => swapTradeFeeNumerator
    mapping(address => mapping(address => uint24))
        internal swapTradeFeeNumerator;

    function initializeSwapTradeFeeNumerator() internal {
        address WETH = Constants.WETH_ADDRESS;
        address ARB = Constants.ARB_ADDRESS;
        address WBTC = Constants.WBTC_ADDRESS;
        address USDC = Constants.USDC_ADDRESS;
        address USDCE = Constants.USDCE_ADDRESS;
        address USDT = Constants.USDT_ADDRESS;
        address RDNT = Constants.RDNT_ADDRESS;
        address LINK = Constants.LINK_ADDRESS;

        /// @dev ArbitrumOne mainnet initialization trade fee 0.01%
        swapTradeFeeNumerator[USDC][USDCE] = 100;
        swapTradeFeeNumerator[USDC][USDT] = 100;
        swapTradeFeeNumerator[USDCE][USDC] = 100;
        swapTradeFeeNumerator[USDCE][USDT] = 100;
        swapTradeFeeNumerator[USDT][USDC] = 100;
        swapTradeFeeNumerator[USDT][USDCE] = 100;

        /// @dev ArbitrumOne mainnet initialization trade fee 0.05%
        swapTradeFeeNumerator[WETH][ARB] = 500;
        swapTradeFeeNumerator[WETH][WBTC] = 500;
        swapTradeFeeNumerator[WETH][USDC] = 500;
        swapTradeFeeNumerator[WETH][USDCE] = 500;
        swapTradeFeeNumerator[WETH][USDT] = 500;
        swapTradeFeeNumerator[ARB][WETH] = 500;
        swapTradeFeeNumerator[WBTC][WETH] = 500;
        swapTradeFeeNumerator[USDCE][ARB] = 500;
        swapTradeFeeNumerator[USDCE][WETH] = 500;
        swapTradeFeeNumerator[USDCE][WBTC] = 500;
        swapTradeFeeNumerator[USDT][WETH] = 500;

        /// @dev ArbitrumOne mainnet initialization trade fee 0.30%
        swapTradeFeeNumerator[WETH][RDNT] = 3000;
        swapTradeFeeNumerator[WETH][LINK] = 3000;
        swapTradeFeeNumerator[RDNT][WETH] = 3000;
        swapTradeFeeNumerator[LINK][WETH] = 3000;
    }

    function initializeSwapPath() internal {
        address WETH = Constants.WETH_ADDRESS;
        address ARB = Constants.ARB_ADDRESS;
        address WBTC = Constants.WBTC_ADDRESS;
        address USDC = Constants.USDC_ADDRESS;
        address USDCE = Constants.USDCE_ADDRESS;
        address USDT = Constants.USDT_ADDRESS;
        address RDNT = Constants.RDNT_ADDRESS;
        address LINK = Constants.LINK_ADDRESS;

        /// @dev ArbitrumOne mainnet initialization single swap
        // trade fee 0.01%
        swapPath[USDC][USDCE] = [USDC, USDCE];
        swapPath[USDC][USDT] = [USDC, USDT];
        swapPath[USDCE][USDC] = [USDCE, USDC];
        swapPath[USDCE][USDT] = [USDCE, USDT];
        swapPath[USDT][USDC] = [USDT, USDC];
        swapPath[USDT][USDCE] = [USDT, USDCE];

        /// @dev ArbitrumOne mainnet initialization single swap
        // trade fee 0.05%
        swapPath[WETH][ARB] = [WETH, ARB];
        swapPath[WETH][WBTC] = [WETH, WBTC];
        swapPath[WETH][USDC] = [WETH, USDC];
        swapPath[WETH][USDCE] = [WETH, USDCE];
        swapPath[WETH][USDT] = [WETH, USDT];
        swapPath[ARB][WETH] = [ARB, WETH];
        swapPath[WBTC][WETH] = [WBTC, WETH];
        swapPath[USDCE][ARB] = [USDCE, ARB];
        swapPath[USDCE][WETH] = [USDCE, WETH];
        swapPath[USDT][WETH] = [USDT, WETH];

        /// @dev ArbitrumOne mainnet initialization single swap
        // trade fee 0.30%
        swapPath[WETH][RDNT] = [WETH, RDNT];
        swapPath[WETH][LINK] = [WETH, LINK];
        swapPath[RDNT][WETH] = [RDNT, WETH];
        swapPath[LINK][WETH] = [LINK, WETH];

        /// @dev ArbitrumOne mainnet initialization multi swap
        swapPath[ARB][WBTC] = [ARB, WETH, WBTC];
        swapPath[ARB][USDC] = [ARB, WETH, USDC];
        swapPath[ARB][USDCE] = [ARB, WETH, USDCE];
        swapPath[ARB][USDT] = [ARB, WETH, USDT];
        swapPath[ARB][RDNT] = [ARB, WETH, RDNT];
        swapPath[ARB][LINK] = [ARB, WETH, LINK];

        swapPath[WBTC][ARB] = [WBTC, WETH, ARB];
        swapPath[WBTC][USDC] = [WBTC, WETH, USDC];
        swapPath[WBTC][USDCE] = [WBTC, WETH, USDCE];
        swapPath[WBTC][USDT] = [WBTC, WETH, USDT];
        swapPath[WBTC][RDNT] = [WBTC, WETH, RDNT];
        swapPath[WBTC][LINK] = [WBTC, WETH, LINK];

        swapPath[USDC][ARB] = [USDC, USDCE, ARB];
        swapPath[USDC][WETH] = [USDC, USDCE, WETH];
        swapPath[USDC][WBTC] = [USDC, USDCE, WBTC];
        swapPath[USDC][RDNT] = [USDC, USDCE, WETH, RDNT];
        swapPath[USDC][LINK] = [USDC, USDCE, WETH, LINK];

        swapPath[USDCE][WBTC] = [USDCE, WETH, WBTC];
        swapPath[USDCE][RDNT] = [USDCE, WETH, RDNT];
        swapPath[USDCE][LINK] = [USDCE, WETH, LINK];

        swapPath[USDT][ARB] = [USDT, USDCE, ARB];
        swapPath[USDT][WBTC] = [USDT, USDCE, WBTC];
        swapPath[USDT][RDNT] = [USDT, WETH, RDNT];
        swapPath[USDT][LINK] = [USDT, WETH, LINK];

        swapPath[RDNT][ARB] = [RDNT, WETH, ARB];
        swapPath[RDNT][WBTC] = [RDNT, WETH, WBTC];
        swapPath[RDNT][USDC] = [RDNT, WETH, USDC];
        swapPath[RDNT][USDCE] = [RDNT, WETH, USDCE];
        swapPath[RDNT][USDT] = [RDNT, WETH, USDT];
        swapPath[RDNT][LINK] = [RDNT, WETH, LINK];

        swapPath[LINK][ARB] = [LINK, WETH, ARB];
        swapPath[LINK][WBTC] = [LINK, WETH, WBTC];
        swapPath[LINK][USDC] = [LINK, WETH, USDC];
        swapPath[LINK][USDCE] = [LINK, WETH, USDCE];
        swapPath[LINK][USDT] = [LINK, WETH, USDT];
        swapPath[LINK][RDNT] = [LINK, WETH, RDNT];
    }
}