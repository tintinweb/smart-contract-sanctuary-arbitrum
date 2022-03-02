/**
 *Submitted for verification at arbiscan.io on 2022-03-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7 ;


contract Send {


    function send(address[] calldata users, uint amt) external payable {

        uint len = users.length;

        require(msg.value == amt*len, "Wrong amount");

        for (uint n=0; n<len; n++) {

            (bool success, ) = users[n].call {
                value: amt
            }("");
            require(success, "Transfer failed");
        }
    }
}