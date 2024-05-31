// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract DelabsDailyJourney {
        
    mapping(address=>uint256) public totalCheckin;
    mapping(address=>uint256) public totalDraws;
  
    event DailyCheckin(address indexed walletAddress);
    event DailyDraw(address indexed walletAddress);

    function dailyDraw() external {
        totalDraws[msg.sender] += 1;
        
        emit DailyDraw(msg.sender);
    }

    function dailyCheckin() external {
        totalCheckin[msg.sender] += 1;
        
        emit DailyCheckin(msg.sender);
    }
}