/**
 *Submitted for verification at Arbiscan.io on 2024-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract ApproveUSDT {
    IERC20 public usdtToken;

    constructor(address _usdtTokenAddress) {
        usdtToken = IERC20(_usdtTokenAddress);
    }

    function approve(address spender, uint256 amount) public {
        require(usdtToken.approve(spender, amount), "Approve failed");
    }
}