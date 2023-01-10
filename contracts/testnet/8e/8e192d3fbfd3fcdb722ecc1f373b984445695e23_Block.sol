/**
 *Submitted for verification at Arbiscan on 2023-01-09
*/

pragma solidity =0.8.0;


contract Block  {
    
    function number() public returns(uint256, uint256)  {
        return (block.number, block.timestamp);
    }

}