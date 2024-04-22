// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IDelayedOracleChild} from '@interfaces/factories/IDelayedOracleChild.sol';
import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

import {DelayedOracle} from '@contracts/oracles/DelayedOracle.sol';

import {FactoryChild} from '@contracts/factories/FactoryChild.sol';

/**
 * @title  DelayedOracleChild
 * @notice This contract inherits all the functionality of DelayedOracle to be factory deployed
 */
contract DelayedOracleChild is DelayedOracle, FactoryChild, IDelayedOracleChild {
  // --- Init ---

  /**
   *
   * @param  _priceSource Address of the price source
   * @param  _updateDelay Amount of seconds to be applied between the price source and the delayed oracle feeds
   */
  constructor(IBaseOracle _priceSource, uint256 _updateDelay) DelayedOracle(_priceSource, _updateDelay) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';

import {IFactoryChild} from '@interfaces/factories/IFactoryChild.sol';

interface IDelayedOracleChild is IDelayedOracle, IFactoryChild {}

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

  /// @notice The current valid price feed storage struct
  Feed internal _currentFeed;
  /// @notice The next valid price feed storage struct
  Feed internal _nextFeed;

  // --- Init ---

  /**
   * @param  _priceSource The address of the non-delayed price source
   * @param  _updateDelay The delay in seconds that should elapse between updates
   */
  constructor(IBaseOracle _priceSource, uint256 _updateDelay) {
    if (address(_priceSource) == address(0)) revert DelayedOracle_NullPriceSource();
    if (_updateDelay == 0) revert DelayedOracle_NullDelay();

    priceSource = _priceSource;
    updateDelay = _updateDelay;

    (uint256 _priceFeedValue, bool _hasValidValue) = _getPriceSourceResult();
    if (_hasValidValue) {
      _nextFeed = Feed(_priceFeedValue, _hasValidValue);
      _currentFeed = _nextFeed;
      lastUpdateTime = block.timestamp;

      emit UpdateResult(_currentFeed.value, lastUpdateTime);
    }

    symbol = priceSource.symbol();
  }

  /// @inheritdoc IDelayedOracle
  function updateResult() external returns (bool _success) {
    // Read the price from the median
    (uint256 _priceFeedValue, bool _hasValidValue) = _getPriceSourceResult();

    // Check if the delay to set the new feed passed
    if (!_delayHasElapsed()) {
      // If it hasn't passed, check if the upcoming feed is valid
      // in the case that it is not valid we check if we can fetch a new valid feed to replace it.
      if (!_nextFeed.isValid) {
        // Check if the newly fetched feed is valid
        if (_hasValidValue) {
          // Store the new next Feed
          _nextFeed = Feed(_priceFeedValue, _hasValidValue);
          lastUpdateTime = block.timestamp;
        }

        return _hasValidValue;
      }

      revert DelayedOracle_DelayHasNotElapsed();
    }

    // Update state
    _currentFeed = _nextFeed;
    _nextFeed = Feed(_priceFeedValue, _hasValidValue);
    lastUpdateTime = block.timestamp;

    // Emit event
    emit UpdateResult(_currentFeed.value, lastUpdateTime);

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
    return _delayHasElapsed() || !_nextFeed.isValid;
  }

  /// @inheritdoc IDelayedOracle
  function getNextResultWithValidity() external view returns (uint256 _result, bool _validity) {
    return (_nextFeed.value, _nextFeed.isValid);
  }

  /// @notice Internal view function that queries the standard price source
  function _getPriceSourceResult() internal view returns (uint256 _priceFeedValue, bool _hasValidValue) {
    return priceSource.getResultWithValidity();
  }

  /// @notice Internal view function that returns whether the delay between calls has been passed
  function _delayHasElapsed() internal view returns (bool _ok) {
    return block.timestamp >= lastUpdateTime + updateDelay;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IFactoryChild} from '@interfaces/factories/IFactoryChild.sol';

/**
 * @title  FactoryChild
 * @notice This abstract contract adds a factory address and modifier to the inheriting contract
 */
abstract contract FactoryChild is IFactoryChild {
  // --- Registry ---

  /// @inheritdoc IFactoryChild
  address public factory;

  // --- Init ---

  /// @dev Verifies that the contract is being deployed by a contract address
  constructor() {
    factory = msg.sender;
    if (factory.code.length == 0) revert NotFactoryDeployment();
  }

  // --- Modifiers ---

  /// @notice Verifies that the caller is the factory
  modifier onlyFactory() {
    if (msg.sender != factory) revert CallerNotFactory();
    _;
  }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

interface IFactoryChild {
  // --- Errors ---

  /// @dev Throws when the contract is being deployed by a non-contract address
  error NotFactoryDeployment();
  /// @dev Throws when trying to call an onlyFactory function from a non-factory address
  error CallerNotFactory();

  // --- Registry ---

  /**
   * @notice Getter for the address of the factory that deployed the inheriting contract
   * @return _factory Factory address
   */
  function factory() external view returns (address _factory);
}