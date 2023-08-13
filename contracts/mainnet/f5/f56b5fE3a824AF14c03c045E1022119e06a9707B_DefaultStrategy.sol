// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

/**
 * @notice
 *  This is a GMX perpetual trading strategy contract
 *  inputs: address[3], [hypervisorAddress, indexToken, hedgeTokenAddress]
 *  config: abi.encodePacked(bytes32(referralCode))
 */
contract DefaultStrategy {
  string public name = "default-strategy";
  address public strategist;

  modifier onlyStrategist() {
    require(msg.sender == strategist, "!strategist");
    _;
  }

  constructor() {
    strategist = msg.sender;
  }

  function run(bytes calldata performData) external { }
}