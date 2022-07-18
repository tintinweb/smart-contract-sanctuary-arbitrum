/**
 *Submitted for verification at Arbiscan on 2022-07-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface BIFIBalanceToken {
  function balanceOf(address account) external view returns (uint256);
}

interface BIFIMaxi {
  function want() external view returns (BIFIBalanceToken);
  function balanceOf(address account) external view returns (uint256);
  function getPricePerFullShare() external view returns (uint256);
}

struct UserInfo {
    uint256 amount; // How many tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
}

interface RipaeGenesisPool {
    function userInfo(uint256, address) external view returns (UserInfo memory); 
    // mapping(uint256 => mapping(address => UserInfo)) public userInfo;
}

contract BIFIPae {

  BIFIBalanceToken public bifi;
  BIFIMaxi public maxi;
  RipaeGenesisPool public genesisPool;

  constructor(BIFIMaxi _bifiMaxiVault, RipaeGenesisPool _genesisPool) {
    bifi = _bifiMaxiVault.want();
    maxi = _bifiMaxiVault;
    genesisPool = _genesisPool;
  }

  function balanceOf(address account) external view returns (uint256) {
    uint ppfs = maxi.getPricePerFullShare();
    return genesisPool.userInfo(3, account).amount * ppfs/ 1e18;
  }

}