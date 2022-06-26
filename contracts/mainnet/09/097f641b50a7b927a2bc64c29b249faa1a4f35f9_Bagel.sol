/**
 *Submitted for verification at Arbiscan on 2022-06-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

contract Bagel {
    uint256 public s_variable = 0;
    uint256 public s_otherVar = 0;
    address _owner; 

    constructor() {
        _owner = msg.sender;
    }

    function doSomething() external {
        s_variable = 123;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function when() public pure returns (string memory)
    {
        return "moon?"; 
    }
}