// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../Treasure/IMasterOfInflation.sol";

contract TestMasterOfInflation is IMasterOfInflation {
  mapping(uint64 => uint256) chances;

  function setChance(uint64 _poolId, uint256 _chance) external {
    chances[_poolId] = _chance;
  }

  function chanceOfItemFromPool(
    uint64 _poolId,
    uint64 _amount,
    uint32 _bonus,
    uint32 _negativeBonus
  ) external view returns (uint256) {
    return chances[_poolId];
  }

  function tryMintFromPool(
    MintFromPoolParams calldata _params
  ) external returns (bool _didMintItem) {
    uint256 rand = _params.randomNumber % 100000;
    return rand < chances[_params.poolId];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMasterOfInflation {
  function chanceOfItemFromPool(
    uint64 _poolId,
    uint64 _amount,
    uint32 _bonus,
    uint32 _negativeBonus
  ) external view returns (uint256);

  function tryMintFromPool(
    MintFromPoolParams calldata _params
  ) external returns (bool _didMintItem);
}

struct MintFromPoolParams {
  // Slot 1 (160/256)
  uint64 poolId;
  uint64 amount;
  // Extra odds (out of 100,000) of pulling the item. Will be multiplied against the base odds
  // (1 + bonus) * dynamicBaseOdds
  uint32 bonus;
  // Slot 2
  uint256 itemId;
  // Slot 3
  uint256 randomNumber;
  // Slot 4 (192/256)
  address user;
  uint32 negativeBonus;
}