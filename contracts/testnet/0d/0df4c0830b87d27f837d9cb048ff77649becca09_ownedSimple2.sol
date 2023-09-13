/**
 *Submitted for verification at Arbiscan.io on 2023-09-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract ownedSimple2 {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function getOwner() public view returns(address) {
        return owner;
    }
}