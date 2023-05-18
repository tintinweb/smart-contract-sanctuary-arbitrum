/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

pragma solidity ^0.8.0;

contract BaseFee {
    function getCurrentBaseFee() public view returns (uint256) {
        return block.basefee;
    }
}