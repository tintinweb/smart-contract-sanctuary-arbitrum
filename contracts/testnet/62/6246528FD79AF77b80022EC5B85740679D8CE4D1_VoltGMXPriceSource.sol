// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGMXPriceProvider {
    function tokenPriceDai() external view returns(uint);
}

interface IVOLTGMX {
    function price() external view returns(uint);
    function compound() external;
}

interface IChainlinkPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

contract VoltGMXPriceSource {
    
    IGMXPriceProvider public gmxPriceProvider;
    IVOLTGMX public voltGMXPriceProvider;
    IChainlinkPrice public chainlink;

    constructor(address gmx_, address voltGMX_, address chainlink_) {

        gmxPriceProvider = IGMXPriceProvider(gmx_);
        voltGMXPriceProvider = IVOLTGMX(voltGMX_);
        chainlink = IChainlinkPrice(chainlink_);
    } 

	function getPrice() external view returns(uint) {
        return getPriceWithoutCompound();
    }

    function getPriceWithoutCompound() public view returns(uint) {
        return 50 * 10 ** 18;
    }

    function getDAIPrice() public view returns(int256) {
        if(address(chainlink) == address(0)) return 1e8;
        (,int256 assetChainlinkPriceInt,,,) = chainlink.latestRoundData();

        if(assetChainlinkPriceInt != 0) {
            return assetChainlinkPriceInt;
        }
        return 1e8;
    }
}