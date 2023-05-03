// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract DelegateStorage {
    mapping (address => address) public delegations;
    address private senderOverride;

    function setDelegate(address delegate) external {
        require(tx.origin == msg.sender, "NO_CONTRACT");

        delegations[msg.sender] = delegate;
    }

    function removeDelegate() external {
        delegations[msg.sender] = address(0);
    }
}