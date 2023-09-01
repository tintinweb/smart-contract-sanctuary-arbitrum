/**
 *Submitted for verification at Arbiscan.io on 2023-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Splitter {
    address public gasTank;
    
    event EthSplit(address indexed sender, address indexed gasTank, address indexed smartWallet, uint256 amountForGasTank, uint256 amountToSmartWallet);
    
    constructor(address _gasTank) {
        gasTank = _gasTank;
    }
    
    function splitETH(address smartWallet, uint256 amountForGasTank) external payable {
        require(amountForGasTank <= msg.value, "Amount for gasTank exceeds the received ETH");
        uint256 amountToSmartWallet = msg.value - amountForGasTank;
        
        (bool success1, ) = gasTank.call{value: amountForGasTank}("");
        require(success1, "Transfer to gasTank failed");
        
        (bool success2, ) = smartWallet.call{value: amountToSmartWallet}("");
        require(success2, "Transfer to smartWallet failed");

        emit EthSplit(msg.sender, gasTank, smartWallet, amountForGasTank, amountToSmartWallet);
    }
}