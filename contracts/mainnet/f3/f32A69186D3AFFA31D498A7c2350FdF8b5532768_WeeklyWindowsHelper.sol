// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/* https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol */
library DateTime {
  uint256 public constant SECONDS_PER_HOUR = 60 * 60;
  uint256 public constant SECONDS_PER_DAY = SECONDS_PER_HOUR * 24;
  int256 public constant OFFSET19700101 = 2440588;

  /// @notice 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }

  /// @notice 0...23
  function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  /// @notice 1 = Monday, 7 = Sunday
  function validateDayOfWeek(uint8 dayOfWeek) internal pure {
    require(dayOfWeek > 0 && dayOfWeek < 8, "invalid day of week");
  }

  /// @notice 0...23
  function validateHour(uint8 hour) internal pure {
    require(hour < 24, "invalid hour");
  }

  function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
    require(year >= 1970, "1970 and later only");
    int256 _year = int256(year);
    int256 _month = int256(month);
    int256 _day = int256(day);

    int256 __days = _day -
      32075 +
      (1461 * (_year + 4800 + (_month - 14) / 12)) /
      4 +
      (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
      12 -
      (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
      4 -
      OFFSET19700101;

    _days = uint256(__days);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library SynthetixV3Structs {
  struct VaultSetting {
    address poolLogic;
    address collateralAsset;
    address debtAsset;
    uint128 snxLiquidityPoolId;
  }

  /// @dev Couldn't find a way to get a mapping from synthAddress to its markedId, so storing it in guard's storage
  /// @dev Was looking for something like getSynth() but reversed
  struct AllowedMarket {
    uint128 marketId;
    address collateralSynth;
    address collateralAsset;
  }

  struct TimePeriod {
    uint8 dayOfWeek;
    uint8 hour;
  }

  struct Window {
    TimePeriod start;
    TimePeriod end;
  }

  struct WeeklyWindows {
    Window delegationWindow;
    Window undelegationWindow;
  }

  struct WeeklyWithdrawalLimit {
    uint256 usdValue;
    uint256 percent;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../../utils/synthetixV3/libraries/SynthetixV3Structs.sol";
import "../../../utils/DateTime.sol";

library WeeklyWindowsHelper {
  using DateTime for uint8;
  using DateTime for uint256;

  /// @notice Helper function to check if the timestamp is within allowed window
  /// @param _window Window of interest
  /// @param _timestamp Timestamp of interest
  /// @return isWithinAllowedWindow If the timestamp is within allowed window
  function isWithinAllowedWindow(
    SynthetixV3Structs.Window calldata _window,
    uint256 _timestamp
  ) external pure returns (bool) {
    uint256 currentDayOfWeek = _timestamp.getDayOfWeek();
    uint256 currentHour = _timestamp.getHour();

    if (currentDayOfWeek < _window.start.dayOfWeek || currentDayOfWeek > _window.end.dayOfWeek) {
      return false;
    }

    if (currentDayOfWeek == _window.start.dayOfWeek && currentHour < _window.start.hour) {
      return false;
    }

    if (currentDayOfWeek == _window.end.dayOfWeek && currentHour > _window.end.hour) {
      return false;
    }

    return true;
  }

  /// @notice Helper function to validate windows
  /// @param _windows Windows of interest
  function validateWindows(SynthetixV3Structs.WeeklyWindows memory _windows) external pure {
    _validateWindow(_windows.delegationWindow);
    _validateWindow(_windows.undelegationWindow);
  }

  /// @notice Helper function to validate window
  /// @param _window Window of interest
  function _validateWindow(SynthetixV3Structs.Window memory _window) internal pure {
    _validateTimePeriod(_window.start);
    _validateTimePeriod(_window.end);
  }

  /// @notice Helper function to validate time period
  /// @param _timePeriod Time period of interest
  function _validateTimePeriod(SynthetixV3Structs.TimePeriod memory _timePeriod) internal pure {
    _timePeriod.dayOfWeek.validateDayOfWeek();
    _timePeriod.hour.validateHour();
  }
}