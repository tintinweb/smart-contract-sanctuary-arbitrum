// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract PingContract {
    event Ping(address addr);

    function ping() external payable {
        emit Ping(msg.sender);
    }
}