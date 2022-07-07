// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { AggregatorV3Interface } from '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { UniswapV3PoolHelper } from '@ragetrade/core/contracts/libraries/UniswapV3PoolHelper.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { FixedPoint96 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint96.sol';
import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { SignedMath } from '@ragetrade/core/contracts/libraries/SignedMath.sol';
import { SignedFullMath } from '@ragetrade/core/contracts/libraries/SignedFullMath.sol';
import { ISwapRouter } from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import { TickMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/TickMath.sol';

import { IVPoolWrapper } from '@ragetrade/core/contracts/interfaces/IVPoolWrapper.sol';
import { IClearingHouse } from '@ragetrade/core/contracts/interfaces/IClearingHouse.sol';
import { ClearingHouseExtsload } from '@ragetrade/core/contracts/extsloads/ClearingHouseExtsload.sol';
import { IClearingHouseStructures } from '@ragetrade/core/contracts/interfaces/clearinghouse/IClearingHouseStructures.sol';

import { IBaseVault } from '../interfaces/IBaseVault.sol';
import { ISwapSimulator } from '../interfaces/ISwapSimulator.sol';
import { ICurveGauge } from '../interfaces/curve/ICurveGauge.sol';
import { ILPPriceGetter } from '../interfaces/curve/ILPPriceGetter.sol';
import { ICurveStableSwap } from '../interfaces/curve/ICurveStableSwap.sol';

import { SafeCast } from '../libraries/SafeCast.sol';
import { SwapManager } from '../libraries/SwapManager.sol';

interface IBaseVaultGetters {
    function minNotionalPositionToCloseThreshold() external view returns (uint64);

    function closePositionSlippageSqrtToleranceBps() external view returns (uint16);
}

library Logic {
    using SafeCast for uint256;
    using FullMath for uint256;
    using SignedMath for int256;
    using SignedFullMath for int256;

    using UniswapV3PoolHelper for IUniswapV3Pool;
    using ClearingHouseExtsload for IClearingHouse;

    event Harvested(uint256 crvAmount);
    event Staked(uint256 amount, address indexed depositor);

    event FeesUpdated(uint256 fee);
    event FeesWithdrawn(uint256 total);

    event CurveParamsUpdated(
        uint256 feeBps,
        uint256 stablecoinSlippage,
        uint256 crvHarvestThreshold,
        uint256 crvSlippageTolerance,
        address indexed crvOracle
    );

    event CrvSwapFailedDueToSlippage(uint256 crvSlippageTolerance);

    event EightyTwentyParamsUpdated(
        uint16 closePositionSlippageSqrtToleranceBps,
        uint16 resetPositionThresholdBps,
        uint64 minNotionalPositionToCloseThreshold
    );

    event BaseParamsUpdated(
        uint256 newDepositCap,
        address newKeeperAddress,
        uint32 rebalanceTimeThreshold,
        uint16 rebalancePriceThresholdBps
    );

    event Rebalance();
    event TokenPositionClosed();

    event StateInfo(uint256 lpPrice);

    // base vault

    function getTwapSqrtPriceX96(IUniswapV3Pool rageVPool, uint32 rageTwapDuration)
        external
        view
        returns (uint160 twapSqrtPriceX96)
    {
        twapSqrtPriceX96 = rageVPool.twapSqrtPrice(rageTwapDuration);
    }

    function _getTwapSqrtPriceX96(IUniswapV3Pool rageVPool, uint32 rageTwapDuration)
        internal
        view
        returns (uint160 twapSqrtPriceX96)
    {
        twapSqrtPriceX96 = rageVPool.twapSqrtPrice(rageTwapDuration);
    }

    // 80 20

    function _simulateClose(
        uint32 ethPoolId,
        int256 tokensToTrade,
        uint160 sqrtPriceX96,
        IClearingHouse clearingHouse,
        ISwapSimulator swapSimulator,
        uint16 slippageSqrtToleranceBps
    ) internal view returns (int256 vTokenAmountOut, int256 vQuoteAmountOut) {
        uint160 sqrtPriceLimitX96;

        if (tokensToTrade > 0) {
            sqrtPriceLimitX96 = uint256(sqrtPriceX96).mulDiv(1e4 + slippageSqrtToleranceBps, 1e4).toUint160();
        } else {
            sqrtPriceLimitX96 = uint256(sqrtPriceX96).mulDiv(1e4 - slippageSqrtToleranceBps, 1e4).toUint160();
        }

        IVPoolWrapper.SwapResult memory swapResult = swapSimulator.simulateSwapView(
            clearingHouse,
            ethPoolId,
            tokensToTrade,
            sqrtPriceLimitX96,
            false
        );

        return (-swapResult.vTokenIn, -swapResult.vQuoteIn);
    }

    function simulateBeforeWithdraw(
        address vault,
        uint256 amountBeforeWithdraw,
        uint256 amountWithdrawn
    ) external view returns (uint256 updatedAmountWithdrawn, int256 tokensToTrade) {
        uint32 ethPoolId = IBaseVault(vault).ethPoolId();
        IClearingHouse clearingHouse = IClearingHouse(IBaseVault(vault).rageClearingHouse());

        uint160 sqrtPriceX96 = _getTwapSqrtPriceX96(
            IBaseVault(vault).rageVPool(),
            clearingHouse.getTwapDuration(ethPoolId)
        );

        int256 netPosition = clearingHouse.getAccountNetTokenPosition(IBaseVault(vault).rageAccountNo(), ethPoolId);

        tokensToTrade = -netPosition.mulDiv(amountWithdrawn, amountBeforeWithdraw);

        uint256 tokensToTradeNotionalAbs = _getTokenNotionalAbs(netPosition, sqrtPriceX96);

        uint64 minNotionalPositionToCloseThreshold = IBaseVaultGetters(vault).minNotionalPositionToCloseThreshold();
        uint16 closePositionSlippageSqrtToleranceBps = IBaseVaultGetters(vault).closePositionSlippageSqrtToleranceBps();

        ISwapSimulator swapSimulatorCopied = IBaseVault(vault).swapSimulator();

        if (tokensToTradeNotionalAbs > minNotionalPositionToCloseThreshold) {
            (int256 vTokenAmountOut, ) = _simulateClose(
                ethPoolId,
                tokensToTrade,
                sqrtPriceX96,
                clearingHouse,
                swapSimulatorCopied,
                closePositionSlippageSqrtToleranceBps
            );

            if (vTokenAmountOut == tokensToTrade) updatedAmountWithdrawn = amountWithdrawn;
            else {
                int256 updatedAmountWithdrawnInt = -vTokenAmountOut.mulDiv(
                    amountBeforeWithdraw.toInt256(),
                    netPosition
                );
                updatedAmountWithdrawn = uint256(updatedAmountWithdrawnInt);
                tokensToTrade = vTokenAmountOut;
            }
        } else {
            updatedAmountWithdrawn = amountWithdrawn;
            tokensToTrade = 0;
        }
    }

    /// @notice Get token notional absolute
    /// @param tokenAmount Token amount
    /// @param sqrtPriceX96 Sqrt of price in X96
    function _getTokenNotionalAbs(int256 tokenAmount, uint160 sqrtPriceX96)
        internal
        pure
        returns (uint256 tokenNotionalAbs)
    {
        tokenNotionalAbs = tokenAmount
            .mulDiv(sqrtPriceX96, FixedPoint96.Q96)
            .mulDiv(sqrtPriceX96, FixedPoint96.Q96)
            .absUint();
    }

    /// @notice checks if upper and lower ticks are valid for rebalacing between current twap price and rebalance threshold
    function isValidRebalanceRangeWithoutCheckReset(
        IUniswapV3Pool rageVPool,
        uint32 rageTwapDuration,
        uint16 rebalancePriceThresholdBps,
        int24 baseTickLower,
        int24 baseTickUpper
    ) external view returns (bool isValid) {
        uint256 twapSqrtPriceX96 = uint256(_getTwapSqrtPriceX96(rageVPool, rageTwapDuration));
        uint256 twapSqrtPriceX96Delta = twapSqrtPriceX96.mulDiv(rebalancePriceThresholdBps, 1e4);
        if (
            TickMath.getTickAtSqrtRatio((twapSqrtPriceX96 + twapSqrtPriceX96Delta).toUint160()) > baseTickUpper ||
            TickMath.getTickAtSqrtRatio((twapSqrtPriceX96 - twapSqrtPriceX96Delta).toUint160()) < baseTickLower
        ) isValid = true;
    }

    /// @notice convert sqrt price in X96 to initializable tick
    /// @param sqrtPriceX96 Sqrt of price in X96
    /// @param isTickUpper true if price represents upper tick and false if price represents lower tick
    function sqrtPriceX96ToValidTick(uint160 sqrtPriceX96, bool isTickUpper) external pure returns (int24 roundedTick) {
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        if (isTickUpper) {
            roundedTick = tick + 10 - (tick % 10);
        } else {
            roundedTick = tick - (tick % 10);
        }

        if (tick < 0) roundedTick -= 10;
    }

    /// @notice helper to get nearest tick for sqrtPriceX96 (tickSpacing = 10)
    function _sqrtPriceX96ToValidTick(uint160 sqrtPriceX96, bool isTickUpper)
        internal
        pure
        returns (int24 roundedTick)
    {
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        if (isTickUpper) {
            roundedTick = tick + 10 - (tick % 10);
        } else {
            roundedTick = tick - (tick % 10);
        }

        if (tick < 0) roundedTick -= 10;
    }

    /// @notice Get updated base range params
    /// @param sqrtPriceX96 Sqrt of price in X96
    /// @param vaultMarketValue Market value of vault in USDC
    function getUpdatedBaseRangeParams(
        uint160 sqrtPriceX96,
        int256 vaultMarketValue,
        /* solhint-disable var-name-mixedcase */
        uint64 SQRT_PRICE_FACTOR_PIPS
    )
        external
        pure
        returns (
            int24 baseTickLowerUpdate,
            int24 baseTickUpperUpdate,
            uint128 baseLiquidityUpdate
        )
    {
        {
            uint160 sqrtPriceLowerX96 = uint256(sqrtPriceX96).mulDiv(SQRT_PRICE_FACTOR_PIPS, 1e6).toUint160();
            uint160 sqrtPriceUpperX96 = uint256(sqrtPriceX96).mulDiv(1e6, SQRT_PRICE_FACTOR_PIPS).toUint160();

            baseTickLowerUpdate = _sqrtPriceX96ToValidTick(sqrtPriceLowerX96, false);
            baseTickUpperUpdate = _sqrtPriceX96ToValidTick(sqrtPriceUpperX96, true);
        }

        uint160 updatedSqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(baseTickLowerUpdate);

        // assert(vaultMarketValue > 0);
        baseLiquidityUpdate = (
            uint256(vaultMarketValue).mulDiv(FixedPoint96.Q96 / 10, (sqrtPriceX96 - updatedSqrtPriceLowerX96))
        ).toUint128();
    }

    // curve yield strategy
    function convertAssetToSettlementToken(
        uint256 amount,
        uint256 slippage,
        ILPPriceGetter lpPriceHolder,
        ICurveGauge gauge,
        ICurveStableSwap triCryptoPool,
        IERC20 usdt,
        ISwapRouter uniV3Router,
        IERC20 usdc
    ) external returns (uint256 usdcAmount) {
        uint256 pricePerLP = lpPriceHolder.lp_price();
        uint256 lpToWithdraw = ((amount * (10**12)) * (10**18)) / pricePerLP;

        gauge.withdraw(lpToWithdraw);
        triCryptoPool.remove_liquidity_one_coin(lpToWithdraw, 0, 0);

        uint256 balance = usdt.balanceOf(address(this));

        bytes memory path = abi.encodePacked(usdt, uint24(500), usdc);

        usdcAmount = SwapManager.swapUsdtToUsdc(balance, slippage, path, uniV3Router);
    }

    function getMarketValue(uint256 amount, ILPPriceGetter lpPriceHolder) external view returns (uint256 marketValue) {
        marketValue = amount.mulDiv(_getPriceX128(lpPriceHolder), FixedPoint128.Q128);
    }

    function getPriceX128(ILPPriceGetter lpPriceHolder) external view returns (uint256 priceX128) {
        return _getPriceX128(lpPriceHolder);
    }

    function _getPriceX128(ILPPriceGetter lpPriceHolder) internal view returns (uint256 priceX128) {
        uint256 pricePerLP = lpPriceHolder.lp_price();
        return pricePerLP.mulDiv(FixedPoint128.Q128, 10**30); // 10**6 / (10**18*10**18)
    }
}

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { TickMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/TickMath.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

/// @title UniswapV3Pool helper functions
library UniswapV3PoolHelper {
    using UniswapV3PoolHelper for IUniswapV3Pool;

    error UV3PH_OracleConsultFailed();

    /// @notice Get the pool's current tick
    /// @param v3Pool The uniswap v3 pool contract
    /// @return tick the current tick
    function tickCurrent(IUniswapV3Pool v3Pool) internal view returns (int24 tick) {
        (, tick, , , , , ) = v3Pool.slot0();
    }

    /// @notice Get the pool's current sqrt price
    /// @param v3Pool The uniswap v3 pool contract
    /// @return sqrtPriceX96 the current sqrt price
    function sqrtPriceCurrent(IUniswapV3Pool v3Pool) internal view returns (uint160 sqrtPriceX96) {
        (sqrtPriceX96, , , , , , ) = v3Pool.slot0();
    }

    /// @notice Get twap price for uniswap v3 pool
    /// @param v3Pool The uniswap v3 pool contract
    /// @param twapDuration The twap period
    /// @return sqrtPriceX96 the twap price
    function twapSqrtPrice(IUniswapV3Pool v3Pool, uint32 twapDuration) internal view returns (uint160 sqrtPriceX96) {
        int24 _twapTick = v3Pool.twapTick(twapDuration);
        sqrtPriceX96 = TickMath.getSqrtRatioAtTick(_twapTick);
    }

    /// @notice Get twap tick for uniswap v3 pool
    /// @param v3Pool The uniswap v3 pool contract
    /// @param twapDuration The twap period
    /// @return _twapTick the twap tick
    function twapTick(IUniswapV3Pool v3Pool, uint32 twapDuration) internal view returns (int24 _twapTick) {
        if (twapDuration == 0) {
            return v3Pool.tickCurrent();
        }

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = twapDuration;
        secondAgos[1] = 0;

        // this call will fail if period is bigger than MaxObservationPeriod
        try v3Pool.observe(secondAgos) returns (int56[] memory tickCumulatives, uint160[] memory) {
            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            int24 timeWeightedAverageTick = int24(tickCumulativesDelta / int56(uint56(twapDuration)));

            // Always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(twapDuration)) != 0)) {
                timeWeightedAverageTick--;
            }
            return timeWeightedAverageTick;
        } catch {
            // if for some reason v3Pool.observe fails, fallback to the current tick
            (, _twapTick, , , , , ) = v3Pool.slot0();
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

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
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

int256 constant ONE = 1;

/// @title Signed math functions
library SignedMath {
    /// @notice gives the absolute value of a signed int
    /// @param value signed int
    /// @return absolute value of signed int
    function abs(int256 value) internal pure returns (int256) {
        return value > 0 ? value : -value;
    }

    /// @notice gives the absolute value of a signed int
    /// @param value signed int
    /// @return absolute value of signed int as unsigned int
    function absUint(int256 value) internal pure returns (uint256) {
        return uint256(abs(value));
    }

    /// @notice gives the sign of a signed int
    /// @param value signed int
    /// @return -1 if negative, 1 if non-negative
    function sign(int256 value) internal pure returns (int256) {
        return value >= 0 ? ONE : -ONE;
    }

    /// @notice converts a signed integer into an unsigned integer and inverts positive bool if negative
    /// @param a signed int
    /// @param positive initial value of positive bool
    /// @return _a absolute value of int provided
    /// @return bool xor of the positive boolean and sign of the provided int
    function extractSign(int256 a, bool positive) internal pure returns (uint256 _a, bool) {
        if (a < 0) {
            positive = !positive;
            _a = uint256(-a);
        } else {
            _a = uint256(a);
        }
        return (_a, positive);
    }

    /// @notice extracts the sign of a signed int
    /// @param a signed int
    /// @return _a unsigned int
    /// @return bool sign of the provided int
    function extractSign(int256 a) internal pure returns (uint256 _a, bool) {
        return extractSign(a, true);
    }

    /// @notice returns the max of two int256 numbers
    /// @param a first number
    /// @param b second number
    /// @return c = max of a and b
    function max(int256 a, int256 b) internal pure returns (int256 c) {
        if (a > b) c = a;
        else c = b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { SafeCast } from '@uniswap/v3-core-0.8-support/contracts/libraries/SafeCast.sol';

import { SignedMath } from './SignedMath.sol';

/// @title Signed full math functions
library SignedFullMath {
    using SafeCast for uint256;
    using SignedMath for int256;

    /// @notice uses full math on signed int and two unsigned ints
    /// @param a: signed int
    /// @param b: unsigned int to be multiplied by
    /// @param denominator: unsigned int to be divided by
    /// @return result of a * b / denominator
    function mulDiv(
        int256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        result = FullMath.mulDiv(a < 0 ? uint256(-1 * a) : uint256(a), b, denominator).toInt256();
        if (a < 0) {
            result = -result;
        }
    }

    /// @notice uses full math on three signed ints
    /// @param a: signed int
    /// @param b: signed int to be multiplied by
    /// @param denominator: signed int to be divided by
    /// @return result of a * b / denominator
    function mulDiv(
        int256 a,
        int256 b,
        int256 denominator
    ) internal pure returns (int256 result) {
        bool resultPositive = true;
        uint256 _a;
        uint256 _b;
        uint256 _denominator;

        (_a, resultPositive) = a.extractSign(resultPositive);
        (_b, resultPositive) = b.extractSign(resultPositive);
        (_denominator, resultPositive) = denominator.extractSign(resultPositive);

        result = FullMath.mulDiv(_a, _b, _denominator).toInt256();
        if (!resultPositive) {
            result = -result;
        }
    }

    /// @notice rounds down towards negative infinity
    /// @dev in Solidity -3/2 is -1. But this method result is -2
    /// @param a: signed int
    /// @param b: unsigned int to be multiplied by
    /// @param denominator: unsigned int to be divided by
    /// @return result of a * b / denominator rounded towards negative infinity
    function mulDivRoundingDown(
        int256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        result = mulDiv(a, b, denominator);
        if (result < 0 && _hasRemainder(a.absUint(), b, denominator)) {
            result += -1;
        }
    }

    /// @notice rounds down towards negative infinity
    /// @dev in Solidity -3/2 is -1. But this method result is -2
    /// @param a: signed int
    /// @param b: signed int to be multiplied by
    /// @param denominator: signed int to be divided by
    /// @return result of a * b / denominator rounded towards negative infinity
    function mulDivRoundingDown(
        int256 a,
        int256 b,
        int256 denominator
    ) internal pure returns (int256 result) {
        result = mulDiv(a, b, denominator);
        if (result < 0 && _hasRemainder(a.absUint(), b.absUint(), denominator.absUint())) {
            result += -1;
        }
    }

    /// @notice checks if full multiplication of a & b would have a remainder if divided by denominator
    /// @param a: multiplicand
    /// @param b: multiplier
    /// @param denominator: divisor
    /// @return hasRemainder true if there is a remainder, false otherwise
    function _hasRemainder(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) private pure returns (bool hasRemainder) {
        assembly {
            let remainder := mulmod(a, b, denominator)
            if gt(remainder, 0) {
                hasRemainder := 1
            }
        }
    }
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
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IVQuote } from './IVQuote.sol';
import { IVToken } from './IVToken.sol';

interface IVPoolWrapper {
    struct InitializeVPoolWrapperParams {
        address clearingHouse; // address of clearing house contract (proxy)
        IVToken vToken; // address of vToken contract
        IVQuote vQuote; // address of vQuote contract
        IUniswapV3Pool vPool; // address of Uniswap V3 Pool contract, created using vToken and vQuote
        uint24 liquidityFeePips; // liquidity fee fraction (in 1e6)
        uint24 protocolFeePips; // protocol fee fraction (in 1e6)
    }

    struct SwapResult {
        int256 amountSpecified; // amount of tokens/vQuote which were specified in the swap request
        int256 vTokenIn; // actual amount of vTokens paid by account to the Pool
        int256 vQuoteIn; // actual amount of vQuotes paid by account to the Pool
        uint256 liquidityFees; // actual amount of fees paid by account to the Pool
        uint256 protocolFees; // actual amount of fees paid by account to the Protocol
        uint160 sqrtPriceX96Start; // sqrt price at the beginning of the swap
        uint160 sqrtPriceX96End; // sqrt price at the end of the swap
    }

    struct WrapperValuesInside {
        int256 sumAX128; // sum of all the A terms in the pool
        int256 sumBInsideX128; // sum of all the B terms in side the tick range in the pool
        int256 sumFpInsideX128; // sum of all the Fp terms in side the tick range in the pool
        uint256 sumFeeInsideX128; // sum of all the fee terms in side the tick range in the pool
    }

    /// @notice Emitted whenever a swap takes place
    /// @param swapResult the swap result values
    event Swap(SwapResult swapResult);

    /// @notice Emitted whenever liquidity is added
    /// @param tickLower the lower tick of the range
    /// @param tickUpper the upper tick of the range
    /// @param liquidity the amount of liquidity that was added
    /// @param vTokenPrincipal the amount of vToken that was sent to UniswapV3Pool
    /// @param vQuotePrincipal the mount of vQuote charged was sent to UniswapV3Pool
    event Mint(int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 vTokenPrincipal, uint256 vQuotePrincipal);

    /// @notice Emitted whenever liquidity is removed
    /// @param tickLower the lower tick of the range
    /// @param tickUpper the upper tick of the range
    /// @param liquidity the amount of liquidity that was removed
    /// @param vTokenPrincipal the amount of vToken that was received from UniswapV3Pool
    /// @param vQuotePrincipal the mount of vQuote charged was received from UniswapV3Pool
    event Burn(int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 vTokenPrincipal, uint256 vQuotePrincipal);

    /// @notice Emitted whenever clearing house enquired about the accrued protocol fees
    /// @param amount the amount of accrued protocol fees
    event AccruedProtocolFeeCollected(uint256 amount);

    /// @notice Emitted when governance updates the liquidity fees
    /// @param liquidityFeePips the new liquidity fee ratio
    event LiquidityFeeUpdated(uint24 liquidityFeePips);

    /// @notice Emitted when governance updates the protocol fees
    /// @param protocolFeePips the new protocol fee ratio
    event ProtocolFeeUpdated(uint24 protocolFeePips);

    /// @notice Emitted when funding rate override is updated
    /// @param fundingRateOverrideX128 the new funding rate override value
    event FundingRateOverrideUpdated(int256 fundingRateOverrideX128);

    function initialize(InitializeVPoolWrapperParams memory params) external;

    function vPool() external view returns (IUniswapV3Pool);

    function getValuesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (WrapperValuesInside memory wrapperValuesInside);

    function getExtrapolatedValuesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (WrapperValuesInside memory wrapperValuesInside);

    function swap(
        bool swapVTokenForVQuote, // zeroForOne
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external returns (SwapResult memory swapResult);

    function mint(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        );

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        );

    function getSumAX128() external view returns (int256);

    function getExtrapolatedSumAX128() external view returns (int256);

    function liquidityFeePips() external view returns (uint24);

    function protocolFeePips() external view returns (uint24);

    /// @notice Used by clearing house to update funding rate when clearing house is paused or unpaused.
    /// @param useZeroFundingRate: used to discount funding payment during the duration ch was paused.
    function updateGlobalFundingState(bool useZeroFundingRate) external;

    /// @notice Used by clearing house to know how much protocol fee was collected.
    /// @return accruedProtocolFeeLast amount of protocol fees accrued since last collection.
    /// @dev Does not do any token transfer, just reduces the state in wrapper by accruedProtocolFeeLast.
    ///     Clearing house already has the amount of settlement tokens to send to treasury.
    function collectAccruedProtocolFee() external returns (uint256 accruedProtocolFeeLast);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IGovernable } from './IGovernable.sol';

import { IClearingHouseActions } from './clearinghouse/IClearingHouseActions.sol';
import { IClearingHouseCustomErrors } from './clearinghouse/IClearingHouseCustomErrors.sol';
import { IClearingHouseEnums } from './clearinghouse/IClearingHouseEnums.sol';
import { IClearingHouseEvents } from './clearinghouse/IClearingHouseEvents.sol';
import { IClearingHouseOwnerActions } from './clearinghouse/IClearingHouseOwnerActions.sol';
import { IClearingHouseStructures } from './clearinghouse/IClearingHouseStructures.sol';
import { IClearingHouseSystemActions } from './clearinghouse/IClearingHouseSystemActions.sol';
import { IClearingHouseView } from './clearinghouse/IClearingHouseView.sol';

interface IClearingHouse is
    IGovernable,
    IClearingHouseEnums,
    IClearingHouseStructures,
    IClearingHouseActions,
    IClearingHouseCustomErrors,
    IClearingHouseEvents,
    IClearingHouseOwnerActions,
    IClearingHouseSystemActions,
    IClearingHouseView
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IClearingHouse } from '../interfaces/IClearingHouse.sol';
import { IExtsload } from '../interfaces/IExtsload.sol';
import { IOracle } from '../interfaces/IOracle.sol';
import { IVQuote } from '../interfaces/IVQuote.sol';
import { IVPoolWrapper } from '../interfaces/IVPoolWrapper.sol';
import { IVToken } from '../interfaces/IVToken.sol';

import { Uint48Lib } from '../libraries/Uint48.sol';
import { WordHelper } from '../libraries/WordHelper.sol';

library ClearingHouseExtsload {
    // Terminology:
    // SLOT is a storage location value which can be sloaded, typed in bytes32.
    // OFFSET is an slot offset value which should not be sloaded, henced typed in uint256.

    using WordHelper for bytes32;
    using WordHelper for WordHelper.Word;

    /**
     * PROTOCOL
     */

    bytes32 constant PROTOCOL_SLOT = bytes32(uint256(100));
    uint256 constant PROTOCOL_POOLS_MAPPING_OFFSET = 0;
    uint256 constant PROTOCOL_COLLATERALS_MAPPING_OFFSET = 1;
    uint256 constant PROTOCOL_SETTLEMENT_TOKEN_OFFSET = 3;
    uint256 constant PROTOCOL_VQUOTE_OFFSET = 4;
    uint256 constant PROTOCOL_LIQUIDATION_PARAMS_STRUCT_OFFSET = 5;
    uint256 constant PROTOCOL_MINIMUM_REQUIRED_MARGIN_OFFSET = 6;
    uint256 constant PROTOCOL_REMOVE_LIMIT_ORDER_FEE_OFFSET = 7;
    uint256 constant PROTOCOL_MINIMUM_ORDER_NOTIONAL_OFFSET = 8;

    function _decodeLiquidationParamsSlot(bytes32 data)
        internal
        pure
        returns (IClearingHouse.LiquidationParams memory liquidationParams)
    {
        WordHelper.Word memory result = data.copyToMemory();
        liquidationParams.rangeLiquidationFeeFraction = result.popUint16();
        liquidationParams.tokenLiquidationFeeFraction = result.popUint16();
        liquidationParams.closeFactorMMThresholdBps = result.popUint16();
        liquidationParams.partialLiquidationCloseFactorBps = result.popUint16();
        liquidationParams.insuranceFundFeeShareBps = result.popUint16();
        liquidationParams.liquidationSlippageSqrtToleranceBps = result.popUint16();
        liquidationParams.maxRangeLiquidationFees = result.popUint64();
        liquidationParams.minNotionalLiquidatable = result.popUint64();
    }

    /// @notice Gets the protocol info, global protocol settings
    /// @return settlementToken the token in which profit is settled
    /// @return vQuote the vQuote token contract
    /// @return liquidationParams the liquidation parameters
    /// @return minRequiredMargin minimum required margin an account has to keep with non-zero netPosition
    /// @return removeLimitOrderFee the fee charged for using removeLimitOrder service
    /// @return minimumOrderNotional the minimum order notional
    function getProtocolInfo(IClearingHouse clearingHouse)
        internal
        view
        returns (
            IERC20 settlementToken,
            IVQuote vQuote,
            IClearingHouse.LiquidationParams memory liquidationParams,
            uint256 minRequiredMargin,
            uint256 removeLimitOrderFee,
            uint256 minimumOrderNotional
        )
    {
        bytes32[] memory arr = new bytes32[](6);
        arr[0] = PROTOCOL_SLOT.offset(PROTOCOL_SETTLEMENT_TOKEN_OFFSET);
        arr[1] = PROTOCOL_SLOT.offset(PROTOCOL_VQUOTE_OFFSET);
        arr[2] = PROTOCOL_SLOT.offset(PROTOCOL_LIQUIDATION_PARAMS_STRUCT_OFFSET);
        arr[3] = PROTOCOL_SLOT.offset(PROTOCOL_MINIMUM_REQUIRED_MARGIN_OFFSET);
        arr[4] = PROTOCOL_SLOT.offset(PROTOCOL_REMOVE_LIMIT_ORDER_FEE_OFFSET);
        arr[5] = PROTOCOL_SLOT.offset(PROTOCOL_MINIMUM_ORDER_NOTIONAL_OFFSET);
        arr = clearingHouse.extsload(arr);
        settlementToken = IERC20(arr[0].toAddress());
        vQuote = IVQuote(arr[1].toAddress());
        liquidationParams = _decodeLiquidationParamsSlot(arr[2]);
        minRequiredMargin = arr[3].toUint256();
        removeLimitOrderFee = arr[4].toUint256();
        minimumOrderNotional = arr[5].toUint256();
    }

    /**
     * PROTOCOL POOLS MAPPING
     */

    uint256 constant POOL_VTOKEN_OFFSET = 0;
    uint256 constant POOL_VPOOL_OFFSET = 1;
    uint256 constant POOL_VPOOLWRAPPER_OFFSET = 2;
    uint256 constant POOL_SETTINGS_STRUCT_OFFSET = 3;

    function poolStructSlot(uint32 poolId) internal pure returns (bytes32) {
        return
            WordHelper.keccak256Two({
                mappingSlot: PROTOCOL_SLOT.offset(PROTOCOL_POOLS_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(poolId)
            });
    }

    function _decodePoolSettingsSlot(bytes32 data) internal pure returns (IClearingHouse.PoolSettings memory settings) {
        WordHelper.Word memory result = data.copyToMemory();
        settings.initialMarginRatioBps = result.popUint16();
        settings.maintainanceMarginRatioBps = result.popUint16();
        settings.maxVirtualPriceDeviationRatioBps = result.popUint16();
        settings.twapDuration = result.popUint32();
        settings.isAllowedForTrade = result.popBool();
        settings.isCrossMargined = result.popBool();
        settings.oracle = IOracle(result.popAddress());
    }

    /// @notice Gets the info about a supported pool in the protocol
    /// @param poolId the id of the pool
    /// @return pool the Pool struct
    function getPoolInfo(IClearingHouse clearingHouse, uint32 poolId)
        internal
        view
        returns (IClearingHouse.Pool memory pool)
    {
        bytes32 POOL_SLOT = poolStructSlot(poolId);
        bytes32[] memory arr = new bytes32[](4);
        arr[0] = POOL_SLOT; // POOL_VTOKEN_OFFSET
        arr[1] = POOL_SLOT.offset(POOL_VPOOL_OFFSET);
        arr[2] = POOL_SLOT.offset(POOL_VPOOLWRAPPER_OFFSET);
        arr[3] = POOL_SLOT.offset(POOL_SETTINGS_STRUCT_OFFSET);
        arr = clearingHouse.extsload(arr);
        pool.vToken = IVToken(arr[0].toAddress());
        pool.vPool = IUniswapV3Pool(arr[1].toAddress());
        pool.vPoolWrapper = IVPoolWrapper(arr[2].toAddress());
        pool.settings = _decodePoolSettingsSlot(arr[3]);
    }

    function getVPool(IClearingHouse clearingHouse, uint32 poolId) internal view returns (IUniswapV3Pool vPool) {
        bytes32 result = clearingHouse.extsload(poolStructSlot(poolId).offset(POOL_VPOOL_OFFSET));
        assembly {
            vPool := result
        }
    }

    function getPoolSettings(IClearingHouse clearingHouse, uint32 poolId)
        internal
        view
        returns (IClearingHouse.PoolSettings memory)
    {
        bytes32 SETTINGS_SLOT = poolStructSlot(poolId).offset(POOL_SETTINGS_STRUCT_OFFSET);
        return _decodePoolSettingsSlot(clearingHouse.extsload(SETTINGS_SLOT));
    }

    function getTwapDuration(IClearingHouse clearingHouse, uint32 poolId) internal view returns (uint32 twapDuration) {
        bytes32 result = clearingHouse.extsload(poolStructSlot(poolId).offset(POOL_SETTINGS_STRUCT_OFFSET));
        twapDuration = result.slice(0x30, 0x50).toUint32();
    }

    function getVPoolAndTwapDuration(IClearingHouse clearingHouse, uint32 poolId)
        internal
        view
        returns (IUniswapV3Pool vPool, uint32 twapDuration)
    {
        bytes32[] memory arr = new bytes32[](2);

        bytes32 POOL_SLOT = poolStructSlot(poolId);
        arr[0] = POOL_SLOT.offset(POOL_VPOOL_OFFSET); // vPool
        arr[1] = POOL_SLOT.offset(POOL_SETTINGS_STRUCT_OFFSET); // settings
        arr = clearingHouse.extsload(arr);

        vPool = IUniswapV3Pool(arr[0].toAddress());
        twapDuration = arr[1].slice(0xB0, 0xD0).toUint32();
    }

    /// @notice Checks if a poolId is unused
    /// @param poolId the id of the pool
    /// @return true if the poolId is unused, false otherwise
    function isPoolIdAvailable(IClearingHouse clearingHouse, uint32 poolId) internal view returns (bool) {
        bytes32 VTOKEN_SLOT = poolStructSlot(poolId).offset(POOL_VTOKEN_OFFSET);
        bytes32 result = clearingHouse.extsload(VTOKEN_SLOT);
        return result == WordHelper.fromUint(0);
    }

    /**
     * PROTOCOL COLLATERALS MAPPING
     */

    uint256 constant COLLATERAL_TOKEN_OFFSET = 0;
    uint256 constant COLLATERAL_SETTINGS_OFFSET = 1;

    function collateralStructSlot(uint32 collateralId) internal pure returns (bytes32) {
        return
            WordHelper.keccak256Two({
                mappingSlot: PROTOCOL_SLOT.offset(PROTOCOL_COLLATERALS_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(collateralId)
            });
    }

    function _decodeCollateralSettings(bytes32 data)
        internal
        pure
        returns (IClearingHouse.CollateralSettings memory settings)
    {
        WordHelper.Word memory result = data.copyToMemory();
        settings.oracle = IOracle(result.popAddress());
        settings.twapDuration = result.popUint32();
        settings.isAllowedForDeposit = result.popBool();
    }

    /// @notice Gets the info about a supported collateral in the protocol
    /// @param collateralId the id of the collateral
    /// @return collateral the Collateral struct
    function getCollateralInfo(IClearingHouse clearingHouse, uint32 collateralId)
        internal
        view
        returns (IClearingHouse.Collateral memory collateral)
    {
        bytes32[] memory arr = new bytes32[](2);
        bytes32 COLLATERAL_STRUCT_SLOT = collateralStructSlot(collateralId);
        arr[0] = COLLATERAL_STRUCT_SLOT; // COLLATERAL_TOKEN_OFFSET
        arr[1] = COLLATERAL_STRUCT_SLOT.offset(COLLATERAL_SETTINGS_OFFSET);
        arr = clearingHouse.extsload(arr);
        collateral.token = IVToken(arr[0].toAddress());
        collateral.settings = _decodeCollateralSettings(arr[1]);
    }

    /**
     * ACCOUNT MAPPING
     */
    bytes32 constant ACCOUNTS_MAPPING_SLOT = bytes32(uint256(211));
    uint256 constant ACCOUNT_ID_OWNER_OFFSET = 0;
    uint256 constant ACCOUNT_VTOKENPOSITIONS_ACTIVE_SET_OFFSET = 1;
    uint256 constant ACCOUNT_VTOKENPOSITIONS_MAPPING_OFFSET = 2;
    uint256 constant ACCOUNT_VQUOTE_BALANCE_OFFSET = 3;
    uint256 constant ACCOUNT_COLLATERAL_ACTIVE_SET_OFFSET = 104;
    uint256 constant ACCOUNT_COLLATERAL_MAPPING_OFFSET = 105;

    // VTOKEN POSITION STRUCT
    uint256 constant ACCOUNT_VTOKENPOSITION_BALANCE_OFFSET = 0;
    uint256 constant ACCOUNT_VTOKENPOSITION_NET_TRADER_POSITION_OFFSET = 1;
    uint256 constant ACCOUNT_VTOKENPOSITION_SUM_A_LAST_OFFSET = 2;
    uint256 constant ACCOUNT_VTOKENPOSITION_LIQUIDITY_ACTIVE_OFFSET = 3;
    uint256 constant ACCOUNT_VTOKENPOSITION_LIQUIDITY_MAPPING_OFFSET = 4;

    // LIQUIDITY POSITION STRUCT
    uint256 constant ACCOUNT_TP_LP_SLOT0_OFFSET = 0; // limit order type, tl, tu, liquidity
    uint256 constant ACCOUNT_TP_LP_VTOKEN_AMOUNTIN_OFFSET = 1;
    uint256 constant ACCOUNT_TP_LP_SUM_A_LAST_OFFSET = 2;
    uint256 constant ACCOUNT_TP_LP_SUM_B_LAST_OFFSET = 3;
    uint256 constant ACCOUNT_TP_LP_SUM_FP_LAST_OFFSET = 4;
    uint256 constant ACCOUNT_TP_LP_SUM_FEE_LAST_OFFSET = 5;

    function accountStructSlot(uint256 accountId) internal pure returns (bytes32) {
        return
            WordHelper.keccak256Two({ mappingSlot: ACCOUNTS_MAPPING_SLOT, paddedKey: WordHelper.fromUint(accountId) });
    }

    function accountCollateralStructSlot(bytes32 ACCOUNT_STRUCT_SLOT, uint32 collateralId)
        internal
        pure
        returns (bytes32)
    {
        return
            WordHelper.keccak256Two({
                mappingSlot: ACCOUNT_STRUCT_SLOT.offset(ACCOUNT_COLLATERAL_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(collateralId)
            });
    }

    function accountVTokenPositionStructSlot(bytes32 ACCOUNT_STRUCT_SLOT, uint32 poolId)
        internal
        pure
        returns (bytes32)
    {
        return
            WordHelper.keccak256Two({
                mappingSlot: ACCOUNT_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITIONS_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(poolId)
            });
    }

    function accountLiquidityPositionStructSlot(
        bytes32 ACCOUNT_VTOKENPOSITION_STRUCT_SLOT,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return
            WordHelper.keccak256Two({
                mappingSlot: ACCOUNT_VTOKENPOSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_LIQUIDITY_MAPPING_OFFSET),
                paddedKey: WordHelper.fromUint(Uint48Lib.concat(tickLower, tickUpper))
            });
    }

    function getAccountInfo(IClearingHouse clearingHouse, uint256 accountId)
        internal
        view
        returns (
            address owner,
            int256 vQuoteBalance,
            uint32[] memory activeCollateralIds,
            uint32[] memory activePoolIds
        )
    {
        bytes32[] memory arr = new bytes32[](4);
        bytes32 ACCOUNT_SLOT = accountStructSlot(accountId);
        arr[0] = ACCOUNT_SLOT; // ACCOUNT_ID_OWNER_OFFSET
        arr[1] = ACCOUNT_SLOT.offset(ACCOUNT_VQUOTE_BALANCE_OFFSET);
        arr[2] = ACCOUNT_SLOT.offset(ACCOUNT_COLLATERAL_ACTIVE_SET_OFFSET);
        arr[3] = ACCOUNT_SLOT.offset(ACCOUNT_VTOKENPOSITIONS_ACTIVE_SET_OFFSET);

        arr = clearingHouse.extsload(arr);

        owner = arr[0].slice(0, 160).toAddress();
        vQuoteBalance = arr[1].toInt256();
        activeCollateralIds = arr[2].convertToUint32Array();
        activePoolIds = arr[3].convertToUint32Array();
    }

    function getAccountCollateralInfo(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 collateralId
    ) internal view returns (IERC20 collateral, uint256 balance) {
        bytes32[] memory arr = new bytes32[](2);
        arr[0] = accountCollateralStructSlot(accountStructSlot(accountId), collateralId); // ACCOUNT_COLLATERAL_BALANCE_SLOT
        arr[1] = collateralStructSlot(collateralId); // COLLATERAL_TOKEN_ADDRESS_SLOT

        arr = clearingHouse.extsload(arr);

        balance = arr[0].toUint256();
        collateral = IERC20(arr[1].toAddress());
    }

    function getAccountCollateralBalance(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 collateralId
    ) internal view returns (uint256 balance) {
        bytes32 COLLATERAL_BALANCE_SLOT = accountCollateralStructSlot(accountStructSlot(accountId), collateralId);

        balance = clearingHouse.extsload(COLLATERAL_BALANCE_SLOT).toUint256();
    }

    function getAccountTokenPositionInfo(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 poolId
    )
        internal
        view
        returns (
            int256 balance,
            int256 netTraderPosition,
            int256 sumALastX128
        )
    {
        bytes32 VTOKEN_POSITION_STRUCT_SLOT = accountVTokenPositionStructSlot(accountStructSlot(accountId), poolId);

        bytes32[] memory arr = new bytes32[](3);
        arr[0] = VTOKEN_POSITION_STRUCT_SLOT; // BALANCE
        arr[1] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_NET_TRADER_POSITION_OFFSET);
        arr[2] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_SUM_A_LAST_OFFSET);

        arr = clearingHouse.extsload(arr);

        balance = arr[0].toInt256();
        netTraderPosition = arr[1].toInt256();
        sumALastX128 = arr[2].toInt256();
    }

    function getAccountPositionInfo(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 poolId
    )
        internal
        view
        returns (
            int256 balance,
            int256 netTraderPosition,
            int256 sumALastX128,
            IClearingHouse.TickRange[] memory activeTickRanges
        )
    {
        bytes32 VTOKEN_POSITION_STRUCT_SLOT = accountVTokenPositionStructSlot(accountStructSlot(accountId), poolId);

        bytes32[] memory arr = new bytes32[](4);
        arr[0] = VTOKEN_POSITION_STRUCT_SLOT; // BALANCE
        arr[1] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_NET_TRADER_POSITION_OFFSET);
        arr[2] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_SUM_A_LAST_OFFSET);
        arr[3] = VTOKEN_POSITION_STRUCT_SLOT.offset(ACCOUNT_VTOKENPOSITION_LIQUIDITY_ACTIVE_OFFSET);

        arr = clearingHouse.extsload(arr);

        balance = arr[0].toInt256();
        netTraderPosition = arr[1].toInt256();
        sumALastX128 = arr[2].toInt256();
        activeTickRanges = arr[3].convertToTickRangeArray();
    }

    function getAccountLiquidityPositionList(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 poolId
    ) internal view returns (IClearingHouse.TickRange[] memory activeTickRanges) {
        return
            clearingHouse
                .extsload(
                    accountVTokenPositionStructSlot(accountStructSlot(accountId), poolId).offset(
                        ACCOUNT_VTOKENPOSITION_LIQUIDITY_ACTIVE_OFFSET
                    )
                )
                .convertToTickRangeArray();
    }

    function getAccountLiquidityPositionInfo(
        IClearingHouse clearingHouse,
        uint256 accountId,
        uint32 poolId,
        int24 tickLower,
        int24 tickUpper
    )
        internal
        view
        returns (
            uint8 limitOrderType,
            uint128 liquidity,
            int256 vTokenAmountIn,
            int256 sumALastX128,
            int256 sumBInsideLastX128,
            int256 sumFpInsideLastX128,
            uint256 sumFeeInsideLastX128
        )
    {
        bytes32 LIQUIDITY_POSITION_STRUCT_SLOT = accountLiquidityPositionStructSlot(
            accountVTokenPositionStructSlot(accountStructSlot(accountId), poolId),
            tickLower,
            tickUpper
        );

        bytes32[] memory arr = new bytes32[](6);
        arr[0] = LIQUIDITY_POSITION_STRUCT_SLOT; // BALANCE
        arr[1] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_VTOKEN_AMOUNTIN_OFFSET);
        arr[2] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_SUM_A_LAST_OFFSET);
        arr[3] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_SUM_B_LAST_OFFSET);
        arr[4] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_SUM_FP_LAST_OFFSET);
        arr[5] = LIQUIDITY_POSITION_STRUCT_SLOT.offset(ACCOUNT_TP_LP_SUM_FEE_LAST_OFFSET);

        arr = clearingHouse.extsload(arr);

        WordHelper.Word memory slot0 = arr[0].copyToMemory();
        limitOrderType = slot0.popUint8();
        slot0.pop(48); // discard 48 bits
        liquidity = slot0.popUint128();
        vTokenAmountIn = arr[1].toInt256();
        sumALastX128 = arr[2].toInt256();
        sumBInsideLastX128 = arr[3].toInt256();
        sumFpInsideLastX128 = arr[4].toInt256();
        sumFeeInsideLastX128 = arr[5].toUint256();
    }

    function _getProtocolSlot() internal pure returns (bytes32) {
        return PROTOCOL_SLOT;
    }

    function _getProtocolOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            PROTOCOL_POOLS_MAPPING_OFFSET,
            PROTOCOL_COLLATERALS_MAPPING_OFFSET,
            PROTOCOL_SETTLEMENT_TOKEN_OFFSET,
            PROTOCOL_VQUOTE_OFFSET,
            PROTOCOL_LIQUIDATION_PARAMS_STRUCT_OFFSET,
            PROTOCOL_MINIMUM_REQUIRED_MARGIN_OFFSET,
            PROTOCOL_REMOVE_LIMIT_ORDER_FEE_OFFSET,
            PROTOCOL_MINIMUM_ORDER_NOTIONAL_OFFSET
        );
    }

    function _getPoolOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (POOL_VTOKEN_OFFSET, POOL_VPOOL_OFFSET, POOL_VPOOLWRAPPER_OFFSET, POOL_SETTINGS_STRUCT_OFFSET);
    }

    function _getCollateralOffsets() internal pure returns (uint256, uint256) {
        return (COLLATERAL_TOKEN_OFFSET, COLLATERAL_SETTINGS_OFFSET);
    }

    function _getAccountsMappingSlot() internal pure returns (bytes32) {
        return ACCOUNTS_MAPPING_SLOT;
    }

    function _getAccountOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            ACCOUNT_ID_OWNER_OFFSET,
            ACCOUNT_VTOKENPOSITIONS_ACTIVE_SET_OFFSET,
            ACCOUNT_VTOKENPOSITIONS_MAPPING_OFFSET,
            ACCOUNT_VQUOTE_BALANCE_OFFSET,
            ACCOUNT_COLLATERAL_ACTIVE_SET_OFFSET,
            ACCOUNT_COLLATERAL_MAPPING_OFFSET
        );
    }

    function _getVTokenPositionOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            ACCOUNT_VTOKENPOSITION_BALANCE_OFFSET,
            ACCOUNT_VTOKENPOSITION_NET_TRADER_POSITION_OFFSET,
            ACCOUNT_VTOKENPOSITION_SUM_A_LAST_OFFSET,
            ACCOUNT_VTOKENPOSITION_LIQUIDITY_ACTIVE_OFFSET,
            ACCOUNT_VTOKENPOSITION_LIQUIDITY_MAPPING_OFFSET
        );
    }

    function _getLiquidityPositionOffsets()
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            ACCOUNT_TP_LP_SLOT0_OFFSET,
            ACCOUNT_TP_LP_VTOKEN_AMOUNTIN_OFFSET,
            ACCOUNT_TP_LP_SUM_A_LAST_OFFSET,
            ACCOUNT_TP_LP_SUM_B_LAST_OFFSET,
            ACCOUNT_TP_LP_SUM_FP_LAST_OFFSET,
            ACCOUNT_TP_LP_SUM_FEE_LAST_OFFSET
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IOracle } from '../IOracle.sol';
import { IVToken } from '../IVToken.sol';
import { IVPoolWrapper } from '../IVPoolWrapper.sol';

