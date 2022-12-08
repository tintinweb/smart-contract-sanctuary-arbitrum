/**
 *Submitted for verification at Arbiscan on 2022-12-08
*/

pragma solidity ^0.5.0;

contract DoubleSender {
    function doubleSend(uint256 amount) public payable {
        require(amount > 0, "Must send a positive amount of ether to double");
        require(msg.value >= amount, "Insufficient amount of ether sent to the contract");

        // Send back twice the amount of ether that was sent to the contract
        msg.sender.transfer(2 * amount);
    }
}