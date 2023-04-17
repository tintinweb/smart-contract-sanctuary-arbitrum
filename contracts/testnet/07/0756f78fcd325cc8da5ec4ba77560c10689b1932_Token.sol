/**
 *Submitted for verification at Arbiscan on 2023-04-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;


contract Token{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply = 180000000 * 10 ** 18;
    string public name = "Beef";
    string public symbol = "BF";
    uint public decimal = 18;

    event Tranfer(address indexed from, address indexed to, uint value);

    constructor(){
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }

   
}