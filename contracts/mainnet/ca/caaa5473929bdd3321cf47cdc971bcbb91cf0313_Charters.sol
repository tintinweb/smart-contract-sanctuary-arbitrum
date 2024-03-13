// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @notice Onchain charter solutions.
contract Charters {
    mapping(address owner => bytes data) public charters;

    event Charter(address indexed owner, bytes data);

    fallback() external payable {
        emit Charter(msg.sender, charters[msg.sender] = msg.data);
    }
}