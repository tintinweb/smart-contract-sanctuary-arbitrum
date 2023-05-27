// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPriceOracle {
    function getPriceInUsd(
        string memory symbol
    ) external view returns (uint256);

    function BASE() external view returns (uint256);

    function setPrice(string memory symbol, uint256 price) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "../interfaces/IPriceOracle.sol";

contract SimpleKeyValueOracle is IPriceOracle {
    mapping(string => uint256) public prices;
    uint256 public BASE = 1e18;

    function setPrice(string memory symbol, uint256 price) external {
        prices[symbol] = price;
    }

    function getPriceInUsd(
        string memory symbol
    ) external view returns (uint256) {
        uint256 price = prices[symbol];
        if (price == 0) {
            return BASE;
        }
        return price;
    }
}