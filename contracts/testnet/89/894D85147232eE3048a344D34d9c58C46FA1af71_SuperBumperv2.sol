/**
 *Submitted for verification at Arbiscan.io on 2023-09-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.19;

/**
 * @title Bump
 */
contract SuperBumperv2 {

    uint256 public number;
    event Bump(address indexed addr, uint indexed num, bool test);

    function bump() public {
        number += 1;
        emit Bump(msg.sender, number, true);
    }
}