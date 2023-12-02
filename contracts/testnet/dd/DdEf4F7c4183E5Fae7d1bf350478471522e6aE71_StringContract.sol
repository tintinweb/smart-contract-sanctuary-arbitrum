/**
 *Submitted for verification at Arbiscan.io on 2023-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StringContract {
    string public myString; // Publicly accessible string variable
    event StringChanged(address indexed account, string indexed newString); // Event to emit when the string changes

    // Function to update the string variable
    function updateString(string memory newString) public {
        myString = newString;
        emit StringChanged(msg.sender,newString); // Emit the event with the updated string
    }

    function callUpdate() public{
        updateString("");
    }

    function setZeroByte() public{
        
    }
}