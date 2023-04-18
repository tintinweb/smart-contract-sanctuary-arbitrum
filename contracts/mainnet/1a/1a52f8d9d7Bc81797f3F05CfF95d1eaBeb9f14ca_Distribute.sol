/**
 *Submitted for verification at Arbiscan on 2023-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract ERC20 {
  function transfer(address _recipient, uint256 _value) public virtual returns (bool success);
}

contract Distribute {
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
    }
    
  function drop(ERC20 token, address[] memory recipients, uint256[] memory values) public {
    require(msg.sender == _owner, "Ownable: caller is not the owner");
    uint arrayLength = recipients.length;
    for (uint i=0; i<arrayLength; i++) 
    {
        token.transfer(recipients[i], values[i]);
    }
  }
}