/**
 *Submitted for verification at Arbiscan.io on 2024-04-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ITraderJoeLPPair {

  function getActiveId() external view returns (uint24 activeId);
  function getBinStep() external pure returns (uint16);
  function totalSupply(uint256 id) external view returns (uint256);
  function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);
  function balanceOf(address account, uint256 id) external view returns (uint256);

}

contract TraderJoeQuery {

  function queryLP(ITraderJoeLPPair pair, address addr, uint256 n)
      public view returns (uint256 xSum, uint256 ySum) {

    // uint256 binStep = pair.getBinStep();
    uint256 activeId = pair.getActiveId();

    for (uint256 id = activeId - n; id <= activeId + n; id++) {
      uint256 totalSupply = pair.totalSupply(id);
      if (totalSupply == 0) {
        continue;
      }

      uint256 balance = pair.balanceOf(addr, id);
      if (balance == 0) {
        continue;
      }

      (uint128 xReserve, uint128 yReserve) = pair.getBin(uint24(id));
      xSum += uint256(xReserve) * balance / totalSupply;
      ySum += uint256(yReserve) * balance / totalSupply;
    }
  }

}