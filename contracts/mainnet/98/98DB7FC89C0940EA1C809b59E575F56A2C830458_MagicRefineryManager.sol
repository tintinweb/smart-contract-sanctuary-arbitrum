// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Realm/IRealm.sol";
import "./IMagicRefinery.sol";
import "../Staker/IStructureStaker.sol";
import "../RealmLock/IRealmLock.sol";

import "../Manager/ManagerModifier.sol";

contract MagicRefineryManager is ReentrancyGuard, Pausable, ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IRealm public immutable REALM;
  IMagicRefinery public immutable REFINERY;
  IStructureStaker public immutable STRUCTURE_STAKER;
  IRealmLock public immutable REALM_LOCK;

  //=======================================
  // Events
  //=======================================
  event MagicRefineryStaked(
    uint256 realmId,
    address structureAddress,
    uint256 structureId
  );
  event MagicRefineryUnstaked(
    uint256 realmId,
    address structureAddress,
    uint256 structureId
  );
  event MagicRefineryBatchStaked(
    uint256[] realmIds,
    address[] structureAddresses,
    uint256[] structureIds
  );
  event MagicRefineryBatchUnstaked(
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
    address _refinery,
    address _structureStaker,
    address _realmLock
  ) ManagerModifier(_manager) {
    REALM = IRealm(_realm);
    REFINERY = IMagicRefinery(_refinery);
    STRUCTURE_STAKER = IStructureStaker(_structureStaker);
    REALM_LOCK = IRealmLock(_realmLock);
  }

  //=======================================
  // External
  //=======================================
  function stake(uint256 _realmId, uint256 _structureId)
    external
    nonReentrant
    whenNotPaused
  {
    // Stake
    STRUCTURE_STAKER.stakeFor(
      msg.sender,
      _realmId,
      address(REFINERY),
      _structureId
    );

    emit MagicRefineryStaked(_realmId, address(REFINERY), _structureId);
  }

  function stakeBatch(
    uint256[] calldata _realmIds,
    uint256[] calldata _structureIds
  ) external nonReentrant whenNotPaused {
    // Set addresses
    address[] memory addresses = new address[](1);
    addresses[0] = address(REFINERY);

    // Stake
    STRUCTURE_STAKER.stakeBatchFor(
      msg.sender,
      _realmIds,
      addresses,
      _structureIds
    );

    emit MagicRefineryBatchStaked(_realmIds, addresses, _structureIds);
  }

  function unstake(uint256 _realmId, uint256 _structureId)
    external
    nonReentrant
    whenNotPaused
  {
    // Check if Realm is locked
    require(
      REALM_LOCK.isUnlocked(_realmId),
      "MagicRefineryManager: Realm is locked"
    );

    // Unstake
    STRUCTURE_STAKER.unstakeFor(
      msg.sender,
      _realmId,
      address(REFINERY),
      _structureId
    );

    emit MagicRefineryUnstaked(_realmId, address(REFINERY), _structureId);
  }

  function unstakeBatch(
    uint256[] calldata _realmIds,
    uint256[] calldata _structureIds
  ) external nonReentrant whenNotPaused {
    uint256 j = 0;
    uint256 length = _realmIds.length;

    // Check if Realm is locked
    for (; j < length; j++) {
      require(
        REALM_LOCK.isUnlocked(_realmIds[j]),
        "MagicRefineryManager: Realm is locked"
      );
    }

    // Set addresses
    address[] memory addresses = new address[](1);
    addresses[0] = address(REFINERY);

    // Unstake
    STRUCTURE_STAKER.unstakeBatchFor(
      msg.sender,
      _realmIds,
      addresses,
      _structureIds
    );

    emit MagicRefineryBatchUnstaked(_realmIds, addresses, _structureIds);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

interface IMagicRefinery {
  function ownerOf(uint256 _realmId) external view returns (address owner);

  function mintFor(address _for, uint256 _quantity) external returns (uint256);

  function burn(uint256 _id) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRealmLock {
  function lock(uint256 _realmId, uint256 _hours) external;

  function unlock(uint256 _realmId) external;

  function isUnlocked(uint256 _realmId) external view returns (bool);
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