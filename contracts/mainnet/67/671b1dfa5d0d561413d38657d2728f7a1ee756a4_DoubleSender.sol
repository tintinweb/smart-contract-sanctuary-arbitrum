/**
 *Submitted for verification at Arbiscan on 2022-12-08
*/

pragma solidity ^0.5.0;

contract DoubleSender {
    // Mapping to track the amount of ether deposited by each address
    mapping(address => uint256) public deposits;

    // Function to deposit ether to the contract
    function deposit(uint256 amount) public payable {
        require(amount > 0, "Must deposit a positive amount of ether");
        require(msg.value >= amount, "Insufficient amount of ether sent to the contract");

        // Record the amount of ether deposited by the caller
        deposits[msg.sender] += amount;
    }

    function doubleSend(uint256 amount) public payable {
        require(amount > 0, "Must send a positive amount of ether to double");
        require(msg.value >= amount, "Insufficient amount of ether sent to the contract");

        // Send back twice the amount of ether that was sent to the contract
        msg.sender.transfer(2 * amount);

        // Update the caller's deposit balance
        deposits[msg.sender] -= amount;
    }
}