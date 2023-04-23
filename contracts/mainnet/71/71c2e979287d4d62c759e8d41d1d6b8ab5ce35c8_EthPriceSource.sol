/**
 *Submitted for verification at Arbiscan on 2023-04-22
*/

/*
  _____ _  _   _ ___ _   _ ___   ___ ___  ___ _____ ___   ___ ___  _    
 |_   _/_\| | | | _ \ | | / __| | _ \ _ \/ _ \_   _/ _ \ / __/ _ \| |   
   | |/ _ \ |_| |   / |_| \__ \ |  _/   / (_) || || (_) | (_| (_) | |__ 
   |_/_/ \_\___/|_|_\\___/|___/ |_| |_|_\\___/ |_| \___/ \___\___/|____|
   
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IETH {
    function shareToAssetsPrice() external view returns(uint);
}

interface IChainlinkPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract EthPriceSource {
    
    IETH public Eth;
    IChainlinkPrice public chainlink;

    constructor(address Eth_, address chainlink_) {
		Eth = IETH(Eth_);
        chainlink = IChainlinkPrice(chainlink_);
    } 

	function getPrice() external view returns(uint) {
        return Eth.shareToAssetsPrice() * uint(getDAIPrice()) / 1e8;
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