/**
 *Submitted for verification at Arbiscan on 2023-03-31
*/

pragma solidity ^0.8.0;

contract One {
    uint256 public value;

    function setValue(uint256 newValue) public returns (bool) {
        require(gasleft() >= 30000, "Insufficient gas");
        value = newValue;
        return true;
    }
}