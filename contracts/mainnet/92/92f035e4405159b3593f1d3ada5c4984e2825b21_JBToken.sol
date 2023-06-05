/**
 *Submitted for verification at Arbiscan on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JBToken {
    string public name = "JB";
    string public symbol = "JB";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;
    bool public buyOnly;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BuyOnlyEnabled();
    event BuyOnlyDisabled();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalSupply = 1000000 * (10**uint256(decimals));
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function enableBuyOnly() external onlyOwner {
        buyOnly = true;
        emit BuyOnlyEnabled();
    }

    function disableBuyOnly() external onlyOwner {
        buyOnly = false;
        emit BuyOnlyDisabled();
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
}