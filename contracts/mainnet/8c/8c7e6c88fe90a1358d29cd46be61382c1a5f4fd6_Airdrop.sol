// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract Airdrop is Ownable {
    IERC20 public token;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public hasClaimed;
    uint256 public tokensPerClaim;

    event Claimed(address indexed claimant, uint256 amount);

    constructor(IERC20 _token, uint256 _tokensPerClaim) {
        require(address(_token) != address(0), "Invalid token address");

        token = _token;
        tokensPerClaim = _tokensPerClaim;
    }

    function addToWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function claimTokens() external {
        require(whitelist[msg.sender], "Not in whitelist");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(token.balanceOf(address(this)) >= tokensPerClaim, "Insufficient tokens for airdrop");

        token.transfer(msg.sender, tokensPerClaim);
        hasClaimed[msg.sender] = true;

        emit Claimed(msg.sender, tokensPerClaim);
    }

    function updateTokensPerClaim(uint256 _newAmount) external onlyOwner {
        tokensPerClaim = _newAmount;
    }

    function withdrawRemainingTokens() external onlyOwner {
        uint256 remainingTokens = token.balanceOf(address(this));
        require(remainingTokens > 0, "No tokens to withdraw");

        token.transfer(owner(), remainingTokens);
    }
}