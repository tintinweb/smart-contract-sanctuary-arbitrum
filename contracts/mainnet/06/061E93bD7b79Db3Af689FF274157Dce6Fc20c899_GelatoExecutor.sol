// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICreditRewardTracker {
    function execute() external;
}

contract GelatoExecutor {
    uint256 public lastExecuted;
    address public creditRewardTracker;

    event Succeed(address _sender, uint256 _timestamp);
    event Failed(address _sender, uint256 _timestamp);

    constructor(address _creditRewardTracker) {
        creditRewardTracker = _creditRewardTracker;
    }

    function execute() external {
        lastExecuted = block.timestamp;

        try ICreditRewardTracker(creditRewardTracker).execute() {
            emit Succeed(msg.sender, block.timestamp);
        } catch {
            emit Failed(msg.sender, block.timestamp);
        }
    }
}