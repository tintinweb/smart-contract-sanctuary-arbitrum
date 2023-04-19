// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract tokenLocker {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        bool released;
    }

    mapping(address => mapping(address => Lock)) public locks;

    function lockToken(
        IERC20 token,
        uint256 amount,
        uint256 unlockTime
    ) external {
        require(amount > 0, "Amount must be greater than 0");
        require(
            unlockTime > block.timestamp,
            "Unlock time must be in the future"
        );

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        locks[address(token)][msg.sender] = Lock(amount, unlockTime, false);
    }

    function releaseToken(IERC20 token) external {
        Lock memory lock = locks[address(token)][msg.sender];
        require(!lock.released, "Tokens already released");
        require(block.timestamp >= lock.unlockTime, "Tokens are still locked");

        require(token.transfer(msg.sender, lock.amount), "Transfer failed");

        locks[address(token)][msg.sender].released = true;
    }
}