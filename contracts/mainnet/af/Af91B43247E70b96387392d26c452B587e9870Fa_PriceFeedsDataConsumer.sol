// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title   Price Feeds Data Consumer
 * @author  Pulsar Finance
 * @dev     VERSION: 1.0
 *          DATE:    2023.10.05
 */

import {Errors} from "Errors.sol";
import {IPriceFeedsDataConsumer} from "IPriceFeedsDataConsumer.sol";
import {AggregatorV3Interface} from "AggregatorV3Interface.sol";

contract PriceFeedsDataConsumer is IPriceFeedsDataConsumer {
    AggregatorV3Interface public nativeTokenDataFeed;

    constructor(address _nativeTokenOracleAddress) {
        nativeTokenDataFeed = AggregatorV3Interface(_nativeTokenOracleAddress);
    }

    function getDataFeedLatestPriceAndDecimals(
        address oracleAddress
    ) external view returns (uint256 answer, uint256 decimals) {
        AggregatorV3Interface dataFeed = AggregatorV3Interface(oracleAddress);
        // prettier-ignore
        (
            /* uint80 roundID */,
            int256 answerRaw,
            /*uint256 startedAt*/,
            /*uint256 timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        uint8 decimalsRaw = dataFeed.decimals();
        if (answerRaw <= 0 || decimalsRaw <= 0) {
            revert Errors.PriceFeedError(
                "Price feed returned zero or negative values"
            );
        }
        answer = uint256(answerRaw);
        decimals = uint256(decimalsRaw);
    }

    function getNativeTokenDataFeedLatestPriceAndDecimals()
        external
        view
        returns (uint256 answer, uint256 decimals)
    {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int256 answerRaw,
            /*uint256 startedAt*/,
            /*uint256 timeStamp*/,
            /*uint80 answeredInRound*/
        ) = nativeTokenDataFeed.latestRoundData();
        uint8 decimalsRaw = nativeTokenDataFeed.decimals();
        answer = uint256(answerRaw);
        decimals = uint256(decimalsRaw);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

library Errors {
    error Forbidden(string message);

    error InvalidParameters(string message);

    /**
     * @dev Attempted to deposit more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxDeposit(
        address receiver,
        uint256 assets,
        uint256 max
    );

    error SwapPathNotFound(string message);

    error InvalidTxEtherAmount(string message);

    error NotEnoughEther(string message);

    error EtherTransferFailed(string message);

    error TokenTransferFailed(string message);

    error InvalidTokenBalance(string message);

    error PriceFeedError(string message);

    error UpdateConditionsNotMet();

    error ZeroOrNegativeVaultWithdrawAmount();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPriceFeedsDataConsumer {
    function getDataFeedLatestPriceAndDecimals(
        address oracleAddress
    ) external view returns (uint256, uint256);

    function getNativeTokenDataFeedLatestPriceAndDecimals()
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}