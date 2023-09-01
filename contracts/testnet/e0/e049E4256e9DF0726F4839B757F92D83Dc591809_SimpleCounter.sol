/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract SimpleCounter {
    uint public count = 0;

    event intAdded(address usrAddress,uint intToAdd, uint curcount,uint blocknbr);
    event intReset(address usrAddress,uint blocknbr, uint curcount);
    
    function addInteger(uint intToAdd, address usrAddress) public returns(uint) {
        count += intToAdd;
        emit intAdded(usrAddress,intToAdd,count,block.number);
        return count;
    }

    function reset(address usrAddress) public returns(uint) {
        count = 0;
        emit intReset(usrAddress,block.number, count);
        return count;
    }
}