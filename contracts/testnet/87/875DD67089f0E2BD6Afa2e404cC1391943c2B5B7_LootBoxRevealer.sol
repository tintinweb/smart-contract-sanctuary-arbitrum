// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IItemDataStorage {
  function obtainTokenId(
    uint16[] memory _characteristics
  ) external returns (uint256);

  function characteristics(
    uint256 _tokenId,
    uint16 _characteristicId
  ) external view returns (uint16);

  function characteristics(
    uint256 _tokenId
  ) external view returns (uint16[16] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

string constant ITEM_COLLECTION_NAME = "Realm Rarity items";
string constant ITEM_COLLECTION_DESCRIPTION = "Rarity items description";

//================================================
// Item-related constants, characteristics
//================================================

uint16 constant ITEM_CHARACTERISTIC_RARITY = 0;
uint16 constant ITEM_CHARACTERISTIC_SLOT = 1;
// "Weapon" slot could have "Heavy Weapon", "Magic Weapon", "Ranged Weapon"
uint16 constant ITEM_CHARACTERISTIC_CATEGORY = 2;
// Specific items in a given slot+category
// Heavy Weapon would be "Mallet" or "Great Axe", ranged weapon would be "Bow", "Crossbow", "Rifle"
uint16 constant ITEM_CHARACTERISTIC_TYPE = 3;
uint16 constant ITEM_CHARACTERISTIC_PREFIX = 4;
uint16 constant ITEM_CHARACTERISTIC_SUFFIX = 5;

uint16 constant ITEM_SLOT_HEAD = 1;
uint16 constant ITEM_SLOT_CHEST = 2;
uint16 constant ITEM_SLOT_HAND = 3;
uint16 constant ITEM_SLOT_JEWELRY = 4;

uint16 constant ITEM_TYPE_HEAD_HEADGEAR = 0;
uint16 constant ITEM_TYPE_CHEST_ARMOR = 0;
uint16 constant ITEM_TYPE_HAND_APPAREL = 0;
uint16 constant ITEM_TYPE_JEWELRY_JEWELRY = 0;

uint16 constant ITEM_RARITY_COMMON = 1;
uint16 constant ITEM_RARITY_RARE = 2;
uint16 constant ITEM_RARITY_EPIC = 3;
uint16 constant ITEM_RARITY_LEGENDARY = 4;
uint16 constant ITEM_RARITY_MYTHIC = 5;
uint16 constant ITEM_RARITY_EXOTIC = 6;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ILootBox {
  function mintFor(address _for, uint256 _id, uint256 _amount) external;

  function mintBatchFor(
    address _for,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function safeBurnBatch(
    address _for,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external;

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata data
  ) external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _ids,
    uint256 _amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Item/IItemDataStorage.sol";

interface ILootBoxDataStorage is IItemDataStorage {
  event LootBoxUpdated(uint256 _tokenId, uint16[16] characteristics);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ILootBoxDispenser {
  function dispense(
    address _address,
    uint256[] calldata _id,
    uint256[] calldata _lootBoxAmounts
  ) external;

  event LootBoxesDispensed(address _address, uint256 _tokenId, uint256 _amount);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./Rewards/IRewardsPool.sol";

interface ILootBoxRevealer {
  function reveal(
    uint256[] calldata _lootBoxTokenIds,
    uint256[] calldata _lootBoxAmount
  ) external;

  //=======================================
  // Events
  //=======================================
  event LootBoxRevealedEvent(
    uint256 revealIndex,
    address lootboxOwner,
    uint256 lootboxTokenId,
    uint256[] rewardTokenType,
    address[] rewardTokenAddress,
    uint256[] rewardTokenId,
    uint256[] rewardAmount
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Manager/ManagerModifier.sol";
import "../Item/RarityItemConstants.sol";
import "./ILootBox.sol";
import "./ILootBoxDataStorage.sol";
import "./ILootBoxDispenser.sol";
import "./ILootBoxRevealer.sol";
import "../Utils/random.sol";
import "./Rewards/IRewardsPool.sol";

contract LootBoxRevealer is
  ILootBoxRevealer,
  ReentrancyGuard,
  Pausable,
  ManagerModifier
{

  struct RewardsUnwrapper {
    uint256[] rewardTokenType;
    address[] rewardTokenAddress;
    uint256[] rewardTokenId;
    uint256[] rewardAmount;
  }

  ILootBox lootBox;
  ILootBoxDataStorage lootBoxDataStorage;
  IRewardsPool lootBoxRewardsPool;
  uint256 minimumGas;

  uint256 lootBoxesRevealed;

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _manager,
    address _lootBox,
    address _lootBoxDataStorage,
    address _lootBoxRewardsPool
  ) ManagerModifier(_manager) {
    lootBox = ILootBox(_lootBox);
    lootBoxDataStorage = ILootBoxDataStorage(_lootBoxDataStorage);
    lootBoxRewardsPool = IRewardsPool(_lootBoxRewardsPool);
    minimumGas = 500000;
  }

  //=======================================
  // External
  //=======================================
  function reveal(
    uint256[] calldata _lootBoxTokenIds,
    uint256[] calldata _lootBoxAmount
  ) external nonReentrant whenNotPaused {
    // Make sure the reveal is not done through another contract
    require(
      msg.sender == tx.origin,
      "Revealing is not allowed through another contract"
    );

    // Burn the LootBoxes
    lootBox.safeBurnBatch(msg.sender, _lootBoxTokenIds, _lootBoxAmount);

    // Generate additional randomness based on the number of LootBoxes revealed
    uint256 tempLootBoxesRevealed = lootBoxesRevealed;
    uint256 randomBase = Random.startRandomBase(tempLootBoxesRevealed, uint256(uint160(msg.sender)));

    for (uint256 i = 0; i < _lootBoxTokenIds.length; i++) {
      // Get the rarity of the burned LootBox
      uint16 lootBoxRarity = uint16(
        lootBoxDataStorage.characteristics(
          _lootBoxTokenIds[i],
          ITEM_CHARACTERISTIC_RARITY
        )
      );

      // Dispense rewards for each Lootbox
      for (uint256 j = 0; j < _lootBoxAmount[i]; j++) {
        require(
          gasleft() > minimumGas,
          "Manual gas reduction is not allowed"
        );

      DispensedRewards memory result = lootBoxRewardsPool.dispenseRewards(
          lootBoxRarity,
          randomBase,
          msg.sender
        );

        // Use the remainder of the hash as the random base for other Lootboxes
        randomBase = result.nextRandomBase;

        // Emit acquired rewards as an event for each Lootbox
        RewardsUnwrapper memory holder;
        holder.rewardTokenType = new uint256[](result.rewards.length);
        holder.rewardTokenAddress = new address[](result.rewards.length);
        holder.rewardTokenId = new uint256[](result.rewards.length);
        holder.rewardAmount = new uint256[](result.rewards.length);

        for (uint r = 0; r < holder.rewardTokenType.length; r++) {
          DispensedReward memory reward = result.rewards[i];
          holder.rewardTokenType[i] = (uint256) (reward.tokenType);
          holder.rewardTokenAddress[i] = reward.token;
          holder.rewardTokenId[i] = reward.tokenId;
          holder.rewardAmount[i] = reward.amount;
        }

        emit LootBoxRevealedEvent(
          tempLootBoxesRevealed++,
          msg.sender,
          _lootBoxTokenIds[i],
          holder.rewardTokenType,
          holder.rewardTokenAddress,
          holder.rewardTokenId,
          holder.rewardAmount
        );
      }

      // Increase the amount of LootBoxes revealed by the sender
      lootBoxesRevealed = tempLootBoxesRevealed;
    }
  }

  //=======================================
  // Admin
  //=======================================

  // Set minimum gas required (per lootbox)
  function setMinimumGas(uint256 _minimumGas) external onlyAdmin {
    minimumGas = _minimumGas;
  }

  function setRewardPool(address _rewardPoolAddress) external onlyAdmin {
    lootBoxRewardsPool = IRewardsPool(_rewardPoolAddress);
  }

  // Pauses the contract in case of emergency
  function pause() external onlyAdmin {
    _pause();
  }

  // Unpauses the contract
  function unpause() external onlyAdmin {
    _unpause();
  }
}

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