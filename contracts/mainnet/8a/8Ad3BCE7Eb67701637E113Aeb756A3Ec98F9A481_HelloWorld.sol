// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract HelloWorld {
  uint256 public storedInteger;
  string public message;

  constructor() {
    message = "Thank you Crypto Currency State for this tutorial";
  }

  function increment() public {
    storedInteger += 1; 
  }
}