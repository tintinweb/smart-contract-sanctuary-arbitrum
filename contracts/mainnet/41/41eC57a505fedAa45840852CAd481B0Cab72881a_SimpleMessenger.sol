/**
 *Submitted for verification at Arbiscan.io on 2024-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessenger {
    function notifyHTLC(
        bytes32 htlcId,
        address payable sender,
        address payable receiver,
        uint256 amount,
        uint256 timelock,
        bytes32 hashlock,
        string memory dstAddress,
        uint256 phtlcID
    ) external;
}

contract SimpleMessenger is IMessenger {
    event HTLCNotificationReceived(
        bytes32 indexed htlcId,
        address payable sender,
        address payable receiver,
        uint256 amount,
        uint256 timelock,
        bytes32 hashlock,
        string dstAddress,
        uint256 phtlcID
    );

    function notifyHTLC(
        bytes32 htlcId,
        address payable sender,
        address payable receiver,
        uint256 amount,
        uint256 timelock,
        bytes32 hashlock,
        string memory dstAddress,
        uint256 phtlcID
    ) public  override {
        emit HTLCNotificationReceived(
            htlcId,
            sender,
            receiver,
            amount,
            timelock,
            hashlock,
            dstAddress,
            phtlcID
        );
    }
}