/**
 *Submitted for verification at Arbiscan on 2022-12-08
*/

//SPDX-License-Identifier: UNLICENSED

//Contract to send message on chain

pragma solidity 0.8.13;

contract TPD_Deployer_Wallet_Verify {

    string public message;
    modifier onlyOwner {
        require(msg.sender == 0x45AA6F62484DAb78ADCbE42A8456Cd09aB88DeC9, "Not the Owner of TPD");
        _;
    }
    constructor(string memory _message) {
        message = _message;
    }
}