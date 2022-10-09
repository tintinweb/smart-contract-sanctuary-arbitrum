// SPDX-License-Identifier: Do-Whatever-You-Want-With-This-License
pragma solidity ^0.8.9;

contract Lock {
    mapping (address => uint256) public lockedBalance;
    mapping (address => uint256) public unlockTime;

    event Withdrawal(uint amount, uint when);
    event Locking(uint amount, uint unlockTime);

    function lock(uint256 time) public payable {
        require(block.timestamp < time, "Unlock time should be in the future");

        unlockTime[msg.sender] = time;
        lockedBalance[msg.sender] = msg.value;

        emit Locking(msg.value, time);
    }

    function withdraw() public {
        require(block.timestamp >= unlockTime[msg.sender], "You can't withdraw yet");

        payable(msg.sender).transfer(lockedBalance[msg.sender]);
        emit Withdrawal(lockedBalance[msg.sender], block.timestamp);

        lockedBalance[msg.sender] = 0;
        unlockTime[msg.sender] = 0;
    }
}