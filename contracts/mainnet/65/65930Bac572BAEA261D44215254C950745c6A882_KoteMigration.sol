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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

uint64 constant DAILY_EPOCH_DURATION = 1 days;
uint64 constant DAILY_EPOCH_OFFSET = 0 hours;

uint64 constant HOURLY_EPOCH_DURATION = 1 hours;
uint64 constant NO_OFFSET = 0 hours;

uint256 constant ACTION_LOCK = 101;

uint256 constant ACTION_ADVENTURER_HOMAGE = 1001;
uint256 constant ACTION_ADVENTURER_BATTLE_V3 = 1002;
uint256 constant ACTION_ADVENTURER_COLLECT_EPOCH_REWARDS = 1003;
uint256 constant ACTION_ADVENTURER_VOID_CRAFTING = 1004;
uint256 constant ACTION_ADVENTURER_REALM_CRAFTING = 1005;
uint256 constant ACTION_ADVENTURER_ANIMA_REGENERATION = 1006;
uint256 constant ACTION_ADVENTURER_BATTLE_V3_OPPONENT = 1007;
uint256 constant ACTION_ADVENTURER_TRAINING = 1008;
uint256 constant ACTION_ADVENTURER_TRANSCENDENCE = 1009;
uint256 constant ACTION_ADVENTURER_MINT_MULTIPASS = 1010;

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

uint256 constant ACTION_ARMORY_STAKE_CITY = 2061;
uint256 constant ACTION_ARMORY_UNSTAKE_CITY = 2062;

uint256 constant ACTION_ARMORY_STAKE_MONUMENT = 2061;
uint256 constant ACTION_ARMORY_UNSTAKE_MONUMENT = 2062;

uint256 constant ACTION_REALM_COLLECT_COLLECTIBLES = 4001;
uint256 constant ACTION_REALM_BUILD_LAB = 4011;
uint256 constant ACTION_REALM_BUILD_MONUMENT = 4012;
uint256 constant ACTION_REALM_BUILD_CITY = 4013;

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";

