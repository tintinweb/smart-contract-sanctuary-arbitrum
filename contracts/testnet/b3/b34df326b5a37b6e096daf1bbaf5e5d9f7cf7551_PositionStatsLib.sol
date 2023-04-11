// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

/* ========== STRUCTS ========== */

/**
 * @notice Struct to store statistical information about all positions
 * @custom:member totalLongMargin total amount of margin for long positions
 * @custom:member totalLongVolume total volume for long positions
 * @custom:member totalLongAssetAmount total amount of size for long positions
 * @custom:member totalShortMargin total amount of margin for short positions
 * @custom:member totalShortVolume total volume for short positions
 * @custom:member totalShortAssetAmount total amount of size for short positions
 */
struct PositionStats {
    uint256 totalLongMargin;
    uint256 totalLongVolume;
    uint256 totalLongAssetAmount;
    uint256 totalShortMargin;
    uint256 totalShortVolume;
    uint256 totalShortAssetAmount;
}

/**
 * @title PositionStats
 * @notice Provides data structures and functions for Aggregated positions statistics at TradePair
 * @dev This contract is a library and should be used by a contract that implements the ITradePair interface
 * Provides methods to keep track of total volume, margin and volume for long and short positions
 */
library PositionStatsLib {
    uint256 constant PERCENTAGE_MULTIPLIER = 1_000_000;

    /* =========== EXTERNAL FUNCTIONS =========== */

    /**
     * @notice add total margin, volume and size
     * @param margin the margin to add
     * @param volume the volume to add
     * @param size the size to add
     * @param isShort bool if the data belongs to a short position
     */
    function addTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
        public
    {
        _self._addTotalCount(margin, volume, size, isShort);
    }

    /**
     * @notice remove total margin, volume and size
     * @param margin the margin to remove
     * @param volume the volume to remove
     * @param size the size to remove
     * @param isShort bool if the data belongs to a short position
     */
    function removeTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
        public
    {
        _self._removeTotalCount(margin, volume, size, isShort);
    }

    /**
     * @notice add total margin, volume and size
     * @param margin the margin to add
     * @param volume the volume to add
     * @param size the size to add
     * @param isShort bool if the data belongs to a short position
     */
    function _addTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
        internal
    {
        if (isShort) {
            _self.totalShortMargin += margin;
            _self.totalShortVolume += volume;
            _self.totalShortAssetAmount += size;
        } else {
            _self.totalLongMargin += margin;
            _self.totalLongVolume += volume;
            _self.totalLongAssetAmount += size;
        }
    }

    /**
     * @notice remove total margin, volume and size
     * @param margin the margin to remove
     * @param volume the volume to remove
     * @param size the size to remove
     * @param isShort bool if the data belongs to a short position
     */
    function _removeTotalCount(PositionStats storage _self, uint256 margin, uint256 volume, uint256 size, bool isShort)
        internal
    {
        if (isShort) {
            _self.totalShortMargin -= margin;
            _self.totalShortVolume -= volume;
            _self.totalShortAssetAmount -= size;
        } else {
            _self.totalLongMargin -= margin;
            _self.totalLongVolume -= volume;
            _self.totalLongAssetAmount -= size;
        }
    }
}

using PositionStatsLib for PositionStats;