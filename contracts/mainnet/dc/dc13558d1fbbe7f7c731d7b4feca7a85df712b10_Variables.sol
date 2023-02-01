/**
 *Submitted for verification at Arbiscan on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Variables {
    // State variables are stored on the blockchain.
    string public text = "\xF0\x9F\x87\xBA\xF0\x9F\x87\xA6\x20\xF0\x9F\x92\x99\x20\xF0\x9F\x92\x9B\x20 Stand with Ukraine! \xF0\x9F\x92\xAA\xF0\x9F\x92\xAA\xF0\x9F\x92\xAA";
    uint public num = 999;

    function doSomething() public {
        // Local variables are not saved to the blockchain.
        uint i = 888;

        // Here are some global variables
        uint timestamp = block.timestamp; // Current block timestamp
        address sender = msg.sender; // address of the caller
    }
}