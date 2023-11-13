/**
 *Submitted for verification at Arbiscan.io on 2023-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    }





//********************************************************************************************
//***********************      HERE STARTS THE CODE OF CONTRACT     **************************
//********************************************************************************************

contract PaymentSplitter {

// simplified version of ownable (to save gas)
    address private _owner;
    constructor() {_owner = msg.sender;}
    modifier onlyOwner() {require(_owner == msg.sender, "Ownable: caller is not the owner"); _;}

// function necessary to receive the native token of the blockchain
    receive() external payable {}

// variables
    address[] public Partners;
    error AlreadyExist();
    error Not_Enough_To_Distribute();

// onlyOwner functions
    function addPartnerWallet(address _addr) external onlyOwner {
        for (uint256 i = 0; i < Partners.length; i++) {
            if (Partners[i] == _addr) {revert AlreadyExist();}
        }
        Partners.push(_addr);
        }
    function removePartnerWallet(address _addr) external onlyOwner {
        for (uint256 i = 0; i < Partners.length; i++) {
            if (Partners[i] == _addr) {
                Partners[i] = Partners[Partners.length - 1];
                Partners.pop();
            }
        }
    }

// view functions
    function getPartnerNumber(address _addr) external view returns (uint256) {
        for (uint256 i = 0; i < Partners.length; i++) {
            if (Partners[i] == _addr) {return i;}
        }
        return 0;
    }

// token distribution
    function distribute_ERC20_Token (IERC20 token) external {
        uint256 balance = token.balanceOf(address(this));
        if (Partners.length > balance) {revert Not_Enough_To_Distribute();}
        uint256 PartnerAmount = balance/Partners.length;
        for (uint256 i = 0; i < Partners.length; i++) {
            token.transfer(Partners[i], PartnerAmount);
        }
    }
    function distribute_Native_Token () external {
        uint256 balance = address(this).balance;
        if (Partners.length > balance) {revert Not_Enough_To_Distribute();}
        uint256 PartnerAmount = balance/Partners.length;
        for (uint256 i = 0; i < Partners.length; i++) {
            payable(Partners[i]).transfer(PartnerAmount);
        }
    }
}