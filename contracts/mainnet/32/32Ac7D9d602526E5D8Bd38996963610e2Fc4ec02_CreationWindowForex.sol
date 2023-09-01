// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CreationWindowForex {
    struct TradingHours {
        uint256 weekId; // week id
        uint256 start; // start time in seconds for the week start
        uint256 end; // end time in seconds for the week start
    }

    TradingHours public marketHours;

    constructor(uint256 _start, uint256 _end) {
        marketHours = TradingHours({
            weekId: getWeekId(_start),
            start: _start,
            end: _end
        });
    }

    function getWeekId(uint256 timestamp) public pure returns (uint256) {
        return (timestamp - (3 * 86400) - (22 * 3600)) / 604800;
    }

    function isInCreationWindow(uint256 period) external view returns (bool) {
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + period;
        uint256 weekId = getWeekId(currentTime);

        uint256 currentWeekStartTime = marketHours.start +
            ((weekId - marketHours.weekId) * 604800);
        uint256 currentWeekEndTime = marketHours.end +
            ((weekId - marketHours.weekId) * 604800);

        if (
            currentTime >= currentWeekStartTime && endTime < currentWeekEndTime
        ) {
            return true;
        }
        return false;
    }
}