/**
 *Submitted for verification at Arbiscan.io on 2024-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract YourContract {
    uint256 public startTime;
    
    address owner;
    mapping(address => bool) public hasPurchased;  // добавляем маппинг для отслеживания покупок

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
        require(!hasPurchased[msg.sender], "You have already made a purchase"); // проверка на предыдущую покупку

        // Логика выполнения действия
        hasPurchased[msg.sender] = true;  // помечаем, что покупка была совершена
        emit PurchaseSuccessful(msg.sender, paymentAmount, code);
    }
}