import { IClearingHouseEnums } from './IClearingHouseEnums.sol';

interface IClearingHouseStructures is IClearingHouseEnums {
    struct BalanceAdjustments {
        int256 vQuoteIncrease; // specifies the increase in vQuote balance
        int256 vTokenIncrease; // specifies the increase in token balance
        int256 traderPositionIncrease; // specifies the increase in trader position
    }

    struct Collateral {
        IERC20 token; // address of the collateral token
        CollateralSettings settings; // collateral settings, changable by governance later
    }

    struct CollateralSettings {
        IOracle oracle; // address of oracle which gives price to be used for collateral
        uint32 twapDuration; // duration of the twap in seconds
        bool isAllowedForDeposit; // whether the collateral is allowed to be deposited at the moment
    }

    struct CollateralDepositView {
        IERC20 collateral; // address of the collateral token
        uint256 balance; // balance of the collateral in the account
    }

    struct LiquidityChangeParams {
        int24 tickLower; // tick lower of the range
        int24 tickUpper; // tick upper of the range
        int128 liquidityDelta; // positive to add liquidity, negative to remove liquidity
        uint160 sqrtPriceCurrent; // hint for virtual price, to prevent sandwitch attack
        uint16 slippageToleranceBps; // slippage tolerance in bps, to prevent sandwitch attack
        bool closeTokenPosition; // whether to close the token position generated due to the liquidity change
        LimitOrderType limitOrderType; // limit order type
        bool settleProfit; // whether to settle profit against USDC margin
    }

