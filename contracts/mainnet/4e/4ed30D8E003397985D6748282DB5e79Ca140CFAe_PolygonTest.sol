/**
 *Submitted for verification at Arbiscan on 2022-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract PolygonTest {

  uint256 public maxSupply = 10;
  string public testString;
  
  constructor(
    string memory _name
  ){
    testString = _name;
  }

  function setName(string memory _newName) public {
    testString = _newName;
  }

  function getName() public view returns(string memory){
    return testString;
  }

}