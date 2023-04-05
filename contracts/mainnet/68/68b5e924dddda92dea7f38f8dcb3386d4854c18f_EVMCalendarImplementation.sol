/**
 *Submitted for verification at Arbiscan on 2023-04-05
*/

// SPDX-License-Identifier: MIT
// @author EVMlord => https://EVMlord.dev
// All times are in UTC

pragma solidity ^0.8.19;

interface IEVMCalendar {
    // @dev Converts timestamp to date string in YYYY-MM-DD HH:MM:SS format
    function convertTimestamp(uint256 unixTimestamp)
        external
        pure
        returns (string memory);

    function countdown(uint256 endTimestamp)
        external
        view
        returns (string memory);

    // @dev Returns current time in HH:MM:SS format
    function checkTimeUTC() external view returns (string memory);

    function checkDateUTC() external view returns (string memory);

    function getCurrentDateAndTimeUTC() external view returns (string memory);
}

contract EVMCalendarImplementation {
    IEVMCalendar EVMSQL;

    constructor(IEVMCalendar _EVMSQL) {
        EVMSQL = _EVMSQL;
    }

    function convertTimestamp(uint256 unixTimestamp)
        external
        view
        returns (string memory)
    {
        return EVMSQL.convertTimestamp(unixTimestamp);
    }

    function countdown(uint256 endTimestamp)
        external
        view
        returns (string memory)
    {
        return EVMSQL.countdown(endTimestamp);
    }

    function checkTimeUTC() external view returns (string memory) {
        return EVMSQL.checkTimeUTC();
    }

    function checkDateUTC() external view returns (string memory) {
        return EVMSQL.checkDateUTC();
    }

    function getCurrentDateAndTimeUTC() external view returns (string memory) {
        return EVMSQL.getCurrentDateAndTimeUTC();
    }
}