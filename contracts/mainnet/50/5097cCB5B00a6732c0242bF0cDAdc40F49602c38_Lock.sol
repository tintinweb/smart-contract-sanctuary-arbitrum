// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract Lock {
    //address payable public owner;
    mapping (address => uint256) public lockedBalance;
    mapping (address => uint256) public unlockTime;

    event Withdrawal(uint amount, uint when);
    event Locking(uint amount, uint unlockTime);
    
    //function setOwner(address newOwner) public {
    //    owner = payable(newOwner);
    //}

    function lock(uint256 time) public payable {
        //console.log("Adress balance is: %s", msg.value);

        require(block.timestamp < time, "Unlock time should be in the future");

        unlockTime[msg.sender] = time;
        lockedBalance[msg.sender] = msg.value;

        emit Locking(msg.value, time);
    }

    function withdraw(uint256 amount) public { 
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);
        require(block.timestamp >= unlockTime[msg.sender], "You can't withdraw yet");
        require(lockedBalance[msg.sender] >= amount, "You cant withdraw more than what you have locked.");

        payable(msg.sender).transfer(address(this).balance);

        //emit Withdrawal(amount, block.timestamp);

    }
}