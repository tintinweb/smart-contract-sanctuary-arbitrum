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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IPoolErrors.sol";
import "./IPoolPosition.sol";
import "./IPoolLiquidityPosition.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Perpetual Pool Position Interface
/// @notice This interface defines the functions for managing positions and liquidity positions in a perpetual pool
interface IPool is IPoolLiquidityPosition, IPoolPosition, IPoolErrors {
    struct PriceVertex {
        uint128 size;
        uint128 premiumRateX96;
    }

    struct PriceState {
        uint128 maxPriceImpactLiquidity;
        uint128 premiumRateX96;
        PriceVertex[7] priceVertices;
        uint8 pendingVertexIndex;
        uint8 liquidationVertexIndex;
        uint8 currentVertexIndex;
        uint128[7] liquidationBufferNetSizes;
    }

    /// @notice Emitted when the price vertex is changed
    event PriceVertexChanged(uint8 index, uint128 sizeAfter, uint128 premiumRateAfterX96);

    /// @notice Emitted when the protocol fee is increased
    /// @param amount The increased protocol fee
    event ProtocolFeeIncreased(uint128 amount);

    /// @notice Emitted when the protocol fee is collected
    /// @param amount The collected protocol fee
    event ProtocolFeeCollected(uint128 amount);

    /// @notice Emitted when the referral fee is increased
    /// @param referee The address of the referee
    /// @param referralToken The id of the referral token
    /// @param referralFee The amount of referral fee
    /// @param referralParentToken The id of the referral parent token
    /// @param referralParentFee The amount of referral parent fee
    event ReferralFeeIncreased(
        address indexed referee,
        uint256 indexed referralToken,
        uint128 referralFee,
        uint256 indexed referralParentToken,
        uint128 referralParentFee
    );

    /// @notice Emitted when the referral fee is collected
    /// @param referralToken The id of the referral token
    /// @param receiver The address to receive the referral fee
    /// @param amount The collected referral fee
    event ReferralFeeCollected(uint256 indexed referralToken, address indexed receiver, uint256 amount);

    function token() external view returns (IERC20);

    /// @notice Change the token config
    /// @dev The call will fail if caller is not the pool factory
    function onChangeTokenConfig() external;

    /// @notice Sample and adjust the funding rate
    function sampleAndAdjustFundingRate() external;

    /// @notice Return the price state
    /// @return maxPriceImpactLiquidity The maximum LP liquidity value used to calculate
    /// premium rate when trader increase or decrease positions
    /// @return premiumRateX96 The premium rate during the last position adjustment by the trader, as a Q32.96
    /// @return priceVertices The price vertices used to determine the pricing function
    /// @return pendingVertexIndex The index used to track the pending update of the price vertex
    /// @return liquidationVertexIndex The index used to store the net position of the liquidation
    /// @return currentVertexIndex The index used to track the current used price vertex
    /// @return liquidationBufferNetSizes The net sizes of the liquidation buffer
    function priceState()
        external
        view
        returns (
            uint128 maxPriceImpactLiquidity,
            uint128 premiumRateX96,
            PriceVertex[7] memory priceVertices,
            uint8 pendingVertexIndex,
            uint8 liquidationVertexIndex,
            uint8 currentVertexIndex,
            uint128[7] memory liquidationBufferNetSizes
        );

    /// @notice Get the market price
    /// @param side The side of the position adjustment, 1 for opening long or closing short positions,
    /// 2 for opening short or closing long positions
    /// @return marketPriceX96 The market price, as a Q64.96
    function marketPriceX96(Side side) external view returns (uint160 marketPriceX96);

    /// @notice Change the price vertex
    /// @param startExclusive The start index of the price vertex to be changed, exclusive
    /// @param endInclusive The end index of the price vertex to be changed, inclusive
    function changePriceVertex(uint8 startExclusive, uint8 endInclusive) external;

    /// @notice Return the protocol fee
    function protocolFee() external view returns (uint128);

    /// @notice Collect the protocol fee
    /// @dev This function can be called without authorization
    function collectProtocolFee() external;

    /// @notice Return the referral fee
    /// @param referralToken The id of the referral token
    function referralFees(uint256 referralToken) external view returns (uint256);

