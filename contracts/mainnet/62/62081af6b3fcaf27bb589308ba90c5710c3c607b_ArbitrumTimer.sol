/**
 *Submitted for verification at Arbiscan on 2023-02-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ArbitrumTimer {
    event SaleStarted(uint256 tokensPerWei, uint128 startTime, uint128 endTime, uint128 tier2ClaimTime, uint128 tier3ClaimTime);

    uint128 public start = 0;
    uint256 public executedTimestamp = 0;

    function setStart(uint128 _startTime) public {
        start = _startTime;
        executedTimestamp = 0;
        emit SaleStarted(0, _startTime, 0, 0, 0);
    }

    function execute() public payable {
        require(block.timestamp > start && start > 0, "NotStarted");
        executedTimestamp = block.timestamp;
        payable(msg.sender).transfer(msg.value);
    }
}