// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract RandaoTest {
  mapping(uint256 => uint256) public blockToRandomNumber;
  uint256[] public blockNumbers;
  event RecordRandom(uint256 blockNumber, uint256 prevRandao);

  constructor() {}

  function recordRandom() public returns (uint256) {
    blockToRandomNumber[block.number] = getCurrentRandom();
    blockNumbers.push(block.number);
    emit RecordRandom(block.number, blockToRandomNumber[block.number]);
    return blockToRandomNumber[block.number];
  }

  function getCurrentRandom() public view returns (uint256) {
    return uint256(blockhash(block.number - 1));
  }

  function getBlockNumbers() external view returns (uint256[] memory) {
    return blockNumbers;
  }

  function getRandomNumbers() external view returns (uint256[] memory) {
    uint256[] memory randomNumbers = new uint256[](blockNumbers.length);
    for (uint256 i = 0; i < randomNumbers.length; i++) {
      randomNumbers[i] = blockToRandomNumber[blockNumbers[i]];
    }
    return randomNumbers;
  }
}