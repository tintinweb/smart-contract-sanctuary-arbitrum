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

pragma solidity ^0.8.4;

interface IAdventurerData {
  function initData(
    address[] calldata _addresses,
    uint256[] calldata _ids,
    bytes32[][] calldata _proofs,
    uint256[] calldata _professions,
    uint256[][] calldata _points
  ) external;

  function baseProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function aovProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function extensionProperties(
    address _addr,
    uint256 _id,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256[] memory);

  function createFor(
    address _addr,
    uint256 _id,
    uint256[] calldata _points
  ) external;

  function createFor(
    address _addr,
    uint256 _id,
    uint256 _archetype
  ) external;

  function addToBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromBase(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromAov(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function addToExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function updateExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function removeFromExtension(
    address _addr,
    uint256 _id,
    uint256 _prop,
    uint256 _val
  ) external;

  function base(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function aov(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);

  function extension(
    address _addr,
    uint256 _id,
    uint256 _prop
  ) external view returns (uint256);
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

pragma solidity ^0.8.4;

interface IQuest {
  function go(
    address _addr,
    uint256 _adventurerId,
    uint256 _questId
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../Adventurer/IAdventurerData.sol";
import "./IQuest.sol";

import "../Manager/ManagerModifier.sol";

contract QuestV1 is IQuest, ManagerModifier, ReentrancyGuard {
  //=======================================
  // Immutables
  //=======================================
  IAdventurerData public immutable ADVENTURER_DATA;

  //=======================================
  // Struct
  //=======================================
  struct Quest {
    uint32 xp;
    uint32 level;
    uint256 cost;
  }

  //=======================================
  // Uints
  //=======================================
  uint256 public animaBaseReward;
  uint256 public professionBonus;

  //=======================================
  // Mappings
  //=======================================
  mapping(uint256 => Quest) public quests;

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _manager,
    address _advData,
    uint256 _animaBaseReward,
    uint256 _professionBonus
  ) ManagerModifier(_manager) {
    ADVENTURER_DATA = IAdventurerData(_advData);

    quests[0] = Quest({ xp: 1, level: 1, cost: 100000000000000000 });
    quests[1] = Quest({ xp: 1, level: 1, cost: 100000000000000000 });
    quests[2] = Quest({ xp: 2, level: 2, cost: 200000000000000000 });
    quests[3] = Quest({ xp: 2, level: 3, cost: 300000000000000000 });
    quests[4] = Quest({ xp: 3, level: 4, cost: 400000000000000000 });
    quests[5] = Quest({ xp: 3, level: 5, cost: 500000000000000000 });

    // Base reward for anima per quest
    animaBaseReward = _animaBaseReward;

    // Profession bonus
    professionBonus = _professionBonus;
  }

  //=======================================
  // External
  //=======================================
  function go(
    address _addr,
    uint256 _adventurerId,
    uint256 _questId
  )
    external
    view
    override
    onlyManager
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Quest memory quest = quests[_questId];

    // Check quest exists
    require(quest.xp > 0, "QuestV1: Quest does not exist");

    // Retrieve adventurer data
    uint256[] memory properties = _adventurerData(_addr, _adventurerId);

    // Check level
    require(properties[0] >= quest.level, "QuestV1: Level not high enough");

    return (quest.cost, quest.xp, _anima(properties));
  }

  //=======================================
  // Admin
  //=======================================
  function updateQuests(
    uint256 _questId,
    uint32 _xp,
    uint32 _level,
    uint32 _cost
  ) external onlyAdmin {
    Quest storage quest = quests[_questId];

    quest.xp = _xp;
    quest.level = _level;
    quest.cost = _cost;
  }

  function updateAnimaBaseRewards(uint256 _animaBaseReward) external onlyAdmin {
    animaBaseReward = _animaBaseReward;
  }

  function updateProfessionBonus(uint256 _professionBonus) external onlyAdmin {
    professionBonus = _professionBonus;
  }

  //=======================================
  // Internal
  //=======================================
  function _anima(uint256[] memory _properties)
    internal
    view
    returns (uint256)
  {
    // Calculate anima based on transcendence level
    uint256 anima = _properties[0] * animaBaseReward;

    // Check if profession is Zealot
    if (_properties[3] == 2) {
      anima += professionBonus;
    }

    return anima;
  }

  function _adventurerData(address _addr, uint256 _adventurerId)
    internal
    view
    returns (uint256[] memory)
  {
    return ADVENTURER_DATA.aovProperties(_addr, _adventurerId, 0, 3);
  }
}