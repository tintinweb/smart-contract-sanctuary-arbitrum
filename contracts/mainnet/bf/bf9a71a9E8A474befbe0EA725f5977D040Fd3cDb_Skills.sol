// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";
import "./Constants.sol";

import "../UserAccessible/UserAccessible.sol";

contract Skills is
  UserAccessible
{

  Skill[] skills;

  mapping (uint => mapping (uint => PlayerSkill)) playerToSkill;

  event ExperienceAdded (uint playerId, uint skillId, uint added, uint total);

  constructor(
    address _userAccess
  )
    UserAccessible(_userAccess)
  {}

  function experienceOfBatch (uint[] calldata playerIds, uint[] calldata skillIds) public view returns (uint[] memory) {
    require(playerIds.length == skillIds.length, 'NON_EQUAL_LENGTH');
    uint[] memory exps = new uint[](playerIds.length);
    for (uint i = 0; i < playerIds.length; i++) {
      exps[i] = playerToSkill[playerIds[i]][skillIds[i]].experience;
    }
    return exps;
  }

  function experienceOf(uint playerId, uint skillId) public view returns (uint) {
    return playerToSkill[playerId][skillId].experience;
  }

  function validSkill (uint skillId) public view returns (bool) {
    return skills[skillId].active;
  }

  function numberOfSkills () public view returns (uint) { 
    return skills.length; 
  }

  function getSkill (uint skillId) public view returns (Skill memory) {
    return skills[skillId];
  }

  function addSkill (bool active) public adminOrRole(SKILL_MANAGER) {
    skills.push(Skill({
      active: active
    }));
  }

  function updateSkill (uint skillId, bool active) public adminOrRole(SKILL_MANAGER) {
    skills[skillId].active = active;
  }

  function addExperience (uint playerId, uint skillId, uint32 experience) 
    public 
    adminOrRole(MINT_EXPERIENCE) 
  {
    PlayerSkill storage player = playerToSkill[playerId][skillId];
    player.experience += experience;
    emit ExperienceAdded(playerId, skillId, experience, player.experience);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct PlayerSkill {
  uint32 experience;
}

struct Skill {
  bool active;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

bytes32 constant SKILL_MANAGER = keccak256("SKILL_MANAGER");
bytes32 constant MINT_EXPERIENCE = keccak256("MINT_EXPERIENCE");

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