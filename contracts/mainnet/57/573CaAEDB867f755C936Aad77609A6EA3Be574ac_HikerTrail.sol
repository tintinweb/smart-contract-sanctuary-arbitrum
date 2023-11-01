// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.7;

contract HikerTrail {
    // Define a mapping to store the elevation for each hiker
    mapping(address => uint256) public hikerElevation;

    // Function to set the elevation for a hiker
    function setElevation(uint256 _elevation) public {
        // Store the elevation for the sender
        hikerElevation[msg.sender] = _elevation;
    }

    // Function to get the elevation for a hiker
    function getElevation(address _hiker) public view returns (uint256) {
        // Return the elevation for the specified hiker
        return hikerElevation[_hiker];
    }
}