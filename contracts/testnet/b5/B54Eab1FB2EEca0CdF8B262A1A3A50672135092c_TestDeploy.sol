// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.17;

contract TestDeploy {

    function getBalanceETH() public view returns (uint256, address){
        address sender = msg.sender;
        return (sender.balance, sender);
    }
}