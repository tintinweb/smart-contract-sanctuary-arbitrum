// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./../shared/Constants.sol";

/**
 * @title FundingFeeLib
 * @notice Library for calculating funding fees
 * @dev Funding fees are the "long pays short" fees. They are calculated based on the excess volume of long positions over short positions or vice-versa.
 * Funding fees are calculated using a curve function. The curve function resembles a logarithmic growth function, but is easier to calculate.
 */

library FundingFee {
    /* ========== CONSTANTS ========== */

    // For the readability of the maths functions, we define the constants below.
    // ONE is defined for readability.
    int256 constant ONE = FEE_MULTIPLIER;
    int256 constant TWO = 2 * ONE;
    // this is a percentage multiplier
    int256 constant PERCENT = ONE / 100;

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice calculates the fee rates for long and short positions.
     * @param longVolume the volume of long positions
     * @param shortVolume the volume of short positions
     * @param maxRatio the maximum ratio of excess volume to deficient volume. All excess volume above this ratio will be ignored.
     * @param maxFeeRate the maximum fee rate that can be charged.
     * @return longFeeRate (int256) the fee for long positions.
     * @return shortFeeRate (int256) the fee for short positions.
     */
    function getFundingFeeRates(uint256 longVolume, uint256 shortVolume, int256 maxRatio, int256 maxFeeRate)
        public
        pure
        returns (int256 longFeeRate, int256 shortFeeRate)
    {
        if (longVolume == shortVolume) {
            return (0, 0);
        }

        uint256 excessVolume;
        uint256 deficientVolume;
        bool isLongExcess;

        // Assign if long or short is excess
        if (longVolume > shortVolume) {
            excessVolume = longVolume;
            deficientVolume = shortVolume;
            isLongExcess = true;

            // edge case: when short volume is 0, long has to pay the max fee
            if (shortVolume == 0) {
                return (maxFeeRate, 0);
            }
        } else {
            excessVolume = shortVolume;
            deficientVolume = longVolume;
            isLongExcess = false;

            // edge case: when long volume is 0, short has to pay the max fee
            if (longVolume == 0) {
                return (0, maxFeeRate);
            }
        }

        // Do the actual fee calculation
        int256 normalizedVolumeRatio = normalizedExcessRatio(excessVolume, deficientVolume, maxRatio);
        int256 normalizedFeeRate = curve(normalizedVolumeRatio);
        int256 feeRate = calculateFundingFee(normalizedFeeRate, maxFeeRate);
        int256 rewardRate = calculateFundingFeeReward(excessVolume, deficientVolume, feeRate);

        // Assign the fees to the correct position
        if (isLongExcess) {
            longFeeRate = int256(feeRate);
            shortFeeRate = rewardRate;
        } else {
            longFeeRate = rewardRate;
            shortFeeRate = int256(feeRate);
        }

        return (longFeeRate, shortFeeRate);
    }

    /**
     * @notice calculates the normalized excess volume
     * @param excessVolume the excess volume
     * @param deficientVolume the deficient volume
     * @param maxRatio the maximum ratio of excess volume to deficient volume. Denominated in ONE. When the ratio is higher than this value, the return value is ONE.
     * @return the normalized excess volume to be used in the curve. Denominated like ONE.
     */
    function normalizedExcessRatio(uint256 excessVolume, uint256 deficientVolume, int256 maxRatio)
        public
        pure
        onlyPositiveVolumeExcess(excessVolume, deficientVolume)
        returns (int256)
    {
        // When maxRatio is smaller than ONE, it is considered an error. Return ONE
        if (maxRatio <= ONE) {
            return ONE;
        }

        // When the excess volume is equal to the deficient volume, the normalizedExcessRatio is 0
        if (excessVolume == deficientVolume) {
            return 0;
        }

        int256 ratio = ONE * int256(excessVolume) / int256(deficientVolume);

        // When the ratio is higher than the max ratio, the normalized excess volume is ONE
        if (ratio >= maxRatio) {
            return ONE;
        }

        // When the ratio is lower than the max ratio, the ratio gets normalized to a range from 0 to ONE
        return ONE * (ratio - ONE) / (maxRatio - ONE);
    }

    /**
     * @notice Curve to calculate the balance fee
     * The curve resembles a logarithmic growth function, but is easier to calculate.
     * Function starts at zero and goes to one.
     * Function has a soft ease-in-ease-out.
     *
     *
     * 1|-------------------
     * .|           ~°°°
     * .|        +´
     * .|       /
     * .|    +´
     * .|_~°°
     * 0+-------------------
     * #0                  1
     *
     * Function:
     * y = 0; x <= 0;
     * y = ((2x)**2)/2; 0 <= x < 0.5;
     * y = (2-(2-2x)**2)/2; 0.5 <= x < 1;
     * y = 1; 1 <= x;
     *
     * Represents concave function starting at (0,0) and reaching the max value
     * and a slope of 0 at (1/1)
     * @param x needs to have decimals of PERCENT
     * @return y
     */

    function curve(int256 x) public pure returns (int256 y) {
        // x <= 0
        // y = 0
        if (x <= 0) {
            return 0;
        }
        // 0 < x < 0.5
        // y = ((2x)**2)/2
        else if (x < ONE / 2) {
            return ((2 * x) ** 2) / 2 / ONE;
        }
        // 0.5 <= x < 1
        // y = (2-(2-2x)**2)/2
        else if (x < ONE) {
            return (TWO - ((TWO - 2 * x) ** 2) / ONE) / 2;
        }

        // x >= 1
        // y = 1
        return ONE;
    }

    /**
     * @notice Calculates the funding fee
     * @param normalizedFeeValue the normalized fee value between 0 and ONE. Denominated in PERCENT.
     * @param maxFee the maximum fee. Denominated in PERCENT
     * @return fee the funding fee. Denominated in PERCENT
     */
    function calculateFundingFee(int256 normalizedFeeValue, int256 maxFee) public pure returns (int256 fee) {
        if (normalizedFeeValue > ONE) {
            return maxFee;
        }
        return normalizedFeeValue * maxFee / ONE;
    }

    /**
     * @notice calculates the funding reward. The funding reward is the fee that is paid to the "other" position.
     * @dev It is calculated by distributing the total collected funding fee to the "other" positions based on their share of the total volume.
     * @param excessVolume the excess volume
     * @param deficientVolume the deficient volume
     * @param fee the relative fee for the excess volume. Denominated in PERCENT
     */
    function calculateFundingFeeReward(uint256 excessVolume, uint256 deficientVolume, int256 fee)
        public
        pure
        onlyPositiveVolumeExcess(excessVolume, deficientVolume)
        returns (int256)
    {
        if (deficientVolume == 0) {
            return 0;
        }

        return -1 * int256(fee) * int256(excessVolume) / int256(deficientVolume);
    }

    /**
     * @notice checks if excessVolume is higher than deficientVolume
     * @param excessVolume the excess volume
     * @param deficientVolume the deficient volume
     */
    modifier onlyPositiveVolumeExcess(uint256 excessVolume, uint256 deficientVolume) {
        require(
            excessVolume >= deficientVolume,
            "FundingFee::onlyPositiveVolumeExcess: Excess volume must be higher than deficient volume"
        );
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

/**
 * @dev These are global constants used in the Unlimited protocol.
 * These constants are mainly used as multipliers.
 */

// 100 percent in BPS.
uint256 constant FULL_PERCENT = 100_00;
int256 constant FEE_MULTIPLIER = 1e14;
int256 constant FEE_BPS_MULTIPLIER = FEE_MULTIPLIER / 1e4; // 1e10
int256 constant BUFFER_MULTIPLIER = 1e6;
uint256 constant PERCENTAGE_MULTIPLIER = 1e6;
uint256 constant LEVERAGE_MULTIPLIER = 1_000_000;
uint8 constant ASSET_DECIMALS = 18;
uint256 constant ASSET_MULTIPLIER = 10 ** ASSET_DECIMALS;

// Rational to use 24 decimals for prices:
// 24 decimals is larger or equal than decimals of all important tokens. (Ethereum = 18, BNB = 18, USDT = 6)
// It is higher than most price feeds (Chainlink = 8, Uniswap = 18, Binance = 8)
uint256 constant PRICE_DECIMALS = 24;
uint256 constant PRICE_MULTIPLIER = 10 ** PRICE_DECIMALS;