/**
 *Submitted for verification at Arbiscan on 2023-05-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Ai {
    address public owner;
    bool public can_transfer;    
    string public symbol = unicode"AIထ";
    string public  name = "Ai infinity";
    uint8 public decimals = 6;
    uint public totalSupply = 100000000000 * (10**6);
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => bool) public white_list;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    fallback () external payable {}
    receive () external payable {}
    function setTransferOFF_ON(bool value)public {
        require(msg.sender == owner);
       can_transfer = value;
    }
    function setOwner(address owner_)public {
        require(msg.sender == owner);
        owner = owner_;
    }
    function setWhiteList(address adds,bool value)public {
        require(msg.sender == owner);
        white_list[adds] = value;
    }
    function safeAdd(uint a, uint b) internal  pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

    function transfer_(address from,address to,uint tokens)internal returns(bool){
        require(can_transfer == true || white_list[from] == true || white_list[to] == true);
        balanceOf[from] = safeSub(balanceOf[from], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        transfer_(msg.sender,to,tokens);        
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], tokens);
        transfer_(from,to,tokens);        
        return true;
    }
    function take_out_of_eth(address payable adds,uint value)public{
        require(msg.sender == owner);
        adds.transfer(value);
    }
    function take_out_of_token(address payable  tok,address to,uint value)public{
        require(msg.sender == owner);
        Ai ai = Ai(tok);
        ai.transfer(to, value);
    }
}