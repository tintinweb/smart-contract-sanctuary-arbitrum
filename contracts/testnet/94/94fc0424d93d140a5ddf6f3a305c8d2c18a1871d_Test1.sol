/**
 *Submitted for verification at Arbiscan on 2023-05-26
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
 
 
contract Test1 {
    uint public myUint;

    function setUint(uint _myUint) public {
        myUint = _myUint;
    }

    function killme() public {
        selfdestruct(payable(msg.sender));
    }
}