/**
 *Submitted for verification at Arbiscan on 2023-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    // State variable to store a number
    uint public num;

    // You need to send a transaction to write to a state variable.
    function set(uint _num) public {
        num = _num;
    }

    // You can read from a state variable without sending a transaction.
    function get() public view returns (uint) {
        return num;
    }

    function StandWithUkraine() external pure returns (string memory) {
        return "\xF0\x9F\x87\xBA\xF0\x9F\x87\xA6\x20\xF0\x9F\x92\x99\x20\xF0\x9F\x92\x9B\x20 Stand with Ukraine! \xF0\x9F\x92\xAA\xF0\x9F\x92\xAA\xF0\x9F\x92\xAA";
    }
}