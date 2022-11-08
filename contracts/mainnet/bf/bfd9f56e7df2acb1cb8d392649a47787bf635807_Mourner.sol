/**
 *Submitted for verification at Arbiscan on 2022-11-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

contract Mourner {
  string mournering;

  constructor(string memory _mournering) {
//    console.log("Deploying a Greeter with mournering:", _ mournering);
   mournering = _mournering;
  }

  function greet() public view returns (string memory) {
    return mournering;
  }

  function setMournering(string memory _mournering) public {
//    console.log("Changing mournering from '%s' to '%s'", mournering, _ mournering);
   mournering = _mournering;
  }
}