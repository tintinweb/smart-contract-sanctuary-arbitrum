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

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED
 * VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * If you are reading data feeds on L2 networks, you must
 * check the latest answer from the L2 Sequencer Uptime
 * Feed to ensure that the data is accurate in the event
 * of an L2 sequencer outage. See the
 * https://docs.chain.link/data-feeds/l2-sequencer-feeds
 * page for details.
 */

contract DataConsumerV3 {
    AggregatorV3Interface internal dataFeed;



    /**
     * Network: Arb Goerli
     * Aggregator: BTC/USD
     * Address: 0x6550bc2301936011c1334555e62A87705A81C12C
     */
    constructor() {
        dataFeed = AggregatorV3Interface(
            0x6550bc2301936011c1334555e62A87705A81C12C
        );
    }

    /**
     * Returns the latest answer.
     */
    function getLatestData() public view returns (uint80, int, uint, uint, uint80) {
        // prettier-ignore
        (
        uint80 roundID,
        int answer,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = dataFeed.latestRoundData();
        return (roundID, answer, startedAt, timeStamp, answeredInRound);
    }
}