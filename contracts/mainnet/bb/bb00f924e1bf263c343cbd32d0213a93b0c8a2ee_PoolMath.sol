// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Libraries
import { RayMath } from "../libs/RayMath.sol";

// @bw move back into vpool ?

library PoolMath {
  using RayMath for uint256;

  // ======= CONSTANTS ======= //

  uint256 constant YEAR = 365 days;
  uint256 constant RAY = RayMath.RAY;
  uint256 constant MAX_SECONDS_PER_TICK = 1 days;
  uint256 constant FEE_BASE = RAY;
  uint256 constant PERCENTAGE_BASE = 100;
  uint256 constant FULL_CAPACITY = PERCENTAGE_BASE * RAY;

  // ======= STRUCTURES ======= //

  struct Formula {
    uint256 uOptimal;
    uint256 r0;
    uint256 rSlope1;
    uint256 rSlope2;
  }

  // ======= FUNCTIONS ======= //

  /**
   * @notice Computes the premium rate of a cover,
   * the premium rate is the APR cost for a cover  ,
   * these are paid by cover buyer on their cover amount.
   *
   * @param formula The formula of the pool
   * @param utilizationRate_ The utilization rate of the pool
   *
   * @return The premium rate of the cover expressed in rays
   *
   * @dev Not pure since reads self but pure for all practical purposes
   */
  function getPremiumRate(
    Formula calldata formula,
    uint256 utilizationRate_
  ) public pure returns (uint256 /* premiumRate */) {
    if (utilizationRate_ < formula.uOptimal) {
      // Return base rate + proportional slope 1 rate
      return
        formula.r0 +
        formula.rSlope1.rayMul(
          utilizationRate_.rayDiv(formula.uOptimal)
        );
    } else if (utilizationRate_ < FULL_CAPACITY) {
      // Return base rate + slope 1 rate + proportional slope 2 rate
      return
        formula.r0 +
        formula.rSlope1 +
        formula.rSlope2.rayMul(
          (utilizationRate_ - formula.uOptimal).rayDiv(
            FULL_CAPACITY - formula.uOptimal
          )
        );
    } else {
      // Return base rate + slope 1 rate + slope 2 rate
      /**
       * @dev Premium rate is capped because in case of overusage the
       * liquidity providers are exposed to the same risk as 100% usage but
       * cover buyers are not fully covered.
       * This means cover buyers only pay for the effective cover they have.
       */
      return formula.r0 + formula.rSlope1 + formula.rSlope2;
    }
  }

  /**
   * @notice Computes the liquidity index for a given period
   * @param utilizationRate_ The utilization rate
   * @param premiumRate_ The premium rate
   * @param timeSeconds_ The time in seconds
   * @return The liquidity index to add for the given time
   */
  function computeLiquidityIndex(
    uint256 utilizationRate_,
    uint256 premiumRate_,
    uint256 timeSeconds_
  ) public pure returns (uint /* liquidityIndex */) {
    return
      utilizationRate_
        .rayMul(premiumRate_)
        .rayMul(timeSeconds_)
        .rayDiv(YEAR);
  }

  /**
   * @notice Computes the premiums or interests earned by a liquidity position
   * @param userCapital_ The amount of liquidity in the position
   * @param endLiquidityIndex_ The end liquidity index
   * @param startLiquidityIndex_ The start liquidity index
   */
  function getCoverRewards(
    uint256 userCapital_,
    uint256 startLiquidityIndex_,
    uint256 endLiquidityIndex_
  ) public pure returns (uint256) {
    return
      (userCapital_.rayMul(endLiquidityIndex_) -
        userCapital_.rayMul(startLiquidityIndex_)) / 10_000;
  }

  /**
   * @notice Computes the new daily cost of a cover,
   * the emmission rate is the daily cost of a cover  .
   *
   * @param oldDailyCost_ The daily cost of the cover before the change
   * @param oldPremiumRate_ The premium rate of the cover before the change
   * @param newPremiumRate_ The premium rate of the cover after the change
   *
   * @return The new daily cost of the cover expressed in tokens/day
   */
  function getDailyCost(
    uint256 oldDailyCost_,
    uint256 oldPremiumRate_,
    uint256 newPremiumRate_
  ) public pure returns (uint256) {
    return (oldDailyCost_ * newPremiumRate_) / oldPremiumRate_;
  }

  /**
   * @notice Computes the new seconds per tick of a pool,
   * the seconds per tick is the time between two ticks  .
   *
   * @param oldSecondsPerTick_ The seconds per tick before the change
   * @param oldPremiumRate_ The premium rate before the change
   * @param newPremiumRate_ The premium rate after the change
   *
   * @return The new seconds per tick of the pool
   */
  function secondsPerTick(
    uint256 oldSecondsPerTick_,
    uint256 oldPremiumRate_,
    uint256 newPremiumRate_
  ) public pure returns (uint256) {
    return
      oldSecondsPerTick_.rayMul(oldPremiumRate_).rayDiv(
        newPremiumRate_
      );
  }

  /**
   * @notice Computes the updated premium rate of the pool based on utilization.
   * @param formula The formula of the pool
   * @param secondsPerTick_ The seconds per tick of the pool
   * @param coveredCapital_ The amount of covered capital
   * @param totalLiquidity_ The total amount liquidity
   * @param newCoveredCapital_ The new amount of covered capital
   * @param newTotalLiquidity_ The new total amount liquidity
   *
   * @return newPremiumRate The updated premium rate of the pool
   * @return newSecondsPerTick The updated seconds per tick of the pool
   */
  function updatePoolMarket(
    Formula calldata formula,
    uint256 secondsPerTick_,
    uint256 totalLiquidity_,
    uint256 coveredCapital_,
    uint256 newTotalLiquidity_,
    uint256 newCoveredCapital_
  )
    public
    pure
    returns (
      uint256 newPremiumRate,
      uint256 newSecondsPerTick,
      uint256 newUtilizationRate
    )
  {
    uint256 previousPremiumRate = getPremiumRate(
      formula,
      _utilization(coveredCapital_, totalLiquidity_)
    );

    newUtilizationRate = _utilization(
      newCoveredCapital_,
      newTotalLiquidity_
    );

    newPremiumRate = getPremiumRate(formula, newUtilizationRate);

    newSecondsPerTick = secondsPerTick(
      secondsPerTick_,
      previousPremiumRate,
      newPremiumRate
    );
  }

  /**
   * @notice Computes the percentage of the pool's liquidity used for covers.
   * @param coveredCapital_ The amount of covered capital
   * @param liquidity_ The total amount liquidity
   *
   * @return rate The utilization rate of the pool
   *
   * @dev The utilization rate is capped at 100%.
   */
  function _utilization(
    uint256 coveredCapital_,
    uint256 liquidity_
  ) public pure returns (uint256 /* rate */) {
    // If the pool has no liquidity then the utilization rate is 0
    if (liquidity_ == 0) return 0;

    /**
     * @dev Utilization rate is capped at 100% because in case of overusage the
     * liquidity providers are exposed to the same risk as 100% usage but
     * cover buyers are not fully covered.
     * This means cover buyers only pay for the effective cover they have.
     */
    if (liquidity_ < coveredCapital_) return FULL_CAPACITY;

    // Get a base PERCENTAGE_BASE percentage
    return (coveredCapital_ * PERCENTAGE_BASE).rayDiv(liquidity_);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.25;

/**
 * @title RayMath library
 * @author Aave
 * @dev Provides mul and div function for rays (decimals with 27 digits)
 **/

library RayMath {
  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(
    uint256 a,
    uint256 b
  ) internal pure returns (uint256) {
    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(
    uint256 a,
    uint256 b
  ) internal pure returns (uint256) {
    return ((a * RAY) + (b / 2)) / b;
  }
}