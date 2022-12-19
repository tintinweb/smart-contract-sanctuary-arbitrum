//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Constants.sol";
import "./Types.sol";

import "../UserAccess/IUserAccess.sol";
import "../TokenAccess/ITokenAccess.sol";

import "../UserAccessible/UserAccessible.sol";
import "../SkillManager/SkillManager.sol";
import "../ItemManager/ItemManager.sol";
import "../RandomManager/RandomManager.sol";
import "../EOA/EOA.sol";
import "../Probable/Probable.sol";

contract Kitchen is 
  UserAccessible, 
  EOA,
  ItemManager,
  RandomManager,
  SkillManager,
  Probable
{

  mapping (uint => Recipe) public itemToRecipe; // itemId => Recipe
  mapping (uint => Result[]) public itemToResults; // itemId => Result[]

  mapping (uint => Activity) public playerToActivity; // playerId => Activity

  // statistics
  mapping (uint => mapping (uint => uint)) public playerToItemToCookCount;
  mapping (uint => uint) public itemToCookCount;

  event StartedCooking (uint playerId, uint itemId, uint timestamp);
  event FinishedCooking (uint playerId, uint itemId, uint rewardId, uint timestamp);

  constructor(
    address _items, 
    address _randomizer, 
    address _skills,
    address _userAccess
  )
    UserAccessible(_userAccess) 
    ItemManager(_items)
    RandomManager(_randomizer)
    SkillManager(_skills)
    {}

  function getRecipe (uint itemId) public view returns (Recipe memory) {
    return itemToRecipe[itemId];
  }

  function updateRecipeRequirement (uint itemId, uint expRequired) public onlyAdmin { itemToRecipe[itemId].expRequired = expRequired; }
  function updateRecipeDuration (uint itemId, uint newDuration) public onlyAdmin { itemToRecipe[itemId].duration = newDuration; }
  function setRecipeActive (uint itemId, bool newState) public onlyAdmin { itemToRecipe[itemId].active = newState; }
  function setResultsForItem (uint itemId, Result[] calldata newResults) public onlyAdmin { _setResultsForItem(itemId, newResults); }
  function resetActivity (uint playerId) public onlyAdmin { delete playerToActivity[playerId]; }

  function updateRecipe (
    uint itemId, 
    bool active, 
    uint duration, 
    uint expRequired
  ) public onlyAdmin {
    itemToRecipe[itemId].active = active;
    itemToRecipe[itemId].duration = duration;
    itemToRecipe[itemId].expRequired = expRequired;
  }

  function setRecipeForItem (
    uint itemId, 
    Result[] calldata newResults, 
    bool active, 
    uint duration,
    uint expRequired
  ) 
    public 
    onlyAdmin 
  {
    _setResultsForItem(itemId, newResults);
    itemToRecipe[itemId].active = active;
    itemToRecipe[itemId].duration = duration;
    itemToRecipe[itemId].expRequired = expRequired;
  }

  function setRandomizer (address _randomizer) public onlyAdmin {
    _setRandomizer(_randomizer);
  }

  function cookFor (address from, uint playerId, uint itemId) 
    public
    adminOrRole(KITCHEN_ROLE)
  {
    _safeCookFor(from, playerId, itemId);
  }

  function claimFor (address to, uint playerId, uint boostFactor) 
    public
    adminOrRole(KITCHEN_ROLE)
  {
    _safeClaimFor(to, playerId, boostFactor);
  }

  function unsafeCookFor (address from, uint playerId, uint itemId) 
    public
    adminOrRole(KITCHEN_ROLE)
  {
    _cookFor(from, playerId, itemId);
  }

   function unsafeClaimFor (address to, uint playerId, uint boostFactor) 
    public
    adminOrRole(KITCHEN_ROLE)
  {
    _claimFor(to, playerId, boostFactor);
  }

  function _safeCookFor (address from, uint playerId, uint itemId) private {
    Recipe memory recipe = itemToRecipe[itemId];
    require(recipe.active, 'RECIPE_INACTIVE');
    require(skills.experienceOf(playerId, SKILL_COOKING) >= recipe.expRequired, 'NOT_ENOUGH_EXP');
    require(items.balanceOf(from, itemId) > 0, 'NO_ITEM');
    _cookFor(from, playerId, itemId);
  }

  function _cookFor (address from, uint playerId, uint itemId) private {
    Activity storage activity = playerToActivity[playerId];
    items.burn(from, itemId, 1);
    activity.itemId = itemId;
    activity.started = block.timestamp;
    activity.randomId = randomizer.requestRandomNumber();

    emit StartedCooking(playerId, itemId, activity.started);
  }

  function _safeClaimFor (address to, uint playerId, uint boostFactor) private {
    Activity storage activity = playerToActivity[playerId];
    Recipe memory recipe = itemToRecipe[activity.itemId];
    require(block.timestamp - activity.started >= recipe.duration, 'NOT_COOKED');
    _claimFor(to, playerId, boostFactor);
  }

  function _claimFor (address to, uint playerId, uint boostFactor) private {
    Activity storage activity = playerToActivity[playerId];
    Recipe memory recipe = itemToRecipe[activity.itemId];
    require(block.timestamp - activity.started >= recipe.duration, 'NOT_COOKED');
    require(randomizer.isRandomReady(activity.randomId), 'RANDOM_NOT_READY');

    uint randomSeed = uint(keccak256(abi.encode(
      randomizer.revealRandomNumber(activity.randomId),
      playerId
    )));
    Result memory result = _rewardForScore(
      randomSeed % baseChance, 
      itemToResults[activity.itemId], 
      baseChance, 
      boostFactor
    );

    items.mint(to, result.itemId, 1);
    skills.addExperience(playerId, SKILL_COOKING, result.experience);
    
    playerToItemToCookCount[playerId][result.itemId] += 1;
    itemToCookCount[result.itemId] += 1;

    emit FinishedCooking(playerId, activity.itemId, result.itemId, block.timestamp);

  }

  function _rewardForScore (
    uint _score, 
    Result[] memory results, 
    uint probability, 
    uint boostFactor
  ) 
    private 
    pure
    returns (Result memory) 
  {
    assert(boostFactor >= probability);
    int score = int(_score);
    int offset = int(boostFactor - probability);
    assert(offset >= 0);
    int bottom = 0 - offset; // offset results to the left.
    for (uint i = 0; i < results.length; i++) {
      int p = int((results[i].probability * boostFactor) / probability);
      if (score >= bottom && score < bottom + p) return results[i]; 
      bottom += p;
    }
    assert(false);
  }

  function _sumOfProbability (Result[] memory results) private pure returns (uint) {
    uint sum = 0;
    for (uint i = 0; i < results.length; i++) {
      sum += results[i].probability;
    }
    return sum;
  }

  function _setResultsForItem (
    uint itemId, 
    Result[] memory newResults
  ) 
    private
  {
    require(_sumOfProbability(newResults) == baseChance, 'INVALID_PROBABILITY');
    delete itemToResults[itemId];
    for (uint i = 0; i < newResults.length; i++) {
      itemToResults[itemId].push(newResults[i]);
    }
  }

  function __testRecipeLength (uint itemId) public view returns (uint) {
    return itemToResults[itemId].length;
  }

  function __testRewardForScore (uint score, Result[] memory results, uint probability, uint boostFactor) 
    public
    pure
    returns (Result memory) 
  {
    return _rewardForScore(score, results, probability, boostFactor);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

bytes32 constant KITCHEN_ROLE = keccak256("KITCHEN_ROLE");

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Recipe {
  bool active;
  uint duration; // time to cook the dish
  uint expRequired;
}

struct Result {
  uint itemId;
  uint probability;
  uint32 experience;
}

struct Activity {
  uint itemId;
  uint randomId;
  uint started;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IUserAccess is IAccessControl {
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface ITokenAccess {

  function getAddress (uint contractId) external view returns (address);
  function getType (uint contractId) external view returns (uint8);
  function getContract (uint contractId) external view returns (ContractMeta memory);

  function validToken (uint contractId, uint tokenId) external view returns (bool);

  function banToken (uint contractId, uint tokenId) external;
  function unbanToken (uint contractId, uint tokenId) external;

  function addContract (address addr, uint8 tokenType, bool active) external;
  function updateContractState (uint contractId, bool active) external;
  function updateContractMeta (uint contractId, address addr, uint8 tokenType) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../UserAccess/IUserAccess.sol";
import "./Constants.sol";

abstract contract UserAccessible {

  IUserAccess public userAccess;

  modifier onlyRole (bytes32 role) {
    require(userAccess != IUserAccess(address(0)), 'UA_NOT_SET');
    require(userAccess.hasRole(role, msg.sender), 'UA_UNAUTHORIZED');
    _;
  }

  modifier eitherRole (bytes32[] memory roles) {
    require(userAccess != IUserAccess(address(0)), 'UA_NOT_SET');
    bool isAuthorized = false;
    for (uint i = 0; i < roles.length; i++) {
      if (userAccess.hasRole(roles[i], msg.sender)) {
        isAuthorized = true;
        break;
      }
    }
    require(isAuthorized, 'UA_UNAUTHORIZED');
    _;
  }

  modifier adminOrRole (bytes32 role) {
    require(userAccess != IUserAccess(address(0)), 'UA_NOT_SET');
    require(isAdminOrRole(msg.sender, role), 'UA_UNAUTHORIZED');
    _;
  }

  modifier onlyAdmin () {
    require(userAccess != IUserAccess(address(0)), 'UA_NOT_SET');
    require(isAdmin(msg.sender), 'UA_UNAUTHORIZED');
    _;
  }

  constructor (address _userAccess) {
    _setUserAccess(_userAccess);
  }

  function _setUserAccess (address _userAccess) internal {
    userAccess = IUserAccess(_userAccess);
  }

  function hasRole (bytes32 role, address sender) public view returns (bool) {
    return userAccess.hasRole(role, sender);
  }

  function isAdmin (address sender) public view returns (bool) {
    return userAccess.hasRole(DEFAULT_ADMIN_ROLE, sender);
  }

  function isAdminOrRole (address sender, bytes32 role) public view returns (bool) {
    return 
      userAccess.hasRole(role, sender) || 
      userAccess.hasRole(DEFAULT_ADMIN_ROLE, sender);
  } 

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Skills/ISkills.sol";
import "./Constants.sol";

abstract contract SkillManager {

  ISkills public skills;

  constructor (address _skills) {
    _setSkills(_skills);
  }

  function _setSkills (address _skills) internal {
    skills = ISkills(_skills);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Items/IItems.sol";

abstract contract ItemManager {

  IItems public items;

  constructor (address _items) {
    _setItems(_items);
  }

  function _setItems (address _items) internal {
    items = IItems(_items);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Randomizer/IRandomizer.sol";

abstract contract RandomManager {

  IRandomizer public randomizer;

  constructor (address _randomizer) {
    _setRandomizer(_randomizer);
  }

  function _setRandomizer (address _randomizer) internal {
    randomizer = IRandomizer(_randomizer);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Tools for Externally Owned Accounts

abstract contract EOA {
  modifier onlyEOA () {
    require(_isEOA(msg.sender), 'EOA_UNAUTHORIZED');
    _;
  }

  function _isEOA (address sender) internal view returns (bool) {
    return sender == tx.origin;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Probable {

  uint baseChance = 1 gwei;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint8 constant TT_ERC20 = 1;
uint8 constant TT_ERC721 = 2;
uint8 constant TT_ERC1155 = 3;

struct ContractMeta {
  address addr;
  bool active;
  uint8 tokenType;
}

struct UserToken {
  uint contractId;
  uint tokenId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant BURNER_ROLE = keccak256("BURNER_ROLE");
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00; // from AccessControl

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISkills {
  function experienceOf(uint playerId, uint skillId) external view returns (uint);
  function validSkill (uint skillId) external view returns (bool);
  function addExperience (uint playerId, uint skillId, uint32 experience) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint constant SKILL_COOKING = 0;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IItems is IERC1155 {
  function mint(address, uint, uint) external;
  function burn(address, uint, uint) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
pragma solidity ^0.8.0;

interface IRandomizer {

    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns(uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns(bool);
}