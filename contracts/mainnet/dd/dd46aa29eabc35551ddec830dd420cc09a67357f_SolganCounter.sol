/**
 *Submitted for verification at Arbiscan on 2022-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SolganCounter{
    mapping(string => uint) slogans;

    function input_slogan(string memory slogan) public {
        slogans[slogan] += 1;
    }

    function get_slogan_count(string memory slogan) public view returns(uint){
        return slogans[slogan];
    }
}