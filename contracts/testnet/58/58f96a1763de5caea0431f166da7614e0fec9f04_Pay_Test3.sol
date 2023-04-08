/**
 *Submitted for verification at Arbiscan on 2023-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Pay_Test3 {
    string public myString="";
    address private _owner;

    constructor() {
        _owner = msg.sender;
        myString="No";
    }

    // Updates myString and then returns half the value.
    function updateString(string memory _newString) public payable {
        if (msg.value != 0 ) {
            myString = _newString;
            // Return half of the value
            payable(msg.sender).transfer(msg.value / 2);
        }
    }

    // Returns all funds in the contract to whoever calls it
    function take_funds() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Send funds to the owner
    function give_owner() public payable {
        payable(_owner).transfer(msg.value);
    }

    // Receive funds
    receive() external payable {}
}