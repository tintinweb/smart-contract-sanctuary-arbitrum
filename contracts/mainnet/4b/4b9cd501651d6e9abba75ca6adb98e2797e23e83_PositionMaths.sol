// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "./../shared/Constants.sol";

interface ITradePair_Multiplier {
    function collateralToPriceMultiplier() external view returns (uint256);
}

/* ========== STRUCTS ========== */
/**
 * @notice Struct to store details of a position
 * @custom:member margin the margin of the position
 * @custom:member volume the volume of the position
 * @custom:member assetAmount the underlying amount of assets. Normalized to  ASSET_DECIMALS
 * @custom:member pastBorrowFeeIntegral the integral of borrow fee at the moment of opening or last fee update
 * @custom:member lastBorrowFeeAmount the last borrow fee amount at the moment of last fee update
 * @custom:member pastFundingFeeIntegral the integral of funding fee at the moment of opening or last fee update
 * @custom:member lastFundingFeeAmount the last funding fee amount at the moment of last fee update
 * @custom:member collectedFundingFeeAmount the total collected funding fee amount, to add up the total funding fee amount
 * @custom:member lastFeeCalculationAt moment of the last fee update
 * @custom:member openedAt moment of the position opening
 * @custom:member isShort bool if the position is short
 * @custom:member owner the owner of the position
 * @custom:member lastAlterationBlock the last block where the position was altered or opened
 */
struct Position {
    uint256 margin;
    uint256 volume;
    uint256 assetAmount;
    int256 pastBorrowFeeIntegral;
    int256 lastBorrowFeeAmount;
    int256 collectedBorrowFeeAmount;
    int256 pastFundingFeeIntegral;
    int256 lastFundingFeeAmount;
    int256 collectedFundingFeeAmount;
    uint48 lastFeeCalculationAt;
    uint48 openedAt;
    bool isShort;
    address owner;
    uint40 lastAlterationBlock;
}

/**
 * @title Position Maths
 * @notice Provides financial maths for leveraged positions.
 */
