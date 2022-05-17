/**
 *Submitted for verification at Arbiscan on 2022-05-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 number;
    uint256 num2;

    function celsius(uint256 num) public {
        num2 = ( num * 9 / 5 ) + 32;
        number = num2;
    }

    function fahrenheit() public view returns (uint256){
        return number;
    }
}