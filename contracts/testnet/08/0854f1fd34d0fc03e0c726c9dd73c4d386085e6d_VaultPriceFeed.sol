// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import { IPriceFeed } from "../interfaces/IPriceFeed.sol";
import { IVaultPriceFeed } from "../interfaces/IVaultPriceFeed.sol";

contract VaultPriceFeed is IVaultPriceFeed {

    address public gov;

    mapping (address => address) public priceFeeds;

    mapping (address => uint256) public priceDecimals;

    uint256 public constant PRICE_PRECISION = 10 ** 30;

    modifier onlyGov() {
        require(msg.sender == gov, "VaultPriceFeed: forbidden");
        _;
    }

    constructor() {
        gov = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals
    ) external override onlyGov {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
    }

    // 把价格统一转成了30位
    function getPrice(address _token) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "VaultPriceFeed: Invalid price feed");
        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);
        int256 price = priceFeed.latestAnswer();
        // uint256 _priceDecimals = priceDecimals[_token];
        return uint256(price);
    }

    function tokenToUnit(address _token, uint256 _price, uint256 amount) public view returns(uint256){
        uint256 _priceDecimals = priceDecimals[_token];
        return amount  * 1**_priceDecimals / _price;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IPriceFeed {
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface IVaultPriceFeed {

    function getPrice(address _token) external view returns (uint256);
 
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals
    ) external;

    function tokenToUnit(address _token, uint256 _price, uint256 amount) external view returns(uint256);
}