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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Armory/DurabilityEnabledArmory.sol";

contract AdventurerArmory is DurabilityEnabledArmory {
  constructor(address _manager) DurabilityEnabledArmory(_manager) {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Item/IRarityItem.sol";

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
    address adventurerAddress,
    uint256 adventurerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  event Unstaked(
    address staker,
    uint tokenType,
    address adventurerAddress,
    uint256 adventurerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  event Burned(
    uint tokenType,
    address adventurerAddress,
    uint256 adventurerId,
    address entityAddress,
    uint256[] entityIds,
    uint256[] entityAmounts
  );

  event Minted(
    uint tokenType,
    address adventurerAddress,
    uint256 adventurerId,
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
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyManager nonReentrant whenNotPaused {
    adapters[_entityAddress].stake(
      _staker,
      _ownerAddress,
      _ownerTokenId,
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
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _stakeBatchInternal(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function stakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _stakeBatchInternal(
      _staker,
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function stakeBatchMulti(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address[] calldata _entityAddresses,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    require(
      _entityAddresses.length == _entityIds.length &&
        _entityAddresses.length == _entityAmounts.length
    );
    for (uint256 i = 0; i < _entityAddresses.length; i++) {
      _stakeBatchInternal(
        _staker,
        _ownerAddress,
        _ownerTokenId,
        _entityAddresses[i],
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function stakeBatchMulti(
    address _staker,
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
      _stakeBatchInternal(
        _staker,
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddresses[i],
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function unstake(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address _entityAddress,
    uint256 _entityId,
    uint256 _entityAmount
  ) external onlyManager nonReentrant whenNotPaused {
    adapters[_entityAddress].unstake(
      _staker,
      _ownerAddress,
      _ownerTokenId,
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
    address _entityAddress,
    uint256[] calldata _entityIds,
    uint256[] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _unstakeBatchInternal(
      _staker,
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function unstakeBatch(
    address _staker,
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _unstakeBatchInternal(
      _staker,
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityIds,
      _entityAmounts
    );
  }

  function unstakeBatchMulti(
    address _staker,
    address _ownerAddress,
    uint256 _ownerTokenId,
    address[] calldata _entityAddresses,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    require(
      _entityAddresses.length == _entityIds.length &&
        _entityAddresses.length == _entityAmounts.length
    );
    for (uint256 i = 0; i < _entityAddresses.length; i++) {
      _unstakeBatchInternal(
        _staker,
        _ownerAddress,
        _ownerTokenId,
        _entityAddresses[i],
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function unstakeBatchMulti(
    address _staker,
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
      _unstakeBatchInternal(
        _staker,
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddresses[i],
        _entityIds[i],
        _entityAmounts[i]
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
    _burnBatchInternal(_ownerAddress, _ownerTokenId, _entityAddress, _entityIds, _entityAmounts);
  }

  function burnBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    _burnBatchInternal(_ownerAddresses, _ownerTokenIds, _entityAddress, _entityIds, _entityAmounts);
  }

  function burnBatchMulti(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address[] calldata _entityAddresses,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyManager nonReentrant whenNotPaused {
    require(
      _entityAddresses.length == _entityIds.length &&
        _entityAddresses.length == _entityAmounts.length
    );
    for (uint256 i = 0; i < _entityAddresses.length; i++) {
      _burnBatchInternal(
        _ownerAddress,
        _ownerTokenId,
        _entityAddresses[i],
        _entityIds[i],
        _entityAmounts[i]
      );
    }
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
    _mintBatchInternal(_ownerAddress, _ownerTokenId, _entityAddress, _entityIds, _entityAmounts);
  }

  function mintBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address _entityAddress,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyMinter nonReentrant whenNotPaused {
    _mintBatchInternal(_ownerAddresses, _ownerTokenIds, _entityAddress, _entityIds, _entityAmounts);
  }

  function mintBatchMulti(
    address _ownerAddress,
    uint256 _ownerTokenId,
    address[] calldata _entityAddresses,
    uint256[][] calldata _entityIds,
    uint256[][] calldata _entityAmounts
  ) external onlyMinter nonReentrant whenNotPaused {
    require(
      _entityAddresses.length == _entityIds.length &&
        _entityAddresses.length == _entityAmounts.length
    );
    for (uint256 i = 0; i < _entityAddresses.length; i++) {
      _mintBatchInternal(
        _ownerAddress,
        _ownerTokenId,
        _entityAddresses[i],
        _entityIds[i],
        _entityAmounts[i]
      );
    }
  }

  function mintBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerTokenIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds,
    uint256[][][] calldata _entityAmounts
  ) external onlyMinter nonReentrant whenNotPaused {
    require(
      _entityAddresses.length == _entityIds.length &&
        _entityAddresses.length == _entityAmounts.length
    );
    for (uint256 i = 0; i < _entityAddresses.length; i++) {
      _mintBatchInternal(
        _ownerAddresses,
        _ownerTokenIds,
        _entityAddresses[i],
        _entityIds[i],
        _entityAmounts[i]
      );
    }
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
      adapters[_entityAddress].balanceOf(_ownerAddress, _ownerId, _entityAddress, _entityTokenId);
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
  function enableEntity(address _entity, address _adapter) public virtual onlyAdmin {
    require(address(adapters[_entity]) == address(0), "Collection already enabled");
    adapters[_entity] = IArmoryEntityStorageAdapter(_adapter);
    if (adapterListIndex[_entity] == 0) {
      adapterListIndex[_entity] = entityList.length;
      entityList.push(_entity);
    }
    entityTypes[_entity] = adapters[_entity].entityType();
    enabledEntitiesCount++;
  }

  function disableEntity(address _entity) public virtual onlyAdmin {
    require(address(adapters[_entity]) != address(0), "Collection already disabled");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint constant ARMORY_ENTITY_DISABLED = 0;
uint constant ARMORY_ENTITY_ERC20 = 1;
uint constant ARMORY_ENTITY_ERC721 = 2;
uint constant ARMORY_ENTITY_ERC1155 = 3;
uint constant ARMORY_ENTITY_DATA = 4;

import "./Armory.sol";
import "./IDurabilityEnabledArmory.sol";
import "./IDurabilityEnabledAdapter.sol";

contract DurabilityEnabledArmory is Armory, IDurabilityEnabledArmory {
  error DurabilityNotSupported(address _address);

  constructor(address _manager) Armory(_manager) {}

  bytes4 private constant DURABILITY_FUNCTION_SELECTOR =
    bytes4(keccak256("hasDurabilitySupport(address)"));

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
    return adapter.currentDurability(_ownerAddress, _ownerId, _entityAddress, _entityId);
  }

  function currentDurabilityBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds
  ) public view returns (uint[] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return adapter.currentDurabilityBatch(_ownerAddress, _ownerId, _entityAddress, _entityIds);
  }

  function currentDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address _entityAddress,
    uint256[][] calldata _entityIds
  ) external view returns (uint[][] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return adapter.currentDurabilityBatch(_ownerAddresses, _ownerIds, _entityAddress, _entityIds);
  }

  function currentDurabilityBatchMulti(
    address[] calldata _ownerAddresses,
    uint256[] calldata _ownerIds,
    address[] calldata _entityAddresses,
    uint256[][][] calldata _entityIds
  ) external view returns (uint[][][] memory result) {
    result = new uint[][][](_entityAddresses.length);
    for (uint i = 0; i < _entityAddresses.length; i++) {
      result[i] = _getDurabilityAdapter(_entityAddresses[i]).currentDurabilityBatch(
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
    return adapter.currentDurabilityPercentage(_ownerAddress, _ownerId, _entityAddress, _entityId);
  }

  function currentDurabilityPercentageBatch(
    address _ownerAddress,
    uint256 _ownerId,
    address _entityAddress,
    uint256[] calldata _entityIds
  ) public view returns (uint[] memory) {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    return
      adapter.currentDurabilityBatchPercentage(_ownerAddress, _ownerId, _entityAddress, _entityIds);
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
      result[i] = _getDurabilityAdapter(_entityAddresses[i]).currentDurabilityBatchPercentage(
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
  ) public onlyManager {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    adapter.reduceDurability(
      msg.sender,
      _ownerAddress,
      _ownerTokenId,
      _entityAddress,
      _entityTokenId,
      durabilityLoss,
      _startNewTokenIfNeeded,
      _ignoreAvailability
    );
  }

  function reduceDurabilityBatch(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external onlyManager {
    IDurabilityEnabledAdapter adapter = _getDurabilityAdapter(_entityAddress);
    adapter.reduceDurabilityBatch(
      msg.sender,
      _ownerAddresses,
      _ownerTokenIds,
      _entityAddress,
      _entityTokenIds,
      _durabilityLoss,
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
  ) external {
    for (uint i = 0; i < _entityAddresses.length; i++) {
      _getDurabilityAdapter(_entityAddresses[i]).reduceDurabilityBatch(
        msg.sender,
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
  ) external {
    for (uint i = 0; i < _entityAddresses.length; i++) {
      _getDurabilityAdapter(_entityAddresses[i]).reduceDurabilityBatch(
        msg.sender,
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

  function enableEntity(address _entity, address _adapter) public override onlyAdmin {
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

  function _checkDurabilitySupportExists(
    address _adapter,
    address _entity
  ) internal returns (bool) {
    bool success;
    bool result;
    bytes memory data = abi.encodeWithSelector(DURABILITY_FUNCTION_SELECTOR, _entity);
    bytes memory returndata = new bytes(32); // storage for returned value

    assembly {
      success := call(
        gas(), // gas remaining
        _adapter, // destination address
        0, // no ether
        add(data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
        mload(data), // input length (loaded from the first 32 bytes in the `data` array)
        returndata, // output buffer
        32 // expecting a single bool returned, hence 32 bytes
      )
    }

    if (success) {
      result = abi.decode(returndata, (bool));
    }

    return result;
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
  ) external;

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address _reducer,
    address _ownerAddress,
    uint _ownerTokenIds,
    address _entityAddress,
    uint[] calldata _entityTokenIds,
    uint[] calldata _durabilityLosses,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddress,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;

  function reduceDurabilityBatch(
    address _reducer,
    address[] calldata _ownerAddress,
    uint[] calldata _ownerTokenIds,
    address _entityAddress,
    uint[][] calldata _entityTokenIds,
    uint[][] calldata _durabilityLoss,
    bool _startNewTokenIfNeeded,
    bool _ignoreAvailability
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../Manager/ManagerModifier.sol";
import "./IArmoryEntityStorageAdapter.sol";

interface IDurabilityEnabledArmory {
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

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IRarityItem is IERC1155 {
  function mintFor(address _for, uint256 _id, uint256 _amount) external;

  function mintBatchFor(
    address _for,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external;

  function burn(uint256 _id, uint256 _amount) external;

  function burnBatch(uint256[] memory ids, uint256[] memory amounts) external;
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