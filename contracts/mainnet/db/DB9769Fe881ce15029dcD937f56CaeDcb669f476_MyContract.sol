// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    // uint256 public immutable startTime;
    uint256 public remainingTokens = 5;

    // constructor(uint256 _startTime) {
    //     require(block.timestamp < _startTime, 'start timestamp too early');
    //     startTime = _startTime;
    // }

    // Read remainingTokens
    function getRemainingTokens() public view returns (uint256) {
        return remainingTokens;
    }

    function purchase(uint256 _amount) public {
        // require(startTime <= block.timestamp, 'sale has not begun');
        require(_amount <= remainingTokens, "Not enough tokens left");

        remainingTokens -= _amount;
    }
}