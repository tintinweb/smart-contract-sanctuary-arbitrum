// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

contract GovernanceTargetAlphaStub {
  function a() external pure returns (string memory) {
    return "a";
  }

  function b() external pure returns (string memory) {
    return "b";
  }

  function add(uint256 _left, uint256 _right) external pure returns (uint256) {
    return _left + _right;
  }

  function willRevert() external pure returns (bool success) {
    require(1 == 2, "1 is not equal to 2");
    return true;
  }

  receive() external payable {
    require(1 == 2, "1 is not equal to 2");
  }
}

contract GovernanceTargetNumberStub {
  function a() external pure returns (uint256) {
    return 1;
  }

  function b() external pure returns (uint256) {
    return 2;
  }

  function add(uint256 _left, uint256 _right) external pure returns (uint256) {
    return _left + _right;
  }

  function willRevert() external pure returns (bool success) {
    require(1 == 2, "1 is not equal to 2");
    return true;
  }

  receive() external payable {
    require(1 == 2, "1 is not equal to 2");
  }
}

contract GovernanceTargetConstructorArgumentStub {
  string public greeting;

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function willRevert() external pure returns (bool success) {
    require(1 == 2, "1 is not equal to 2");
    return true;
  }

  receive() external payable {
    require(1 == 2, "1 is not equal to 2");
  }
}

contract GovernanceStateChangeTargetStub {
  string public greeting;

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function changeGreeting(string calldata _newGreeting) external {
    greeting = _newGreeting;
  }

  function willRevert() external pure returns (bool success) {
    require(1 == 2, "1 is not equal to 2");
    return true;
  }

  receive() external payable {
    require(1 == 2, "1 is not equal to 2");
  }
}