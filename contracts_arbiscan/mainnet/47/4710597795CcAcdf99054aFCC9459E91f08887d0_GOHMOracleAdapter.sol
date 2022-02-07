/**
 *Submitted for verification at arbiscan.io on 2022-02-07
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/B.Protocol/Dependencies/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.6.11;

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


// File contracts/B.Protocol/OracleAdapter.sol


pragma solidity 0.6.11;

contract OracleAdapter {
    AggregatorV3Interface immutable oracle;
    uint immutable tokenDecimals;

    constructor(AggregatorV3Interface _oracle, uint _tokenDecimals) public {
        oracle = _oracle;
        tokenDecimals = _tokenDecimals;

        require(_tokenDecimals <= 18, "unstupported decimals");
    }

    function decimals() public view returns (uint8) {
        return oracle.decimals();
    }

    function latestRoundData() public view
        returns
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 timestamp,
            uint80 answeredInRound
        )
    {
        (roundId, answer, startedAt, timestamp, answeredInRound) = oracle.latestRoundData();
        int decimalsFactor = int(10 ** (18 - tokenDecimals));
        int adjustAnswer = answer * decimalsFactor;
        require(adjustAnswer / decimalsFactor == answer, "latestRoundData: overflow");
        answer = adjustAnswer;
        timestamp = now; // override timestamp, as on arbitrum they are updated every 24 hours
    }
}

contract GOHMOracleAdapter {
    AggregatorV3Interface immutable ohmIndex;
    AggregatorV3Interface immutable ohmV2;

    constructor(AggregatorV3Interface _ohmIndex, AggregatorV3Interface _ohmV2) public {
        ohmIndex = _ohmIndex;
        ohmV2 = _ohmV2;
    }

    function decimals() public view returns (uint8) {
        return ohmIndex.decimals() + ohmV2.decimals();
    }

    function latestRoundData() public view
        returns
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 timestamp,
            uint80 answeredInRound
        )
    {
        int answer1; int answer2;
        (roundId, answer1, startedAt, , answeredInRound) = ohmIndex.latestRoundData();
        (, answer2, , , ) = ohmV2.latestRoundData();
        answer = answer1 * answer2;
        require(answer / answer2 == answer1, "latestRoundData: overflow");
        timestamp = now; // override timestamp, as on arbitrum they are updated every 24 hours
    }
}