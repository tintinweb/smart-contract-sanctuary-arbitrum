/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <=0.9.0;

interface Curve{
function exchange(uint fromToken, uint toToken, uint _amountIN, uint min_amountOUT, bool use_eth) external payable returns(uint);
}

contract Project3 {

function Swap(uint _WEthAmount) external returns(uint) {
uint Liquidated = Curve(0x960ea3e3C7FB317332d990873d354E18d7645590).exchange{value:0}(2, 0, _WEthAmount, 0, false);
return Liquidated;
}

}