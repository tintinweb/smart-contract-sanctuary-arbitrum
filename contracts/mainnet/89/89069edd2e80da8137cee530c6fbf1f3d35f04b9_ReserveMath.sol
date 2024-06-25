// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import { LiquidityAmounts } from '../../lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol';

import { ISovereignPool } from '../../lib/valantis-core/src/pools/interfaces/ISovereignPool.sol';

import { TightPack } from '../libraries/utils/TightPack.sol';
import { AMMState } from '../structs/HOTStructs.sol';

library ReserveMath {
    using TightPack for AMMState;

    /**
        @notice Returns the AMM reserves assuming some AMM spot price.
        @param sqrtSpotPriceX96New square-root price to query AMM reserves for, in Q96 format.
        @return reserve0 Reserves of token0 at `sqrtSpotPriceX96New`.
        @return reserve1 Reserves of token1 at `sqrtSpotPriceX96New`.
     */
    function getReservesAtPrice(
        AMMState storage _ammState,
        address _pool,
        uint128 _effectiveAMMLiquidity,
        uint160 sqrtSpotPriceX96New
    ) external view returns (uint256 reserve0, uint256 reserve1) {
        (uint160 sqrtSpotPriceX96, uint160 sqrtPriceLowX96, uint160 sqrtPriceHighX96) = _ammState.getState();

        (reserve0, reserve1) = ISovereignPool(_pool).getReserves();

        uint128 effectiveAMMLiquidityCache = _effectiveAMMLiquidity;

        (uint256 activeReserve0, uint256 activeReserve1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtSpotPriceX96,
            sqrtPriceLowX96,
            sqrtPriceHighX96,
            effectiveAMMLiquidityCache
        );

        uint256 passiveReserve0 = reserve0 - activeReserve0;
        uint256 passiveReserve1 = reserve1 - activeReserve1;

        (activeReserve0, activeReserve1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtSpotPriceX96New,
            sqrtPriceLowX96,
            sqrtPriceHighX96,
            effectiveAMMLiquidityCache
        );

        reserve0 = passiveReserve0 + activeReserve0;
        reserve1 = passiveReserve1 + activeReserve1;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IValantisPool } from '../interfaces/IValantisPool.sol';
import { PoolLocks } from '../structs/ReentrancyGuardStructs.sol';
import { SovereignPoolSwapContextData, SovereignPoolSwapParams } from '../structs/SovereignPoolStructs.sol';

interface ISovereignPool is IValantisPool {
    event SwapFeeModuleSet(address swapFeeModule);
    event ALMSet(address alm);
    event GaugeSet(address gauge);
    event PoolManagerSet(address poolManager);
    event PoolManagerFeeSet(uint256 poolManagerFeeBips);
    event SovereignOracleSet(address sovereignOracle);
    event PoolManagerFeesClaimed(uint256 amount0, uint256 amount1);
    event DepositLiquidity(uint256 amount0, uint256 amount1);
    event WithdrawLiquidity(address indexed recipient, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, bool isZeroToOne, uint256 amountIn, uint256 fee, uint256 amountOut);

    function getTokens() external view returns (address[] memory tokens);

    function sovereignVault() external view returns (address);

    function protocolFactory() external view returns (address);

    function gauge() external view returns (address);

    function poolManager() external view returns (address);

    function sovereignOracleModule() external view returns (address);

    function swapFeeModule() external view returns (address);

    function verifierModule() external view returns (address);

    function isLocked() external view returns (bool);

    function isRebaseTokenPool() external view returns (bool);

    function poolManagerFeeBips() external view returns (uint256);

    function defaultSwapFeeBips() external view returns (uint256);

    function swapFeeModuleUpdateTimestamp() external view returns (uint256);

    function alm() external view returns (address);

    function getPoolManagerFees() external view returns (uint256 poolManagerFee0, uint256 poolManagerFee1);

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);

    function setPoolManager(address _manager) external;

    function setGauge(address _gauge) external;

    function setPoolManagerFeeBips(uint256 _poolManagerFeeBips) external;

    function setSovereignOracle(address sovereignOracle) external;

    function setSwapFeeModule(address _swapFeeModule) external;

    function setALM(address _alm) external;

    function swap(SovereignPoolSwapParams calldata _swapParams) external returns (uint256, uint256);

    function depositLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _sender,
        bytes calldata _verificationContext,
        bytes calldata _depositData
    ) external returns (uint256 amount0Deposited, uint256 amount1Deposited);

    function withdrawLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _sender,
        address _recipient,
        bytes calldata _verificationContext
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import { AMMState } from '../../structs/HOTStructs.sol';

