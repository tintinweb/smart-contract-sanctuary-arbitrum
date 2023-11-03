// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract RealmUpkeep {
  event Invoked(address caller, uint timestamp, bytes32[] data);

  function upkeep(bytes32[] calldata data) external {
    emit Invoked(msg.sender, block.timestamp, data);
  }
}