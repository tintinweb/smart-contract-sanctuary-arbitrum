//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "../interfaces/IPerpetualMarketCore.sol";
import "./Math.sol";
import "./EntryPriceMath.sol";

/**
 * @title TraderVaultLib
 * @notice TraderVaultLib has functions to calculate position value and minimum collateral for implementing cross margin wallet.
 *
 * Data Structure
 *  Vault
 *  - PositionUSDC
 *  - SubVault0(PositionPerpetuals, EntryPrices, entryFundingFee)
 *  - SubVault1(PositionPerpetuals, EntryPrices, entryFundingFee)
 *  - ...
 *
 *  PositionPerpetuals = [PositionSqueeth, PositionFuture]
 *  EntryPrices = [EntryPriceSqueeth, EntryPriceFuture]
 *  entryFundingFee = [entryFundingFeeqeeth, FundingFeeEntryValueFuture]
 *
 *
 * Error codes
 *  T0: PositionValue must be greater than MinCollateral
 *  T1: PositionValue must be less than MinCollateral
 *  T2: Vault is insolvent
 *  T3: subVaultIndex is too large
 *  T4: position must not be 0
 */
library TraderVaultLib {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;

    uint256 private constant MAX_PRODUCT_ID = 2;

    /// @dev minimum margin is 500 USDC
    uint256 private constant MIN_MARGIN = 500 * 1e8;

    /// @dev risk parameter for MinCollateral calculation is 5.0%
    uint256 private constant RISK_PARAM_FOR_VAULT = 500;

    struct SubVault {
        int128[2] positionPerpetuals;
        uint128[2] entryPrices;
        int128[2] entryFundingFee;
    }

    struct TraderVault {
        int128 positionUsdc;
        SubVault[] subVaults;
        bool isInsolvent;
    }

    /**
     * @notice Gets amount of min collateral to add Squees/Future
     * @param _traderVault trader vault object
     * @param _tradeAmounts amount to trade
     * @param _tradePriceInfo trade price info
     * @return minCollateral and positionValue
     */
    function getMinCollateralToAddPosition(
        TraderVault memory _traderVault,
        int128[2] memory _tradeAmounts,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256 minCollateral) {
        int128[2] memory positionPerpetuals = getPositionPerpetuals(_traderVault);

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            positionPerpetuals[i] = positionPerpetuals[i].add(_tradeAmounts[i]).toInt128();
        }

        minCollateral = calculateMinCollateral(positionPerpetuals, _tradePriceInfo);
    }

    /**
     * @notice Updates USDC position
     * @param _traderVault trader vault object
     * @param _usdcPositionToAdd amount to add. if positive then increase amount, if negative then decrease amount.
     * @param _tradePriceInfo trade price info
     * @return finalUsdcPosition positive means amount of deposited margin
     * and negative means amount of withdrawn margin.
     */
    function updateUsdcPosition(
        TraderVault storage _traderVault,
        int256 _usdcPositionToAdd,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) external returns (int256 finalUsdcPosition) {
        finalUsdcPosition = _usdcPositionToAdd;
        require(!_traderVault.isInsolvent, "T2");

        int256 positionValue = getPositionValue(_traderVault, _tradePriceInfo);
        int256 minCollateral = getMinCollateral(_traderVault, _tradePriceInfo);
        int256 maxWithdrawable = positionValue - minCollateral;

        // If trader wants to withdraw all USDC, set maxWithdrawable.
        if (_usdcPositionToAdd < -maxWithdrawable && maxWithdrawable > 0 && _usdcPositionToAdd < 0) {
            finalUsdcPosition = -maxWithdrawable;
        }

        _traderVault.positionUsdc = _traderVault.positionUsdc.add(finalUsdcPosition).toInt128();

        require(!checkVaultIsLiquidatable(_traderVault, _tradePriceInfo), "T0");
    }

    /**
     * @notice Gets total position of perpetuals in the vault
     * @param _traderVault trader vault object
     * @return positionPerpetuals are total amount of perpetual scaled by 1e8
     */
    function getPositionPerpetuals(TraderVault memory _traderVault)
        internal
        pure
        returns (int128[2] memory positionPerpetuals)
    {
        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            positionPerpetuals[i] = getPositionPerpetual(_traderVault, i);
        }
    }

    /**
     * @notice Gets position of a perpetual in the vault
     * @param _traderVault trader vault object
     * @param _productId product id
     * @return positionPerpetual is amount of perpetual scaled by 1e8
     */
    function getPositionPerpetual(TraderVault memory _traderVault, uint256 _productId)
        internal
        pure
        returns (int128 positionPerpetual)
    {
        for (uint256 i = 0; i < _traderVault.subVaults.length; i++) {
            positionPerpetual = positionPerpetual
                .add(_traderVault.subVaults[i].positionPerpetuals[_productId])
                .toInt128();
        }
    }

    /**
     * @notice Updates positions in the vault
     * @param _traderVault trader vault object
     * @param _subVaultIndex index of sub-vault
     * @param _productId product id
     * @param _positionPerpetual amount of position to increase or decrease
     * @param _tradePrice trade price
     * @param _fundingFeePerPosition entry funding fee paid per position
     */
    function updateVault(
        TraderVault storage _traderVault,
        uint256 _subVaultIndex,
        uint256 _productId,
        int128 _positionPerpetual,
        uint256 _tradePrice,
        int256 _fundingFeePerPosition
    ) external returns (int256 deltaUsdcPosition) {
        require(!_traderVault.isInsolvent, "T2");
        require(_positionPerpetual != 0, "T4");

        if (_traderVault.subVaults.length == _subVaultIndex) {
            int128[2] memory positionPerpetuals;
            uint128[2] memory entryPrices;
            int128[2] memory entryFundingFee;

            _traderVault.subVaults.push(SubVault(positionPerpetuals, entryPrices, entryFundingFee));
        } else {
            require(_traderVault.subVaults.length > _subVaultIndex, "T3");
        }

        SubVault storage subVault = _traderVault.subVaults[_subVaultIndex];

        {
            (int256 newEntryPrice, int256 profitValue) = EntryPriceMath.updateEntryPrice(
                int256(subVault.entryPrices[_productId]),
                subVault.positionPerpetuals[_productId],
                int256(_tradePrice),
                _positionPerpetual
            );

            subVault.entryPrices[_productId] = newEntryPrice.toUint256().toUint128();
            deltaUsdcPosition = deltaUsdcPosition.add(profitValue);
        }

        {
            (int256 newEntryFundingFee, int256 profitValue) = EntryPriceMath.updateEntryPrice(
                int256(subVault.entryFundingFee[_productId]),
                subVault.positionPerpetuals[_productId],
                _fundingFeePerPosition,
                _positionPerpetual
            );

            subVault.entryFundingFee[_productId] = newEntryFundingFee.toInt128();
            deltaUsdcPosition = deltaUsdcPosition.sub(profitValue);
        }

        _traderVault.positionUsdc = _traderVault.positionUsdc.add(deltaUsdcPosition).toInt128();

        subVault.positionPerpetuals[_productId] = subVault
            .positionPerpetuals[_productId]
            .add(_positionPerpetual)
            .toInt128();
    }

    /**
     * @notice Checks the vault is liquidatable and return result
     * if PositionValue is less than MinCollateral return true
     * otherwise return false
     * @param _traderVault trader vault object
     * @return if true the vault is liquidatable, if false the vault is not liquidatable
     */
    function checkVaultIsLiquidatable(
        TraderVault memory _traderVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (bool) {
        int256 positionValue = getPositionValue(_traderVault, _tradePriceInfo);

        return positionValue < getMinCollateral(_traderVault, _tradePriceInfo);
    }

    /**
     * @notice Set insolvency flag if needed
     * If PositionValue is negative, set insolvency flag.
     * @param _traderVault trader vault object
     */
    function setInsolvencyFlagIfNeeded(TraderVault storage _traderVault) external {
        // Confirm that there are no positions
        for (uint256 i = 0; i < _traderVault.subVaults.length; i++) {
            for (uint256 j = 0; j < MAX_PRODUCT_ID; j++) {
                require(_traderVault.subVaults[i].positionPerpetuals[j] == 0);
            }
        }

        // If there are no positions, PositionUSDC is equal to PositionValue.
        if (_traderVault.positionUsdc < 0) {
            _traderVault.isInsolvent = true;
        }
    }

    /**
     * @notice Decreases liquidation reward from usdc position
     * @param _traderVault trader vault object
     * @param _minCollateral min collateral
     * @param _liquidationFee liquidation fee rate
     */
    function decreaseLiquidationReward(
        TraderVault storage _traderVault,
        int256 _minCollateral,
        int256 _liquidationFee
    ) external returns (uint256) {
        if (_traderVault.positionUsdc <= 0) {
            return 0;
        }

        int256 reward = _minCollateral.mul(_liquidationFee).div(1e4);

        reward = Math.min(reward, _traderVault.positionUsdc);

        // reduce margin
        // sub is safe because we know reward is less than positionUsdc
        _traderVault.positionUsdc -= reward.toInt128();

        return reward.toUint256();
    }

    /**
     * @notice Gets min collateral of the vault
     * @param _traderVault trader vault object
     * @param _tradePriceInfo trade price info
     * @return MinCollateral scaled by 1e8
     */
    function getMinCollateral(
        TraderVault memory _traderVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int128[2] memory assetAmounts = getPositionPerpetuals(_traderVault);

        return calculateMinCollateral(assetAmounts, _tradePriceInfo);
    }

    /**
     * @notice Calculates min collateral
     * MinCollateral = alpha*S*(|2*S*(1+fundingSqueeth)*PositionSqueeth + (1+fundingFuture)*PositionFuture| + 2*alpha*S*(1+fundingSqueeth)*|PositionSqueeth|)
     * where alpha is 0.05
     * @param positionPerpetuals amount of perpetual positions
     * @param _tradePriceInfo trade price info
     * @return MinCollateral scaled by 1e8
     */
    function calculateMinCollateral(
        int128[2] memory positionPerpetuals,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        uint256 maxDelta = Math.abs(
            (
                int256(_tradePriceInfo.spotPrice)
                    .mul(_tradePriceInfo.fundingRates[1].add(1e8))
                    .mul(positionPerpetuals[1])
                    .mul(2)
                    .div(1e20)
            ).add(positionPerpetuals[0].mul(_tradePriceInfo.fundingRates[0].add(1e8)).div(1e8))
        );

        maxDelta = maxDelta.add(
            Math.abs(
                int256(RISK_PARAM_FOR_VAULT)
                    .mul(int256(_tradePriceInfo.spotPrice))
                    .mul(_tradePriceInfo.fundingRates[1].add(1e8))
                    .mul(2)
                    .mul(positionPerpetuals[1])
                    .div(1e24)
            )
        );

        uint256 minCollateral = (RISK_PARAM_FOR_VAULT.mul(_tradePriceInfo.spotPrice).mul(maxDelta)) / 1e12;

        if ((positionPerpetuals[0] != 0 || positionPerpetuals[1] != 0) && minCollateral < MIN_MARGIN) {
            minCollateral = MIN_MARGIN;
        }

        return minCollateral.toInt256();
    }

    /**
     * @notice Gets position value in the vault
     * PositionValue = USDC + Σ(ValueOfSubVault_i)
     * @param _traderVault trader vault object
     * @param _tradePriceInfo trade price info
     * @return PositionValue scaled by 1e8
     */
    function getPositionValue(
        TraderVault memory _traderVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int256 value = _traderVault.positionUsdc;

        for (uint256 i = 0; i < _traderVault.subVaults.length; i++) {
            value = value.add(getSubVaultPositionValue(_traderVault.subVaults[i], _tradePriceInfo));
        }

        return value;
    }

    /**
     * @notice Gets position value in the sub-vault
     * ValueOfSubVault = TotalPerpetualValueOfSubVault + TotalFundingFeePaidOfSubVault
     * @param _subVault sub-vault object
     * @param _tradePriceInfo trade price info
     * @return ValueOfSubVault scaled by 1e8
     */
    function getSubVaultPositionValue(
        SubVault memory _subVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        return
            getTotalPerpetualValueOfSubVault(_subVault, _tradePriceInfo).add(
                getTotalFundingFeePaidOfSubVault(_subVault, _tradePriceInfo.amountsFundingPaidPerPosition)
            );
    }

    /**
     * @notice Gets total perpetual value in the sub-vault
     * TotalPerpetualValueOfSubVault = Σ(PerpetualValueOfSubVault_i)
     * @param _subVault sub-vault object
     * @param _tradePriceInfo trade price info
     * @return TotalPerpetualValueOfSubVault scaled by 1e8
     */
    function getTotalPerpetualValueOfSubVault(
        SubVault memory _subVault,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int256 pnl;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            pnl = pnl.add(getPerpetualValueOfSubVault(_subVault, i, _tradePriceInfo));
        }

        return pnl;
    }

    /**
     * @notice Gets perpetual value in the sub-vault
     * PerpetualValueOfSubVault_i = (TradePrice_i - EntryPrice_i)*Position_i
     * @param _subVault sub-vault object
     * @param _productId product id
     * @param _tradePriceInfo trade price info
     * @return PerpetualValueOfSubVault_i scaled by 1e8
     */
    function getPerpetualValueOfSubVault(
        SubVault memory _subVault,
        uint256 _productId,
        IPerpetualMarketCore.TradePriceInfo memory _tradePriceInfo
    ) internal pure returns (int256) {
        int256 pnl = _tradePriceInfo.tradePrices[_productId].sub(_subVault.entryPrices[_productId].toInt256()).mul(
            _subVault.positionPerpetuals[_productId]
        );

        return pnl / 1e8;
    }

    /**
     * @notice Gets total funding fee in the sub-vault
     * TotalFundingFeePaidOfSubVault = Σ(FundingFeePaidOfSubVault_i)
     * @param _subVault sub-vault object
     * @param _amountsFundingPaidPerPosition the cumulative funding fee paid by long per position
     * @return TotalFundingFeePaidOfSubVault scaled by 1e8
     */
    function getTotalFundingFeePaidOfSubVault(
        SubVault memory _subVault,
        int128[2] memory _amountsFundingPaidPerPosition
    ) internal pure returns (int256) {
        int256 fundingFee;

        for (uint256 i = 0; i < MAX_PRODUCT_ID; i++) {
            fundingFee = fundingFee.add(getFundingFeePaidOfSubVault(_subVault, i, _amountsFundingPaidPerPosition));
        }

        return fundingFee;
    }

    /**
     * @notice Gets funding fee in the sub-vault
     * FundingFeePaidOfSubVault_i = Position_i*(EntryFundingFee_i - FundingFeeGlobal_i)
     * @param _subVault sub-vault object
     * @param _productId product id
     * @param _amountsFundingPaidPerPosition cumulative funding fee paid by long per position.
     * @return FundingFeePaidOfSubVault_i scaled by 1e8
     */
    function getFundingFeePaidOfSubVault(
        SubVault memory _subVault,
        uint256 _productId,
        int128[2] memory _amountsFundingPaidPerPosition
    ) internal pure returns (int256) {
        int256 fundingFee = _subVault.entryFundingFee[_productId].sub(_amountsFundingPaidPerPosition[_productId]).mul(
            _subVault.positionPerpetuals[_productId]
        );

        return fundingFee / 1e8;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


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
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
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
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
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
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
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
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../lib/NettingLib.sol";

interface IPerpetualMarketCore {
    struct TradePriceInfo {
        uint128 spotPrice;
        int256[2] tradePrices;
        int256[2] fundingRates;
        int128[2] amountsFundingPaidPerPosition;
    }

    function initialize(
        address _depositor,
        uint256 _depositAmount,
        int256 _initialFundingRate
    ) external returns (uint256 mintAmount);

    function deposit(address _depositor, uint256 _depositAmount) external returns (uint256 mintAmount);

    function withdraw(address _withdrawer, uint256 _withdrawnAmount) external returns (uint256 burnAmount);

    function addLiquidity(uint256 _amount) external;

    function updatePoolPosition(uint256 _productId, int128 _tradeAmount)
        external
        returns (
            uint256 tradePrice,
            int256,
            uint256 protocolFee
        );

    function completeHedgingProcedure(NettingLib.CompleteParams memory _completeParams) external;

    function updatePoolSnapshot() external;

    function executeFundingPayment() external;

    function getTradePriceInfo(int128[2] memory amountAssets) external view returns (TradePriceInfo memory);

    function getTradePrice(uint256 _productId, int128 _tradeAmount)
        external
        view
        returns (
            int256,
            int256,
            int256,
            int256,
            int256
        );

    function rebalance() external;

    function getTokenAmountForHedging() external view returns (NettingLib.CompleteParams memory completeParams);

    function getLPTokenPrice(int256 _deltaLiquidityAmount) external view returns (uint256);
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * Error codes
 * M0: y is too small
 * M1: y is too large
 * M2: possible overflow
 * M3: input should be positive number
 * M4: cannot handle exponents greater than 100
 */
library Math {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /// @dev Min exp
    int256 private constant MIN_EXP = -63 * 1e8;
    /// @dev Max exp
    uint256 private constant MAX_EXP = 100 * 1e8;
    /// @dev ln(2) scaled by 1e8
    uint256 private constant LN_2_E8 = 69314718;

    /**
     * @notice Return the addition of unsigned integer and sigined integer.
     * when y is negative reverting on negative result and when y is positive reverting on overflow.
     */
    function addDelta(uint256 x, int256 y) internal pure returns (uint256 z) {
        if (y < 0) {
            require((z = x - uint256(-y)) < x, "M0");
        } else {
            require((z = x + uint256(y)) >= x, "M1");
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? b : a;
    }

    /**
     * @notice Returns scaled number.
     * Reverts if the scaler is greater than 50.
     */
    function scale(
        uint256 _a,
        uint256 _from,
        uint256 _to
    ) internal pure returns (uint256) {
        if (_from > _to) {
            require(_from - _to < 70, "M2");
            // (_from - _to) is safe because _from > _to.
            // 10**(_from - _to) is safe because it's less than 10**70.
            return _a.div(10**(_from - _to));
        } else if (_from < _to) {
            require(_to - _from < 70, "M2");
            // (_to - _from) is safe because _to > _from.
            // 10**(_to - _from) is safe because it's less than 10**70.
            return _a.mul(10**(_to - _from));
        } else {
            return _a;
        }
    }

    /**
     * @dev Calculates an approximate value of the logarithm of input value by Halley's method.
     */
    function log(uint256 x) internal pure returns (int256) {
        int256 res;
        int256 next;

        for (uint256 i = 0; i < 8; i++) {
            int256 e = int256(exp(res));
            next = res.add((int256(x).sub(e).mul(2)).mul(1e8).div(int256(x).add(e)));
            if (next == res) {
                break;
            }
            res = next;
        }

        return res;
    }

    /**
     * @dev Returns the exponent of the value using Taylor expansion with support for negative numbers.
     */
    function exp(int256 x) internal pure returns (uint256) {
        if (0 <= x) {
            return exp(uint256(x));
        } else if (x < MIN_EXP) {
            // return 0 because `exp(-63) < 1e-27`
            return 0;
        } else {
            return uint256(1e8).mul(1e8).div(exp(uint256(-x)));
        }
    }

    /**
     * @dev Calculates the exponent of the value using Taylor expansion.
     */
    function exp(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return 1e8;
        }
        require(x <= MAX_EXP, "M4");

        uint256 k = floor(x.mul(1e8).div(LN_2_E8)) / 1e8;
        uint256 p = 2**k;
        uint256 r = x.sub(k.mul(LN_2_E8));

        uint256 multiplier = 1e8;

        uint256 lastMultiplier;
        for (uint256 i = 16; i > 0; i--) {
            multiplier = multiplier.mul(r / i).div(1e8).add(1e8);
            if (multiplier == lastMultiplier) {
                break;
            }
            lastMultiplier = multiplier;
        }

        return p.mul(multiplier);
    }

    /**
     * @dev Returns the floor of a 1e8
     */
    function floor(uint256 x) internal pure returns (uint256) {
        return x - (x % 1e8);
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./Math.sol";

/**
 * @title EntryPriceMath
 * @notice Library contract which has functions to calculate new entry price and profit
 * from previous entry price and trade price for implementing margin wallet.
 */
library EntryPriceMath {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /**
     * @notice Calculates new entry price and return profit if position is closed
     *
     * Calculation Patterns
     *  |Position|PositionTrade|NewPosition|Pattern|
     *  |       +|            +|          +|      A|
     *  |       +|            -|          +|      B|
     *  |       +|            -|          -|      C|
     *  |       -|            -|          -|      A|
     *  |       -|            +|          -|      B|
     *  |       -|            +|          +|      C|
     *
     * Calculations
     *  Pattern A (open positions)
     *   NewEntryPrice = (EntryPrice * |Position| + TradePrce * |PositionTrade|) / (Position + PositionTrade)
     *
     *  Pattern B (close positions)
     *   NewEntryPrice = EntryPrice
     *   ProfitValue = -PositionTrade * (TradePrice - EntryPrice)
     *
     *  Pattern C (close all positions & open new)
     *   NewEntryPrice = TradePrice
     *   ProfitValue = Position * (TradePrice - EntryPrice)
     *
     * @param _entryPrice previous entry price
     * @param _position current position
     * @param _tradePrice trade price
     * @param _positionTrade position to trade
     * @return newEntryPrice new entry price
     * @return profitValue notional profit value when positions are closed
     */
    function updateEntryPrice(
        int256 _entryPrice,
        int256 _position,
        int256 _tradePrice,
        int256 _positionTrade
    ) internal pure returns (int256 newEntryPrice, int256 profitValue) {
        int256 newPosition = _position.add(_positionTrade);
        if (_position == 0 || (_position > 0 && _positionTrade > 0) || (_position < 0 && _positionTrade < 0)) {
            newEntryPrice = (
                _entryPrice.mul(int256(Math.abs(_position))).add(_tradePrice.mul(int256(Math.abs(_positionTrade))))
            ).div(int256(Math.abs(_position.add(_positionTrade))));
        } else if (
            (_position > 0 && _positionTrade < 0 && newPosition > 0) ||
            (_position < 0 && _positionTrade > 0 && newPosition < 0)
        ) {
            newEntryPrice = _entryPrice;
            profitValue = (-_positionTrade).mul(_tradePrice.sub(_entryPrice)) / 1e8;
        } else {
            if (newPosition != 0) {
                newEntryPrice = _tradePrice;
            }

            profitValue = _position.mul(_tradePrice.sub(_entryPrice)) / 1e8;
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./Math.sol";

/**
 * @title NettingLib
 * Error codes
 * N0: Unknown product id
 * N1: Total delta must be greater than 0
 * N2: No enough USDC
 */
library NettingLib {
    using SafeCast for int256;
    using SafeCast for uint128;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SignedSafeMath for int256;
    using SignedSafeMath for int128;

    struct AddMarginParams {
        int256 delta0;
        int256 delta1;
        int256 gamma1;
        int256 spotPrice;
        int256 poolMarginRiskParam;
    }

    struct CompleteParams {
        uint256 amountUsdc;
        uint256 amountUnderlying;
        int256[2] amountsRequiredUnderlying;
        bool isLong;
    }

    struct Info {
        uint128 amountAaveCollateral;
        uint128[2] amountsUsdc;
        int128[2] amountsUnderlying;
    }

    /**
     * @notice Adds required margin for delta hedging
     */
    function addMargin(
        Info storage _info,
        uint256 _productId,
        AddMarginParams memory _params
    ) internal returns (int256 requiredMargin, int256 hedgePositionValue) {
        int256 totalRequiredMargin = getRequiredMargin(_productId, _params);

        hedgePositionValue = getHedgePositionValue(_info, _params.spotPrice, _productId);

        requiredMargin = totalRequiredMargin.sub(hedgePositionValue);

        if (_info.amountsUsdc[_productId].toInt256().add(requiredMargin) < 0) {
            requiredMargin = -_info.amountsUsdc[_productId].toInt256();
        }

        _info.amountsUsdc[_productId] = Math.addDelta(_info.amountsUsdc[_productId], requiredMargin).toUint128();
    }

    function getRequiredTokenAmountsForHedge(
        int128[2] memory _amountsUnderlying,
        int256[2] memory _deltas,
        int256 _spotPrice
    ) internal pure returns (CompleteParams memory completeParams) {
        completeParams.amountsRequiredUnderlying[0] = -_amountsUnderlying[0] - _deltas[0];
        completeParams.amountsRequiredUnderlying[1] = -_amountsUnderlying[1] - _deltas[1];

        int256 totalUnderlyingPosition = getTotalUnderlyingPosition(_amountsUnderlying);

        // 1. Calculate required amount of underlying token
        int256 requiredUnderlyingAmount;
        {
            // required amount is -(net delta)
            requiredUnderlyingAmount = -_deltas[0].add(_deltas[1]).add(totalUnderlyingPosition);

            if (_deltas[0].add(_deltas[1]) > 0) {
                // if pool delta is positive
                requiredUnderlyingAmount = -totalUnderlyingPosition;

                completeParams.amountsRequiredUnderlying[0] = -_amountsUnderlying[0] + _deltas[1];
            }

            completeParams.isLong = requiredUnderlyingAmount > 0;
        }

        // 2. Calculate USDC and ETH amounts.
        completeParams.amountUnderlying = Math.abs(requiredUnderlyingAmount);
        completeParams.amountUsdc = (Math.abs(requiredUnderlyingAmount).mul(uint256(_spotPrice))) / 1e8;

        return completeParams;
    }

    /**
     * @notice Completes delta hedging procedure
     * Calculate holding amount of Underlying and USDC after a hedge.
     */
    function complete(Info storage _info, CompleteParams memory _params) internal {
        uint256 totalUnderlying = Math.abs(_params.amountsRequiredUnderlying[0]).add(
            Math.abs(_params.amountsRequiredUnderlying[1])
        );

        require(totalUnderlying > 0, "N1");

        for (uint256 i = 0; i < 2; i++) {
            _info.amountsUnderlying[i] = _info
                .amountsUnderlying[i]
                .add(_params.amountsRequiredUnderlying[i])
                .toInt128();

            {
                uint256 deltaUsdcAmount = (_params.amountUsdc.mul(Math.abs(_params.amountsRequiredUnderlying[i]))).div(
                    totalUnderlying
                );

                if (_params.isLong) {
                    require(_info.amountsUsdc[i] >= deltaUsdcAmount, "N2");
                    _info.amountsUsdc[i] = _info.amountsUsdc[i].sub(deltaUsdcAmount).toUint128();
                } else {
                    _info.amountsUsdc[i] = _info.amountsUsdc[i].add(deltaUsdcAmount).toUint128();
                }
            }
        }
    }

    /**
     * @notice Gets required margin
     * @param _productId Id of product to get required margin
     * @param _params parameters to calculate required margin
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMargin(uint256 _productId, AddMarginParams memory _params) internal pure returns (int256) {
        int256 weightedDelta = calculateWeightedDelta(_productId, _params.delta0, _params.delta1);

        if (_productId == 0) {
            return getRequiredMarginOfFuture(_params, weightedDelta);
        } else if (_productId == 1) {
            return getRequiredMarginOfSqueeth(_params, weightedDelta);
        } else {
            revert("N0");
        }
    }

    /**
     * @notice Gets required margin for future
     * RequiredMargin_{future} = (1+α)*S*|WeightedDelta|
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMarginOfFuture(AddMarginParams memory _params, int256 _weightedDelta)
        internal
        pure
        returns (int256)
    {
        int256 requiredMargin = (_params.spotPrice.mul(Math.abs(_weightedDelta).toInt256())) / 1e8;
        return ((1e4 + _params.poolMarginRiskParam).mul(requiredMargin)) / 1e4;
    }

    /**
     * @notice Gets required margin for squeeth
     * RequiredMargin_{squeeth}
     * = max((1-α) * S * |WeightDelta_{sqeeth}-α * S * gamma|, (1+α) * S * |WeightDelta_{sqeeth}+α * S * gamma|)
     * @return RequiredMargin scaled by 1e8
     */
    function getRequiredMarginOfSqueeth(AddMarginParams memory _params, int256 _weightedDelta)
        internal
        pure
        returns (int256)
    {
        int256 deltaFromGamma = (_params.poolMarginRiskParam.mul(_params.spotPrice).mul(_params.gamma1)) / 1e12;

        return
            Math.max(
                (
                    (1e4 - _params.poolMarginRiskParam).mul(_params.spotPrice).mul(
                        Math.abs(_weightedDelta.sub(deltaFromGamma)).toInt256()
                    )
                ) / 1e12,
                (
                    (1e4 + _params.poolMarginRiskParam).mul(_params.spotPrice).mul(
                        Math.abs(_weightedDelta.add(deltaFromGamma)).toInt256()
                    )
                ) / 1e12
            );
    }

    /**
     * @notice Gets notional value of hedge positions
     * HedgePositionValue_i = AmountsUsdc_i+AmountsUnderlying_i*S
     * @return HedgePositionValue scaled by 1e8
     */
    function getHedgePositionValue(
        Info memory _info,
        int256 _spot,
        uint256 _productId
    ) internal pure returns (int256) {
        int256 hedgeNotional = _spot.mul(_info.amountsUnderlying[_productId]) / 1e8;

        return _info.amountsUsdc[_productId].toInt256().add(hedgeNotional);
    }

    /**
     * @notice Gets total underlying position
     * TotalUnderlyingPosition = ΣAmountsUnderlying_i
     */
    function getTotalUnderlyingPosition(int128[2] memory _amountsUnderlying)
        internal
        pure
        returns (int256 underlyingPosition)
    {
        for (uint256 i = 0; i < 2; i++) {
            underlyingPosition = underlyingPosition.add(_amountsUnderlying[i]);
        }

        return underlyingPosition;
    }

    /**
     * @notice Calculates weighted delta
     * WeightedDelta = delta_i * (Σdelta_i) / (Σ|delta_i|)
     * @return weighted delta scaled by 1e8
     */
    function calculateWeightedDelta(
        uint256 _productId,
        int256 _delta0,
        int256 _delta1
    ) internal pure returns (int256) {
        int256 netDelta = _delta0.add(_delta1);
        int256 totalDelta = (Math.abs(_delta0).add(Math.abs(_delta1))).toInt256();

        require(totalDelta >= 0, "N1");

        if (totalDelta == 0) {
            return 0;
        }

        if (_productId == 0) {
            return (Math.abs(_delta0).toInt256().mul(netDelta)).div(totalDelta);
        } else if (_productId == 1) {
            return (Math.abs(_delta1).toInt256().mul(netDelta)).div(totalDelta);
        } else {
            revert("N0");
        }
    }
}