/**
 *Submitted for verification at Arbiscan on 2023-05-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <=0.9.0;

//Uniswap Contract Interface
interface Curve{
function exchange(uint i, uint j, uint dx, uint min_dy, bool use_eth) external payable;
}

interface USDT{
    function approve(address _spender, uint _amount) external returns(bool);
    function transfer(address _to, uint256 _amount) external returns (bool);
}


contract Project {

function ExchangeETH(uint _i, uint _j, uint _dx, uint _min_dy) public payable{
Curve(0x960ea3e3C7FB317332d990873d354E18d7645590).exchange{value:msg.value}(_i, _j, _dx, _min_dy, false);
}

function ApproveContract(address _spender, uint _amount) public returns(bool){
    USDT(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9).approve(_spender, _amount);
    return true;
}

function TranferFromContract(address _recipent, uint _amount) public returns(bool){
    USDT(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9).transfer(_recipent, _amount);
    return true;
}

}