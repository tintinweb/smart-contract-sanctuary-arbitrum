// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../Realm/IRealm.sol";
import "./IReactor.sol";
import "../Staker/IStructureStaker.sol";
import "../RealmLock/IRealmLock.sol";
import "../lib/ITreasure.sol";

import "../Manager/ManagerModifier.sol";

contract ReactorManager is
  ReentrancyGuard,
  Pausable,
  ManagerModifier,
  ERC1155Holder
{
  //=======================================
  // Immutables
  //=======================================
  IRealm public immutable REALM;
  IReactor public immutable FOOD_REACTOR;
  IReactor public immutable AQUATIC_REACTOR;
  IReactor public immutable TECH_REACTOR;
  IReactor public immutable EARTHEN_REACTOR;
  IStructureStaker public immutable STRUCTURE_STAKER;
  IRealmLock public immutable REALM_LOCK;
  ITreasure public immutable TREASURE;

  //=======================================
  // Array
  //=======================================
  uint256[] public defaultTreasureIds;

  //=======================================
  // Events
  //=======================================
  event ReactorStaked(
    uint256 realmId,
    address structureAddress,
    uint256 structureId
  );
  event ReactorUnstaked(
    uint256 realmId,
    address structureAddress,
    uint256 structureId
  );
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
    address[4] memory _reactors,
    address _structureStaker,
    address _realmLock,
    address _treasure,
    uint256[4] memory _treasureIds
  ) ManagerModifier(_manager) {
    REALM = IRealm(_realm);
    FOOD_REACTOR = IReactor(_reactors[0]);
    AQUATIC_REACTOR = IReactor(_reactors[1]);
    TECH_REACTOR = IReactor(_reactors[2]);
    EARTHEN_REACTOR = IReactor(_reactors[3]);
    STRUCTURE_STAKER = IStructureStaker(_structureStaker);
    REALM_LOCK = IRealmLock(_realmLock);
    TREASURE = ITreasure(_treasure);

    defaultTreasureIds = _treasureIds;
  }

  //=======================================
  // External
  //=======================================
  function stake(
    uint256 _realmId,
    uint256 _structureId,
    uint256 _kind
  ) external nonReentrant whenNotPaused {
    // Check kind is valid
    require(_kind <= 3, "ReactorManager: Kind must be below 3");

    // Get reactor
    IReactor reactor = _reactor(_kind);

    // Stake
    STRUCTURE_STAKER.stakeFor(
      msg.sender,
      _realmId,
      address(reactor),
      _structureId
    );

    // Transfer treasures to contract forever
    // TODO: or do we want to store them for later?
    TREASURE.safeTransferFrom(
      msg.sender,
      address(this),
      defaultTreasureIds[_kind],
      1,
      ""
    );

    emit ReactorStaked(_realmId, address(reactor), _structureId);
  }

  function stakeBatch(
    uint256[] calldata _realmIds,
    uint256[] calldata _structureIds,
    uint256[] calldata _kinds
  ) external nonReentrant whenNotPaused {
    uint256 j = 0;
    uint256 length = _kinds.length;
    uint256[] memory treasureIds = new uint256[](4);
    uint256[] memory treasureAmounts = new uint256[](4);
    address[] memory addresses = new address[](length);

    for (; j < length; j++) {
      uint256 kind = _kinds[j];

      // Check kind is valid
      require(kind <= 3, "ReactorManager: Kind must be below 3");

      // Get reactor
      IReactor reactor = _reactor(kind);

      // Set addresses
      addresses[j] = address(reactor);

      // Set Treasure ids and amounts
      treasureIds[j] = defaultTreasureIds[kind];
      treasureAmounts[j] = 1;
    }

    // Transfer treasures to contract forever
    // TODO: or do we want to store them for later?
    TREASURE.safeBatchTransferFrom(
      msg.sender,
      address(this),
      treasureIds,
      treasureAmounts,
      ""
    );

    // Stake
    STRUCTURE_STAKER.stakeBatchFor(
      msg.sender,
      _realmIds,
      addresses,
      _structureIds
    );

    emit ReactorBatchStaked(_realmIds, addresses, _structureIds);
  }

  function unstake(
    uint256 _realmId,
    uint256 _structureId,
    uint256 _kind
  ) external nonReentrant whenNotPaused {
    // Check if Realm is locked
    require(REALM_LOCK.isUnlocked(_realmId), "ReactorManager: Realm is locked");

    // Check kind is valid
    require(_kind <= 3, "ReactorManager: Kind must be below 3");

    // Get reactor
    IReactor reactor = _reactor(_kind);

    // Unstake
    STRUCTURE_STAKER.unstakeFor(
      msg.sender,
      _realmId,
      address(reactor),
      _structureId
    );

    emit ReactorUnstaked(_realmId, address(reactor), _structureId);
  }

  function unstakeBatch(
    uint256[] calldata _realmIds,
    uint256[] calldata _structureIds,
    uint256[] calldata _kinds
  ) external nonReentrant whenNotPaused {
    uint256 j = 0;
    uint256 length = _realmIds.length;

    // TODO: Maybe do this inside the other loop
    // Check if Realm is locked
    for (; j < length; j++) {
      require(
        REALM_LOCK.isUnlocked(_realmIds[j]),
        "ReactorManager: Realm is locked"
      );
    }

    uint256 h = 0;
    uint256 typesLength = _kinds.length;
    address[] memory addresses = new address[](typesLength);

    for (; h < typesLength; h++) {
      uint256 kind = _kinds[h];

      // Check kind is valid
      require(kind <= 3, "ReactorManager: Kind must be below 3");

      // Get reactor
      IReactor reactor = _reactor(kind);

      // Set addresses
      addresses[h] = address(reactor);
    }

    // Unstake
    STRUCTURE_STAKER.unstakeBatchFor(
      msg.sender,
      _realmIds,
      addresses,
      _structureIds
    );

    emit ReactorBatchUnstaked(_realmIds, addresses, _structureIds);
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

  function setTreasureIds(uint256[4] calldata _treasureIds) external onlyAdmin {
    defaultTreasureIds = _treasureIds;
  }

  function _reactor(uint256 _kind) internal view returns (IReactor reactor) {
    if (_kind == 0) {
      return FOOD_REACTOR;
    } else if (_kind == 1) {
      return AQUATIC_REACTOR;
    } else if (_kind == 2) {
      return TECH_REACTOR;
    } else if (_kind == 3) {
      return EARTHEN_REACTOR;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

interface IReactor {
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

interface ITreasure {
  // Transfers the treasure at the given ID of the given amount.
  // Requires that the legions are pre-approved.
  //
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes memory data
  ) external;

  // Transfers the treasure at the given ID of the given amount.
  //
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory data
  ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}