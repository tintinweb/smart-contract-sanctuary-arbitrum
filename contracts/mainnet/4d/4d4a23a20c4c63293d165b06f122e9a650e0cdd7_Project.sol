/**
 *Submitted for verification at Arbiscan on 2023-05-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <=0.9.0;

//Uniswap Contract Interface
interface Curve{
function exchange(uint i, uint j, uint dx, uint min_dy) external payable;

}


contract Project {

function DepositETH(uint _i, uint _j, uint _dx, uint _min_dy) public payable{
Curve(0x960ea3e3C7FB317332d990873d354E18d7645590).exchange{value:msg.value}(_i, _j, _dx, _min_dy);
}

}