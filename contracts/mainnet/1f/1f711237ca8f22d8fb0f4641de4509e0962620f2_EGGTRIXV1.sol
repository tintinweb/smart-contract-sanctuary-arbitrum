//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";

import "../UserAccessible/UserAccessible.sol";
import "../LocationManager/LocationManager.sol";
import "../VaultManager/VaultManager.sol";
import "../KitchenManager/KitchenManager.sol";
import "../Probable/Probable.sol";
import "../EOA/EOA.sol";

import "./Constants.sol";

/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMKkkkkkKMMMMMMMMMMMMWKkKWMMMMMMMMMMMMMWKkKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMWk;.   ;xkkkkkkkkkkkx; ;xkkkkkkkkKWMMMWl.;xkkkkkkkkKWMWKkxkkkkkkKWMMMMMMMMMWKkkkkkkkkkkkKMMMKkkkkkkkkkkkkkkkkkkkKWKkkkkkKWMMMM
MMMMNl     .;;;;;;;;;;;.           lWMMMWl           lWMWk:;;.    ;xkkkkKWMMMWl   .;;;;;. lWMWk;.     .;;;;;;;.   lNo   .:kWMMMM
MMMMWl     lNWWWWWWWWWNc .,,,,,,,,;kWMMMWl .,,,,,,,,;kWMMMWWNl      .;;:kWMMMWl   lNWWWNc lWMMWNl     lNWWWWWNl   ,d,   lNWMMMMM
MMMMWl     ,xkkkkKWMMMWl lNWW0xxxxxxkkkkx, lNWW0xxxxxKMMMMMMWl      lNWWWMMMMWl   ,xkkkx, lWMMMWl     lWMMMMMWk;.   .,,;kWMMMMMM
MMMMWl           lWMMMWl lWMWl     .;;;;;. lWMWl     lWMMMMMWl      lWMMMMMMMWl         .;kWMMMWl     lWMMMMMMWNl   lNWWMMMMMMMM
MMMMWl     .,,,,;kWMMMWl lWMWl     lNWWWNc lWMWl     lWMMMMMWl      lWMMMMMMMWl   .,,,. lNWMMMMWl     lWMMMMMMKx,   ,xkkKMMMMMMM
MMMMWl     lNWWWWMMMMMWl lWMWl     lWMMMWl lWMWl     lWMMMMMWl      lWMMMMMMMWl   lNWNc lWMMMMMWl     lWMMMMMWl   .,.   lWMMMMMM
MMMMWl     ,xkkkkkkKMMWl ,xkx,     lWMMMWl ,xkx,     ,xkkkkkx,      ,xkkkkkkkx,   lWMWl ,xkkkkkx,     ,xKWMWKx,   lXl   ,xKWMMMM
MMMMWk;,,,,;;;;;;;:kWMWk;;;;;;,,,,;kWMMMWk;;;;;;,,,,,;;;;;;;;;,,,,,,;;;;;;;;;;;,,;kWMWk;;;;;;;;;;,,,,,;:kWMWk:;,,;kNk;,,;:kWMMMM
MMMMMWWWWWWWWWWWWWWMMMMMWWWWWWWWWWWWMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMWWWWWWWWWWWWWWWWWMMMMMWWWWWMMMWWWWWMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

