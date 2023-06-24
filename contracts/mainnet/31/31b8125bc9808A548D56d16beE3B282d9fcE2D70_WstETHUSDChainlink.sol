// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

interface IUsdPlusToken{
    function liquidityIndex() external view returns(uint256);
}

contract WstETHUSDChainlink{
    uint8 public decimals;
    string public description;

    uint8 constant public wsteth_decimals = 18;
    uint8 constant public eth_decimals = 8;
    AggregatorV3Interface public wsteth_eth = AggregatorV3Interface(0xb523AE262D20A936BC152e6023996e46FDC2A95D);
    AggregatorV3Interface public eth_usd = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

    constructor(string memory _description) {
        description = _description;
        decimals = 8;
    }

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = wsteth_eth.latestRoundData();
        (, int256 answer2,,,) = eth_usd.latestRoundData();

        answer = int(uint256(answer) * uint256(answer2) * (10**decimals) / (10**wsteth_decimals) / (10**eth_decimals));
    }
}

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