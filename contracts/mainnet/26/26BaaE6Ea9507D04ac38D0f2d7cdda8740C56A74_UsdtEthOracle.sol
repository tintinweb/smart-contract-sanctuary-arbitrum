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
 * @title UsdtEthOracle (Arbitrum)
 */

/**
 * @dev PriceFeed contract for USDT token on Arbitrum.
 * Takes chainLink oracle value of USDT / USD and divides it
 * with corresponding ETH value in USD reported by chainLink.
 * Result of this feed is correct USDT value in ETH equivalent.
 */

contract UsdtEthOracle {

    constructor(
        IPriceFeed _wethUsdFeed,
        IPriceFeed _usdtUsdFeed
    )
    {
        WETH_USD_FEED = _wethUsdFeed;
        USDT_USD_FEED = _usdtUsdFeed;

        POW_WETH_USD = 10 ** WETH_USD_FEED.decimals();
        POW_USDT_USD = 10 ** USDT_USD_FEED.decimals();
    }

    // Pricefeed for WETH in USD.
    IPriceFeed public immutable WETH_USD_FEED;

    // Pricefeed for USDT in USD.
    IPriceFeed public immutable USDT_USD_FEED;

    // 10 ** Decimals of the feeds for WethUsd.
    uint256 internal immutable POW_WETH_USD;

    // 10 ** Decimals of the feeds for UsdtUsd.
    uint256 internal immutable POW_USDT_USD;

    // Default decimals for the feed.
    uint8 internal constant FEED_DECIMALS = 18;

    // Precision factor for computations.
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;

    /**
     * @dev Read function returning latest WETH value for USDT.
     * Uses answer from USDT / USD chainLink priceFeed then divides it
     * and combines it with the result from WETH / USD feed.
     */
    function latestAnswer()
        public
        view
        returns (uint256)
    {
        (
            ,
            int256 answerUsdtUsd,
            ,
            ,
        ) = USDT_USD_FEED.latestRoundData();

        (
            ,
            int256 answerWethUsd,
            ,
            ,
        ) = WETH_USD_FEED.latestRoundData();

        return uint256(answerUsdtUsd)
            * PRECISION_FACTOR_E18
            / POW_USDT_USD
            * POW_WETH_USD
            / uint256(answerWethUsd);
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
        ) = USDT_USD_FEED.latestRoundData();
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
        ) = USDT_USD_FEED.getRoundData(
            _roundId
        );
    }
}