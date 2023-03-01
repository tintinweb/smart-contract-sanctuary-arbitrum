/**
 *Submitted for verification at Arbiscan on 2023-02-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract ERC20 {
  function transfer(address _recipient, uint256 _value) public virtual returns (bool success);
}

contract AirDrop {
    address private _owner;
    
    constructor() public {
        _owner = msg.sender;
    }
    
  function drop(ERC20 token, address[] calldata recipients, uint256 value) public {
    require(msg.sender == _owner, "Ownable: caller is not the owner");
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transfer(recipients[i], value);
    }
  }
}