/**
 *Submitted for verification at Arbiscan.io on 2023-09-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract ownedSimple {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function changeOwner(address newOwner) external onlyOwner {
            owner = newOwner;
        }
    }