    struct LiquidityPositionView {
        int24 tickLower; // tick lower of the range
        int24 tickUpper; // tick upper of the range
        uint128 liquidity; // liquidity in the range by the account
        int256 vTokenAmountIn; // amount of token supplied by the account, to calculate net position
        int256 sumALastX128; // checkpoint of the term A in funding payment math
        int256 sumBInsideLastX128; // checkpoint of the term B in funding payment math
        int256 sumFpInsideLastX128; // checkpoint of the term Fp in funding payment math
        uint256 sumFeeInsideLastX128; // checkpoint of the trading fees
        LimitOrderType limitOrderType; // limit order type
    }

    struct LiquidationParams {
        uint16 rangeLiquidationFeeFraction; // fraction of net token position rm from the range to be charged as liquidation fees (in 1e5)
        uint16 tokenLiquidationFeeFraction; // fraction of traded amount of vquote to be charged as liquidation fees (in 1e5)
        uint16 closeFactorMMThresholdBps; // fraction the MM threshold for partial liquidation (in 1e4)
        uint16 partialLiquidationCloseFactorBps; // fraction the % of position to be liquidated if partial liquidation should occur (in 1e4)
        uint16 insuranceFundFeeShareBps; // fraction of the fee share for insurance fund out of the total liquidation fee (in 1e4)
        uint16 liquidationSlippageSqrtToleranceBps; // fraction of the max sqrt price slippage threshold (in 1e4) (can be set to - actual price slippage tolerance / 2)
        uint64 maxRangeLiquidationFees; // maximum range liquidation fees (in settlement token amount decimals)
        uint64 minNotionalLiquidatable; // minimum notional value of position for it to be eligible for partial liquidation (in settlement token amount decimals)
    }

