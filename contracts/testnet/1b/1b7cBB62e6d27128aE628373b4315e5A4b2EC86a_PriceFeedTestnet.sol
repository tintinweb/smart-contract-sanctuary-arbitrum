// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.17;

interface IPriceFeed {
    // Structs --------------------------------------------------------------------------------------------------------

    struct OracleRecord {
        AggregatorV3Interface chainLinkOracle;
        // Maximum price deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
        uint256 maxDeviationBetweenRounds;
        bool exists;
        bool isFeedWorking;
        bool isEthIndexed;
    }

    struct PriceRecord {
        uint256 scaledPrice;
        uint256 timestamp;
    }

    struct FeedResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    // Custom Errors --------------------------------------------------------------------------------------------------

    error PriceFeed__InvalidFeedResponseError(address token);
    error PriceFeed__InvalidPriceDeviationParamError();
    error PriceFeed__FeedFrozenError(address token);
    error PriceFeed__PriceDeviationError(address token);
    error PriceFeed__UnknownFeedError(address token);
    error PriceFeed__TimelockOnly();

    // Events ---------------------------------------------------------------------------------------------------------

    event NewOracleRegistered(
        address token,
        address chainlinkAggregator,
        bool isEthIndexed
    );
    event PriceFeedStatusUpdated(address token, address oracle, bool isWorking);
    event PriceRecordUpdated(address indexed token, uint256 _price);

    // Functions ------------------------------------------------------------------------------------------------------

    function setOracle(
        address _token,
        address _chainlinkOracle,
        uint256 _maxPriceDeviationFromPreviousRound,
        bool _isEthIndexed
    ) external;

    function fetchPrice(address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "../Interfaces/IPriceFeed.sol";

/*
 * PriceFeed placeholder for testnet and development. The price is simply set manually and saved in a state
 * variable. The contract does not connect to a live Chainlink price feed.
 */
contract PriceFeedTestnet is IPriceFeed {
    string public constant NAME = "PriceFeedTestnet";

    mapping(address => uint256) public prices;

    function getPrice(address _asset) external view returns (uint256) {
        return prices[_asset];
    }

    function setPrice(address _asset, uint256 _price) external {
        prices[_asset] = _price;
    }

    function setOracle(
        address _token,
        address _chainlinkOracle,
        uint256 _maxDeviationBetweenRounds,
        bool _isEthIndexed
    ) external override {}

    function fetchPrice(
        address _asset
    ) external view override returns (uint256) {
        return this.getPrice(_asset);
    }
}