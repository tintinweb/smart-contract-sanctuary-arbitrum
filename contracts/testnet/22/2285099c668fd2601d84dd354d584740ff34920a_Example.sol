/**
 *Submitted for verification at Arbiscan.io on 2023-09-27
*/

pragma solidity 0.8.18;

contract Example {
    uint256 gp;

    function method() external {
        gp = tx.gasprice;
    }

    function getGp() external view returns (uint256) {
        return gp;
    }
}