    struct MulticallOperation {
        MulticallOperationType operationType; // operation type
        bytes data; // abi encoded data for the operation
    }

    struct Pool {
        IVToken vToken; // address of the vToken, poolId = vToken.truncate()
        IUniswapV3Pool vPool; // address of the UniswapV3Pool(token0=vToken, token1=vQuote, fee=500)
        IVPoolWrapper vPoolWrapper; // wrapper address
        PoolSettings settings; // pool settings, which can be updated by governance later
    }

    struct PoolSettings {
        uint16 initialMarginRatioBps; // margin ratio (1e4) considered for create/update position, removing margin or profit
        uint16 maintainanceMarginRatioBps; // margin ratio (1e4) considered for liquidations by keeper
        uint16 maxVirtualPriceDeviationRatioBps; // maximum deviation (1e4) from the current virtual price
        uint32 twapDuration; // twap duration (seconds) for oracle
        bool isAllowedForTrade; // whether the pool is allowed to be traded at the moment
        bool isCrossMargined; // whether cross margined is done for positions of this pool
        IOracle oracle; // spot price feed twap oracle for this pool
    }

    struct SwapParams {
        int256 amount; // amount of tokens/vQuote to swap
        uint160 sqrtPriceLimit; // threshold sqrt price which should not be crossed
        bool isNotional; // whether the amount represents vQuote amount
        bool isPartialAllowed; // whether to end swap (partial) when sqrtPriceLimit is reached, instead of reverting
        bool settleProfit; // whether to settle profit against USDC margin
    }

