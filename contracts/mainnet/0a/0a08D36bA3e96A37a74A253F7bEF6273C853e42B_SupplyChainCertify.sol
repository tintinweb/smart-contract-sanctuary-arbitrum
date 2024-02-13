/**
 *Submitted for verification at Arbiscan.io on 2024-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SupplyChainCertify {

  address private owner;
  string private groupHash;

  /**
   * @notice Event for logging ownership transfer.
   * @param oldOwner Address of old ownership. Indexed.
   * @param newOwner Address of new ownership. Indexed.
   */
  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
 
  /**
   * @notice Constructor that sets the initial owner of the contract to the address that deploys it, then emit the relative event.
   */
  constructor () {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  /**
   * @notice Returns the address of the current owner.
   */
  function getOwner() public view returns (address) {
    return owner;
  }

  /**
   * @notice Sets a new group hash for the contract.
   * @param _groupHash The new group hash to be set.
   */
  function setGroupHash(string memory _groupHash) public onlyOwner {
    groupHash = _groupHash;
  }

  /**
   * @notice Returns the current group hash of the contract. Can only be called by the current owner.
   */
  function getGroupHash() public view onlyOwner returns (string memory) {
    return groupHash;
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`_newOwner`). Can only be called by the current owner.
   * @param _newOwner The address of the new owner.
   */
  function transferOwnership(address _newOwner) public onlyOwner notZeroAddress(_newOwner) {
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  } 

  /**
   * @notice Modifier that restricts the execution of functions to only the owner of the contract.
   */
  modifier onlyOwner() {
    require (msg.sender == owner, "Error: only owner can execute this function");
    _;
  }

  /**
   * @notice Modifier that checks if an address is not the zero address.
   * @param _newOwner The address to be checked.
   */
  modifier notZeroAddress(address _newOwner) {
    require(_newOwner != address(0), "New owner cannot be the zero address.");
    _;
  }

}