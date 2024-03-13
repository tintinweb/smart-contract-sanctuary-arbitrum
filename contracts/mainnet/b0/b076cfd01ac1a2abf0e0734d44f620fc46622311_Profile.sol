// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// ██████╗  █████╗  ██████╗     ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗
// ██╔══██╗██╔══██╗██╔═══██╗    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝
// ██║  ██║███████║██║   ██║    ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗
// ██║  ██║██╔══██║██║   ██║    ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝
// ██████╔╝██║  ██║╚██████╔╝    ██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗
// ╚═════╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝
////////////////////////////////////////////////////////////////////////////////////
//                   DAO Profile. Designed and coded by @s0wcy.                   //
////////////////////////////////////////////////////////////////////////////////////

// Imports
import '@openzeppelin/contracts/access/AccessControl.sol';

// Interfaces
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './interfaces/IProfile.sol';

/**
 * @title Profile
 * @author https://x.com/s0wcy
 * @dev Implements profile management for DAO users including avatar association and custom user information.
 *      Profiles are identified by Ethereum addresses. Each profile can have a username, an avatar, and a set of predefined information keys.
 *      This contract utilizes OpenZeppelin's AccessControl for role management, allowing specific actions to be restricted to administrators.
 *
 *      Avatar #0 is the default avatar for every profile.
 *      It should be owned by an admin to change default look for all new profiles.
 *      See Avatar contract for more details about Avatar #0 mint.
 */
