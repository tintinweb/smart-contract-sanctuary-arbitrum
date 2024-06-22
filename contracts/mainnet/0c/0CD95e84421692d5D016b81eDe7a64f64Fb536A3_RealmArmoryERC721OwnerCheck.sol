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

interface IBrokenTokenHandler {
  function handleBrokenToken(
    address _breakerContract,
    address _ownerAddress,
    uint _ownerTokenId,
    address _brokenEntityAddress,
    uint _brokenEntityTokenId,
    uint _brokenAmount
  ) external;

  function handleBrokenTokenBatch(
    address _breakerContract,
    address _ownerAddress,
    uint _ownerTokenId,
    address _brokenEntityAddress,
    uint[] calldata _brokenEntityTokenIds,
    uint[] calldata _brokenAmounts
  ) external;

  function handleBrokenTokenBatch(
    address _breakerContract,
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _brokenEntityAddress,
    uint[][] calldata _brokenEntityTokenIds,
    uint[][] calldata _brokenAmounts
  ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Manager/ManagerModifier.sol";
import "../Utils/ArrayUtils.sol";
import "./IArmoryEntityStorageAdapter.sol";
import "./ArmoryConstants.sol";
import "./IArmory.sol";

contract Armory is IArmory, ReentrancyGuard, Pausable, ManagerModifier {
  //=======================================
  // Mappings
  //=======================================
  mapping(address => IArmoryEntityStorageAdapter) public adapters;
  mapping(address => uint) public entityTypes; // gas efficiency
  mapping(address => uint) public adapterListIndex;
  address[] public entityList;
  uint public enabledEntitiesCount;

  //=======================================
  // Events
  //=======================================

  // Batch events (as this is the most common usage)

  event Staked(
    address staker,
    uint tokenType,
    address ownerAddress,
    uint256 ownerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  event Unstaked(
    address staker,
    uint tokenType,
    address ownerAddress,
    uint256 ownerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  event Burned(
    uint tokenType,
    address ownerAddress,
    uint256 ownerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  event Minted(
    uint tokenType,
    address ownerAddress,
    uint256 ownerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) ManagerModifier(_manager) {}

  //=======================================
  // External
  //=======================================

  function stake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    bytes32[] calldata _proof,
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyManager nonReentrant whenNotPaused {
    adapters[_entityAddress].stake(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _proof,
      _entityAddress,
      _entityId,
      _entityAmount
    );

    emit Staked(
      _staker,
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      ArrayUtils.toMemoryArray(_entityId, 1),
      ArrayUtils.toMemoryArray(_entityAmount, 1)
    );
  }

  function stakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _stakeBatchInternal(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _proof,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _stakeBatchInternal(
      _staker,
      _ownerAddresses,
      _ownerTokenIds,
      _proofs,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function stakeBatchMulti(
    MultiStakeRequest calldata _request
  ) external onlyManager nonReentrant whenNotPaused {
    for (uint i = 0; i < _request._entityAddresses.length; i++) {
      _stakeBatchInternal(
        _request._staker,
        _request._ownerAddresses,
        _request._ownerTokenIds,
        _request._proofs,
        _request._entityAddresses[i],
        _request._entityIds[i],
        _request._entityAmounts[i]
      );
    }
  }

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyManager nonReentrant whenNotPaused {
    adapters[_entityAddress].unstake(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _proof,
      _entityAddress,
      _entityId,
      _entityAmount
    );

    emit Unstaked(
      _staker,
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      ArrayUtils.toMemoryArray(_entityId, 1),
      ArrayUtils.toMemoryArray(_entityAmount, 1)
    );
  }

  function unstakeBatch(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _unstakeBatchInternal(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _proof,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _unstakeBatchInternal(
      _staker,
      _ownerAddresses,
      _ownerTokenIds,
      _proofs,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function unstakeBatchMulti(
    MultiStakeRequest calldata _request
  ) external onlyManager nonReentrant whenNotPaused {
    for (uint i = 0; i < _request._entityAddresses.length; i++) {
      _unstakeBatchInternal(
        _request._staker,
        _request._ownerAddresses,
        _request._ownerTokenIds,
        _request._proofs,
        _request._entityAddresses[i],
        _request._entityIds[i],
        _request._entityAmounts[i]
      );
    }
  }

  function burn(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyManager nonReentrant whenNotPaused {
    adapters[_entityAddress].burn(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityId,
      _entityAmount
    );

    emit Burned(
      adapters[_entityAddress].entityType(),
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      ArrayUtils.toMemoryArray(_entityId, 1),
      ArrayUtils.toMemoryArray(_entityAmount, 1)
    );
  }

  function burnBatch(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _burnBatchInternal(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function burnBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _burnBatchInternal(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function burnBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds,
    uint256[][][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    require(
      _entityAddresses.length == _entityIds.length &&
        _entityAddresses.length == _entityAmounts.length
    );
    for (uint256 i = 0; i < _entityAddresses.length; i++) {
      _burnBatchInternal(
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddresses[i],
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function mint(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyMinter nonReentrant whenNotPaused {
    adapters[_entityAddress].mint(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityId,
      _entityAmount
    );

    emit Minted(
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      ArrayUtils.toMemoryArray(_entityId, 1),
      ArrayUtils.toMemoryArray(_entityAmount, 1)
    );
  }

  function mintBatch(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyMinter nonReentrant whenNotPaused {
    _mintBatchInternal(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyMinter nonReentrant whenNotPaused {
    _mintBatchInternal(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function checkMinimumAmounts(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external view whenNotPaused {
    adapters[_entityAddress].batchCheckAmounts(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function checkMinimumAmounts(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256 _entityAmount
  ) external view whenNotPaused {
    adapters[_entityAddress].batchCheckAmounts(
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmount
    );
  }

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external view whenNotPaused {
    for (uint256 j = 0; j < _ownerTokenIds.length; j++) {
      adapters[_entityAddress].batchCheckAmounts(
        _ownerAddresses[j],
        _ownerTokenIds[j],
        _entityAddress,
        _entityIds[j],
        _entityAmounts[j]
      );
    }
  }

  function checkMinimumAmountsBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256 _entityAmounts
  ) external view whenNotPaused {
    for (uint256 j = 0; j < _ownerTokenIds.length; j++) {
      adapters[_entityAddress].batchCheckAmounts(
        _ownerAddresses[j],
        _ownerTokenIds[j],
        _entityAddress,
        _entityIds[j],
        _entityAmounts
      );
    }
  }

  function balanceOf(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityTokenId
  ) external view returns (uint) {
    return
      adapters[_entityAddress].balanceOf(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityTokenId
      );
  }

  function balanceOfBatch(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint[] memory _entityTokenIds
  ) external view returns (uint[] memory) {
    return
      adapters[_entityAddress].balanceOfBatch(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityTokenIds
      );
  }

  function totalEntityCount() external view returns (uint) {
    return entityList.length;
  }

  function enabledEntities() external view returns (address[] memory) {
    address[] memory result = new address[](enabledEntitiesCount);
    uint enabledEntityIndex = 0;
    for (uint i = 0; i < entityList.length; i++) {
      address entity = entityList[i];
      if (entityTypes[entity] != ARMORY_ENTITY_DISABLED) {
        result[enabledEntityIndex++] = address(adapters[entity]);
      }
    }
    return result;
  }

  //=======================================
  // Internals
  //=======================================

  function _stakeBatchInternal(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) internal {
    if (_entityIds.length == 0) {
      return;
    }

    adapters[_entityAddress].stakeBatch(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    emit Staked(
      _staker,
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function _stakeBatchInternal(
    address _staker,
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) internal {
    require(
      _ownerAddress.length == _ownerId.length &&
        _ownerAddress.length == _entityIds.length &&
        _ownerAddress.length == _entityAmounts.length
    );

    adapters[_entityAddress].stakeBatch(
      _staker,
      _ownerAddress,
      _ownerId,
      _proofs,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    uint entityType = entityTypes[_entityAddress];
    for (uint i = 0; i < _ownerAddress.length; i++) {
      emit Staked(
        _staker,
        entityType,
        _ownerAddress[i],
        _ownerId[i],
        _entityAddress,
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function _unstakeBatchInternal(
    address _staker,
    address _ownerAddress,
    uint256 _ownerId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) internal {
    if (_entityIds.length == 0) {
      return;
    }

    adapters[_entityAddress].unstakeBatch(
      _staker,
      _ownerAddress,
      _ownerId,
      _proof,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    emit Unstaked(
      _staker,
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function _unstakeBatchInternal(
    address _staker,
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    bytes32[][] calldata _proofs,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) internal {
    require(
      _ownerAddress.length == _ownerId.length &&
        _ownerAddress.length == _entityIds.length &&
        _ownerAddress.length == _entityAmounts.length
    );

    adapters[_entityAddress].unstakeBatch(
      _staker,
      _ownerAddress,
      _ownerId,
      _proofs,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    uint entityType = entityTypes[_entityAddress];
    for (uint i = 0; i < _ownerAddress.length; i++) {
      emit Unstaked(
        _staker,
        entityType,
        _ownerAddress[i],
        _ownerId[i],
        _entityAddress,
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function _mintBatchInternal(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) internal {
    if (_entityIds.length == 0) {
      return;
    }

    adapters[_entityAddress].mintBatch(
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    emit Minted(
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function _mintBatchInternal(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) internal {
    require(
      _ownerAddress.length == _ownerId.length &&
        _ownerAddress.length == _entityIds.length &&
        _ownerAddress.length == _entityAmounts.length
    );

    adapters[_entityAddress].mintBatch(
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    uint entityType = entityTypes[_entityAddress];
    for (uint i = 0; i < _ownerAddress.length; i++) {
      emit Minted(
        entityType,
        _ownerAddress[i],
        _ownerId[i],
        _entityAddress,
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function _burnBatchInternal(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) internal {
    if (_entityIds.length == 0) {
      return;
    }

    adapters[_entityAddress].burnBatch(
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    emit Burned(
      entityTypes[_entityAddress],
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function _burnBatchInternal(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) internal {
    require(
      _ownerAddress.length == _ownerId.length &&
        _ownerAddress.length == _entityIds.length &&
        _ownerAddress.length == _entityAmounts.length
    );

    adapters[_entityAddress].burnBatch(
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );

    uint entityType = entityTypes[_entityAddress];
    for (uint i = 0; i < _ownerAddress.length; i++) {
      emit Burned(
        entityType,
        _ownerAddress[i],
        _ownerId[i],
        _entityAddress,
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  //=======================================
  // Admin
  //=======================================
  function enableEntity(
    address _entity,
    address _adapter
  ) public virtual onlyAdmin {
    require(
      address(adapters[_entity]) == address(0),
      "Collection already enabled"
    );
    adapters[_entity] = IArmoryEntityStorageAdapter(_adapter);
    if (adapterListIndex[_entity] == 0) {
      adapterListIndex[_entity] = entityList.length;
      entityList.push(_entity);
    }
    entityTypes[_entity] = adapters[_entity].entityType();
    enabledEntitiesCount++;
  }

  function disableEntity(address _entity) public virtual onlyAdmin {
    require(
      address(adapters[_entity]) != address(0),
      "Collection already disabled"
    );
    adapters[_entity] = IArmoryEntityStorageAdapter(address(0));
    entityTypes[_entity] = ARMORY_ENTITY_DISABLED;
    enabledEntitiesCount--;
  }

  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

uint constant ARMORY_ENTITY_DISABLED = 0;
uint constant ARMORY_ENTITY_ERC20 = 1;
uint constant ARMORY_ENTITY_ERC721 = 2;
uint constant ARMORY_ENTITY_ERC1155 = 3;
uint constant ARMORY_ENTITY_DATA = 4;

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./Armory.sol";
import "./IDurabilityEnabledArmory.sol";
import "./IDurabilityEnabledAdapter.sol";

contract DurabilityEnabledArmory is Armory, IDurabilityEnabledArmory {
  error DurabilityNotSupported(address _address);

  constructor(address _manager) Armory(_manager) {}

  // durability support, ownedEntity => support
  mapping(address => bool) public durabilitySupport;

  struct ProcessingMemory {
    address _ownerAddress;
    uint _ownerTokenId;
    address _entityAddress;
    uint _entityTokenId;
    uint durabilityLoss;
  }

  function currentDurability(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) public view returns (uint) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurability(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityId
      );
  }

  function currentDurabilityBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds
  ) public view returns (uint[] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityBatch(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityIds
      );
  }

  function currentDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityBatch(
        _ownerAddresses,
        _ownerIds,
        _entityAddress,
        _entityIds
      );
  }

  function currentDurabilityBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory result) {
    result = new uint[][][](_entityAddresses.length);
    for (uint i = 0; i < _entityAddresses.length; i++) {
      result[i] = _getDurabilityAdapter(_entityAddresses[i])
        .currentDurabilityBatch(
          _ownerAddresses,
          _ownerIds,
          _entityAddresses[i],
          _entityIds[i]
        );
    }
  }

  function currentDurabilityPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityPercentage(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityId
      );
  }

  function currentDurabilityPercentageBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds
  ) public view returns (uint[] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityBatchPercentage(
        _ownerAddress,
        _ownerId,
        _entityAddress,
        _entityIds
      );
  }

  function currentDurabilityPercentageBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityBatchPercentage(
        _ownerAddresses,
        _ownerIds,
        _entityAddress,
        _entityIds
      );
  }

  function currentDurabilityPercentageBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory result) {
    result = new uint[][][](_entityAddresses.length);
    for (uint i = 0; i < _entityAddresses.length; i++) {
      result[i] = _getDurabilityAdapter(_entityAddresses[i])
        .currentDurabilityBatchPercentage(
          _ownerAddresses,
          _ownerIds,
          _entityAddresses[i],
          _entityIds[i]
        );
    }
  }

  function reduceDurability(
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId,
    uint durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) public whenNotPaused onlyManager {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    uint brokenAmount = adapter.reduceDurability(
      msg.sender,
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityTokenId,
      durabilityLoss,
      _startNewTokenIfNeeded,
      _ignoreAvailability
    );

    if (brokenAmount > 0) {
      emit Burned(
        IArmoryEntityStorageAdapter(address(adapter)).entityType(),
        _ownerAddress,
        _ownerTokenId,
        _entityAddress,
        ArrayUtils.toMemoryArray(_entityTokenId, 1),
        ArrayUtils.toMemoryArray(brokenAmount, 1)
      );
    }
  }

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external whenNotPaused onlyManager {
    _reduceDurabilityBatchInternal(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      _durabilityLoss,
      _startNewTokenIfNeeded,
      _ignoreAvailability
    );
  }

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external whenNotPaused onlyManager {
    _reduceDurabilityBatchInternal(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      _durabilityLosses,
      _startNewTokenIfNeeded,
      _ignoreAvailability
    );
  }

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint[][][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external whenNotPaused onlyManager {
    for (uint i = 0; i < _entityAddresses.length; i++) {
      _reduceDurabilityBatchInternal(
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddresses[i],
        _entityTokenIds[i],
        _durabilityLoss,
        _startNewTokenIfNeeded,
        _ignoreAvailability
      );
    }
  }

  function reduceDurabilityMultiBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint[][][] calldata _entityTokenIds,
    uint[][][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external whenNotPaused onlyManager {
    for (uint i = 0; i < _entityAddresses.length; i++) {
      _reduceDurabilityBatchInternal(
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddresses[i],
        _entityTokenIds[i],
        _durabilityLosses[i],
        _startNewTokenIfNeeded,
        _ignoreAvailability
      );
    }
  }

  function _reduceDurabilityBatchInternal(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) internal returns (bool anyBroken, uint[][] memory brokenAmounts) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    (anyBroken, brokenAmounts) = adapter.reduceDurabilityBatch(
      msg.sender,
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      _durabilityLoss,
      _startNewTokenIfNeeded,
      _ignoreAvailability
    );

    _emitBurnEvents(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      brokenAmounts,
      anyBroken
    );
  }

  function _reduceDurabilityBatchInternal(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) internal returns (bool anyBroken, uint[][] memory brokenAmounts) {
    (anyBroken, brokenAmounts) = _getDurabilityAdapter(_entityAddress)
      .reduceDurabilityBatch(
        msg.sender,
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddress,
        _entityTokenIds,
        _durabilityLosses,
        _startNewTokenIfNeeded,
        _ignoreAvailability
      );

    _emitBurnEvents(
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      brokenAmounts,
      anyBroken
    );
  }

  function _emitBurnEvents(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] memory _brokenAmounts,
    bool anyBroken
  ) internal {
    if (!anyBroken) {
      return;
    }
    for (uint i = 0; i < _ownerAddresses.length; i++) {
      emit Burned(
        adapters[_entityAddress].entityType(),
        _ownerAddresses[i],
        _ownerTokenIds[i],
        _entityAddress,
        _entityTokenIds[i],
        _brokenAmounts[i]
      );
    }
  }

  function enableEntity(
    address _entity,
    address _adapter
  ) public override onlyAdmin {
    super.enableEntity(_entity, _adapter);
    durabilitySupport[_entity] = true;
  }

  function disableEntity(address _entity) public override onlyAdmin {
    super.disableEntity(_entity);
    durabilitySupport[_entity] = false;
  }

  function forceChangeDurabilitySupport(
    address _entity,
    bool _durabilitySupport
  ) external onlyAdmin {
    durabilitySupport[_entity] = _durabilitySupport;
  }

  function _getDurabilityAdapter(
    address _entityAddress
  ) internal view returns (IDurabilityEnabledAdapter) {
    if (!durabilitySupport[_entityAddress]) {
      revert DurabilityNotSupported(_entityAddress);
    }
    return IDurabilityEnabledAdapter(address(adapters[_entityAddress]));
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
  function adapters(
    address _entityAddress
  ) external view returns (IArmoryEntityStorageAdapter);

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

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    bytes32[] calldata _proof,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external;

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
  error AlreadyStaked(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint _entityId,
    uint _tokenAmounts
  );
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

import "./IArmoryEntityStorageAdapter.sol";

interface IArmoryERC721Adapter is IArmoryEntityStorageAdapter {
  function ownerOf(
    address _entityAddress,
    uint _entityId
  ) external view returns (bool, address, uint);

  function ownerOfBatch(
    address _entityAddress,
    uint[] calldata _entityIds
  )
    external
    view
    returns (
      bool[] memory areStaked,
      address[] memory ownerAddresses,
      uint[] memory ownerIds
    );

  function ownerOfBatch(
    address _entityAddress,
    uint[][] calldata _entityIds
  )
    external
    view
    returns (
      bool[][] memory areStaked,
      address[][] memory ownerAddresses,
      uint[][] memory ownerIds
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Armory/DurabilityEnabledArmory.sol";

interface IArmoryERC721OwnerCheck {
  function ownerOf(
    address _entityAddress,
    uint256 _entityId
  )
    external
    view
    returns (bool isOwned, address _ownerAddress, uint256 _ownerTokenId);

  function ownerOfBatch(
    address _entityAddress,
    uint256[] calldata _entityIds
  )
    external
    view
    returns (
      bool[] memory areOwned,
      address[] memory ownerAddresses,
      uint[] memory ownerIds
    );
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";
import "../AdventurerEquipment/IBrokenEquipmentHandler.sol";
import "./IArmoryEntityStorageAdapter.sol";

interface IDurabilityEnabledAdapter {
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
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityId
  ) external view returns (uint[][] memory);

  function currentDurabilityPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256 _entityId
  ) external view returns (uint);

  function currentDurabilityBatchPercentage(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityId
  ) external view returns (uint[] memory);

  function currentDurabilityBatchPercentage(
    address[] calldata _ownerAddress,
    uint256[] calldata _ownerId,
    address _entityAddress,
    uint256[][] calldata _entityId
  ) external view returns (uint[][] memory);

  function reduceDurability(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenId,
    address _entityAddress,
    uint _entityTokenId,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (uint);

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (bool, uint[] memory);

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint[] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (bool, uint[] memory);

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddress,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (bool, uint[][] memory);

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddress,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external returns (bool, uint[][] memory);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import { IArmory } from "./IArmory.sol";

interface IDurabilityEnabledArmory is IArmory {
  function durabilitySupport(
    address _entityAddress
  ) external view returns (bool);

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

import "./IArmory.sol";
import "./IArmoryERC721Adapter.sol";
import { IArmoryERC721OwnerCheck } from "./IArmoryERC721OwnerCheck.sol";

contract RealmArmoryERC721OwnerCheck is IArmoryERC721OwnerCheck {
  IArmory public ARMORY;

  constructor(address _armory) {
    ARMORY = IArmory(_armory);
  }

  function ownerOf(
    address _entityAddress,
    uint256 _entityId
  )
    external
    view
    returns (bool isOwned, address _ownerAddress, uint256 _ownerTokenId)
  {
    return _adapter(_entityAddress).ownerOf(_entityAddress, _entityId);
  }

  function ownerOfBatch(
    address _entityAddress,
    uint256[] calldata _entityIds
  )
    external
    view
    returns (
      bool[] memory areOwned,
      address[] memory ownerAddresses,
      uint[] memory ownerIds
    )
  {
    return _adapter(_entityAddress).ownerOfBatch(_entityAddress, _entityIds);
  }

  function ownerOfBatch(
    address _entityAddress,
    uint256[][] calldata _entityIds
  )
    external
    view
    returns (
      bool[][] memory areOwned,
      address[][] memory ownerAddresses,
      uint[][] memory ownerIds
    )
  {
    return _adapter(_entityAddress).ownerOfBatch(_entityAddress, _entityIds);
  }

  function _adapter(
    address _entityAddress
  ) internal view returns (IArmoryERC721Adapter) {
    return IArmoryERC721Adapter(address(ARMORY.adapters(_entityAddress)));
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

  modifier onlyTokenEmitter() {
    require(MANAGER.isManager(msg.sender, 6), "Manager: Not token emitter");
    _;
  }

  modifier onlyPauser() {
    require(
      MANAGER.isAdmin(msg.sender) || MANAGER.isManager(msg.sender, 6),
      "Manager: Not pauser"
    );
    _;
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

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4,
    uint _l5
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
    ensureSameLength(_l1, _l5);
  }

  function checkAddressesForDuplicates(
    address[] memory _tokenAddrs
  ) internal pure {
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

  function checkForDuplicates(
    address[] memory _tokenAddrs,
    uint[] memory _tokenIds
  ) internal pure {
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

  function toSingleValueDoubleArray(
    uint[] memory _vals
  ) internal pure returns (uint[][] memory result) {
    result = new uint[][](_vals.length);
    for (uint i = 0; i < _vals.length; i++) {
      result[i] = ArrayUtils.toMemoryArray(_vals[i], 1);
    }
  }

  function toMemoryArray(
    uint _value,
    uint _length
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _value;
    }
  }

  function toMemoryArray(
    uint[] calldata _value
  ) internal pure returns (uint[] memory result) {
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