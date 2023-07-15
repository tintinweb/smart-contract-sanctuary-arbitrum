// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IChainlinkRelayer} from '@interfaces/oracles/IChainlinkRelayer.sol';
import {IChainlinkOracle} from '@interfaces/oracles/IChainlinkOracle.sol';

/**
 * @title ChainlinkRelayer
 * @notice This contracts transforms a Chainlink price feed into a standard IBaseOracle feed
 *         It also verifies that the reading is new enough, compared to a staleThreshold
 */
contract ChainlinkRelayer is IBaseOracle, IChainlinkRelayer {
  // --- Registry ---
  /// @inheritdoc IChainlinkRelayer
  IChainlinkOracle public chainlinkFeed;

  // --- Data ---
  /// @inheritdoc IBaseOracle
  string public symbol;

  /// @inheritdoc IChainlinkRelayer
  uint256 public multiplier;
  /// @inheritdoc IChainlinkRelayer
  uint256 public staleThreshold;

  constructor(address _aggregator, uint256 _staleThreshold) {
    if (_aggregator == address(0)) revert ChainlinkRelayer_NullAggregator();
    if (_staleThreshold == 0) revert ChainlinkRelayer_NullStaleThreshold();

    staleThreshold = _staleThreshold;
    chainlinkFeed = IChainlinkOracle(_aggregator);

    multiplier = 18 - chainlinkFeed.decimals();
    symbol = chainlinkFeed.description();
  }

  /// @inheritdoc IBaseOracle
  function getResultWithValidity() external view returns (uint256 _result, bool _validity) {
    // Fetch values from Chainlink
    (, int256 _aggregatorResult,, uint256 _aggregatorTimestamp,) = chainlinkFeed.latestRoundData();

    // Parse the quote into 18 decimals format
    _result = _parseResult(_aggregatorResult);

    // Check if the price is valid
    _validity = _aggregatorResult > 0 && _isValidFeed(_aggregatorTimestamp);
  }

  /// @inheritdoc IBaseOracle
  function read() external view returns (uint256 _result) {
    // Fetch values from Chainlink
    (, int256 _aggregatorResult,, uint256 _aggregatorTimestamp,) = chainlinkFeed.latestRoundData();

    // Revert if price is invalid
    if (_aggregatorResult == 0 || !_isValidFeed(_aggregatorTimestamp)) revert InvalidPriceFeed();

    // Parse the quote into 18 decimals format
    _result = _parseResult(_aggregatorResult);
  }

  function _parseResult(int256 _chainlinkResult) internal view returns (uint256 _result) {
    return uint256(_chainlinkResult) * 10 ** multiplier;
  }

  function _isValidFeed(uint256 _feedTimestamp) internal view returns (bool _valid) {
    uint256 _now = block.timestamp;
    if (_feedTimestamp > _now) return false;
    return _now - _feedTimestamp <= staleThreshold;
  }
}

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

import {IChainlinkOracle} from '@interfaces/oracles/IChainlinkOracle.sol';
import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

interface IChainlinkRelayer is IBaseOracle {
  // --- Errors ---
  error ChainlinkRelayer_NullAggregator();
  error ChainlinkRelayer_NullStaleThreshold();

  /**
   * @notice Address of the Chainlink aggregator used to consult the price
   */
  function chainlinkFeed() external view returns (IChainlinkOracle _chainlinkFeed);

  /**
   * @notice The multiplier used to convert the quote into an 18 decimals format
   */
  function multiplier() external view returns (uint256 _multiplier);

  /**
   * @notice The time threshold after which a Chainlink response is considered stale
   */
  function staleThreshold() external view returns (uint256 _staleThreshold);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IChainlinkOracle {
  function decimals() external view returns (uint8 _decimals);
  function description() external view returns (string memory _description);
  function getAnswer(uint256 _roundId) external view returns (int256 _answer);
  function getRoundData(uint256 __roundId)
    external
    view
    returns (uint256 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint256 _answeredInRound);
  function getTimestamp(uint256 _roundId) external view returns (uint256 _timestamp);
  function latestAnswer() external view returns (int256 _latestAnswer);
  function latestRound() external view returns (uint256 _latestRound);
  function latestRoundData()
    external
    view
    returns (uint256 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint256 _answeredInRound);
  function latestTimestamp() external view returns (uint256 _latestTimestamp);
}