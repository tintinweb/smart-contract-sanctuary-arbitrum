/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {

    bytes32[] proposalNames;

    mapping(uint256 => uint256) _map;
    uint256 length;

    function test(uint256 index) external
    {
        uint256[] memory list = new uint256[](index);
        for(uint256 i=0; i<index; i++)
        {
            _map[i] = i;
            list[i] = i+100;
        }
        length += index;
    }
}