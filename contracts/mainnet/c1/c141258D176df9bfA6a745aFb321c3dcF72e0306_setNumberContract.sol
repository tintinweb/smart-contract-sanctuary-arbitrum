/**
 *Submitted for verification at Arbiscan on 2022-08-02
*/

/**
 *Submitted for verification at Arbiscan on 2022-05-13
*/

pragma solidity ^0.8.0;

contract setNumberContract{
    address reserved;
    uint256 public number;
    
    function setNumber(uint256 _number) public {
        number = _number + 1;
    }
}