// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';

// solhint-disable
contract OracleForTest is IBaseOracle, IDelayedOracle {
  uint256 price;
  bool validity = true;
  bool throwsError;
  string public symbol;

  constructor(uint256 _price) {
    price = _price;
  }

  function getResultWithValidity() external view returns (uint256 _price, bool _validity) {
    _checkThrowsError();
    _price = price;
    _validity = validity;
  }

  function setPriceAndValidity(uint256 _price, bool _validity) public virtual {
    price = _price;
    validity = _validity;
  }

  function priceSource() external view returns (IBaseOracle) {
    _checkThrowsError();
    return IBaseOracle(address(this));
  }

  function read() external view returns (uint256 _value) {
    return price;
  }

  function setThrowsError(bool _throwError) public virtual {
    throwsError = _throwError;
  }

  function _checkThrowsError() internal view {
    if (throwsError) {
      revert();
    }
  }

  // --- IDelayedOracle ---

  function getNextResultWithValidity() external view returns (uint256 _result, bool _validity) {
    return (price, validity);
  }

  function lastUpdateTime() external view returns (uint256 _lastUpdateTime) {
    return block.timestamp;
  }

  function shouldUpdate() external pure returns (bool _ok) {
    return true;
  }

  function updateDelay() external pure returns (uint256 _updateDelay) {
    return 0;
  }

  function updateResult() external pure returns (bool _success) {
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

/**
 * @title IBaseOracle
 * @notice Basic interface for a system price feed
 *         All price feeds should be translated into an 18 decimals format
 */
interface IBaseOracle {
  // --- Errors ---
  error InvalidPriceFeed();

  /**
   * @notice Symbol of the quote: token / baseToken (e.g. 'ETH / USD')
   */
  function symbol() external view returns (string memory _symbol);

  /**
   * @notice Fetch the latest oracle result and whether it is valid or not
   * @dev    This method should never revert
   */
  function getResultWithValidity() external view returns (uint256 _result, bool _validity);

  /**
   * @notice Fetch the latest oracle result
   * @dev    Will revert if is the price feed is invalid
   */
  function read() external view returns (uint256 _value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

interface IDelayedOracle is IBaseOracle {
  // --- Events ---

  /**
   * @notice Emitted when the oracle is updated
   * @param _newMedian The new median value
   * @param _lastUpdateTime The timestamp of the update
   */
  event UpdateResult(uint256 _newMedian, uint256 _lastUpdateTime);

  // --- Errors ---

  /// @notice Throws if the provided price source address is null
  error DelayedOracle_NullPriceSource();
  /// @notice Throws if the provided delay is null
  error DelayedOracle_NullDelay();
  /// @notice Throws when trying to update the oracle before the delay has elapsed
  error DelayedOracle_DelayHasNotElapsed();
  /// @notice Throws when trying to read the current value and it is invalid
  error DelayedOracle_NoCurrentValue();

  // --- Structs ---

  struct Feed {
    // The value of the price feed
    uint256 /* WAD */ value;
    // Whether the value is valid or not
    bool /* bool   */ isValid;
  }

  /**
   * @notice Address of the non-delayed price source
   * @dev    Assumes that the price source is a valid IBaseOracle
   */
  function priceSource() external view returns (IBaseOracle _priceSource);

  /**
   * @notice The next valid price feed, taking effect at the next updateResult call
   * @return _result The value in 18 decimals format of the next price feed
   * @return _validity Whether the next price feed is valid or not
   */
  function getNextResultWithValidity() external view returns (uint256 _result, bool _validity);

  /// @notice The delay in seconds that should elapse between updates
  function updateDelay() external view returns (uint256 _updateDelay);

  /// @notice The timestamp of the last update
  function lastUpdateTime() external view returns (uint256 _lastUpdateTime);

  /**
   * @notice Indicates if a delay has passed since the last update
   * @return _ok Whether the oracle should be updated or not
   */
  function shouldUpdate() external view returns (bool _ok);

  /**
   * @notice Updates the current price with the last next price, and reads the next price feed
   * @dev    Will revert if the delay since last update has not elapsed
   * @return _success Whether the update was successful or not
   */
  function updateResult() external returns (bool _success);
}