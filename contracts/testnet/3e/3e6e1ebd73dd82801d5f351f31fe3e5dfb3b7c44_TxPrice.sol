/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1
    ONLY FOR TEST
    DO NOT DEPLOY IN PRODUCTION ENV
*/
pragma solidity 0.8.9;

contract TxPrice {

    function getTxPrice() view external returns(uint256){
        return tx.gasprice;
    }

}