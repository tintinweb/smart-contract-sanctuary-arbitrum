/**
 *Submitted for verification at Arbiscan.io on 2024-04-21
*/

// SPDX-License-Identifier: MIT
/**                  __                 v1.1+
                    / _|                     
   __ _  __ _ _   _| |_                      
  / _` |/ _` | | | |  _|__              _    
 | (_| | (_| | |_| | |  _ \            | |   
  \__, |\__, |\__,_|_| |_) | __ _ _ __ | | __
   __/ | __/ |   / _ \  _ < / _` | '_ \| |/ /
  |___/ |___/   |  __/ |_) | (_| | | | |   < 
                 \___|____/ \__,_|_| |_|_|\_\
*/
pragma solidity ^0.8.25;

contract eBank {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(address to, uint amount) public {
        (bool success, ) = to.call{value: amount}("");
        require(success);
        balances[msg.sender] -= amount;
    }
}