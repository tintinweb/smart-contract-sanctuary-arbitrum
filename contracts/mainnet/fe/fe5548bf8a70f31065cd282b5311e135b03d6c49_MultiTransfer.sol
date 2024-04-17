// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract MultiTransfer is ReentrancyGuard{


    function multiTransfer(address coin_address,uint256[] memory amounts,address[] memory toAddresses) public {
        ERC20 erc20 = ERC20(coin_address);
        require(amounts.length>0,"size must bigger than zero");
        require(amounts.length==toAddresses.length,"amount size must equals address size");
        for(uint i=0;i<amounts.length;i++){
            erc20.transferFrom(msg.sender,toAddresses[i],amounts[i]);
        }
    }


    constructor(){
    }
}