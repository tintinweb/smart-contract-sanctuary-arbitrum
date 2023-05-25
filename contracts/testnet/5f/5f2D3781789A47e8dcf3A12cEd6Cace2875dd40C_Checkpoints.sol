// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library Checkpoints {
  struct Checkpoint {
    bytes32 root;
    uint256 totalAmount;
  }

  struct History {
    Checkpoint[] _checkpoints;
  }

  function push(
    History storage self,
    bytes32 root,
    uint256 totalAmount
  ) internal returns (uint256) {
    uint256 pos = self._checkpoints.length;
    self._checkpoints.push(
      Checkpoint({ root: root, totalAmount: totalAmount })
    );
    return pos;
  }

  function getCheckpoint(
    History memory self,
    uint256 idx
  ) public pure returns (bytes32, uint256) {
    Checkpoint memory checkpoint = self._checkpoints[idx];
    return (checkpoint.root, checkpoint.totalAmount);
  }

  function updateCheckpoint(
    History storage self,
    uint256 idx,
    bytes32 newRoot,
    uint256 newTotalAmount,
    bool updateRoot,
    bool updateTotalAmount
  ) internal {
    require(idx < len(self), 'Not right index');
    Checkpoint storage checkpoint = self._checkpoints[idx];
    if (updateRoot) checkpoint.root = newRoot;
    if (updateTotalAmount) checkpoint.totalAmount = newTotalAmount;
  }

  function len(History memory self) public pure returns (uint256) {
    return self._checkpoints.length;
  }
}