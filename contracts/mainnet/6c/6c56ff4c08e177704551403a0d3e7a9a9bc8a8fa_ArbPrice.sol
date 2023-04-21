// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "src/interfaces/IPriceSource.sol";

/// @notice The Chainlink AggregatorV3 contract
interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

/// @notice Returns the price of ARB for the Yama protocol using Chainlink
contract ArbPrice is IPriceSource {
    IChainlinkAggregatorV3 public constant chainlinkArbAggregator = IChainlinkAggregatorV3(
        0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6);
    uint8 public immutable decimalDifferenceChainlink;

    constructor() {
        decimalDifferenceChainlink = uint8(18 - chainlinkArbAggregator.decimals());
    }

    /// @notice Returns the price of mooGLP in GLP
    function price() external view returns (uint256 arbPrice) {
        (
            ,
            int256 chainlinkArbPrice,
            ,
            ,
        ) = chainlinkArbAggregator.latestRoundData();

        arbPrice = uint256(chainlinkArbPrice) * 10 ** decimalDifferenceChainlink;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/// @notice Returns the price of a collateral type in Yama.
/// @dev Used by the CDP module to determine the value of collateral.
interface IPriceSource {
  /// @notice Returns the price of a collateral type in Yama.
  /// @return amount price of the collateral type in Yama.
  function price() external view returns (uint256 amount);
}