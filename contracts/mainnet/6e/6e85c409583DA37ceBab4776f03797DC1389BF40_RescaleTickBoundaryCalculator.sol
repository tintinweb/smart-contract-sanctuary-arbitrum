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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IConstants {
    /// @dev Uniswap v3 Related
    function UNISWAP_V3_FACTORY_ADDRESS() external view returns (address);
    function NONFUNGIBLE_POSITION_MANAGER_ADDRESS() external view returns (address);
    function SWAP_ROUTER_ADDRESS() external view returns (address);

    /// @dev Distribute reward token address
    function DISTRIBUTE_REWARD_ADDRESS() external view returns (address);

    /// @dev Token address (combine each chain)
    function WETH_ADDRESS() external view returns (address);
    function WBTC_ADDRESS() external view returns (address);
    function ARB_ADDRESS() external view returns (address);
    function USDC_ADDRESS() external view returns (address);
    function USDCE_ADDRESS() external view returns (address);
    function USDT_ADDRESS() external view returns (address);
    function RDNT_ADDRESS() external view returns (address);
    function LINK_ADDRESS() external view returns (address);
    function DEGEN_ADDRESS() external view returns (address);
    function BRETT_ADDRESS() external view returns (address);
    function TOSHI_ADDRESS() external view returns (address);
    function CIRCLE_ADDRESS() external view returns (address);
    function ROOST_ADDRESS() external view returns (address);
    function AERO_ADDRESS() external view returns (address);
    function INT_ADDRESS() external view returns (address);
    function HIGHER_ADDRESS() external view returns (address);
    function KEYCAT_ADDRESS() external view returns (address);

    /// @dev Black hole address
    function BLACK_HOLE_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IController {
    function tickSpreadUpper(address strategyAddress) external view returns (int24);

    function tickSpreadLower(address strategyAddress) external view returns (int24);

    function tickGapUpper(address strategyAddress) external view returns (int24);

    function tickGapLower(address strategyAddress) external view returns (int24);

    function tickUpperBoundaryOffset(address strategyAddress) external view returns (int24);

    function tickLowerBoundaryOffset(address strategyAddress) external view returns (int24);

    function rescaleTickUpperBoundaryOffset(address strategyAddress) external view returns (int24);

    function rescaleTickLowerBoundaryOffset(address strategyAddress) external view returns (int24);

    function lastRescaleTick(address strategyAddress) external view returns (int24);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRescaleTickBoundaryCalculator {
    function verifyAndGetNewRescaleTickBoundary(
        bool wasInRange,
        int24 lastRescaleTick,
        address strategyAddress,
        address controllerAddress
    )
        external
        view
        returns (bool allowRescale, int24 newTickUpper, int24 newTickLower);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrategyInfo {
    /// @dev Uniswap-Transaction-related Variable
    function transactionDeadlineDuration() external view returns (uint256);

    /// @dev get Liquidity-NFT-related Variable
    function liquidityNftId() external view returns (uint256);

    function tickSpacing() external view returns (int24);

    /// @dev get Pool-related Variable
    function poolAddress() external view returns (address);

    function poolFee() external view returns (uint24);

    function token0Address() external view returns (address);

    function token1Address() external view returns (address);

    /// @dev get Tracker-Token-related Variable
    function trackerTokenAddress() external view returns (address);

    /// @dev get User-Management-related Variable
    function isInUserList(address userAddress) external view returns (bool);

    function userIndex(address userAddress) external view returns (uint256);

    function getAllUsersInUserList() external view returns (address[] memory);

    /// @dev get User-Share-Management-related Variable
    function userShare(address userAddress) external view returns (uint256);

    function totalUserShare() external view returns (uint256);

    /// @dev get Reward-Management-related Variable
    function rewardToken0Amount() external view returns (uint256);

    function rewardToken1Amount() external view returns (uint256);

    function distributeRewardAmount() external view returns (uint256);

    /// @dev get User-Reward-Management-related Variable
    function userDistributeReward(address userAddress) external view returns (uint256);

    function totalUserDistributeReward() external view returns (uint256);

    /// @dev get Buyback-related Variable
    function buyBackToken() external view returns (address);

    function buyBackNumerator() external view returns (uint24);

    /// @dev get Fund-Manager-related Variable
    struct FundManagerVault {
        address fundManagerVaultAddress;
        uint256 fundManagerProfitVaultNumerator;
    }

    function getAllFundManagerVaults() external view returns (FundManagerVault[3] memory);

    /// @dev get Earn-Loop-Control-related Variable
    function earnLoopSegmentSize() external view returns (uint256);

    function earnLoopDistributedAmount() external view returns (uint256);

    function earnLoopStartIndex() external view returns (uint256);

    function isEarning() external view returns (bool);

    /// @dev get Rescale-related Variable
    function dustToken0Amount() external view returns (uint256);

    function dustToken1Amount() external view returns (uint256);

    /// @dev get Constant Variable
    function getBuyBackDenominator() external pure returns (uint24);

    function getFundManagerProfitVaultDenominator() external pure returns (uint24);

    function getFarmAddress() external view returns (address);

    function getControllerAddress() external view returns (address);

    function getSwapAmountCalculatorAddress() external view returns (address);

    function getZapAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface INonfungiblePositionManager {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    )
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
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

import "../interfaces/uniswapV3/INonfungiblePositionManager.sol";
import "./uniswapV3/TickMath.sol";
import "./PoolHelper.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LiquidityNftHelper {
    using SafeMath for uint256;

    function getLiquidityAmountByNftId(
        uint256 liquidityNftId,
        address nonfungiblePositionManagerAddress
    ) internal view returns (uint128 liquidity) {
        (, , , , , , , liquidity, , , , ) = INonfungiblePositionManager(
            nonfungiblePositionManagerAddress
        ).positions(liquidityNftId);
    }

    function getPoolInfoByLiquidityNft(
        uint256 liquidityNftId,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    )
        internal
        view
        returns (
            address poolAddress,
            int24 tick,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        )
    {
        (
            address token0,
            address token1,
            uint24 poolFee,
            ,
            ,
            ,

        ) = getLiquidityNftPositionsInfo(
                liquidityNftId,
                nonfungiblePositionManagerAddress
            );
        poolAddress = PoolHelper.getPoolAddress(
            uniswapV3FactoryAddress,
            token0,
            token1,
            poolFee
        );
        (, , , tick, sqrtPriceX96, decimal0, decimal1) = PoolHelper.getPoolInfo(
            poolAddress
        );
    }

    function getLiquidityNftPositionsInfo(
        uint256 liquidityNftId,
        address nonfungiblePositionManagerAddress
    )
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 poolFee,
            int24 tickLower,
            int24 tickUpper,
            uint160 sqrtRatioAX96,
            uint160 sqrtRatioBX96
        )
    {
        (
            ,
            ,
            token0,
            token1,
            poolFee,
            tickLower,
            tickUpper,
            ,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(nonfungiblePositionManagerAddress)
            .positions(liquidityNftId);
        sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    }

    /// @dev formula explanation
    /*
    [Original formula (without decimal precision)]
    tickUpper -> sqrtRatioBX96
    tickLower -> sqrtRatioAX96
    tick      -> sqrtPriceX96
    (token1 * (10^decimal1)) / (token0 * (10^decimal0)) = 
        (sqrtPriceX96 * sqrtRatioBX96 * (sqrtPriceX96 - sqrtRatioAX96))
            / ((2^192) * (sqrtRatioBX96 - sqrtPriceX96))
    
    [Formula with decimal precision & decimal adjustment]
    liquidityRatioWithDecimalAdj = liquidityRatio * (10^decimalPrecision)
        = (sqrtPriceX96 * (10^decimalPrecision) / (2^96))
            * (sqrtPriceBX96 * (10^decimalPrecision) / (2^96))
            * (sqrtPriceX96 - sqrtRatioAX96)
            / ((sqrtRatioBX96 - sqrtPriceX96) * (10^(decimalPrecision + decimal1 - decimal0)))
    */
    function getInRangeLiquidityRatioWithDecimals(
        uint256 liquidityNftId,
        uint256 decimalPrecision,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    ) internal view returns (uint256 liquidityRatioWithDecimals) {
        // get sqrtPrice of tickUpper, tick, tickLower
        (
            ,
            ,
            ,
            ,
            ,
            uint160 sqrtRatioAX96,
            uint160 sqrtRatioBX96
        ) = getLiquidityNftPositionsInfo(
                liquidityNftId,
                nonfungiblePositionManagerAddress
            );
        (
            ,
            ,
            uint160 sqrtPriceX96,
            uint256 decimal0,
            uint256 decimal1
        ) = getPoolInfoByLiquidityNft(
                liquidityNftId,
                uniswapV3FactoryAddress,
                nonfungiblePositionManagerAddress
            );

        // when decimalPrecision is 18,
        // calculation restriction: 79228162514264337594 <= sqrtPriceX96 <= type(uint160).max
        uint256 scaledPriceX96 = uint256(sqrtPriceX96)
            .mul(10 ** decimalPrecision)
            .div(2 ** 96);
        uint256 scaledPriceBX96 = uint256(sqrtRatioBX96)
            .mul(10 ** decimalPrecision)
            .div(2 ** 96);

        uint256 decimalAdj = decimalPrecision.add(decimal1).sub(decimal0);
        uint256 preLiquidityRatioWithDecimals = scaledPriceX96
            .mul(scaledPriceBX96)
            .div(10 ** decimalAdj);

        liquidityRatioWithDecimals = preLiquidityRatioWithDecimals
            .mul(uint256(sqrtPriceX96).sub(sqrtRatioAX96))
            .div(uint256(sqrtRatioBX96).sub(sqrtPriceX96));
    }

    function verifyInputTokenIsLiquidityNftTokenPair(
        uint256 liquidityNftId,
        address inputToken,
        address nonfungiblePositionManagerAddress
    ) internal view {
        (
            address token0,
            address token1,
            ,
            ,
            ,
            ,

        ) = getLiquidityNftPositionsInfo(
                liquidityNftId,
                nonfungiblePositionManagerAddress
            );
        require(
            inputToken == token0 || inputToken == token1,
            "inputToken not in token pair"
        );
    }

    function verifyCurrentPriceInLiquidityNftRange(
        uint256 liquidityNftId,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    ) internal view returns (bool isInRange, address liquidity0Token) {
        (, int24 tick, , , ) = getPoolInfoByLiquidityNft(
            liquidityNftId,
            uniswapV3FactoryAddress,
            nonfungiblePositionManagerAddress
        );
        (
            address token0,
            address token1,
            ,
            int24 tickLower,
            int24 tickUpper,
            ,

        ) = getLiquidityNftPositionsInfo(
                liquidityNftId,
                nonfungiblePositionManagerAddress
            );

        // tick out of range, tick <= tickLower left token0
        if (tick <= tickLower) {
            return (false, token0);

            // tick in range, tickLower < tick < tickUpper
        } else if (tick < tickUpper) {
            return (true, address(0));

            // tick out of range, tick >= tickUpper left token1
        } else {
            return (false, token1);
        }
    }

    function getTickInfo(
        uint256 liquidityNftId,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    ) internal view returns (int24 tick, int24 tickLower, int24 tickUpper) {
        (, tick, , , ) = getPoolInfoByLiquidityNft(
            liquidityNftId,
            uniswapV3FactoryAddress,
            nonfungiblePositionManagerAddress
        );
        (, , , tickLower, tickUpper, , ) = getLiquidityNftPositionsInfo(
            liquidityNftId,
            nonfungiblePositionManagerAddress
        );
    }

    function verifyNoDuplicateTickAndTickLower(
        uint256 liquidityNftId,
        address uniswapV3FactoryAddress,
        address nonfungiblePositionManagerAddress
    ) internal view {
        (int24 tick, int24 tickLower, ) = getTickInfo(
            liquidityNftId,
            uniswapV3FactoryAddress,
            nonfungiblePositionManagerAddress
        );

        require(tickLower != tick, "tickLower == tick");
    }

    // for general condition (except tickSpacing 1 condition)
    function calculateInitTickBoundary(
        address poolAddress,
        int24 tickSpread,
        int24 tickSpacing
    ) internal view returns (int24 tickLower, int24 tickUpper) {
        require(tickSpacing != 1, "tickSpacing == 1");

        // Get current tick
        (, , , int24 currentTick, , , ) = PoolHelper.getPoolInfo(poolAddress);

        // Calculate the floor tick value
        int24 tickFloor = floorTick(currentTick, tickSpacing);

        // Calculate the tickLower & tickToTickLower value
        tickLower = tickFloor - tickSpacing * tickSpread;
        int24 tickToTickLower = currentTick - tickLower;

        // Calculate the tickUpper & tickUpperToTick value
        tickUpper = floorTick((currentTick + tickToTickLower), tickSpacing);
        int24 tickUpperToTick = tickUpper - currentTick;

        // Check
        // if the tickSpacing is greater than 1
        // and
        // if the (tickToTickLower - tickUpperToTick) is greater than or equal to (tickSpacing / 2)
        if (
            tickSpacing > 1 &&
            (tickToTickLower - tickUpperToTick) >= (tickSpacing / 2)
        ) {
            // Increment the tickUpper by the tickSpacing
            tickUpper += tickSpacing;
        }
    }

    function floorTick(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (int24) {
        int24 baseFloor = tick / tickSpacing;

        if (tick < 0 && tick % tickSpacing != 0) {
            return (baseFloor - 1) * tickSpacing;
        }
        return baseFloor * tickSpacing;
    }

    function ceilingTick(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (int24) {
        int24 baseFloor = tick / tickSpacing;

        if (tick > 0 && tick % tickSpacing != 0) {
            return (baseFloor + 1) * tickSpacing;
        }
        return baseFloor * tickSpacing;
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

    function getPoolAddress(address uniswapV3FactoryAddress, address tokenA, address tokenB, uint24 poolFee)
        internal
        view
        returns (address poolAddress)
    {
        return IUniswapV3Factory(uniswapV3FactoryAddress).getPool(tokenA, tokenB, poolFee);
    }

    function getPoolInfo(address poolAddress)
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
        (sqrtPriceX96, tick,,,,,) = IUniswapV3Pool(poolAddress).slot0();
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
    function getTokenPriceWithDecimalsByPool(address poolAddress, uint256 decimalPrecision)
        internal
        view
        returns (uint256 tokenPriceWithDecimals)
    {
        (,,,, uint160 sqrtPriceX96, uint256 decimal0, uint256 decimal1) = getPoolInfo(poolAddress);

        // when decimalPrecision is 18,
        // calculation restriction: 79228162514264337594 <= sqrtPriceX96 <= type(uint160).max
        uint256 scaledPriceX96 = uint256(sqrtPriceX96).mul(10 ** decimalPrecision).div(2 ** 96);
        uint256 tokenPriceWithoutDecimalAdj = scaledPriceX96.mul(scaledPriceX96);
        uint256 decimalAdj = decimalPrecision.add(decimal1).sub(decimal0);
        uint256 result = tokenPriceWithoutDecimalAdj.div(10 ** decimalAdj);
        require(result > 0, "token price too small");
        tokenPriceWithDecimals = result;
    }

    function getTokenDecimalAdjustment(address token) internal view returns (uint256 decimalAdjustment) {
        uint256 tokenDecimalStandard = 18;
        uint256 decimal = IERC20Querier(token).decimals();
        return tokenDecimalStandard.sub(decimal);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(
        int24 tick
    ) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IController.sol";
import "./interfaces/IStrategyInfo.sol";
import "./interfaces/IRescaleTickBoundaryCalculator.sol";
import "./libraries/LiquidityNftHelper.sol";
// import "./libraries/constants/Constants.sol";
import "./interfaces/IConstants.sol";

/// @dev verified, public contract
contract RescaleTickBoundaryCalculator is IRescaleTickBoundaryCalculator {
    IConstants public Constants;

    constructor(address _constants) {
        require(_constants != address(0), "Constants address cannot be zero");
        Constants = IConstants(_constants);
    }

    function verifyAndGetNewRescaleTickBoundary(
        bool wasInRange,
        int24 lastRescaleTick,
        address strategyAddress,
        address controllerAddress
    ) public view returns (bool allowRescale, int24 newTickUpper, int24 newTickLower) {
        // Get Tick Info
        (int24 tickSpacing, int24 currentTick, int24 currentTickLower, int24 currentTickUpper) =
            getTickInfo(strategyAddress);

        // Verify Not In Range (Exclude Exact Boundary)
        if (!(currentTick < currentTickLower || currentTick > currentTickUpper)) {
            return (false, 0, 0);
        }

        // Get Rescale Info and Verify
        if (tickSpacing == 1) {
            allowRescale = isRescaleAllowedWithOneTickSpacing(
                strategyAddress, controllerAddress, currentTick, currentTickLower, currentTickUpper
            );
        } else {
            allowRescale = isRescaleAllowedWithNonOneTickSpacing(
                wasInRange,
                lastRescaleTick,
                strategyAddress,
                controllerAddress,
                tickSpacing,
                currentTick,
                currentTickLower,
                currentTickUpper
            );
        }

        // Calculate newTickUpper & newTickLower
        if (!allowRescale) {
            return (false, 0, 0);
        } else {
            if (tickSpacing == 1) {
                (newTickLower, newTickUpper) = calculateOneTickSpacingRescaleTickBoundary(
                    strategyAddress, controllerAddress, currentTick, currentTickLower
                );
            } else {
                (newTickLower, newTickUpper) = calculateNonOneTickSpacingRescaleTickBoundary(
                    strategyAddress, controllerAddress, tickSpacing, currentTick, currentTickLower
                );
            }
        }

        // Verify Rescale Result
        if (currentTickUpper == newTickUpper && currentTickLower == newTickLower) {
            return (false, newTickUpper, newTickLower);
        } else {
            return (true, newTickUpper, newTickLower);
        }
    }

    function isRescaleAllowedWithOneTickSpacing(
        address strategyAddress,
        address controllerAddress,
        int24 currentTick,
        int24 currentTickLower,
        int24 currentTickUpper
    ) internal view returns (bool allowRescale) {
        // Get Rescale Info
        (int24 tickSpreadUpper, int24 tickSpreadLower,,,,, int24 tickGapUpper, int24 tickGapLower) =
            getRescaleInfo(strategyAddress, controllerAddress);

        // Verify Rescale Related Variables
        require(tickSpreadUpper > 1, "tickSpreadUpper <= 1");
        require(tickSpreadLower > 1, "tickSpreadLower <= 1");
        require(tickGapUpper > 1, "tickGapUpper <= 1");
        require(tickGapLower > 1, "tickGapLower <= 1");

        // Verify Rescale Condition
        if (currentTick < (currentTickLower - tickGapLower) || currentTick > (currentTickUpper + tickGapUpper)) {
            return true;
        }
    }

    function isRescaleAllowedWithNonOneTickSpacing(
        bool wasInRange,
        int24 lastRescaleTick,
        address strategyAddress,
        address controllerAddress,
        int24 tickSpacing,
        int24 currentTick,
        int24 currentTickLower,
        int24 currentTickUpper
    ) internal view returns (bool allowRescale) {
        // Get Rescale Info
        (
            int24 tickSpreadUpper,
            int24 tickSpreadLower,
            int24 tickUpperBoundaryOffset,
            int24 tickLowerBoundaryOffset,
            int24 rescaleTickUpperBoundaryOffset,
            int24 rescaleTickLowerBoundaryOffset,
            ,
        ) = getRescaleInfo(strategyAddress, controllerAddress);

        // Verify Rescale Related Variables
        require(tickSpreadUpper >= 0, "tickSpreadUpper < 0");
        require(tickSpreadLower >= 0, "tickSpreadLower < 0");
        require(tickUpperBoundaryOffset >= 0, "tickUpperBoundaryOffset < 0");
        require(tickLowerBoundaryOffset >= 0, "tickLowerBoundaryOffset < 0");
        require(rescaleTickUpperBoundaryOffset >= 0, "rescaleTickUpperBoundaryOffset < 0");
        require(rescaleTickLowerBoundaryOffset >= 0, "rescaleTickLowerBoundaryOffset < 0");

        // Verify Rescale Parameter
        //? verify wasInRange parameter
        if (
            (lastRescaleTick > currentTickUpper && currentTick < currentTickLower)
                || (lastRescaleTick < currentTickLower && currentTick > currentTickUpper)
        ) {
            require(wasInRange, "wasInRange parameter error");
        }

        // Verify Rescale Condition
        if (wasInRange) {
            //? it means the tick pass our range and keep far way from our range
            if (
                currentTick < currentTickLower - (tickLowerBoundaryOffset * tickSpacing)
                    || currentTick > currentTickUpper + (tickUpperBoundaryOffset * tickSpacing)
            ) {
                return true;
            }
        } else {
            //? it means the tick far away from our range since last time
            if (
                (currentTick < currentTickLower && currentTick < lastRescaleTick)
                    || (currentTick > currentTickUpper && currentTick > lastRescaleTick)
            ) {
                return true;
            }
        }
        //? not return false it will still return false ?
    }

    function calculateOneTickSpacingRescaleTickBoundary(
        address strategyAddress,
        address controllerAddress,
        int24 currentTick,
        int24 currentTickLower
    ) internal view returns (int24 newTickLower, int24 newTickUpper) {
        (int24 tickSpreadUpper, int24 tickSpreadLower,,,,,,) = getRescaleInfo(strategyAddress, controllerAddress);

        if (currentTick < currentTickLower) {
            newTickLower = currentTick + 1;
            newTickUpper = newTickLower + tickSpreadLower;
        } else {
            newTickUpper = currentTick - 1;
            newTickLower = newTickUpper - tickSpreadUpper;
        }
    }

    function calculateNonOneTickSpacingRescaleTickBoundary(
        address strategyAddress,
        address controllerAddress,
        int24 tickSpacing,
        int24 currentTick,
        int24 currentTickLower
    ) internal view returns (int24 newTickLower, int24 newTickUpper) {
        (
            int24 tickSpreadUpper,
            int24 tickSpreadLower,
            ,
            ,
            int24 rescaleTickUpperBoundaryOffset,
            int24 rescaleTickLowerBoundaryOffset,
            ,
        ) = getRescaleInfo(strategyAddress, controllerAddress);

        int24 tickSpread;
        if (currentTick < currentTickLower) {
            tickSpread = tickSpreadLower;
        } else {
            tickSpread = tickSpreadUpper;
        }
        int24 tickDistance = (tickSpread == 0) ? tickSpacing : (2 * tickSpread * tickSpacing);

        if (currentTick < currentTickLower) {
            newTickLower =
                LiquidityNftHelper.ceilingTick(currentTick, tickSpacing) + rescaleTickLowerBoundaryOffset * tickSpacing;
            newTickUpper = newTickLower + tickDistance;
        } else {
            newTickUpper =
                LiquidityNftHelper.floorTick(currentTick, tickSpacing) - rescaleTickUpperBoundaryOffset * tickSpacing;
            newTickLower = newTickUpper - tickDistance;
        }
    }

    /**
     * Add:
     * tickUpperBoundaryOffset
     * tickLowerBoundaryOffset
     * rescaleTickUpperBoundaryOffset
     * rescaleTickLowerBoundaryOffset
     *
     * Remove:
     * tickBoundaryOffset
     * rescaleTickBoundaryOffset
     */
    function getRescaleInfo(address strategyAddress, address controllerAddress)
        internal
        view
        returns (
            int24 tickSpreadUpper,
            int24 tickSpreadLower,
            int24 tickUpperBoundaryOffset,
            int24 tickLowerBoundaryOffset,
            int24 rescaleTickUpperBoundaryOffset,
            int24 rescaleTickLowerBoundaryOffset,
            int24 tickGapUpper,
            int24 tickGapLower
        )
    {
        tickSpreadUpper = IController(controllerAddress).tickSpreadUpper(strategyAddress);
        tickSpreadLower = IController(controllerAddress).tickSpreadLower(strategyAddress);
        tickUpperBoundaryOffset = IController(controllerAddress).tickUpperBoundaryOffset(strategyAddress);
        tickLowerBoundaryOffset = IController(controllerAddress).tickLowerBoundaryOffset(strategyAddress);
        rescaleTickUpperBoundaryOffset = IController(controllerAddress).rescaleTickUpperBoundaryOffset(strategyAddress);
        rescaleTickLowerBoundaryOffset = IController(controllerAddress).rescaleTickLowerBoundaryOffset(strategyAddress);
        tickGapUpper = IController(controllerAddress).tickGapUpper(strategyAddress);
        tickGapLower = IController(controllerAddress).tickGapLower(strategyAddress);
    }

    function getTickInfo(address strategyAddress)
        internal
        view
        returns (int24 tickSpacing, int24 currentTick, int24 currentTickLower, int24 currentTickUpper)
    {
        tickSpacing = IStrategyInfo(strategyAddress).tickSpacing();
        (currentTick, currentTickLower, currentTickUpper) = LiquidityNftHelper.getTickInfo(
            IStrategyInfo(strategyAddress).liquidityNftId(),
            Constants.UNISWAP_V3_FACTORY_ADDRESS(),
            Constants.NONFUNGIBLE_POSITION_MANAGER_ADDRESS()
        );
    }
}