/**
 *Submitted for verification at Arbiscan on 2023-01-05
*/

// To make function signature visible on block explorer
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma abicoder v2;

contract P1Margin
{
    string constant internal NATIVE_TOKEN = "ETH";

    struct Int {
        uint256 value;
        bool isPositive;
    }

    event LogDeposit(
        address indexed account,
        string token_symbol,
        uint256 amount
        //bytes32 balance
    );

    event LogWithdraw(
        address indexed account,
        string token_symbol,
        uint256 amount,
        uint256 withdrawid
    );

    function deposit(
        address account,
        string calldata token_symbol,
        uint256 amount
    )
        external
    {
        emit LogDeposit(
            account,
            token_symbol,
            amount
            //toBytes32_deposit_withdraw(account, SignedMath.Int({value:0, isPositive:false}))
        );
    }

    function depositNative(
        address account
    )
        external
        payable
    {
        emit LogDeposit(
            account,
            NATIVE_TOKEN,
            msg.value
        );
    }

    function withdraw(
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
            token_symbol,
            amount,
            withdrawid
        );
    }

}