// SimpleStorage.sol
// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.19;

contract SimpleStorage {
    string[] public data;
    address private owner;

    function getOwner() public view returns (address) {    
        return owner;
    }
    function addTask(string memory _data) public {
        data.push(_data);
    }

    function getAll() public view returns (string[] memory){
         return data;
    }
    
    function removeIndex(uint256 Index) public {
        require(Index < data.length, "Index out of bounds");
        data[Index] = data[data.length-1];
          data.pop();
    }

    function updateIndex(uint256 Index,string memory _data) public {
            require(Index < data.length, "Index out of bounds");
            data[Index]=_data;
    }

     function removeAll() public {
        data = new string[](0);
    }
}