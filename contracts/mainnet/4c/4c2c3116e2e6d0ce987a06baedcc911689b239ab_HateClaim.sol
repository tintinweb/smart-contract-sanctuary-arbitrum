// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract HateClaim is Ownable {
    ERC20 public token;
    mapping(address => bool) public hasClaimed;
    uint256 public claimAmount;
    uint256 public startTime;
    uint256 public endTime;

    constructor(ERC20 _token) {
        token = _token;
    }

    function StartClaim(uint256 _startTime, uint256 _endTime, uint256 _claimAmount) public onlyOwner {
        claimAmount = _claimAmount;
        startTime = _startTime;
        endTime = _endTime;
    }

    function Claim() public {
        require(block.timestamp >= startTime, "Claim period has not started");
        require(block.timestamp <= endTime, "Claim period has ended");
        require(!hasClaimed[msg.sender], "You have already claimed your tokens");
        
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= claimAmount, "Not enough tokens left in the contract");

        token.transfer(msg.sender, claimAmount);
        hasClaimed[msg.sender] = true;
    }

    function ClaimFor(address wallet) public {
        require(block.timestamp >= startTime, "Claim period has not started");
        require(block.timestamp <= endTime, "Claim period has ended");
        require(!hasClaimed[wallet], "This wallet has already claimed its tokens");
        
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= claimAmount, "Not enough tokens left in the contract");

        token.transfer(wallet, claimAmount);
        hasClaimed[wallet] = true;
    }

    function withdrawERC20(ERC20 _token) public onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        _token.transfer(owner(), balance);
    }

    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        payable(owner()).transfer(balance);
    }
}