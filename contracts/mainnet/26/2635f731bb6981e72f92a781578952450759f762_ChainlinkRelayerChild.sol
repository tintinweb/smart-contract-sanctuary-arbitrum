// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import {ChainlinkRelayer} from '@contracts/oracles/ChainlinkRelayer.sol';
import {FactoryChild} from '@contracts/factories/FactoryChild.sol';

contract ChainlinkRelayerChild is ChainlinkRelayer, FactoryChild {
  // --- Init ---

  /**
   * @param  _aggregator The address of the aggregator to relay
   * @param  _staleThreshold The threshold in seconds to consider the aggregator stale
   */
  constructor(address _aggregator, uint256 _staleThreshold) ChainlinkRelayer(_aggregator, _staleThreshold) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import {IChainlinkOracle} from '@interfaces/oracles/IChainlinkOracle.sol';

/**
 * @title  ChainlinkRelayer
 * @notice This contracts transforms a Chainlink price feed into a standard IBaseOracle feed
 *         It also verifies that the reading is new enough, compared to a STALE_THRESHOLD
 */
contract ChainlinkRelayer {
  uint256 public immutable STALE_THRESHOLD;
  int256 public immutable MULTIPLIER;

  // --- Registry ---
  IChainlinkOracle public chainlinkFeed;

  // --- Data ---
  string public symbol;

  /**
   * @param  _aggregator The address of the Chainlink aggregator
   * @param  _staleThreshold The threshold after which the price is considered stale
   */
  constructor(address _aggregator, uint256 _staleThreshold) {
    require(_aggregator != address(0)); // error msg will not show from constructor revert
    require(_staleThreshold != 0);

    STALE_THRESHOLD = _staleThreshold;
    chainlinkFeed = IChainlinkOracle(_aggregator);

    MULTIPLIER = int256(18) - int256(uint256(chainlinkFeed.decimals()));
    symbol = chainlinkFeed.description();
  }

  function getResultWithValidity() public view virtual returns (uint256 _result, bool _validity) {
    // Fetch values from Chainlink
    (, int256 _aggregatorResult,, uint256 _aggregatorTimestamp,) = chainlinkFeed.latestRoundData();

    // Parse the quote into 18 decimals format
    _result = _parseResult(_aggregatorResult);

    // Check if the price is valid
    _validity = _aggregatorResult > 0 && _isValidFeed(_aggregatorTimestamp);
  }

  function read() public view virtual returns (uint256 _result) {
    // Fetch values from Chainlink
    (, int256 _aggregatorResult,, uint256 _aggregatorTimestamp,) = chainlinkFeed.latestRoundData();

    // Revert if price is invalid
    require(_aggregatorResult != 0 && _isValidFeed(_aggregatorTimestamp), 'InvalidPriceFeed');

    // Parse the quote into 18 decimals format
    _result = _parseResult(_aggregatorResult);
  }

  /// @notice Parses the result from the aggregator into 18 decimals format
  function _parseResult(int256 _chainlinkResult) internal view returns (uint256 _result) {
    require(_chainlinkResult >= 0, 'Negative price value not allowed');

    if (MULTIPLIER == 0) {
      return uint256(_chainlinkResult);
    } else if (MULTIPLIER > 0) {
      return uint256(_chainlinkResult) * (10 ** uint256(MULTIPLIER));
    } else {
      return uint256(_chainlinkResult) / (10 ** _abs(MULTIPLIER));
    }
  }

  /// @notice Checks if the feed is valid, considering the STALE_THRESHOLD and the feed timestamp
  function _isValidFeed(uint256 _feedTimestamp) internal view returns (bool _valid) {
    uint256 _now = block.timestamp;
    if (_feedTimestamp > _now) return false;
    return _now - _feedTimestamp <= STALE_THRESHOLD;
  }

  /// @notice Return the absolute value of a signed integer as an unsigned integer
  function _abs(int256 x) internal pure returns (uint256) {
    x >= 0 ? x : -x;
    return uint256(x);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

abstract contract FactoryChild {
  // --- Registry ---
  address public factory;

  // --- Init ---

  /// @dev Verifies that the contract is being deployed by a contract address
  constructor() {
    factory = msg.sender;
  }

  // --- Modifiers ---

  ///@dev Verifies that the caller is the factory
  modifier onlyFactory() {
    require(msg.sender == factory, 'CallerNotFactory');
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

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