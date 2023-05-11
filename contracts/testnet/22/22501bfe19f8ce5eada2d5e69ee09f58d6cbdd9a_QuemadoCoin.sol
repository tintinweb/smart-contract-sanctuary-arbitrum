/**
 *Submitted for verification at Arbiscan on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuemadoCoin {
  // The total supply of QuemadoCoins
  uint256 public totalSupply;

  // Mapping from addresses to the number of QuemadoCoins they own
  mapping(address => uint256) public balances;

  // Event to be fired when a transfer of QuemadoCoins is made
  event Transfer(address indexed from, address indexed to, uint256 amount);

  // Event to be fired when new QuemadoCoins are minted
  event Mint(address indexed to, uint256 amount);

  // Event to be fired when QuemadoCoins are burned
  event Burn(address indexed from, uint256 amount);

  // Event to be fired when the contract is abandoned
  event Abandoned(address indexed owner);

  // The name and symbol of the token
  string public constant name = "QuemadoCoin";
  string public constant symbol = "QCO";

  // Constructor
  constructor() {
    // The initial supply of QuemadoCoins is 420,690,000,000,000
    totalSupply = 420690000000000;

    // The creator of the contract gets all of the initial supply
    balances[msg.sender] = totalSupply;

    // Set the owner of the contract to the creator
    owner = msg.sender;
  }

  // Function to transfer QuemadoCoins from one address to another
  function transfer(address to, uint256 amount) public {
    // Check if the sender has enough QuemadoCoins to transfer
    require(balances[msg.sender] >= amount);

    // Update the balances of the sender and the recipient
    balances[msg.sender] -= amount;
    balances[to] += amount;

    // Fire the Transfer event
    emit Transfer(msg.sender, to, amount);
  }

  // Function to mint new QuemadoCoins
  function mint(address to, uint256 amount) public onlyOwner {
    // Check if the amount to mint is valid
    require(amount > 0);

    // Update the total supply
    totalSupply += amount;

    // Update the balance of the recipient
    balances[to] += amount;

    // Fire the Mint event
    emit Mint(to, amount);
  }

  // Function to burn QuemadoCoins
  function burn(uint256 amount) public onlyOwner {
    // Check if the amount to burn is valid
    require(amount > 0);

    // Update the total supply
    totalSupply -= amount;

    // Update the balance of the sender
    balances[msg.sender] -= amount;

    // Fire the Burn event
    emit Burn(msg.sender, amount);
  }

  // Function to get the balance of an address
  function balanceOf(address account) public view returns (uint256) {
    // Return the balance of the specified account
    return balances[account];
  }

  // Function to abandon the contract
  function abandonContract() public onlyOwner {
    // Set the owner to the zero address
    owner = address(0);

    // Fire the Abandoned event
    emit Abandoned(msg.sender);
  }

  // The onlyOwner modifier is used to restrict access to certain functions to the contract owner
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // The owner of the contract is stored in the `owner` variable
  address public owner;
}