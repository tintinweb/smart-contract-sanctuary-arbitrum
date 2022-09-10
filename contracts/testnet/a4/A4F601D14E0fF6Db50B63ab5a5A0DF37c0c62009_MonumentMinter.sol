// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Realm/IRealm.sol";
import "../Monument/IMonument.sol";
import "../RealmLock/IRealmLock.sol";
import "../Collectible/ICollectible.sol";
import "../BatchStaker/IBatchStaker.sol";
import "../Entity/IEntityTimer.sol";

import "../Manager/ManagerModifier.sol";

contract MonumentMinter is ReentrancyGuard, Pausable, ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IRealm public immutable REALM;
  IMonument public immutable ENTITY;
  ICollectible public immutable COLLECTIBLE;
  IBatchStaker public immutable BATCH_STAKER;
  IEntityTimer public immutable TIMER;
  address public immutable COLLECTIBLE_HOLDER;

  //=======================================
  // RealmLock
  //=======================================
  IRealmLock public realmLock;

  //=======================================
  // Uintss
  //=======================================
  uint256 public maxEntities = 3;

  //=======================================
  // Arrays
  //=======================================
  uint256[] public requirements;
  uint256[] public requirementAmounts;

  //=======================================
  // Mappings
  //=======================================
  mapping(uint256 => uint256[]) public collectibleType;
  mapping(uint256 => uint256) public buildHours;
  mapping(uint256 => uint256) public collectibleCost;

  //=======================================
  // Events
  //=======================================
  event Minted(uint256 realmId, uint256 entityId, uint256 quantity);
  event CollectiblesUsed(
    uint256 realmId,
    uint256 collectibleId,
    uint256 amount
  );
  event StakedEntity(
    uint256 realmId,
    address addr,
    uint256[] entityIds,
    uint256[] amounts
  );
  event UnstakedEntity(
    uint256 realmId,
    address addr,
    uint256[] entityIds,
    uint256[] amounts
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _realm,
    address _manager,
    address _collectible,
    address _batchStaker,
    address _timer,
    address _entity,
    address _realmLock,
    address _collectibleHolder,
    uint256[][] memory _collectibleType,
    uint256[] memory _requirements,
    uint256[] memory _requirementAmounts
  ) ManagerModifier(_manager) {
    REALM = IRealm(_realm);
    COLLECTIBLE = ICollectible(_collectible);
    BATCH_STAKER = IBatchStaker(_batchStaker);
    TIMER = IEntityTimer(_timer);
    ENTITY = IMonument(_entity);
    COLLECTIBLE_HOLDER = _collectibleHolder;

    realmLock = IRealmLock(_realmLock);

    collectibleType[0] = _collectibleType[0];
    collectibleType[1] = _collectibleType[1];
    collectibleType[2] = _collectibleType[2];
    collectibleType[3] = _collectibleType[3];
    collectibleType[4] = _collectibleType[4];
    collectibleType[5] = _collectibleType[5];
    collectibleType[6] = _collectibleType[6];

    requirements = _requirements;
    requirementAmounts = _requirementAmounts;

    buildHours[0] = 12;
    buildHours[1] = 12;
    buildHours[2] = 24;
    buildHours[3] = 24;
    buildHours[4] = 36;
    buildHours[5] = 36;
    buildHours[6] = 48;

    collectibleCost[0] = 7;
    collectibleCost[1] = 7;
    collectibleCost[2] = 7;
    collectibleCost[3] = 7;
    collectibleCost[4] = 6;
    collectibleCost[5] = 6;
    collectibleCost[6] = 5;
  }

  //=======================================
  // External
  //=======================================
  function mint(
    uint256 _realmId,
    uint256[] calldata _collectibleIds,
    uint256[] calldata _entityIds,
    uint256[] calldata _quantities
  ) external nonReentrant whenNotPaused {
    // Check if Realm owner
    require(
      REALM.ownerOf(_realmId) == msg.sender,
      "EntityMinter: Must be Realm owner"
    );

    uint256 totalQuantity;
    uint256 totalHours;

    for (uint256 j = 0; j < _entityIds.length; j++) {
      uint256 collectibleId = _collectibleIds[j];
      uint256 entityId = _entityIds[j];
      uint256 desiredQuantity = _quantities[j];

      // Check collectibleId is prime collectible
      _checkCollectibleType(entityId, collectibleId);

      // Check requirements
      _checkRequirements(_realmId, entityId);

      // Mint
      _mint(_realmId, entityId, desiredQuantity);

      // Add to quantity
      totalQuantity = totalQuantity + desiredQuantity;

      // Add total hours
      totalHours = totalHours + (buildHours[entityId] * desiredQuantity);

      uint256 collectibleAmount = collectibleCost[entityId] * desiredQuantity;

      // Burn collectibles
      COLLECTIBLE.safeTransferFrom(
        msg.sender,
        COLLECTIBLE_HOLDER,
        collectibleId,
        collectibleAmount,
        ""
      );

      emit CollectiblesUsed(_realmId, collectibleId, collectibleAmount);
    }

    // Check if totalQuantity is below max entities
    require(
      totalQuantity <= maxEntities,
      "EntityMinter: Max entities per transaction reached"
    );

    // Build
    TIMER.build(_realmId, totalHours);
  }

  function stakeBatch(
    uint256[] calldata _realmIds,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _amounts
  ) external nonReentrant whenNotPaused {
    for (uint256 j = 0; j < _realmIds.length; j++) {
      uint256 realmId = _realmIds[j];
      uint256[] memory entityIds = _entityIds[j];
      uint256[] memory amounts = _amounts[j];

      BATCH_STAKER.stakeBatchFor(
        msg.sender,
        address(ENTITY),
        realmId,
        entityIds,
        amounts
      );

      emit StakedEntity(realmId, address(ENTITY), entityIds, amounts);
    }
  }

  function unstakeBatch(
    uint256[] calldata _realmIds,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _amounts
  ) external nonReentrant whenNotPaused {
    for (uint256 j = 0; j < _realmIds.length; j++) {
      uint256 realmId = _realmIds[j];

      // Check if Realm is locked
      require(realmLock.isUnlocked(realmId), "EntityMinter: Realm is locked");

      uint256[] memory entityIds = _entityIds[j];
      uint256[] memory amounts = _amounts[j];

      BATCH_STAKER.unstakeBatchFor(
        msg.sender,
        address(ENTITY),
        realmId,
        entityIds,
        amounts
      );

      emit UnstakedEntity(realmId, address(ENTITY), entityIds, amounts);
    }
  }

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  function updateCollectibleCost(uint256[] calldata _values)
    external
    onlyAdmin
  {
    collectibleCost[0] = _values[0];
    collectibleCost[1] = _values[1];
    collectibleCost[2] = _values[2];
    collectibleCost[3] = _values[3];
    collectibleCost[4] = _values[4];
    collectibleCost[5] = _values[5];
    collectibleCost[6] = _values[6];
  }

  function updateMaxEntities(uint256 _maxEntities) external onlyAdmin {
    maxEntities = _maxEntities;
  }

  function updateBuildHours(uint256[] calldata _values) external onlyAdmin {
    buildHours[0] = _values[0];
    buildHours[1] = _values[1];
    buildHours[2] = _values[2];
    buildHours[3] = _values[3];
    buildHours[4] = _values[4];
    buildHours[5] = _values[5];
    buildHours[6] = _values[6];
  }

  function updateRealmLock(address _realmLock) external onlyAdmin {
    realmLock = IRealmLock(_realmLock);
  }

  function updateRequirements(uint256[] calldata _requirements)
    external
    onlyAdmin
  {
    requirements = _requirements;
  }

  function updateCollectibleType(uint256[][] calldata _values)
    external
    onlyAdmin
  {
    collectibleType[0] = _values[0];
    collectibleType[1] = _values[1];
    collectibleType[2] = _values[2];
    collectibleType[3] = _values[3];
    collectibleType[4] = _values[4];
    collectibleType[5] = _values[5];
    collectibleType[6] = _values[6];
  }

  function updateRequirementAmounts(uint256[] calldata _requirementAmounts)
    external
    onlyAdmin
  {
    requirementAmounts = _requirementAmounts;
  }

  //=======================================
  // Internal
  //=======================================
  function _checkRequirements(uint256 _realmId, uint256 _entityId)
    internal
    view
  {
    // Town does not require any staked entities
    if (_entityId == 0) return;

    // Check they have right amount of staked entities
    require(
      BATCH_STAKER.hasStaked(
        _realmId,
        address(ENTITY),
        requirements[_entityId],
        requirementAmounts[_entityId]
      ),
      "EntityMinter: Don't have the required entity staked"
    );
  }

  function _checkCollectibleType(uint256 _entityId, uint256 _collectibleId)
    internal
    view
  {
    bool invalid;

    for (uint256 j = 0; j < collectibleType[_entityId].length; j++) {
      // Check collectibleId matches prime collectible IDs
      if (_collectibleId == collectibleType[_entityId][j]) {
        invalid = false;
        break;
      }

      invalid = true;
    }

    require(
      !invalid,
      "EntityMinter: Collectible doesn't match entity requirements"
    );
  }

  function _mint(
    uint256 _realmId,
    uint256 _entityId,
    uint256 _desiredQuantity
  ) internal {
    // Mint
    ENTITY.mintFor(msg.sender, _entityId, _desiredQuantity);

    emit Minted(_realmId, _entityId, _desiredQuantity);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

pragma solidity ^0.8.4;

interface IRealm {
  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 _realmId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function isApprovedForAll(address owner, address operator)
    external
    returns (bool);

  function realmFeatures(uint256 realmId, uint256 index)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMonument {
  function mintFor(
    address _for,
    uint256 _id,
    uint256 _amount
  ) external;

  function mintBatchFor(
    address _for,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] calldata ids, uint256[] calldata amounts)
    external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealmLock {
  function lock(uint256 _realmId, uint256 _hours) external;

  function unlock(uint256 _realmId) external;

  function isUnlocked(uint256 _realmId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICollectible {
  function mintFor(
    address _for,
    uint256 _id,
    uint256 _amount
  ) external;

  function mintBatchFor(
    address _for,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] memory ids, uint256[] memory amounts) external;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBatchStaker {
  function stakeBatchFor(
    address _staker,
    address _addr,
    uint256 _realmId,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function unstakeBatchFor(
    address _staker,
    address _addr,
    uint256 _realmId,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function hasStaked(
    uint256 _realmId,
    address _addr,
    uint256 _id,
    uint256 _count
  ) external view returns (bool);

  function stakerBalance(
    uint256 _realmId,
    address _addr,
    uint256 _id
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IEntityTimer {
  function build(uint256 _realmId, uint256 _hours) external;

  function canBuild(uint256 _realmId) external view returns (bool);
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