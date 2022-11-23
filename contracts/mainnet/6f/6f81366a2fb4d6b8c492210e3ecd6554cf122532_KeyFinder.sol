/**
 *Submitted for verification at Arbiscan on 2022-11-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract KeyFinder {

    function getKey(uint256 epoch) public view returns (uint256) {
        uint256 result = uint256(uint160(msg.sender)) * (epoch**2);
        return result;
    }
}