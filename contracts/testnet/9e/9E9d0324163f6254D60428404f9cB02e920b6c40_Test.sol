/**
 *Submitted for verification at Arbiscan on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Test{

    string public myName;

    function set(string memory _name) public {
        myName = _name;
    }

    function get() public view returns(string memory) {
        return myName;
    }
}