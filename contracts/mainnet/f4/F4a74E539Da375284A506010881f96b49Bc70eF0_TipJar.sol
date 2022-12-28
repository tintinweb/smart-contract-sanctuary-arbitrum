/**
 *Submitted for verification at Arbiscan on 2022-12-28
*/

pragma solidity ^0.8.16;

contract TipJar {
    address owner; // current owner of the contract

    constructor() {
        owner = msg.sender;
    }

    function withdraw() public {
        require(owner == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }

    function deposit(uint256 amount) public payable {
        require(msg.value == amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}