contract Profile is AccessControl {
  ////////////////////////
  ///     CONSTANTS    ///
  ////////////////////////
  bytes32 public constant PROFILE_ADMIN_ROLE = keccak256('PROFILE_ADMIN_ROLE');

  ////////////////////////
  ///     VARIABLES    ///
  ////////////////////////
  string[] public registeredInfoKeys;

  ////////////////////////
  ///     MAPPINGS     ///
  ////////////////////////
  mapping(address => bool) public isValidAvatar;
  mapping(string => bool) public isUsernameUsed;
  mapping(address => string) private addressToUsername;
  mapping(address => address) private addressToAvatarAddress;
  mapping(address => uint) private addressToAvatarId;
  mapping(string => bool) private isValidInfoKey;
  mapping(address => mapping(string => string)) private addressToInfo;
  mapping(address => uint) private addressToCreation;

  ////////////////////////
  ///    INITIALIZE    ///
  ////////////////////////
  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PROFILE_ADMIN_ROLE, msg.sender);

    addInfoKey('description');
    addInfoKey('location');
    addInfoKey('banner');
    addInfoKey('x');
    addInfoKey('instagram');
    addInfoKey('telegram');
  }

  ////////////////////////
  ///      EVENTS      ///
  ////////////////////////
  event CreateProfile(string username, address avatarAddress, uint avatarId, string[] infoKeys, string[] infoValues);
  event UpdateUsername(string username, address profile);
  event UpdateAvatar(address avatarAddress, uint avatarId, address profile);
  event UpdateInfo(string[] infoKeys, string[] infoValues, address profile);
  event AddInfoKey(string infoKey);
  event RemoveInfoKey(string infoKey);

  ////////////////////////
  ///      PUBLIC      ///
  ////////////////////////

  /**
   * @dev Allows a user to create a profile with specified username, avatar, and information.
   *      Emits a {CreateProfile} event.
   * @param _username The username for the profile.
   * @param _avatarAddress The avatar address for the profile. Must be registered.
   * @param _avatarId The avatar ID for the profile. Must be owned by the caller if not 0.
   * @param _infoKeys An array of information keys to be added.
   * @param _infoValues An array of information values corresponding to the keys.
   */
  function createProfile(
    string memory _username,
    address _avatarAddress,
    uint _avatarId,
    string[] memory _infoKeys,
    string[] memory _infoValues
  ) public {
    // Check
    require(addressToCreation[msg.sender] == 0, 'Profile already exists');
    require(_infoKeys.length == _infoValues.length, 'Info arrays length mismatch');

    // Username
    require(!isUsernameUsed[_username], 'Username already used');
    addressToUsername[msg.sender] = _username;
    isUsernameUsed[_username] = true;

    // Avatar
    if (_avatarAddress != address(0)) {
      // Check
      require(isValidAvatar[_avatarAddress], 'Invalid avatar');
      require(IERC721(_avatarAddress).ownerOf(_avatarId) == msg.sender, 'Avatar not owned');

      // Update
      addressToAvatarAddress[msg.sender] = _avatarAddress;
      addressToAvatarId[msg.sender] = _avatarId;
    } else {
      // Update
      addressToAvatarAddress[msg.sender] = address(0);
      addressToAvatarId[msg.sender] = 0;
    }

    // Infos
    for (uint i = 0; i < _infoKeys.length; i++) {
      // Check
      require(isValidInfoKey[_infoKeys[i]], 'Invalid info');

      // Update
      addressToInfo[msg.sender][_infoKeys[i]] = _infoValues[i];
    }

    // Creation
    addressToCreation[msg.sender] = block.timestamp;

    // Event
    emit CreateProfile(_username, _avatarAddress, _avatarId, _infoKeys, _infoValues);
  }

  /**
   * @dev Allows a user or an admin to update the username of a profile.
   *      Emits an {UpdateUsername} event.
   * @param _profile The address of the profile to update.
   * @param _username The new username for the profile.
   */
  function updateUsername(address _profile, string memory _username) public {
    // Check
    require(addressToCreation[msg.sender] != 0, 'Profile does not exists');
    require(!isUsernameUsed[_username], 'Username already used');
    if (!hasRole(PROFILE_ADMIN_ROLE, msg.sender)) {
      require(msg.sender == _profile, 'Wrong profile');
    }

    // Update
    isUsernameUsed[addressToUsername[_profile]] = false;
    addressToUsername[_profile] = _username;
    isUsernameUsed[_username] = true;

    // Event
    emit UpdateUsername(_username, _profile);
  }

  /**
   * @dev Allows a user to update the avatar of their profile.
   *      Emits an {UpdateAvatar} event.
   * @param _avatarAddress New avatar address for the profile.
   * @param _avatarId New avatar ID for the profile.
   */
  function updateAvatar(address _avatarAddress, uint _avatarId) public {
    // Check
    require(addressToCreation[msg.sender] != 0, 'Profile does not exists');

    if (_avatarAddress != address(0)) {
      // Check
      require(isValidAvatar[_avatarAddress], 'Invalid avatar');
      require(IERC721(_avatarAddress).ownerOf(_avatarId) == msg.sender, 'Avatar not owned');

      // Update
      addressToAvatarAddress[msg.sender] = _avatarAddress;
      addressToAvatarId[msg.sender] = _avatarId;
    } else {
      addressToAvatarAddress[msg.sender] = address(0);
      addressToAvatarId[msg.sender] = 0;
    }

    // Event
    emit UpdateAvatar(_avatarAddress, _avatarId, msg.sender);
  }

  /**
   * @dev Allows a user or an admin to update the custom information of a profile.
   *      Emits an {UpdateInfo} event.
   * @param _profile The address of the profile to update.
   * @param _infoKeys An array of information keys to be updated.
   * @param _infoValues An array of information values corresponding to the keys.
   */
  function updateInfo(address _profile, string[] memory _infoKeys, string[] memory _infoValues) public {
    // Check
    require(addressToCreation[msg.sender] != 0, 'Profile does not exists');
    require(_infoKeys.length == _infoValues.length, 'Info arrays length mismatch');
    if (!hasRole(PROFILE_ADMIN_ROLE, msg.sender)) {
      require(msg.sender == _profile, 'Wrong profile');
    }

    // Update
    for (uint i = 0; i < _infoKeys.length; i++) {
      // Check
      require(isValidInfoKey[_infoKeys[i]], 'Info not registered');

      // Update
      addressToInfo[_profile][_infoKeys[i]] = _infoValues[i];
    }

    // Event
    emit UpdateInfo(_infoKeys, _infoValues, _profile);
  }

  /**
   * @dev Retrieves the complete information of a profile.
   * @param _profile The address of the profile to retrieve.
   * @return username The username of the profile.
   * @return avatarAddress The avatar address of the profile.
   * @return avatarId The avatar ID of the profile.
   * @return infoKeys An array of information keys of the profile.
   * @return infoValues An array of information values corresponding to the keys.
   * @return creation The timestamp when the profile was created.
   */
  function getProfile(
    address _profile
  )
    public
    view
    returns (
      string memory username,
      address avatarAddress,
      uint avatarId,
      string[] memory infoKeys,
      string[] memory infoValues,
      uint creation
    )
  {
    // Check
    require(addressToCreation[_profile] != 0, 'Profile not registered');

    // Avatar
    try IERC721(addressToAvatarAddress[_profile]).ownerOf(addressToAvatarId[_profile]) returns (address avatarOwner) {
      if (avatarOwner == _profile) {
        avatarAddress = addressToAvatarAddress[_profile];
        avatarId = addressToAvatarId[_profile];
      }
    } catch {}

    // Info
    string[] memory info = new string[](registeredInfoKeys.length);
    for (uint i = 0; i < registeredInfoKeys.length; i++) {
      info[i] = addressToInfo[_profile][registeredInfoKeys[i]];
    }

    // Return
    return (addressToUsername[_profile], avatarAddress, avatarId, registeredInfoKeys, info, addressToCreation[_profile]);
  }

  /**
   * @dev Returns the total number of registered information keys.
   * @return length The total number of registered information keys.
   */
  function infoKeysLength() public view returns (uint length) {
    return registeredInfoKeys.length;
  }

  ////////////////////////
  ///       ADMIN      ///
  ////////////////////////
  /**
   * @dev Allows an admin to add a new information key to the system.
   *      Emits an {AddInfoKey} event.
   * @param _infoKey The information key to add.
   */
  function addInfoKey(string memory _infoKey) public onlyRole(PROFILE_ADMIN_ROLE) {
    // Check
    require(!isValidInfoKey[_infoKey], 'Key already added');

    // Update
    registeredInfoKeys.push(_infoKey);
    isValidInfoKey[_infoKey] = true;

    // Event
    emit AddInfoKey(_infoKey);
  }

  /**
   * @dev Allows an admin to remove an information key from the system.
   *      Emits a {RemoveInfoKey} event.
   * @param _infoKey The information key to remove.
   */
  function removeInfoKey(string memory _infoKey) public onlyRole(PROFILE_ADMIN_ROLE) {
    // Check
    require(isValidInfoKey[_infoKey], 'Key already removed');

    // Loop
    bool found = false;
    for (uint i = 0; i < registeredInfoKeys.length; i++) {
      if (keccak256(abi.encodePacked(registeredInfoKeys[i])) == keccak256(abi.encodePacked(_infoKey))) {
        // Update
        registeredInfoKeys[i] = registeredInfoKeys[registeredInfoKeys.length - 1];
        registeredInfoKeys.pop();
        found = true;
        break;
      }
    }

    // Check
    require(found, 'Key already removed');

    // Update
    isValidInfoKey[_infoKey] = false;

    // Event
    emit RemoveInfoKey(_infoKey);
  }

  /**
   * @dev Allows an admin to change the Avatar contract address.
   * @param _avatarAddress The new address of the Avatar contract.
   */
  function setValidAvatarAddress(address _avatarAddress, bool _valid) public onlyRole(PROFILE_ADMIN_ROLE) {
    // Check
    IERC721 newAvatar = IERC721(_avatarAddress);
    require(newAvatar.supportsInterface(type(IERC721).interfaceId), 'Incompatible Avatar');

    // Update
    isValidAvatar[_avatarAddress] = _valid;
  }

  ////////////////////////
  ///  IMPLEMENTATIONS ///
  ////////////////////////
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
    return interfaceId == type(IProfile).interfaceId || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
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
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC-721 compliant contract.
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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC-721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC-721
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

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
pragma solidity ^0.8.23;

