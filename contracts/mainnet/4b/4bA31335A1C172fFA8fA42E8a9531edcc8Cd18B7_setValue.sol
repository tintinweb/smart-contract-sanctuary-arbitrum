// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity 0.8.19;

contract setValue {
    uint public num;
    function setNum(uint _num) public {
        num = _num;
    }
}