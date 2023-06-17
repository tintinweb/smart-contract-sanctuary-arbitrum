// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGNSPriceProvider {
    function tokenPriceDai() external view returns(uint);
}

interface IVOLTGNS {
    function price() external view returns(uint);
    function compound() external;
}

interface IChainlinkPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract VoltGNSPriceSource {
    
    IGNSPriceProvider public gnsPriceProvider;
    IVOLTGNS public voltGNSPriceProvider;
    IChainlinkPrice public chainlink;

    constructor(address gns_, address voltGNS_, address chainlink_) {
		gnsPriceProvider = IGNSPriceProvider(gns_);
        voltGNSPriceProvider = IVOLTGNS(voltGNS_);
        chainlink = IChainlinkPrice(chainlink_);
    } 

	function getPrice() external returns(uint) {
        voltGNSPriceProvider.compound();
        return getPriceWithoutCompound();
    }

    function getPriceWithoutCompound() public view returns(uint) {
        return gnsPriceProvider.tokenPriceDai() * 1e8 * voltGNSPriceProvider.price() * uint(getDAIPrice()) / 1e18 / 1e8;
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