/**
 *Submitted for verification at Arbiscan.io on 2023-11-10
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.9;

contract Locker {
    struct Lock {
        address locker;
        address spender;
        uint256 amount;
        uint256 end;
    }

    event Locked(uint256 id, address indexed locker, address indexed spender, uint256 amount, uint256 end);
    event Claimed(uint256 id);

    mapping (uint256 => Lock) public locks;
    mapping (uint256 => bool) public lockClaimed;
    uint256 public totalLock;
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }


    function lock(address _spender, uint256 _duration) external payable {
        uint256 amount = msg.value;
        require(amount > 0, "Lock ZERO amount");
        uint256 end = block.timestamp + _duration;
        uint256 id = totalLock;
        locks[id] = Lock ({
            locker: msg.sender,
            spender: _spender,
            amount: amount,
            end: end
        });
        totalLock++;
        emit Locked(id, msg.sender, _spender, amount, end);
    }

   
    function claim(uint256 _lockId) external noReentrant {
        require(_lockId < totalLock, "Invalid lock id");
        bool claimed = lockClaimed[_lockId];
        require(!claimed, "Lock is CLAIMED");
        Lock memory _lock = locks[_lockId];
        address sender = msg.sender;
        require(_lock.spender == sender, "Unauthorized");
        require(block.timestamp > _lock.end, "Lock is NOT END");
        lockClaimed[_lockId] = true;
        (bool success, ) = sender.call{value: _lock.amount}("");
        require(success, "Failed to send Ether");
    }
}