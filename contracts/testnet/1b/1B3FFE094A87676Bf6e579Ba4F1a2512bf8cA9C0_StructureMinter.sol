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

pragma solidity ^0.8.17;

uint256 constant ACTION_LOCK = 101;

uint256 constant ACTION_ADVENTURER_HOMAGE = 1001;
uint256 constant ACTION_ADVENTURER_BATTLE_V3 = 1002;
uint256 constant ACTION_ADVENTURER_COLLECT_EPOCH_REWARDS = 1003;
uint256 constant ACTION_ADVENTURER_VOID_CRAFTING = 1004;
uint256 constant ACTION_ADVENTURER_REALM_CRAFTING = 1005;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM = 2001;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM = 2002;

uint256 constant ACTION_ARMORY_STAKE_RARITY_ITEM_SHARD = 2011;
uint256 constant ACTION_ARMORY_UNSTAKE_RARITY_ITEM_SHARD = 2012;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL_SHARD = 2021;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL_SHARD = 2022;

uint256 constant ACTION_ARMORY_STAKE_LAB = 2031;
uint256 constant ACTION_ARMORY_UNSTAKE_LAB = 2032;

uint256 constant ACTION_ARMORY_STAKE_COLLECTIBLE = 2041;
uint256 constant ACTION_ARMORY_UNSTAKE_COLLECTIBLE = 2042;

uint256 constant ACTION_ARMORY_STAKE_MATERIAL = 2051;
uint256 constant ACTION_ARMORY_UNSTAKE_MATERIAL = 2052;

uint256 constant ACTION_PRODUCTION_CREATE_LAB = 4001;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error Unauthorized(address _tokenAddr, uint256 _tokenId);
error EntityLocked(address _tokenAddr, uint256 _tokenId, uint _lockedUntil);
error MinEpochsTooLow(uint256 _minEpochs);
error InsufficientEpochSpan(
  uint256 _minEpochs,
  uint256 _epochs,
  address _tokenAddr,
  uint256 _tokenId
);
error DuplicateActionAttempt(address _tokenAddr, uint256 _tokenId);

interface IActionPermit {
  // Reverts if no permissions or action already taken this epoch
  function checkAndMarkActionComplete(
    address _sender,
    address _tokenAddr,
    uint256 _tokenId,
    uint256 _action,
    uint256 _minEpochs
  ) external returns (uint256 _epochsSinceLastAction, uint currentEpoch);

  function checkAndMarkActionCompleteMany(
    address _sender,
    address[] calldata _tokenAddr,
    uint256[] calldata _tokenId,
    uint256 _action,
    uint256 _minEpochs
  ) external returns (uint currentEpoch);

  // Marks action complete even if already completed
  function forceMarkActionComplete(address _tokenAddr, uint256 _tokenId, uint256 _action) external;

  // Reverts if no permissions
  function checkPermissions(
    address _sender,
    address _tokenAddr,
    uint256 _tokenId,
    uint256 _action
  ) external view;

  function checkPermissionsMany(
    address _sender,
    address[] calldata _tokenAddr,
    uint256[] calldata _tokenId,
    uint256 _action
  ) external view;

  function checkPermissionsMany(
    address _sender,
    address _tokenAddr,
    uint256[] calldata _tokenId,
    uint256 _action
  ) external view;

