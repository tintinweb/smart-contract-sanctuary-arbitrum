/**
 *Submitted for verification at Arbiscan on 2023-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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

/// @author MiguelBits
contract PegOracle {
    /***
    @dev  for example: oracle1 would be stETH / USD, while oracle2 would be ETH / USD oracle
    ***/
    address public oracle1;
    address public oracle2;

    uint8 public decimals;

    AggregatorV3Interface internal priceFeed1;
    AggregatorV3Interface internal priceFeed2;

    /** @notice Contract constructor
     * @param _oracleHEDGE Oracle address for the hedging asset
     * @param _oracleRISK Oracle address for peg asset
     */
    constructor(address _oracleHEDGE, address _oracleRISK) {
        require(
            _oracleHEDGE != address(0),
            "oracle1 cannot be the zero address"
        );
        require(
            _oracleRISK != address(0),
            "oracle2 cannot be the zero address"
        );
        require(_oracleHEDGE != _oracleRISK, "Cannot be same Oracle");

        priceFeed1 = AggregatorV3Interface(_oracleHEDGE);
        priceFeed2 = AggregatorV3Interface(_oracleRISK);

        require(
            (priceFeed1.decimals() == priceFeed2.decimals()),
            "Decimals must be the same"
        );

        require(decimals <= 18, "Decimals must be less than 18");

        oracle1 = _oracleHEDGE;
        oracle2 = _oracleRISK;
        decimals = 18;
    }

    /** @notice Returns oracle-fed data from the latest round
     * @return roundID Current round id
     * @return nowPrice Current price
     * @return startedAt Starting timestamp
     * @return timeStamp Current timestamp
     * @return answeredInRound Round id for which answer was computed
     */
    function latestRoundData()
        public
        view
        returns (
            uint80 roundID,
            int256 nowPrice,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        )
    {
        (
            uint80 roundID1,
            int256 price1,
            uint256 startedAt1,
            uint256 timeStamp1,
            uint80 answeredInRound1
        ) = priceFeed1.latestRoundData();
        require(price1 > 0, "Chainlink price <= 0");
        require(
            answeredInRound1 >= roundID1,
            "RoundID from Oracle is outdated!"
        );
        require(timeStamp1 != 0, "Timestamp == 0 !");

        int256 price2 = getOracle2_Price();

        int256 WAD = 1e18;
        nowPrice = (price1 * WAD) / price2; //divWadDown() from FixedPointMathLib.sol

        return (roundID1, nowPrice, startedAt1, timeStamp1, answeredInRound1);
    }

    /* solhint-disbable-next-line func-name-mixedcase */
    /** @notice Lookup first oracle price
     * @return price Current first oracle price
     */
    function getOracle1_Price() public view returns (int256 price) {
        (
            uint80 roundID1,
            int256 price1,
            ,
            uint256 timeStamp1,
            uint80 answeredInRound1
        ) = priceFeed1.latestRoundData();

        require(price1 > 0, "Chainlink price <= 0");
        require(
            answeredInRound1 >= roundID1,
            "RoundID from Oracle is outdated!"
        );
        require(timeStamp1 != 0, "Timestamp == 0 !");

        return price1;
    }

    /* solhint-disbable-next-line func-name-mixedcase */
    /** @notice Lookup second oracle price
     * @return price Current second oracle price
     */
    function getOracle2_Price() public view returns (int256 price) {
        (
            uint80 roundID2,
            int256 price2,
            ,
            uint256 timeStamp2,
            uint80 answeredInRound2
        ) = priceFeed2.latestRoundData();

        require(price2 > 0, "Chainlink price <= 0");
        require(
            answeredInRound2 >= roundID2,
            "RoundID from Oracle is outdated!"
        );
        require(timeStamp2 != 0, "Timestamp == 0 !");

        return price2;
    }
}