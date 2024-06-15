// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
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
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                FullMath.mulDiv(
                    uint256(liquidity) << FixedPoint96.RESOLUTION,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

pragma solidity ^0.8.0;

interface ITeaVaultV3Pair {

    error PoolNotInitialized();
    error InvalidFeePercentage();
    error InvalidFeeCap();
    error InvalidShareAmount();
    error PositionLengthExceedsLimit();
    error InvalidPriceSlippage(uint256 amount0, uint256 amount1);
    error PositionDoesNotExist();
    error ZeroLiquidity();
    error CallerIsNotManager();
    error InvalidCallbackStatus();
    error InvalidCallbackCaller();
    error SwapInZeroLiquidityRegion();
    error TransactionExpired();
    error InvalidSwapToken();
    error InvalidSwapReceiver();
    error InsufficientSwapResult(uint256 minAmount, uint256 convertedAmount);
    error InvalidTokenOrder();

    event TeaVaultV3PairCreated(address indexed teaVaultAddress);
    event FeeConfigChanged(address indexed sender, uint256 timestamp, FeeConfig feeConfig);
    event ManagerChanged(address indexed sender, address indexed newManager);
    event ManagementFeeCollected(uint256 shares);
    event DepositShares(address indexed shareOwner, uint256 shares, uint256 amount0, uint256 amount1, uint256 feeAmount0, uint256 feeAmount1);
    event WithdrawShares(address indexed shareOwner, uint256 shares, uint256 amount0, uint256 amount1, uint256 feeShares);
    event AddLiquidity(address indexed pool, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 amount0, uint256 amount1);
    event RemoveLiquidity(address indexed pool, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 amount0, uint256 amount1);
    event Collect(address indexed pool, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1);
    event CollectSwapFees(address indexed pool, uint256 amount0, uint256 amount1, uint256 feeAmount0, uint256 feeAmount1);
    event Swap(bool indexed zeroForOne, bool indexed exactInput, uint256 amountIn, uint256 amountOut);

    /// @notice Fee config structure
    /// @param vault Fee goes to this address
    /// @param entryFee Entry fee in 0.0001% (collected when depositing)
    /// @param exitFee Exit fee in 0.0001% (collected when withdrawing)
    /// @param performanceFee Platform performance fee in 0.0001% (collected for each cycle, from profits)
    /// @param managementFee Platform yearly management fee in 0.0001% (collected when depositing/withdrawing)
    struct FeeConfig {
        address vault;
        uint24 entryFee;
        uint24 exitFee;
        uint24 performanceFee;
        uint24 managementFee;
    }

    /// @notice Uniswap V3 position structure
    /// @param tickLower Tick lower bound
    /// @param tickUpper Tick upper bound
    /// @param liquidity Liquidity size
    struct Position {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    /// @notice get asset token0 address
    /// @return token0 token0 address
    function assetToken0() external view returns (address token0);

    /// @notice get asset token1 address
    /// @return token1 token1 address
    function assetToken1() external view returns (address token1);

    /// @notice get vault balance of token0
    /// @return amount vault balance of token0
    function getToken0Balance() external view returns (uint256 amount);

    /// @notice get vault balance of token1
    /// @return amount vault balance of token1
    function getToken1Balance() external view returns (uint256 amount);

    /// @notice get pool token and price info
    /// @return token0 token0 address
    /// @return token1 token1 address
    /// @return decimals0 token0 decimals
    /// @return decimals1 token1 decimals
    /// @return feeTier current pool price in tick
    /// @return sqrtPriceX96 current pool price in sqrtPriceX96
    /// @return tick current pool price in tick
    function getPoolInfo() external view returns (
        address token0,
        address token1,
        uint8 decimals0,
        uint8 decimals1,
        uint24 feeTier,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /// @notice Set fee structure and vault addresses
    /// @notice Only available to admins
    /// @param _feeConfig Fee structure settings
    function setFeeConfig(FeeConfig calldata _feeConfig) external;

    /// @notice Assign fund manager
    /// @notice Only the owner can do this
    /// @param _manager Fund manager address
    function assignManager(address _manager) external;

    /// @notice Collect management fee by share token inflation
    /// @notice Only fund manager can do this
    /// @return collectedShares Share amount collected by minting
    function collectManagementFee() external returns (uint256 collectedShares);

    /// @notice Mint shares and deposit token0 and token1
    /// @param _shares Share amount to be mint
    /// @param _amount0Max Max token0 amount to be deposited
    /// @param _amount1Max Max token1 amount to be deposited
    /// @return depositedAmount0 Deposited token0 amount
    /// @return depositedAmount1 Deposited token1 amount
    function deposit(
        uint256 _shares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external returns (uint256 depositedAmount0, uint256 depositedAmount1);

    /// @notice Burn shares and withdraw token0 and token1
    /// @param _shares Share amount to be burnt
    /// @param _amount0Min Min token0 amount to be withdrawn
    /// @param _amount1Min Min token1 amount to be withdrawn
    /// @return withdrawnAmount0 Withdrew token0 amount
    /// @return withdrawnAmount1 Withdrew token1 amount
    function withdraw(
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1);

    /// @notice Add liquidity to a position from this vault
    /// @notice Only fund manager can do this
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @param _liquidity Liquidity to be added to the position
    /// @param _amount0Min Minimum token0 amount to be added to the position
    /// @param _amount1Min Minimum token1 amount to be added to the position
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amount0 Token0 amount added to the position
    /// @return amount1 Token1 amount added to the position
    function addLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint64 _deadline
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Remove liquidity from a position from this vault
    /// @notice Only fund manager can do this
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @param _liquidity Liquidity to be removed from the position
    /// @param _amount0Min Minimum token0 amount to be removed from the position
    /// @param _amount1Min Minimum token1 amount to be removed from the position
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amount0 Token0 amount removed from the position
    /// @return amount1 Token1 amount removed from the position
    function removeLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint64 _deadline
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collect swap fee of a position
    /// @notice Only fund manager can do this
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @return amount0 Token0 amount collected from the position
    /// @return amount1 Token1 amount collected from the position
    function collectPositionSwapFee(
        int24 _tickLower,
        int24 _tickUpper
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Collect swap fee of all positions
    /// @notice Only fund manager can do this
    /// @return amount0 Token0 amount collected from the positions
    /// @return amount1 Token1 amount collected from the positions
    function collectAllSwapFee() external returns (uint128 amount0, uint128 amount1);

    /// @notice Swap tokens on the pool with exact input amount
    /// @notice Only fund manager can do this
    /// @param _zeroForOne Swap direction from token0 to token1 or not
    /// @param _amountIn Amount of input token
    /// @param _amountOutMin Required minimum output token amount
    /// @param _minPriceInSqrtPriceX96 Minimum price in sqrtPriceX96
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amountOut Output token amount
    function swapInputSingle(
        bool _zeroForOne,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint160 _minPriceInSqrtPriceX96,
        uint64 _deadline
    ) external returns (uint256 amountOut);


    /// @notice Swap tokens on the pool with exact output amount
    /// @notice Only fund manager can do this
    /// @param _zeroForOne Swap direction from token0 to token1 or not
    /// @param _amountOut Output token amount
    /// @param _amountInMax Required maximum input token amount
    /// @param _maxPriceInSqrtPriceX96 Maximum price in sqrtPriceX96
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amountIn Input token amount
    function swapOutputSingle(
        bool _zeroForOne,
        uint256 _amountOut,
        uint256 _amountInMax,
        uint160 _maxPriceInSqrtPriceX96,
        uint64 _deadline
    ) external returns (uint256 amountIn);

    /// @notice Process batch operations in one transation
    /// @return results Results in bytes array
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    /// @notice Get position info by specifying tickLower and tickUpper of the position
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @return amount0 Current position token0 amount
    /// @return amount1 Current position token1 amount
    /// @return fee0 Pending fee token0 amount
    /// @return fee1 Pending fee token1 amount
    function positionInfo(
        int24 _tickLower,
        int24 _tickUpper
    ) external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    /// @notice Get position info by specifying position index
    /// @param _index Position index
    /// @return amount0 Current position token0 amount
    /// @return amount1 Current position token1 amount
    /// @return fee0 Pending fee token0 amount
    /// @return fee1 Pending fee token1 amount
    function positionInfo(
        uint256 _index
    ) external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    /// @notice Get all position info
    /// @return amount0 All positions token0 amount
    /// @return amount1 All positions token1 amount
    /// @return fee0 All positions pending fee token0 amount
    /// @return fee1 All positions pending fee token1 amount
    function allPositionInfo() external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    /// @notice Get underlying assets hold by this vault
    /// @return amount0 Total token0 amount
    /// @return amount1 Total token1 amount
    function vaultAllUnderlyingAssets() external view returns (uint256 amount0, uint256 amount1);

    /// @notice Get vault value in token0
    /// @return value0 Vault value in token0
    function estimatedValueInToken0() external view returns (uint256 value0);

    /// @notice Get vault value in token1
    /// @return value1 Vault value in token1
    function estimatedValueInToken1() external view returns (uint256 value1);

    /// @notice Calculate liquidity of a position from amount0 and amount1
    /// @param tickLower lower tick of the position
    /// @param tickUpper upper tick of the position
    /// @param amount0 amount of token0
    /// @param amount1 amount of token1
    /// @return liquidity calculated liquidity 
    function getLiquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external view returns (uint128 liquidity);

    /// @notice Calculate amount of tokens required for liquidity of a position
    /// @param tickLower lower tick of the position
    /// @param tickUpper upper tick of the position
    /// @param liquidity amount of liquidity
    /// @return amount0 amount of token0 required
    /// @return amount1 amount of token1 required
    function getAmountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external view returns (uint256 amount0, uint256 amount1);

    /// @notice Get all open positions
    /// @return results Array of all open positions
   function getAllPositions() external view returns (Position[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV3Pool {

    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
    function feeGrowthGlobal0X128() external view returns (uint256);
    function feeGrowthGlobal1X128() external view returns (uint256);
    function ticks(int24 tick) external view returns (
        uint128 liquidityGross,
        int128 liquidityNet,
        uint256 feeGrowthOutside0X128,
        uint256 feeGrowthOutside1X128,
        int56 tickCumulativeOutside,
        uint160 secondsPerLiquidityOutsideX128,
        uint32 secondsOutside,
        bool initialized
    );
    function positions(bytes32 key) external view returns (
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance
pragma solidity =0.8.25;

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint128.sol";

import "../interface/IUniswapV3Pool.sol";
import "../interface/ITeaVaultV3Pair.sol";

library VaultUtils {

    function getLiquidityForAmounts(
        IUniswapV3Pool _pool,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _amount0,
        uint256 _amount1
    ) external view returns (uint128 liquidity) {
        (uint160 sqrtPriceX96, , , , , , ) = _pool.slot0();
        
        return LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(_tickLower),
            TickMath.getSqrtRatioAtTick(_tickUpper),
            _amount0,
            _amount1
        );
    }

    function getAmountsForLiquidity(
        IUniswapV3Pool _pool,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity
    ) external view returns (uint256 amount0, uint256 amount1) {
        (uint160 sqrtPriceX96, , , , , , ) = _pool.slot0();

        return LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(_tickLower),
            TickMath.getSqrtRatioAtTick(_tickUpper),
            _liquidity
        );
    }

    function positionInfo(
        address vault,
        IUniswapV3Pool pool,
        ITeaVaultV3Pair.Position storage position
    ) external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1) {
        bytes32 positionKey = keccak256(abi.encodePacked(vault, position.tickLower, position.tickUpper));
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
        (, , uint256 feeGrowthOutside0X128Lower, uint256 feeGrowthOutside1X128Lower, , , , ) = pool.ticks(position.tickLower);
        (, , uint256 feeGrowthOutside0X128Upper, uint256 feeGrowthOutside1X128Upper, , , , ) = pool.ticks(position.tickUpper);
        (
            uint128 liquidity,
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = pool.positions(positionKey);

        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(position.tickLower),
            TickMath.getSqrtRatioAtTick(position.tickUpper),
            liquidity
        );
        
        fee0 = tokensOwed0 + potisionSwapFee(
            tick,
            position.tickLower,
            position.tickUpper,
            liquidity,
            feeGrowthGlobal0X128,
            feeGrowthInside0Last,
            feeGrowthOutside0X128Lower,
            feeGrowthOutside0X128Upper
        );

        fee1 = tokensOwed1 + potisionSwapFee(
            tick,
            position.tickLower,
            position.tickUpper,
            liquidity,
            feeGrowthGlobal1X128,
            feeGrowthInside1Last,
            feeGrowthOutside1X128Lower,
            feeGrowthOutside1X128Upper
        );
    }

    function potisionSwapFee(
        int24 _tick,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        uint256 _feeGrowthGlobalX128,
        uint256 _feeGrowthInsideLastX128,
        uint256 _feeGrowthOutsideX128Lower,
        uint256 _feeGrowthOutsideX128Upper
    ) public pure returns (uint256 swapFee) {
        unchecked {
            uint256 feeGrowthInsideX128;
            uint256 feeGrowthBelowX128;
            uint256 feeGrowthAboveX128;

            feeGrowthBelowX128 = _tick >= _tickLower?
                _feeGrowthOutsideX128Lower:
                _feeGrowthGlobalX128 - _feeGrowthOutsideX128Lower;
            
            feeGrowthAboveX128 = _tick < _tickUpper?
                _feeGrowthOutsideX128Upper:
                _feeGrowthGlobalX128 - _feeGrowthOutsideX128Upper;

            feeGrowthInsideX128 = _feeGrowthGlobalX128 - feeGrowthBelowX128 - feeGrowthAboveX128;

            swapFee = FullMath.mulDiv(
                feeGrowthInsideX128 - _feeGrowthInsideLastX128,
                _liquidity,
                FixedPoint128.Q128
            );
        }
    }

    function estimatedValueInToken0(
        IUniswapV3Pool pool,
        uint256 _amount0,
        uint256 _amount1
    ) external view returns (uint256 value0) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        value0 = _amount0 + FullMath.mulDiv(
            _amount1,
            FixedPoint96.Q96,
            FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96)
        );
    }

    function estimatedValueInToken1(
        IUniswapV3Pool pool,
        uint256 _amount0,
        uint256 _amount1
    ) external view returns (uint256 value1) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        value1 = _amount1 + FullMath.mulDiv(
            _amount0,
            FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96),
            FixedPoint96.Q96
        );
    }
}