contract EGGTRIXV1 is 
  LocationManager,
  KitchenManager,
  VaultManager,
  Probable,
  UserAccessible,
  EOA,
  Pausable
{
  
  constructor(
    address kitchen,
    address location,
    address tokenVault,
    address userAccess
  ) 
    KitchenManager(kitchen)
    LocationManager(location)
    VaultManager(tokenVault)
    UserAccessible(userAccess)
  {}

  function setContracts (
    address kitchen,
    address location,
    address tokenVault
  )
    public
    adminOrRole(EGGTRIX_ROLE)
    onlyEOA
  {
    _setTokenLocation(location);
    _setKitchen(kitchen);
    _setTokenVault(tokenVault);
  }

  function pause () public adminOrRole(EGGTRIX_ROLE) onlyEOA { _pause(); }
  function unpause () public adminOrRole(EGGTRIX_ROLE) onlyEOA { _unpause(); }

  function withdrawTokens (
    uint[] calldata playerIds
  ) 
    public 
    whenNotPaused
    onlyEOA
  {
    for (uint i = 0; i < playerIds.length; i++) {
      uint playerId = playerIds[i];
      require(location.atLocation(playerId, LOCATION_CHILL), 'BUSY');
      tokenVault.withdrawToken(playerId, msg.sender);
      location.setLocation(playerId, LOCATION_NONE);
    }
  }

  function depositTokens (
    UserToken[] calldata tokens
  ) 
    public 
    whenNotPaused
    onlyEOA
  {
    UserToken memory token;
    uint playerId;
    for (uint i = 0; i < tokens.length; i++) {
      token = tokens[i];
      playerId = tokenVault.resolvePlayerId(token);
      tokenVault.depositToken(token, msg.sender);
      location.setLocation(playerId, LOCATION_CHILL);
    }
  }

  function cook (
    uint[] calldata playerIds, 
    uint[] calldata itemIds
  ) 
    public 
    whenNotPaused
    onlyEOA
  {
    require(playerIds.length == itemIds.length, 'NON_EQUAL_LENGTH');
    for (uint i = 0; i < playerIds.length; i++) {
      uint playerId = playerIds[i];
      requireOwnershipOf(playerId, msg.sender);
      requirePlayableToken(playerId);
      require(location.atLocation(playerId, LOCATION_CHILL), 'BUSY');
      kitchen.cookFor(msg.sender, playerId, itemIds[i]);
      location.setLocation(playerId, LOCATION_KITCHEN);
    }
  }

  function claimFood (
    uint[] calldata playerIds
  ) 
    public 
    whenNotPaused
    onlyEOA
  {
    for (uint i = 0; i < playerIds.length; i++) {
      uint playerId = playerIds[i];
      requireOwnershipOf(playerId, msg.sender);
      requirePlayableToken(playerId);
      require(location.atLocation(playerId, LOCATION_KITCHEN), 'NOT_COOKING');
      kitchen.claimFor(msg.sender, playerId, baseChance);
      location.setLocation(playerId, LOCATION_CHILL);
    }
  }

  function claimFoodAndCook (
    uint[] calldata playerIds,
    uint[] calldata itemIds
  ) 
    public 
    whenNotPaused
    onlyEOA
  {
    require(playerIds.length == itemIds.length, 'NON_EQUAL_LENGTH');
    for (uint i = 0; i < playerIds.length; i++) {
      uint playerId = playerIds[i];
      requireOwnershipOf(playerId, msg.sender);
      requirePlayableToken(playerId);
      require(location.atLocation(playerId, LOCATION_KITCHEN), 'NOT_COOKING');
      kitchen.claimFor(msg.sender, playerId, baseChance);
      kitchen.cookFor(msg.sender, playerId, itemIds[i]);
    }
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

import "../TokenLocation/ITokenLocation.sol";

abstract contract LocationManager {

  ITokenLocation public location;

  constructor (address _tokenLocation) {
    _setTokenLocation(_tokenLocation);
  }

  function _setTokenLocation (address _tokenLocation) internal {
    location = ITokenLocation(_tokenLocation);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TokenVault/ITokenVault.sol";

abstract contract VaultManager {

  ITokenVault public tokenVault;

  constructor (address _tokenVault) {
    _setTokenVault(_tokenVault);
  }

  function requireDepositableToken (UserToken memory token) internal view {
    require(tokenVault.depositableToken(token), 'UNAUTH_DEPOSIT');
  }

  function requirePlayableToken (uint playerId) internal view {
    require(tokenVault.playableToken(playerId), 'TOKEN_UNPLAYABLE');
  }

  function requireOwnershipOf (uint playerId, address owner) internal view {
    require(_ownsToken(playerId, owner),'NOT_OWNER');
  }

  function _ownsToken (uint playerId, address owner) view internal returns (bool) {
    return tokenVault.ownerOf(playerId) == owner;
  }

  function _setTokenVault (address _tokenVault) internal {
    tokenVault = ITokenVault(_tokenVault);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Kitchen/IKitchen.sol";

abstract contract KitchenManager {

  IKitchen public kitchen;

  constructor (address _kitchen) {
    _setKitchen(_kitchen);
  }

  function _setKitchen (address _kitchen) internal {
    kitchen = IKitchen(_kitchen);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Probable {

  uint baseChance = 1 gwei;

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

bytes32 constant EGGTRIX_ROLE = keccak256("EGGTRIX_ROLE");

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IUserAccess is IAccessControl {
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant BURNER_ROLE = keccak256("BURNER_ROLE");
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00; // from AccessControl

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

import "../TokenAccess/Types.sol";
import "./Constants.sol";

interface ITokenLocation {
  function playerAtLocationByIndex (uint locationId, uint index) external view returns (uint);
  function playersAtLocation (uint locationId) external view returns (uint);
  function setLocation (uint playerId, uint locationId) external;
  function atLocation (uint playerId, uint locationId) external view returns (bool);
  function locationOf (uint playerId) external view returns (uint);
  function locationSince (uint playerId) external view returns (uint);
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

uint constant LOCATION_NONE = 0;
uint constant LOCATION_CHILL = 1;
uint constant LOCATION_FAUCET = 2;
uint constant LOCATION_KITCHEN = 3;

bytes32 constant LOCATION_ROLE = keccak256("LOCATION_ROLE");

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./Types.sol";

interface ITokenVault is IERC721Enumerable {
  function withdrawToken (uint playerId, address to) external;
  function depositToken (UserToken memory token, address from) external;
  function resolveToken (uint) external view returns (UserToken memory);
  function resolvePlayerId (UserToken memory token) external view returns (uint);
  function playableToken (uint playerId) external view returns (bool);
  function depositableToken (UserToken memory) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TokenAccess/Types.sol";

struct VaultInfo {
  uint start; // start of tokenIds
  uint size; // size of collection in case of overflow
  uint deposits; // number of deposits
  uint depositSpots; // max number of deposits
}

struct PlayerToken {
  UserToken token;
  bool active;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Constants.sol";
import "./Types.sol";

interface IKitchen {
  function cookFor (address from, uint playerId, uint itemId) external;
  function claimFor (address from, uint playerId, uint boostFactor) external;
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