    /// @notice Collect the referral fee
    /// @param referralToken The id of the referral token
    /// @param receiver The address to receive the referral fee
    /// @return The collected referral fee
    function collectReferralFee(uint256 referralToken, address receiver) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

interface IPoolErrors {
    /// @notice Liquidity is not enough to open a liquidity position
    error InvalidLiquidityToOpen();
    /// @notice Invalid caller
    error InvalidCaller(address requiredCaller);
    /// @notice Insufficient size to decrease
    error InsufficientSizeToDecrease(uint128 size, uint128 requiredSize);
    /// @notice Insufficient margin
    error InsufficientMargin();
    /// @notice Position not found
    error PositionNotFound(address requiredAccount, Side requiredSide);
    /// @notice Liquidity position not found
    error LiquidityPositionNotFound(uint256 requiredPositionID);
    /// @notice Last liquidity position cannot be closed
    error LastLiquidityPositionCannotBeClosed();
    /// @notice Caller is not the liquidator
    error CallerNotLiquidator();
    /// @notice Insufficient balance
    error InsufficientBalance(uint128 balance, uint128 requiredAmount);
    /// @notice Leverage is too high
    error LeverageTooHigh(uint256 margin, uint128 liquidity, uint32 maxLeverage);
    /// @notice Insufficient global liquidity
    error InsufficientGlobalLiquidity();
    /// @notice Risk rate is too high
    error RiskRateTooHigh(uint256 margin, uint64 liquidationExecutionFee, uint128 positionUnrealizedLoss);
    /// @notice Risk rate is too low
    error RiskRateTooLow(uint256 margin, uint64 liquidationExecutionFee, uint128 positionUnrealizedLoss);
    /// @notice Position margin rate is too low
    error MarginRateTooLow(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
    /// @notice Position margin rate is too high
    error MarginRateTooHigh(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

/// @title Perpetual Pool Liquidity Position Interface
/// @notice This interface defines the functions for managing liquidity positions in a perpetual pool
interface IPoolLiquidityPosition {
    /// @notice Emitted when the unrealized loss metrics of the global liquidity position are changed
    /// @param lastZeroLossTimeAfter The time when the LP's net position no longer has unrealized losses
    /// or the risk buffer fund has enough balance to cover the unrealized losses of all LPs
    /// @param liquidityAfter The total liquidity of all LPs whose entry time is
    /// after `lastZeroLossTime`
    /// @param liquidityTimesUnrealizedLossAfter The product of liquidity and unrealized loss for
    /// each LP whose entry time is after `lastZeroLossTime`
    event GlobalUnrealizedLossMetricsChanged(
        uint64 lastZeroLossTimeAfter,
        uint128 liquidityAfter,
        uint256 liquidityTimesUnrealizedLossAfter
    );

    /// @notice Emitted when an LP opens a liquidity position
    /// @param account The owner of the position
    /// @param positionID The position ID
    /// @param margin The margin of the position
    /// @param liquidity The liquidity of the position
    /// @param entryUnrealizedLoss The snapshot of the unrealized loss of LP at the time of opening the position
    /// @param realizedProfitGrowthX64 The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
    /// at the time of opening the position, as a Q192.64
    event LiquidityPositionOpened(
        address indexed account,
        uint96 positionID,
        uint128 margin,
        uint128 liquidity,
        uint256 entryUnrealizedLoss,
        uint256 realizedProfitGrowthX64
    );

    /// @notice Emitted when an LP closes a liquidity position
    /// @param positionID The position ID
    /// @param margin The margin removed from the position after closing
    /// @param unrealizedLoss The unrealized loss incurred by the position at the time of closing,
    /// which will be transferred to `GlobalLiquidityPosition.riskBufferFund`
    /// @param realizedProfit The realized profit of the position at the time of closing
    /// @param receiver The address that receives the margin upon closing
    event LiquidityPositionClosed(
        uint96 indexed positionID,
        uint128 margin,
        uint128 unrealizedLoss,
        uint256 realizedProfit,
        address receiver
    );

    /// @notice Emitted when the margin of an LP's position is adjusted
    /// @param positionID The position ID
    /// @param marginDelta Change in margin, positive for increase and negative for decrease
    /// @param marginAfter Adjusted margin
    /// @param entryRealizedProfitGrowthAfterX64 The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
    ///  after adjustment, as a Q192.64
    /// @param receiver The address that receives the margin when it is decreased
    event LiquidityPositionMarginAdjusted(
        uint96 indexed positionID,
        int128 marginDelta,
        uint128 marginAfter,
        uint256 entryRealizedProfitGrowthAfterX64,
        address receiver
    );

    /// @notice Emitted when an LP's position is liquidated
    /// @param liquidator The address that executes the liquidation of the position
    /// @param positionID The position ID to be liquidated
    /// @param realizedProfit The realized profit of the position at the time of liquidation
    /// @param riskBufferFundDelta The remaining margin of the position after liquidation,
    /// which will be transferred to `GlobalLiquidityPosition.riskBufferFund`
    /// @param liquidationExecutionFee The liquidation execution fee paid by the position
    /// @param feeReceiver The address that receives the liquidation execution fee
    event LiquidityPositionLiquidated(
        address indexed liquidator,
        uint96 indexed positionID,
        uint256 realizedProfit,
        uint256 riskBufferFundDelta,
        uint64 liquidationExecutionFee,
        address feeReceiver
    );

    /// @notice Emitted when the net position of all LP's is adjusted
    /// @param netSizeAfter The adjusted net position size
    /// @param liquidationBufferNetSizeAfter The adjusted net position size in the liquidation buffer
    /// @param entryPriceAfterX96 The adjusted entry price, as a Q64.96
    /// @param sideAfter The adjusted side of the net position
    event GlobalLiquidityPositionNetPositionAdjusted(
        uint128 netSizeAfter,
        uint128 liquidationBufferNetSizeAfter,
        uint160 entryPriceAfterX96,
        Side sideAfter
    );

    /// @notice Emitted when the `realizedProfitGrowthX64` of the global liquidity position is changed
    /// @param realizedProfitGrowthAfterX64 The adjusted `realizedProfitGrowthX64`, as a Q192.64
    event GlobalLiquidityPositionRealizedProfitGrowthChanged(uint256 realizedProfitGrowthAfterX64);

    /// @notice Emitted when the risk buffer fund is used by `Gov`
    /// @param receiver The address that receives the risk buffer fund
    /// @param riskBufferFundDelta The amount of risk buffer fund used
    event GlobalRiskBufferFundGovUsed(address indexed receiver, uint128 riskBufferFundDelta);

    /// @notice Emitted when the risk buffer fund is changed
    event GlobalRiskBufferFundChanged(int256 riskBufferFundAfter);

    /// @notice Emitted when the liquidity of the risk buffer fund is increased
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the increase
    /// @param unlockTimeAfter The unlock time of the position after the increase
    event RiskBufferFundPositionIncreased(address indexed account, uint128 liquidityAfter, uint64 unlockTimeAfter);

    /// @notice Emitted when the liquidity of the risk buffer fund is decreased
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the decrease
    /// @param receiver The address that receives the liquidity when it is decreased
    event RiskBufferFundPositionDecreased(address indexed account, uint128 liquidityAfter, address receiver);

    struct GlobalLiquidityPosition {
        uint128 netSize;
        uint128 liquidationBufferNetSize;
        uint160 entryPriceX96;
        Side side;
        uint128 liquidity;
        uint256 realizedProfitGrowthX64;
    }

    struct GlobalRiskBufferFund {
        int256 riskBufferFund;
        uint256 liquidity;
    }

    struct GlobalUnrealizedLossMetrics {
        uint64 lastZeroLossTime;
        uint128 liquidity;
        uint256 liquidityTimesUnrealizedLoss;
    }

    struct LiquidityPosition {
        uint128 margin;
        uint128 liquidity;
        uint256 entryUnrealizedLoss;
        uint256 entryRealizedProfitGrowthX64;
        uint64 entryTime;
        address account;
    }

    struct RiskBufferFundPosition {
        uint128 liquidity;
        uint64 unlockTime;
    }

    /// @notice Get the global liquidity position
    /// @return netSize The size of the net position held by all LPs
    /// @return liquidationBufferNetSize The size of the net position held by all LPs in the liquidation buffer
    /// @return entryPriceX96 The entry price of the net position held by all LPs, as a Q64.96
    /// @return side The side of the position (Long or Short)
    /// @return liquidity The total liquidity of all LPs
    /// @return realizedProfitGrowthX64 The accumulated realized profit growth per liquidity unit, as a Q192.64
    function globalLiquidityPosition()
        external
        view
        returns (
            uint128 netSize,
            uint128 liquidationBufferNetSize,
            uint160 entryPriceX96,
            Side side,
            uint128 liquidity,
            uint256 realizedProfitGrowthX64
        );

    /// @notice Get the global unrealized loss metrics
    /// @return lastZeroLossTime The time when the LP's net position no longer has unrealized losses
    /// or the risk buffer fund has enough balance to cover the unrealized losses of all LPs
    /// @return liquidity The total liquidity of all LPs whose entry time is
    /// after `lastZeroLossTime`
    /// @return liquidityTimesUnrealizedLoss The product of liquidity and unrealized loss for
    /// each LP whose entry time is after `lastZeroLossTime`
    function globalUnrealizedLossMetrics()
        external
        view
        returns (uint64 lastZeroLossTime, uint128 liquidity, uint256 liquidityTimesUnrealizedLoss);

    /// @notice Get the information of a liquidity position
    /// @param positionID The position ID
    /// @return margin The margin of the position
    /// @return liquidity The liquidity (value) of the position
    /// @return entryUnrealizedLoss The snapshot of unrealized loss of LP at the time of opening the position
    /// @return entryRealizedProfitGrowthX64 The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
    /// at the time of opening the position, as a Q192.64
    /// @return entryTime The time when the position is opened
    /// @return account The owner of the position
    function liquidityPositions(
        uint96 positionID
    )
        external
        view
        returns (
            uint128 margin,
            uint128 liquidity,
            uint256 entryUnrealizedLoss,
            uint256 entryRealizedProfitGrowthX64,
            uint64 entryTime,
            address account
        );

    /// @notice Get the owner of a specific liquidity position
    /// @param positionID The position ID
    /// @return account The owner of the position, `address(0)` returned if the position does not exist
    function liquidityPositionAccount(uint96 positionID) external view returns (address account);

    /// @notice Open a new liquidity position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param account The owner of the position
    /// @param margin The margin of the position
    /// @param liquidity The liquidity (value) of the position
    /// @return positionID The position ID
    function openLiquidityPosition(
        address account,
        uint128 margin,
        uint128 liquidity
    ) external returns (uint96 positionID);

    /// @notice Close a liquidity position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param positionID The position ID
    /// @param receiver The address to receive the margin at the time of closing
    function closeLiquidityPosition(uint96 positionID, address receiver) external;

    /// @notice Adjust the margin of a liquidity position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param positionID The position ID
    /// @param marginDelta The change in margin, positive for increasing margin and negative for decreasing margin
    /// @param receiver The address to receive the margin when the margin is decreased
    function adjustLiquidityPositionMargin(uint96 positionID, int128 marginDelta, address receiver) external;

    /// @notice Liquidate a liquidity position
    /// @dev The call will fail if the caller is not the liquidator or the position does not exist
    /// @param positionID The position ID
    /// @param feeReceiver The address to receive the liquidation execution fee
    function liquidateLiquidityPosition(uint96 positionID, address feeReceiver) external;

    /// @notice `Gov` uses the risk buffer fund
    /// @dev The call will fail if the caller is not the `Gov` or
    /// the adjusted remaining risk buffer fund cannot cover the unrealized loss
    /// @param receiver The address to receive the risk buffer fund
    /// @param riskBufferFundDelta The used risk buffer fund
    function govUseRiskBufferFund(address receiver, uint128 riskBufferFundDelta) external;

    /// @notice Get the global risk buffer fund
    /// @return riskBufferFund The risk buffer fund, which accumulated by unrealized losses and price impact fees
    /// paid by LPs when positions are closed or liquidated. It also accumulates the remaining margin of LPs
    /// after liquidation. Additionally, the net profit or loss from closing LP's net position is also accumulated
    /// in the risk buffer fund
    /// @return liquidity The total liquidity of the risk buffer fund
    function globalRiskBufferFund() external view returns (int256 riskBufferFund, uint256 liquidity);

    /// @notice Get the liquidity of the risk buffer fund
    /// @param account The owner of the position
    /// @return liquidity The liquidity of the risk buffer fund
    /// @return unlockTime The time when the liquidity can be withdrawn
    function riskBufferFundPositions(address account) external view returns (uint128 liquidity, uint64 unlockTime);

    /// @notice Increase the liquidity of a risk buffer fund position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param account The owner of the position
    /// @param liquidityDelta The increase in liquidity
    function increaseRiskBufferFundPosition(address account, uint128 liquidityDelta) external;

    /// @notice Decrease the liquidity of a risk buffer fund position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param account The owner of the position
    /// @param liquidityDelta The decrease in liquidity
    /// @param receiver The address to receive the liquidity when it is decreased
    function decreaseRiskBufferFundPosition(address account, uint128 liquidityDelta, address receiver) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

/// @title Perpetual Pool Position Interface
/// @notice This interface defines the functions for managing positions in a perpetual pool
interface IPoolPosition {
    /// @notice Emitted when the funding rate growth is adjusted
    /// @param fundingRateDeltaX96 The change in funding rate, a positive value means longs pay shorts,
    /// when a negative value means shorts pay longs, as a Q160.96
    /// @param longFundingRateGrowthAfterX96 The adjusted `GlobalPosition.longFundingRateGrowthX96`, as a Q96.96
    /// @param shortFundingRateGrowthAfterX96 The adjusted `GlobalPosition.shortFundingRateGrowthX96`, as a Q96.96
    /// @param lastAdjustFundingRateTime The adjusted `GlobalFundingRateSample.lastAdjustFundingRateTime`
    event FundingRateGrowthAdjusted(
        int256 fundingRateDeltaX96,
        int192 longFundingRateGrowthAfterX96,
        int192 shortFundingRateGrowthAfterX96,
        uint64 lastAdjustFundingRateTime
    );

    /// @notice Emitted when the position margin/liquidity (value) is increased
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    /// @param entryPriceAfterX96 The adjusted entry price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives funding fee,
    /// while a negative value means the position positive pays funding fee
    /// @param tradingFee The trading fee paid by the position
    event PositionIncreased(
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        uint160 entryPriceAfterX96,
        int256 fundingFee,
        uint128 tradingFee
    );

    /// @notice Emitted when the position margin/liquidity (value) is decreased
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decreased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    /// @param realizedPnLDelta The realized PnL
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param tradingFee The trading fee paid by the position
    /// @param receiver The address that receives the margin
    event PositionDecreased(
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        int256 realizedPnLDelta,
        int256 fundingFee,
        uint128 tradingFee,
        address receiver
    );

    /// @notice Emitted when a position is liquidated
    /// @param liquidator The address that executes the liquidation of the position
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param indexPriceX96 The index price when liquidating the position, as a Q64.96
    /// @param liquidationPriceX96 The liquidation price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee. If it's negative,
    /// it represents the actual funding fee paid during liquidation
    /// @param tradingFee The trading fee paid by the position
    /// @param liquidationFee The liquidation fee paid by the position
    /// @param liquidationExecutionFee The liquidation execution fee paid by the position
    /// @param feeReceiver The address that receives the liquidation execution fee
    event PositionLiquidated(
        address indexed liquidator,
        address indexed account,
        Side side,
        uint160 indexPriceX96,
        uint160 liquidationPriceX96,
        int256 fundingFee,
        uint128 tradingFee,
        uint128 liquidationFee,
        uint64 liquidationExecutionFee,
        address feeReceiver
    );

    struct GlobalPosition {
        uint128 longSize;
        uint128 shortSize;
        int192 longFundingRateGrowthX96;
        int192 shortFundingRateGrowthX96;
    }

    struct PreviousGlobalFundingRate {
        int192 longFundingRateGrowthX96;
        int192 shortFundingRateGrowthX96;
    }

    struct GlobalFundingRateSample {
        uint64 lastAdjustFundingRateTime;
        uint16 sampleCount;
        int176 cumulativePremiumRateX96;
    }

    struct Position {
        uint128 margin;
        uint128 size;
        uint160 entryPriceX96;
        int192 entryFundingRateGrowthX96;
    }

    /// @notice Get the global position
    /// @return longSize The sum of long position sizes
    /// @return shortSize The sum of short position sizes
    /// @return longFundingRateGrowthX96 The funding rate growth per unit of long position sizes, as a Q96.96
    /// @return shortFundingRateGrowthX96 The funding rate growth per unit of short position sizes, as a Q96.96
    function globalPosition()
        external
        view
        returns (
            uint128 longSize,
            uint128 shortSize,
            int192 longFundingRateGrowthX96,
            int192 shortFundingRateGrowthX96
        );

    /// @notice Get the previous global funding rate growth
    /// @return longFundingRateGrowthX96 The funding rate growth per unit of long position sizes, as a Q96.96
    /// @return shortFundingRateGrowthX96 The funding rate growth per unit of short position sizes, as a Q96.96
    function previousGlobalFundingRate()
        external
        view
        returns (int192 longFundingRateGrowthX96, int192 shortFundingRateGrowthX96);

    /// @notice Get the global funding rate sample
    /// @return lastAdjustFundingRateTime The timestamp of the last funding rate adjustment
    /// @return sampleCount The number of samples taken since the last funding rate adjustment
    /// @return cumulativePremiumRateX96 The cumulative premium rate of the samples taken
    /// since the last funding rate adjustment, as a Q80.96
    function globalFundingRateSample()
        external
        view
        returns (uint64 lastAdjustFundingRateTime, uint16 sampleCount, int176 cumulativePremiumRateX96);

    /// @notice Get the information of a position
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @return margin The margin of the position
    /// @return size The size of the position
    /// @return entryPriceX96 The entry price of the position, as a Q64.96
    /// @return entryFundingRateGrowthX96 The snapshot of the funding rate growth at the time the position was opened.
    /// For long positions it is `GlobalPosition.longFundingRateGrowthX96`,
    /// and for short positions it is `GlobalPosition.shortFundingRateGrowthX96`
    function positions(
        address account,
        Side side
    ) external view returns (uint128 margin, uint128 size, uint160 entryPriceX96, int192 entryFundingRateGrowthX96);

    /// @notice Increase the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increase in margin, which can be 0
    /// @param sizeDelta The increase in size, which can be 0
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    function increasePosition(
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta
    ) external returns (uint160 tradePriceX96);

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decrease in margin, which can be 0
    /// @param sizeDelta The decrease in size, which can be 0
    /// @param receiver The address to receive the margin
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    function decreasePosition(
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta,
        address receiver
    ) external returns (uint160 tradePriceX96);

    /// @notice Liquidate a position
    /// @dev The call will fail if the caller is not the liquidator or the position does not exist
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param feeReceiver The address that receives the liquidation execution fee
    function liquidatePosition(address account, Side side, address feeReceiver) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Constants {
    uint32 internal constant BASIS_POINTS_DIVISOR = 100_000_000;

    uint16 internal constant ADJUST_FUNDING_RATE_INTERVAL = 1 hours;
    uint16 internal constant SAMPLE_PREMIUM_RATE_INTERVAL = 5 seconds;
    uint16 internal constant REQUIRED_SAMPLE_COUNT = ADJUST_FUNDING_RATE_INTERVAL / SAMPLE_PREMIUM_RATE_INTERVAL;
    /// @dev 8 * (1+2+3+...+720) = 8 * ((1+720) * 720 / 2) = 8 * 259560
    uint32 internal constant PREMIUM_RATE_AVG_DENOMINATOR = 8 * 259560;
    /// @dev RoundingUp(50000 / 8 * Q96 / BASIS_POINTS_DIVISOR) = 4951760157141521099596497
    int256 internal constant PREMIUM_RATE_CLAMP_BOUNDARY_X96 = 4951760157141521099596497; // 0.05% / 8

    uint8 internal constant VERTEX_NUM = 7;
    uint8 internal constant LATEST_VERTEX = VERTEX_NUM - 1;

    uint64 internal constant RISK_BUFFER_FUND_LOCK_PERIOD = 90 days;

    uint256 internal constant Q64 = 1 << 64;
    uint256 internal constant Q96 = 1 << 96;

    bytes32 internal constant ROLE_POSITION_LIQUIDATOR = keccak256("ROLE_POSITION_LIQUIDATOR");
    bytes32 internal constant ROLE_LIQUIDITY_POSITION_LIQUIDATOR = keccak256("ROLE_LIQUIDITY_POSITION_LIQUIDATOR");
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Math as _math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Math library
/// @dev Derived from OpenZeppelin's Math library. To avoid conflicts with OpenZeppelin's Math,
/// it has been renamed to `M` here. Import it using the following statement:
///      import {M as Math} from "path/to/Math.sol";
library M {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Calculate `a / b` with rounding up
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // Guarantee the same behavior as in a regular Solidity division
        if (b == 0) return a / b;

        // prettier-ignore
        unchecked { return a == 0 ? 0 : (a - 1) / b + 1; }
    }

    /// @notice Calculate `x * y / denominator` with rounding down
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator);
    }

    /// @notice Calculate `x * y / denominator` with rounding up
    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator, _math.Rounding.Up);
    }

    /// @notice Calculate `x * y / denominator` with rounding down and up
    /// @return result Result with rounding down
    /// @return resultUp Result with rounding up
    function mulDiv2(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result, uint256 resultUp) {
        result = _math.mulDiv(x, y, denominator);
        resultUp = result;
        if (mulmod(x, y, denominator) > 0) resultUp += 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {M as Math} from "./Math.sol";
import "./Constants.sol";
import "./SafeCast.sol";
import "../core/interfaces/IPool.sol";
import {Side} from "../types/Side.sol";

/// @notice Utility library for trader positions
library PositionUtil {
    using SafeCast for *;

    /// @notice Calculate the next entry price of a position
    /// @param _side The side of the position (Long or Short)
    /// @param _sizeBefore The size of the position before the trade
    /// @param _entryPriceBeforeX96 The entry price of the position before the trade, as a Q64.96
    /// @param _sizeDelta The size of the trade
    /// @param _tradePriceX96 The price of the trade, as a Q64.96
    /// @return nextEntryPriceX96 The entry price of the position after the trade, as a Q64.96
    function calculateNextEntryPriceX96(
        Side _side,
        uint128 _sizeBefore,
        uint160 _entryPriceBeforeX96,
        uint128 _sizeDelta,
        uint160 _tradePriceX96
    ) internal pure returns (uint160 nextEntryPriceX96) {
        if ((_sizeBefore | _sizeDelta) == 0) nextEntryPriceX96 = 0;
        else if (_sizeBefore == 0) nextEntryPriceX96 = _tradePriceX96;
        else if (_sizeDelta == 0) nextEntryPriceX96 = _entryPriceBeforeX96;
        else {
            uint256 liquidityAfterX96 = uint256(_sizeBefore) * _entryPriceBeforeX96;
            liquidityAfterX96 += uint256(_sizeDelta) * _tradePriceX96;
            unchecked {
                uint256 sizeAfter = uint256(_sizeBefore) + _sizeDelta;
                nextEntryPriceX96 = (
                    _side.isLong() ? Math.ceilDiv(liquidityAfterX96, sizeAfter) : liquidityAfterX96 / sizeAfter
                ).toUint160();
            }
        }
    }

    /// @notice Calculate the liquidity (value) of a position
    /// @param _size The size of the position
    /// @param _priceX96 The trade price, as a Q64.96
    /// @return liquidity The liquidity (value) of the position
    function calculateLiquidity(uint128 _size, uint160 _priceX96) internal pure returns (uint128 liquidity) {
        liquidity = Math.mulDivUp(_size, _priceX96, Constants.Q96).toUint128();
    }

    /// @dev Calculate the unrealized PnL of a position based on entry price
    /// @param _side The side of the position (Long or Short)
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _priceX96 The trade price or index price, as a Q64.96
    /// @return unrealizedPnL The unrealized PnL of the position, positive value means profit,
    /// negative value means loss
    function calculateUnrealizedPnL(
        Side _side,
        uint128 _size,
        uint160 _entryPriceX96,
        uint160 _priceX96
    ) internal pure returns (int256 unrealizedPnL) {
        unchecked {
            // Because the maximum value of size is type(uint128).max, and the maximum value of entryPriceX96 and
            // priceX96 is type(uint160).max, so the maximum value of
            //      size * (entryPriceX96 - priceX96) / Q96
            // is type(uint192).max, so it is safe to convert the type to int256.
            if (_side.isLong()) {
                if (_entryPriceX96 > _priceX96)
                    unrealizedPnL = -int256(Math.mulDivUp(_size, _entryPriceX96 - _priceX96, Constants.Q96));
                else unrealizedPnL = int256(Math.mulDiv(_size, _priceX96 - _entryPriceX96, Constants.Q96));
            } else {
                if (_entryPriceX96 < _priceX96)
                    unrealizedPnL = -int256(Math.mulDivUp(_size, _priceX96 - _entryPriceX96, Constants.Q96));
                else unrealizedPnL = int256(Math.mulDiv(_size, _entryPriceX96 - _priceX96, Constants.Q96));
            }
        }
    }

    function chooseFundingRateGrowthX96(
        IPoolPosition.GlobalPosition storage _globalPosition,
        Side _side
    ) internal view returns (int192) {
        return _side.isLong() ? _globalPosition.longFundingRateGrowthX96 : _globalPosition.shortFundingRateGrowthX96;
    }

    /// @notice Calculate the trading fee of a trade
    /// @param _size The size of the trade
    /// @param _tradePriceX96 The price of the trade, as a Q64.96
    /// @param _tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    function calculateTradingFee(
        uint128 _size,
        uint160 _tradePriceX96,
        uint32 _tradingFeeRate
    ) internal pure returns (uint128 tradingFee) {
        unchecked {
            uint256 denominator = Constants.BASIS_POINTS_DIVISOR * Constants.Q96;
            tradingFee = Math.mulDivUp(uint256(_size) * _tradingFeeRate, _tradePriceX96, denominator).toUint128();
        }
    }

    /// @notice Calculate the liquidation fee of a position
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @return liquidationFee The liquidation fee of the position
    function calculateLiquidationFee(
        uint128 _size,
        uint160 _entryPriceX96,
        uint32 _liquidationFeeRate
    ) internal pure returns (uint128 liquidationFee) {
        unchecked {
            uint256 denominator = Constants.BASIS_POINTS_DIVISOR * Constants.Q96;
            liquidationFee = Math
                .mulDivUp(uint256(_size) * _liquidationFeeRate, _entryPriceX96, denominator)
                .toUint128();
        }
    }

    /// @notice Calculate the funding fee of a position
    /// @param _globalFundingRateGrowthX96 The global funding rate growth, as a Q96.96
    /// @param _positionFundingRateGrowthX96 The position funding rate growth, as a Q96.96
    /// @param _positionSize The size of the position
    /// @return fundingFee The funding fee of the position, a positive value means the position receives
    /// funding fee, while a negative value means the position pays funding fee
    function calculateFundingFee(
        int192 _globalFundingRateGrowthX96,
        int192 _positionFundingRateGrowthX96,
        uint128 _positionSize
    ) internal pure returns (int256 fundingFee) {
        int256 deltaX96 = _globalFundingRateGrowthX96 - _positionFundingRateGrowthX96;
        if (deltaX96 >= 0) fundingFee = Math.mulDiv(uint256(deltaX96), _positionSize, Constants.Q96).toInt256();
        else fundingFee = -Math.mulDivUp(uint256(-deltaX96), _positionSize, Constants.Q96).toInt256();
    }

    /// @notice Calculate the maintenance margin
    /// @dev maintenanceMargin = size * (entryPrice * liquidationFeeRate
    ///                          + indexPrice * tradingFeeRate)
    ///                          + liquidationExecutionFee
    /// @param _size The size of the position
    /// @param _entryPriceX96 The entry price of the position, as a Q64.96
    /// @param _indexPriceX96 The index price, as a Q64.96
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @return maintenanceMargin The maintenance margin
    function calculateMaintenanceMargin(
        uint128 _size,
        uint160 _entryPriceX96,
        uint160 _indexPriceX96,
        uint32 _liquidationFeeRate,
        uint32 _tradingFeeRate,
        uint64 _liquidationExecutionFee
    ) internal pure returns (uint256 maintenanceMargin) {
        unchecked {
            maintenanceMargin = Math.mulDivUp(
                _size,
                uint256(_entryPriceX96) * _liquidationFeeRate + uint256(_indexPriceX96) * _tradingFeeRate,
                Constants.BASIS_POINTS_DIVISOR * Constants.Q96
            );
            // Because the maximum value of size is type(uint128).max, and the maximum value of entryPriceX96 and
            // indexPriceX96 is type(uint160).max, and liquidationFeeRate + tradingFeeRate is at most 2 * DIVISOR,
            // so the maximum value of
            //      size * (entryPriceX96 * liquidationFeeRate + indexPriceX96 * tradingFeeRate) / (Q96 * DIVISOR)
            // is type(uint193).max, so there will be no overflow here.
            maintenanceMargin += _liquidationExecutionFee;
        }
    }

    /// @notice calculate the liquidation price
    /// @param _positionCache The cache of position
    /// @param _side The side of the position (Long or Short)
    /// @param _fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @return liquidationPriceX96 The liquidation price of the position, as a Q64.96
    /// @return adjustedFundingFee The liquidation price based on the funding fee. If `_fundingFee` is negative,
    /// then this value is not less than `_fundingFee`
    function calculateLiquidationPriceX96(
        IPool.Position memory _positionCache,
        IPool.PreviousGlobalFundingRate storage _previousGlobalFundingRate,
        Side _side,
        int256 _fundingFee,
        uint32 _liquidationFeeRate,
        uint32 _tradingFeeRate,
        uint64 _liquidationExecutionFee
    ) public view returns (uint160 liquidationPriceX96, int256 adjustedFundingFee) {
        int256 marginInt256 = int256(uint256(_positionCache.margin));
        if ((marginInt256 + _fundingFee) > 0) {
            liquidationPriceX96 = _calculateLiquidationPriceX96(
                _positionCache,
                _side,
                _fundingFee,
                _liquidationFeeRate,
                _tradingFeeRate,
                _liquidationExecutionFee
            );
            if (_isAcceptableLiquidationPriceX96(_side, liquidationPriceX96, _positionCache.entryPriceX96))
                return (liquidationPriceX96, _fundingFee);
        }
        // Try to use the previous funding rate to calculate the funding fee
        adjustedFundingFee = calculateFundingFee(
            _choosePreviousGlobalFundingRateGrowthX96(_previousGlobalFundingRate, _side),
            _positionCache.entryFundingRateGrowthX96,
            _positionCache.size
        );
        if (adjustedFundingFee > _fundingFee && (marginInt256 + adjustedFundingFee) > 0) {
            liquidationPriceX96 = _calculateLiquidationPriceX96(
                _positionCache,
                _side,
                adjustedFundingFee,
                _liquidationFeeRate,
                _tradingFeeRate,
                _liquidationExecutionFee
            );
            if (_isAcceptableLiquidationPriceX96(_side, liquidationPriceX96, _positionCache.entryPriceX96))
                return (liquidationPriceX96, adjustedFundingFee);
        } else adjustedFundingFee = _fundingFee;

        // Only try to use zero funding fee calculation when the current best funding fee is negative,
        // then zero funding fee is the best
        if (adjustedFundingFee < 0) {
            adjustedFundingFee = 0;
            liquidationPriceX96 = _calculateLiquidationPriceX96(
                _positionCache,
                _side,
                adjustedFundingFee,
                _liquidationFeeRate,
                _tradingFeeRate,
                _liquidationExecutionFee
            );
        }
    }

    function _choosePreviousGlobalFundingRateGrowthX96(
        IPool.PreviousGlobalFundingRate storage _pgrf,
        Side _side
    ) private view returns (int192) {
        return _side.isLong() ? _pgrf.longFundingRateGrowthX96 : _pgrf.shortFundingRateGrowthX96;
    }

    function _isAcceptableLiquidationPriceX96(
        Side _side,
        uint160 _liquidationPriceX96,
        uint160 _entryPriceX96
    ) private pure returns (bool) {
        return
            (_side.isLong() && _liquidationPriceX96 < _entryPriceX96) ||
            (_side.isShort() && _liquidationPriceX96 > _entryPriceX96);
    }

    /// @notice Calculate the liquidation price
    /// @dev Given the liquidation condition as:
    /// For long position: margin + fundingFee - positionSize * (entryPrice - liquidationPrice)
    ///                     = entryPrice * positionSize * liquidationFeeRate
    ///                         + liquidationPrice * positionSize * tradingFeeRate + liquidationExecutionFee
    /// For short position: margin + fundingFee - positionSize * (liquidationPrice - entryPrice)
    ///                     = entryPrice * positionSize * liquidationFeeRate
    ///                         + liquidationPrice * positionSize * tradingFeeRate + liquidationExecutionFee
    /// We can get:
    /// Long position liquidation price:
    ///     liquidationPrice
    ///       = [margin + fundingFee - liquidationExecutionFee - entryPrice * positionSize * (1 + liquidationFeeRate)]
    ///       / [positionSize * (tradingFeeRate - 1)]
    /// Short position liquidation price:
    ///     liquidationPrice
    ///       = [margin + fundingFee - liquidationExecutionFee + entryPrice * positionSize * (1 - liquidationFeeRate)]
    ///       / [positionSize * (tradingFeeRate + 1)]
    /// @param _positionCache The cache of position
    /// @param _side The side of the position (Long or Short)
    /// @param _fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param _liquidationFeeRate The liquidation fee rate for trader positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _tradingFeeRate The trading fee rate for trader increase or decrease positions,
    /// denominated in ten thousandths of a bip (i.e. 1e-8)
    /// @param _liquidationExecutionFee The liquidation execution fee paid by the position
    /// @return liquidationPriceX96 The liquidation price of the position, as a Q64.96
    function _calculateLiquidationPriceX96(
        IPool.Position memory _positionCache,
        Side _side,
        int256 _fundingFee,
        uint32 _liquidationFeeRate,
        uint32 _tradingFeeRate,
        uint64 _liquidationExecutionFee
    ) private pure returns (uint160 liquidationPriceX96) {
        uint256 marginAfter = uint256(_positionCache.margin);
        if (_fundingFee >= 0) marginAfter += uint256(_fundingFee);
        else marginAfter -= uint256(-_fundingFee);

        (uint256 numeratorX96, uint256 denominator) = _side.isLong()
            ? (Constants.BASIS_POINTS_DIVISOR + _liquidationFeeRate, Constants.BASIS_POINTS_DIVISOR - _tradingFeeRate)
            : (Constants.BASIS_POINTS_DIVISOR - _liquidationFeeRate, Constants.BASIS_POINTS_DIVISOR + _tradingFeeRate);

        uint256 numeratorPart2X96 = marginAfter >= _liquidationExecutionFee
            ? marginAfter - _liquidationExecutionFee
            : _liquidationExecutionFee - marginAfter;

        numeratorX96 *= uint256(_positionCache.entryPriceX96) * _positionCache.size;
        denominator *= _positionCache.size;
        numeratorPart2X96 *= Constants.BASIS_POINTS_DIVISOR * Constants.Q96;

        if (_side.isLong()) {
            numeratorX96 = marginAfter >= _liquidationExecutionFee
                ? numeratorX96 - numeratorPart2X96
                : numeratorX96 + numeratorPart2X96;
        } else {
            numeratorX96 = marginAfter >= _liquidationExecutionFee
                ? numeratorX96 + numeratorPart2X96
                : numeratorX96 - numeratorPart2X96;
        }
        liquidationPriceX96 = _side.isLong()
            ? (numeratorX96 / denominator).toUint160()
            : Math.ceilDiv(numeratorX96, denominator).toUint160();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.19;

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
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

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
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
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
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
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
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
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
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
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
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
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
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
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
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
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
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
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
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
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
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
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
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
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
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
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
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
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
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

Side constant LONG = Side.wrap(1);
Side constant SHORT = Side.wrap(2);

type Side is uint8;

error InvalidSide(Side side);

using {requireValid, isLong, isShort, flip, eq as ==} for Side global;

function requireValid(Side self) pure {
    if (!isLong(self) && !isShort(self)) revert InvalidSide(self);
}

function isLong(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(LONG);
}

function isShort(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(SHORT);
}

function eq(Side self, Side other) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(other);
}

function flip(Side self) pure returns (Side) {
    return isLong(self) ? SHORT : LONG;
}