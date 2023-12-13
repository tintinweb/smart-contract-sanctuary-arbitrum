// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {MAX_RATE, ONE} from "./libraries/constants/Constants.sol";

interface IRateModel {
    /**
     * @notice Specifies the percentage yield per second for a `lender`. Need not be a pure function
     * of `utilization`. To convert to APY: `(1 + returnValue / 1e12) ** secondsPerYear - 1`
     * @param utilization The `lender`'s total borrows divided by total assets, scaled up by 1e18
     * @param lender The `Lender` to examine
     * @return The percentage yield per second, scaled up by 1e12
     */
    function getYieldPerSecond(uint256 utilization, address lender) external view returns (uint256);
}

/// @title RateModel
/// @author Aloe Labs, Inc.
/// @dev "Test everything; hold fast what is good." - 1 Thessalonians 5:21
contract RateModel is IRateModel {
    uint256 private constant _A = 6.1010463348e20;

    uint256 private constant _B = _A / 1e18;

    /// @inheritdoc IRateModel
    function getYieldPerSecond(uint256 utilization, address) external pure returns (uint256) {
        unchecked {
            return (utilization < 0.99e18) ? _A / (1e18 - utilization) - _B : 60400;
        }
    }
}

library SafeRateLib {
    using FixedPointMathLib for uint256;

    function getAccrualFactor(IRateModel rateModel, uint256 utilization, uint256 dt) internal view returns (uint256) {
        uint256 rate;

        // Essentially `rate = rateModel.getYieldPerSecond(utilization, address(this)) ?? 0`, i.e. if the call
        // fails, we set `rate = 0` instead of reverting. Solidity's try/catch could accomplish the same thing,
        // but this is slightly more gas efficient.
        bytes memory encodedCall = abi.encodeCall(IRateModel.getYieldPerSecond, (utilization, address(this)));
        assembly ("memory-safe") {
            let success := staticcall(100000, rateModel, add(encodedCall, 32), mload(encodedCall), 0, 32)
            rate := mul(success, mload(0))
        }

        return _computeAccrualFactor(rate, dt);
    }

    function _computeAccrualFactor(uint256 rate, uint256 dt) private pure returns (uint256) {
        if (rate > MAX_RATE) rate = MAX_RATE;
        if (dt > 1 weeks) dt = 1 weeks;

        unchecked {
            return (ONE + rate).rpow(dt, ONE);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

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
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @dev The initial value of `Lender`'s `borrowIndex`
uint256 constant ONE = 1e12;

/// @dev An additional scaling factor applied to borrowed amounts before dividing by `borrowIndex` and storing.
/// 72 matches the type of `borrowIndex` in `Ledger` to guarantee that the stored borrow units fit in uint256.
uint256 constant BORROWS_SCALER = ONE << 72;

/// @dev The maximum percentage yield per second, scaled up by 1e12. The current value is equivalent to
/// `((1 + 706354 / 1e12) ** (24 * 60 * 60)) - 1` ⇒ +6.3% per day or +53% per week. If the rate is consistently at
/// this maximum value, the `Lender` will function for 1 year before `borrowIndex` overflows.
/// @custom:math
/// > 📘 Useful Math
/// >
/// > - T: number of years before overflow, assuming maximum rate
/// > - borrowIndexInit: `ONE`
/// > - borrowIndexMax: 2^72 - 1
/// >
/// > - maxAPR: ln(borrowIndexMax / borrowIndexInit) / T
/// > - maxAPY: exp(maxAPR) - 1
/// > - MAX_RATE: (exp(maxAPR / secondsPerYear) - 1) * 1e12
uint256 constant MAX_RATE = 706354;

/*//////////////////////////////////////////////////////////////
                        FACTORY DEFAULTS
//////////////////////////////////////////////////////////////*/

/// @dev The default amount of Ether required to take on debt in a `Borrower`. The `Factory` can override this value
/// on a per-market basis. Incentivizes calls to `Borrower.warn`.
uint208 constant DEFAULT_ANTE = 0.01 ether;

/// @dev The default number of standard deviations of price movement used to determine probe prices for `Borrower`
/// solvency. The `Factory` can override this value on a per-market basis. Expressed x10, e.g. 50 → 5σ
uint8 constant DEFAULT_N_SIGMA = 50;

/// @dev Assume someone is manipulating the Uniswap TWAP oracle. To steal money from the protocol and create bad debt,
/// they would need to change the TWAP by a factor of (1 / LTV), where the LTV is a function of volatility. We have a
/// manipulation metric that increases as an attacker tries to change the TWAP. If this metric rises above a certain
/// threshold, certain functionality will be paused, e.g. no new debt can be created. The threshold is calculated as
/// follows:
///
/// \\( \text{manipulationThreshold} =
/// \frac{log_{1.0001}\left( \frac{1}{\text{LTV}} \right)}{\text{MANIPULATION_THRESHOLD_DIVISOR}} \\)
uint8 constant DEFAULT_MANIPULATION_THRESHOLD_DIVISOR = 12;

/// @dev The default portion of interest that will accrue to a `Lender`'s `RESERVE` address.
/// Expressed as a reciprocal, e.g. 16 → 6.25%
uint8 constant DEFAULT_RESERVE_FACTOR = 16;

/*//////////////////////////////////////////////////////////////
                        GOVERNANCE CONSTRAINTS
//////////////////////////////////////////////////////////////*/

/// @dev The lowest number of standard deviations of price movement allowed for determining `Borrower` probe prices.
/// Expressed x10, e.g. 40 → 4σ
uint8 constant CONSTRAINT_N_SIGMA_MIN = 40;

/// @dev The highest number of standard deviations of price movement allowed for determining `Borrower` probe prices.
/// Expressed x10, e.g. 80 → 8σ
uint8 constant CONSTRAINT_N_SIGMA_MAX = 80;

/// @dev The minimum value of the `manipulationThresholdDivisor`, described above
uint8 constant CONSTRAINT_MANIPULATION_THRESHOLD_DIVISOR_MIN = 10;

/// @dev The maximum value of the `manipulationThresholdDivisor`, described above
uint8 constant CONSTRAINT_MANIPULATION_THRESHOLD_DIVISOR_MAX = 16;

/// @dev The lower bound on what any `Lender`'s reserve factor can be. Expressed as reciprocal, e.g. 4 → 25%
uint8 constant CONSTRAINT_RESERVE_FACTOR_MIN = 4;

/// @dev The upper bound on what any `Lender`'s reserve factor can be. Expressed as reciprocal, e.g. 20 → 5%
uint8 constant CONSTRAINT_RESERVE_FACTOR_MAX = 20;

/// @dev The maximum amount of Ether that `Borrower`s can be required to post before taking on debt
uint216 constant CONSTRAINT_ANTE_MAX = 0.5 ether;

/*//////////////////////////////////////////////////////////////
                            LIQUIDATION
//////////////////////////////////////////////////////////////*/

/// @dev \\( 1 + \frac{1}{\text{MAX_LEVERAGE}} \\) should be greater than the maximum feasible single-block
/// `accrualFactor` so that liquidators have time to respond to interest updates
uint256 constant MAX_LEVERAGE = 200;

/// @dev The minimum discount that a healthy `Borrower` should be able to offer a liquidator when swapping
/// assets. Expressed as reciprocal, e.g. 20 → 5%
uint256 constant LIQUIDATION_INCENTIVE = 20;

/// @dev The minimum time that must pass between calls to `Borrower.warn` and `Borrower.liquidate`.
uint256 constant LIQUIDATION_GRACE_PERIOD = 5 minutes;

/// @dev The minimum `closeFactor` necessary to conclude a liquidation auction. To actually conclude the auction,
/// `Borrower.liquidate` must result in a healthy balance sheet (in addition to this `closeFactor` requirement).
/// Expressed in basis points.
/// NOTE: The ante is depleted after just 4 `Borrower.warn`ings. By requiring that each auction repay at least
/// 68%, we ensure that after 4 auctions, no more than 1% of debt remains ((1 - 0.6838)^4). Increasing the threshold
/// would reduce that further, but we don't want to prolong individual auctions unnecessarily since the incentive
/// (and loss to `Borrower`s) increases with time.
uint256 constant TERMINATING_CLOSE_FACTOR = 6837;

/// @dev The minimum scaling factor by which `sqrtMeanPriceX96` is multiplied or divided to get probe prices
uint256 constant PROBE_SQRT_SCALER_MIN = 1.026248453011e12;

/// @dev The maximum scaling factor by which `sqrtMeanPriceX96` is multiplied or divided to get probe prices
uint256 constant PROBE_SQRT_SCALER_MAX = 3.078745359035e12;

/// @dev Equivalent to \\( \frac{10^{36}}{1 + \frac{1}{liquidationIncentive} + \frac{1}{maxLeverage}} \\)
uint256 constant LTV_NUMERATOR = uint256(LIQUIDATION_INCENTIVE * MAX_LEVERAGE * 1e36) /
    (LIQUIDATION_INCENTIVE * MAX_LEVERAGE + LIQUIDATION_INCENTIVE + MAX_LEVERAGE);

/// @dev The minimum loan-to-value ratio. Actual ratio is based on implied volatility; this is just a lower bound.
/// Expressed as a 1e12 percentage, e.g. 0.10e12 → 10%. Must be greater than `TickMath.MIN_SQRT_RATIO` because
/// we reuse a base 1.0001 logarithm in `BalanceSheet`
uint256 constant LTV_MIN = LTV_NUMERATOR / (PROBE_SQRT_SCALER_MAX * PROBE_SQRT_SCALER_MAX);

/// @dev The maximum loan-to-value ratio. Actual ratio is based on implied volatility; this is just a upper bound.
/// Expressed as a 1e12 percentage, e.g. 0.90e12 → 90%
uint256 constant LTV_MAX = LTV_NUMERATOR / (PROBE_SQRT_SCALER_MIN * PROBE_SQRT_SCALER_MIN);

/*//////////////////////////////////////////////////////////////
                            IV AND TWAP
//////////////////////////////////////////////////////////////*/

/// @dev The timescale of implied volatility, applied to measurements and calculations. When `BalanceSheet` detects
/// that an `nSigma` event would cause insolvency in this time period, it enables liquidations. So if you squint your
/// eyes and wave your hands enough, this is (in expectation) the time liquidators have to act before the protocol
/// accrues bad debt.
uint32 constant IV_SCALE = 24 hours;

/// @dev The initial value of implied volatility, used when `VolatilityOracle.prepare` is called for a new pool.
/// Expressed as a 1e12 percentage at `IV_SCALE`, e.g. {0.12e12, 24 hours} → 12% daily → 229% annual. Error on the
/// side of making this too large (resulting in low LTV).
uint104 constant IV_COLD_START = 0.127921282726e12;

/// @dev The maximum rate at which (reported) implied volatility can change. Raw samples in `VolatilityOracle.update`
/// are clamped (before being stored) so as not to exceed this rate.
/// Expressed in 1e12 percentage points at `IV_SCALE` **per second**, e.g. {115740, 24 hours} means daily IV can
/// change by 0.0000116 percentage points per second → 1 percentage point per day.
uint256 constant IV_CHANGE_PER_SECOND = 115740;

/// @dev The maximum amount by which (reported) implied volatility can change with a single `VolatilityOracle.update`
/// call. If updates happen as frequently as possible (every `FEE_GROWTH_SAMPLE_PERIOD`), this cap is no different
/// from `IV_CHANGE_PER_SECOND` alone.
uint104 constant IV_CHANGE_PER_UPDATE = uint104(IV_CHANGE_PER_SECOND * FEE_GROWTH_SAMPLE_PERIOD);

/// @dev The gain on the EMA update when IV is increasing. Expressed as reciprocal, e.g. 20 → 0.05
int256 constant IV_EMA_GAIN_POS = 20;

/// @dev The gain on the EMA update when IV is decreasing. Expressed as reciprocal, e.g. 100 → 0.01
int256 constant IV_EMA_GAIN_NEG = 100;

/// @dev To estimate volume, we need 2 samples. One is always at the current block, the other is from
/// `FEE_GROWTH_AVG_WINDOW` seconds ago, +/- `FEE_GROWTH_SAMPLE_PERIOD / 2`. Larger values make the resulting volume
/// estimate more robust, but may cause the oracle to miss brief spikes in activity.
uint256 constant FEE_GROWTH_AVG_WINDOW = 72 hours;

/// @dev The length of the circular buffer that stores feeGrowthGlobals samples.
/// Must be in interval
/// \\( \left[ \frac{\text{FEE_GROWTH_AVG_WINDOW}}{\text{FEE_GROWTH_SAMPLE_PERIOD}}, 256 \right) \\)
uint256 constant FEE_GROWTH_ARRAY_LENGTH = 32;

/// @dev The minimum number of seconds that must elapse before a new feeGrowthGlobals sample will be stored. This
/// controls how often the oracle can update IV.
uint256 constant FEE_GROWTH_SAMPLE_PERIOD = 4 hours;

/// @dev To compute Uniswap mean price & liquidity, we need 2 samples. One is always at the current block, the other is
/// from `UNISWAP_AVG_WINDOW` seconds ago. Larger values make the resulting price/liquidity values harder to
/// manipulate, but also make the oracle slower to respond to changes.
uint32 constant UNISWAP_AVG_WINDOW = 30 minutes;