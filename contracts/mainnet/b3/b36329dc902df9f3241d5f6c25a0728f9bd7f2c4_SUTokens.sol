/**
 *Submitted for verification at Arbiscan on 2022-09-05
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

contract SUTokens {

    string public constant name = "SuperTest";
    string public constant symbol = "SUT";
    string public snames;
    uint8 public constant decimals = 18;  
    uint256 public constant totalSupply_ = 100000000000;

 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;
   

    mapping(address => mapping (address => uint256)) allowed;
    
   constructor(string memory names) public {  
    balances[msg.sender] = 100000000000;
    snames = names;
    }  

 
    function balanceOf(address tokenOwner) external view returns (uint) {
        return balances[tokenOwner];
    }
     function tokenRemaning(address token) external view returns (uint) {
        return balances[token];
}
    function transfer(address receiver, uint numTokens) public returns (bool) {
       uint OwnerBalance=balances[msg.sender];
        require(numTokens <= OwnerBalance ,"Don't have enough SUT Tokens...");
        
        balances[msg.sender] = OwnerBalance-numTokens;
        balances[receiver]+=numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) external returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        
        return true;
    }

    function allowance(address owner, address delegate) external view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
       uint OwnerBalance=balances[owner];
       uint AlowedOwner=allowed[owner][msg.sender];

        require(numTokens <= OwnerBalance,"Don't have enough SUT Tokens...");    
        require(numTokens <= AlowedOwner);
    
        balances[owner] = OwnerBalance-numTokens;
        allowed[owner][msg.sender] =AlowedOwner-numTokens;
        balances[buyer] +=numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}