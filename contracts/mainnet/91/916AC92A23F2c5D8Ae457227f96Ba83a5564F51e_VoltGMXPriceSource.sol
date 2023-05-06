// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IVOLTGMX {
    function price() external view returns(uint);
    function compound() external;
}

interface IChainlinkPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

contract VoltGMXPriceSource {
    
    IVOLTGMX public voltGMXPriceProvider;
    IChainlinkPrice public chainlink;

    constructor(address voltGMX_, address chainlink_) {
        voltGMXPriceProvider = IVOLTGMX(voltGMX_);
        chainlink = IChainlinkPrice(chainlink_);
    } 

	function getPrice() external view returns(uint) {
        return getPriceWithoutCompound();
    }

    function getPriceWithoutCompound() public view returns(uint) {
        return voltGMXPriceProvider.price() * uint(getGMXPrice()) / 10 ** chainlink.decimals();
    }

    function getGMXPrice() public view returns(int256) {
        (,int256 gmxPrice,,,) = chainlink.latestRoundData();

        if(gmxPrice != 0) {
            return gmxPrice;
        }
        revert();
    }
}