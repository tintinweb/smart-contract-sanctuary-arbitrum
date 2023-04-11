// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./../shared/Constants.sol";

/* ========== STRUCTS ========== */
/**
 * @notice Struct to store the fee buffer for a given trade pair
 * @custom:member currentBufferAmount Currently buffered fee amount
 * @custom:member bufferFactor Buffer Factor nominated in BUFFER_MULTIPLIER
 */
struct FeeBuffer {
    int256 currentBufferAmount;
    int256 bufferFactor;
}

/**
 * @title FeeBuffer
 * @notice Stores and operates on the fee buffer. Calculates possible fee losses.
 * @dev This contract is a library and should be used by a contract that implements the ITradePair interface
 */
library FeeBufferLib {
    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice clears fee buffer for a given position. Either ´remainingBuffer´ is positive OR ´requestLoss´ is positive.
     * When ´remainingBuffer´ is positive, then ´remainingMargin´ could also be possible.
     * @param _margin the margin of the position
     * @param _borrowFeeAmount amount of borrow fee
     * @param _fundingFeeAmount amount of funding fee
     * @return remainingMargin the _margin of the position after clearing the buffer and paying fees
     * @return remainingBuffer remaining amount that needs to be transferred to the fee manager
     * @return requestLoss the amount of loss that needs to be requested from the liquidity pool
     */
    function clearBuffer(FeeBuffer storage _self, uint256 _margin, int256 _borrowFeeAmount, int256 _fundingFeeAmount)
        public
        returns (uint256 remainingMargin, uint256 remainingBuffer, uint256 requestLoss)
    {
        // calculate fee loss
        int256 buffered = _borrowFeeAmount * _self.bufferFactor / BUFFER_MULTIPLIER;
        int256 collected = _borrowFeeAmount - buffered;
        int256 overcollected = _borrowFeeAmount + _fundingFeeAmount - int256(_margin);
        int256 missing = overcollected - buffered;

        // Check if the buffer amount is big enough
        if (missing < 0) {
            // No overollection, no fees missing (close or liquidate bc. loss)
            if (-1 * missing > buffered) {
                remainingBuffer = uint256(buffered);

                remainingMargin = uint256(int256(_margin) - _fundingFeeAmount - (collected + int256(remainingBuffer)));
                // Buffer covers missing fees (early liquidation bc. fees)
            } else {
                remainingBuffer = uint256(-1 * missing);
            }
            // Buffer does not cover missing fees (late liquidation bc. fees)
        } else if (missing > 0) {
            // If fees are missing, request them as loss
            requestLoss = uint256(missing);
        }

        // update fee buffer
        _self.currentBufferAmount -= buffered;

        return (remainingMargin, remainingBuffer, requestLoss);
    }

    /**
     * @notice Takes buffer amount from the provided amount and returns reduced amount.
     * @param _amount the amount to take buffer from
     * @return amount the amount after taking buffer
     */
    function takeBufferFrom(FeeBuffer storage _self, uint256 _amount) public returns (uint256) {
        int256 newBufferAmount = int256(_amount) * _self.bufferFactor / BUFFER_MULTIPLIER;
        _self.currentBufferAmount += newBufferAmount;
        return _amount - uint256(newBufferAmount);
    }
}

using FeeBufferLib for FeeBuffer;

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