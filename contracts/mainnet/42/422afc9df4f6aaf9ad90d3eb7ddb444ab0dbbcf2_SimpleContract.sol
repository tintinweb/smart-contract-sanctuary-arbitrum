/**
 *Submitted for verification at Arbiscan.io on 2023-11-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SimpleContract {

    event LogMessage(string message);

    function logMsg(string memory _message) public {
        emit LogMessage(_message);
    }

}