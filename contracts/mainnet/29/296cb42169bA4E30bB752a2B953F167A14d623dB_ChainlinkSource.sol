// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../interfaces/IChainlinkDataSource.sol";
import "../interfaces/IDataSource.sol";

contract ChainlinkSource is IDataSource {
    IChainlinkDataSource public oracle;

    constructor(address oracleAddress) {
        oracle = IChainlinkDataSource(oracleAddress);
    }

    function getLatestPrice()
        external
        view
        override
        returns (uint256 value, uint8 decimals)
    {
        (, int256 answer, , , ) = oracle.latestRoundData();
        return (uint256(answer), oracle.decimals());
    }

    function eventSource() external view override returns (address) {
        return oracle.aggregator();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkDataSource {
    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

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

    function aggregator() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDataSource {
    function getLatestPrice()
        external
        view
        returns (uint256 value, uint8 decimals);

    function eventSource() external view returns (address);
}