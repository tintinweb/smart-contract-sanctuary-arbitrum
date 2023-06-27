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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBatchBurnableStructure {
  function burnBatchFor(
    address _from,
    uint256[] calldata ids,
    uint256[] calldata amounts
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

interface ICollectible {
  function mintFor(address _for, uint256 _id, uint256 _amount) external;

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

pragma solidity ^0.8.17;

import "../BatchStaker/IBatchBurnableStructure.sol";

interface ILab is IBatchBurnableStructure {
  function mintFor(address _for, uint256 _id, uint256 _amount) external;

  function mintBatchFor(
    address _for,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external;

  function burnFor(address _for, uint256 _id, uint256 _amount) external;

  function burnBatchFor(
    address _for,
    uint256[] calldata _ids,
    uint256[] calldata _amounts
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ILabStorage {
  function set(
    uint256[] calldata _realmIds,
    uint256[] calldata _entityIds,
    uint256[] calldata _amounts
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Realm/IRealm.sol";
import "../Lab/ILab.sol";
import "../Collectible/ICollectible.sol";
import "../BatchStaker/IBatchStaker.sol";
import "../Lab/ILabStorage.sol";

import "../Manager/ManagerModifier.sol";

contract LabMinter is ReentrancyGuard, Pausable, ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IRealm public immutable REALM;
  ILab public immutable ENTITY;
  ICollectible public immutable COLLECTIBLE;
  IBatchStaker public immutable BATCH_STAKER;
  ILabStorage public immutable STORAGE;
  address public immutable COLLECTIBLE_HOLDER;

  //=======================================
  // Mappings
  //=======================================
  mapping(uint256 => uint256[]) public collectibleType;
  mapping(uint256 => uint256) public collectibleCost;

  //=======================================
  // Events
  //=======================================
  event Minted(uint256[] realmIds, uint256[] entityId, uint256[] quantity);
  event Burned(uint256[] realmIds, uint256[] entityId, uint256[] quantity);
  event CollectiblesUsed(
    uint256 realmId,
    uint256 collectibleId,
    uint256 amount
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _realm,
    address _manager,
    address _collectible,
    address _batchStaker,
    address _entity,
    address _storage,
    address _collectibleHolder
  ) ManagerModifier(_manager) {
    REALM = IRealm(_realm);
    COLLECTIBLE = ICollectible(_collectible);
    BATCH_STAKER = IBatchStaker(_batchStaker);
    ENTITY = ILab(_entity);
    COLLECTIBLE_HOLDER = _collectibleHolder;
    STORAGE = ILabStorage(_storage);

    collectibleType[0] = [20, 21];
    collectibleType[1] = [22, 23];
    collectibleType[2] = [24, 25];
    collectibleType[3] = [26];
    collectibleType[4] = [27];
    collectibleType[5] = [28];
    collectibleType[6] = [29];

    collectibleCost[0] = 10;
    collectibleCost[1] = 10;
    collectibleCost[2] = 10;
    collectibleCost[3] = 10;
    collectibleCost[4] = 10;
    collectibleCost[5] = 10;
    collectibleCost[6] = 10;
  }

  //=======================================
  // External
  //=======================================
  function mint(
    uint256[] calldata _realmIds,
    uint256[] calldata _collectibleIds,
    uint256[] calldata _entityIds,
    uint256[] calldata _quantities
  ) external nonReentrant whenNotPaused {
    for (uint256 j = 0; j < _entityIds.length; j++) {
      uint256 realmId = _realmIds[j];
      uint256 collectibleId = _collectibleIds[j];
      uint256 entityId = _entityIds[j];
      uint256 desiredQuantity = _quantities[j];

      // Check if Realm owner
      require(
        REALM.ownerOf(realmId) == msg.sender,
        "LabMinter: Must be Realm owner"
      );

      // Check collectibleId is valid
      _checkCollectibleType(entityId, collectibleId);

      // Mint
      ENTITY.mintFor(msg.sender, entityId, desiredQuantity);

      uint256 collectibleAmount = collectibleCost[entityId] * desiredQuantity;

      // Burn collectibles
      COLLECTIBLE.safeTransferFrom(
        msg.sender,
        COLLECTIBLE_HOLDER,
        collectibleId,
        collectibleAmount,
        ""
      );

      emit CollectiblesUsed(realmId, collectibleId, collectibleAmount);
    }

    emit Minted(_realmIds, _entityIds, _quantities);
  }

  function burn(
    uint256[][] calldata _realmIds,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _amounts
  ) external nonReentrant whenNotPaused {
    for (uint256 j = 0; j < _realmIds.length; j++) {
      uint256[] memory realmIds = _realmIds[j];
      uint256[] memory entityIds = _entityIds[j];
      uint256[] memory amounts = _amounts[j];

      // Burn entities
      ENTITY.burnBatchFor(msg.sender, entityIds, amounts);

      // Add labs to realm
      STORAGE.set(realmIds, entityIds, amounts);

      emit Burned(realmIds, entityIds, amounts);
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

  function updateCollectibleCost(
    uint256[] calldata _values
  ) external onlyAdmin {
    collectibleCost[0] = _values[0];
    collectibleCost[1] = _values[1];
    collectibleCost[2] = _values[2];
    collectibleCost[3] = _values[3];
    collectibleCost[4] = _values[4];
    collectibleCost[5] = _values[5];
    collectibleCost[6] = _values[6];
  }

  function updateCollectibleType(
    uint256[][] calldata _values
  ) external onlyAdmin {
    collectibleType[0] = _values[0];
    collectibleType[1] = _values[1];
    collectibleType[2] = _values[2];
    collectibleType[3] = _values[3];
    collectibleType[4] = _values[4];
    collectibleType[5] = _values[5];
    collectibleType[6] = _values[6];
  }

  //=======================================
  // Internal
  //=======================================
  function _checkCollectibleType(
    uint256 _entityId,
    uint256 _collectibleId
  ) internal view {
    bool invalid;

    for (uint256 j = 0; j < collectibleType[_entityId].length; j++) {
      // Check collectibleId matches collectible IDs
      if (_collectibleId == collectibleType[_entityId][j]) {
        invalid = false;
        break;
      }

      invalid = true;
    }

    require(
      !invalid,
      "LabMinter: Collectible doesn't match entity requirements"
    );
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

interface IRealm {
  function balanceOf(address owner) external view returns (uint256);

  function ownerOf(uint256 _realmId) external view returns (address owner);

  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  function isApprovedForAll(
    address owner,
    address operator
  ) external returns (bool);

  function realmFeatures(
    uint256 realmId,
    uint256 index
  ) external view returns (uint256);
}