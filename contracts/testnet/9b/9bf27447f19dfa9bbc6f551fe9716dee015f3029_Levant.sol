/**
 *Submitted for verification at Arbiscan.io on 2023-09-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Levant {
    // Custom Errors
    error Unauthorized();

    address public owner;

    // Transaction Structure
    struct Transaction {
        string importerCode;
        string providerCode;
        string productCode;
        string productCountryOrigin;
        string transactionCode;
        string typeOfTransaction;
        string currency;
        string transport;
        string salesPrice;
        string quantity;
        string costOfTx;
    }
    Transaction[] public allTransactions;

    // Events submitted
    event TransactionSubmitted(Transaction tx);

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
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);
        Transaction memory newTransaction = txData;
        allTransactions.push(newTransaction);
    }

    function getAllTransactions() external view returns (Transaction[] memory) {
        return allTransactions;
    }
}