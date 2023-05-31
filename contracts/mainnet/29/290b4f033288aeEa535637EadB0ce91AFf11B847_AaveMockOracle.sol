/**
 *Submitted for verification at Arbiscan on 2023-05-31
*/

pragma solidity 0.8;

contract AaveMockOracle {
    
    mapping(address => uint256) private assetPrices;

    AaveMockOracle actualOracle;

    constructor(AaveMockOracle oracle) {
        actualOracle = oracle;
    }

    function setAssetPrice(address asset, uint256 price) external {
        assetPrices[asset] = price;
    }

    function getAssetPrice(address asset) public view returns (uint256) {
        uint256 mockPrice = assetPrices[asset];
        return mockPrice == 0 ? actualOracle.getAssetPrice(asset) : mockPrice;
    }

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
          prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }

}