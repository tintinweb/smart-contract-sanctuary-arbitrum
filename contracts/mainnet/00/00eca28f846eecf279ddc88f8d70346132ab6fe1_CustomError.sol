/**
 *Submitted for verification at Arbiscan.io on 2024-06-18
*/

pragma solidity >=0.8.19;

contract CustomError {
    error HelloBrother(uint256 streamId, address caller);

    function trap() external {
        revert HelloBrother(1, msg.sender);
    }
}