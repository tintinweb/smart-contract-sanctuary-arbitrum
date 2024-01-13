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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IProductionCapacity {
  function productionCapacity(uint _realmId) external view returns (uint);

  function productionCapacityBatch(
    uint[] calldata _realmIds
  ) external view returns (uint[] memory result);

  function spendProductionCapacity(uint _realmId, uint _spentCapacity) external;

  function spendProductionCapacityBatch(
    uint[] calldata _realmIds,
    uint[] calldata _spentCapacity
  ) external;

  function resetProductionCapacity(uint _realmId) external;

  function resetProductionCapacityBatch(uint[] calldata _realmIds) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IReactor {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function mintFor(address _for, uint256 _quantity) external returns (uint256);

  function burn(uint256 _id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Realm/IRealm.sol";
import "./IReactor.sol";
import "../Staker/IStructureStaker.sol";
import "../RealmLock/IRealmLock.sol";
import "../Productivity/IProductionCapacity.sol";

import "../Manager/ManagerModifier.sol";

contract ReactorManager is ReentrancyGuard, Pausable, ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IRealm public immutable REALM;
  IReactor public immutable REACTOR;
  IStructureStaker public immutable STRUCTURE_STAKER;
  IProductionCapacity public immutable PRODUCTION_CAPACITY;

  //=======================================
  // ReamLock
  //=======================================
  IRealmLock public realmLock;

  //=======================================
  // Arrays
  //=======================================
  address[] public reactorAddress;

  //=======================================
  // Events
  //=======================================
  event ReactorStaked(uint256 realmId, address structureAddress, uint256 structureId);
  event ReactorUnstaked(uint256 realmId, address structureAddress, uint256 structureId);
  event ReactorBatchStaked(
    uint256[] realmIds,
    address[] structureAddresses,
    uint256[] structureIds
  );
  event ReactorBatchUnstaked(
    uint256[] realmIds,
    address[] structureAddresses,
    uint256[] structureIds
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _realm,
    address _manager,
    address _reactor,
    address _structureStaker,
    address _realmLock,
    address _productionCapacity
  ) ManagerModifier(_manager) {
    REALM = IRealm(_realm);
    REACTOR = IReactor(_reactor);
    STRUCTURE_STAKER = IStructureStaker(_structureStaker);
    PRODUCTION_CAPACITY = IProductionCapacity(_productionCapacity);

    realmLock = IRealmLock(_realmLock);

    reactorAddress = [_reactor];
  }

  //=======================================
  // External
  //=======================================
  function stake(uint256 _realmId, uint256 _structureId) external nonReentrant whenNotPaused {
    // Stake
    STRUCTURE_STAKER.stakeFor(msg.sender, _realmId, address(REACTOR), _structureId);

    // Reset production
    PRODUCTION_CAPACITY.resetProductionCapacity(_realmId);

    emit ReactorStaked(_realmId, address(REACTOR), _structureId);
  }

  function stakeBatch(
    uint256[] calldata _realmIds,
    uint256[] calldata _structureIds
  ) external nonReentrant whenNotPaused {
    // Stake
    STRUCTURE_STAKER.stakeBatchFor(msg.sender, _realmIds, reactorAddress, _structureIds);

    // Reset production
    PRODUCTION_CAPACITY.resetProductionCapacityBatch(_realmIds);

    emit ReactorBatchStaked(_realmIds, reactorAddress, _structureIds);
  }

  function unstake(uint256 _realmId, uint256 _structureId) external nonReentrant whenNotPaused {
    // Check if Realm is locked
    require(realmLock.isUnlocked(_realmId), "ReactorManager: Realm is locked");

    // Unstake
    STRUCTURE_STAKER.unstakeFor(msg.sender, _realmId, address(REACTOR), _structureId);

    emit ReactorUnstaked(_realmId, address(REACTOR), _structureId);
  }

  function unstakeBatch(
    uint256[] calldata _realmIds,
    uint256[] calldata _structureIds
  ) external nonReentrant whenNotPaused {
    // Check if Realm is locked
    for (uint256 j = 0; j < _realmIds.length; j++) {
      require(realmLock.isUnlocked(_realmIds[j]), "ReactorManager: Realm is locked");
    }

    // Unstake
    STRUCTURE_STAKER.unstakeBatchFor(msg.sender, _realmIds, reactorAddress, _structureIds);

    emit ReactorBatchUnstaked(_realmIds, reactorAddress, _structureIds);
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

  function updateRealmLock(address _realmLock) external onlyAdmin {
    realmLock = IRealmLock(_realmLock);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealmLock {
  function lock(uint256 _realmId, uint256 _hours) external;

  function unlock(uint256 _realmId) external;

  function isUnlocked(uint256 _realmId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStructureStaker {
  function stakeFor(
    address _staker,
    uint256 _realmId,
    address _addr,
    uint256 _structureId
  ) external;

  function unstakeFor(
    address _staker,
    uint256 _realmId,
    address _addr,
    uint256 _structureId
  ) external;

  function stakeBatchFor(
    address _staker,
    uint256[] calldata _realmIds,
    address[] calldata _addrs,
    uint256[] calldata _structureIds
  ) external;

  function unstakeBatchFor(
    address _staker,
    uint256[] calldata _realmIds,
    address[] calldata _addrs,
    uint256[] calldata _structureIds
  ) external;

  function getStaker(
    uint256 _realmId,
    address _addr,
    uint256 _structureId
  ) external;

  function hasStaked(
    uint256 _realmId,
    address _addr,
    uint256 _count
  ) external returns (bool);
}