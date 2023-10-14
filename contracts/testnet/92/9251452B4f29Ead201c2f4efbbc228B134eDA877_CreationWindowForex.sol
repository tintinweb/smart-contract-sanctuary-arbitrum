// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CreationWindowForex {
    function isInCreationWindow(uint256 period) external view returns (bool) {
        uint256 currentTime = block.timestamp;
        uint256 endTime = currentTime + period;
        uint256 dayId = ((currentTime / 86400) + 4) % 7;

        if (
            dayId < 6 && dayId > 0 // check if it's a weekday
        ) {
            uint256 startHour = (currentTime / 3600) % 24;
            uint256 startMinute = (currentTime / 60) % 60;
            uint256 endHour = (endTime / 3600) % 24;
            uint256 endMinute = (endTime / 60) % 60;
            if (
                startHour >= 6 &&
                startHour < 16 &&
                endHour >= 6 &&
                endHour < 16 &&
                (startHour < endHour ||
                    (startHour == endHour && startMinute < endMinute))
            ) {
                return true;
            }
        }
        return false;
    }
}