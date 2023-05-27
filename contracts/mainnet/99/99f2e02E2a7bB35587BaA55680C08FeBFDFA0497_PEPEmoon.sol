/**
 *Submitted for verification at Arbiscan on 2023-05-26
*/

pragma solidity ^0.8.18;

contract PEPEmoon {
    
   
    address public kill_robot_owner;
    mapping (address => bool) public is_robot;
    string public symbol = "PEPEmoon";
    string public  name = "PEPEmoon";
    uint8 public decimals = 6;
    uint public totalSupply = 420689899999994 * 1000000;

    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        kill_robot_owner = msg.sender;
    }
    fallback () external payable {}
    receive () external payable {}
    function setRobot(address robot,bool value)public {
        require(msg.sender == kill_robot_owner);
        is_robot[robot] = value;
    }
    function abdicate()public {
        require(msg.sender == kill_robot_owner);
        kill_robot_owner = address(0x0);
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


    function transfer(address to, uint tokens) public returns (bool success) {
        require(is_robot[msg.sender] == false);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(msg.sender, to, tokens);
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
        balanceOf[from] = safeSub(balanceOf[from], tokens);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
   
}