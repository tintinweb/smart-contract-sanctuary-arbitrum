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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Manager/ManagerModifier.sol";
import "./IArmoryEntityStorageAdapter.sol";

struct MultiStakeRequest {
  address _staker;
  address[] _ownerAddresses;
  uint256[] _ownerTokenIds;
  bytes32[][] _proofs;
  address[] _entityAddresses;
  uint256[][][] _entityIds;
  uint256[][][] _entityAmounts;
}

interface IArmory {
  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    bytes32[] calldata _proof,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

  function stakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function stakeBatchMulti(MultiStakeRequest calldata _request) external;

  function unstakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external;

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external;

  function unstakeBatchMulti(MultiStakeRequest calldata _request) external;

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

// SPDX-License-Identifier: Unlicensed

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
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external;

  function stakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    bytes32[] calldata _proof,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    bytes32[][] calldata _proofs,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[][] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[][] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityTokenId,
    uint256 _entityAmount
  ) external;

  function unstakeBatch(
    address _staker,
    address _ownerAddresses,
    uint256 _ownerIds,
    bytes32[] calldata _proof,
    address _entityAddress, // only used for ERC-20, ERC-721, ERC-1155
    uint256[] calldata _entityTokenIds, // only used for ERC-721, ERC-1155
    uint256[] calldata _entityAmounts // only used for ERC-20, ERC-1155
  ) external;

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    bytes32[][] calldata _proofs,
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import { IArmory } from "./IArmory.sol";

interface IDurabilityEnabledArmory is IArmory {
  function currentDurability(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory);

