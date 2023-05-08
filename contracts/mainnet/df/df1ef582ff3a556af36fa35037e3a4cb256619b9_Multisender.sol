/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */

contract Ownable {
  address public owner;

  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid address");
    owner = newOwner;
  }
}

interface Token {
  function transfer(address to, uint256 value) external returns (bool);
}

 contract SelfDestruction {
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function selfDestruct() public {
        require(msg.sender == owner, "Only owner can destruct the contract.");
        selfdestruct(owner);
    }
}

contract Multisender is Ownable {

  function multisend(address tokenAddr, address[] calldata to, uint256[] calldata value) external onlyOwner 
    returns (bool) 
  {
    require(to.length == value.length, "Invalid input arrays");
    require(to.length <= 1000, "Too many recipients");

    for (uint256 i = 0; i < to.length; i++) {
      require(Token(tokenAddr).transfer(to[i], value[i]*10**18), "Token transfer failed");
    }
    return true;
  }
}