interface IBatchLastActionMarkerStorage {
  function setActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action,
    uint256 _marker
  ) external;

  function setActionMarkerMany(
    address[] calldata _tokenAddress,
    uint256[] calldata _tokenId,
    uint256 _action,
    uint256 _marker
  ) external;

  function getActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action
  ) external view returns (uint256);

  function getActionMarkerBatch(
    address[] calldata _tokenAddress,
    uint256[] calldata _tokenId,
    uint256 _action
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "../Manager/ManagerModifier.sol";

interface ILastActionMarkerStorage {
  function setActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action,
    uint256 _marker
  ) external;

  function getActionMarker(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _action
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

uint constant ADVENTURER_DATA_BASE = 0;
uint constant ADVENTURER_DATA_AOV = 1;
uint constant ADVENTURER_DATA_EXTENSION = 2;

interface IBatchAdventurerData {
  function STORAGE(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256 _prop
  ) external view returns (uint24);

  function add(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256 _val
  ) external;

  function addBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external;

  function update(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function updateRaw(address _addr, uint256 _id, uint256 _type, uint24[10] calldata _val) external;

  function updateBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop,
    uint256[] calldata _val
  ) external;

  function updateBatchRaw(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint24[10][] calldata _val
  ) external;

  function remove(address _addr, uint256 _id, uint256 _type, uint256 _prop, uint256 _val) external;

  function removeBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256[][] calldata _prop,
    uint256[][] calldata _val
  ) external;

  function get(address _addr, uint256 _id, uint256 _type, uint256 _prop) external returns (uint256);

  function getRaw(address _addr, uint256 _id, uint256 _type) external returns (uint24[10] memory);

  function getMulti(
    address _addr,
    uint256 _id,
    uint256 _type,
    uint256[] calldata _prop
  ) external returns (uint256[] memory result);

  function getBatch(
    address[] calldata _addr,
    uint256[] calldata _id,
    uint256 _type,
    uint256 _prop
  ) external returns (uint256[] memory);

  function getBatchMulti(
    address[] calldata _addrs,
    uint256[] calldata _ids,
    uint256 _type,
    uint256[] calldata _props
  ) external returns (uint256[][] memory);

  function getRawBatch(
    address[] calldata _addrs,
    uint256[] calldata _ids,
    uint256 _type
  ) external returns (uint24[10][] memory result);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBatchAdventurerGateway {
  function checkAddress(address _addr, bytes32[] calldata _proof) external view;

  function checkAddressBatch(address[] calldata _addr, bytes32[][] calldata _proof) external view;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library traits {
  uint256 public constant ADV_TRAIT_GROUP_BASE = 0;

  // Base, _type = 0
  uint256 public constant ADV_TRAIT_BASE_LEVEL = 0;
  uint256 public constant ADV_TRAIT_BASE_XP = 1;
  uint256 public constant ADV_TRAIT_BASE_STRENGTH = 2;
  uint256 public constant ADV_TRAIT_BASE_DEXTERITY = 3;
  uint256 public constant ADV_TRAIT_BASE_CONSTITUTION = 4;
  uint256 public constant ADV_TRAIT_BASE_INTELLIGENCE = 5;
  uint256 public constant ADV_TRAIT_BASE_WISDOM = 6;
  uint256 public constant ADV_TRAIT_BASE_CHARISMA = 7;
  uint256 public constant ADV_TRAIT_BASE_CLASS = 8;

  uint256 public constant ADV_TRAIT_GROUP_ADVANCED = 1;
  // Advanced, _type = 1
  uint256 public constant ADV_TRAIT_ADVANCED_ARCHETYPE = 0;
  uint256 public constant ADV_TRAIT_ADVANCED_PROFESSION = 1;
  uint256 public constant ADV_TRAIT_ADVANCED_TRAINING_POINTS = 2;

  // Base Ttraits
  // See AdventurerData.sol for details
  uint256 public constant LEGACY_ADV_BASE_TRAIT_XP = 0;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_XP_BROKEN = 1;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_STRENGTH = 2;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_DEXTERITY = 3;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_CONSTITUTION = 4;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_INTELLIGENCE = 5;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_WISDOM = 6;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_CHARISMA = 7;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_HP = 8;
  uint256 public constant LEGACY_ADV_BASE_TRAIT_HP_USED = 9;

  // AoV Traits
  // See AdventurerData.sol for details
  uint256 public constant LEGACY_ADV_AOV_TRAIT_LEVEL = 0;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_ARCHETYPE = 1;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_CLASS = 2;
  uint256 public constant LEGACY_ADV_AOV_TRAIT_PROFESSION = 3;

  function baseTraitNames() public pure returns (string[10] memory) {
    return [
      "Level",
      "XP",
      "Strength",
      "Dexterity",
      "Constitution",
      "Intelligence",
      "Wisdom",
      "Charisma",
      "Class",
      ""
    ];
  }

  function advancedTraitNames() public pure returns (string[2] memory) {
    return ["Archetype", "Profession"];
  }

  function baseTraitName(uint256 traitId) public pure returns (string memory) {
    return baseTraitNames()[traitId];
  }

  function advancedTraitName(uint256 traitId) public pure returns (string memory) {
    return advancedTraitNames()[traitId];
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

uint256 constant DECIMAL_POINT = 10 ** 3;
uint256 constant ROUNDING_ADJUSTER = DECIMAL_POINT - 1;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../Manager/ManagerModifier.sol";
import "../Utils/ArrayUtils.sol";
import "../Adventurer/IBatchAdventurerData.sol";
import "../Action/ILastActionMarkerStorage.sol";
import "../Action/Actions.sol";
import "../Action/IBatchLastActionMarkerStorage.sol";
import "../Particle/IParticleTracker.sol";
import "../Adventurer/IBatchAdventurerGateway.sol";
import "../Renown/IRenown.sol";
import "../Adventurer/TraitConstants.sol";
import "../Armory/IDurabilityEnabledArmory.sol";
import "../lib/FloatingPointConstants.sol";

error AlreadyMigrated(address tokenAddress, uint256 tokenId);
error NotAllowed(
  address sender,
  address fromTokenAddress,
  uint256 fromTokenId,
  address toTokenAddress,
  uint256 toTokenId
);

uint256 constant EXPLORER_WEIGHT = 10;

struct MigrationRequest {
  address[] fromTokenAddresses;
  uint256[] fromTokenIds;
  address[] toTokenAddresses;
  uint256[] toTokenIds;
  bytes32[][] toProofs;
}

struct ArmoryMigrationRequest {
  address[] armoryEntityTypes;
  uint256[][][] armoryEntityTokenIds;
  uint256[][][] armoryEntityAmounts;
}

abstract contract AbstractAdventurerMigration is
  ManagerModifier,
  Pausable,
  ReentrancyGuard
{
  //=======================================
  // Events
  //=======================================
  event AdventurerMigrated(
    address fromAddr,
    uint256 fromId,
    address toAddr,
    uint256 toId
  );

  IBatchAdventurerData public BATCH_ADVENTURER_DATA;
  IDurabilityEnabledArmory public ADVENTURER_ARMORY;
  IBatchLastActionMarkerStorage public BATCH_LAST_ACTION_MARKER_STORAGE;
  IParticleTracker public PARTICLE_TRACKER;
  IBatchAdventurerGateway public GATEWAY;
  IRenown public RENOWN;

  mapping(address => mapping(uint256 => bool)) public FINISHED_MIGRATIONS;

  constructor(
    address _manager,
    address _batchAdventurerData,
    address _adventurerArmory,
    address _lastActionMarkerStorage,
    address _particleTracker,
    address _gateway,
    address _renown
  ) ManagerModifier(_manager) {
    BATCH_ADVENTURER_DATA = IBatchAdventurerData(_batchAdventurerData);
    ADVENTURER_ARMORY = IDurabilityEnabledArmory(_adventurerArmory);
    BATCH_LAST_ACTION_MARKER_STORAGE = IBatchLastActionMarkerStorage(
      _lastActionMarkerStorage
    );
    PARTICLE_TRACKER = IParticleTracker(_particleTracker);
    GATEWAY = IBatchAdventurerGateway(_gateway);
    RENOWN = IRenown(_renown);
  }

  function checkOwnedItems(
    address[] calldata _ownerAddresses,
    uint[] calldata _ownerIds,
    address[] calldata _entityAddresses,
    uint[][] calldata _entityIds
  ) external view returns (ArmoryMigrationRequest memory) {
    ArmoryMigrationRequest memory result;
    result.armoryEntityTypes = _entityAddresses;
    result.armoryEntityTokenIds = new uint256[][][](_entityAddresses.length);
    result.armoryEntityAmounts = new uint256[][][](_entityAddresses.length);

    for (uint i = 0; i < _entityAddresses.length; i++) {
      result.armoryEntityTokenIds[i] = new uint256[][](_ownerAddresses.length);
      result.armoryEntityAmounts[i] = new uint256[][](_ownerAddresses.length);
      bool isDurabilitySupported = ADVENTURER_ARMORY.durabilitySupport(
        _entityAddresses[i]
      );

      for (uint j = 0; j < _ownerAddresses.length; j++) {
        (
          result.armoryEntityTokenIds[i][j],
          result.armoryEntityAmounts[i][j]
        ) = loadSingleAdventurerEntityBalances(
          _ownerAddresses[j],
          _ownerIds[j],
          _entityAddresses[i],
          _entityIds[i],
          isDurabilitySupported
        );
      }
    }
    return result;
  }

  function loadSingleAdventurerEntityBalances(
    address _ownerAddress,
    uint _ownerId,
    address _entityAddress,
    uint[] calldata _entityIds,
    bool _isDurabilitySupported
  ) internal view returns (uint256[] memory ids, uint256[] memory amounts) {
    uint[] memory balances = ADVENTURER_ARMORY.balanceOfBatch(
      _ownerAddress,
      _ownerId,
      _entityAddress,
      _entityIds
    );

    uint resultSize = 0;
    for (uint i = 0; i < _entityIds.length; i++) {
      if (balances[i] <= 0) {
        continue;
      }

      if (_isDurabilitySupported) {
        uint durability = ADVENTURER_ARMORY.currentDurabilityPercentage(
          _ownerAddress,
          _ownerId,
          _entityAddress,
          _entityIds[i]
        );

        // We can't migrate damaged items
        if (durability != ONE_HUNDRED) {
          balances[i]--;
        }
      }

      if (balances[i] > 0) {
        resultSize++;
      }
    }

    ids = new uint256[](resultSize);
    amounts = new uint256[](resultSize);

    uint index = 0;
    for (uint i = 0; i < _entityIds.length; i++) {
      if (balances[i] <= 0) {
        continue;
      }

      ids[index] = _entityIds[i];
      amounts[index] = balances[i];
      index++;
    }
  }

  function _isAllowed(
    address _sender,
    address _fromTokenAddress,
    uint256 _fromTokenId,
    address _toTokenAddress,
    uint256 _toTokenId
  ) internal virtual returns (bool);

  function migrate(
    MigrationRequest calldata _request,
    ArmoryMigrationRequest calldata _armoryRequest
  ) external virtual whenNotPaused nonReentrant {
    ArrayUtils.ensureSameLength(
      _request.fromTokenAddresses.length,
      _request.fromTokenIds.length,
      _request.toTokenAddresses.length,
      _request.toTokenIds.length,
      _request.toProofs.length
    );
    ArrayUtils.ensureSameLength(
      _armoryRequest.armoryEntityTypes.length,
      _armoryRequest.armoryEntityTokenIds.length,
      _armoryRequest.armoryEntityAmounts.length
    );

    GATEWAY.checkAddressBatch(_request.toTokenAddresses, _request.toProofs);
    _verifyMigrations(
      _request.fromTokenAddresses,
      _request.fromTokenIds,
      _request.toTokenAddresses,
      _request.toTokenIds
    );
    // Mark as finished
    for (uint i = 0; i < _request.toTokenAddresses.length; i++) {
      FINISHED_MIGRATIONS[_request.toTokenAddresses[i]][
        _request.toTokenIds[i]
      ] = true;
      emit AdventurerMigrated(
        _request.fromTokenAddresses[i],
        _request.fromTokenIds[i],
        _request.toTokenAddresses[i],
        _request.toTokenIds[i]
      );
    }

    _migrateStats(
      _request.fromTokenAddresses,
      _request.fromTokenIds,
      _request.toTokenAddresses,
      _request.toTokenIds
    );

    _migrateArmory(
      _request.fromTokenAddresses,
      _request.fromTokenIds,
      _request.toTokenAddresses,
      _request.toTokenIds,
      _armoryRequest.armoryEntityTypes,
      _armoryRequest.armoryEntityTokenIds,
      _armoryRequest.armoryEntityAmounts
    );

    _migrateActionStates(
      _request.fromTokenAddresses,
      _request.fromTokenIds,
      _request.toTokenAddresses,
      _request.toTokenIds
    );

    _migrateExploration(
      _request.fromTokenAddresses,
      _request.fromTokenIds,
      _request.toTokenAddresses,
      _request.toTokenIds
    );
  }

  function _verifyMigrations(
    address[] calldata _fromTokenAddresses,
    uint256[] calldata _fromTokenIds,
    address[] calldata _toTokenAddresses,
    uint256[] calldata _toTokenIds
  ) internal {
    for (uint i = 0; i < _fromTokenAddresses.length; i++) {
      if (FINISHED_MIGRATIONS[_toTokenAddresses[i]][_toTokenIds[i]]) {
        revert AlreadyMigrated(_toTokenAddresses[i], _toTokenIds[i]);
      }

      if (
        !_isAllowed(
          msg.sender,
          _fromTokenAddresses[i],
          _fromTokenIds[i],
          _toTokenAddresses[i],
          _toTokenIds[i]
        )
      ) {
        revert NotAllowed(
          msg.sender,
          _fromTokenAddresses[i],
          _fromTokenIds[i],
          _toTokenAddresses[i],
          _toTokenIds[i]
        );
      }
    }
  }

  function _migrateStats(
    address[] calldata _fromTokenAddresses,
    uint256[] calldata _fromTokenIds,
    address[] calldata _toTokenAddresses,
    uint256[] calldata _toTokenIds
  ) internal virtual {
    // Migrate base stats
    uint24[10][] memory rawStats = BATCH_ADVENTURER_DATA.getRawBatch(
      _fromTokenAddresses,
      _fromTokenIds,
      traits.ADV_TRAIT_GROUP_BASE
    );

    uint[] memory levels = new uint[](_fromTokenAddresses.length);
    for (uint i = 0; i < _fromTokenAddresses.length; i++) {
      levels[i] = uint(rawStats[i][traits.ADV_TRAIT_BASE_LEVEL]);
    }

    BATCH_ADVENTURER_DATA.updateBatchRaw(
      _toTokenAddresses,
      _toTokenIds,
      traits.ADV_TRAIT_GROUP_BASE,
      rawStats
    );

    rawStats = BATCH_ADVENTURER_DATA.getRawBatch(
      _fromTokenAddresses,
      _fromTokenIds,
      traits.ADV_TRAIT_GROUP_ADVANCED
    );

    BATCH_ADVENTURER_DATA.updateBatchRaw(
      _toTokenAddresses,
      _toTokenIds,
      traits.ADV_TRAIT_GROUP_ADVANCED,
      rawStats
    );

    // Migrate Renown
    int[] memory renowns = RENOWN.currentRenownBatch(
      _fromTokenAddresses,
      _fromTokenIds,
      levels
    );
    int[] memory targetRenowns = RENOWN.currentRenownBatch(
      _toTokenAddresses,
      _toTokenIds,
      levels
    );

    for (uint i = 0; i < _fromTokenAddresses.length; i++) {
      targetRenowns[i] = renowns[i] - targetRenowns[i];
    }

    RENOWN.changeBatch(_toTokenAddresses, _toTokenIds, levels, targetRenowns);
  }

  function _migrateArmory(
    address[] calldata _fromTokenAddresses,
    uint256[] calldata _fromTokenIds,
    address[] calldata _toTokenAddresses,
    uint256[] calldata _toTokenIds,
    address[] calldata _armoryEntityTypes,
    uint256[][][] calldata _armoryEntityTokenIds,
    uint256[][][] calldata _armoryEntityAmounts
  ) internal virtual {
    ADVENTURER_ARMORY.burnBatchMulti(
      _fromTokenAddresses,
      _fromTokenIds,
      _armoryEntityTypes,
      _armoryEntityTokenIds,
      _armoryEntityAmounts
    );

    for (uint i = 0; i < _armoryEntityTypes.length; i++) {
      ADVENTURER_ARMORY.mintBatch(
        _toTokenAddresses,
        _toTokenIds,
        _armoryEntityTypes[i],
        _armoryEntityTokenIds[i],
        _armoryEntityAmounts[i]
      );
    }
  }

  function _migrateActionStates(
    address[] calldata _fromTokenAddresses,
    uint256[] calldata _fromTokenIds,
    address[] calldata _toTokenAddresses,
    uint256[] calldata _toTokenIds
  ) internal virtual {
    uint256[] memory lastBattleTimes = BATCH_LAST_ACTION_MARKER_STORAGE
      .getActionMarkerBatch(
        _fromTokenAddresses,
        _fromTokenIds,
        ACTION_ADVENTURER_BATTLE_V3
      );

    for (uint i = 0; i < _fromTokenAddresses.length; i++) {
      BATCH_LAST_ACTION_MARKER_STORAGE.setActionMarker(
        _toTokenAddresses[i],
        _toTokenIds[i],
        ACTION_ADVENTURER_BATTLE_V3,
        lastBattleTimes[i]
      );
    }
  }

  function _migrateExploration(
    address[] calldata _fromTokenAddresses,
    uint256[] calldata _fromTokenIds,
    address[] calldata _toTokenAddresses,
    uint256[] calldata _toTokenIds
  ) internal virtual {
    for (uint i = 0; i < _fromTokenAddresses.length; i++) {
      (uint256 realmId, bool isExploring) = PARTICLE_TRACKER.currentRealm(
        _fromTokenAddresses[i],
        _fromTokenIds[i]
      );

      if (isExploring) {
        PARTICLE_TRACKER.removeExplorer(
          realmId,
          _fromTokenAddresses[i],
          _fromTokenIds[i],
          EXPLORER_WEIGHT
        );

        PARTICLE_TRACKER.addExplorer(
          realmId,
          _toTokenAddresses[i],
          _toTokenIds[i],
          EXPLORER_WEIGHT
        );
      }
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
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./AbstractAdventurerMigration.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

contract KoteMigration is AbstractAdventurerMigration {
  address public KNIGHTS;
  address public INITIATED_KNIGHTS;

  constructor(
    address _manager,
    address _batchAdventurerData,
    address _adventurerArmory,
    address _lastActionMarkerStorage,
    address _particleTracker,
    address _gateway,
    address _renown,
    address _knights,
    address _initiatedKnights
  )
    AbstractAdventurerMigration(
      _manager,
      _batchAdventurerData,
      _adventurerArmory,
      _lastActionMarkerStorage,
      _particleTracker,
      _gateway,
      _renown
    )
  {
    KNIGHTS = _knights;
    INITIATED_KNIGHTS = _initiatedKnights;
  }

  function _isAllowed(
    address _sender,
    address _fromTokenAddress,
    uint256 _fromTokenId,
    address _toTokenAddress,
    uint256 _toTokenId
  ) internal view override returns (bool) {
    return
      _fromTokenAddress == KNIGHTS &&
      _toTokenAddress == INITIATED_KNIGHTS &&
      _fromTokenId == _toTokenId &&
      IERC721(KNIGHTS).ownerOf(_fromTokenId) == BURN_ADDRESS &&
      IERC721(INITIATED_KNIGHTS).ownerOf(_toTokenId) == _sender;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IParticleTracker {
  function timer(
    address _addr,
    uint256 _adventurerId
  ) external view returns (uint256);

  function currentRealm(
    address _addr,
    uint256 _adventurerId
  ) external view returns (uint256, bool);

  function getExplorerCount(uint256 _realmId) external view returns (uint256);

  function addExplorer(
    uint256 _realmId,
    address _addr,
    uint256 _adventurerId,
    uint256 _amount
  ) external;

  function removeExplorer(
    uint256 _realmId,
    address _addr,
    uint256 _adventurerId,
    uint256 _amount
  ) external;

  function setTimer(address _addr, uint256 _adventurerId) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IRenown {
  event RenownInitialized(address adventurerAddress, uint adventurerId, uint level, int baseAmount);
  event RenownChange(address adventurerAddress, uint adventurerId, uint level, int delta);

  // All time Renown
  function currentRenown(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _level
  ) external view returns (int);

  function currentRenowns(
    address _tokenAddress1,
    uint256 _tokenId1,
    uint _level1,
    address _tokenAddress2,
    uint256 _tokenId2,
    uint _level2
  ) external view returns (int, int);

  function currentRenownBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels
  ) external view returns (int[] memory);

  function forceInitIfNeeded(
    address _tokenAddress,
    uint256 _tokenId,
    uint _level
  ) external returns (int);

  function change(address _tokenAddress, uint256 _tokenId, uint _level, int _delta) external;

  function changeBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels,
    int[] calldata _deltas
  ) external;

  function changeBatch(
    address[] calldata _tokenAddresses,
    uint256[] calldata _tokenIds,
    uint256[] calldata _levels,
    int _delta
  ) external;
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