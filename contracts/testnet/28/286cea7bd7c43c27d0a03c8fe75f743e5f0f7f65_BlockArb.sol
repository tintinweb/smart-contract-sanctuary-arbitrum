/**
 *Submitted for verification at Arbiscan on 2023-01-13
*/

pragma solidity =0.8.0;

interface IArbSys {
    function arbBlockNumber() external view returns (uint);
}


contract BlockArb  {
    
    function number() public view returns(uint256 block1, uint256 block2, uint256 timestamp)  {
        block1 = block.number;
        block2 = IArbSys(0x0000000000000000000000000000000000000064).arbBlockNumber();
        timestamp = block.timestamp;
    }

}