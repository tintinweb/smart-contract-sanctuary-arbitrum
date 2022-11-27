/**
 *Submitted for verification at Arbiscan on 2022-11-26
*/

pragma solidity ^0.7.0;

contract HelloWorld {

   string public message;

   constructor(string memory initMessage) {

      message = initMessage;
   }

   function update(string memory newMessage) public {
      message = newMessage;
   }
}