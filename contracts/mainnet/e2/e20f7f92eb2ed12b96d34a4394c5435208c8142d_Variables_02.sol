/**
 *Submitted for verification at Arbiscan on 2023-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Variables_02 {
    // State variables are stored on the blockchain.
    string public text = "Hello World! \xF0\x9F\x91\x8B";
    uint public num = 211;

    function doSomething() public {
        // Local variables are not saved to the blockchain.
        uint i = 112;

        // Here are some global variables
        uint timestamp = block.timestamp; // Current block timestamp
        address sender = msg.sender; // address of the caller
    }
}