/**
 *Submitted for verification at Arbiscan on 2023-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// Used by relay to watch logs instead of transactions/blocks.
contract RelayProxy {
    event Deposit(address indexed to, uint256 balance);
    event Execute(address indexed from, uint256 balance);

    function deposit(address to) external payable returns (bool success) {
        (success, ) = to.call{value: msg.value}(new bytes(0));
        emit Deposit(to, to.balance);
    }

    function execute(
        address to,
        bytes memory data
    ) external payable returns (bool success, bytes memory returnData) {
        (success, returnData) = to.call{value: msg.value}(data);
        address sender = msg.sender;
        emit Execute(sender, sender.balance);
    }
}