/**
 *Submitted for verification at Arbiscan on 2023-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenAirdrop {
    address public tokenAddress;
    address[] public recipients;
    uint256[] public amounts;
    address public owner;

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Invalid token address");
        tokenAddress = _tokenAddress;
        owner = msg.sender;
    }

    function setAirdropData(address[] memory _recipients, uint256[] memory _amounts) public {
        require(msg.sender == owner, "Only the contract owner can call this function");
        require(_recipients.length == _amounts.length, "Lengths of recipients and amounts arrays do not match");
        require(_recipients.length > 0, "Recipient list is empty");

        recipients = _recipients;
        amounts = _amounts;
    }

    function airdropTokens() public {
        require(msg.sender == owner, "Only the contract owner can call this function");
        require(recipients.length > 0, "Recipient list is empty");

        IERC20 tokenContract = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(amounts[i] > 0, "Amount should be greater than 0");
            tokenContract.transfer(recipients[i], amounts[i]);
        }
    }

    function withdrawTokens() public {
        require(msg.sender == owner, "Only the contract owner can call this function");

        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");

        tokenContract.transfer(owner, balance);
    }
}