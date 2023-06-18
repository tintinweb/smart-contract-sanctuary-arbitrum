/**
 *Submitted for verification at Arbiscan on 2023-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MinimalReceiver {
    event Received(address sender, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}