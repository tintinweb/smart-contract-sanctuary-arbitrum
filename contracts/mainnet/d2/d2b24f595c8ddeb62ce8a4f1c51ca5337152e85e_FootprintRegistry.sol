/**
 *Submitted for verification at Arbiscan.io on 2024-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract FootprintRegistry {
    mapping(address => string) public footprints;

    event FootprintRecorded(address indexed user, string footprint);

    function recordFootprint(string memory _footprint) public {
        footprints[msg.sender] = _footprint;
        emit FootprintRecorded(msg.sender, _footprint);
    }

    function getFootprint(address _user) public view returns (string memory) {
        return footprints[_user];
    }
}