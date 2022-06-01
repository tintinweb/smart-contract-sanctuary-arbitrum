// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

contract PoolCreateEvent {

    event PoolCreated(address indexed factory, bool indexed isApeXPool);

    function PoolCreate(address factory, bool isApeXPool) external {
        emit PoolCreated(factory, isApeXPool);
    }
}