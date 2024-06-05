/**
 *Submitted for verification at Arbiscan.io on 2024-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract YourContract {
    uint256 public startTime;
    
    address owner;

    event PurchaseSuccessful(address indexed user, uint256 paymentAmount, string code);

    modifier onlyDuringSale() {
        require(block.timestamp >= startTime, "Sale has not started yet");
        _;
    }

    constructor(uint256 _startTime) {
        startTime = _startTime;
        owner = msg.sender;
    }

    function whitelistedPurchaseWithCode(
        uint256 paymentAmount,
        string calldata code
    ) public onlyDuringSale {
        // Логика выполнения действия
        emit PurchaseSuccessful(msg.sender, paymentAmount, code);
    }
}