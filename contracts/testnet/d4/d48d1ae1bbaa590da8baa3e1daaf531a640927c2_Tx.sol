/**
 *Submitted for verification at Arbiscan on 2022-09-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

contract Tx {
    uint256 public g = 999;
    function g1() external view returns(uint256){
        return tx.gasprice;
    }
    function g2() external returns(uint256){
        g = tx.gasprice;
        return g;
    }
}