/**
 *Submitted for verification at Arbiscan on 2022-11-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

contract Omega {
  string omegaing;

  constructor(string memory _omegaing) {
//    console.log("Deploying a Greeter with omegaing:", _omegaing);
   omegaing = _omegaing;
  }

  function omega() public view returns (string memory) {
    return omegaing;
  }

  function setOmegaing (string memory _omegaing) public {
//    console.log("Changing omegaing from '%s' to '%s'", omegaing, _omegaing);
   omegaing = _omegaing;
  }
}