    struct TickRange {
        int24 tickLower;
        int24 tickUpper;
    }

    struct VTokenPositionView {
        uint32 poolId; // id of the pool of which this token position is for
        int256 balance; // vTokenLong - vTokenShort
        int256 netTraderPosition; // net position due to trades and liquidity change carries
        int256 sumALastX128; // checkoint of the term A in funding payment math
        LiquidityPositionView[] liquidityPositions; // liquidity positions of the account in the pool
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import { ISwapSimulator } from './ISwapSimulator.sol';
import { IClearingHouse } from '@ragetrade/core/contracts/interfaces/IClearingHouse.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

interface IBaseVault {
    function rebalance() external;

    function closeTokenPosition() external;

    function ethPoolId() external view returns (uint32);

    function depositCap() external view returns (uint256);

    function rageAccountNo() external view returns (uint256);

    function rageVPool() external view returns (IUniswapV3Pool);

    function swapSimulator() external view returns (ISwapSimulator);

    function rageClearingHouse() external view returns (IClearingHouse);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import { IVPoolWrapper } from '@ragetrade/core/contracts/interfaces/IVPoolWrapper.sol';
import { IClearingHouse } from '@ragetrade/core/contracts/interfaces/IClearingHouse.sol';

interface ISwapSimulator {
    function simulateSwapView(
        IClearingHouse clearingHouse,
        uint32 poolId,
        int256 amount,
        uint160 sqrtPriceLimitX96,
        bool isNotional
    ) external view returns (IVPoolWrapper.SwapResult memory swapResult);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

/* solhint-disable func-name-mixedcase */
/* solhint-disable var-name-mixedcase */

interface ICurveGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function balanceOf(address arg0) external view returns (uint256);

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool claim_rewards) external;

