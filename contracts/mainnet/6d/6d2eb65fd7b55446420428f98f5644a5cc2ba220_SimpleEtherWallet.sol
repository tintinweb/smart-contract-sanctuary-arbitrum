/**
 *Submitted for verification at Arbiscan on 2023-03-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract SimpleEtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }
    
    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "Only the Owner call this method");
        payable(msg.sender).transfer(_amount);
    }
    
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

}