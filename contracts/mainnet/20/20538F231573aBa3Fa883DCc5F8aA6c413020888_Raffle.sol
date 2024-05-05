/**
 *Submitted for verification at Arbiscan.io on 2024-05-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;
//import "hardhat/console.sol";

// This contract keeps all Ether sent to it with no way
// to get it back.
contract Raffle {

  uint                            counter;
  mapping(uint=>address)          senders;
  mapping(uint=>uint)             value;
  mapping(uint=>uint)             index;
  uint                            total;
  uint                            randNonce;
  uint                            winIndex;
  address                         owner;
  address                         owner2;
  address                         winner;
  uint                            lastWindex;
  uint                            windex;
  uint                            payout=99;
  bool                            success;
  bool                            ownerSent;
  bool                            ownerSent2;
  string                          progress;
  uint                            lastIVal;
  address                         NFT;
  uint                            minPlayers;
  uint                            lastAmount;
  bool                            lessThan;

  constructor() {

    counter   = 0;
    total     = 0;
    randNonce = 0;
    winIndex  = 0;
    minPlayers= 1;
    lastAmount= 0;
    lessThan  = false;

    owner     = msg.sender;
    //owner2    = 

  }

  function getWindex(
   ) public view returns(
     uint    winning,    uint count, uint tot, uint winningIndex, bool suc, bool os, uint bal, 
     address winnerAddy, uint gas,   string memory pro,           uint last){
      
      winning       = lastWindex;
      count         = counter;
      tot           = total;
      winningIndex  = winIndex;
      suc           = success;
      os            = ownerSent;
      bal           = owner.balance;
      winnerAddy    = winner;
      gas           = gasleft();
      pro           = progress;
      last          = lastIVal;

   }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        
        if(msg.value>=1) {
          
          senders [counter]=msg.sender;
          value   [counter]=msg.value; 
          index   [counter]=total+msg.value;

          if (counter>0) {
            
            lastAmount=value[counter-1];

          }

          counter++;
          total=total+msg.value;
          
        }

        if(counter>1){
          
          //Ensure the current amount sent is LESS THAN the last amount sent

          lessThan=false;
          if(msg.value<lastAmount) {
            lessThan=true;
          }

          randNonce++;
          winIndex=(uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % total)+1;
          
          //cycle through the index to see if the value is equal to or greater than the winIndex to determine winner
          for (uint i = 0; i < counter; i++) {
            
            if(lessThan==false){break;}

            lastIVal=i;

            if(index[i]>=winIndex) {
              
              progress="Found the winner";

              //Ensure the total is LESS THAN the balance of this contract
              if(total > address(this).balance) {
                 total = address(this).balance;
              }

              //this is our winner, pay her
              winner = senders[i];
              (bool sent, ) = senders[i].call{value: uint(uint(total-value[i])*payout/100)+value[i]}("");
              success       = sent;
              progress      = "Sent winning funds";
              //require(sent, "Failed to send Ether");
              
              if(sent==false) {
                break;
              }

              //Primary owner - Contract creator
              //(bool sentOwn, )  = owner.call{value: address(this).balance/2}("");
              //ownerSent         = sentOwn;

              //Secondary Owner
              //(bool sentOwn2, ) = owner2.call{value: address(this).balance/2}("");
              //ownerSent2        = sentOwn2;

              //require(sentOwn, "Failed to send Ether");
              windex=i;

              for(uint clearIndex = 0; clearIndex<counter; clearIndex++){
                
                (bool send2part, ) = senders[clearIndex].call{value: address(this).balance/(clearIndex+2)}("");
                if(send2part==false){
                  break;
                }

                index[clearIndex]=0;

              }
              counter   = 0;
              lastWindex=winIndex;
              total     = 0;
              winIndex  = 0;
              minPlayers++;
              break;
            }

          }

        }

    }

}