  function currentDurabilityBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddress,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory);

  function currentDurabilityPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityPercentageBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityPercentageBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory);

  function currentDurabilityPercentageBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddress,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory);

  function reduceDurability(
    address _ownerAddress,
    uint _ownerTokenId,
    address _ownedTokenAddress,
    uint _ownedTokenId,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _ownedTokenAddress,
    uint[][] calldata _ownedTokenIds,
    uint durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _ownedTokenAddresses,
    uint[][][] calldata _ownedTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint[][][] calldata _entityTokenIds,
    uint[][][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
uint256 constant ROUNDING_ADJUSTER = DECIMAL_POINT - 1;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library MathHelpers {
  function divideRoundedUp(
    uint256 _a,
    uint256 _b
  ) internal pure returns (uint256) {
    return (_a + _b - 1) / _b;
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

  modifier onlyConfigManager() {
    require(MANAGER.isManager(msg.sender, 4), "Manager: Not config manager");
    _;
  }

  modifier onlyTokenSpender() {
    require(MANAGER.isManager(msg.sender, 5), "Manager: Not token spender");
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomPicker {
  struct TicketPool {
    uint32 currentLength;
    TicketPoolPosition[] tickets;
  }

  struct TicketPoolPosition {
    uint16 ownerId;
    uint32 ownerPoolIndex;
  }

  struct OwnerTickets {
    uint32 currentLength;
    uint32[] positions;
  }

  function pools(
    uint256 poolType,
    uint256 subPoolId
  ) external view returns (TicketPool memory);

  function ownedTickets(
    uint256 poolType,
    uint256 subPoolId,
    uint16 ownerId
  ) external view returns (OwnerTickets memory);

  function addToPool(
    uint256 poolType,
    uint256 subPool,
    uint256 owner,
    uint256 number
  ) external;

  function addToPoolBatch(
    uint256 poolType,
    uint256 subPool,
    uint256[] calldata _ownerIds,
    uint256[] calldata _numbers
  ) external;

  function addToPoolBatch2(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256 owner,
    uint256[] calldata numbers
  ) external;

  function addToPoolBatch3(
    uint256 poolType,
    uint256[][] calldata subPools,
    uint256[] calldata owners,
    uint256[][] calldata numbers
  ) external;

  function addToPoolBatch4(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256[][] calldata owners,
    uint256[][] calldata numbers
  ) external;

  function removeFromPool(
    uint256 poolType,
    uint256 subPool,
    uint256 owner,
    uint256 number
  ) external;

  function removeFromPoolBatch(
    uint256 poolType,
    uint256 subPool,
    uint256[] calldata owner,
    uint256[] calldata number
  ) external;

  function removeFromPoolBatch2(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256 owner,
    uint256[] calldata numbers
  ) external;

  function removeFromPoolBatch3(
    uint256 poolType,
    uint256[][] calldata subPools,
    uint256[] calldata owners,
    uint256[][] calldata numbers
  ) external;

  function removeFromPoolBatch4(
    uint256 poolType,
    uint256[] calldata subPools,
    uint256[][] calldata owners,
    uint256[][] calldata numbers
  ) external;

  function useRandomizer(
    uint256 poolType,
    uint256 subPool,
    uint256 number,
    uint256 randomBase
  ) external view returns (uint[] memory result, uint newRandomBase);

  function useRandomizerBatch(
    uint256 poolType,
    uint256[] calldata subPool,
    uint256[] calldata number,
    uint256 randomBase
  ) external view returns (uint[][] memory result, uint newRandomBase);

  function getPoolSizes(
    uint256 poolType,
    uint256[] calldata subPools
  ) external view returns (uint256[] memory result);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomStructureBurner {
  function availableUsageCounts(
    address _structureAddress,
    uint[] calldata _structureIds,
    uint[] calldata _lossPerUsage
  ) external view returns (uint[] memory);

  function randomReduceDurability(
    uint _randomBase,
    address _structureAddress,
    uint[] calldata _structureIds,
    uint[] calldata _durabilityLoss,
    uint[] calldata _amounts,
    address _durabilityLossHandler
  ) external returns (uint nextRandomBase);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomStructureBurnerDurabilityLossHandler {
  function handleDurabilityLoss(
    uint[] calldata realmIds,
    uint[][] calldata structureIds,
    uint[][] calldata durabilityLoss
  ) external;

  function handleDurabilityLoss(
    uint realmId,
    uint structureId,
    uint durabilityLoss
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRandomStructureBurnerStorage {
  function getPartialBurn(
    address _structureAddress,
    uint _structureId
  ) external view returns (uint);

  function getPartialBurns(
    address _structureAddress,
    uint[] calldata _structureIds
  ) external view returns (uint[] memory);

  function setPartialBurn(
    address _structureAddress,
    uint _structureId,
    uint _loss
  ) external;

  function addPartialBurn(
    address _structureAddress,
    uint _structureId,
    uint _delta
  ) external;

  function subtractPartialBurn(
    address _structureAddress,
    uint _structureId,
    uint _delta
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "./IRandomStructureBurner.sol";
import "./IRandomStructureBurnerDurabilityLossHandler.sol";
import "../Utils/Random.sol";
import "../Utils/ArrayUtils.sol";
import "../lib/FloatingPointConstants.sol";
import "../RandomPicker/IRandomPicker.sol";
import "../Armory/IDurabilityEnabledArmory.sol";
import "../lib/MathHelpers.sol";
import "./IRandomStructureBurnerStorage.sol";

uint constant HALF_DURABILITY = 50000;

error InvalidRequestLossValue(
  address structureAddress,
  uint structureId,
  uint loss
);
error InsufficientStructures(address structureAddress, uint structureId);

contract RandomStructureBurner is ManagerModifier, IRandomStructureBurner {
  using Random for uint256;
  using MathHelpers for uint256;

  IRandomPicker private immutable RANDOM_PICKER;
  IDurabilityEnabledArmory private immutable REALM_ARMORY;
  IRandomStructureBurnerStorage private immutable STORAGE;
  address private immutable REALM;

  constructor(
    address _manager,
    address _randomPicker,
    address _realmArmory,
    address _realm,
    address _randomStructureBurnerStorage
  ) ManagerModifier(_manager) {
    RANDOM_PICKER = IRandomPicker(_randomPicker);
    REALM_ARMORY = IDurabilityEnabledArmory(_realmArmory);
    REALM = _realm;
    STORAGE = IRandomStructureBurnerStorage(_randomStructureBurnerStorage);
  }

  function availableUsageCounts(
    address _structureAddress,
    uint[] calldata _structureIds,
    uint[] calldata _lossPerUsage
  ) external view returns (uint[] memory) {
    uint256[] memory poolSizes = RANDOM_PICKER.getPoolSizes(
      uint(uint160(_structureAddress)),
      _structureIds
    );

    uint[] memory partialLosses = STORAGE.getPartialBurns(
      _structureAddress,
      _structureIds
    );
    uint[] memory result = new uint[](_structureIds.length);
    for (uint i = 0; i < _structureIds.length; i++) {
      if (poolSizes[i] == 0) {
        result[i] = 0;
      } else {
        result[i] = _calculateCapacity(
          poolSizes[i],
          _lossPerUsage[i],
          partialLosses[i]
        );
      }
    }

    return result;
  }

  function randomReduceDurability(
    uint _randomBase,
    address _structureAddress,
    uint[] calldata _structureIds,
    uint[] calldata _lossPerUsage,
    uint[] calldata _usages,
    address _durabilityLossHandler
  ) external onlyManager returns (uint) {
    _ensurePoolSizesHaveEnoughCapacity(
      _structureAddress,
      _structureIds,
      _lossPerUsage,
      _usages
    );

    for (uint i = 0; i < _structureIds.length; i++) {
      _randomBase = _reduceDurability(
        _randomBase,
        _structureAddress,
        _structureIds[i],
        _lossPerUsage[i],
        _usages[i],
        _durabilityLossHandler
      );
    }

    return _randomBase;
  }

  struct ReduceDurabilityMem {
    uint batchLoss;
    int batchRemainderChange;
    int remainderChange;
    uint lossLeft;
    uint usagesLeft;
    uint maxUsagesPerStructure;
    uint batchSize;
    uint maxLossPerRealm;
    uint[] realmIds;
  }

  // Instead of randomizing for each crafting attempt, we'll
  // batch them to take half of the structure's durability at a time instead,
  function _reduceDurability(
    uint _randomBase,
    address _structureAddress,
    uint _structureId,
    uint _lossPerUsage,
    uint _usages,
    address _durabilityLossHandler
  ) internal returns (uint) {
    if (_usages <= 0) {
      return _randomBase;
    }

    ReduceDurabilityMem memory mem;

    mem.usagesLeft = _usages;
    mem.lossLeft = mem.usagesLeft * _lossPerUsage;

    // Calculate how many times each structure can be used in a single batch
    mem.maxUsagesPerStructure = HALF_DURABILITY.divideRoundedUp(_lossPerUsage);

    // Calculate batch sizes
    do {
      mem.usagesLeft = mem.lossLeft.divideRoundedUp(_lossPerUsage);
      mem.batchSize =
        1 +
        mem.usagesLeft.divideRoundedUp(mem.maxUsagesPerStructure);

      uint[] memory realmIds;
      if (
        RANDOM_PICKER
          .pools(uint(uint160(_structureAddress)), _structureId)
          .currentLength == 0
      ) {
        break;
      }

      (realmIds, _randomBase) = RANDOM_PICKER.useRandomizer(
        uint(uint160(_structureAddress)),
        _structureId,
        mem.batchSize,
        _randomBase
      );

      (mem.batchLoss, mem.batchRemainderChange) = _batchReduceDurability(
        _structureAddress,
        _structureId,
        mem.lossLeft,
        realmIds,
        _durabilityLossHandler
      );

      mem.remainderChange += mem.batchRemainderChange;

      if (mem.batchLoss >= mem.lossLeft) {
        mem.batchLoss = mem.lossLeft;
      }

      mem.lossLeft -= mem.batchLoss;
    } while (mem.lossLeft > 0 && mem.batchLoss > 0);

    // Once all structures are burnt, we reset the partial burn to 0
    if (
      mem.lossLeft > 0 &&
      RANDOM_PICKER
        .pools(uint(uint160(_structureAddress)), _structureId)
        .currentLength ==
      0
    ) {
      STORAGE.setPartialBurn(_structureAddress, _structureId, 0);
    } else if (mem.remainderChange > 0) {
      STORAGE.addPartialBurn(
        _structureAddress,
        _structureId,
        uint(mem.remainderChange)
      );
    } else if (mem.remainderChange < 0) {
      STORAGE.subtractPartialBurn(
        _structureAddress,
        _structureId,
        uint(-mem.remainderChange)
      );
    }

    return _randomBase;
  }

  function _batchReduceDurability(
    address _structureAddress,
    uint _structureId,
    uint _totalLoss,
    uint[] memory _realmIds,
    address _durabilityLossHandler
  ) internal returns (uint, int lossRemainderChange) {
    uint remainingLoss = _totalLoss;
    for (uint i = 0; i < _realmIds.length; i++) {
      uint remainingDurability = REALM_ARMORY.currentDurabilityPercentage(
        REALM,
        _realmIds[i],
        _structureAddress,
        _structureId
      );
      if (remainingDurability == 0) {
        continue;
      }

      uint structureLoss = remainingLoss > HALF_DURABILITY
        ? HALF_DURABILITY
        : remainingLoss;

      if (structureLoss >= remainingDurability) {
        structureLoss = remainingDurability;
        lossRemainderChange -= SIGNED_ONE_HUNDRED; // We're burning the rest of the structure
      }

      lossRemainderChange += int(structureLoss);
      remainingLoss -= structureLoss;

      REALM_ARMORY.reduceDurability(
        REALM,
        _realmIds[i],
        _structureAddress,
        _structureId,
        structureLoss,
        true,
        true
      );

      if (structureLoss > 0 && _durabilityLossHandler != address(0)) {
        IRandomStructureBurnerDurabilityLossHandler(_durabilityLossHandler)
          .handleDurabilityLoss(_realmIds[i], _structureId, structureLoss);
      }

      if (remainingLoss <= 0) {
        break;
      }
    }

    return (_totalLoss - remainingLoss, lossRemainderChange);
  }

  function _calculateCapacity(
    uint _poolSize,
    uint _lossPerUse,
    uint _partialBurnsTotal
  ) internal pure returns (uint) {
    uint totalRemainingDurability = (ONE_HUNDRED * _poolSize) -
      _partialBurnsTotal;
    return totalRemainingDurability.divideRoundedUp(_lossPerUse);
  }

  function _ensurePoolSizesHaveEnoughCapacity(
    address _structureAddress,
    uint[] calldata _structureIds,
    uint[] calldata _durabilityLoss,
    uint[] calldata _amounts
  ) internal view {
    uint256[] memory poolSizes = RANDOM_PICKER.getPoolSizes(
      uint(uint160(_structureAddress)),
      _structureIds
    );
    for (uint i = 0; i < poolSizes.length; i++) {
      if (_durabilityLoss[i] < 1 || _durabilityLoss[i] > ONE_HUNDRED) {
        revert InvalidRequestLossValue(
          _structureAddress,
          _structureIds[i],
          _durabilityLoss[i]
        );
      }

      uint[] memory partialBurns = STORAGE.getPartialBurns(
        _structureAddress,
        _structureIds
      );
      if (
        _calculateCapacity(poolSizes[i], _durabilityLoss[i], partialBurns[i]) <
        _amounts[i]
      ) {
        revert InsufficientStructures(_structureAddress, _structureIds[i]);
      }
    }
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

library ArrayUtils {
  error ArrayLengthMismatch(uint _length1, uint _length2);
  error InvalidArrayOrder(uint index);

  function ensureSameLength(uint _l1, uint _l2) internal pure {
    if (_l1 != _l2) {
      revert ArrayLengthMismatch(_l1, _l2);
    }
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3, uint _l4) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3, uint _l4, uint _l5) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
    ensureSameLength(_l1, _l5);
  }

  function checkAddressesForDuplicates(address[] memory _tokenAddrs) internal pure {
    address lastAddress;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (lastAddress > _tokenAddrs[i]) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
    }
  }

  function checkForDuplicates(uint[] memory _ids) internal pure {
    uint lastId;
    for (uint i = 0; i < _ids.length; i++) {
      if (lastId > _ids[i]) {
        revert InvalidArrayOrder(i);
      }
      lastId = _ids[i];
    }
  }

  function checkForDuplicates(address[] memory _tokenAddrs, uint[] memory _tokenIds) internal pure {
    address lastAddress;
    int256 lastTokenId = -1;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (_tokenAddrs[i] > lastAddress) {
        lastTokenId = -1;
      }

      if (_tokenAddrs[i] < lastAddress || int(_tokenIds[i]) <= lastTokenId) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
      lastTokenId = int(_tokenIds[i]);
    }
  }

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

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
  /**
   * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
   * @return block number as int
   */
  function arbBlockNumber() external view returns (uint256);

  /**
   * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
   * @return block hash
   */
  function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

  /**
   * @notice Gets the rollup's unique chain identifier
   * @return Chain identifier as int
   */
  function arbChainID() external view returns (uint256);

  /**
   * @notice Get internal version number identifying an ArbOS build
   * @return version number as int
   */
  function arbOSVersion() external view returns (uint256);

  /**
   * @notice Returns 0 since Nitro has no concept of storage gas
   * @return uint 0
   */
  function getStorageGasAvailable() external view returns (uint256);

  /**
   * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
   * @dev this call has been deprecated and may be removed in a future release
   * @return true if current execution frame is not a call by another L2 contract
   */
  function isTopLevelCall() external view returns (bool);

  /**
   * @notice map L1 sender contract address to its L2 alias
   * @param sender sender address
   * @param unused argument no longer used
   * @return aliased sender address
   */
  function mapL1SenderContractAddressToL2Alias(
    address sender,
    address unused
  ) external pure returns (address);

  /**
   * @notice check if the caller (of this caller of this) is an aliased L1 contract address
   * @return true iff the caller's address is an alias for an L1 contract address
   */
  function wasMyCallersAddressAliased() external view returns (bool);

  /**
   * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
   * @return address of the caller's caller, without applying L1 contract address aliasing
   */
  function myCallersAddressWithoutAliasing() external view returns (address);

  /**
   * @notice Send given amount of Eth to dest from sender.
   * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
   * @param destination recipient address on L1
   * @return unique identifier for this L2-to-L1 transaction.
   */
  function withdrawEth(address destination) external payable returns (uint256);

  /**
   * @notice Send a transaction to L1
   * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
   * to a contract address without any code (as enforced by the Bridge contract).
   * @param destination recipient address on L1
   * @param data (optional) calldata for L1 contract call
   * @return a unique identifier for this L2-to-L1 transaction.
   */
  function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);

  /**
   * @notice Get send Merkle tree .state
   * @return size number of sends in the history
   * @return root root hash of the send history
   * @return partials hashes of partial subtrees in the send history tree
   */
  function sendMerkleTreeState()
    external
    view
    returns (uint256 size, bytes32 root, bytes32[] memory partials);

  /**
   * @notice creates a send txn from L2 to L1
   * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
   */
  event L2ToL1Tx(
    address caller,
    address indexed destination,
    uint256 indexed hash,
    uint256 indexed position,
    uint256 arbBlockNum,
    uint256 ethBlockNum,
    uint256 timestamp,
    uint256 callvalue,
    bytes data
  );

  /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
  event L2ToL1Transaction(
    address caller,
    address indexed destination,
    uint256 indexed uniqueId,
    uint256 indexed batchNumber,
    uint256 indexInBatch,
    uint256 arbBlockNum,
    uint256 ethBlockNum,
    uint256 timestamp,
    uint256 callvalue,
    bytes data
  );

  /**
   * @notice logs a merkle branch for proof synthesis
   * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
   * @param hash the merkle hash
   * @param position = (level << 192) + leaf
   */
  event SendMerkleUpdate(uint256 indexed reserved, bytes32 indexed hash, uint256 indexed position);

  error InvalidBlockNumber(uint256 requested, uint256 current);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./IArbSys.sol";

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
uint256 constant MIN_SAFE_NEXT_NUMBER_PRIME = 200033;
uint256 constant HIGH_RANGE_PRIME_OFFSET = 13;

library Random {
  function startRandomBase(uint256 _highSalt, uint256 _lowSalt) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            _getPreviousBlockhash(),
            block.timestamp,
            msg.sender,
            _lowSalt,
            _highSalt
          )
        )
      );
  }

  function getNextRandom(
    uint256 _randomBase,
    uint256 _range
  ) internal view returns (uint256, uint256) {
    uint256 nextNumberSeparator = MIN_SAFE_NEXT_NUMBER_PRIME > _range
      ? MIN_SAFE_NEXT_NUMBER_PRIME
      : (_range + HIGH_RANGE_PRIME_OFFSET);
    uint256 nextBaseNumber = _randomBase / nextNumberSeparator;
    if (nextBaseNumber > nextNumberSeparator) {
      return (_randomBase % _range, nextBaseNumber);
    }
    nextBaseNumber = uint256(
      keccak256(abi.encodePacked(_getPreviousBlockhash(), msg.sender, _randomBase, _range))
    );
    return (nextBaseNumber % _range, nextBaseNumber / nextNumberSeparator);
  }

  function _getPreviousBlockhash() internal view returns (bytes32) {
    // Arbitrum One, Nova, Goerli, Sepolia, Stylus or Rinkeby
    if (
      block.chainid == 42161 ||
      block.chainid == 42170 ||
      block.chainid == 421613 ||
      block.chainid == 421614 ||
      block.chainid == 23011913 ||
      block.chainid == 421611
    ) {
      return ArbSys(address(0x64)).arbBlockHash(ArbSys(address(0x64)).arbBlockNumber() - 1);
    } else {
      // WARNING: THIS IS HIGHLY INSECURE ON ETH MAINNET, it is currently used mostly for testing
      return blockhash(block.number - 1);
    }
  }
}