// ██████╗  █████╗  ██████╗     ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗
// ██╔══██╗██╔══██╗██╔═══██╗    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝
// ██║  ██║███████║██║   ██║    ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗
// ██║  ██║██╔══██║██║   ██║    ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝
// ██████╔╝██║  ██║╚██████╔╝    ██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗
// ╚═════╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝
////////////////////////////////////////////////////////////////////////////////////
//                   DAO Profile. Designed and coded by @s0wcy.                   //
////////////////////////////////////////////////////////////////////////////////////

/**
 * @title IProfile
 * @author https://x.com/s0wcy
 * @dev Interface for the Profile contract.
 *      For an implementation, see {Profile}.
 */
interface IProfile {
  ////////////////////////
  ///     CONSTANTS    ///
  ////////////////////////
  function PROFILE_ADMIN_ROLE() external view returns (bytes32);

  ////////////////////////
  ///     VARIABLES    ///
  ////////////////////////
  function registeredInfoKeys(uint index) external view returns (string memory);

  ////////////////////////
  ///     MAPPINGS     ///
  ////////////////////////
  function isUsernameUsed(string calldata username) external view returns (bool);

  ////////////////////////
  ///      EVENTS      ///
  ////////////////////////
  event CreateProfile(string username, address avatarAddress, uint avatarId, string[] infoKeys, string[] infoValues);
  event UpdateUsername(string username, address profile);
  event UpdateAvatar(address avatarAddress, uint avatarId, address profile);
  event UpdateInfo(string[] infoKeys, string[] infoValues, address profile);
  event AddInfoKey(string infoKey);
  event RemoveInfoKey(string infoKey);

  ////////////////////////
  ///      PUBLIC      ///
  ////////////////////////
  function createProfile(
    string calldata _username,
    address _avatarAddress,
    uint _avatar,
    string[] calldata _infoKeys,
    string[] calldata _infoValues
  ) external;

  function updateUsername(address _profile, string calldata _username) external;

  function updateAvatar(address _avatarAddress, uint _avatar) external;

  function updateInfo(address _profile, string[] calldata _infoKeys, string[] calldata _infoValues) external;

  function getProfile(
    address _profile
  )
    external
    view
    returns (
      string memory username,
      address avatarAddress,
      uint avatarId,
      string[] memory infoKeys,
      string[] memory infoValues,
      uint creation
    );

  function infoKeysLength() external view returns (uint);

  ////////////////////////
  ///       ADMIN      ///
  ////////////////////////
  function addInfoKey(string calldata _infoKey) external;

  function removeInfoKey(string calldata _infoKey) external;

  function setValidAvatarAddress(address _avatarAddress, bool _valid) external;

  ////////////////////////
  ///  IMPLEMENTATIONS ///
  ////////////////////////
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call. This account bears the admin role (for the granted role).
     * Expected in cases where the role was granted using the internal {AccessControl-_grantRole}.
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
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}