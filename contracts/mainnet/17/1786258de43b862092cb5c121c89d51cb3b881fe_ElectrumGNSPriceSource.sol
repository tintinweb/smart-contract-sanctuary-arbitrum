/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

// SPDX-License-Identifier: MIT
/**

*    ███████╗██╗░░░░░███████╗░█████╗░████████╗██████╗░░█████╗░███╗░░██╗
*    ██╔════╝██║░░░░░██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗████╗░██║
*    █████╗░░██║░░░░░█████╗░░██║░░╚═╝░░░██║░░░██████╔╝██║░░██║██╔██╗██║
*    ██╔══╝░░██║░░░░░██╔══╝░░██║░░██╗░░░██║░░░██╔══██╗██║░░██║██║╚████║
*    ███████╗███████╗███████╗╚█████╔╝░░░██║░░░██║░░██║╚█████╔╝██║░╚███║
*     ╚══════╝╚══════╝╚══════╝░╚════╝░░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝
*
*    ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
*    ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
*    █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
*    ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
*    ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
*    ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
*/

// https://twitter.com/ElectronDollar


pragma solidity 0.8.18;

interface IGNSPriceProvider {
    function tokenPriceDai() external view returns(uint);
}

interface IELECTRUMGNS {
    function price() external view returns(uint);
}

interface IChainlinkPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract ElectrumGNSPriceSource {
    
    IGNSPriceProvider public gnsPriceProvider;
    IELECTRUMGNS public electrumGNSPriceProvider;
    IChainlinkPrice public chainlink;

    constructor(address gns_, address electrumGNS_, address chainlink_) {
		gnsPriceProvider = IGNSPriceProvider(gns_);
        electrumGNSPriceProvider = IELECTRUMGNS(electrumGNS_);
        chainlink = IChainlinkPrice(chainlink_);
    } 

	function getPrice() external view returns(uint) {
        return getPriceWithoutCompound();
    }

    function getPriceWithoutCompound() public view returns(uint) {
        return gnsPriceProvider.tokenPriceDai() * 1e8 * electrumGNSPriceProvider.price() * uint(getDAIPrice()) / 1e18 / 1e8;
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