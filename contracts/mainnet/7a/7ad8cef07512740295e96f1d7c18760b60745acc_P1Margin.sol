/**
 *Submitted for verification at Arbiscan on 2022-10-28
*/

// To make function signature visible on block explorer
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma abicoder v2;

contract P1Margin
{
    string constant internal NATIVE_TOKEN = "AVAX";

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
        address destination,
        string token_symbol,
        uint256 amount,
        uint256 withdrawid,
        uint256 gasfee,
        bytes32 funding
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
        address account,
        address payable destination,
        string calldata token_symbol,
        uint256 amount,
        uint256 withdrawid,
        uint256 gasfee,
        Int calldata funding,
        bytes32 r, 
        bytes32 s,
        uint8 v
    )
        external
    {
        emit LogWithdraw(
            account,
            destination,
            token_symbol,
            amount,
            withdrawid,
            gasfee,
            bytes32(funding.value)
        );
    }

}