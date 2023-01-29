/**
 *Submitted for verification at Arbiscan on 2023-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Variables {

    // State variables are stored on the blockchain.
    string public text = "Stand with Ukraine!";
    uint public num = 465;

    function doSomething() public {
        // Local variables are not saved to the blockchain.
        uint i = 111;

        // Here are some global variables
        uint timestamp = block.timestamp; // Current block timestamp
        address sender = msg.sender; // address of the caller
    }
}