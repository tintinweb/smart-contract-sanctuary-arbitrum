/**
 *Submitted for verification at Arbiscan on 2023-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

contract NumbersGameEdgar {
        uint favouriteNumber = 97;

        function setnewfavouriteNumber (uint newNumber) external {
            favouriteNumber = newNumber; 
        }

        function letsseeYourNumber() external view returns (uint) {
             return favouriteNumber;
        }
}