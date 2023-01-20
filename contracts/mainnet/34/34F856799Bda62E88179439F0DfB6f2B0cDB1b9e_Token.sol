/**
 *Submitted for verification at Arbiscan on 2023-01-19
*/

// SPDX-License-Identifier: MIT
// File: Arbitrum token.sol


pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000 * 10 ** decimals;
    string public name = "CryptoFriends";
    string public symbol = "Crf";
    uint public decimals = 18;
    }