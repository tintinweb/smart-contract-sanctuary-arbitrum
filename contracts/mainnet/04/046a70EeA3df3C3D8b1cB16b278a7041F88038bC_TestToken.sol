/**
 *Submitted for verification at Arbiscan on 2023-01-21
*/

pragma solidity ^0.8.0;

contract TestToken {
// Token name, symbol, and decimal places
 string public name = "Test";
 string public symbol = "TST";
 uint8 public decimals = 9;

// Total supply of tokens
 uint256 public totalSupply = 100;

// Tax on token buy and sell transactions
uint256 public buyTax = 2;
uint256 public sellTax = 2;

 // Mapping of wallet address to bool to check if address is blacklisted
 mapping(address => bool) public blacklisted;

// Address of the contract owner
address public owner;

// Events for token transfers and updates to buy and sell tax
 event Transfer(address indexed from, address indexed to, uint256 value);
 event TaxUpdate(uint256 buyTax, uint256 sellTax);

// Initialize total supply and set the contract owner
       constructor() public {
 owner = msg.sender;
 }

 // Function to blacklist a wallet address
 function blacklist(address _wallet) public {
 require(msg.sender == owner, "Only contract owner can blacklist addresses");
 blacklisted[_wallet] = true;
 }

 // Function to unblacklist a wallet address
 function unblacklist(address _wallet) public {
 require(msg.sender == owner, "Only contract owner can unblacklist addresses");
 blacklisted[_wallet] = false;
 }

// Function to renounce contract ownership
 function renounceOwnership() public {
 require(msg.sender == owner, "Only contract owner can renounce ownership");
  owner = address(0);
 }

 // Function to update buy and sell tax
 function updateTax(uint256 _buyTax, uint256 _sellTax) public {
 require(msg.sender == owner, "Only contract owner can update taxes");
     buyTax = _buyTax;
     sellTax = _sellTax;
        emit TaxUpdate(_buyTax, _sellTax);
    }

     // Function to transfer tokens from one wallet to another
       function transfer(address _to, uint256 _value) public {
        require(!blacklisted[msg.sender], "Sender address is blacklisted");
        require(!blacklisted[_to], "Receiver address is blacklisted");
        require(_value <= totalSupply, "Insufficient token balance");
        totalSupply -= _value;
        emit Transfer(msg.sender, _to, _value);
    }
}