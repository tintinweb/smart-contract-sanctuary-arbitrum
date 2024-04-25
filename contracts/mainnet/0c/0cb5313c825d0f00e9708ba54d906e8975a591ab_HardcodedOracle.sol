// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

/**
 * @title  HardcodedOracle
 * @notice This oracle is used to simulate a price source that returns a hardcoded price
 */
contract HardcodedOracle is IBaseOracle {
  /// @notice The hardcoded price the oracle returns [wad]
  uint256 public /* WAD */ price;

  /// @inheritdoc IBaseOracle
  string public symbol;

  /**
   * @param  _symbol The symbol of the oracle
   * @param  _price The hardcoded price the oracle returns [wad]
   */
  constructor(string memory _symbol, uint256 _price) {
    symbol = _symbol;
    price = _price;
  }

  /// @inheritdoc IBaseOracle
  function getResultWithValidity() external view returns (uint256 _price, bool _validity) {
    _price = price;
    _validity = true;
  }

  /// @inheritdoc IBaseOracle
  function read() external view returns (uint256 _value) {
    return price;
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