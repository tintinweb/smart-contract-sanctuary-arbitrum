/**
 *Submitted for verification at Arbiscan on 2022-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;


interface VestaGMXOracleLike {
    function TARGET_DIGITS() external view returns(uint);
    function getExternalPrice(address _token) external view returns (uint); 
}

contract GMXOracle {
    VestaGMXOracleLike constant ORACLE = VestaGMXOracleLike(0x43CFDad2BD42A9a7B2935a6e8094F6F8D28031a1);
    address constant GMX = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;

    function decimals() external view returns(uint8) {
        return uint8(ORACLE.TARGET_DIGITS());
    }

    function latestRoundData() public view returns(uint80 /* roundId */,int256 answer,uint256 /* startedAt */,uint256 timestamp,uint80 /* answeredInRound */) {
        timestamp = now;
        answer = int(ORACLE.getExternalPrice(GMX));
    }

}

interface DPXOralceLike {
    function getPriceInUSD() external view returns (uint); 
}

contract DPXOracle {
    DPXOralceLike constant ORACLE = DPXOralceLike(0x252C07E0356d3B1a8cE273E39885b094053137b9);

    function decimals() external pure returns(uint8) {
        return 8;
    }

    function latestRoundData() public view returns(uint80 /* roundId */,int256 answer,uint256 /* startedAt */,uint256 timestamp,uint80 /* answeredInRound */) {
        timestamp = now;
        answer = int(ORACLE.getPriceInUSD());
    } 
}