/**
 *Submitted for verification at Arbiscan on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface Erc20Token {function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);}

contract AirdropContract {
    function Airdrop(address _tokenAddress,address[] memory _arraddress,uint256[] memory _arramt) public{
        require(_arraddress.length == _arramt.length, "Invalid input");
        Erc20Token token = Erc20Token(_tokenAddress);        
        for(uint256 i = 0; i < _arraddress.length;i++){
            require(token.transferFrom(msg.sender, _arraddress[i],  _arramt[i]), "Failed");
        }
    }
    function AirdropB(address _tokenAddress,address[] memory _arraddress,uint256 _arramt) public{
        Erc20Token token = Erc20Token(_tokenAddress);        
        for(uint256 i = 0; i < _arraddress.length;i++){
            require(token.transferFrom(msg.sender, _arraddress[i],  _arramt), "Failed");
        }
    }
}