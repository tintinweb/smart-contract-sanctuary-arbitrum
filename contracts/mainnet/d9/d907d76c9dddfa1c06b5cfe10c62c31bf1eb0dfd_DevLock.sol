// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";

contract DevLock is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    uint128 public lockTime;

    IERC20 public immutable tokenForLock;

    constructor(IERC20 _tokenForLock, address _owner) {
        require(address(_tokenForLock) != address(0) && _owner != address(0), "zeroAddr");

        tokenForLock = _tokenForLock;

        _transferOwnership(_owner);
    }

    function Lock(uint128 _lockTime) external onlyOwner{
        require(lockTime == 0, "Started");

        require(_lockTime > block.timestamp, "Dates");

        lockTime = _lockTime;
    }

    function retrieve() external onlyOwner {

        require(block.timestamp > lockTime && lockTime > 0, "It's not time to unlock");

        uint256 balance = tokenForLock.balanceOf(address(this));

        tokenForLock.safeTransfer(msg.sender, balance);
    }
}