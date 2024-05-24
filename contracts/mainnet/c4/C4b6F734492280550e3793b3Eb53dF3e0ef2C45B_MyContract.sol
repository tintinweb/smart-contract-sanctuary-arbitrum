// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    uint256 public remainingTokens = 3;

    // Read remainingTokens
    function getRemainingTokens() public view returns (uint256) {
        return remainingTokens;
    }

    function purchase(uint256 _amount) public {
        require(_amount <= remainingTokens, "Not enough tokens left");
        remainingTokens -= _amount;
    }
}