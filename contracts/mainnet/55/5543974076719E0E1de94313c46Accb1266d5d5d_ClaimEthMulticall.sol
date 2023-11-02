// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IHandler {
  function claimETHRewards(address _account) external;
}

contract ClaimEthMulticall {
  address private vodkaV1 = 0xcEE11989222f80D21ef22177B71eaA52E9B6b576;
  address private vodkaV1a = 0xA77943a1b736989115d24ca1BDc19713C1eECf34;

  function claim(address _account) external {
    IHandler(vodkaV1).claimETHRewards(_account);
    IHandler(vodkaV1a).claimETHRewards(_account);
  }
}