    function claim_rewards() external;

    function claim_rewards(address addr) external;

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address user, address token) external view returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);

    function claimable_reward_write(address user, address token) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

/* solhint-disable func-name-mixedcase */

interface ILPPriceGetter {
    function lp_price() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

/* solhint-disable func-name-mixedcase */
/* solhint-disable var-name-mixedcase */

interface ICurveStableSwap {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 index,
        uint256 min_amount
    ) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function exchange(
        uint256,
        uint256,
        uint256,
        uint256,
        bool
    ) external;

    function get_dy(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function balances(uint256) external view returns (uint256);

    function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        unchecked {
            require((z = uint160(y)) == y, 'Overflow');
        }
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        unchecked {
            /* solhint-disable reason-string */
            require((z = uint128(y)) == y);
        }
    }

    /// @notice Cast a uint128 to a int128, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt128(uint128 y) internal pure returns (int128 z) {
        unchecked {
            require(y < 2**127, 'Overflow');
            z = int128(y);
        }
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        unchecked {
            require((z = int128(y)) == y, 'Overflow');
        }
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        unchecked {
            require(y < 2**255, 'Overflow');
            z = int256(y);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import { ISwapRouter } from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import { ICurveStableSwap } from '../interfaces/curve/ICurveStableSwap.sol';

import { AggregatorV3Interface } from '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

/* solhint-disable not-rely-on-time */

library SwapManager {
    error CYS_NEGATIVE_CRV_PRICE();

    uint256 internal constant MAX_BPS = 10_000;

    function _getCrvPrice(AggregatorV3Interface crvOracle) internal view returns (uint256) {
        (, int256 answer, , , ) = crvOracle.latestRoundData();
        if (answer < 0) revert CYS_NEGATIVE_CRV_PRICE();
        return (uint256(answer));
    }

    function swapUsdcToUsdtAndAddLiquidity(
        uint256 amount,
        uint256 slippage,
        bytes memory path,
        ISwapRouter uniV3Router,
        ICurveStableSwap triCrypto
    ) external {
        uint256 minOut = (amount * (MAX_BPS - slippage)) / MAX_BPS;

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            amountIn: amount,
            amountOutMinimum: minOut,
            recipient: address(this),
            deadline: block.timestamp
        });

        uint256 usdtOut = uniV3Router.exactInput(params);

        // USDT, WBTC, WETH
        uint256[3] memory amounts = [usdtOut, uint256(0), uint256(0)];
        triCrypto.add_liquidity(amounts, 0);
    }

    function swapUsdtToUsdc(
        uint256 amount,
        uint256 slippage,
        bytes memory path,
        ISwapRouter uniV3Router
    ) external returns (uint256 usdcOut) {
        uint256 minOut = (amount * (MAX_BPS - slippage)) / MAX_BPS;

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            amountIn: amount,
            amountOutMinimum: minOut,
            recipient: address(this),
            deadline: block.timestamp
        });

