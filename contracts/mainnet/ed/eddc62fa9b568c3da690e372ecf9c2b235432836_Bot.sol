/**
 *Submitted for verification at Arbiscan on 2023-07-12
*/

pragma solidity ^0.4.25;

contract Bot {

// Mapping to track token balances for all addresses   
mapping (address => uint) public tokensOwned;

// Mapping to track Ether balances for bot
mapping (address => uint) public etherBalances;

// Address of the bot owner
address public botOwner;

constructor() public {  
  // Set bot owner to contract deployer
  botOwner = msg.sender;  
}

// Function for bot owner to withdraw funds
function withdraw() public {  
    require(msg.sender == botOwner); 
    // Transfer contract balance to bot owner
    msg.sender.transfer(address(this).balance);
}  

// Emitted when tokens are bought  
event BoughtTokens(address buyer, uint amount);

// Emitted when tokens are sold   
event SoldTokens(address seller, uint amount);

// Function for users to buy tokens        
function buyTokens(uint amount) public payable {
   // Increase buyer's token balance  
   tokensOwned[msg.sender] += amount;
  
   // If buyer is not the bot, trigger bot to buy tokens
   if (msg.sender != botOwner) {        
       buyTokensForBot(amount);
   }
   
   // Increase bot's Ether balance 
   etherBalances[botOwner] += msg.value;  
   
   // Emit event     
   emit BoughtTokens(msg.sender, amount);
}

// Function for bot to buy tokens (internal)
function buyTokensForBot(uint amount) internal {
   // Increase bot's token balance        
   tokensOwned[botOwner] += amount;
   
   // Emit event   
   emit BoughtTokens(botOwner, amount);
}
// Function for users to sell tokens
function sellTokens(uint amount) public {  
   require(tokensOwned[msg.sender] >= amount);
   
   // Decrease seller's token balance    
   tokensOwned[msg.sender] -= amount;
   
   // If seller is the bot, wait for user to sell first
   if (msg.sender == botOwner) {
       sellTokensForBot(amount);
   }   
   
   // Decrease bot's Ether balance   
   etherBalances[botOwner] -= msg.value;  
   
   // Emit event
   emit SoldTokens(msg.sender, amount);
}

// Function for bot to sell tokens (internal)  
function sellTokensForBot(uint amount) internal {
   // Decrease bot's token balance    
   tokensOwned[botOwner] -= amount;  
      
   // Emit event   
   emit SoldTokens(botOwner, amount);
}

}