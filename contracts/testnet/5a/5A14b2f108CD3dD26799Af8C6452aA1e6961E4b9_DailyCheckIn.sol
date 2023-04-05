/**
 *Submitted for verification at Arbiscan on 2023-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DailyCheckIn {
    mapping(address => uint256) private lastCheckIn;
    mapping(address => uint256) private lastCheckInCount;

    event CheckedIn(address indexed user, uint256 date);


    function checkIn() public {
        uint256 today = block.timestamp / 1 days; 
        uint256 lastCheckInDate = lastCheckIn[msg.sender];
        require(lastCheckInDate < today, "Already checked in today");
        lastCheckIn[msg.sender] = block.timestamp;
        lastCheckInCount[msg.sender] = lastCheckInCount[msg.sender] + 1;
        emit CheckedIn(msg.sender, today);
    }


    function getLastCheckInDate(address user) public view returns (uint256) {
        return lastCheckIn[user];
    }


    function getLastCheckInCount(address user) public view returns (uint256) {
        return lastCheckInCount[user];
    }
}