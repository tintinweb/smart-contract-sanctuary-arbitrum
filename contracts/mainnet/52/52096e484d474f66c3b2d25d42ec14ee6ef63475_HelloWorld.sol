/**
 *Submitted for verification at Arbiscan on 2022-11-05
*/

// Specifies the version of Solidity, using semantic versioning.

pragma solidity ^0.7.0;

// Defines a contract named `HelloWorld`

contract HelloWorld {

   // Declares a state variable `message` of type `string`.

   string public message;

   // Constructors are used to initialize the contract's data.

   constructor(string memory initMessage) {

      // Accepts a string argument `initMessage`.

      message = initMessage;
   }

   // A public function that accepts a string argument.

   function update(string memory newMessage) public {
      message = newMessage;
   }
}