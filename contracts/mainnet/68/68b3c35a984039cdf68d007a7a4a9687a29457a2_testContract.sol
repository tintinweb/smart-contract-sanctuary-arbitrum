/**
 *Submitted for verification at Arbiscan on 2022-11-23
*/

pragma solidity 0.7.6;
contract testContract 
{ 
     function timestamp() public view returns (uint256) {
          return block.timestamp;
     }
}