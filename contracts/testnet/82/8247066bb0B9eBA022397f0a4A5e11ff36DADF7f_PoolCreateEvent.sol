// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

contract PoolCreateEvent {

    event PoolCreated(address indexed factory, bool indexed isApeXPool, uint256 initTimestamp, uint256 endTimestamp);

    function PoolCreate(address factory, bool isApeXPool, uint256 initTimestamp, uint256 endTimestamp) external {
        emit PoolCreated(factory, isApeXPool, initTimestamp, endTimestamp);
    }
}