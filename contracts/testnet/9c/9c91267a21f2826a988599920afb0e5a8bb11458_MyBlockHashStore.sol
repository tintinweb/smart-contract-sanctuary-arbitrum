pragma solidity 0.6.6;

interface BlockHashStoreInterface {
  function getBlockhash(uint256 number) external view returns (bytes32);
}

contract MyBlockHashStore is BlockHashStoreInterface {
  mapping(uint256 => bytes32) private blockhashes;

  function getBlockhash(uint256 number) external view override returns (bytes32) {
    return blockhashes[number];
  }

  function setBlockhash(uint256 number, bytes32 hash) external {
    blockhashes[number] = hash;
  }
}