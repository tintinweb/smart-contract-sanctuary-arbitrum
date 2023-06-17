/**
 *Submitted for verification at Arbiscan on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DEX {

    uint256 private price;

    function setPrice(uint256 _price) external 
    {
        price = _price;
    }

    function getPrice(address _tokenContract) external view returns (uint256)
    {
        _tokenContract;
        return price;
    }
}