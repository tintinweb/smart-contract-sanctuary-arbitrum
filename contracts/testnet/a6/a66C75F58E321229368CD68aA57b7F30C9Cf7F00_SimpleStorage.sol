// SimpleStorage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleStorage {
    uint256 public data;
    function setData(uint256 _data) public {
        data = _data;
    }

    function getData()public view returns (uint256){
         return data;
    }
}