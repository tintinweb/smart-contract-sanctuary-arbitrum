/**
 *Submitted for verification at Arbiscan.io on 2024-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256);
}

contract MyContract is ERC20 {
    ERC20 public token;

    constructor(address _tokenAddress) {
        token = ERC20(_tokenAddress);
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        return token.balanceOf(_owner);
    }
}