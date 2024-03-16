// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract KillTracker {
    mapping (address => uint256) private kills;
    address[] private addresses;

    function addKillsForSender(uint256 _kills) public {
        if (kills[msg.sender] == 0) {
            addresses.push(msg.sender); // Add new address to the list
        }
        kills[msg.sender] += _kills;
    }

    function getKillsForAddress(address _address) public view returns (uint256) {
        return kills[_address];
    }

    function getAllKills() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory killCounts = new uint256[](addresses.length);
        
        for (uint256 i = 0; i < addresses.length; i++) {
            killCounts[i] = kills[addresses[i]];
        }
        
        return (addresses, killCounts);
    }
}