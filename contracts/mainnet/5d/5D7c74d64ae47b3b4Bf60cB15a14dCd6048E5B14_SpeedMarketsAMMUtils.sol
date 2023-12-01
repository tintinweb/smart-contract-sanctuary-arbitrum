// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title An AMM utils for Thales speed markets
contract SpeedMarketsAMMUtils {
    uint private constant SECONDS_PER_MINUTE = 60;

    /// @notice get dynamic fee based on defined time thresholds for a given delta time
    /// @param _deltaTimeSec to search for appropriate time range (in seconds)
    /// @param _timeThresholds array of time thresholds for each fee (in minutes)
    /// @param _fees array of fees for every time range
    /// @param _defaultFee if _deltaTime doesn't have appropriate time range return this value
    /// @return fee defined for specific time range to which _deltaTime belongs to
    function getFeeByTimeThreshold(
        uint64 _deltaTimeSec,
        uint[] calldata _timeThresholds,
        uint[] calldata _fees,
        uint _defaultFee
    ) external pure returns (uint fee) {
        fee = _defaultFee;
        uint _deltaTime = _deltaTimeSec / SECONDS_PER_MINUTE;
        for (uint i = _timeThresholds.length; i > 0; i--) {
            if (_deltaTime >= _timeThresholds[i - 1]) {
                fee = _fees[i - 1];
                break;
            }
        }
    }
}