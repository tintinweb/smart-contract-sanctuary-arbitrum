/**
 *Submitted for verification at Arbiscan.io on 2023-09-26
*/

// LICENSE : MIT

pragma solidity ^0.8.0;

contract Logger {
    event Log(string);

    function emitEvent() public {
        emit Log("proba");
    }
}