/**
 *Submitted for verification at Arbiscan on 2022-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;


interface DPXOralceLike {
    function getPriceInUSD() external view returns (uint); 
}

contract DPXOracle {
    DPXOralceLike constant ORACLE = DPXOralceLike(0x252C07E0356d3B1a8cE273E39885b094053137b9);

    function decimals() external pure returns(uint8) {
        return 8;
    }

    function latestRound() public view returns(uint80 /* roundId */,int256 answer,uint256 /* startedAt */,uint256 timestamp,uint80 /* answeredInRound */) {
        timestamp = now;
        answer = int(ORACLE.getPriceInUSD());
    } 
}