// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
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

    function latestAnswer() external view returns(int256);
}

contract ETHPriceOracle {
    AggregatorV3Interface internal priceFeed;

    constructor(address _aggregatorInterfaceAddress) {
        priceFeed = AggregatorV3Interface(_aggregatorInterfaceAddress);
        // Fantom network Chainlink FTM/USD price feed: 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc
        // BNB / USD: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
    }

    function getEthPrice() external view returns (uint256, uint256) {
        uint256 _price = uint256(priceFeed.latestAnswer());
        uint256 _decimals = uint256(priceFeed.decimals());
        return (_price, _decimals);
    }
}