        usdcOut = uniV3Router.exactInput(params);
    }

    function swapCrvToUsdtAndAddLiquidity(
        uint256 crvAmount,
        uint256 crvSwapSlippageTolerance,
        AggregatorV3Interface crvOracle,
        bytes memory path,
        ISwapRouter uniV3Router,
        ICurveStableSwap triCrypto
    ) external returns (uint256 usdtOut) {
        uint256 minOut = (_getCrvPrice(crvOracle) * crvAmount * (MAX_BPS - crvSwapSlippageTolerance)) / MAX_BPS;
        // should not underflow because crvAmount > crv swap threshold
        minOut = ((minOut * (10**6)) / 10**18) / 10**8;

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            amountIn: crvAmount,
            amountOutMinimum: minOut,
            recipient: address(this),
            deadline: block.timestamp
        });

        usdtOut = uniV3Router.exactInput(params);

        uint256[3] memory amounts = [usdtOut, uint256(0), uint256(0)];
        triCrypto.add_liquidity(amounts, 0);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

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

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
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

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
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
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVQuote is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function authorize(address vPoolWrapper) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function setVPoolWrapper(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IGovernable {
    function governance() external view returns (address);

    function governancePending() external view returns (address);

    function teamMultisig() external view returns (address);

    function teamMultisigPending() external view returns (address);

    function initiateGovernanceTransfer(address newGovernancePending) external;

    function acceptGovernanceTransfer() external;

    function initiateTeamMultisigTransfer(address newTeamMultisigPending) external;

    function acceptTeamMultisigTransfer() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseActions is IClearingHouseStructures {
    /// @notice creates a new account and adds it to the accounts map
    /// @return newAccountId - serial number of the new account created
    function createAccount() external returns (uint256 newAccountId);

    /// @notice deposits 'amount' of token associated with 'poolId'
    /// @param accountId account id
    /// @param collateralId truncated address of token to deposit
    /// @param amount amount of token to deposit
    function updateMargin(
        uint256 accountId,
        uint32 collateralId,
        int256 amount
    ) external;

    /// @notice creates a new account and deposits 'amount' of token associated with 'poolId'
    /// @param collateralId truncated address of collateral token to deposit
    /// @param amount amount of token to deposit
    /// @return newAccountId - serial number of the new account created
    function createAccountAndAddMargin(uint32 collateralId, uint256 amount) external returns (uint256 newAccountId);

    /// @notice withdraws 'amount' of settlement token from the profit made
    /// @param accountId account id
    /// @param amount amount of token to withdraw
    function updateProfit(uint256 accountId, int256 amount) external;

    /// @notice settles the profit/loss made with the settlement token collateral deposits
    /// @param accountId account id
    function settleProfit(uint256 accountId) external;

    /// @notice swaps token associated with 'poolId' by 'amount' (Long if amount>0 else Short)
    /// @param accountId account id
    /// @param poolId truncated address of token to withdraw
    /// @param swapParams swap parameters
    function swapToken(
        uint256 accountId,
        uint32 poolId,
        SwapParams memory swapParams
    ) external returns (int256 vTokenAmountOut, int256 vQuoteAmountOut);

    /// @notice updates range order of token associated with 'poolId' by 'liquidityDelta' (Adds if amount>0 else Removes)
    /// @notice also can be used to update limitOrderType
    /// @param accountId account id
    /// @param poolId truncated address of token to withdraw
    /// @param liquidityChangeParams liquidity change parameters
    function updateRangeOrder(
        uint256 accountId,
        uint32 poolId,
        LiquidityChangeParams calldata liquidityChangeParams
    ) external returns (int256 vTokenAmountOut, int256 vQuoteAmountOut);

    /// @notice keeper call to remove a limit order
    /// @dev checks the position of current price relative to limit order and checks limitOrderType
    /// @param accountId account id
    /// @param poolId truncated address of token to withdraw
    /// @param tickLower liquidity change parameters
    /// @param tickUpper liquidity change parameters
    function removeLimitOrder(
        uint256 accountId,
        uint32 poolId,
        int24 tickLower,
        int24 tickUpper
    ) external;

    /// @notice keeper call for liquidation of range position
    /// @dev removes all the active range positions and gives liquidator a percent of notional amount closed + fixedFee
    /// @param accountId account id
    function liquidateLiquidityPositions(uint256 accountId) external;

    /// @notice keeper call for liquidation of token position
    /// @dev transfers the fraction of token position at a discount to current price to liquidators account and gives liquidator some fixedFee
    /// @param targetAccountId account id
    /// @param poolId truncated address of token to withdraw
    /// @return keeperFee - amount of fees transferred to keeper
    function liquidateTokenPosition(uint256 targetAccountId, uint32 poolId) external returns (int256 keeperFee);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseCustomErrors is IClearingHouseStructures {
    /// @notice error to denote invalid account access
    /// @param senderAddress address of msg sender
    error AccessDenied(address senderAddress);

    /// @notice error to denote usage of uninitialized token
    /// @param collateralId address of token
    error CollateralDoesNotExist(uint32 collateralId);

    /// @notice error to denote usage of unsupported collateral token
    /// @param collateralId address of token
    error CollateralNotAllowedForUse(uint32 collateralId);

    /// @notice error to denote unpause is in progress, hence cannot pause
    error CannotPauseIfUnpauseInProgress();

    /// @notice error to denote pause is in progress, hence cannot unpause
    error CannotUnpauseIfPauseInProgress();

    /// @notice error to denote incorrect address is supplied while updating collateral settings
    /// @param incorrectAddress incorrect address of collateral token
    /// @param correctAddress correct address of collateral token
    error IncorrectCollateralAddress(IERC20 incorrectAddress, IERC20 correctAddress);

    /// @notice error to denote invalid address supplied as a collateral token
    /// @param invalidAddress invalid address of collateral token
    error InvalidCollateralAddress(address invalidAddress);

    /// @notice error to denote invalid token liquidation (fraction to liquidate> 1)
    error InvalidTokenLiquidationParameters();

    /// @notice this is errored when the enum (uint8) value is out of bounds
    /// @param multicallOperationType is the value that is out of bounds
    error InvalidMulticallOperationType(MulticallOperationType multicallOperationType);

    /// @notice error to denote that keeper fee is negative or zero
    error KeeperFeeNotPositive(int256 keeperFee);

    /// @notice error to denote low notional value of txn
    /// @param notionalValue notional value of txn
    error LowNotionalValue(uint256 notionalValue);

    /// @notice error to denote that caller is not ragetrade factory
    error NotRageTradeFactory();

    /// @notice error to denote usage of uninitialized pool
    /// @param poolId unitialized truncated address supplied
    error PoolDoesNotExist(uint32 poolId);

    /// @notice error to denote usage of unsupported pool
    /// @param poolId address of token
    error PoolNotAllowedForTrade(uint32 poolId);

    /// @notice error to denote slippage of txn beyond set threshold
    error SlippageBeyondTolerance();

    /// @notice error to denote that zero amount is passed and it's prohibited
    error ZeroAmount();

    /// @notice error to denote an invalid setting for parameters
    error InvalidSetting(uint256 errorCode);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClearingHouseEnums {
    enum LimitOrderType {
        NONE,
        LOWER_LIMIT,
        UPPER_LIMIT
    }

    enum MulticallOperationType {
        UPDATE_MARGIN,
        UPDATE_PROFIT,
        SWAP_TOKEN,
        UPDATE_RANGE_ORDER,
        REMOVE_LIMIT_ORDER,
        LIQUIDATE_LIQUIDITY_POSITIONS,
        LIQUIDATE_TOKEN_POSITION
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseEvents is IClearingHouseStructures {
    /// @notice denotes new account creation
    /// @param ownerAddress wallet address of account owner
    /// @param accountId serial number of the account
    event AccountCreated(address indexed ownerAddress, uint256 accountId);

    /// @notice new collateral supported as margin
    /// @param cTokenInfo collateral token info
    event CollateralSettingsUpdated(IERC20 cToken, CollateralSettings cTokenInfo);

    /// @notice maintainance margin ratio of a pool changed
    /// @param poolId id of the rage trade pool
    /// @param settings new settings
    event PoolSettingsUpdated(uint32 poolId, PoolSettings settings);

    /// @notice protocol settings changed
    /// @param liquidationParams liquidation params
    /// @param removeLimitOrderFee fee for remove limit order
    /// @param minimumOrderNotional minimum order notional
    /// @param minRequiredMargin minimum required margin
    event ProtocolSettingsUpdated(
        LiquidationParams liquidationParams,
        uint256 removeLimitOrderFee,
        uint256 minimumOrderNotional,
        uint256 minRequiredMargin
    );

    event PausedUpdated(bool paused);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseOwnerActions is IClearingHouseStructures {
    /// @notice updates the collataral settings
    /// @param cToken collateral token
    /// @param collateralSettings settings
    function updateCollateralSettings(IERC20 cToken, CollateralSettings memory collateralSettings) external;

    /// @notice updates the rage trade pool settings
    /// @param poolId rage trade pool id
    /// @param newSettings updated rage trade pool settings
    function updatePoolSettings(uint32 poolId, PoolSettings calldata newSettings) external;

    /// @notice updates the protocol settings
    /// @param liquidationParams liquidation params
    /// @param removeLimitOrderFee fee for remove limit order
    /// @param minimumOrderNotional minimum order notional
    /// @param minRequiredMargin minimum required margin
    function updateProtocolSettings(
        LiquidationParams calldata liquidationParams,
        uint256 removeLimitOrderFee,
        uint256 minimumOrderNotional,
        uint256 minRequiredMargin
    ) external;

    /// @notice withdraws protocol fees collected in the supplied wrappers to team multisig
    /// @param numberOfPoolsToUpdateInThisTx number of pools to collect fees from
    function withdrawProtocolFee(uint256 numberOfPoolsToUpdateInThisTx) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IInsuranceFund } from '../IInsuranceFund.sol';
import { IOracle } from '../IOracle.sol';
import { IVQuote } from '../IVQuote.sol';
import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseSystemActions is IClearingHouseStructures {
    /// @notice initializes clearing house contract
    /// @param rageTradeFactoryAddress rage trade factory address
    /// @param defaultCollateralToken address of default collateral token
    /// @param defaultCollateralTokenOracle address of default collateral token oracle
    /// @param insuranceFund address of insurance fund
    /// @param vQuote address of vQuote
    function initialize(
        address rageTradeFactoryAddress,
        address initialGovernance,
        address initialTeamMultisig,
        IERC20 defaultCollateralToken,
        IOracle defaultCollateralTokenOracle,
        IInsuranceFund insuranceFund,
        IVQuote vQuote
    ) external;

    function registerPool(Pool calldata poolInfo) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';
import { IExtsload } from '../IExtsload.sol';

interface IClearingHouseView is IClearingHouseStructures, IExtsload {
    /// @notice Gets the market value and required margin of an account
    /// @dev This method can be used to check if an account is under water or not.
    ///     If accountMarketValue < requiredMargin then liquidation can take place.
    /// @param accountId the account id
    /// @param isInitialMargin true is initial margin, false is maintainance margin
    /// @return accountMarketValue the market value of the account, due to collateral and positions
    /// @return requiredMargin margin needed due to positions
    function getAccountMarketValueAndRequiredMargin(uint256 accountId, bool isInitialMargin)
        external
        view
        returns (int256 accountMarketValue, int256 requiredMargin);

    /// @notice Gets the net profit of an account
    /// @param accountId the account id
    /// @return accountNetProfit the net profit of the account
    function getAccountNetProfit(uint256 accountId) external view returns (int256 accountNetProfit);

    /// @notice Gets the net position of an account
    /// @param accountId the account id
    /// @param poolId the id of the pool (vETH, ... etc)
    /// @return netPosition the net position of the account
    function getAccountNetTokenPosition(uint256 accountId, uint32 poolId) external view returns (int256 netPosition);

    /// @notice Gets the real twap price from the respective oracle of the given poolId
    /// @param poolId the id of the pool
    /// @return realPriceX128 the real price of the pool
    function getRealTwapPriceX128(uint32 poolId) external view returns (uint256 realPriceX128);

    /// @notice Gets the virtual twap price from the respective oracle of the given poolId
    /// @param poolId the id of the pool
    /// @return virtualPriceX128 the virtual price of the pool
    function getVirtualTwapPriceX128(uint32 poolId) external view returns (uint256 virtualPriceX128);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IOracle {
    function getTwapPriceX128(uint32 twapDuration) external view returns (uint256 priceX128);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IInsuranceFund {
    function initialize(
        IERC20 settlementToken,
        address clearingHouse,
        string calldata name,
        string calldata symbol
    ) external;

    function claim(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/// @title This is an interface to read contract's state that supports extsload.
interface IExtsload {
    /// @notice Returns a value from the storage.
    /// @param slot to read from.
    /// @return value stored at the slot.
    function extsload(bytes32 slot) external view returns (bytes32 value);

    /// @notice Returns multiple values from storage.
    /// @param slots to read from.
    /// @return values stored at the slots.
    function extsload(bytes32[] memory slots) external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/// @title Uint48 concating functions
library Uint48Lib {
    /// @notice Packs two int24 values into uint48
    /// @dev Used for concating two ticks into 48 bits value
    /// @param val1 First 24 bits value
    /// @param val2 Second 24 bits value
    /// @return concatenated value
    function concat(int24 val1, int24 val2) internal pure returns (uint48 concatenated) {
        assembly {
            concatenated := add(shl(24, val1), and(val2, 0x000000ffffff))
        }
    }

    /// @notice Unpacks uint48 into two int24 values
    /// @dev Used for unpacking 48 bits value into two 24 bits values
    /// @param concatenated 48 bits value
    /// @return val1 First 24 bits value
    /// @return val2 Second 24 bits value
    function unconcat(uint48 concatenated) internal pure returns (int24 val1, int24 val2) {
        assembly {
            val2 := concatenated
            val1 := shr(24, concatenated)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import { IClearingHouseStructures } from '../interfaces/clearinghouse/IClearingHouseStructures.sol';

import { Uint48Lib } from '../libraries/Uint48.sol';

library WordHelper {
    using WordHelper for bytes32;

    struct Word {
        bytes32 data;
    }

    // struct Word methods

    function copyToMemory(bytes32 data) internal pure returns (Word memory) {
        return Word(data);
    }

    function pop(Word memory input, uint256 bits) internal pure returns (uint256 value) {
        (value, input.data) = pop(input.data, bits);
    }

    function popAddress(Word memory input) internal pure returns (address value) {
        (value, input.data) = popAddress(input.data);
    }

    function popUint8(Word memory input) internal pure returns (uint8 value) {
        (value, input.data) = popUint8(input.data);
    }

    function popUint16(Word memory input) internal pure returns (uint16 value) {
        (value, input.data) = popUint16(input.data);
    }

    function popUint32(Word memory input) internal pure returns (uint32 value) {
        (value, input.data) = popUint32(input.data);
    }

    function popUint64(Word memory input) internal pure returns (uint64 value) {
        (value, input.data) = popUint64(input.data);
    }

    function popUint128(Word memory input) internal pure returns (uint128 value) {
        (value, input.data) = popUint128(input.data);
    }

    function popBool(Word memory input) internal pure returns (bool value) {
        (value, input.data) = popBool(input.data);
    }

    function slice(
        Word memory input,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes32 val) {
        return slice(input.data, start, end);
    }

    // primitive uint256 methods

    function fromUint(uint256 input) internal pure returns (bytes32 output) {
        assembly {
            output := input
        }
    }

    // primitive bytes32 methods

    function keccak256One(bytes32 input) internal pure returns (bytes32 result) {
        assembly {
            mstore(0, input)
            result := keccak256(0, 0x20)
        }
    }

    function keccak256Two(bytes32 paddedKey, bytes32 mappingSlot) internal pure returns (bytes32 result) {
        assembly {
            mstore(0, paddedKey)
            mstore(0x20, mappingSlot)
            result := keccak256(0, 0x40)
        }
    }

    function offset(bytes32 key, uint256 offset_) internal pure returns (bytes32) {
        assembly {
            key := add(key, offset_)
        }
        return key;
    }

    function slice(
        bytes32 input,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes32 val) {
        assembly {
            val := shl(start, input)
            val := shr(add(start, sub(256, end)), val)
        }
    }

    /// @notice pops bits from the right side of the input
    /// @dev E.g. input = 0x0102030405060708091011121314151617181920212223242526272829303132
    ///          input.pop(16) -> 0x3132
    ///          input.pop(16) -> 0x2930
    ///          input -> 0x0000000001020304050607080910111213141516171819202122232425262728
    /// @dev this does not throw on underflow, value returned would be zero
    /// @param input the input bytes
    /// @param bits the number of bits to pop
    /// @return value of the popped bits
    /// @return inputUpdated the input bytes shifted right by bits
    function pop(bytes32 input, uint256 bits) internal pure returns (uint256 value, bytes32 inputUpdated) {
        assembly {
            let shift := sub(256, bits)
            value := shr(shift, shl(shift, input))
            inputUpdated := shr(bits, input)
        }
    }

    function popAddress(bytes32 input) internal pure returns (address value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 160);
        assembly {
            value := temp
        }
    }

    function popUint8(bytes32 input) internal pure returns (uint8 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 8);
        value = uint8(temp);
    }

    function popUint16(bytes32 input) internal pure returns (uint16 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 16);
        value = uint16(temp);
    }

    function popUint32(bytes32 input) internal pure returns (uint32 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 32);
        value = uint32(temp);
    }

    function popUint64(bytes32 input) internal pure returns (uint64 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 64);
        value = uint64(temp);
    }

    function popUint128(bytes32 input) internal pure returns (uint128 value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 128);
        value = uint128(temp);
    }

    function popBool(bytes32 input) internal pure returns (bool value, bytes32 inputUpdated) {
        uint256 temp;
        (temp, inputUpdated) = pop(input, 8);
        value = temp != 0;
    }

    function toAddress(bytes32 input) internal pure returns (address value) {
        return address(toUint160(input));
    }

    function toUint8(bytes32 input) internal pure returns (uint8 value) {
        return uint8(toUint256(input));
    }

    function toUint16(bytes32 input) internal pure returns (uint16 value) {
        return uint16(toUint256(input));
    }

    function toUint32(bytes32 input) internal pure returns (uint32 value) {
        return uint32(toUint256(input));
    }

    function toUint48(bytes32 input) internal pure returns (uint48 value) {
        return uint48(toUint256(input));
    }

    function toUint64(bytes32 input) internal pure returns (uint64 value) {
        return uint64(toUint256(input));
    }

    function toUint128(bytes32 input) internal pure returns (uint128 value) {
        return uint128(toUint256(input));
    }

    function toUint160(bytes32 input) internal pure returns (uint160 value) {
        return uint160(toUint256(input));
    }

    function toUint256(bytes32 input) internal pure returns (uint256 value) {
        assembly {
            value := input
        }
    }

    function toInt256(bytes32 input) internal pure returns (int256 value) {
        assembly {
            value := input
        }
    }

    function toBool(bytes32 input) internal pure returns (bool value) {
        (value, ) = popBool(input);
    }

    bytes32 constant ZERO = bytes32(uint256(0));

    function convertToUint32Array(bytes32 active) internal pure returns (uint32[] memory activeArr) {
        unchecked {
            uint256 i = 8;
            while (i > 0) {
                bytes32 id = active.slice((i - 1) * 32, i * 32);
                if (id == ZERO) {
                    break;
                }
                i--;
            }
            activeArr = new uint32[](8 - i);
            while (i < 8) {
                activeArr[7 - i] = active.slice(i * 32, (i + 1) * 32).toUint32();
                i++;
            }
        }
    }

    function convertToTickRangeArray(bytes32 active)
        internal
        pure
        returns (IClearingHouseStructures.TickRange[] memory activeArr)
    {
        unchecked {
            uint256 i = 5;
            while (i > 0) {
                bytes32 id = active.slice((i - 1) * 48, i * 48);
                if (id == ZERO) {
                    break;
                }
                i--;
            }
            activeArr = new IClearingHouseStructures.TickRange[](5 - i);
            while (i < 5) {
                // 256 - 48 * 5 = 16
                (int24 tickLower, int24 tickUpper) = Uint48Lib.unconcat(
                    active.slice(16 + i * 48, 16 + (i + 1) * 48).toUint48()
                );
                activeArr[4 - i].tickLower = tickLower;
                activeArr[4 - i].tickUpper = tickUpper;
                i++;
            }
        }
    }
}