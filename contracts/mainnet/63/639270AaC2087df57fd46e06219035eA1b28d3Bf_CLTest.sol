// SPDX-License-Identifier: None
pragma solidity 0.8.4;

contract CLTest {
  uint256 public ts;
  uint256 public oldTs;
  address public caller;

  function upkeepCall() public {
    require(block.timestamp >= ts + 300, "Condition not met");
    oldTs = ts;
    ts = block.timestamp;
    caller = msg.sender;
  }

  function getTsDelta() public view returns (uint256) {
    return ts - oldTs;
  }
}