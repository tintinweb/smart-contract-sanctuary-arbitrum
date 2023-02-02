// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.17;

contract TestDeploy {

    

    function getBalanceETH(address user) public view returns (uint256, address){
        return (user.balance, user);
    }
}