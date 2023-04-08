/**
 *Submitted for verification at Arbiscan on 2023-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma abicoder v2;

contract P1Margin
{
    string constant internal NATIVE_TOKEN = "ETH";

    // struct Int {
    //     uint256 value;
    //     bool isPositive;
    // }

    event LogDeposit(
        address indexed account,
        uint8 account_type,
        string token_symbol,
        uint256 amount
    );

    event LogWithdraw(
        address indexed account,
        uint8 account_type,
        string token_symbol,
        uint256 amount,
        uint256 withdrawid
    );
    
    function deposit(
        address account,
        uint8 account_type,
        string calldata token_symbol,
        uint256 amount
    )
        external
    {
        emit LogDeposit(
            account,
            account_type,
            token_symbol,
            amount
        );
    }

    function depositNative(
        address account,
        uint8 account_type
    )
        external
        payable
    {
        emit LogDeposit(
            account,
            account_type,
            NATIVE_TOKEN,
            msg.value
        );
    }

    function withdraw(
        uint8 account_type,
        string calldata token_symbol,
        uint256 amount,
        uint256 withdrawid,
        uint256 timestamp,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        external
    {
        emit LogWithdraw(
            msg.sender,
            account_type,
            token_symbol,
            amount,
            withdrawid
        );
    }

}