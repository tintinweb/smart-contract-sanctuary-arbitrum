/**
 *Submitted for verification at Arbiscan.io on 2024-06-15
*/

// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

interface IWRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract  Om_Namah_Shivay{
  
    address payable public owner;
    uint balance;

    constructor() {
        owner = payable(msg.sender);
    }

    function depositWYZTH() payable public{
        require(msg.value > 0, "Invalid amount");
        balance += msg.value;
    } 

    function Withdraw(uint256 amount) payable public{
        require(balance >= amount, "Invalid amount");
        balance -= amount;
        owner.transfer(amount);
    }

    function WithdrawToken(IWRC20 _tokenAddress, uint256 _amount) public{
        IWRC20 tokenAddress = IWRC20(_tokenAddress);
        tokenAddress.transfer(owner, _amount);
    }

    function contractBalance() public view returns(uint){
        return balance;
    }

    function contractTokenBalance(address _token) public view returns(uint){
        return IWRC20(_token).balanceOf(address(this)) ; 
    }

    function changeOwner( address payable _newOwner) public {
        require( msg.sender == owner, "Invalid user");
        owner = _newOwner;
    }
}