library PositionMaths {
    /**
     * External Functions
     */

    /**
     * @notice Price at entry level
     * @return price int
     */
    function entryPrice(Position storage self) public view returns (int256) {
        return self._entryPrice();
    }

    function _entryPrice(Position storage self) internal view returns (int256) {
        return int256(self.volume * collateralToPriceMultiplier() * ASSET_MULTIPLIER / self.assetAmount);
    }

    /**
     * @notice Leverage at entry level
     * @return leverage uint
     */
    function entryLeverage(Position storage self) public view returns (uint256) {
        return self._entryLeverage();
    }

    function _entryLeverage(Position storage self) internal view returns (uint256) {
        return self.volume * LEVERAGE_MULTIPLIER / self.margin;
    }

    /**
     * @notice Last net leverage is calculated with the last net margin, which is entry margin minus last total fees. Margin of zero means position is liquidatable.
     * @return net leverage uint. When margin is less than zero, leverage is max uint256
     * @dev this value is only valid when the position got updated at the same block
     */
    function lastNetLeverage(Position storage self) public view returns (uint256) {
        return self._lastNetLeverage();
    }

    function _lastNetLeverage(Position storage self) internal view returns (uint256) {
        uint256 lastNetMargin_ = self._lastNetMargin();
        if (lastNetMargin_ == 0) {
            return type(uint256).max;
        }
        return self.volume * LEVERAGE_MULTIPLIER / lastNetMargin_;
    }

    /**
     * @notice Current Net Margin, which is entry margin minus current total fees. Margin of zero means position is liquidatable.
     * @return net margin int
     */
    function currentNetMargin(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
        public
        view
        returns (uint256)
    {
        return self._currentNetMargin(currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentNetMargin(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
        internal
        view
        returns (uint256)
    {
        int256 actualCurrentMargin =
            int256(self.margin) - self._currentTotalFeeAmount(currentBorrowFeeIntegral, currentFundingFeeIntegral);
        return actualCurrentMargin > 0 ? uint256(actualCurrentMargin) : 0;
    }

    /**
     * @notice Returns the last net margin, calculated at the moment of last fee update
     * @return last net margin uint. Can be zero.
     * @dev this value is only valid when the position got updated at the same block
     * It is a convenience function because the caller does not need to provice fee integrals
     */
    function lastNetMargin(Position storage self) internal view returns (uint256) {
        return self._lastNetMargin();
    }

    function _lastNetMargin(Position storage self) internal view returns (uint256) {
        int256 _lastMargin = int256(self.margin) - self.lastBorrowFeeAmount - self.lastFundingFeeAmount;
        return _lastMargin > 0 ? uint256(_lastMargin) : 0;
    }

    /**
     * @notice Current Net Leverage, which is entry volume divided by current net margin
     * @return current net leverage
     */
    function currentNetLeverage(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) public view returns (uint256) {
        return self._currentNetLeverage(currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentNetLeverage(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) internal view returns (uint256) {
        uint256 currentNetMargin_ = self._currentNetMargin(currentBorrowFeeIntegral, currentFundingFeeIntegral);
        if (currentNetMargin_ == 0) {
            return type(uint256).max;
        }
        return self.volume * LEVERAGE_MULTIPLIER / currentNetMargin_;
    }

    /**
     * @notice Liquidation price takes into account fee-reduced collateral and absolute maintenance margin
     * @return liquidationPrice int
     */
    function liquidationPrice(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral,
        uint256 maintenanceMargin
    ) public view returns (int256) {
        return self._liquidationPrice(currentBorrowFeeIntegral, currentFundingFeeIntegral, maintenanceMargin);
    }

    function _liquidationPrice(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral,
        uint256 maintenanceMargin
    ) internal view returns (int256) {
        // Reduce current margin by liquidator reward
        int256 liquidatableMargin = int256(self._currentNetMargin(currentBorrowFeeIntegral, currentFundingFeeIntegral))
            - int256(maintenanceMargin);

        // If margin is zero, position is liquidatable by fee reduction alone.
        // Return entry price
        if (liquidatableMargin <= 0) {
            return self._entryPrice();
        }

        // Return entryPrice +/- entryPrice / leverage
        // Where leverage = volume / liquidatableMargin
        return self._entryPrice()
            - self._entryPrice() * int256(LEVERAGE_MULTIPLIER) * self._shortMultiplier() * liquidatableMargin
                / int256(self.volume * LEVERAGE_MULTIPLIER);
    }

    function _shortMultiplier(Position storage self) internal view returns (int256) {
        if (self.isShort) {
            return int256(-1);
        } else {
            return int256(1);
        }
    }

    /**
     * @notice Current Volume is the current mark price times the asset amount (this is not the current value)
     * @param currentPrice int current mark price
     * @return currentVolume uint
     */
    function currentVolume(Position storage self, int256 currentPrice) public view returns (uint256) {
        return self._currentVolume(currentPrice);
    }

    function _currentVolume(Position storage self, int256 currentPrice) internal view returns (uint256) {
        return self.assetAmount * uint256(currentPrice) / ASSET_MULTIPLIER / collateralToPriceMultiplier();
    }

    /**
     * @notice Current Profit and Losses (without fees)
     * @param currentPrice int current mark price
     * @return currentPnL int
     */
    function currentPnL(Position storage self, int256 currentPrice) public view returns (int256) {
        return self._currentPnL(currentPrice);
    }

    function _currentPnL(Position storage self, int256 currentPrice) internal view returns (int256) {
        return (int256(self._currentVolume(currentPrice)) - int256(self.volume)) * self._shortMultiplier();
    }

    /**
     * @notice Current Value is the derived value that takes into account entry volume and PNL
     * @dev This value is shown on the UI. It normalized the differences of LONG/SHORT into a single value
     * @param currentPrice int current mark price
     * @return currentValue int
     */
    function currentValue(Position storage self, int256 currentPrice) public view returns (int256) {
        return self._currentValue(currentPrice);
    }

    function _currentValue(Position storage self, int256 currentPrice) internal view returns (int256) {
        return int256(self.volume) + self._currentPnL(currentPrice);
    }

    /**
     * @notice Current Equity (without fees)
     * @param currentPrice int current mark price
     * @return currentEquity int
     */
    function currentEquity(Position storage self, int256 currentPrice) public view returns (int256) {
        return self._currentEquity(currentPrice);
    }

    function _currentEquity(Position storage self, int256 currentPrice) internal view returns (int256) {
        return self._currentPnL(currentPrice) + int256(self.margin);
    }

    function currentTotalFeeAmount(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) public view returns (int256) {
        return self._currentTotalFeeAmount(currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentTotalFeeAmount(
        Position storage self,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) internal view returns (int256) {
        return self._currentBorrowFeeAmount(currentBorrowFeeIntegral)
            + self._currentFundingFeeAmount(currentFundingFeeIntegral);
    }

    /**
     * @notice Current Amount of Funding Fee, accumulated over time
     * @param currentFundingFeeIntegral uint current funding fee integral
     * @return currentFundingFeeAmount int
     */
    function currentFundingFeeAmount(Position storage self, int256 currentFundingFeeIntegral)
        public
        view
        returns (int256)
    {
        return self._currentFundingFeeAmount(currentFundingFeeIntegral);
    }

    function _currentFundingFeeAmount(Position storage self, int256 currentFundingFeeIntegral)
        internal
        view
        returns (int256)
    {
        int256 elapsedFundingFeeAmount =
            (currentFundingFeeIntegral - self.pastFundingFeeIntegral) * int256(self.volume) / FEE_MULTIPLIER;
        return self.lastFundingFeeAmount + elapsedFundingFeeAmount;
    }

    /**
     * @notice Current amount of borrow fee, accumulated over time
     * @param currentBorrowFeeIntegral uint current fee integral
     * @return currentBorrowFeeAmount int
     */
    function currentBorrowFeeAmount(Position storage self, int256 currentBorrowFeeIntegral)
        public
        view
        returns (int256)
    {
        return self._currentBorrowFeeAmount(currentBorrowFeeIntegral);
    }

    function _currentBorrowFeeAmount(Position storage self, int256 currentBorrowFeeIntegral)
        internal
        view
        returns (int256)
    {
        return self.lastBorrowFeeAmount
            + (currentBorrowFeeIntegral - self.pastBorrowFeeIntegral) * int256(self.volume) / FEE_MULTIPLIER;
    }

    /**
     * @notice Current Net PnL, including fees
     * @param currentPrice int current mark price
     * @param currentBorrowFeeIntegral uint current fee integral
     * @param currentFundingFeeIntegral uint current funding fee integral
     * @return currentNetPnL int
     */
    function currentNetPnL(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) public view returns (int256) {
        return self._currentNetPnL(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentNetPnL(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) internal view returns (int256) {
        return self._currentPnL(currentPrice)
            - int256(self._currentTotalFeeAmount(currentBorrowFeeIntegral, currentFundingFeeIntegral));
    }

    /**
     * @notice Current Net Equity, including fees
     * @param currentPrice int current mark price
     * @param currentBorrowFeeIntegral uint current fee integral
     * @param currentFundingFeeIntegral uint current funding fee integral
     * @return currentNetEquity int
     */
    function currentNetEquity(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) public view returns (int256) {
        return self._currentNetEquity(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    function _currentNetEquity(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral
    ) internal view returns (int256) {
        return
            self._currentNetPnL(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral) + int256(self.margin);
    }

    /**
     * @notice Determines if the position can be liquidated
     * @param currentPrice int current mark price
     * @param currentBorrowFeeIntegral uint current fee integral
     * @param currentFundingFeeIntegral uint current funding fee integral
     * @param absoluteMaintenanceMargin absolute amount of maintenance margin.
     * @return isLiquidatable bool
     * @dev A position is liquidatable, when either the margin or the current equity
     * falls under or equals the absolute maintenance margin
     */
    function isLiquidatable(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral,
        uint256 absoluteMaintenanceMargin
    ) public view returns (bool) {
        return self._isLiquidatable(
            currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral, absoluteMaintenanceMargin
        );
    }

    function _isLiquidatable(
        Position storage self,
        int256 currentPrice,
        int256 currentBorrowFeeIntegral,
        int256 currentFundingFeeIntegral,
        uint256 absoluteMaintenanceMargin
    ) internal view returns (bool) {
        // If margin does not cover fees, position is liquidatable.
        if (
            int256(self.margin)
                <= int256(absoluteMaintenanceMargin)
                    + int256(self._currentTotalFeeAmount(currentBorrowFeeIntegral, currentFundingFeeIntegral))
        ) {
            return true;
        }
        // Otherwise, a position is liquidatable if equity is below the absolute maintenance margin.
        return self._currentNetEquity(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral)
            <= int256(absoluteMaintenanceMargin);
    }

    /* ========== POSITION ALTERATIONS ========== */

    /**
     * @notice Partially closes a position
     * @param currentPrice int current mark price
     * @param closeProportion the share of the position that should be closed
     */
    function partiallyClose(Position storage self, int256 currentPrice, uint256 closeProportion)
        public
        returns (int256)
    {
        return self._partiallyClose(currentPrice, closeProportion);
    }

    /**
     * @dev Partially closing works as follows:
     *
     * 1. Sell a share of the position, and use the proceeds to either:
     * 2.a) Get a payout and by this, leave the leverage as it is
     * 2.b) "Buy" new margin and by this decrease the leverage
     * 2.c) a mixture of 2.a) and 2.b)
     */
    function _partiallyClose(Position storage self, int256 currentPrice, uint256 closeProportion)
        internal
        returns (int256)
    {
        require(
            closeProportion < PERCENTAGE_MULTIPLIER,
            "PositionMaths::_partiallyClose: cannot partially close full position"
        );

        Position memory delta;
        // Close a proportional share of the position
        delta.margin = self._lastNetMargin() * closeProportion / PERCENTAGE_MULTIPLIER;
        delta.volume = self.volume * closeProportion / PERCENTAGE_MULTIPLIER;
        delta.assetAmount = self.assetAmount * closeProportion / PERCENTAGE_MULTIPLIER;

        // The realized PnL is the change in volume minus the price of the changes in size at LONG
        // And the inverse of that at SHORT
        // @dev At a long position, the delta of size is sold to give back the volume
        // @dev At a short position, the volume delta is used, to "buy" the change of size (and give it back)
        int256 priceOfSizeDelta =
            currentPrice * int256(delta.assetAmount) / int256(collateralToPriceMultiplier()) / int256(ASSET_MULTIPLIER);
        int256 realizedPnL = (priceOfSizeDelta - int256(delta.volume)) * self._shortMultiplier();

        int256 payout = int256(delta.margin) + realizedPnL;

        // change storage values
        self.margin -= self.margin * closeProportion / PERCENTAGE_MULTIPLIER;
        self.volume -= delta.volume;
        self.assetAmount -= delta.assetAmount;

        // Update borrow fee amounts
        self.collectedBorrowFeeAmount +=
            self.lastBorrowFeeAmount * int256(closeProportion) / int256(PERCENTAGE_MULTIPLIER);
        self.lastBorrowFeeAmount -= self.lastBorrowFeeAmount * int256(closeProportion) / int256(PERCENTAGE_MULTIPLIER);

        // Update funding fee amounts
        self.collectedFundingFeeAmount +=
            self.lastFundingFeeAmount * int256(closeProportion) / int256(PERCENTAGE_MULTIPLIER);
        self.lastFundingFeeAmount -= self.lastFundingFeeAmount * int256(closeProportion) / int256(PERCENTAGE_MULTIPLIER);

        // Return payout for further calculations
        return payout;
    }

    /**
     * @notice Adds margin to a position
     * @param addedMargin the margin that gets added to the position
     */
    function addMargin(Position storage self, uint256 addedMargin) public {
        self._addMargin(addedMargin);
    }

    function _addMargin(Position storage self, uint256 addedMargin) internal {
        self.margin += addedMargin;
    }

    /**
     * @notice Removes margin from a position
     * @dev The remaining equity has to stay positive
     * @param removedMargin the margin to remove
     */
    function removeMargin(Position storage self, uint256 removedMargin) public {
        self._removeMargin(removedMargin);
    }

    function _removeMargin(Position storage self, uint256 removedMargin) internal {
        require(self.margin > removedMargin, "PositionMaths::_removeMargin: cannot remove more margin than available");
        self.margin -= removedMargin;
    }

    /**
     * @notice Extends position with margin and loan.
     * @param addedMargin Margin added to position.
     * @param addedAssetAmount Asset amount added to position.
     * @param addedVolume Loan added to position.
     */
    function extend(Position storage self, uint256 addedMargin, uint256 addedAssetAmount, uint256 addedVolume) public {
        self._extend(addedMargin, addedAssetAmount, addedVolume);
    }

    function _extend(Position storage self, uint256 addedMargin, uint256 addedAssetAmount, uint256 addedVolume)
        internal
    {
        self.margin += addedMargin;
        self.assetAmount += addedAssetAmount;
        self.volume += addedVolume;
    }

    /**
     * @notice Extends position with loan to target leverage.
     * @param currentPrice current asset price
     * @param targetLeverage target leverage
     */
    function extendToLeverage(Position storage self, int256 currentPrice, uint256 targetLeverage) public {
        self._extendToLeverage(currentPrice, targetLeverage);
    }

    function _extendToLeverage(Position storage self, int256 currentPrice, uint256 targetLeverage) internal {
        require(
            targetLeverage > self._lastNetLeverage(),
            "PositionMaths::_extendToLeverage: target leverage must be larger than current leverage"
        );

        // calculate changes
        Position memory delta;
        delta.volume = targetLeverage * self._lastNetMargin() / LEVERAGE_MULTIPLIER - self.volume;
        delta.assetAmount = delta.volume * collateralToPriceMultiplier() * ASSET_MULTIPLIER / uint256(currentPrice);

        // store changes
        self.assetAmount += delta.assetAmount;
        self.volume += delta.volume;
    }

    /**
     * @notice Returns if the position exists / is open
     */
    function exists(Position storage self) public view returns (bool) {
        return self._exists();
    }

    function _exists(Position storage self) internal view returns (bool) {
        return self.margin > 0;
    }

    /**
     * @notice Adds all elapsed fees to the fee amounts. After this, the position can be altered.
     */
    function updateFees(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
        public
    {
        self._updateFees(currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    /**
     * Internal Functions (that are only called internally and not mirror a public function)
     */

    function _updateFees(Position storage self, int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral)
        internal
    {
        int256 elapsedBorrowFeeAmount =
            (currentBorrowFeeIntegral - self.pastBorrowFeeIntegral) * int256(self.volume) / FEE_MULTIPLIER;
        int256 elapsedFundingFeeAmount =
            (currentFundingFeeIntegral - self.pastFundingFeeIntegral) * int256(self.volume) / FEE_MULTIPLIER;

        self.lastBorrowFeeAmount += elapsedBorrowFeeAmount;
        self.lastFundingFeeAmount += elapsedFundingFeeAmount;
        self.pastBorrowFeeIntegral = currentBorrowFeeIntegral;
        self.pastFundingFeeIntegral = currentFundingFeeIntegral;
        self.lastFeeCalculationAt = uint48(block.timestamp);
    }

    /**
     * @notice Returns the multiplier from TradePair, as PositionMaths is decimal agnostic
     */
    function collateralToPriceMultiplier() private view returns (uint256) {
        return ITradePair_Multiplier(address(this)).collateralToPriceMultiplier();
    }
}

using PositionMaths for Position;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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