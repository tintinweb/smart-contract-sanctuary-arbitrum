// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CreationWindowCommodity {
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
        return (timestamp - (3 * 86400) - (23 * 3600)) / 604800;
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
            // check if trading is closed from 9PM to 10PM UTC daily
            uint256 endHour = (endTime / 3600) % 24;
            uint256 startHour = (currentTime / 3600) % 24;
            if (
                endHour == 21 ||
                startHour == 21 ||
                (endHour == 22 && period > 59 * 60)
            ) {
                return false;
            }
            return true;
        }
        return false;
    }
}