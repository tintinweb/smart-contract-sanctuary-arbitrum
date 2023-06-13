/**
 *Submitted for verification at Arbiscan on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGMDETH {
   
    function GDpriceToStakedtoken(uint256 _pid) external view returns(uint256);
}


contract EthPriceFeed {
    IGMDETH public GMDEthContract;
 
    mapping(uint =>  function () view returns (uint256)) funcMap;

    constructor(address _gmdeth) {
        GMDEthContract = IGMDETH(_gmdeth);
       
        funcMap[0] = getPooledEthByShares;
        funcMap[1] = getEthExchangeRate;
 
    }


    function getPooledEthByShares() public view returns (uint256) {
        return GMDEthContract.GDpriceToStakedtoken(1);
    }

    function getEthExchangeRate() public pure returns (uint256) {
        return 1e18;
    }

    function getPrice(uint id) public view returns (uint256) {
        return funcMap[id]();
    }

}