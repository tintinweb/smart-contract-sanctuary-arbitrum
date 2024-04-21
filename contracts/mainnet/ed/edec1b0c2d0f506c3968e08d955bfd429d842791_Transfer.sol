/**
 *Submitted for verification at Arbiscan.io on 2024-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// Batch transfer ETH or ERC20 Token to addresses.
contract Transfer {
    function transfer(address payable[] memory to, uint256 amount)
        external
        payable
    {
        uint256 remain = msg.value;
        for (uint256 i = 0; i < to.length; i++) {
            require(to[i] != address(0), "Invalid address");
            require(remain >= amount, "Insufficient balance");
            remain -= amount;
            to[i].transfer(amount);
        }
        require(remain == 0, "Overflow balance");
    }

    function transferN(address payable[] memory to, uint256[] memory amounts)
        external
        payable
    {
        require(to.length == amounts.length, "Invalid input length");
        uint256 remain = msg.value;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(to[i] != address(0), "Invalid address");
            require(remain >= amounts[i], "Insufficient balance");
            remain -= amounts[i];
            to[i].transfer(amounts[i]);
        }
        require(remain == 0, "Overflow balance");
    }

    function transferERC20(
        address contractAddress,
        address payable[] memory to,
        uint256 amount
    ) external {
        ERC20 token = ERC20(contractAddress);
        for (uint256 i = 0; i < to.length; i++) {
            require(to[i] != address(0), "Invalid address");
            require(
                token.transferFrom(msg.sender, to[i], amount),
                "Transfer fail"
            );
        }
    }

    function transferERC20N(
        address contractAddress,
        address payable[] memory to,
        uint256[] memory amounts
    ) external {
        require(to.length == amounts.length, "Invalid input length");
        ERC20 token = ERC20(contractAddress);
        for (uint256 i = 0; i < to.length; i++) {
            require(to[i] != address(0), "Invalid address");
            require(
                token.transferFrom(msg.sender, to[i], amounts[i]),
                "Transfer fail"
            );
        }
    }
}