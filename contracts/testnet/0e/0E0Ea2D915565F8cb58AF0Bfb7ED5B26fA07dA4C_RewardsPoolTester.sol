// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

//=======================================
// Enums
//=======================================

enum RewardTokenType {
  ERC20,
  ERC721,
  ERC1155
}

//=======================================
// Structs
//=======================================
struct DispensedRewards {
  uint256 nextRandomBase;
  DispensedReward[] rewards;
}

struct DispensedReward {
  RewardTokenType tokenType;
  address token;
  uint256 tokenId;
  uint256 amount;
}

//=========================================================================================================================================
// Rewards will use 10^3 decimal point to calculate drop rates. This means if something has a drop rate of 100% it's represented as 100000
//=========================================================================================================================================
uint256 constant DECIMAL_POINT = 1000;
uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;

//=======================================================================================================================================================
// Dispenser contract for rewards. Each RewardPool is divided into subpools (in case of lootboxes: for different rarities, or realm specific pools, etc).
//=======================================================================================================================================================
interface IRewardsPool {
  //==============================================================================================================================
  // Dispenses random rewards from the pool
  //==============================================================================================================================
  function dispenseRewards(
    uint64 subPoolId,
    uint256 randomNumberBase,
    address receiver
  ) external returns (DispensedRewards memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../Lootbox/Rewards/IRewardsPool.sol";
import "../../Utils/random.sol";
import "../../Manager/ManagerModifier.sol";

contract RewardsPoolTester is ManagerModifier {
  event RewardsPoolResult(DispensedRewards rewards);

  IRewardsPool rewardsPool;
  mapping(address => uint256) lootBoxesRevealed;

  constructor(
    address _manager
  ) ManagerModifier(_manager) {
  }

  function dispenseRewards(
    uint64 subPoolId,
    uint256 randomNumberBase,
    address receiver
  ) external onlyAdmin {
    lootBoxesRevealed[msg.sender] += 1;
    Random.startRandomBase(subPoolId, randomNumberBase);
    DispensedRewards memory rewards = rewardsPool.dispenseRewards(
      subPoolId,
      randomNumberBase,
      receiver
    );
    emit RewardsPoolResult(rewards);
  }

  function setRewardsPool(address _rewardsPool) external onlyAdmin {
    rewardsPool = IRewardsPool(_rewardsPool);
  }
}

pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

//=========================================================================================================================================
// We're trying to normalize all chances close to 100%, which is 100 000 with decimal point 10^3. Assuming this, we can get more "random"
// numbers by dividing the "random" number by this prime. To be honest most primes larger than 100% should work, but to be safe we'll
// use an order of magnitude higher (10^3) relative to the decimal point
// We're using uint256 (2^256 ~= 10^77), which means we're safe to derive 8 consecutive random numbers from each hash.
// If we, by any chance, run out of random numbers (hash being lower than the range) we can in turn
// use the remainder of the hash to regenerate a new random number.
// Example: assuming our hash function result would be 1132134687911000 (shorter number picked for explanation) and we're using
// % 100000 range for our drop chance. The first "random" number is 11000. We then divide 1000000011000 by the 100000037 prime,
// leaving us at 11321342. The second derived random number would be 11321342 % 100000 = 21342. 11321342/100000037 is in turn less than
// 100000037, so we'll instead regenerate a new hash using 11321342.
// Primes are used for additional safety, but we could just deal with the "range".
//=========================================================================================================================================
uint256 constant MIN_SAFE_NEXT_NUMBER_PRIME = 1000033;
uint256 constant HIGH_RANGE_PRIME_OFFSET = 13;

library Random {
  function startRandomBase(
    uint256 _highSalt,
    uint256 _lowSalt
  ) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            blockhash(block.number - 1),
            msg.sender,
            _lowSalt,
            _highSalt
          )
        )
      );
  }

  function getNextRandom(
    uint256 randomBase,
    uint256 range
  ) internal view returns (uint256 random, uint256 nextBase) {
    uint256 nextNumberSeparator = MIN_SAFE_NEXT_NUMBER_PRIME > range
      ? MIN_SAFE_NEXT_NUMBER_PRIME
      : (range + HIGH_RANGE_PRIME_OFFSET);
    uint256 nextBaseNumber = randomBase / nextNumberSeparator;
    if (nextBaseNumber > nextNumberSeparator) {
      return (randomBase % range, nextBaseNumber);
    }
    nextBaseNumber = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          msg.sender,
          randomBase,
          range
        )
      )
    );
    return (nextBaseNumber % range, nextBaseNumber / nextNumberSeparator);
  }
}