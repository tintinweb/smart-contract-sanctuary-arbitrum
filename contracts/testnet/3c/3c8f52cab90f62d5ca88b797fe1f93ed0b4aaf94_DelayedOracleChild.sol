// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IDelayedOracleChild} from '@interfaces/factories/IDelayedOracleChild.sol';
import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

import {DelayedOracle} from '@contracts/oracles/DelayedOracle.sol';

import {FactoryChild} from '@contracts/factories/FactoryChild.sol';

/**
 * @title  DelayedOracleChild
 * @notice This contract inherits all the functionality of `DelayedOracle.sol` to be factory deployed
 */
contract DelayedOracleChild is DelayedOracle, FactoryChild, IDelayedOracleChild {
  // --- Init ---
  constructor(IBaseOracle _priceSource, uint256 _updateDelay) DelayedOracle(_priceSource, _updateDelay) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';

import {IFactoryChild} from '@interfaces/factories/IFactoryChild.sol';

interface IDelayedOracleChild is IDelayedOracle, IFactoryChild {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

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
pragma solidity 0.8.19;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';

/**
 * @title  DelayedOracle
 * @notice Transforms a price feed into a delayed price feed with a step function
 * @dev    Requires an external mechanism to call updateResult every `updateDelay` seconds
 */
contract DelayedOracle is IBaseOracle, IDelayedOracle {
  // --- Registry ---
  /// @inheritdoc IDelayedOracle
  IBaseOracle public priceSource;

  // --- Data ---
  /// @inheritdoc IBaseOracle
  string public symbol;

  /// @inheritdoc IDelayedOracle
  uint256 public updateDelay;
  /// @inheritdoc IDelayedOracle
  uint256 public lastUpdateTime;

  Feed internal _currentFeed;
  Feed internal _nextFeed;

  constructor(IBaseOracle _priceSource, uint256 _updateDelay) {
    if (address(_priceSource) == address(0)) revert DelayedOracle_NullPriceSource();
    if (_updateDelay == 0) revert DelayedOracle_NullDelay();

    priceSource = _priceSource;
    updateDelay = _updateDelay;

    (uint256 _priceFeedValue, bool _hasValidValue) = _getPriceSourceResult();
    if (_hasValidValue) {
      _nextFeed = Feed(_priceFeedValue, true);
      _currentFeed = _nextFeed;
      lastUpdateTime = block.timestamp;

      emit UpdateResult(_currentFeed.value, lastUpdateTime);
    }

    symbol = priceSource.symbol();
  }

  /// @inheritdoc IDelayedOracle
  function updateResult() external returns (bool _success) {
    // Check if the delay passed
    if (!_delayHasElapsed()) revert DelayedOracle_DelayHasNotElapsed();
    // Read the price from the median
    (uint256 _priceFeedValue, bool _hasValidValue) = _getPriceSourceResult();
    // If the value is valid, update storage
    if (_hasValidValue) {
      // Update state
      _currentFeed = _nextFeed;
      _nextFeed = Feed(_priceFeedValue, true);
      lastUpdateTime = block.timestamp;
      // Emit event
      emit UpdateResult(_currentFeed.value, lastUpdateTime);
    }
    return _hasValidValue;
  }

  // --- Getters ---

  /// @inheritdoc IBaseOracle
  function getResultWithValidity() external view returns (uint256 _result, bool _validity) {
    return (_currentFeed.value, _currentFeed.isValid);
  }

  /// @inheritdoc IBaseOracle
  function read() external view returns (uint256 _result) {
    if (!_currentFeed.isValid) revert DelayedOracle_NoCurrentValue();
    return _currentFeed.value;
  }

  /// @inheritdoc IDelayedOracle
  function shouldUpdate() external view returns (bool _ok) {
    return _delayHasElapsed();
  }

  /// @inheritdoc IDelayedOracle
  function getNextResultWithValidity() external view returns (uint256 _result, bool _validity) {
    return (_nextFeed.value, _nextFeed.isValid);
  }

  /**
   * @dev View function that queries the standard price source
   */
  function _getPriceSourceResult() internal view returns (uint256 _priceFeedValue, bool _hasValidValue) {
    return priceSource.getResultWithValidity();
  }

  /**
   * @dev View function that returns whether the delay between calls has been passed
   */
  function _delayHasElapsed() internal view returns (bool _ok) {
    return block.timestamp >= lastUpdateTime + updateDelay;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IFactoryChild} from '@interfaces/factories/IFactoryChild.sol';

abstract contract FactoryChild is IFactoryChild {
  // --- Registry ---
  address public factory;

  // --- Init ---
  constructor() {
    factory = msg.sender;
    if (factory.code.length == 0) revert NotFactoryDeployment();
  }

  modifier onlyFactory() {
    if (msg.sender != factory) revert CallerNotFactory();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

interface IDelayedOracle is IBaseOracle {
  // --- Events ---
  event UpdateResult(uint256 _newMedian, uint256 _lastUpdateTime);

  // --- Errors ---
  error DelayedOracle_NullPriceSource();
  error DelayedOracle_NullDelay();
  error DelayedOracle_DelayHasNotElapsed();
  error DelayedOracle_NoCurrentValue();

  // --- Structs ---
  struct Feed {
    uint256 value;
    bool isValid;
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

  /**
   * @notice The delay in seconds that should elapse between updates
   */
  function updateDelay() external view returns (uint256 _updateDelay);

  /**
   * @notice The timestamp of the last update
   */
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IFactoryChild {
  // --- Errors ---
  error NotFactoryDeployment();
  error CallerNotFactory();

  // --- Registry ---
  function factory() external view returns (address _factory);
}