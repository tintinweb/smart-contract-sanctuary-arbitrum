/**
 *Submitted for verification at Arbiscan.io on 2024-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
contract FunctionTypes{
    uint256 public number = 5;
    
    constructor() payable {}

    function add() external{
        number = number + 1;
    }

    function addPure(uint256 _number) external pure returns(uint256 new_number){
        new_number = _number+1;
    }
    
    function addView() external view returns(uint256 new_number) {
        new_number = number + 1;
    }

    function minus() internal {
        number = number - 1;
    }

    function minusCall() external {
        minus();
    }

    function minusPayable() external payable returns(uint256 balance) {
        minus();    
        balance = address(this).balance;
    }
}