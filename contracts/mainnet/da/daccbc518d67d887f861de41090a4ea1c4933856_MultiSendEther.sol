/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

pragma solidity ^0.8.0;

contract MultiSendEther {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function sendEther(address payable[] memory recipients, uint256[] memory amounts) public payable onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(msg.value >= totalAmount, "Insufficient Ether provided");

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            owner.transfer(remainingBalance);
        }
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}