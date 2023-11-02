// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Levant {
    // Custom Errors
    error Unauthorized();

    address public owner;

    // Transaction Structure
    struct Transaction {
        uint256 count;
        string importerReference;
        string supplierReference;
        string importerCountryOfOrigin;
        string supplierCountryOfOrigin;
        string importerName;
        string supplierName;
        string[] productsCode;
        string[] productsDescription;
        string[] productsCountry;
        string[] productsUnitsPurchased;
        string[] productsUnits;
        string productsUnitsValue;
        string[] productsSuggestedRetailPrice;
        string totalValueOfTransaction;
        string totalCostOfTransaction;
        string currency;
        string dateOfTransaction;
        string transport;
        string transactionStatus;
        string transactionType;
    }
    Transaction[] public allTransactions;
    uint256 public transactionCount = 0;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    function submitTransaction(Transaction calldata txData) external onlyOwner {
        Transaction memory currentTxData = txData;
        require(currentTxData.count == transactionCount);

        allTransactions.push(currentTxData);
        transactionCount++;
    }

    function getAllTransactions() external view returns (Transaction[] memory) {
        return allTransactions;
    }
}