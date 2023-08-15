/**
 *Submitted for verification at Arbiscan on 2023-08-14
*/

// SPDX-License-Identifier: GNU LGPLv3

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// ----------------------------------------------------------------------------

pragma solidity >=0.8.18 <0.9.0;

contract DateTimeContract {
  uint constant SECONDS_PER_DAY = 24*60*60;
  uint constant SECONDS_PER_HOUR = 60*60;
  uint constant SECONDS_PER_MINUTE = 60;
  int constant OFFSET19700101 = 2440588;

  uint constant DOW_MON = 1;
  uint constant DOW_TUE = 2;
  uint constant DOW_WED = 3;
  uint constant DOW_THU = 4;
  uint constant DOW_FRI = 5;
  uint constant DOW_SAT = 6;
  uint constant DOW_SUN = 7;

  function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
    require(year >= 1970);

    int _year = int(year);
    int _month = int(month);
    int _day = int(day);

    unchecked {
      int __days = _day - 32075 + 1461 * (_year + 4800 + (_month - 14) / 12) / 4 + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12 - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4 - OFFSET19700101;

      _days = uint(__days);
    }
  }

  function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
    int __days = int(_days);

    unchecked {
      int L = __days + 68569 + OFFSET19700101;
      int N = 4 * L / 146097;
      L = L - (146097 * N + 3) / 4;
      int _year = 4000 * (L + 1) / 1461001;
      L = L - 1461 * _year / 4 + 31;
      int _month = 80 * L / 2447;
      int _day = L - 2447 * _month / 80;
      L = _month / 11;
      _month = _month + 2 - 12 * L;
      _year = 100 * (N - 49) + _year + L;

      year = uint(_year);
      month = uint(_month);
      day = uint(_day);
    }
  }

  function timestampFromDate(uint year, uint month, uint day) public pure returns (uint timestamp) {
    unchecked {
      timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
  }

  function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (uint timestamp) {
    unchecked {
      timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
  }

  function timestampToDate(uint timestamp) public pure returns (uint year, uint month, uint day) {
    unchecked {
      (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
  }

  function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
    unchecked {
      (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);

      uint secs = timestamp % SECONDS_PER_DAY;
      hour = secs / SECONDS_PER_HOUR;
      secs = secs % SECONDS_PER_HOUR;
      minute = secs / SECONDS_PER_MINUTE;
      second = secs % SECONDS_PER_MINUTE;
    }
  }

  function isValidDate(uint year, uint month, uint day) public pure returns (bool valid) {
    if (year >= 1970 && month > 0 && month <= 12) {
      uint daysInMonth = _getDaysInMonth(year, month);

      if (day > 0 && day <= daysInMonth) { valid = true; }
    }
  }

  function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (bool valid) {
    if (isValidDate(year, month, day)) {
      if (hour < 24 && minute < 60 && second < 60) { valid = true; }
    }
  }

  function isLeapYear(uint timestamp) public pure returns (bool leapYear) {
    unchecked {
      (uint year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);

      leapYear = _isLeapYear(year);
    }
  }

  function _isLeapYear(uint year) internal pure returns (bool leapYear) {
    unchecked {
      leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
  }

  function isWeekDay(uint timestamp) public pure returns (bool weekDay) {
    weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
  }

  function isWeekEnd(uint timestamp) public pure returns (bool weekEnd) {
    weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
  }

  function getDaysInMonth(uint timestamp) public pure returns (uint daysInMonth) {
    (uint year, uint month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);

    daysInMonth = _getDaysInMonth(year, month);
  }

  function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      daysInMonth = 31;
    } else if (month != 2) {
      daysInMonth = 30;
    } else {
      daysInMonth = _isLeapYear(year) ? 29 : 28;
    }
  }

  function getDayOfWeek(uint timestamp) public pure returns (uint dayOfWeek) {
    unchecked {
      uint _days = timestamp / SECONDS_PER_DAY;

      dayOfWeek = (_days + 3) % 7 + 1;
    }
  }

  function getYear(uint timestamp) public pure returns (uint) {
    unchecked {
      (uint year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);

      return year;
    }
  }

  function getMonth(uint timestamp) public pure returns (uint) {
    unchecked {
      (, uint month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);

      return month;
    }
  }

  function getDay(uint timestamp) public pure returns (uint) {
    unchecked {
      (, , uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);

      return day;
    }
  }

  function getHour(uint timestamp) public pure returns (uint hour) {
    unchecked {
      uint secs = timestamp % SECONDS_PER_DAY;
      hour = secs / SECONDS_PER_HOUR;
    }
  }

  function getMinute(uint timestamp) public pure returns (uint minute) {
    unchecked {
      uint secs = timestamp % SECONDS_PER_HOUR;
      minute = secs / SECONDS_PER_MINUTE;
    }
  }

  function getSecond(uint timestamp) public pure returns (uint second) {
    unchecked {
      second = timestamp % SECONDS_PER_MINUTE;
    }
  }

  function addYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
    unchecked {
      (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);

      year += _years;
      uint daysInMonth = _getDaysInMonth(year, month);

      if (day > daysInMonth) { day = daysInMonth; }

      newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;

      require(newTimestamp >= timestamp);
    }
  }

  function addMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
    unchecked {
      (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);

      month += _months;
      year += (month - 1) / 12;
      month = (month - 1) % 12 + 1;
      uint daysInMonth = _getDaysInMonth(year, month);

      if (day > daysInMonth) { day = daysInMonth; }

      newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;

      require(newTimestamp >= timestamp);
    }
  }

  function addDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
    unchecked {
      newTimestamp = timestamp + _days * SECONDS_PER_DAY;

      require(newTimestamp >= timestamp);
    }
  }

  function addHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
    unchecked {
      newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;

      require(newTimestamp >= timestamp);
    }
  }

  function addMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
    unchecked {
      newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;

      require(newTimestamp >= timestamp);
    }
  }

  function addSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
    unchecked {
      newTimestamp = timestamp + _seconds;

      require(newTimestamp >= timestamp);
    }
  }

  function subYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
    unchecked {
      (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);

      year -= _years;
      uint daysInMonth = _getDaysInMonth(year, month);

      if (day > daysInMonth) { day = daysInMonth; }

      newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;

      require(newTimestamp <= timestamp);
    }
  }

  function subMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
    unchecked {
      (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);

      uint yearMonth = year * 12 + (month - 1) - _months;
      year = yearMonth / 12;
      month = yearMonth % 12 + 1;
      uint daysInMonth = _getDaysInMonth(year, month);

      if (day > daysInMonth) { day = daysInMonth; }

      newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;

      require(newTimestamp <= timestamp);
    }
  }

  function subDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
    unchecked {
      newTimestamp = timestamp - _days * SECONDS_PER_DAY;

      require(newTimestamp <= timestamp);
    }
  }

  function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
    unchecked {
      newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;

      require(newTimestamp <= timestamp);
    }
  }

  function subMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
    unchecked {
      newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;

      require(newTimestamp <= timestamp);
    }
  }

  function subSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
    unchecked {
      newTimestamp = timestamp - _seconds;

      require(newTimestamp <= timestamp);
    }
  }

  function diffYears(uint fromTimestamp, uint toTimestamp) public pure returns (uint _years) {
    require(fromTimestamp <= toTimestamp);

    unchecked {
      (uint fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
      (uint toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);

      _years = toYear - fromYear;
    }
  }

  function diffMonths(uint fromTimestamp, uint toTimestamp) public pure returns (uint _months) {
    require(fromTimestamp <= toTimestamp);

    unchecked {
      (uint fromYear, uint fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
      (uint toYear, uint toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);

      _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
  }

  function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
    require(fromTimestamp <= toTimestamp);

    unchecked {
      _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
  }

  function diffHours(uint fromTimestamp, uint toTimestamp) public pure returns (uint _hours) {
    require(fromTimestamp <= toTimestamp);

    unchecked {
      _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
  }

  function diffMinutes(uint fromTimestamp, uint toTimestamp) public pure returns (uint _minutes) {
    require(fromTimestamp <= toTimestamp);

    unchecked {
      _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
  }

  function diffSeconds(uint fromTimestamp, uint toTimestamp) public pure returns (uint _seconds) {
    require(fromTimestamp <= toTimestamp);

    unchecked {
      _seconds = toTimestamp - fromTimestamp;
    }
  }
}