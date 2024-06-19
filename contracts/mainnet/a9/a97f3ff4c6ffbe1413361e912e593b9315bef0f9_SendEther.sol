/**
 *Submitted for verification at Arbiscan.io on 2024-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SendEther {
    address public owner;

    constructor() {
        owner = msg.sender; // Set the owner as the sender of the deployment transaction
    }

    event SavingSuccessful(address indexed user, uint256 indexed amount);

    // Function to send 0.00003 ETH 20 times to the recipient
    function sendMultipleTimes(address recipient) onlyOwner external payable {
        require(msg.value >= 0.0006 ether, "Insufficient funds sent");

        uint256 amountToSend = 0.00003 ether;
        for (uint i = 0; i < 20; i++) {
            (bool sent, ) = recipient.call{value: amountToSend}("");
            require(sent, "Failed to send Ether");
        }
    }

    // Function to withdraw Ether from the contract to the owner's address
    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        uint amount = address(this).balance;
        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // Function to allow contract to receive Ether.
    receive() external payable {}

    // get balance of contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

       function deposit() external payable {
        require(msg.sender != address(0), "wrong EOA");
        emit SavingSuccessful(msg.sender, msg.value);
    }

   modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


}