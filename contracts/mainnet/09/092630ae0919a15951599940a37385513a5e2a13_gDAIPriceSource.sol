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

interface IGDAI {
    function shareToAssetsPrice() external view returns(uint);
}

interface IChainlinkPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract gDAIPriceSource {
    
    IGDAI public gDAI;
    IChainlinkPrice public chainlink;

    constructor(address gDAI_, address chainlink_) {
		gDAI = IGDAI(gDAI_);
        chainlink = IChainlinkPrice(chainlink_);
    } 

	function getPrice() external view returns(uint) {
        return gDAI.shareToAssetsPrice() * uint(getDAIPrice()) / 1e8;
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