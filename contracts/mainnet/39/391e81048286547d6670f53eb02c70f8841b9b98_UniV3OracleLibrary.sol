// SPDX-License-Indetifier: MIT
pragma solidity ^0.8.10;

import {IUniswapV3Pool} from "src/interfaces/swap/uniswap/IUniswapV3Pool.sol";
import {OracleLibrary} from "src/oracles/OracleLibrary.sol";
import {IMetadata} from "src/interfaces/IMetadata.sol";

library UniV3OracleLibrary {
    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /**
     * @notice Get TWAP of token0 quoted in token1.
     * @param _secondsAgo Length of TWAP.
     */
    function getPrice(IUniswapV3Pool _pool, int24 _secondsAgo) public view returns (uint256) {
        // Avoid revert with arg 0 and get spot price.
        _secondsAgo = _secondsAgo == 0 ? int24(1) : _secondsAgo;

        uint32[] memory secondsAgo = new uint32[](2);

        secondsAgo[0] = uint32(uint24(_secondsAgo));
        secondsAgo[1] = 0;

        // Get cumulative ticks
        (int56[] memory tickCumulative,) = _pool.observe(secondsAgo);

        // Now get the cumulative tick just for the specified timeframe (_secondsAgo).
        int56 deltaCumulativeTicks = tickCumulative[1] - tickCumulative[0];

        // Get the arithmetic mean of the delta between the two cumulative ticks.
        int24 arithmeticMeanTick = int24(deltaCumulativeTicks / _secondsAgo);

        // Rounding to negative infinity.
        if (deltaCumulativeTicks < 0 && (deltaCumulativeTicks % _secondsAgo != 0)) {
            arithmeticMeanTick = arithmeticMeanTick - 1;
        }

        // One unit of token0, so we if for example token has 9 decimals, one unit will be 10 ** 9 = 1000000000.
        uint256 oneUnit = 10 ** IMetadata(_pool.token0()).decimals();

        return OracleLibrary.getQuoteAtTick(arithmeticMeanTick, uint128(oneUnit), _pool.token0(), _pool.token1());
    }

    function getSpot(IUniswapV3Pool _pool) public view returns (uint256) {
        return getPrice(_pool, 0);
    }

    function getPool(address factory, address tokenA, address tokenB, uint24 fee, bytes32 initCodeHash)
        public
        pure
        returns (IUniswapV3Pool)
    {
        return IUniswapV3Pool(computeAddress(factory, getPoolKey(tokenA, tokenB, fee), initCodeHash));
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB, uint24 fee) private pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key, bytes32 initCodeHash)
        private
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff", factory, keccak256(abi.encode(key.token0, key.token1, key.fee)), initCodeHash
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

interface IUniswapV3Pool {
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

    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

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
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

import "src/oracles/FullMath.sol";
import "src/oracles/TickMath.sol";
import "src/interfaces/swap/uniswap/IUniswapV3Pool.sol";

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(int24 tick, uint128 baseAmount, address baseToken, address quoteToken)
        internal
        pure
        returns (uint256 quoteAmount)
    {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IMetadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0 = a * b; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            // Subtract 256 bit remainder from 512 bit number
            assembly {
                let remainder := mulmod(a, b, denominator)
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
            // correct result modulo 2**256. Since the preconditions guarantee
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
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            if (a == 0 || ((result = a * b) / a == b)) {
                require(denominator > 0);
                assembly {
                    result := add(div(result, denominator), gt(mod(result, denominator), 0))
                }
            } else {
                result = mulDiv(a, b, denominator);
                if (mulmod(a, b, denominator) > 0) {
                    require(result < type(uint256).max);
                    result++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library TickMath {
    error tickOutOfRange();

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
    /// @return price A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 price) {
        unchecked {
            // get abs value
            int24 mask = tick >> (24 - 1);
            uint256 absTick = uint24((tick ^ mask) - mask);
            if (absTick > uint24(MAX_TICK)) {
                revert tickOutOfRange();
            }

            uint256 ratio =
                absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) {
                ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            }
            if (absTick & 0x4 != 0) {
                ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            }
            if (absTick & 0x8 != 0) {
                ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            }
            if (absTick & 0x10 != 0) {
                ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            }
            if (absTick & 0x20 != 0) {
                ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            }
            if (absTick & 0x40 != 0) {
                ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            }
            if (absTick & 0x80 != 0) {
                ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            }
            if (absTick & 0x100 != 0) {
                ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            }
            if (absTick & 0x200 != 0) {
                ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            }
            if (absTick & 0x400 != 0) {
                ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            }
            if (absTick & 0x800 != 0) {
                ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            }
            if (absTick & 0x1000 != 0) {
                ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            }
            if (absTick & 0x2000 != 0) {
                ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            }
            if (absTick & 0x4000 != 0) {
                ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            }
            if (absTick & 0x8000 != 0) {
                ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            }
            if (absTick & 0x10000 != 0) {
                ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            }
            if (absTick & 0x20000 != 0) {
                ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            }
            if (absTick & 0x40000 != 0) {
                ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            }
            if (absTick & 0x80000 != 0) {
                ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
            }

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            price = uint160((ratio + 0xFFFFFFFF) >> 32);
        }
    }
}