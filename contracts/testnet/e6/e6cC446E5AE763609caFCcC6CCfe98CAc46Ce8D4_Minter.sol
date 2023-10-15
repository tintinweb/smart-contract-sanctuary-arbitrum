/**
 *Submitted for verification at Arbiscan.io on 2023-10-14
*/

// SPDX-License-Identifier: MBUSL-1.1IT
pragma solidity 0.8.19;

contract Minter {

    uint256 public counter;

    constructor()
    {
        counter = 0;
    }

    function update_period() external returns (uint256)
    {
        counter++;
        return counter;
    }
}