/**
 *Submitted for verification at Arbiscan.io on 2023-10-27
*/

pragma solidity =0.8.17;

contract Counter {
    uint256 public count;
    
    function add(uint x) public {
        count += x;
    }
}