/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

pragma solidity ^0.8.0;

contract Disperse {
    function disperse(address payable target, uint256 value) public payable {
        require(target != address(0), "address required");
        require(msg.value == value, "value requred");

        target.transfer(value);
    }
}