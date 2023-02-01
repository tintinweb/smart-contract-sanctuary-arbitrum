pragma solidity ^0.4.18;
import './StandardToken.sol';

contract LuckyToadv3 is StandardToken {
  string public name = "LuckyToadv3"; 
  string public symbol = "TOAD";
  uint public decimals = 9;
  uint public INITIAL_SUPPLY = 1000000000 * (10 ** decimals);
  uint256 public totalSupply;
  
  constructor() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}