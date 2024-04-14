/**
 *Submitted for verification at Arbiscan.io on 2024-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Paywall {
    address public owner;
    uint256 public amountToPay = 0.001 ether;
    mapping(address => bool) public whitelist;

    event Payment(address indexed payer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function purchase() external payable {
        require(msg.value >= amountToPay, "Insufficient payment amount");
        
        whitelist[msg.sender] = true;
        emit Payment(msg.sender, msg.value);
    }

    function setAmountToPay(uint256 _amount) external onlyOwner {
        amountToPay = _amount;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return whitelist[_address];
    }
}