/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract SimpleCounter {
    uint public count = 0;

    event intAdded(address indexed sndrAddress,uint indexed intToAdd, uint curcount,uint blocknbr);
    event intReset(address indexed sndrAddress,uint blocknbr, uint curcount);
    
    function addInteger(uint intToAdd) public returns(uint) {
        count += intToAdd;
        emit intAdded(msg.sender,intToAdd,count,block.number);
        return count;
    }

    function reset() public returns(uint) {
        count = 0;
        emit intReset(msg.sender,block.number, count);
        return count;
    }
}