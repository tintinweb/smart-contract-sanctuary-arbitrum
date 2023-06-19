// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IPimlicoERC20Paymaster.sol";

contract OracleUpdater {
    function shouldUpdatePrice(
        IPimlicoERC20Paymaster _paymaster,
        // The price update threshold percentage that triggers a price update (1e6 = 100%)
        uint32 _priceUpdateThreshold
    ) public view returns (bool doUpdate) {
        uint192 tokenPrice = fetchPrice(_paymaster.tokenOracle());
        uint192 nativeAsset = fetchPrice(_paymaster.nativeAssetOracle());
        uint256 cachedPrice = _paymaster.previousPrice();
        uint192 price = (nativeAsset * uint192(_paymaster.tokenDecimals())) / tokenPrice;
        uint256 cachedUpdateThreshold = _priceUpdateThreshold;
        doUpdate =
            ((uint256(price) * _paymaster.priceDenominator()) / cachedPrice >
                _paymaster.priceDenominator() + cachedUpdateThreshold) ||
            ((uint256(price) * _paymaster.priceDenominator()) / cachedPrice <
                _paymaster.priceDenominator() - cachedUpdateThreshold);
        return doUpdate;
    }

    function fetchPrice(IOracle _oracle) public view returns (uint192 price) {
        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = _oracle
            .latestRoundData();
        require(answer > 0, "PP-ERC20 : Chainlink price <= 0");
        // 2 days old price is considered stale since the price is updated
        // every 24 hours
        require(updatedAt >= block.timestamp - 60 * 60 * 24 * 2, "PP-ERC20 : Incomplete round");
        require(answeredInRound >= roundId, "PP-ERC20 : Stale price");
        price = uint192(int192(answer));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./IOracle.sol";

interface IPimlicoERC20Paymaster {
    function priceUpdateThreshold() external view returns (uint32);

    function tokenOracle() external view returns (IOracle);

    function nativeAssetOracle() external view returns (IOracle);

    function tokenDecimals() external view returns (uint256);

    function priceDenominator() external view returns (uint256);

    function previousPrice() external view returns (uint256);

    function updatePrice() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IOracle {
    function decimals() external view returns (uint8);

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