/**
 *Submitted for verification at Arbiscan on 2022-11-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

// import "hardhat/console.sol";

contract Greeter {
  string greeting;

  constructor(string memory _greeting) {
//    console.log("Deploying a Greeter with greeting:", _greeting);
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
//    console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
    greeting = _greeting;
  }
}