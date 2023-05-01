/**
 *Submitted for verification at Arbiscan on 2023-04-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Airdrop {
    address public owner;
    address public tokenAddress;
    uint256 public fee = 250000000000000;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    function setFee(uint256 _fee) external {
        require(msg.sender == owner, "Only owner can call this function.");
        fee = _fee;
    }

    function claim() external {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= 1500, "Airdrop has been depleted.");
        require(IERC20(tokenAddress).transfer(msg.sender, 1500), "Failed to transfer token.");
        require(IERC20(tokenAddress).transfer(owner, fee), "Failed to transfer fee.");
    }
}