/**
    @notice Helper library for tight packing multiple uint160 values into minimum amount of uint256 slots.
 */
library TightPack {
    uint256 constant LOWER_160_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant UPPER_96_MASK = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;

    /************************************************
     *  FUNCTIONS
     ***********************************************/

    /**
        @notice Packs 3 uint160 values into 2 uint256 slots.
        @param a uint160 value to pack into slot1.
        @param b uint160 value to pack into slot1 and slot2.
        @param c uint160 value to pack into slot2.
        @dev slot1: << 32 free bits | upper 64 bits of b | all 160 bits of a >>
             slot2: << lower 96 bits of b | all 160 bits of c >>
     */
    function setState(AMMState storage state, uint160 a, uint160 b, uint160 c) internal {
        uint256 slot1;
        uint256 slot2;
        assembly {
            slot1 := or(shl(160, shr(96, b)), a)
            slot2 := or(shl(160, b), c)
        }

        state.slot1 = slot1;
        state.slot2 = slot2;
    }

    /**
        @notice Unpacks 2 uint256 slots into 3 uint160 values.
        @param state AMMState struct containing slot1 and slot2.
        @return a uint160 value unpacked from slot1.
        @return b uint160 value unpacked from slot1 and slot2.
        @return c uint160 value unpacked from slot2.
        @dev slot1: << 32 empty bits | upper 64 bits of b | all 160 bits of a >>
             slot2: << lower 96 bits of b | all 160 bits of c >>
     */
    function getState(AMMState storage state) internal view returns (uint160 a, uint160 b, uint160 c) {
        uint256 slot1 = state.slot1;
        uint256 slot2 = state.slot2;

        assembly {
            a := and(slot1, LOWER_160_MASK)
            c := and(slot2, LOWER_160_MASK)
            b := or(shl(96, shr(160, slot1)), shr(160, slot2))
        }
    }

    function getSqrtSpotPriceX96(AMMState storage state) internal view returns (uint160 a) {
        uint256 slot1 = state.slot1;
        assembly {
            a := and(slot1, LOWER_160_MASK)
        }
    }

    function setSqrtSpotPriceX96(AMMState storage state, uint160 a) internal {
        uint256 slot1 = state.slot1;
        assembly {
            slot1 := or(and(slot1, UPPER_96_MASK), a)
        }
        state.slot1 = slot1;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/**
    @notice The struct with all the information for a HOT swap. 

    This struct is signed by `signer`, and put onchain via HOT swaps.

    * amountInMax: Maximum amount of input token which `authorizedSender` is allowed to swap.
    * sqrtHotPriceX96Discounted: sqrtPriceX96 to quote if the HOT is eligible to update AMM state (see HOT).
    * sqrtHotPriceX96Base: sqrtPriceX96 to quote if the HOT isn't eligible to update AMM (can be same as above).
    * sqrtSpotPriceX96New: New sqrt spot price of the AMM, in Q96 format.
    * authorizedSender: Address of authorized msg.sender in `pool`.
    * authorizedRecipient: Address of authorized recipient of tokenOut amounts.
    * signatureTimestamp: Offchain UNIX timestamp that determines when this HOT intent has been signed.
    * expiry: Duration, in seconds, for the validity of this HOT intent.
    * feeMinToken0: Minimum AMM swap fee for token0.
    * feeMaxToken0: Maximum AMM swap fee for token0.
    * feeGrowthE6Token0: Fee growth in pips, per second, of AMM swap fee for token0.
    * feeMinToken1: Minimum AMM swap fee for token1.
    * feeMaxToken1: Maximum AMM swap fee for token1.
    * feeGrowthE6Token1: Fee growth in pips, per second, of AMM swap fee for token1.
    * nonce: Nonce in bitmap format (see AlternatingNonceBitmap library and docs).
    * expectedFlag: Expected flag (0 or 1) for nonce (see AlternatingNonceBitmap library and docs).
    * isZeroToOne: Direction of the swap for which the HOT is valid.
 */
struct HybridOrderType {
    uint256 amountInMax;
    uint160 sqrtHotPriceX96Discounted;
    uint160 sqrtHotPriceX96Base;
    uint160 sqrtSpotPriceX96New;
    address authorizedSender;
    address authorizedRecipient;
    uint32 signatureTimestamp;
    uint32 expiry;
    uint16 feeMinToken0;
    uint16 feeMaxToken0;
    uint16 feeGrowthE6Token0;
    uint16 feeMinToken1;
    uint16 feeMaxToken1;
    uint16 feeGrowthE6Token1;
    uint8 nonce;
    uint8 expectedFlag;
    bool isZeroToOne;
}

/**
    @notice Packed struct containing state variables which get updated on HOT swaps.

    * lastProcessedBlockQuoteCount: Number of HOT swaps processed in the last block.
    * feeGrowthE6Token0: Fee growth in pips, per second, of AMM swap fee for token0.
    * feeMaxToken0: Maximum AMM swap fee for token0.
    * feeMinToken0: Minimum AMM swap fee for token0.
    * feeGrowthE6Token1: Fee growth in pips, per second, of AMM swap fee for token1.
    * feeMaxToken1: Maximum AMM swap fee for token1.
    * feeMinToken1: Minimum AMM swap fee for token1.
    * lastStateUpdateTimestamp: Block timestamp of the last AMM state update from an HOT swap.
    * lastProcessedQuoteTimestamp: Block timestamp of the last processed HOT swap (not all HOT swaps update AMM state).
    * lastProcessedSignatureTimestamp: Signature timestamp of the last HOT swap which has been successfully processed.
    * alternatingNonceBitmap: Nonce bitmap (see AlternatingNonceBitmap library and docs).
 */
struct HotWriteSlot {
    uint8 lastProcessedBlockQuoteCount;
    uint16 feeGrowthE6Token0;
    uint16 feeMaxToken0;
    uint16 feeMinToken0;
    uint16 feeGrowthE6Token1;
    uint16 feeMaxToken1;
    uint16 feeMinToken1;
    uint32 lastStateUpdateTimestamp;
    uint32 lastProcessedQuoteTimestamp;
    uint32 lastProcessedSignatureTimestamp;
    uint56 alternatingNonceBitmap;
}

/**
    @notice Contains read-only variables required during execution of an HOT swap.
    * isPaused: Indicates whether the contract is paused or not.     
    * maxAllowedQuotes: Maximum number of quotes that can be processed in a single block.
    * maxOracleDeviationBipsLower: Maximum deviation in bips allowed when, sqrtSpotPrice < sqrtOraclePrice
    * maxOracleDeviationBipsUpper: Maximum deviation in bips allowed when, sqrtSpotPrice >= sqrtOraclePrice
    * hotFeeBipsToken0: Fee in basis points for all subsequent hot for token0.
    * hotFeeBipsToken1: Fee in basis points for all subsequent hot for token1.
    * signer: Address of the signer of the HOT.
 */
struct HotReadSlot {
    bool isPaused;
    uint8 maxAllowedQuotes;
    uint16 maxOracleDeviationBipsLower;
    uint16 maxOracleDeviationBipsUpper;
    uint16 hotFeeBipsToken0;
    uint16 hotFeeBipsToken1;
    address signer;
}

/**
    @notice Contains all the arguments passed to the constructor of the HOT.
 */
struct HOTConstructorArgs {
    address pool;
    address manager;
    address signer;
    address liquidityProvider;
    address feedToken0;
    address feedToken1;
    uint160 sqrtSpotPriceX96;
    uint160 sqrtPriceLowX96;
    uint160 sqrtPriceHighX96;
    uint32 maxDelay;
    uint32 maxOracleUpdateDurationFeed0;
    uint32 maxOracleUpdateDurationFeed1;
    uint16 hotMaxDiscountBipsLower;
    uint16 hotMaxDiscountBipsUpper;
    uint16 maxOracleDeviationBound;
    uint16 minAMMFeeGrowthE6;
    uint16 maxAMMFeeGrowthE6;
    uint16 minAMMFee;
}

/**
    @notice Packed struct that contains all variables relevant to the state of the AMM.
    
    * a: sqrtSpotPriceX96
    * b: sqrtPriceLowX96
    * c: sqrtPriceHighX96
        
    This arrangement saves 1 storage slot by packing the variables at the bit level.
    
    @dev Should never be used directly without the help of the TightPack library.

    @dev slot1: << 32 free bits | upper 64 bits of b | all 160 bits of a >>
         slot2: << lower 96 bits of b | all 160 bits of c >>
 */
struct AMMState {
    uint256 slot1;
    uint256 slot2;
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
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IFlashBorrower } from './IFlashBorrower.sol';

interface IValantisPool {
    /************************************************
     *  EVENTS
     ***********************************************/

    event Flashloan(address indexed initiator, address indexed receiver, uint256 amount, address token);

    /************************************************
     *  ERRORS
     ***********************************************/

    error ValantisPool__flashloan_callbackFailed();
    error ValantisPool__flashLoan_flashLoanDisabled();
    error ValantisPool__flashLoan_flashLoanNotRepaid();
    error ValantisPool__flashLoan_rebaseTokenNotAllowed();

    /************************************************
     *  VIEW FUNCTIONS
     ***********************************************/

    /**
        @notice Address of ERC20 token0 of the pool.
     */
    function token0() external view returns (address);

    /**
        @notice Address of ERC20 token1 of the pool.
     */
    function token1() external view returns (address);

    /************************************************
     *  EXTERNAL FUNCTIONS
     ***********************************************/

    /**
        @notice Claim share of protocol fees accrued by this pool.
        @dev Can only be claimed by `gauge` of the pool. 
     */
    function claimProtocolFees() external returns (uint256, uint256);

    /**
        @notice Claim share of fees accrued by this pool
                And optionally share some with the protocol.
        @dev Only callable by `poolManager`.
        @param _feeProtocol0Bips Percent of `token0` fees to be shared with protocol.
        @param _feeProtocol1Bips Percent of `token1` fees to be shared with protocol.
     */
    function claimPoolManagerFees(
        uint256 _feeProtocol0Bips,
        uint256 _feeProtocol1Bips
    ) external returns (uint256 feePoolManager0Received, uint256 feePoolManager1Received);

    /**
        @notice Sets the gauge contract address for the pool.
        @dev Only callable by `protocolFactory`.
        @dev Once a gauge is set it cannot be changed again.
        @param _gauge address of the gauge.
     */
    function setGauge(address _gauge) external;

    /**
        @notice Allows anyone to flash loan any amount of tokens from the pool.
        @param _isTokenZero True if token0 is being flash loaned, False otherwise.
        @param _receiver Address of the flash loan receiver.
        @param _amount Amount of tokens to be flash loaned.
        @param _data Bytes encoded data for flash loan callback.
     */
    function flashLoan(bool _isTokenZero, IFlashBorrower _receiver, uint256 _amount, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

enum Lock {
    WITHDRAWAL,
    DEPOSIT,
    SWAP,
    SPOT_PRICE_TICK
}

struct PoolLocks {
    /**
        @notice Locks all functions that require any withdrawal of funds from the pool
                This involves the following functions -
                * withdrawLiquidity
                * claimProtocolFees
                * claimPoolManagerFees
     */
    uint8 withdrawals;
    /**
        @notice Only locks the deposit function
    */
    uint8 deposit;
    /**
        @notice Only locks the swap function
    */
    uint8 swap;
    /**
        @notice Only locks the spotPriceTick function
    */
    uint8 spotPriceTick;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from '../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import { ISwapFeeModule } from '../../swap-fee-modules/interfaces/ISwapFeeModule.sol';

struct SovereignPoolConstructorArgs {
    address token0;
    address token1;
    address protocolFactory;
    address poolManager;
    address sovereignVault;
    address verifierModule;
    bool isToken0Rebase;
    bool isToken1Rebase;
    uint256 token0AbsErrorTolerance;
    uint256 token1AbsErrorTolerance;
    uint256 defaultSwapFeeBips;
}

struct SovereignPoolSwapContextData {
    bytes externalContext;
    bytes verifierContext;
    bytes swapCallbackContext;
    bytes swapFeeModuleContext;
}

struct SwapCache {
    ISwapFeeModule swapFeeModule;
    IERC20 tokenInPool;
    IERC20 tokenOutPool;
    uint256 amountInWithoutFee;
}

struct SovereignPoolSwapParams {
    bool isSwapCallback;
    bool isZeroToOne;
    uint256 amountIn;
    uint256 amountOutMin;
    uint256 deadline;
    address recipient;
    address swapTokenOut;
    SovereignPoolSwapContextData swapContext;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFlashBorrower {
    /**
        @dev Receive a flash loan.
        @param initiator The initiator of the loan.
        @param token The loan currency.
        @param amount The amount of tokens lent.
        @param data Arbitrary data structure, intended to contain user-defined parameters.
        @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32);
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
pragma solidity 0.8.19;

/**
    @notice Struct returned by the swapFeeModule during the getSwapFeeInBips call.
    * feeInBips: The swap fee in bips.
    * internalContext: Arbitrary bytes context data.
 */
struct SwapFeeModuleData {
    uint256 feeInBips;
    bytes internalContext;
}

interface ISwapFeeModuleMinimal {
    /**
        @notice Returns the swap fee in bips for both Universal & Sovereign Pools.
        @param _tokenIn The address of the token that the user wants to swap.
        @param _tokenOut The address of the token that the user wants to receive.
        @param _amountIn The amount of tokenIn being swapped.
        @param _user The address of the user.
        @param _swapFeeModuleContext Arbitrary bytes data which can be sent to the swap fee module.
        @return swapFeeModuleData A struct containing the swap fee in bips, and internal context data.
     */
    function getSwapFeeInBips(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _user,
        bytes memory _swapFeeModuleContext
    ) external returns (SwapFeeModuleData memory swapFeeModuleData);
}

interface ISwapFeeModule is ISwapFeeModuleMinimal {
    /**
        @notice Callback function called by the pool after the swap has finished. ( Universal Pools )
        @param _effectiveFee The effective fee charged for the swap.
        @param _spotPriceTick The spot price tick after the swap.
        @param _amountInUsed The amount of tokenIn used for the swap.
        @param _amountOut The amount of the tokenOut transferred to the user.
        @param _swapFeeModuleData The context data returned by getSwapFeeInBips.
     */
    function callbackOnSwapEnd(
        uint256 _effectiveFee,
        int24 _spotPriceTick,
        uint256 _amountInUsed,
        uint256 _amountOut,
        SwapFeeModuleData memory _swapFeeModuleData
    ) external;

    /**
        @notice Callback function called by the pool after the swap has finished. ( Sovereign Pools )
        @param _effectiveFee The effective fee charged for the swap.
        @param _amountInUsed The amount of tokenIn used for the swap.
        @param _amountOut The amount of the tokenOut transferred to the user.
        @param _swapFeeModuleData The context data returned by getSwapFeeInBips.
     */
    function callbackOnSwapEnd(
        uint256 _effectiveFee,
        uint256 _amountInUsed,
        uint256 _amountOut,
        SwapFeeModuleData memory _swapFeeModuleData
    ) external;
}