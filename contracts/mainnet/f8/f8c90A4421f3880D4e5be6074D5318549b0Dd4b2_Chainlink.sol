// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Chainlink
/// @notice Consumes price data
contract Chainlink {
    // -- Constants -- //
    uint256 public constant UNIT = 10 ** 18;
    uint256 public constant GRACE_PERIOD_TIME = 3600;
    uint256 public constant RATE_STALE_PERIOD = 86400;

    // -- Variables -- //
    AggregatorV3Interface internal sequencerUptimeFeed;

    // -- Errors -- //
    error SequencerDown();
    error GracePeriodNotOver();
    error StaleRate();

    /**
     * For a list of available sequencer proxy addresses, see:
     * https://docs.chain.link/docs/l2-sequencer-flag/#available-networks
     */

    // -- Constructor -- //
    constructor() {
        // Arbitrum L2 sequencer feed
        sequencerUptimeFeed = AggregatorV3Interface(0xFdB631F5EE196F0ed6FAa767959853A9F217697D);
    }

    // Returns the latest price
    function getPrice(address feed) public view returns (uint256) {
        if (feed == address(0)) return 0;

        // prettier-ignore
        (
            /*uint80 roundID*/
            ,
            int256 answer,
            uint256 startedAt,
            /*uint256 updatedAt*/
            ,
            /*uint80 answeredInRound*/
        ) = sequencerUptimeFeed.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;

        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);

        // prettier-ignore
        (
            /*uint80 roundID*/
            ,
            int256 price,
            /*uint startedAt*/
            ,
            uint256 updatedAt,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        if (updatedAt < block.timestamp - RATE_STALE_PERIOD) {
            revert StaleRate();
        }

        uint8 decimals = priceFeed.decimals();

        // Return 18 decimals standard
        return (uint256(price) * UNIT) / 10 ** decimals;
    }
}