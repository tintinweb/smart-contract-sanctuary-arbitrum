/**
 *Submitted for verification at Arbiscan.io on 2024-02-12
*/

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.24;

interface IPriceFeed {

    function decimals()
        external
        view
        returns (uint8);

    function description()
        external
        view
        returns (string memory);

    function version()
        external
        view
        returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
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

    function latestAnswer()
        external
        view
        returns (uint256);

    function phaseId()
        external
        view
        returns (uint16);

    function aggregator()
        external
        view
        returns (address);
}

/**
 * @author René Hochmuth
 * @title DaiEthOracle (Arbitrum)
 */

/**
 * @dev PriceFeed contract for DAI token on Arbitrum.
 * Takes chainLink oracle value of DAI / USD and divides it
 * with corresponding ETH value in USD reported by chainLink.
 * Result of this feed is correct DAI value in ETH equivalent.
 */

contract DaiEthOracle {

    constructor(
        IPriceFeed _ethUsdFeed,
        IPriceFeed _daiUsdFeed
    )
    {
        ETH_USD_FEED = _ethUsdFeed;
        DAI_USD_FEED = _daiUsdFeed;

        POW_ETH_USD = 10 ** ETH_USD_FEED.decimals();
        POW_DAI_USD = 10 ** DAI_USD_FEED.decimals();
    }

    // Pricefeed for ETH in USD.
    IPriceFeed public immutable ETH_USD_FEED;

    // Pricefeed for DAI in USD.
    IPriceFeed public immutable DAI_USD_FEED;

    // 10 ** Decimals of the feeds for EthUsd.
    uint256 internal immutable POW_ETH_USD;

    // 10 ** Decimals of the feeds for DaiUsd.
    uint256 internal immutable POW_DAI_USD;

    // Default decimals for the feed.
    uint8 internal constant FEED_DECIMALS = 18;

    // Precision factor for computations.
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;

    /**
     * @dev Read function returning latest ETH value for DAI.
     * Uses answer from DAI / USD chainLink priceFeed then divides it
     * and combines it with the result from ETH / USD feed.
     */
    function latestAnswer()
        public
        view
        returns (uint256)
    {
        (
            ,
            int256 answerDaiUsd,
            ,
            ,
        ) = DAI_USD_FEED.latestRoundData();

        (
            ,
            int256 answerEthUsd,
            ,
            ,
        ) = ETH_USD_FEED.latestRoundData();

        return uint256(answerDaiUsd)
            * PRECISION_FACTOR_E18
            / POW_DAI_USD
            * POW_ETH_USD
            / uint256(answerEthUsd);
    }

    /**
     * @dev Returns priceFeed decimals.
     */
    function decimals()
        external
        pure
        returns (uint8)
    {
        return FEED_DECIMALS;
    }

    /**
     * @dev Read function returning the latest round data
     * from stETH plus the latest USD value for WstETH.
     * Needed for calibrating the pricefeed in the
     * OracleHub. (see WiseOracleHub and heartbeat)
     */
    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        answer = int256(
            latestAnswer()
        );

        (
            roundId,
            ,
            startedAt,
            updatedAt,
            answeredInRound
        ) = DAI_USD_FEED.latestRoundData();
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (
            roundId,
            answer,
            startedAt,
            updatedAt,
            answeredInRound
        ) = DAI_USD_FEED.getRoundData(
            _roundId
        );
    }
}