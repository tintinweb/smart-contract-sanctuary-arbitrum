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

contract ARBPriceConsumer {
    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal sequencerUptimeFeed;

    uint256 private constant GRACE_PERIOD_TIME = 3600;

    error SequencerDown();
    error GracePeriodNotOver();

    /**
     * Aggregator: ARB/USD
     * Address (ArbOne): 0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6
     * Address (ArbGoerli): 0x2eE9BFB2D319B31A573EA15774B755715988E99D
     * 
     * Sequencer uptime
     * Address (ArbOne): 0xFdB631F5EE196F0ed6FAa767959853A9F217697D
     * Address (ArbGoerli): 0x4da69F028a5790fCCAfe81a75C0D24f46ceCDd69
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x2eE9BFB2D319B31A573EA15774B755715988E99D
        );
        sequencerUptimeFeed = AggregatorV3Interface(
            0x4da69F028a5790fCCAfe81a75C0D24f46ceCDd69
        );
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /*uint80 roundID*/,
            int256 answer,
            uint256 startedAt,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = sequencerUptimeFeed.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        if (answer != 0) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the
        // sequencer is back up.
        if ((block.timestamp - startedAt) <= GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }
        
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}