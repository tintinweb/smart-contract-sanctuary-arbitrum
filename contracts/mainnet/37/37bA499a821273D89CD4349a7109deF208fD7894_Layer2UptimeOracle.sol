// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { IChainlinkAggregator } from "contracts/interfaces/IChainlinkAggregator.sol";
import { IUptimeOracle } from "contracts/interfaces/IUptimeOracle.sol";

/**
    @title Layer2 Uptime Oracle
    @author defidotmoney
    @dev Chainlink L2 sequencer uptime feed, with fixed grace period
         https://docs.chain.link/data-feeds/l2-sequencer-feeds
 */
contract Layer2UptimeOracle is IUptimeOracle {
    uint256 public constant SEQUENCER_GRACE_PERIOD = 1800;
    IChainlinkAggregator public immutable chainlinkL2SequencerFeed;

    constructor(IChainlinkAggregator _chainlink) {
        chainlinkL2SequencerFeed = _chainlink;
    }

    /**
        @notice Return the current uptime status for this chain's sequencer
        @dev After a sequencer outage, this function continues to return `false`
             for `SEQUENCER_GRACE_PERIOD` seconds.
             * Price oracles that incorporate this feed should return a cached
               price during downtime, so users have a window to unwind positions.
             * An L2 sequencer hook should be applied globally which prevents
               increasing debt or adjusting collateral during a downtime.
     */
    function getUptimeStatus() external view returns (bool) {
        (, int256 answer, uint256 startedAt, , ) = chainlinkL2SequencerFeed.latestRoundData();
        if (answer == 0) {
            return startedAt + SEQUENCER_GRACE_PERIOD < block.timestamp;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChainlinkAggregator {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    @dev Uptime oracles (related to L2 sequencer uptime) must implement all
         functions outlined within this interface
 */
interface IUptimeOracle {
    function getUptimeStatus() external view returns (bool);
}