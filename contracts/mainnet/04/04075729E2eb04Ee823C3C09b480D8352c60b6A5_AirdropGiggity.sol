/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract AirdropGiggity{
    uint256 public amountAllowed = 1000000000000;
    address public tokenContract;   
    mapping(address => bool) public requestedAddress;

    event SendToken(address indexed Receiver, uint256 indexed Amount); 

    constructor(address _tokenContract) {
    tokenContract = _tokenContract; 
    }

    function requestTokens() external {
    require(requestedAddress[msg.sender] == false, "Can't Request Multiple Times!");
      IERC20 token = IERC20(tokenContract);
     require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!"); 
    token.transfer(msg.sender, amountAllowed);
    requestedAddress[msg.sender] = true;
    emit SendToken(msg.sender, amountAllowed);
}

}