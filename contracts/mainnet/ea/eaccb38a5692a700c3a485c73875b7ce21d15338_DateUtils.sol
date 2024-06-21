/**
 *Submitted for verification at Arbiscan.io on 2024-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.12;

library DateUtils {
    // The number of seconds per day
    uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;

    // The number of seconds per hour
    uint256 internal constant SECONDS_PER_HOUR = 60 * 60;

    // The number of seconds per minute
    uint256 internal constant SECONDS_PER_MINUTE = 60;

    // The offset from 01/01/1970
    int256 internal constant OFFSET19700101 = 2440588;

    function timestampToDate(uint256 ts) public pure returns (uint256 year, uint256 month, uint256 day) {
        (year, month, day) = _daysToDate(ts / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function timestampFromDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }

    /**
     * @notice Calculate year/month/day from the number of days since 1970/01/01 using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and adding the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param _days The year
     * @return year The year
     * @return month The month
     * @return day The day
     */
    function _daysToDate (uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        int256 __days = int256(_days);

        int256 x = __days + 68569 + OFFSET19700101;
        int256 n = 4 * x / 146097;
        x = x - (146097 * n + 3) / 4;
        int256 _year = 4000 * (x + 1) / 1461001;
        x = x - 1461 * _year / 4 + 31;
        int256 _month = 80 * x / 2447;
        int256 _day = x - 2447 * _month / 80;
        x = _month / 11;
        _month = _month + 2 - 12 * x;
        _year = 100 * (n - 49) + _year + x;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    /**
     * @notice Calculates the number of days from 1970/01/01 to year/month/day using the date conversion algorithm from http://aa.usno.navy.mil/faq/docs/JD_Formula.php and subtracting the offset 2440588 so that 1970/01/01 is day 0
     * @dev Taken from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
     * @param year The year
     * @param month The month
     * @param day The day
     * @return _days Returns the number of days
     */
    function _daysFromDate (uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970, "Error");
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint256(__days);
    }
}