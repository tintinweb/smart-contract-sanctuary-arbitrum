// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

/// @title Interface of shared variable types
/// @author float
/// @notice Top-level interface for the market contract tree
interface IMarketCommon {
  /// @notice Thrown when an unsupported address in used (e.g. 0 address)
  error InvalidAddress(address invalidAddress);

  /// @notice Info on the current epoch state
  struct EpochInfo {
    uint32 latestExecutedEpochIndex;
    // Reference to Chainlink Index
    uint80 latestExecutedOracleRoundId;
    // This should be large enough for all price data.
    uint144 lastEpochPrice;
  }

  /// @notice Each market has 3 different types of pools
  enum PoolType {
    SHORT,
    LONG,
    FLOAT,
    LAST // useful for getting last element of enum, commonly used in cpp/c also eg: https://stackoverflow.com/a/2102615
  }

  /// @notice Collection of all user actions (deposit is for mints)
  struct BatchedActions {
    uint256 paymentToken_deposit;
    uint256 poolToken_redeem;
  }

  /// @notice Static values that each pool needs to have
  struct PoolFixedConfig {
    address token;
    int96 leverage;
  }

  /// @notice Total values that define each pool
  struct Pool {
    uint256 value;
    // first element is for even epochs and second element for odd epochs
    BatchedActions[2] batchedAmount;
    PoolFixedConfig fixedConfig;
  }

  /// @notice Total values that define each action per user
  struct UserAction {
    uint32 correspondingEpoch;
    uint112 amount;
    uint112 nextEpochAmount;
  }

  /// @notice Ephemeral values used when updating the system state each epoch
  struct ValueChangeAndFunding {
    int256 valueChange;
    int256[2] fundingAmount;
    uint256 underBalancedSide;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../../interfaces/IMarketCommon.sol";

contract MockMarket {
  event PriceUpdated(uint256 price, uint256 index);

  mapping(uint256 => uint256) public prices;
  uint256 latestExecutedEpochIndex;

  function pushOraclePricesToUpdateSystemState(uint256[] memory newPrices, uint256[] memory indecies) public {
    require(newPrices.length == indecies.length, "Arrays must be of equal length");

    for (uint256 i = 0; i < newPrices.length; i++) {
      require(indecies[i] > latestExecutedEpochIndex, "Index must be greater than latest executed epoch index");

      emit PriceUpdated(newPrices[i], indecies[i]);
      newPrices[indecies[i]] = newPrices[i];
    }
  }

  function get_epochInfo() external view returns (IMarketCommon.EpochInfo memory epochInfo) {
    epochInfo.latestExecutedEpochIndex = uint32(latestExecutedEpochIndex);
    epochInfo.latestExecutedOracleRoundId = uint80(latestExecutedEpochIndex);
    epochInfo.lastEpochPrice = uint144(prices[latestExecutedEpochIndex]);
  }
}