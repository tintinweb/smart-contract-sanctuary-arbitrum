// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract AirdropContract {
    address public admin;
    IERC20 public token;
    mapping(address => bool) public isEligible;

    constructor(address _tokenAddress) {
        admin = msg.sender;
        token = IERC20(_tokenAddress);
    }

    function addEligibleAddress(address[] memory addresses) external {
        require(msg.sender == admin, "Only admin can add eligible addresses");
        
        for (uint256 i = 0; i < addresses.length; i++) {
            isEligible[addresses[i]] = true;
        }
    }

    function removeEligibleAddress(address[] memory addresses) external {
        require(msg.sender == admin, "Only admin can remove eligible addresses");
        
        for (uint256 i = 0; i < addresses.length; i++) {
            isEligible[addresses[i]] = false;
        }
    }

    function airdrop() external {
        require(isEligible[msg.sender], "You are not eligible for the airdrop");

        uint256 amount = 10000e18;

        // Transfer tokens to the recipient
        token.transfer(msg.sender, amount);

        // Emit the airdrop event
        emit Airdrop(msg.sender, amount);
    }

    event Airdrop(address indexed recipient, uint256 amount);
}