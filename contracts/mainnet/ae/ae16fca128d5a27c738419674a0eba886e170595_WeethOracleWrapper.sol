// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

/**
 * @author René Hochmuth
 * @title weethOracle (Arbitrum)
 */

/**
 * @dev creates a derivative weethOracle to have 18 decimals
 */

import "../InterfaceHub/IPriceFeed.sol";

contract WeethOracleWrapper {

    constructor(
        IPriceFeed _weethRedStone
    )
    {
        WEETH_REDSTONE = _weethRedStone;
    }

    // Pricefeed for WEETH.
    IPriceFeed public immutable WEETH_REDSTONE;

    // Default decimals for the feed.
    uint8 internal constant FEED_DECIMALS = 18;

    // Precision factor for computations.
    uint256 internal constant PRECISION_FACTOR_E10 = 1E10;

    // Precision factor for computations.
    uint256 internal constant PRECISION_FACTOR_E28 = 1E28;

    /**
     * @dev Gets the eeth underlying through weeth oracle and contract rate
     */
    function latestAnswer()
        public
        view
        returns (uint256)
    {
        (
            ,
            int256 answerWeeth,
            ,
            ,
        ) = WEETH_REDSTONE.latestRoundData();

        return uint256(answerWeeth)
            * PRECISION_FACTOR_E10;
    }

    function decimals()
        external
        pure
        returns (uint8)
    {
        return FEED_DECIMALS;
    }

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
        ) = WEETH_REDSTONE.latestRoundData();
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
        ) = WEETH_REDSTONE.getRoundData(
            _roundId
        );
    }
}

// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.25;

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