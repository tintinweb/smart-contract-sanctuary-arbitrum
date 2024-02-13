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
 * @title UsdcEthOracle (Arbitrum)
 */

/**
 * @dev PriceFeed contract for USDC token on Arbitrum.
 * Takes chainLink oracle value of USDC / USD and divides it
 * with corresponding ETH value in USD reported by chainLink.
 * Result of this feed is correct USDC value in ETH equivalent.
 */

contract UsdcEthOracle {

    constructor(
        IPriceFeed _wethUsdFeed,
        IPriceFeed _usdcUsdFeed
    )
    {
        WETH_USD_FEED = _wethUsdFeed;
        USDC_USD_FEED = _usdcUsdFeed;

        POW_WETH_USD = 10 ** WETH_USD_FEED.decimals();
        POW_USDC_USD = 10 ** USDC_USD_FEED.decimals();
    }

    // Pricefeed for ETH in USD.
    IPriceFeed public immutable WETH_USD_FEED;

    // Pricefeed for USDC in USD.
    IPriceFeed public immutable USDC_USD_FEED;

    // 10 ** Decimals of the feeds for EthUsd.
    uint256 internal immutable POW_WETH_USD;

    // 10 ** Decimals of the feeds for UsdcUsd.
    uint256 internal immutable POW_USDC_USD;

    // Default decimals for the feed.
    uint8 internal constant FEED_DECIMALS = 18;

    // Precision factor for computations.
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;

    /**
     * @dev Read function returning latest ETH value for USDC.
     * Uses answer from USDC / USD chainLink priceFeed then divides it
     * and combines it with the result from ETH / USD feed.
     */
    function latestAnswer()
        public
        view
        returns (uint256)
    {
        (
            ,
            int256 answerUsdcUsd,
            ,
            ,
        ) = USDC_USD_FEED.latestRoundData();

        (
            ,
            int256 answerWethUsd,
            ,
            ,
        ) = WETH_USD_FEED.latestRoundData();

        return uint256(answerUsdcUsd)
            * PRECISION_FACTOR_E18
            / POW_USDC_USD
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
        ) = USDC_USD_FEED.latestRoundData();
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
        ) = USDC_USD_FEED.getRoundData(
            _roundId
        );
    }
}