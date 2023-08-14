/**
 *Submitted for verification at Arbiscan on 2023-08-14
*/

// SPDX-License-Identifier: MIT

/*
   __  __      ____                 __ 
  / / / /___  / __/________  ____  / /_
 / / / / __ \/ /_/ ___/ __ \/ __ \/ __/
/ /_/ / /_/ / __/ /  / /_/ / / / / /_  
\____/ .___/_/ /_/   \____/_/ /_/\__/  
    /_/                                

  Unixtime Utils

  Authors: <dotfx>
  Date: 2023/08/14
  Version: 1.0.0
*/

pragma solidity >=0.8.18 <0.9.0;

contract UnixtimeUtils {
  function isLeapYear(uint256 year) public pure returns (bool) {
    unchecked {
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
    }
  }

  function getDaysInMonth(uint256 month, uint256 year) public pure returns (uint8) {
    if (month == 2) { return isLeapYear(year) ? 29 : 28; }
    if (month == 4 || month == 6 || month == 9 || month == 11) { return 30; }

    return 31;
  }

  function getDayOfMonth(uint256 unixtime) public pure returns (uint8) {
    uint256 year = 1970;
    uint256 secondsInDay = 86400;
    uint256 totalDays = unixtime / secondsInDay;

    unchecked {
      while (true) {
        uint256 daysInCurrentYear = isLeapYear(year) ? 366 : 365;

        if (totalDays < daysInCurrentYear) { break; }

        totalDays -= daysInCurrentYear;
        year++;
      }

      uint256 month = 1;

      while (true) {
        uint8 daysInMonth = getDaysInMonth(month, year);

        if (totalDays < daysInMonth) { break; }

        totalDays -= daysInMonth;
        month++;
      }

      return uint8(totalDays) + 1;
    }
  }
}