  // Reverts if action already taken this epoch
  function checkIfEnoughEpochsElapsed(
    address _tokenAddr,
    uint256 _tokenId,
    uint256 _action,
    uint256 _minEpochs
  ) external view returns (uint256 elapsedEpochs, uint256 currentEpoch);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Manager/ManagerModifier.sol";
import "./IArmoryEntityStorageAdapter.sol";

interface IArmory {
  function stakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function stakeBatchMulti(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address[] calldata _entityAddresses,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function stakeBatchMulti(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds,
    uint256[][][] calldata _entityAmounts
  ) external;

  function unstakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function unstakeBatchMulti(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address[] calldata _entityAddresses,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function unstakeBatchMulti(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address[] calldata _entityAddress,
    uint256[][][] calldata _entityIds,
    uint256[][][] calldata _entityAmounts
  ) external;

  function burn(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function burnBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function burnBatchMulti(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address[] calldata _entityAddresses,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function burnBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds,
    uint256[][][] calldata _entityAmounts
  ) external;

  function mint(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function mintBatch(
    address _ownerAddresses,
    uint256 _ownerTokenIds,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function mintBatchMulti(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address[] calldata _entityAddresses,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function mintBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds,
    uint256[][][] calldata _entityAmounts
  ) external;

  function checkMinimumAmounts(
    address _ownerAddresses,
    uint256 _ownerTokenIds,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external view;

  function checkMinimumAmounts(
    address _ownerAddresses,
    uint256 _ownerTokenIds,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256 _entityAmounts
  ) external view;

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external view;

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256 _entityAmount
  ) external view;

  function balanceOf(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityTokenId
  ) external view returns (uint);

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint[] memory _entityTokenIds
  ) external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IArmoryEntityStorageAdapter {
  error Unauthorized(address _staker, address _ownerAddress, uint _ownerId);
  error UnsupportedOperation(address _entityAddress, string operation);
  error UnsupportedEntity(address _entityAddress);
  error InsufficientAmountStaked(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _tokenIds,
    uint _tokenAmounts
  );

  function entityType() external pure returns (uint);

  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external;

  function stakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external;

  function unstakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function burn(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256 _entityTokenId, // only used for ERC-721, ERC-1155
    uint256 _entityAmount // only used for ERC-20, ERC-1155
  ) external;

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function burnBatch(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function mint(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256 _entityTokenId, // only used for ERC-721, ERC-1155
    uint256 _entityAmount // only used for ERC-20, ERC-1155
  ) external;

  function mintBatch(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external view;

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external view;

  // Reverts if not enough tokens
  function batchCheckAmounts(
    address _ownerAddresses,
    uint256 _ownerIds,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256 _entityAmounts // only used for ERC-20, ERC-1155
  ) external view;

  function balanceOf(
    address _ownerAddress,
    uint _ownerIds,
    address _entityAddress,
    uint _entityTokenId
  ) external view returns (uint);

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds
  ) external view returns (uint[] memory);
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

interface IRandomPicker {
  function addToQueue(uint256 queueType, uint256 subQueue, uint256 owner, uint256 number) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256 subQueue,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256 owner,
    uint256[] calldata number
  ) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[][] calldata owner,
    uint256[][] calldata number
  ) external;

  function addToQueueBatch(
    uint256 queueType,
    uint256[][] calldata subQueue,
    uint256[] calldata owner,
    uint256[][] calldata number
  ) external;

  function removeFromQueue(
    uint256 queueType,
    uint256 subQueue,
    uint256 owner,
    uint256 number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256 subQueue,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256 owner,
    uint256[] calldata number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[][] calldata owner,
    uint256[][] calldata number
  ) external;

  function removeFromQueueBatch(
    uint256 queueType,
    uint256[][] calldata subQueue,
    uint256[] calldata owner,
    uint256[][] calldata number
  ) external;

  function useRandomizer(
    uint256 queueType,
    uint256 subQueue,
    uint256 number,
    uint256 randomBase
  ) external view returns (uint[] memory result, uint newRandomBase);

  function useRandomizerBatch(
    uint256 queueType,
    uint256[] calldata subQueue,
    uint256[] calldata number,
    uint256 randomBase
  ) external view returns (uint[][] memory result, uint newRandomBase);

  function getQueueSizes(
    uint256 queueType,
    uint256[] calldata subQueues
  ) external view returns (uint256[] memory result);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";

import "../Collectible/ICollectible.sol";
import "../BatchStaker/IBatchStaker.sol";

import "../Manager/ManagerModifier.sol";
import "../Armory/IArmory.sol";
import "../Action/IActionPermit.sol";
import "../Action/Actions.sol";
import "../Utils/ArrayUtils.sol";
import "../RandomPicker/IRandomPicker.sol";

struct StructureMintRequest {
  address structureAddress;
  uint256[] realmIds;
  // Structure requests
  uint256[][] structureTokenIds;
  uint256[][] structureAmounts;
  // Staking collectibles
  uint256[][] stakeCollectibleIds;
  uint256[][] stakeCollectibleAmounts;
  // collectibles used in structure blueprints
  uint256[][] useCollectibleIds;
  uint256[][] useCollectibleAmounts;
}

struct StructureBlueprint {
  uint256 structureTokenId;
  uint256 collectibleTokenId;
  uint256 collectibleCost;
}

contract StructureMinter is Pausable, ManagerModifier {
  error InvalidCollectibleType(uint realmId, uint structureId, uint collectibleId);

  error InvalidCollectibleAmount(
    uint realmId,
    uint structureId,
    uint collectibleId,
    uint submittedAmount,
    uint requiredAmount
  );

  //=======================================
  // Immutables
  //=======================================
  address public immutable REALM_ADDRESS;
  address public immutable COLLECTIBLE_ADDRESS;
  IArmory public immutable REALM_ARMORY;
  IActionPermit public immutable ACTION_PERMIT;
  IRandomPicker public immutable RANDOM_PICKER;
  uint public immutable PERMISSION;

  //=======================================
  // Mappings
  //=======================================

  mapping(address => uint) public actionIds;
  mapping(address => StructureBlueprint[]) public blueprints;
  // structure address => structure id => collectible id => collectible cost
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public collectibleCosts;

  //=======================================
  // Events
  //=======================================
  event StructuresMinted(
    uint256 realmId,
    address structureAddress,
    uint256[] structureIds,
    uint256[] structureAmounts,
    uint256[] collectibleIds,
    uint256[] collectibleAmounts
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(
    address _manager,
    address _realm,
    address _collectible,
    address _armory,
    address _actionPermit,
    address _randomPicker
  ) ManagerModifier(_manager) {
    REALM_ADDRESS = _realm;
    COLLECTIBLE_ADDRESS = _collectible;
    REALM_ARMORY = IArmory(_armory);
    ACTION_PERMIT = IActionPermit(_actionPermit);
    PERMISSION = ACTION_PRODUCTION_CREATE_LAB;
    RANDOM_PICKER = IRandomPicker(_randomPicker);
  }

  //=======================================
  // External
  //=======================================
  function mint(StructureMintRequest calldata _request) external whenNotPaused {
    uint256 realmId;
    uint256 collectibleId;
    uint256 structureId;
    uint256 collectibleAmount;

    // Check if Realm owners
    ACTION_PERMIT.checkPermissionsMany(
      msg.sender,
      REALM_ADDRESS,
      _request.realmIds,
      actionIds[_request.structureAddress]
    );

    address[] memory rlmAddressArray = ArrayUtils.toMemoryArray(
      REALM_ADDRESS,
      _request.realmIds.length
    );

    // Stake required collectibles in the Realm armories
    REALM_ARMORY.stakeBatch(
      msg.sender,
      rlmAddressArray,
      _request.realmIds,
      COLLECTIBLE_ADDRESS,
      _request.stakeCollectibleIds,
      _request.stakeCollectibleAmounts
    );

    // Burn collectibles from the armory
    REALM_ARMORY.burnBatch(
      rlmAddressArray,
      _request.realmIds,
      COLLECTIBLE_ADDRESS,
      _request.useCollectibleIds,
      _request.useCollectibleAmounts
    );

    for (uint256 i = 0; i < _request.realmIds.length; i++) {
      realmId = _request.realmIds[i];
      for (uint256 j = 0; j < _request.structureTokenIds[i].length; j++) {
        structureId = _request.structureTokenIds[i][j];
        collectibleId = _request.useCollectibleIds[i][j];
        collectibleAmount = _request.useCollectibleAmounts[i][j];

        // Check collectible amounts are valid
        _checkCollectibleAmounts(
          realmId,
          _request.structureAddress,
          structureId,
          _request.structureAmounts[i][j],
          collectibleId,
          collectibleAmount
        );
      }

      // Emit the event, but we'll actually mint in batch for all Realms later
      emit StructuresMinted(
        realmId,
        _request.structureAddress,
        _request.structureTokenIds[i],
        _request.structureAmounts[i],
        _request.useCollectibleIds[i],
        _request.useCollectibleAmounts[i]
      );
    }

    // Mass mint staked amounts in the armory
    REALM_ARMORY.mintBatch(
      rlmAddressArray,
      _request.realmIds,
      _request.structureAddress,
      _request.structureTokenIds,
      _request.structureAmounts
    );

    // Add labs to be able to be picked during crafting
    RANDOM_PICKER.addToQueueBatch(
      uint256(uint160(_request.structureAddress)),
      _request.structureTokenIds,
      _request.realmIds,
      _request.structureAmounts
    );
  }

  //=======================================
  // Internal
  //=======================================

  function _checkCollectibleAmounts(
    uint _realmId,
    address _structureAddress,
    uint _structureId,
    uint _structureAmount,
    uint _collectibleId,
    uint _collectibleAmount
  ) internal view {
    uint cost = collectibleCosts[_structureAddress][_structureId][_collectibleId];
    if (cost == 0) {
      revert InvalidCollectibleType(_realmId, _structureId, _structureAmount);
    }
    if (cost * _structureAmount != _collectibleAmount) {
      revert InvalidCollectibleAmount(
        _realmId,
        _structureId,
        _structureAmount,
        _collectibleAmount,
        cost * _structureAmount
      );
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

  function updateBlueprints(
    address _structureAddress,
    StructureBlueprint[] calldata _blueprints
  ) external onlyAdmin {
    // Disable current blueprints
    for (uint i = 0; i < blueprints[_structureAddress].length; i++) {
      collectibleCosts[_structureAddress][blueprints[_structureAddress][i].structureTokenId][
        blueprints[_structureAddress][i].collectibleTokenId
      ] = 0;
    }

    while (_blueprints.length < blueprints[_structureAddress].length) {
      blueprints[_structureAddress].pop();
    }
    while (_blueprints.length > blueprints[_structureAddress].length) {
      blueprints[_structureAddress].push();
    }

    for (uint i = 0; i < _blueprints.length; i++) {
      blueprints[_structureAddress][i].structureTokenId = _blueprints[i].structureTokenId;
      blueprints[_structureAddress][i].collectibleTokenId = _blueprints[i].collectibleTokenId;
      blueprints[_structureAddress][i].collectibleCost = _blueprints[i].collectibleCost;
      collectibleCosts[_structureAddress][blueprints[_structureAddress][i].structureTokenId][
        blueprints[_structureAddress][i].collectibleTokenId
      ] = _blueprints[i].collectibleCost;
    }
  }

  function updateAction(address _structureAddress, uint _actionId) external onlyAdmin {
    actionIds[_structureAddress] = _actionId;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library ArrayUtils {
  function toMemoryArray(uint _value, uint _length) internal pure returns (uint[] memory result) {
    result = new uint[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _value;
    }
  }

  function toMemoryArray(uint[] calldata _value) internal pure returns (uint[] memory result) {
    result = new uint[](_value.length);
    for (uint i = 0; i < _value.length; i++) {
      result[i] = _value[i];
    }
  }

  function toMemoryArray(
    address _address,
    uint _length
  ) internal pure returns (address[] memory result) {
    result = new address[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _address;
    }
  }

  function toMemoryArray(
    address[] calldata _addresses
  ) internal pure returns (address[] memory result) {
    result = new address[](_addresses.length);
    for (uint i = 0; i < _addresses.length; i++) {
      result[i] = _addresses[i];
    }
  }
}