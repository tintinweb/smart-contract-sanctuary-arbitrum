// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Timer {
    uint256 public startTime;

    constructor() {
        startTime = block.timestamp + 3 minutes;
    }

    function updateStartTime(uint256 newTime) external {
        startTime = newTime;
    }

    function execute() external {
        require(block.timestamp >= startTime, "Time not started");
    }

    function destroy() external {
        selfdestruct(payable(msg.sender));
    }
}