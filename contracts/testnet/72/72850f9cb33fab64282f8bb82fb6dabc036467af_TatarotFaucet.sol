/**
 *Submitted for verification at Arbiscan on 2023-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TatarotFaucet {
    mapping(address => bool) public hasClaimed;
    uint256 public claimAmount = 0.15 ether;

    // Event to log successful claims
    event Claimed(address indexed claimant, uint256 amount);

    // Event to log successful top-ups
    event ToppedUp(address indexed sender, uint256 amount);

    // Modifier to check if the sender has claimed before
    modifier notClaimed() {
        require(!hasClaimed[msg.sender], "You have already claimed your share.");
        _;
    }

    // Function to claim 0.15 Ether
    function claim() public notClaimed {
        require(address(this).balance >= claimAmount, "Not enough Ether in the contract.");

        hasClaimed[msg.sender] = true;
        (bool success, ) = payable(msg.sender).call{value: claimAmount}("");
        require(success, "Claim failed.");

        emit Claimed(msg.sender, claimAmount);
    }

    // Function to top up the contract with Ether
    function topUp() public payable {
        require(msg.value > 0, "You must send some Ether to top up.");

        emit ToppedUp(msg.sender, msg.value);
    }

    // Function to get contract balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}