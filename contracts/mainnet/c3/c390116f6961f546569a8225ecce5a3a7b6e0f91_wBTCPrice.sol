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

interface IWBTC {
    function shareToAssetsPrice() external view returns(uint);
}

interface IChainlinkPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract wBTCPrice {
    
    IWBTC public wBTC;
    IChainlinkPrice public chainlink;

    constructor(address wBTC_, address chainlink_) {
		wBTC = IWBTC(wBTC_);
        chainlink = IChainlinkPrice(chainlink_);
    } 

    function getPrice() public view returns(int256) {
        if(address(chainlink) == address(0)) return 1e8;
        (,int256 assetChainlinkPriceInt,,,) = chainlink.latestRoundData();

        if(assetChainlinkPriceInt != 0) {
            return assetChainlinkPriceInt;
        }
        return 1e8;
    }
}