/**
 *Submitted for verification at Arbiscan on 2023-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
}

contract MultiTokenTransfer {
    address[] public tokenAddresses;
    address public owner;
    address public pendingOwner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyCreator() {
        require(msg.sender == owner, "Only the contract creator can perform this action");
        _;
    }

    function transferOwnership(address newContractCreator) external onlyCreator {
        require(newContractCreator != address(0), "Invalid contract creator address");
        owner = newContractCreator;
    }

    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "Only the new contract creator can accept the ownership");
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function addTokenAddress(address tokenAddress) external onlyCreator {
        require(tokenAddress != address(0), "Invalid token address");
        require(!isTokenAddressAdded(tokenAddress), "Token already added");

        tokenAddresses.push(tokenAddress);
    }

    function isTokenAddressAdded(address tokenAddress) internal view returns (bool) {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == tokenAddress) {
                return true;
            }
        }
        return false;
    }

    function disperseTokensEqually(address[] calldata targetAddresses) external {
        require(targetAddresses.length > 0, "Empty target address list");

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(msg.sender);

            if (balance > 0) {
                uint256 amountToSend = balance / targetAddresses.length;
                for (uint256 j = 0; j < targetAddresses.length; j++) {
                    address recipientAddress = targetAddresses[j];
                    require(recipientAddress != address(0), "Invalid recipient address");

                    require(token.transfer(recipientAddress, amountToSend), string(abi.encodePacked(token.name(), ": Transfer failed")));
                }
            }
        }
    }

    function transferTokens(address recipient, uint256 amount) external {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(msg.sender);

            if (balance > 0) {
                require(token.transfer(recipient, amount), string(abi.encodePacked(token.name(), ": Transfer failed")));
            }
        }
    }
}