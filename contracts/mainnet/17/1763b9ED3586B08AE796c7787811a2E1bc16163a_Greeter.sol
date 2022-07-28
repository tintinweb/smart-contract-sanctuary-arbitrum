/**
 *Submitted for verification at Arbiscan on 2022-07-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

contract Greeter {
  event MessageUpdated(string newMessage);
  string public message;

  constructor() {}

  function setMessage(string memory newMessage) public {
    message = newMessage;
    emit MessageUpdated(newMessage);
  }
}