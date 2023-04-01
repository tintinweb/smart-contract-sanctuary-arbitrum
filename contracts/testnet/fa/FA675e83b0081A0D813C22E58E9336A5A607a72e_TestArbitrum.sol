/**
 *Submitted for verification at Arbiscan on 2023-03-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestArbitrum {
  string private name;

  function setName(string memory newName) public {
    name = newName;
  }

  function getName() public view returns (string memory) {
    return name;
  }
}