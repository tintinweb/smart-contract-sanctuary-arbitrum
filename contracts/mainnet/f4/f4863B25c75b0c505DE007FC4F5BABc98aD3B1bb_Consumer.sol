// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;



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


interface Challange {
  function solveChallenge(uint256 priceGuess, string memory yourTwitterHandle) external;
}

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Consumer {

    AggregatorV3Interface oracle = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    Challange challange = Challange(0xA2626bE06C11211A44fb6cA324A67EBDBCd30B70);

    function getPrice() private view returns (uint256) {
        (, int256 price,,,) = oracle.latestRoundData();
        return uint256(price);
    }

    function solve() external {
      challange.solveChallenge({priceGuess: getPrice(), yourTwitterHandle: "@AaronAbuUsama"});
    }
}