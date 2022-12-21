// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract HelloWorld {
  address public owner;
  uint256 public value;

  modifier onlyOwner() {
    require(owner == msg.sender, "Not Owner");
    _;
  }

  constructor(address _owner) {
    owner = _owner;
  }

  function testMe() external pure returns (uint256) {
    return 99e18;
  }

  function ownerChangeValue(uint256 _newValue) external onlyOwner {
    value = _newValue;
  }

  function DDDSDS(uint256 _newValue) external onlyOwner {
    value = _newValue;
  }
}