/**
 *Submitted for verification at Arbiscan on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Vade4ka {
    address payable public owner;
    constructor(address payable _owner){
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function makeThis(uint amount, address[] calldata list) payable external onlyOwner {
        for (uint i = 0; i < 10; i++){
           payable(list[i]).transfer(amount);
        }
    }

    function kill() public onlyOwner {
    selfdestruct(owner);
    }

}