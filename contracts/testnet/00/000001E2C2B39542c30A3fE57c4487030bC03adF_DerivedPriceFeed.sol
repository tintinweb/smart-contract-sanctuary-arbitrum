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
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error MismatchInBaseAndQuoteDecimals();
error InvalidPriceFromRound();
error LatestRoundIncomplete();
error PriceFeedStale();
error OracleAddressCannotBeZero();

contract DerivedPriceFeed {
    // price is native-per-dollar
    AggregatorV3Interface internal nativeOracle;
    // price is tokens-per-dollar
    AggregatorV3Interface internal tokenOracle;

    string internal DESCRIPTION;

    constructor(
        address _nativeOracleAddress,
        address _tokenOracleAddress,
        string memory _description
    ) {
        if (_nativeOracleAddress == address(0))
            revert OracleAddressCannotBeZero();
        if (_tokenOracleAddress == address(0))
            revert OracleAddressCannotBeZero();
        nativeOracle = AggregatorV3Interface(_nativeOracleAddress);
        tokenOracle = AggregatorV3Interface(_tokenOracleAddress);

        // If either of the base or quote price feeds have mismatch in decimal then it could be a problem, so throw!
        uint8 decimals1 = nativeOracle.decimals();
        uint8 decimals2 = tokenOracle.decimals();
        if (decimals1 != decimals2) revert MismatchInBaseAndQuoteDecimals();

        DESCRIPTION = _description;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function description() public view returns (string memory) {
        return DESCRIPTION;
    }

    function validateRound(
        uint80 roundId,
        int256 price,
        uint256 updatedAt,
        uint80 answeredInRound,
        uint256 staleFeedThreshold
    ) internal view {
        if (price <= 0) revert InvalidPriceFromRound();
        // 2 days old price is considered stale since the price is updated every 24 hours
        if (updatedAt < block.timestamp - staleFeedThreshold)
            revert PriceFeedStale();
        if (updatedAt == 0) revert LatestRoundIncomplete();
        if (answeredInRound < roundId) revert PriceFeedStale();
    }

    function getThePrice() public view returns (int) {
        /**
         * Returns the latest price of price feed 1
         */

        (
            uint80 roundID1,
            int256 price1,
            ,
            uint256 updatedAt1,
            uint80 answeredInRound1
        ) = nativeOracle.latestRoundData();

        // By default 2 days old price is considered stale BUT it may vary per price feed
        // comapred to stable coin feeds this may have different heartbeat
        validateRound(
            roundID1,
            price1,
            updatedAt1,
            answeredInRound1,
            60 * 60 * 24 * 2
        );

        /**
         * Returns the latest price of price feed 2
         */

        (
            uint80 roundID2,
            int256 price2,
            ,
            uint256 updatedAt2,
            uint80 answeredInRound2
        ) = tokenOracle.latestRoundData();

        // By default 2 days old price is considered stale BUT it may vary per price feed
        validateRound(
            roundID2,
            price2,
            updatedAt2,
            answeredInRound2,
            60 * 60 * 24 * 2
        );

        // Always using decimals 18 for derived price feeds
        int token_native = (price2 * (10 ** 18)) / price1;
        return token_native;
    }
}