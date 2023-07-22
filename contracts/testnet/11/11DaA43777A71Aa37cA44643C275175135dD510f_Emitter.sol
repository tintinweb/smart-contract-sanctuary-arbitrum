// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { AccessControlEnumerableUpgradeable } from "./AccessControlEnumerableUpgradeable.sol";
import { EnumerableSetUpgradeable } from "../utils/structs/EnumerableSetUpgradeable.sol";

library AccessControlEnumerableStorage {

  struct Layout {

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) _roleMembers;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.AccessControlEnumerable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import { AccessControlEnumerableStorage } from "./AccessControlEnumerableStorage.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    using AccessControlEnumerableStorage for AccessControlEnumerableStorage.Layout;
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return AccessControlEnumerableStorage.layout()._roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return AccessControlEnumerableStorage.layout()._roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        AccessControlEnumerableStorage.layout()._roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        AccessControlEnumerableStorage.layout()._roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { AccessControlUpgradeable } from "./AccessControlUpgradeable.sol";

library AccessControlStorage {

  struct Layout {

    mapping(bytes32 => AccessControlUpgradeable.RoleData) _roles;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.AccessControl');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import { AccessControlStorage } from "./AccessControlStorage.sol";
import "../proxy/utils/Initializable.sol";

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    using AccessControlStorage for AccessControlStorage.Layout;
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return AccessControlStorage.layout()._roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return AccessControlStorage.layout()._roles[role].adminRole;
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        AccessControlStorage.layout()._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            AccessControlStorage.layout()._roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            AccessControlStorage.layout()._roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { OwnableUpgradeable } from "./OwnableUpgradeable.sol";

library OwnableStorage {

  struct Layout {
    address _owner;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Ownable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import { OwnableStorage } from "./OwnableStorage.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    using OwnableStorage for OwnableStorage.Layout;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return OwnableStorage.layout()._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = OwnableStorage.layout()._owner;
        OwnableStorage.layout()._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173Upgradeable {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";
import { InitializableStorage } from "./InitializableStorage.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !InitializableStorage.layout()._initializing;
        require(
            (isTopLevelCall && InitializableStorage.layout()._initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && InitializableStorage.layout()._initialized == 1),
            "Initializable: contract is already initialized"
        );
        InitializableStorage.layout()._initialized = 1;
        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!InitializableStorage.layout()._initializing && InitializableStorage.layout()._initialized < version, "Initializable: contract is already initialized");
        InitializableStorage.layout()._initialized = version;
        InitializableStorage.layout()._initializing = true;
        _;
        InitializableStorage.layout()._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(InitializableStorage.layout()._initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!InitializableStorage.layout()._initializing, "Initializable: contract is initializing");
        if (InitializableStorage.layout()._initialized < type(uint8).max) {
            InitializableStorage.layout()._initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return InitializableStorage.layout()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return InitializableStorage.layout()._initializing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { Initializable } from "./Initializable.sol";

library InitializableStorage {

  struct Layout {
    /*
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 _initialized;

    /*
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool _initializing;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Initializable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { PausableUpgradeable } from "./PausableUpgradeable.sol";

library PausableStorage {

  struct Layout {

    bool _paused;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.Pausable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import { PausableStorage } from "./PausableStorage.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    using PausableStorage for PausableStorage.Layout;
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage.layout()._paused = false;
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
        return PausableStorage.layout()._paused;
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
        PausableStorage.layout()._paused = true;
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
        PausableStorage.layout()._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ReentrancyGuardUpgradeable } from "./ReentrancyGuardUpgradeable.sol";

library ReentrancyGuardStorage {

  struct Layout {

    uint256 _status;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.ReentrancyGuard');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import { ReentrancyGuardStorage } from "./ReentrancyGuardStorage.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
    using ReentrancyGuardStorage for ReentrancyGuardStorage.Layout;
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage.layout()._status = _NOT_ENTERED;
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
        require(ReentrancyGuardStorage.layout()._status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        ReentrancyGuardStorage.layout()._status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        ReentrancyGuardStorage.layout()._status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ERC1155Upgradeable } from "./ERC1155Upgradeable.sol";

library ERC1155Storage {

  struct Layout {

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string _uri;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.ERC1155');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import { ERC1155Storage } from "./ERC1155Storage.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using ERC1155Storage for ERC1155Storage.Layout;
    using AddressUpgradeable for address;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return ERC1155Storage.layout()._uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return ERC1155Storage.layout()._balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return ERC1155Storage.layout()._operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = ERC1155Storage.layout()._balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            ERC1155Storage.layout()._balances[id][from] = fromBalance - amount;
        }
        ERC1155Storage.layout()._balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = ERC1155Storage.layout()._balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                ERC1155Storage.layout()._balances[id][from] = fromBalance - amount;
            }
            ERC1155Storage.layout()._balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        ERC1155Storage.layout()._uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        ERC1155Storage.layout()._balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            ERC1155Storage.layout()._balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = ERC1155Storage.layout()._balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            ERC1155Storage.layout()._balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = ERC1155Storage.layout()._balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                ERC1155Storage.layout()._balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        ERC1155Storage.layout()._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ERC20Upgradeable } from "./ERC20Upgradeable.sol";

library ERC20Storage {

  struct Layout {
    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowances;

    uint256 _totalSupply;

    string _name;
    string _symbol;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.ERC20');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import { ERC20Storage } from "./ERC20Storage.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    using ERC20Storage for ERC20Storage.Layout;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC20Storage.layout()._name = name_;
        ERC20Storage.layout()._symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return ERC20Storage.layout()._name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC20Storage.layout()._symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC20Storage.layout()._totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return ERC20Storage.layout()._balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return ERC20Storage.layout()._allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = ERC20Storage.layout()._balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            ERC20Storage.layout()._balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            ERC20Storage.layout()._balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        ERC20Storage.layout()._totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            ERC20Storage.layout()._balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = ERC20Storage.layout()._balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            ERC20Storage.layout()._balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            ERC20Storage.layout()._totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        ERC20Storage.layout()._allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ERC721Upgradeable } from "./ERC721Upgradeable.sol";

library ERC721Storage {

  struct Layout {

    // Token name
    string _name;

    // Token symbol
    string _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;

    // Mapping owner address to token count
    mapping(address => uint256) _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.ERC721');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import { ERC721Storage } from "./ERC721Storage.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using ERC721Storage for ERC721Storage.Layout;
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC721Storage.layout()._name = name_;
        ERC721Storage.layout()._symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return ERC721Storage.layout()._balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return ERC721Storage.layout()._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721Storage.layout()._symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return ERC721Storage.layout()._tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return ERC721Storage.layout()._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return ERC721Storage.layout()._owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            ERC721Storage.layout()._balances[to] += 1;
        }

        ERC721Storage.layout()._owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete ERC721Storage.layout()._tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            ERC721Storage.layout()._balances[owner] -= 1;
        }
        delete ERC721Storage.layout()._owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete ERC721Storage.layout()._tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            ERC721Storage.layout()._balances[from] -= 1;
            ERC721Storage.layout()._balances[to] += 1;
        }
        ERC721Storage.layout()._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        ERC721Storage.layout()._tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        ERC721Storage.layout()._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                ERC721Storage.layout()._balances[from] -= batchSize;
            }
            if (to != address(0)) {
                ERC721Storage.layout()._balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { ERC721EnumerableUpgradeable } from "./ERC721EnumerableUpgradeable.sol";

library ERC721EnumerableStorage {

  struct Layout {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) _allTokensIndex;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.ERC721Enumerable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import { ERC721EnumerableStorage } from "./ERC721EnumerableStorage.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    using ERC721EnumerableStorage for ERC721EnumerableStorage.Layout;
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return ERC721EnumerableStorage.layout()._ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC721EnumerableStorage.layout()._allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return ERC721EnumerableStorage.layout()._allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        ERC721EnumerableStorage.layout()._ownedTokens[to][length] = tokenId;
        ERC721EnumerableStorage.layout()._ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        ERC721EnumerableStorage.layout()._allTokensIndex[tokenId] = ERC721EnumerableStorage.layout()._allTokens.length;
        ERC721EnumerableStorage.layout()._allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.layout()._ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ERC721EnumerableStorage.layout()._ownedTokens[from][lastTokenIndex];

            ERC721EnumerableStorage.layout()._ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ERC721EnumerableStorage.layout()._ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.layout()._ownedTokensIndex[tokenId];
        delete ERC721EnumerableStorage.layout()._ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721EnumerableStorage.layout()._allTokens.length - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.layout()._allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ERC721EnumerableStorage.layout()._allTokens[lastTokenIndex];

        ERC721EnumerableStorage.layout()._allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ERC721EnumerableStorage.layout()._allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.layout()._allTokensIndex[tokenId];
        ERC721EnumerableStorage.layout()._allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }


    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { EIP712Upgradeable } from "./EIP712Upgradeable.sol";

library EIP712Storage {

  struct Layout {
    /* solhint-disable var-name-mixedcase */
    bytes32 _HASHED_NAME;
    bytes32 _HASHED_VERSION;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzeppelin.contracts.storage.EIP712');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import { EIP712Storage } from "./EIP712Storage.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    using EIP712Storage for EIP712Storage.Layout;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        EIP712Storage.layout()._HASHED_NAME = hashedName;
        EIP712Storage.layout()._HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return EIP712Storage.layout()._HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return EIP712Storage.layout()._HASHED_VERSION;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// Common mathematical functions used in both SD59x18 and UD60x18. Note that these global functions do not
/// always operate with SD59x18 and UD60x18 numbers.

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Emitted when the ending result in the fixed-point version of `mulDiv` would overflow uint256.
error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y);

/// @notice Emitted when the ending result in `mulDiv` would overflow uint256.
error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);

/// @notice Emitted when attempting to run `mulDiv` with one of the inputs `type(int256).min`.
error PRBMath_MulDivSigned_InputTooSmall();

/// @notice Emitted when the ending result in the signed version of `mulDiv` would overflow int256.
error PRBMath_MulDivSigned_Overflow(int256 x, int256 y);

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// @dev The maximum value an uint128 number can have.
uint128 constant MAX_UINT128 = type(uint128).max;

/// @dev The maximum value an uint40 number can have.
uint40 constant MAX_UINT40 = type(uint40).max;

/// @dev How many trailing decimals can be represented.
uint256 constant UNIT = 1e18;

/// @dev Largest power of two that is a divisor of `UNIT`.
uint256 constant UNIT_LPOTD = 262144;

/// @dev The `UNIT` number inverted mod 2^256.
uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

/*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Finds the zero-based index of the first one in the binary representation of x.
/// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
///
/// Each of the steps in this implementation is equivalent to this high-level code:
///
/// ```solidity
/// if (x >= 2 ** 128) {
///     x >>= 128;
///     result += 128;
/// }
/// ```
///
/// Where 128 is swapped with each respective power of two factor. See the full high-level implementation here:
/// https://gist.github.com/PaulRBerg/f932f8693f2733e30c4d479e8e980948
///
/// A list of the Yul instructions used below:
/// - "gt" is "greater than"
/// - "or" is the OR bitwise operator
/// - "shl" is "shift left"
/// - "shr" is "shift right"
///
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return result The index of the most significant bit as an uint256.
function msb(uint256 x) pure returns (uint256 result) {
    // 2^128
    assembly ("memory-safe") {
        let factor := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^64
    assembly ("memory-safe") {
        let factor := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^32
    assembly ("memory-safe") {
        let factor := shl(5, gt(x, 0xFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^16
    assembly ("memory-safe") {
        let factor := shl(4, gt(x, 0xFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^8
    assembly ("memory-safe") {
        let factor := shl(3, gt(x, 0xFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^4
    assembly ("memory-safe") {
        let factor := shl(2, gt(x, 0xF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^2
    assembly ("memory-safe") {
        let factor := shl(1, gt(x, 0x3))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^1
    // No need to shift x any more.
    assembly ("memory-safe") {
        let factor := gt(x, 0x1)
        result := or(result, factor)
    }
}

/// @notice Calculates floor(x*y÷denominator) with full precision.
///
/// @dev Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
///
/// Requirements:
/// - The denominator cannot be zero.
/// - The result must fit within uint256.
///
/// Caveats:
/// - This function does not work with fixed-point numbers.
///
/// @param x The multiplicand as an uint256.
/// @param y The multiplier as an uint256.
/// @param denominator The divisor as an uint256.
/// @return result The result as an uint256.
function mulDiv(uint256 x, uint256 y, uint256 denominator) pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
        unchecked {
            return prod0 / denominator;
        }
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
        revert PRBMath_MulDiv_Overflow(x, y, denominator);
    }

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly ("memory-safe") {
        // Compute remainder using the mulmod Yul instruction.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512 bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
    // See https://cs.stackexchange.com/q/138556/92363.
    unchecked {
        // Does not overflow because the denominator cannot be zero at this stage in the function.
        uint256 lpotdod = denominator & (~denominator + 1);
        assembly ("memory-safe") {
            // Divide denominator by lpotdod.
            denominator := div(denominator, lpotdod)

            // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

            // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
            lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * lpotdod;

        // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
        // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
        // four bits. That is, denominator * inv = 1 mod 2^4.
        uint256 inverse = (3 * denominator) ^ 2;

        // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
        // in modular arithmetic, doubling the correct bits in each step.
        inverse *= 2 - denominator * inverse; // inverse mod 2^8
        inverse *= 2 - denominator * inverse; // inverse mod 2^16
        inverse *= 2 - denominator * inverse; // inverse mod 2^32
        inverse *= 2 - denominator * inverse; // inverse mod 2^64
        inverse *= 2 - denominator * inverse; // inverse mod 2^128
        inverse *= 2 - denominator * inverse; // inverse mod 2^256

        // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
        // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
        // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inverse;
    }
}

/// @notice Calculates floor(x*y÷1e18) with full precision.
///
/// @dev Variant of `mulDiv` with constant folding, i.e. in which the denominator is always 1e18. Before returning the
/// final result, we add 1 if `(x * y) % UNIT >= HALF_UNIT`. Without this adjustment, 6.6e-19 would be truncated to 0
/// instead of being rounded to 1e-18. See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
///
/// Requirements:
/// - The result must fit within uint256.
///
/// Caveats:
/// - The body is purposely left uncommented; to understand how this works, see the NatSpec comments in `mulDiv`.
/// - It is assumed that the result can never be `type(uint256).max` when x and y solve the following two equations:
///     1. x * y = type(uint256).max * UNIT
///     2. (x * y) % UNIT >= UNIT / 2
///
/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
function mulDiv18(uint256 x, uint256 y) pure returns (uint256 result) {
    uint256 prod0;
    uint256 prod1;
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    if (prod1 >= UNIT) {
        revert PRBMath_MulDiv18_Overflow(x, y);
    }

    uint256 remainder;
    assembly ("memory-safe") {
        remainder := mulmod(x, y, UNIT)
    }

    if (prod1 == 0) {
        unchecked {
            return prod0 / UNIT;
        }
    }

    assembly ("memory-safe") {
        result := mul(
            or(
                div(sub(prod0, remainder), UNIT_LPOTD),
                mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
            ),
            UNIT_INVERSE
        )
    }
}

/// @notice Calculates floor(x*y÷denominator) with full precision.
///
/// @dev An extension of `mulDiv` for signed numbers. Works by computing the signs and the absolute values separately.
///
/// Requirements:
/// - None of the inputs can be `type(int256).min`.
/// - The result must fit within int256.
///
/// @param x The multiplicand as an int256.
/// @param y The multiplier as an int256.
/// @param denominator The divisor as an int256.
/// @return result The result as an int256.
function mulDivSigned(int256 x, int256 y, int256 denominator) pure returns (int256 result) {
    if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
        revert PRBMath_MulDivSigned_InputTooSmall();
    }

    // Get hold of the absolute values of x, y and the denominator.
    uint256 absX;
    uint256 absY;
    uint256 absD;
    unchecked {
        absX = x < 0 ? uint256(-x) : uint256(x);
        absY = y < 0 ? uint256(-y) : uint256(y);
        absD = denominator < 0 ? uint256(-denominator) : uint256(denominator);
    }

    // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
    uint256 rAbs = mulDiv(absX, absY, absD);
    if (rAbs > uint256(type(int256).max)) {
        revert PRBMath_MulDivSigned_Overflow(x, y);
    }

    // Get the signs of x, y and the denominator.
    uint256 sx;
    uint256 sy;
    uint256 sd;
    assembly ("memory-safe") {
        // This works thanks to two's complement.
        // "sgt" stands for "signed greater than" and "sub(0,1)" is max uint256.
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
        sd := sgt(denominator, sub(0, 1))
    }

    // XOR over sx, sy and sd. What this does is to check whether there are 1 or 3 negative signs in the inputs.
    // If there are, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
/// @dev Has to use 192.64-bit fixed-point numbers.
/// See https://ethereum.stackexchange.com/a/96594/24693.
/// @param x The exponent as an unsigned 192.64-bit fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
function prbExp2(uint256 x) pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
        // because the initial result is 2^191 and all magic factors are less than 2^65.
        if (x & 0xFF00000000000000 > 0) {
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
        }

        if (x & 0xFF000000000000 > 0) {
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
        }

        if (x & 0xFF0000000000 > 0) {
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
        }

        if (x & 0xFF00000000 > 0) {
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
        }

        if (x & 0xFF00000000 > 0) {
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
        }

        if (x & 0xFF0000 > 0) {
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
        }

        if (x & 0xFF00 > 0) {
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
        }

        if (x & 0xFF > 0) {
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
        }

        // We're doing two things at the same time:
        //
        //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
        //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
        //      rather than 192.
        //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
        //
        // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
        result *= UNIT;
        result >>= (191 - (x >> 64));
    }
}

/// @notice Calculates the square root of x, rounding down if x is not a perfect square.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
/// Credits to OpenZeppelin for the explanations in code comments below.
///
/// Caveats:
/// - This function does not work with fixed-point numbers.
///
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as an uint256.
function prbSqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of x.
    //
    // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
    //
    // $$
    // msb(x) <= x <= 2*msb(x)$
    // $$
    //
    // We write $msb(x)$ as $2^k$ and we get:
    //
    // $$
    // k = log_2(x)
    // $$
    //
    // Thus we can write the initial inequality as:
    //
    // $$
    // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1} \\
    // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1}) \\
    // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
    // $$
    //
    // Consequently, $2^{log_2(x) /2}` is a good first approximation of sqrt(x) with at least one correct bit.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 2 ** 128) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 2 ** 64) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 2 ** 32) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 2 ** 16) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 2 ** 8) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 2 ** 4) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 2 ** 2) {
        result <<= 1;
    }

    // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
    // most 128 bits, since  it is the square root of a uint256. Newton's method converges quadratically (precision
    // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
    // precision into the expected uint128 result.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;

        // Round down the result in case x is not a perfect square.
        uint256 roundedDownResult = x / result;
        if (result >= roundedDownResult) {
            result = roundedDownResult;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT40 } from "../Common.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import {
    PRBMath_SD1x18_ToUD2x18_Underflow,
    PRBMath_SD1x18_ToUD60x18_Underflow,
    PRBMath_SD1x18_ToUint128_Underflow,
    PRBMath_SD1x18_ToUint256_Underflow,
    PRBMath_SD1x18_ToUint40_Overflow,
    PRBMath_SD1x18_ToUint40_Underflow
} from "./Errors.sol";
import { SD1x18 } from "./ValueType.sol";

/// @notice Casts an SD1x18 number into SD59x18.
/// @dev There is no overflow check because the domain of SD1x18 is a subset of SD59x18.
function intoSD59x18(SD1x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(SD1x18.unwrap(x)));
}

/// @notice Casts an SD1x18 number into UD2x18.
/// - x must be positive.
function intoUD2x18(SD1x18 x) pure returns (UD2x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUD2x18_Underflow(x);
    }
    result = UD2x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD1x18 x) pure returns (UD60x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD1x18 x) pure returns (uint256 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUint256_Underflow(x);
    }
    result = uint256(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
function intoUint128(SD1x18 x) pure returns (uint128 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUint128_Underflow(x);
    }
    result = uint128(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD1x18 x) pure returns (uint40 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUint40_Underflow(x);
    }
    if (xInt > int64(uint64(MAX_UINT40))) {
        revert PRBMath_SD1x18_ToUint40_Overflow(x);
    }
    result = uint40(uint64(xInt));
}

/// @notice Alias for the `wrap` function.
function sd1x18(int64 x) pure returns (SD1x18 result) {
    result = wrap(x);
}

/// @notice Unwraps an SD1x18 number into int64.
function unwrap(SD1x18 x) pure returns (int64 result) {
    result = SD1x18.unwrap(x);
}

/// @notice Wraps an int64 number into the SD1x18 value type.
function wrap(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SD1x18 } from "./ValueType.sol";

/// @dev Euler's number as an SD1x18 number.
SD1x18 constant E = SD1x18.wrap(2_718281828459045235);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMAX_SD1x18 = 9_223372036854775807;
SD1x18 constant MAX_SD1x18 = SD1x18.wrap(uMAX_SD1x18);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMIN_SD1x18 = -9_223372036854775808;
SD1x18 constant MIN_SD1x18 = SD1x18.wrap(uMIN_SD1x18);

/// @dev PI as an SD1x18 number.
SD1x18 constant PI = SD1x18.wrap(3_141592653589793238);

/// @dev The unit amount that implies how many trailing decimals can be represented.
SD1x18 constant UNIT = SD1x18.wrap(1e18);
int256 constant uUNIT = 1e18;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SD1x18 } from "./ValueType.sol";

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in UD2x18.
error PRBMath_SD1x18_ToUD2x18_Underflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in UD60x18.
error PRBMath_SD1x18_ToUD60x18_Underflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in uint128.
error PRBMath_SD1x18_ToUint128_Underflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in uint256.
error PRBMath_SD1x18_ToUint256_Underflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Overflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Underflow(SD1x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Casting.sol" as C;

/// @notice The signed 1.18-decimal fixed-point number representation, which can have up to 1 digit and up to 18 decimals.
/// The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity type int64.
/// This is useful when end users want to use int64 to save gas, e.g. with tight variable packing in contract storage.
type SD1x18 is int64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using { C.intoSD59x18, C.intoUD2x18, C.intoUD60x18, C.intoUint256, C.intoUint128, C.intoUint40, C.unwrap } for SD1x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18, uMIN_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import {
    PRBMath_SD59x18_IntoSD1x18_Overflow,
    PRBMath_SD59x18_IntoSD1x18_Underflow,
    PRBMath_SD59x18_IntoUD2x18_Overflow,
    PRBMath_SD59x18_IntoUD2x18_Underflow,
    PRBMath_SD59x18_IntoUD60x18_Underflow,
    PRBMath_SD59x18_IntoUint128_Overflow,
    PRBMath_SD59x18_IntoUint128_Underflow,
    PRBMath_SD59x18_IntoUint256_Underflow,
    PRBMath_SD59x18_IntoUint40_Overflow,
    PRBMath_SD59x18_IntoUint40_Underflow
} from "./Errors.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Casts an SD59x18 number into int256.
/// @dev This is basically a functional alias for the `unwrap` function.
function intoInt256(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Casts an SD59x18 number into SD1x18.
/// @dev Requirements:
/// - x must be greater than or equal to `uMIN_SD1x18`.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(SD59x18 x) pure returns (SD1x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < uMIN_SD1x18) {
        revert PRBMath_SD59x18_IntoSD1x18_Underflow(x);
    }
    if (xInt > uMAX_SD1x18) {
        revert PRBMath_SD59x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xInt));
}

/// @notice Casts an SD59x18 number into UD2x18.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(SD59x18 x) pure returns (UD2x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUD2x18_Underflow(x);
    }
    if (xInt > int256(uint256(uMAX_UD2x18))) {
        revert PRBMath_SD59x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(uint256(xInt)));
}

/// @notice Casts an SD59x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD59x18 x) pure returns (UD60x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD59x18 x) pure returns (uint256 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUint256_Underflow(x);
    }
    result = uint256(xInt);
}

/// @notice Casts an SD59x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UINT128`.
function intoUint128(SD59x18 x) pure returns (uint128 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUint128_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT128))) {
        revert PRBMath_SD59x18_IntoUint128_Overflow(x);
    }
    result = uint128(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD59x18 x) pure returns (uint40 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUint40_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT40))) {
        revert PRBMath_SD59x18_IntoUint40_Overflow(x);
    }
    result = uint40(uint256(xInt));
}

/// @notice Alias for the `wrap` function.
function sd(int256 x) pure returns (SD59x18 result) {
    result = wrap(x);
}

/// @notice Alias for the `wrap` function.
function sd59x18(int256 x) pure returns (SD59x18 result) {
    result = wrap(x);
}

/// @notice Unwraps an SD59x18 number into int256.
function unwrap(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Wraps an int256 number into the SD59x18 value type.
function wrap(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SD59x18 } from "./ValueType.sol";

/// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as an SD59x18 number.
SD59x18 constant E = SD59x18.wrap(2_718281828459045235);

/// @dev Half the UNIT number.
int256 constant uHALF_UNIT = 0.5e18;
SD59x18 constant HALF_UNIT = SD59x18.wrap(uHALF_UNIT);

/// @dev log2(10) as an SD59x18 number.
int256 constant uLOG2_10 = 3_321928094887362347;
SD59x18 constant LOG2_10 = SD59x18.wrap(uLOG2_10);

/// @dev log2(e) as an SD59x18 number.
int256 constant uLOG2_E = 1_442695040888963407;
SD59x18 constant LOG2_E = SD59x18.wrap(uLOG2_E);

/// @dev The maximum value an SD59x18 number can have.
int256 constant uMAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_792003956564819967;
SD59x18 constant MAX_SD59x18 = SD59x18.wrap(uMAX_SD59x18);

/// @dev The maximum whole value an SD59x18 number can have.
int256 constant uMAX_WHOLE_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MAX_WHOLE_SD59x18 = SD59x18.wrap(uMAX_WHOLE_SD59x18);

/// @dev The minimum value an SD59x18 number can have.
int256 constant uMIN_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_792003956564819968;
SD59x18 constant MIN_SD59x18 = SD59x18.wrap(uMIN_SD59x18);

/// @dev The minimum whole value an SD59x18 number can have.
int256 constant uMIN_WHOLE_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MIN_WHOLE_SD59x18 = SD59x18.wrap(uMIN_WHOLE_SD59x18);

/// @dev PI as an SD59x18 number.
SD59x18 constant PI = SD59x18.wrap(3_141592653589793238);

/// @dev The unit amount that implies how many trailing decimals can be represented.
int256 constant uUNIT = 1e18;
SD59x18 constant UNIT = SD59x18.wrap(1e18);

/// @dev Zero as an SD59x18 number.
SD59x18 constant ZERO = SD59x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SD59x18 } from "./ValueType.sol";

/// @notice Emitted when taking the absolute value of `MIN_SD59x18`.
error PRBMath_SD59x18_Abs_MinSD59x18();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMath_SD59x18_Ceil_Overflow(SD59x18 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMath_SD59x18_Convert_Overflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMath_SD59x18_Convert_Underflow(int256 x);

/// @notice Emitted when dividing two numbers and one of them is `MIN_SD59x18`.
error PRBMath_SD59x18_Div_InputTooSmall();

/// @notice Emitted when dividing two numbers and one of the intermediary unsigned results overflows SD59x18.
error PRBMath_SD59x18_Div_Overflow(SD59x18 x, SD59x18 y);

/// @notice Emitted when taking the natural exponent of a base greater than 133.084258667509499441.
error PRBMath_SD59x18_Exp_InputTooBig(SD59x18 x);

/// @notice Emitted when taking the binary exponent of a base greater than 192.
error PRBMath_SD59x18_Exp2_InputTooBig(SD59x18 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMath_SD59x18_Floor_Underflow(SD59x18 x);

/// @notice Emitted when taking the geometric mean of two numbers and their product is negative.
error PRBMath_SD59x18_Gm_NegativeProduct(SD59x18 x, SD59x18 y);

/// @notice Emitted when taking the geometric mean of two numbers and multiplying them overflows SD59x18.
error PRBMath_SD59x18_Gm_Overflow(SD59x18 x, SD59x18 y);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Overflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Overflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in UD60x18.
error PRBMath_SD59x18_IntoUD60x18_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Overflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint256.
error PRBMath_SD59x18_IntoUint256_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Overflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Underflow(SD59x18 x);

/// @notice Emitted when taking the logarithm of a number less than or equal to zero.
error PRBMath_SD59x18_Log_InputTooSmall(SD59x18 x);

/// @notice Emitted when multiplying two numbers and one of the inputs is `MIN_SD59x18`.
error PRBMath_SD59x18_Mul_InputTooSmall();

/// @notice Emitted when multiplying two numbers and the intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Mul_Overflow(SD59x18 x, SD59x18 y);

/// @notice Emitted when raising a number to a power and hte intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Powu_Overflow(SD59x18 x, uint256 y);

/// @notice Emitted when taking the square root of a negative number.
error PRBMath_SD59x18_Sqrt_NegativeInput(SD59x18 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMath_SD59x18_Sqrt_Overflow(SD59x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { unwrap, wrap } from "./Casting.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the SD59x18 type.
function add(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(unwrap(x) + unwrap(y));
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and(SD59x18 x, int256 bits) pure returns (SD59x18 result) {
    return wrap(unwrap(x) & bits);
}

/// @notice Implements the equal (=) operation in the SD59x18 type.
function eq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) == unwrap(y);
}

/// @notice Implements the greater than operation (>) in the SD59x18 type.
function gt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) > unwrap(y);
}

/// @notice Implements the greater than or equal to operation (>=) in the SD59x18 type.
function gte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) >= unwrap(y);
}

/// @notice Implements a zero comparison check function in the SD59x18 type.
function isZero(SD59x18 x) pure returns (bool result) {
    result = unwrap(x) == 0;
}

/// @notice Implements the left shift operation (<<) in the SD59x18 type.
function lshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) << bits);
}

/// @notice Implements the lower than operation (<) in the SD59x18 type.
function lt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) < unwrap(y);
}

/// @notice Implements the lower than or equal to operation (<=) in the SD59x18 type.
function lte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) <= unwrap(y);
}

/// @notice Implements the unchecked modulo operation (%) in the SD59x18 type.
function mod(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) % unwrap(y));
}

/// @notice Implements the not equal operation (!=) in the SD59x18 type.
function neq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) != unwrap(y);
}

/// @notice Implements the OR (|) bitwise operation in the SD59x18 type.
function or(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) | unwrap(y));
}

/// @notice Implements the right shift operation (>>) in the SD59x18 type.
function rshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the SD59x18 type.
function sub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) - unwrap(y));
}

/// @notice Implements the unchecked addition operation (+) in the SD59x18 type.
function uncheckedAdd(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(unwrap(x) + unwrap(y));
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the SD59x18 type.
function uncheckedSub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(unwrap(x) - unwrap(y));
    }
}

/// @notice Implements the unchecked unary minus operation (-) in the SD59x18 type.
function uncheckedUnary(SD59x18 x) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(-unwrap(x));
    }
}

/// @notice Implements the XOR (^) bitwise operation in the SD59x18 type.
function xor(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) ^ unwrap(y));
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT128, MAX_UINT40, msb, mulDiv, mulDiv18, prbExp2, prbSqrt } from "../Common.sol";
import {
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_SD59x18,
    uMAX_WHOLE_SD59x18,
    uMIN_SD59x18,
    uMIN_WHOLE_SD59x18,
    UNIT,
    uUNIT,
    ZERO
} from "./Constants.sol";
import {
    PRBMath_SD59x18_Abs_MinSD59x18,
    PRBMath_SD59x18_Ceil_Overflow,
    PRBMath_SD59x18_Div_InputTooSmall,
    PRBMath_SD59x18_Div_Overflow,
    PRBMath_SD59x18_Exp_InputTooBig,
    PRBMath_SD59x18_Exp2_InputTooBig,
    PRBMath_SD59x18_Floor_Underflow,
    PRBMath_SD59x18_Gm_Overflow,
    PRBMath_SD59x18_Gm_NegativeProduct,
    PRBMath_SD59x18_Log_InputTooSmall,
    PRBMath_SD59x18_Mul_InputTooSmall,
    PRBMath_SD59x18_Mul_Overflow,
    PRBMath_SD59x18_Powu_Overflow,
    PRBMath_SD59x18_Sqrt_NegativeInput,
    PRBMath_SD59x18_Sqrt_Overflow
} from "./Errors.sol";
import { unwrap, wrap } from "./Helpers.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Calculate the absolute value of x.
///
/// @dev Requirements:
/// - x must be greater than `MIN_SD59x18`.
///
/// @param x The SD59x18 number for which to calculate the absolute value.
/// @param result The absolute value of x as an SD59x18 number.
function abs(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt == uMIN_SD59x18) {
        revert PRBMath_SD59x18_Abs_MinSD59x18();
    }
    result = xInt < 0 ? wrap(-xInt) : x;
}

/// @notice Calculates the arithmetic average of x and y, rounding towards zero.
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The arithmetic average as an SD59x18 number.
function avg(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);

    unchecked {
        // This is equivalent to "x / 2 +  y / 2" but faster.
        // This operation can never overflow.
        int256 sum = (xInt >> 1) + (yInt >> 1);

        if (sum < 0) {
            // If at least one of x and y is odd, we add 1 to the result, since shifting negative numbers to the right rounds
            // down to infinity. The right part is equivalent to "sum + (x % 2 == 1 || y % 2 == 1)" but faster.
            assembly ("memory-safe") {
                result := add(sum, and(or(xInt, yInt), 1))
            }
        } else {
            // We need to add 1 if both x and y are odd to account for the double 0.5 remainder that is truncated after shifting.
            result = wrap(sum + (xInt & yInt & 1));
        }
    }
}

/// @notice Yields the smallest whole SD59x18 number greater than or equal to x.
///
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to ceil.
/// @param result The least number greater than or equal to x, as an SD59x18 number.
function ceil(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt > uMAX_WHOLE_SD59x18) {
        revert PRBMath_SD59x18_Ceil_Overflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt > 0) {
                resultInt += uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Divides two SD59x18 numbers, returning a new SD59x18 number. Rounds towards zero.
///
/// @dev This is a variant of `mulDiv` that works with signed numbers. Works by computing the signs and the absolute values
/// separately.
///
/// Requirements:
/// - All from `Common.mulDiv`.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The denominator cannot be zero.
/// - The result must fit within int256.
///
/// Caveats:
/// - All from `Common.mulDiv`.
///
/// @param x The numerator as an SD59x18 number.
/// @param y The denominator as an SD59x18 number.
/// @param result The quotient as an SD59x18 number.
function div(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert PRBMath_SD59x18_Div_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*UNIT)÷y. The resulting value must fit within int256.
    uint256 resultAbs = mulDiv(xAbs, uint256(uUNIT), yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert PRBMath_SD59x18_Div_Overflow(x, y);
    }

    // Check if x and y have the same sign. This works thanks to two's complement; the left-most bit is the sign bit.
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs don't have the same sign, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Calculates the natural exponent of x.
///
/// @dev Based on the formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// Requirements:
/// - All from `log2`.
/// - x must be less than 133.084258667509499441.
///
/// Caveats:
/// - All from `exp2`.
/// - For any x less than -41.446531673892822322, the result is zero.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
function exp(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    // Without this check, the value passed to `exp2` would be less than -59.794705707972522261.
    if (xInt < -41_446531673892822322) {
        return ZERO;
    }

    // Without this check, the value passed to `exp2` would be greater than 192.
    if (xInt >= 133_084258667509499441) {
        revert PRBMath_SD59x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Do the fixed-point multiplication inline to save gas.
        int256 doubleUnitProduct = xInt * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev Based on the formula:
///
/// $$
/// 2^{-x} = \frac{1}{2^x}
/// $$
///
/// See https://ethereum.stackexchange.com/q/79903/24693.
///
/// Requirements:
/// - x must be 192 or less.
/// - The result must fit within `MAX_SD59x18`.
///
/// Caveats:
/// - For any x less than -59.794705707972522261, the result is zero.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
function exp2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt < 0) {
        // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
        if (xInt < -59_794705707972522261) {
            return ZERO;
        }

        unchecked {
            // Do the fixed-point inversion $1/2^x$ inline to save gas. 1e36 is UNIT * UNIT.
            result = wrap(1e36 / unwrap(exp2(wrap(-xInt))));
        }
    } else {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (xInt >= 192e18) {
            revert PRBMath_SD59x18_Exp2_InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x_192x64 = uint256((xInt << 64) / uUNIT);

            // It is safe to convert the result to int256 with no checks because the maximum input allowed in this function is 192.
            result = wrap(int256(prbExp2(x_192x64)));
        }
    }
}

/// @notice Yields the greatest whole SD59x18 number less than or equal to x.
///
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be greater than or equal to `MIN_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to floor.
/// @param result The greatest integer less than or equal to x, as an SD59x18 number.
function floor(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt < uMIN_WHOLE_SD59x18) {
        revert PRBMath_SD59x18_Floor_Underflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt < 0) {
                resultInt -= uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right.
/// of the radix point for negative numbers.
/// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
/// @param x The SD59x18 number to get the fractional part of.
/// @param result The fractional part of x as an SD59x18 number.
function frac(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) % uUNIT);
}

/// @notice Calculates the geometric mean of x and y, i.e. sqrt(x * y), rounding down.
///
/// @dev Requirements:
/// - x * y must fit within `MAX_SD59x18`, lest it overflows.
/// - x * y must not be negative, since this library does not handle complex numbers.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The result as an SD59x18 number.
function gm(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);
    if (xInt == 0 || yInt == 0) {
        return ZERO;
    }

    unchecked {
        // Equivalent to "xy / x != y". Checking for overflow this way is faster than letting Solidity do it.
        int256 xyInt = xInt * yInt;
        if (xyInt / xInt != yInt) {
            revert PRBMath_SD59x18_Gm_Overflow(x, y);
        }

        // The product must not be negative, since this library does not handle complex numbers.
        if (xyInt < 0) {
            revert PRBMath_SD59x18_Gm_NegativeProduct(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product had picked up a factor of `UNIT`
        // during multiplication. See the comments within the `prbSqrt` function.
        uint256 resultUint = prbSqrt(uint256(xyInt));
        result = wrap(int256(resultUint));
    }
}

/// @notice Calculates 1 / x, rounding toward zero.
///
/// @dev Requirements:
/// - x cannot be zero.
///
/// @param x The SD59x18 number for which to calculate the inverse.
/// @return result The inverse as an SD59x18 number.
function inv(SD59x18 x) pure returns (SD59x18 result) {
    // 1e36 is UNIT * UNIT.
    result = wrap(1e36 / unwrap(x));
}

/// @notice Calculates the natural logarithm of x.
///
/// @dev Based on the formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}$$.
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
/// - This doesn't return exactly 1 for 2.718281828459045235, for that more fine-grained precision is needed.
///
/// @param x The SD59x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as an SD59x18 number.
function ln(SD59x18 x) pure returns (SD59x18 result) {
    // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
    // can return is 195.205294292027477728.
    result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_E);
}

/// @notice Calculates the common logarithm of x.
///
/// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
/// logarithm based on the formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
///
/// @param x The SD59x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as an SD59x18 number.
function log10(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this block is the assembly mul operation, not the SD59x18 `mul`.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        default {
            result := uMAX_SD59x18
        }
    }

    if (unwrap(result) == uMAX_SD59x18) {
        unchecked {
            // Do the fixed-point division inline to save gas.
            result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x.
///
/// @dev Based on the iterative approximation algorithm.
/// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
///
/// Requirements:
/// - x must be greater than zero.
///
/// Caveats:
/// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
///
/// @param x The SD59x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as an SD59x18 number.
function log2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt <= 0) {
        revert PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    unchecked {
        // This works because of:
        //
        // $$
        // log_2{x} = -log_2{\frac{1}{x}}
        // $$
        int256 sign;
        if (xInt >= uUNIT) {
            sign = 1;
        } else {
            sign = -1;
            // Do the fixed-point inversion inline to save gas. The numerator is UNIT * UNIT.
            xInt = 1e36 / xInt;
        }

        // Calculate the integer part of the logarithm and add it to the result and finally calculate $y = x * 2^(-n)$.
        uint256 n = msb(uint256(xInt / uUNIT));

        // This is the integer part of the logarithm as an SD59x18 number. The operation can't overflow
        // because n is maximum 255, UNIT is 1e18 and sign is either 1 or -1.
        int256 resultInt = int256(n) * uUNIT;

        // This is $y = x * 2^{-n}$.
        int256 y = xInt >> n;

        // If y is 1, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultInt * sign);
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        int256 DOUBLE_UNIT = 2e18;
        for (int256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is $y^2 > 2$ and so in the range [2,4)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultInt = resultInt + delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        resultInt *= sign;
        result = wrap(resultInt);
    }
}

/// @notice Multiplies two SD59x18 numbers together, returning a new SD59x18 number.
///
/// @dev This is a variant of `mulDiv` that works with signed numbers and employs constant folding, i.e. the denominator
/// is always 1e18.
///
/// Requirements:
/// - All from `Common.mulDiv18`.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The result must fit within `MAX_SD59x18`.
///
/// Caveats:
/// - To understand how this works in detail, see the NatSpec comments in `Common.mulDivSigned`.
///
/// @param x The multiplicand as an SD59x18 number.
/// @param y The multiplier as an SD59x18 number.
/// @return result The product as an SD59x18 number.
function mul(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert PRBMath_SD59x18_Mul_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    uint256 resultAbs = mulDiv18(xAbs, yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert PRBMath_SD59x18_Mul_Overflow(x, y);
    }

    // Check if x and y have the same sign. This works thanks to two's complement; the left-most bit is the sign bit.
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Raises x to the power of y.
///
/// @dev Based on the formula:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// Requirements:
/// - All from `exp2`, `log2` and `mul`.
/// - x cannot be zero.
///
/// Caveats:
/// - All from `exp2`, `log2` and `mul`.
/// - Assumes 0^0 is 1.
///
/// @param x Number to raise to given power y, as an SD59x18 number.
/// @param y Exponent to raise x to, as an SD59x18 number
/// @return result x raised to power y, as an SD59x18 number.
function pow(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);

    if (xInt == 0) {
        result = yInt == 0 ? UNIT : ZERO;
    } else {
        if (yInt == uUNIT) {
            result = x;
        } else {
            result = exp2(mul(log2(x), y));
        }
    }
}

/// @notice Raises x (an SD59x18 number) to the power y (unsigned basic integer) using the famous algorithm
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
///
/// Requirements:
/// - All from `abs` and `Common.mulDiv18`.
/// - The result must fit within `MAX_SD59x18`.
///
/// Caveats:
/// - All from `Common.mulDiv18`.
/// - Assumes 0^0 is 1.
///
/// @param x The base as an SD59x18 number.
/// @param y The exponent as an uint256.
/// @return result The result as an SD59x18 number.
function powu(SD59x18 x, uint256 y) pure returns (SD59x18 result) {
    uint256 xAbs = uint256(unwrap(abs(x)));

    // Calculate the first iteration of the loop in advance.
    uint256 resultAbs = y & 1 > 0 ? xAbs : uint256(uUNIT);

    // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
    uint256 yAux = y;
    for (yAux >>= 1; yAux > 0; yAux >>= 1) {
        xAbs = mulDiv18(xAbs, xAbs);

        // Equivalent to "y % 2 == 1" but faster.
        if (yAux & 1 > 0) {
            resultAbs = mulDiv18(resultAbs, xAbs);
        }
    }

    // The result must fit within `MAX_SD59x18`.
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert PRBMath_SD59x18_Powu_Overflow(x, y);
    }

    unchecked {
        // Is the base negative and the exponent an odd number?
        int256 resultInt = int256(resultAbs);
        bool isNegative = unwrap(x) < 0 && y & 1 == 1;
        if (isNegative) {
            resultInt = -resultInt;
        }
        result = wrap(resultInt);
    }
}

/// @notice Calculates the square root of x, rounding down. Only the positive root is returned.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Requirements:
/// - x cannot be negative, since this library does not handle complex numbers.
/// - x must be less than `MAX_SD59x18` divided by `UNIT`.
///
/// @param x The SD59x18 number for which to calculate the square root.
/// @return result The result as an SD59x18 number.
function sqrt(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_Sqrt_NegativeInput(x);
    }
    if (xInt > uMAX_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Sqrt_Overflow(x);
    }

    unchecked {
        // Multiply x by `UNIT` to account for the factor of `UNIT` that is picked up when multiplying two SD59x18
        // numbers together (in this case, the two numbers are both the square root).
        uint256 resultUint = prbSqrt(uint256(xInt * uUNIT));
        result = wrap(int256(resultUint));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Casting.sol" as C;
import "./Helpers.sol" as H;
import "./Math.sol" as M;

/// @notice The signed 59.18-decimal fixed-point number representation, which can have up to 59 digits and up to 18 decimals.
/// The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity type int256.
type SD59x18 is int256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    C.intoInt256,
    C.intoSD1x18,
    C.intoUD2x18,
    C.intoUD60x18,
    C.intoUint256,
    C.intoUint128,
    C.intoUint40,
    C.unwrap
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    M.abs,
    M.avg,
    M.ceil,
    M.div,
    M.exp,
    M.exp2,
    M.floor,
    M.frac,
    M.gm,
    M.inv,
    M.log10,
    M.log2,
    M.ln,
    M.mul,
    M.pow,
    M.powu,
    M.sqrt
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    H.add,
    H.and,
    H.eq,
    H.gt,
    H.gte,
    H.isZero,
    H.lshift,
    H.lt,
    H.lte,
    H.mod,
    H.neq,
    H.or,
    H.rshift,
    H.sub,
    H.uncheckedAdd,
    H.uncheckedSub,
    H.uncheckedUnary,
    H.xor
} for SD59x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { PRBMath_UD2x18_IntoSD1x18_Overflow, PRBMath_UD2x18_IntoUint40_Overflow } from "./Errors.sol";
import { UD2x18 } from "./ValueType.sol";

/// @notice Casts an UD2x18 number into SD1x18.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD2x18 x) pure returns (SD1x18 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(uMAX_SD1x18)) {
        revert PRBMath_UD2x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xUint));
}

/// @notice Casts an UD2x18 number into SD59x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of SD59x18.
function intoSD59x18(UD2x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(uint256(UD2x18.unwrap(x))));
}

/// @notice Casts an UD2x18 number into UD60x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of UD60x18.
function intoUD60x18(UD2x18 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(UD2x18.unwrap(x));
}

/// @notice Casts an UD2x18 number into uint128.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint128.
function intoUint128(UD2x18 x) pure returns (uint128 result) {
    result = uint128(UD2x18.unwrap(x));
}

/// @notice Casts an UD2x18 number into uint256.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint256.
function intoUint256(UD2x18 x) pure returns (uint256 result) {
    result = uint256(UD2x18.unwrap(x));
}

/// @notice Casts an UD2x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD2x18 x) pure returns (uint40 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(MAX_UINT40)) {
        revert PRBMath_UD2x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for the `wrap` function.
function ud2x18(uint64 x) pure returns (UD2x18 result) {
    result = wrap(x);
}

/// @notice Unwrap an UD2x18 number into uint64.
function unwrap(UD2x18 x) pure returns (uint64 result) {
    result = UD2x18.unwrap(x);
}

/// @notice Wraps an uint64 number into the UD2x18 value type.
function wrap(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { UD2x18 } from "./ValueType.sol";

/// @dev Euler's number as an UD2x18 number.
UD2x18 constant E = UD2x18.wrap(2_718281828459045235);

/// @dev The maximum value an UD2x18 number can have.
uint64 constant uMAX_UD2x18 = 18_446744073709551615;
UD2x18 constant MAX_UD2x18 = UD2x18.wrap(uMAX_UD2x18);

/// @dev PI as an UD2x18 number.
UD2x18 constant PI = UD2x18.wrap(3_141592653589793238);

/// @dev The unit amount that implies how many trailing decimals can be represented.
uint256 constant uUNIT = 1e18;
UD2x18 constant UNIT = UD2x18.wrap(1e18);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { UD2x18 } from "./ValueType.sol";

/// @notice Emitted when trying to cast a UD2x18 number that doesn't fit in SD1x18.
error PRBMath_UD2x18_IntoSD1x18_Overflow(UD2x18 x);

/// @notice Emitted when trying to cast a UD2x18 number that doesn't fit in uint40.
error PRBMath_UD2x18_IntoUint40_Overflow(UD2x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Casting.sol" as C;

/// @notice The unsigned 2.18-decimal fixed-point number representation, which can have up to 2 digits and up to 18 decimals.
/// The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity type uint64.
/// This is useful when end users want to use uint64 to save gas, e.g. with tight variable packing in contract storage.
type UD2x18 is uint64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using { C.intoSD1x18, C.intoSD59x18, C.intoUD60x18, C.intoUint256, C.intoUint128, C.intoUint40, C.unwrap } for UD2x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./ud60x18/Casting.sol";
import "./ud60x18/Constants.sol";
import "./ud60x18/Conversions.sol";
import "./ud60x18/Errors.sol";
import "./ud60x18/Helpers.sol";
import "./ud60x18/Math.sol";
import "./ud60x18/ValueType.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_SD59x18 } from "../sd59x18/Constants.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import {
    PRBMath_UD60x18_IntoSD1x18_Overflow,
    PRBMath_UD60x18_IntoUD2x18_Overflow,
    PRBMath_UD60x18_IntoSD59x18_Overflow,
    PRBMath_UD60x18_IntoUint128_Overflow,
    PRBMath_UD60x18_IntoUint40_Overflow
} from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Casts an UD60x18 number into SD1x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD60x18 x) pure returns (SD1x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(int256(uMAX_SD1x18))) {
        revert PRBMath_UD60x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(uint64(xUint)));
}

/// @notice Casts an UD60x18 number into UD2x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(UD60x18 x) pure returns (UD2x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uMAX_UD2x18) {
        revert PRBMath_UD60x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(xUint));
}

/// @notice Casts an UD60x18 number into SD59x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD59x18`.
function intoSD59x18(UD60x18 x) pure returns (SD59x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(uMAX_SD59x18)) {
        revert PRBMath_UD60x18_IntoSD59x18_Overflow(x);
    }
    result = SD59x18.wrap(int256(xUint));
}

/// @notice Casts an UD60x18 number into uint128.
/// @dev This is basically a functional alias for the `unwrap` function.
function intoUint256(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Casts an UD60x18 number into uint128.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT128`.
function intoUint128(UD60x18 x) pure returns (uint128 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT128) {
        revert PRBMath_UD60x18_IntoUint128_Overflow(x);
    }
    result = uint128(xUint);
}

/// @notice Casts an UD60x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD60x18 x) pure returns (uint40 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT40) {
        revert PRBMath_UD60x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for the `wrap` function.
function ud(uint256 x) pure returns (UD60x18 result) {
    result = wrap(x);
}

/// @notice Alias for the `wrap` function.
function ud60x18(uint256 x) pure returns (UD60x18 result) {
    result = wrap(x);
}

/// @notice Unwraps an UD60x18 number into uint256.
function unwrap(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Wraps an uint256 number into the UD60x18 value type.
function wrap(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { UD60x18 } from "./ValueType.sol";

/// @dev Euler's number as an UD60x18 number.
UD60x18 constant E = UD60x18.wrap(2_718281828459045235);

/// @dev Half the UNIT number.
uint256 constant uHALF_UNIT = 0.5e18;
UD60x18 constant HALF_UNIT = UD60x18.wrap(uHALF_UNIT);

/// @dev log2(10) as an UD60x18 number.
uint256 constant uLOG2_10 = 3_321928094887362347;
UD60x18 constant LOG2_10 = UD60x18.wrap(uLOG2_10);

/// @dev log2(e) as an UD60x18 number.
uint256 constant uLOG2_E = 1_442695040888963407;
UD60x18 constant LOG2_E = UD60x18.wrap(uLOG2_E);

/// @dev The maximum value an UD60x18 number can have.
uint256 constant uMAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_584007913129639935;
UD60x18 constant MAX_UD60x18 = UD60x18.wrap(uMAX_UD60x18);

/// @dev The maximum whole value an UD60x18 number can have.
uint256 constant uMAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_000000000000000000;
UD60x18 constant MAX_WHOLE_UD60x18 = UD60x18.wrap(uMAX_WHOLE_UD60x18);

/// @dev PI as an UD60x18 number.
UD60x18 constant PI = UD60x18.wrap(3_141592653589793238);

/// @dev The unit amount that implies how many trailing decimals can be represented.
uint256 constant uUNIT = 1e18;
UD60x18 constant UNIT = UD60x18.wrap(uUNIT);

/// @dev Zero as an UD60x18 number.
UD60x18 constant ZERO = UD60x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { uMAX_UD60x18, uUNIT } from "./Constants.sol";
import { PRBMath_UD60x18_Convert_Overflow } from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Converts an UD60x18 number to a simple integer by dividing it by `UNIT`. Rounds towards zero in the process.
/// @dev Rounds down in the process.
/// @param x The UD60x18 number to convert.
/// @return result The same number in basic integer form.
function convert(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x) / uUNIT;
}

/// @notice Converts a simple integer to UD60x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UD60x18` divided by `UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to UD60x18.
function convert(uint256 x) pure returns (UD60x18 result) {
    if (x > uMAX_UD60x18 / uUNIT) {
        revert PRBMath_UD60x18_Convert_Overflow(x);
    }
    unchecked {
        result = UD60x18.wrap(x * uUNIT);
    }
}

/// @notice Alias for the `convert` function defined above.
/// @dev Here for backward compatibility. Will be removed in V4.
function fromUD60x18(UD60x18 x) pure returns (uint256 result) {
    result = convert(x);
}

/// @notice Alias for the `convert` function defined above.
/// @dev Here for backward compatibility. Will be removed in V4.
function toUD60x18(uint256 x) pure returns (UD60x18 result) {
    result = convert(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { UD60x18 } from "./ValueType.sol";

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMath_UD60x18_Ceil_Overflow(UD60x18 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows UD60x18.
error PRBMath_UD60x18_Convert_Overflow(uint256 x);

/// @notice Emitted when taking the natural exponent of a base greater than 133.084258667509499441.
error PRBMath_UD60x18_Exp_InputTooBig(UD60x18 x);

/// @notice Emitted when taking the binary exponent of a base greater than 192.
error PRBMath_UD60x18_Exp2_InputTooBig(UD60x18 x);

/// @notice Emitted when taking the geometric mean of two numbers and multiplying them overflows UD60x18.
error PRBMath_UD60x18_Gm_Overflow(UD60x18 x, UD60x18 y);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in SD1x18.
error PRBMath_UD60x18_IntoSD1x18_Overflow(UD60x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in SD59x18.
error PRBMath_UD60x18_IntoSD59x18_Overflow(UD60x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in UD2x18.
error PRBMath_UD60x18_IntoUD2x18_Overflow(UD60x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint128.
error PRBMath_UD60x18_IntoUint128_Overflow(UD60x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint40.
error PRBMath_UD60x18_IntoUint40_Overflow(UD60x18 x);

/// @notice Emitted when taking the logarithm of a number less than 1.
error PRBMath_UD60x18_Log_InputTooSmall(UD60x18 x);

/// @notice Emitted when calculating the square root overflows UD60x18.
error PRBMath_UD60x18_Sqrt_Overflow(UD60x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { unwrap, wrap } from "./Casting.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the UD60x18 type.
function add(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) + unwrap(y));
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) & bits);
}

/// @notice Implements the equal operation (==) in the UD60x18 type.
function eq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) == unwrap(y);
}

/// @notice Implements the greater than operation (>) in the UD60x18 type.
function gt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) > unwrap(y);
}

/// @notice Implements the greater than or equal to operation (>=) in the UD60x18 type.
function gte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) >= unwrap(y);
}

/// @notice Implements a zero comparison check function in the UD60x18 type.
function isZero(UD60x18 x) pure returns (bool result) {
    // This wouldn't work if x could be negative.
    result = unwrap(x) == 0;
}

/// @notice Implements the left shift operation (<<) in the UD60x18 type.
function lshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) << bits);
}

/// @notice Implements the lower than operation (<) in the UD60x18 type.
function lt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) < unwrap(y);
}

/// @notice Implements the lower than or equal to operation (<=) in the UD60x18 type.
function lte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) <= unwrap(y);
}

/// @notice Implements the checked modulo operation (%) in the UD60x18 type.
function mod(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) % unwrap(y));
}

/// @notice Implements the not equal operation (!=) in the UD60x18 type
function neq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) != unwrap(y);
}

/// @notice Implements the OR (|) bitwise operation in the UD60x18 type.
function or(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) | unwrap(y));
}

/// @notice Implements the right shift operation (>>) in the UD60x18 type.
function rshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the UD60x18 type.
function sub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) - unwrap(y));
}

/// @notice Implements the unchecked addition operation (+) in the UD60x18 type.
function uncheckedAdd(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(unwrap(x) + unwrap(y));
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the UD60x18 type.
function uncheckedSub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(unwrap(x) - unwrap(y));
    }
}

/// @notice Implements the XOR (^) bitwise operation in the UD60x18 type.
function xor(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) ^ unwrap(y));
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { msb, mulDiv, mulDiv18, prbExp2, prbSqrt } from "../Common.sol";
import { unwrap, wrap } from "./Casting.sol";
import { uHALF_UNIT, uLOG2_10, uLOG2_E, uMAX_UD60x18, uMAX_WHOLE_UD60x18, UNIT, uUNIT, ZERO } from "./Constants.sol";
import {
    PRBMath_UD60x18_Ceil_Overflow,
    PRBMath_UD60x18_Exp_InputTooBig,
    PRBMath_UD60x18_Exp2_InputTooBig,
    PRBMath_UD60x18_Gm_Overflow,
    PRBMath_UD60x18_Log_InputTooSmall,
    PRBMath_UD60x18_Sqrt_Overflow
} from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the arithmetic average of x and y, rounding down.
///
/// @dev Based on the formula:
///
/// $$
/// avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
/// $$
//
/// In English, what this formula does is:
///
/// 1. AND x and y.
/// 2. Calculate half of XOR x and y.
/// 3. Add the two results together.
///
/// This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
/// https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223
///
/// @param x The first operand as an UD60x18 number.
/// @param y The second operand as an UD60x18 number.
/// @return result The arithmetic average as an UD60x18 number.
function avg(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    uint256 yUint = unwrap(y);
    unchecked {
        result = wrap((xUint & yUint) + ((xUint ^ yUint) >> 1));
    }
}

/// @notice Yields the smallest whole UD60x18 number greater than or equal to x.
///
/// @dev This is optimized for fractional value inputs, because for every whole value there are "1e18 - 1" fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_UD60x18`.
///
/// @param x The UD60x18 number to ceil.
/// @param result The least number greater than or equal to x, as an UD60x18 number.
function ceil(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    if (xUint > uMAX_WHOLE_UD60x18) {
        revert PRBMath_UD60x18_Ceil_Overflow(x);
    }

    assembly ("memory-safe") {
        // Equivalent to "x % UNIT" but faster.
        let remainder := mod(x, uUNIT)

        // Equivalent to "UNIT - remainder" but faster.
        let delta := sub(uUNIT, remainder)

        // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
        result := add(x, mul(delta, gt(remainder, 0)))
    }
}

/// @notice Divides two UD60x18 numbers, returning a new UD60x18 number. Rounds towards zero.
///
/// @dev Uses `mulDiv` to enable overflow-safe multiplication and division.
///
/// Requirements:
/// - The denominator cannot be zero.
///
/// @param x The numerator as an UD60x18 number.
/// @param y The denominator as an UD60x18 number.
/// @param result The quotient as an UD60x18 number.
function div(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(mulDiv(unwrap(x), uUNIT, unwrap(y)));
}

/// @notice Calculates the natural exponent of x.
///
/// @dev Based on the formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// Requirements:
/// - All from `log2`.
/// - x must be less than 133.084258667509499441.
///
/// @param x The exponent as an UD60x18 number.
/// @return result The result as an UD60x18 number.
function exp(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    // Without this check, the value passed to `exp2` would be greater than 192.
    if (xUint >= 133_084258667509499441) {
        revert PRBMath_UD60x18_Exp_InputTooBig(x);
    }

    unchecked {
        // We do the fixed-point multiplication inline rather than via the `mul` function to save gas.
        uint256 doubleUnitProduct = xUint * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693.
///
/// Requirements:
/// - x must be 192 or less.
/// - The result must fit within `MAX_UD60x18`.
///
/// @param x The exponent as an UD60x18 number.
/// @return result The result as an UD60x18 number.
function exp2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    // Numbers greater than or equal to 2^192 don't fit within the 192.64-bit format.
    if (xUint >= 192e18) {
        revert PRBMath_UD60x18_Exp2_InputTooBig(x);
    }

    // Convert x to the 192.64-bit fixed-point format.
    uint256 x_192x64 = (xUint << 64) / uUNIT;

    // Pass x to the `prbExp2` function, which uses the 192.64-bit fixed-point number representation.
    result = wrap(prbExp2(x_192x64));
}

/// @notice Yields the greatest whole UD60x18 number less than or equal to x.
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
/// @param x The UD60x18 number to floor.
/// @param result The greatest integer less than or equal to x, as an UD60x18 number.
function floor(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        // Equivalent to "x % UNIT" but faster.
        let remainder := mod(x, uUNIT)

        // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
        result := sub(x, mul(remainder, gt(remainder, 0)))
    }
}

/// @notice Yields the excess beyond the floor of x.
/// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
/// @param x The UD60x18 number to get the fractional part of.
/// @param result The fractional part of x as an UD60x18 number.
function frac(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        result := mod(x, uUNIT)
    }
}

/// @notice Calculates the geometric mean of x and y, i.e. $$sqrt(x * y)$$, rounding down.
///
/// @dev Requirements:
/// - x * y must fit within `MAX_UD60x18`, lest it overflows.
///
/// @param x The first operand as an UD60x18 number.
/// @param y The second operand as an UD60x18 number.
/// @return result The result as an UD60x18 number.
function gm(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    uint256 yUint = unwrap(y);
    if (xUint == 0 || yUint == 0) {
        return ZERO;
    }

    unchecked {
        // Checking for overflow this way is faster than letting Solidity do it.
        uint256 xyUint = xUint * yUint;
        if (xyUint / xUint != yUint) {
            revert PRBMath_UD60x18_Gm_Overflow(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product had picked up a factor of `UNIT`
        // during multiplication. See the comments in the `prbSqrt` function.
        result = wrap(prbSqrt(xyUint));
    }
}

/// @notice Calculates 1 / x, rounding toward zero.
///
/// @dev Requirements:
/// - x cannot be zero.
///
/// @param x The UD60x18 number for which to calculate the inverse.
/// @return result The inverse as an UD60x18 number.
function inv(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // 1e36 is UNIT * UNIT.
        result = wrap(1e36 / unwrap(x));
    }
}

/// @notice Calculates the natural logarithm of x.
///
/// @dev Based on the formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}$$.
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
/// - This doesn't return exactly 1 for 2.718281828459045235, for that more fine-grained precision is needed.
///
/// @param x The UD60x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as an UD60x18 number.
function ln(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // We do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value
        // that `log2` can return is 196.205294292027477728.
        result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_E);
    }
}

/// @notice Calculates the common logarithm of x.
///
/// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
/// logarithm based on the formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
///
/// @param x The UD60x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as an UD60x18 number.
function log10(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    if (xUint < uUNIT) {
        revert PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this assembly block is the assembly multiplication operation, not the UD60x18 `mul`.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 59) }
        default {
            result := uMAX_UD60x18
        }
    }

    if (unwrap(result) == uMAX_UD60x18) {
        unchecked {
            // Do the fixed-point division inline to save gas.
            result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x.
///
/// @dev Based on the iterative approximation algorithm.
/// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
///
/// Requirements:
/// - x must be greater than or equal to UNIT, otherwise the result would be negative.
///
/// Caveats:
/// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
///
/// @param x The UD60x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as an UD60x18 number.
function log2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    if (xUint < uUNIT) {
        revert PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    unchecked {
        // Calculate the integer part of the logarithm, add it to the result and finally calculate y = x * 2^(-n).
        uint256 n = msb(xUint / uUNIT);

        // This is the integer part of the logarithm as an UD60x18 number. The operation can't overflow because n
        // n is maximum 255 and UNIT is 1e18.
        uint256 resultUint = n * uUNIT;

        // This is $y = x * 2^{-n}$.
        uint256 y = xUint >> n;

        // If y is 1, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultUint);
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta.rshift(1)" part is equivalent to "delta /= 2", but shifting bits is faster.
        uint256 DOUBLE_UNIT = 2e18;
        for (uint256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultUint += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        result = wrap(resultUint);
    }
}

/// @notice Multiplies two UD60x18 numbers together, returning a new UD60x18 number.
/// @dev See the documentation for the `Common.mulDiv18` function.
/// @param x The multiplicand as an UD60x18 number.
/// @param y The multiplier as an UD60x18 number.
/// @return result The product as an UD60x18 number.
function mul(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(mulDiv18(unwrap(x), unwrap(y)));
}

/// @notice Raises x to the power of y.
///
/// @dev Based on the formula:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// Requirements:
/// - All from `exp2`, `log2` and `mul`.
///
/// Caveats:
/// - All from `exp2`, `log2` and `mul`.
/// - Assumes 0^0 is 1.
///
/// @param x Number to raise to given power y, as an UD60x18 number.
/// @param y Exponent to raise x to, as an UD60x18 number.
/// @return result x raised to power y, as an UD60x18 number.
function pow(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    uint256 yUint = unwrap(y);

    if (xUint == 0) {
        result = yUint == 0 ? UNIT : ZERO;
    } else {
        if (yUint == uUNIT) {
            result = x;
        } else {
            result = exp2(mul(log2(x), y));
        }
    }
}

/// @notice Raises x (an UD60x18 number) to the power y (unsigned basic integer) using the famous algorithm
/// "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
///
/// Requirements:
/// - The result must fit within `MAX_UD60x18`.
///
/// Caveats:
/// - All from "Common.mulDiv18".
/// - Assumes 0^0 is 1.
///
/// @param x The base as an UD60x18 number.
/// @param y The exponent as an uint256.
/// @return result The result as an UD60x18 number.
function powu(UD60x18 x, uint256 y) pure returns (UD60x18 result) {
    // Calculate the first iteration of the loop in advance.
    uint256 xUint = unwrap(x);
    uint256 resultUint = y & 1 > 0 ? xUint : uUNIT;

    // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
    for (y >>= 1; y > 0; y >>= 1) {
        xUint = mulDiv18(xUint, xUint);

        // Equivalent to "y % 2 == 1" but faster.
        if (y & 1 > 0) {
            resultUint = mulDiv18(resultUint, xUint);
        }
    }
    result = wrap(resultUint);
}

/// @notice Calculates the square root of x, rounding down.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Requirements:
/// - x must be less than `MAX_UD60x18` divided by `UNIT`.
///
/// @param x The UD60x18 number for which to calculate the square root.
/// @return result The result as an UD60x18 number.
function sqrt(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    unchecked {
        if (xUint > uMAX_UD60x18 / uUNIT) {
            revert PRBMath_UD60x18_Sqrt_Overflow(x);
        }
        // Multiply x by `UNIT` to account for the factor of `UNIT` that is picked up when multiplying two UD60x18
        // numbers together (in this case, the two numbers are both the square root).
        result = wrap(prbSqrt(xUint * uUNIT));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Casting.sol" as C;
import "./Helpers.sol" as H;
import "./Math.sol" as M;

/// @notice The unsigned 60.18-decimal fixed-point number representation, which can have up to 60 digits and up to 18 decimals.
/// The values of this are bound by the minimum and the maximum values permitted by the Solidity type uint256.
/// @dev The value type is defined here so it can be imported in all other files.
type UD60x18 is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using { C.intoSD1x18, C.intoUD2x18, C.intoSD59x18, C.intoUint128, C.intoUint256, C.intoUint40, C.unwrap } for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    M.avg,
    M.ceil,
    M.div,
    M.exp,
    M.exp2,
    M.floor,
    M.frac,
    M.gm,
    M.inv,
    M.ln,
    M.log10,
    M.log2,
    M.mul,
    M.pow,
    M.powu,
    M.sqrt
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    H.add,
    H.and,
    H.eq,
    H.gt,
    H.gte,
    H.isZero,
    H.lshift,
    H.lt,
    H.lte,
    H.mod,
    H.neq,
    H.or,
    H.rshift,
    H.sub,
    H.uncheckedAdd,
    H.uncheckedSub,
    H.xor
} for UD60x18 global;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControlEnumerableUpgradeable } from
    "@openzeppelin/contracts-diamond/access/AccessControlEnumerableUpgradeable.sol";
import { SupportsMetaTx } from "src/metatx/SupportsMetaTx.sol";
import { FacetInitializable } from "../utils/FacetInitializable.sol";
import { LibUtilities } from "../libraries/LibUtilities.sol";
import { LibAccessControlRoles, ADMIN_ROLE, ADMIN_GRANTER_ROLE } from "../libraries/LibAccessControlRoles.sol";

/**
 * @title AccessControl facet wrapper for OZ's pausable contract.
 * @dev Use this facet to limit the spread of third-party dependency references and allow new functionality to be shared
 */
contract AccessControlFacet is FacetInitializable, SupportsMetaTx, AccessControlEnumerableUpgradeable {
    function AccessControlFacet_init() external facetInitializer(keccak256("AccessControlFacet_init")) {
        __AccessControlEnumerable_init();

        _setRoleAdmin(ADMIN_ROLE, ADMIN_GRANTER_ROLE);
        _grantRole(ADMIN_GRANTER_ROLE, LibAccessControlRoles.contractOwner());

        // Give admin to the owner. May be revoked to prevent permanent administrative rights as owner
        _grantRole(ADMIN_ROLE, LibAccessControlRoles.contractOwner());
    }

    // =============================================================
    //                        External functions
    // =============================================================

    /// @notice Batch function for granting access to many addresses at once.
    /// @dev Checks for RoleAdmin permissions inside the grantRole function
    ///  per the OpenZeppelin AccessControl standard
    /// @param _roles Roles to be granted to the account in the same index of the _accounts array
    /// @param _accounts Addresses to grant the role in the same index of the _roles array
    function grantRoles(bytes32[] calldata _roles, address[] calldata _accounts) external {
        uint256 _roleLength = _roles.length;
        LibUtilities.requireArrayLengthMatch(_roleLength, _accounts.length);
        for (uint256 i = 0; i < _roleLength; i++) {
            grantRole(_roles[i], _accounts[i]);
        }
    }

    /**
     * @dev Helper for getting admin role from block explorers
     */
    function adminRole() external pure returns (bytes32 role_) {
        return ADMIN_ROLE;
    }

    /**
     * @dev Overrides to use custom error vs string building
     */
    function _checkRole(bytes32 _role, address _account) internal view virtual override {
        if (!hasRole(_role, _account)) {
            revert LibAccessControlRoles.MissingRole(_account, _role);
        }
    }

    function _grantRole(bytes32 _role, address _account) internal override {
        LibAccessControlRoles._grantRole(_role, _account);
    }

    function _revokeRole(bytes32 _role, address _account) internal override {
        LibAccessControlRoles._revokeRole(_role, _account);
    }

    /**
     * @dev Overrides AccessControlEnumerableUpgradeable and passes through to it.
     *  This is to have multiple inheritance overrides to be from this repo instead of OZ
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ECDSAUpgradeable } from "@openzeppelin/contracts-diamond/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-diamond/utils/cryptography/EIP712Upgradeable.sol";

import { FacetInitializable } from "../utils/FacetInitializable.sol";
import { LibAccessControlRoles } from "../libraries/LibAccessControlRoles.sol";
import { LibSpellcasterGM } from "../libraries/LibSpellcasterGM.sol";
import { LibMeta } from "../libraries/LibMeta.sol";

import { CollectionRoleGrantRequest } from "../interfaces/ISpellcasterGM.sol";

bytes32 constant COLLECTION_ROLE_GRANT_REQUEST_TYPEHASH =
    keccak256("CollectionRoleGrantRequest(address collection,uint96 nonce,address receiver,bytes32 role)");

contract CollectionAccessControlFacet is FacetInitializable, EIP712Upgradeable {
    function CollectionAccessControlFacet_init()
        external
        facetInitializer(keccak256("CollectionAccessControlFacet_init"))
    {
        __EIP712_init("Spellcaster", "1.0.0");
    }

    using ECDSAUpgradeable for bytes32;

    /**
     * @dev Error for when the signer is not a trusted signer.
     */
    error SignerIsNotTrustedSigner();

    /**
     * @dev Error for when the role request doesn't match the called function.
     */
    error InvalidRoleRequest();

    /**
     * @dev Verifies a given signature and a request and whether the signer is a trusted signer.
     * @param _collectionRoleGrantRequest The request to verify.
     * @param _signature The signature from a signer.
     */
    function verify(
        CollectionRoleGrantRequest calldata _collectionRoleGrantRequest,
        bytes calldata _signature
    ) internal returns (bool) {
        address _signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    COLLECTION_ROLE_GRANT_REQUEST_TYPEHASH,
                    _collectionRoleGrantRequest.collection,
                    _collectionRoleGrantRequest.nonce,
                    _collectionRoleGrantRequest.receiver,
                    _collectionRoleGrantRequest.role
                )
            )
        ).recover(_signature);

        //Use the nonce, revert if used.
        LibSpellcasterGM.useNonce(_signer, _collectionRoleGrantRequest.nonce);

        //Require signer is trusted.
        LibSpellcasterGM.requireTrustedSigner(_signer);

        //Return bool of whether signer is trusted.
        return (LibSpellcasterGM.isTrustedSigner(_signer));
    }

    /**
     * @dev Grants a collection role granter role given a valid request.
     * @param _collectionRoleGrantRequest The request to verify.
     * @param _signature The signature from a signer.
     */
    function grantCollectionRoleGranter(
        CollectionRoleGrantRequest calldata _collectionRoleGrantRequest,
        bytes calldata _signature
    ) external {
        if (LibMeta._msgSender() == LibAccessControlRoles.contractOwner()) {
            //Check that msg sender is collection owner
            //Do nothing
        } else {
            //This call reverts if they are not signed
            verify(_collectionRoleGrantRequest, _signature);
        }

        if (
            _collectionRoleGrantRequest.role
                != keccak256(
                    abi.encodePacked("COLLECTION_ROLE_GRANTER_ROLE_", address(_collectionRoleGrantRequest.collection))
                )
        ) revert InvalidRoleRequest();

        LibAccessControlRoles.grantCollectionRoleGranter(
            _collectionRoleGrantRequest.receiver, _collectionRoleGrantRequest.collection
        );
    }

    /**
     * @dev Grants a collection role admin role. Only callable by collection role granter.
     * @param _account The account to make an admin.
     * @param _collection The colletion to make them an admin of.
     */
    function grantCollectionAdmin(address _account, address _collection) external {
        if (LibMeta._msgSender() != LibAccessControlRoles.contractOwner()) {
            LibAccessControlRoles.requireCollectionRoleGranter(LibMeta._msgSender(), _collection);
        }
        LibAccessControlRoles.grantCollectionAdmin(_account, _collection);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "../diamond/LibDiamond.sol";
import { IERC173Upgradeable } from "@openzeppelin/contracts-diamond/interfaces/IERC173Upgradeable.sol";

contract OwnershipFacet is IERC173Upgradeable {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    ERC1155HolderUpgradeable,
    ERC1155ReceiverUpgradeable
} from "@openzeppelin/contracts-diamond/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/IERC20Upgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC721/IERC721Upgradeable.sol";
import { IERC1155Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC1155/IERC1155Upgradeable.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { AddressUpgradeable } from "@openzeppelin/contracts-diamond/utils/AddressUpgradeable.sol";
import { LibAccessControlRoles } from "src/libraries/LibAccessControlRoles.sol";

import { ISimpleCrafting, CraftingRecipe, Ingredient, Result, TokenType } from "src/interfaces/ISimpleCrafting.sol";
import { SimpleCraftingStorage } from "src/crafting/SimpleCraftingStorage.sol";

import { LibSimpleCrafting } from "src/libraries/LibSimpleCrafting.sol";
import { IERC20Consumer } from "src/interfaces/IERC20Consumer.sol";
import { AccessControlFacet } from "src/access/AccessControlFacet.sol";
import { Modifiers } from "src/Modifiers.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";
import { FacetInitializable } from "../utils/FacetInitializable.sol";

import { IERC173Upgradeable } from "@openzeppelin/contracts-diamond/interfaces/IERC173Upgradeable.sol";
import { SupportsMetaTx } from "src/metatx/SupportsMetaTx.sol";

/**
 * @title Simple Crafting Contract
 * @dev Simple contract allows for the creation of a recipe with arbitrary inputs and outputs
 *  by the GuildManager contract.
 */
contract SimpleCrafting is FacetInitializable, ERC1155HolderUpgradeable, ISimpleCrafting, SupportsMetaTx {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function SimpleCrafting_init() external facetInitializer(keccak256("SimpleCrafting_init")) { }

    /**
     * @dev As an allowed admin, set a recipe as allowed for your scope
     * @param _collection The collection you are signing on behalf of.
     * @param _recipeId The recipeId to set.
     */
    function setRecipeToAllowedAsAdmin(address _collection, uint256 _recipeId) public supportsMetaTxNoId {
        //Ensure they are an admin of this collection.
        if (
            LibMeta._msgSender() != IERC173Upgradeable(_collection).owner()
                && !LibAccessControlRoles.isCollectionAdmin(LibMeta._msgSender(), _collection)
        ) revert UserNotPermitted(LibMeta._msgSender());

        LibSimpleCrafting.setCollectionToRecipeIdToAllowed(_collection, _recipeId, true);
    }

    /**
     * @dev Create a new recipe, anyone can call this.
     * @param _craftingRecipeInput The creation data for a crafting recipe.
     */
    function createNewCraftingRecipe(CraftingRecipe calldata _craftingRecipeInput) public supportsMetaTxNoId {
        //Pull the current recipe Id
        uint256 _currentRecipeId = SimpleCraftingStorage.getState().currentRecipeId;

        //Create a pointer to this recipeId (empty)
        CraftingRecipe storage _craftingRecipe = SimpleCraftingStorage.getState().craftingRecipes[_currentRecipeId];

        //For each ingredient
        for (uint256 i = 0; i < _craftingRecipeInput.ingredients.length; i++) {
            //Push it into storage
            _craftingRecipe.ingredients.push(_craftingRecipeInput.ingredients[i]);
        }

        //For each result
        for (uint256 i = 0; i < _craftingRecipeInput.results.length; i++) {
            //Push it into storage
            _craftingRecipe.results.push(_craftingRecipeInput.results[i]);
        }

        emit CraftingRecipeCreated(_currentRecipeId);

        //Increment currentRecipeId
        SimpleCraftingStorage.getState().currentRecipeId++;
    }

    /**
     * @dev Helper function to return a crafting recipe
     * @param _recipeId The recipeId to return.
     */
    function getCraftingRecipe(uint256 _recipeId) public view returns (CraftingRecipe memory) {
        return SimpleCraftingStorage.getState().craftingRecipes[_recipeId];
    }

    /**
     * @dev Craft a given recipeId, recipe must be fully allowed.
     * @param _recipeId The recipeId to craft.
     */
    function craft(uint256 _recipeId) public supportsMetaTxNoId {
        //Create a pointer to this recipe in storage.
        CraftingRecipe storage _craftingRecipe = SimpleCraftingStorage.getState().craftingRecipes[_recipeId];

        for (uint256 i = 0; i < _craftingRecipe.ingredients.length; i++) {
            //Pull all the ingredients
            Ingredient storage _ingredient = _craftingRecipe.ingredients[i];

            if (_ingredient.tokenType == TokenType.ERC20) {
                //ERC20
                IERC20Upgradeable(_ingredient.tokenAddress).safeTransferFrom(
                    LibMeta._msgSender(), address(this), _ingredient.tokenQuantity
                );
            }

            if (_ingredient.tokenType == TokenType.ERC721) {
                //ERC721
                IERC721Upgradeable(_ingredient.tokenAddress).transferFrom(
                    LibMeta._msgSender(), address(this), _ingredient.tokenId
                );
            }

            if (_ingredient.tokenType == TokenType.ERC1155) {
                //ERC1155
                IERC1155Upgradeable(_ingredient.tokenAddress).safeTransferFrom(
                    LibMeta._msgSender(), address(this), _ingredient.tokenId, _ingredient.tokenQuantity, ""
                );
            }
        }

        for (uint256 i = 0; i < _craftingRecipe.results.length; i++) {
            //Create a pointer to this result in storage.
            Result storage _result = _craftingRecipe.results[i];

            //Ensure this recipe result has been condoned by its' admin.
            if (!LibSimpleCrafting.getCollectionToRecipeIdToAllowed(_result.target, _recipeId)) {
                revert RecipeNotAllowed(_recipeId);
            }

            AddressUpgradeable.functionCall(
                _result.target, abi.encodePacked(_result.selector, abi.encode(LibMeta._msgSender()), _result.params)
            );
        }

        emit CraftingRecipeCrafted(_recipeId, LibMeta._msgSender());
    }

    /**
     * @dev supportsInterface
     * @param _interfaceId The interface id.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        if (_interfaceId == type(ISimpleCrafting).interfaceId) return true;
        return super.supportsInterface(_interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CraftingRecipe } from "../interfaces/ISimpleCrafting.sol";

library SimpleCraftingStorage {
    struct SimpleCraftingState {
        /**
         * @dev Store collection -> recipeId -> allowed, whether a collection has permitted a recipe
         */
        mapping(address => mapping(uint256 => bool)) collectionToRecipeIdToAllowed;
        /**
         * @dev Store all crafting recipes
         */
        mapping(uint256 => CraftingRecipe) craftingRecipes;
        uint256 currentRecipeId;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.simple.crafting");

    /**
     * @dev Returns the state struct at a given storage position.
     */
    function getState() internal pure returns (SimpleCraftingState storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 *
 * Implementation of a diamond.
 * /*****************************************************************************
 */

import { LibDiamond } from "./LibDiamond.sol";
import { IDiamondCut } from "./IDiamondCut.sol";

contract Diamond {
    struct Initialization {
        address initContract;
        bytes initData;
    }

    /// @notice This construct a diamond contract
    /// @param _contractOwner the owner of the contract. With default DiamondCutFacet, this is the sole address allowed to make further cuts.
    /// @param _diamondCut the list of facet to add
    /// @param _initializations the list of initialization pair to execute. This allow to setup a contract with multiple level of independent initialization.
    constructor(
        address _contractOwner,
        IDiamondCut.FacetCut[] memory _diamondCut,
        Initialization[] memory _initializations
    ) payable {
        if (_contractOwner != address(0)) {
            LibDiamond.setContractOwner(_contractOwner);
        }

        LibDiamond.diamondCut(_diamondCut, address(0), "");

        for (uint256 i = 0; i < _initializations.length; i++) {
            LibDiamond.initializeDiamondCut(_initializations[i].initContract, _initializations[i].initData);
        }
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        LibDiamond.DiamondStorage storage _ds;
        bytes32 _position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            _ds.slot := _position
        }
        // get facet from function selector
        address _facet = _ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(_facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), _facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable { }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */

import { IDiamondCut } from "./IDiamondCut.sol";
import { LibDiamond } from "./LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */

import { LibDiamond } from "./LibDiamond.sol";
import { IDiamondLoupe } from "./IDiamondLoupe.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-diamond/interfaces/IERC165Upgradeable.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165Upgradeable {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage _ds = LibDiamond.diamondStorage();
        uint256 _numFacets = _ds.facetAddresses.length;
        facets_ = new Facet[](_numFacets);
        for (uint256 i; i < _numFacets; i++) {
            address facetAddress_ = _ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = _ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        LibDiamond.DiamondStorage storage _ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = _ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage _ds = LibDiamond.diamondStorage();
        facetAddresses_ = _ds.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage _ds = LibDiamond.diamondStorage();
        facetAddress_ = _ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage _ds = LibDiamond.diamondStorage();
        return _ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */

import { LibDiamond } from "./LibDiamond.sol";
import { IDiamondLoupe } from "./IDiamondLoupe.sol";

contract DiamondLoupeFacet is IDiamondLoupe {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage _ds = LibDiamond.diamondStorage();
        uint256 _numFacets = _ds.facetAddresses.length;
        facets_ = new Facet[](_numFacets);
        for (uint256 i; i < _numFacets; i++) {
            address facetAddress_ = _ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = _ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        LibDiamond.DiamondStorage storage _ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = _ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage _ds = LibDiamond.diamondStorage();
        facetAddresses_ = _ds.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage _ds = LibDiamond.diamondStorage();
        facetAddress_ = _ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    event DiamondCut(FacetCut[] diamondCut, address init, bytes data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

/* solhint-disable reason-string, avoid-low-level-calls */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 * /*****************************************************************************
 */
import { IDiamondCut } from "./IDiamondCut.sol";

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds_) {
        bytes32 _position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds_.slot := _position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage _ds = diamondStorage();
        address _previousOwner = _ds.contractOwner;
        _ds.contractOwner = _newOwner;
        emit OwnershipTransferred(_previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] diamondCut, address init, bytes data);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 _facetIndex; _facetIndex < _diamondCut.length; _facetIndex++) {
            IDiamondCut.FacetCutAction _action = _diamondCut[_facetIndex].action;
            if (_action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[_facetIndex].facetAddress, _diamondCut[_facetIndex].functionSelectors);
            } else if (_action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[_facetIndex].facetAddress, _diamondCut[_facetIndex].functionSelectors);
            } else if (_action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[_facetIndex].facetAddress, _diamondCut[_facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage _ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 _selectorPosition = uint96(_ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (_selectorPosition == 0) {
            addFacet(_ds, _facetAddress);
        }
        for (uint256 _selectorIndex; _selectorIndex < _functionSelectors.length; _selectorIndex++) {
            bytes4 _selector = _functionSelectors[_selectorIndex];
            address _oldFacetAddress = _ds.selectorToFacetAndPosition[_selector].facetAddress;
            require(_oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(_ds, _selector, _selectorPosition, _facetAddress);
            _selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage _ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 _selectorPosition = uint96(_ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (_selectorPosition == 0) {
            addFacet(_ds, _facetAddress);
        }
        for (uint256 _selectorIndex; _selectorIndex < _functionSelectors.length; _selectorIndex++) {
            bytes4 _selector = _functionSelectors[_selectorIndex];
            address _oldFacetAddress = _ds.selectorToFacetAndPosition[_selector].facetAddress;
            require(_oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(_ds, _oldFacetAddress, _selector);
            addFunction(_ds, _selector, _selectorPosition, _facetAddress);
            _selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage _ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 _selectorIndex; _selectorIndex < _functionSelectors.length; _selectorIndex++) {
            bytes4 _selector = _functionSelectors[_selectorIndex];
            address _oldFacetAddress = _ds.selectorToFacetAndPosition[_selector].facetAddress;
            removeFunction(_ds, _oldFacetAddress, _selector);
        }
    }

    function addFacet(DiamondStorage storage _ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(_ds.facetAddresses.length);
        _ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage _ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        _ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = uint16(_selectorPosition);
        _ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage _ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 _selectorPosition = _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 _lastSelectorPosition = _ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with _lastSelector
        if (_selectorPosition != _lastSelectorPosition) {
            bytes4 _lastSelector = _ds.facetFunctionSelectors[_facetAddress].functionSelectors[_lastSelectorPosition];
            _ds.facetFunctionSelectors[_facetAddress].functionSelectors[_selectorPosition] = _lastSelector;
            _ds.selectorToFacetAndPosition[_lastSelector].functionSelectorPosition = uint16(_selectorPosition);
        }
        // delete the last selector
        _ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete _ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (_lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 _lastFacetAddressPosition = _ds.facetAddresses.length - 1;
            uint256 _facetAddressPosition = _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (_facetAddressPosition != _lastFacetAddressPosition) {
                address _lastFacetAddress = _ds.facetAddresses[_lastFacetAddressPosition];
                _ds.facetAddresses[_facetAddressPosition] = _lastFacetAddress;
                _ds.facetFunctionSelectors[_lastFacetAddress].facetAddressPosition = uint16(_facetAddressPosition);
            }
            _ds.facetAddresses.pop();
            delete _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool _success, bytes memory _error) = _init.delegatecall(_calldata);
            if (!_success) {
                if (_error.length > 0) {
                    // bubble up the _error
                    assembly {
                        revert(add(32, _error), mload(_error))
                    }
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 _contractSize;
        assembly {
            _contractSize := extcodesize(_contract)
        }
        require(_contractSize > 0, _errorMessage);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { EmitterBase, LibEmitter, IEmitter } from "./EmitterBase.sol";
import { LibEmitterStorage } from "./LibEmitterStorage.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";
import { LibUtilities } from "src/libraries/LibUtilities.sol";
import { LibAccessControlRoles } from "src/libraries/LibAccessControlRoles.sol";
import { LibOrganizationManager } from "src/libraries/LibOrganizationManager.sol";
import { EmittingCollectionType, EmittingInfo, EmittingRateChangeBehavior } from "src/interfaces/IEmitter.sol";

contract Emitter is EmitterBase {
    /**
     * @inheritdoc IEmitter
     */
    function Emitter_init() external facetInitializer(keccak256("Emitter_init")) {
        __EmitterBase_init();
    }

    function createEmittingInstance(
        bytes32 _organizationId,
        EmittingCollectionType _collectionType,
        address _collection,
        uint64 _emittingFrequencyInSeconds,
        uint256 _amountToEmitPerSecond,
        uint64 _startTime,
        uint64 _endTime,
        EmittingRateChangeBehavior _rateChangeBehavior,
        uint256 _tokenId,
        bytes4 _emitFunctionSelector
    ) external whenNotPaused {
        LibEmitter.createEmittingInstance(
            _organizationId,
            _collectionType,
            _collection,
            _emittingFrequencyInSeconds,
            _amountToEmitPerSecond,
            _startTime,
            _endTime,
            _rateChangeBehavior,
            _tokenId,
            _emitFunctionSelector
        );
    }

    function deactivateEmittingInstance(uint64 _emittingId) external whenNotPaused {
        LibEmitter.deactivateEmittingInstance(_emittingId);
    }

    function changeEmittingInstanceCreator(uint64 _emittingId, address _newOwner) external whenNotPaused {
        LibEmitter.changeEmittingInstanceCreator(_emittingId, _newOwner);
    }

    function changeEmittingInstanceFrequencyAndRate(
        uint64 _emittingId,
        uint64 _emittingFrequencyInSeconds,
        uint256 _amountToEmitPerSecond
    ) external whenNotPaused {
        LibEmitter.changeEmittingInstanceFrequencyAndRate(
            _emittingId, _emittingFrequencyInSeconds, _amountToEmitPerSecond
        );
    }

    function changeEmittingInstanceCanClaim(
        uint64 _emittingId,
        address _address,
        bool _canClaim
    ) external whenNotPaused {
        LibEmitter.changeEmittingInstanceCanClaim(_emittingId, _address, _canClaim);
    }

    function changeEmittingInstanceApproval(uint64 _emittingId, bool _isApproved) external whenNotPaused {
        LibEmitter.changeEmittingInstanceApproval(_emittingId, _isApproved);
    }

    function claim(uint64 _emittingId) external whenNotPaused {
        LibEmitter.claim(_emittingId);
    }

    function amountToClaim(uint64 _emittingId) public view returns (uint256) {
        (uint256 _retVal,) = LibEmitter.amountToClaim(_emittingId, false);
        return _retVal;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { FacetInitializable } from "src/utils/FacetInitializable.sol";

import { LibEmitter } from "src/emitter/LibEmitter.sol";
import { LibEmitterStorage } from "src/emitter/LibEmitterStorage.sol";
import { IEmitter } from "src/interfaces/IEmitter.sol";
import { Modifiers } from "src/Modifiers.sol";
import { SupportsMetaTx } from "src/metatx/SupportsMetaTx.sol";

abstract contract EmitterBase is FacetInitializable, IEmitter, Modifiers, SupportsMetaTx {
    function __EmitterBase_init() internal onlyFacetInitializing {
        LibEmitterStorage.layout().currentEmittingId = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC721/IERC721Upgradeable.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import { LibAccessControlRoles } from "src/libraries/LibAccessControlRoles.sol";
import { LibOrganizationManager } from "src/libraries/LibOrganizationManager.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";
import { EmittingCollectionType, EmittingInfo, EmittingRateChangeBehavior } from "src/interfaces/IEmitter.sol";

import { LibEmitterStorage } from "src/emitter/LibEmitterStorage.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-diamond/utils/AddressUpgradeable.sol";

/**
 * @title Emitter Library
 * @dev This library is used to implement features that use/update storage data for the Emitter contracts
 */
library LibEmitter {
    function createEmittingInstance(
        bytes32 _organizationId,
        EmittingCollectionType _collectionType,
        address _collection,
        uint64 _emittingFrequencyInSeconds,
        uint256 _amountToEmitPerSecond,
        uint64 _startTime,
        uint64 _endTime,
        EmittingRateChangeBehavior _rateChangeBehavior,
        uint256 _tokenId,
        bytes4 _emitFunctionSelector
    ) internal {
        LibOrganizationManager.requireOrganizationValid(_organizationId);

        if (_startTime == 0) {
            revert LibEmitterStorage.InvalidStartTime();
        }

        uint64 _emittingId = LibEmitterStorage.layout().currentEmittingId;
        LibEmitterStorage.layout().currentEmittingId++;

        EmittingInfo storage _emittingInfo = LibEmitterStorage.layout().emittingIdToInfo[_emittingId];
        _emittingInfo.organizationId = _organizationId;
        _emittingInfo.collectionType = _collectionType;
        _emittingInfo.collection = _collection;
        _emittingInfo.startTime = _startTime;
        _emittingInfo.lastClaimWindowTime = _startTime;
        _emittingInfo.rateChangeBehavior = _rateChangeBehavior;
        _emittingInfo.tokenId = _tokenId;
        _emittingInfo.emitFunctionSelector = _emitFunctionSelector;
        _emittingInfo.isActive = true;

        emit LibEmitterStorage.EmittingInstanceCreated(
            _emittingId,
            _organizationId,
            _collectionType,
            _collection,
            _startTime,
            _rateChangeBehavior,
            _tokenId,
            _emitFunctionSelector
        );

        _setEmittingInstanceCreator(_emittingId, LibMeta._msgSender());
        _setEmittingInstanceCanClaim(_emittingId, LibMeta._msgSender(), true);
        _setEmittingInstanceFrequencyAndRate(_emittingId, _emittingFrequencyInSeconds, _amountToEmitPerSecond);
        _setEmittingInstanceEndTime(_emittingId, _endTime);
    }

    function deactivateEmittingInstance(uint64 _emittingId) internal {
        _requireEmittingInstanceCreator(_emittingId);
        _requireEmittingInstanceActive(_emittingId);

        EmittingInfo storage _emittingInfo = LibEmitterStorage.layout().emittingIdToInfo[_emittingId];

        _emittingInfo.isActive = false;

        emit LibEmitterStorage.EmittingInstanceDeactivated(_emittingId);
    }

    function changeEmittingInstanceCreator(uint64 _emittingId, address _newOwner) internal {
        _requireEmittingInstanceCreator(_emittingId);

        _setEmittingInstanceCreator(_emittingId, _newOwner);
    }

    function changeEmittingInstanceFrequencyAndRate(
        uint64 _emittingId,
        uint64 _emittingFrequencyInSeconds,
        uint256 _amountToEmitPerSecond
    ) internal {
        _requireEmittingInstanceCreator(_emittingId);

        _setEmittingInstanceFrequencyAndRate(_emittingId, _emittingFrequencyInSeconds, _amountToEmitPerSecond);

        EmittingInfo storage _emittingInfo = LibEmitterStorage.layout().emittingIdToInfo[_emittingId];
        _emittingInfo.isApprovedByCollection = false;

        emit LibEmitterStorage.EmittingInstanceCollectionApprovalChanged(_emittingId, _emittingInfo.collection, false);
    }

    function changeEmittingInstanceCanClaim(uint64 _emittingId, address _address, bool _canClaim) internal {
        _requireEmittingInstanceCreator(_emittingId);

        _setEmittingInstanceCanClaim(_emittingId, _address, _canClaim);
    }

    function changeEmittingInstanceApproval(uint64 _emittingId, bool _isApproved) internal {
        _requireEmittingInstanceActive(_emittingId);

        EmittingInfo storage _emittingInfo = LibEmitterStorage.layout().emittingIdToInfo[_emittingId];

        require(
            LibAccessControlRoles.isCollectionAdmin(LibMeta._msgSender(), _emittingInfo.collection),
            "Not collection admin"
        );

        _emittingInfo.isApprovedByCollection = _isApproved;

        emit LibEmitterStorage.EmittingInstanceCollectionApprovalChanged(
            _emittingId, _emittingInfo.collection, _isApproved
        );
    }

    function claim(uint64 _emittingId) internal {
        _requireEmittingInstanceActive(_emittingId);
        _requireEmittingInstanceCanClaim(_emittingId);
        _requireEmittingInstanceApproved(_emittingId);

        (uint256 _amountToClaim, uint64 _newLastClaimWindowTime) = amountToClaim(_emittingId, false);

        if (_amountToClaim == 0) {
            return;
        }

        bytes4 _functionSelector = LibEmitterStorage.layout().emittingIdToInfo[_emittingId].emitFunctionSelector;

        address _collection = LibEmitterStorage.layout().emittingIdToInfo[_emittingId].collection;

        EmittingCollectionType _collectionType = LibEmitterStorage.layout().emittingIdToInfo[_emittingId].collectionType;

        LibEmitterStorage.layout().emittingIdToInfo[_emittingId].lastClaimWindowTime = _newLastClaimWindowTime;

        delete LibEmitterStorage
            .layout()
            .emittingIdToInfo[_emittingId]
            .additionalAmountToClaim;

        if (_collectionType == EmittingCollectionType.ERC20) {
            AddressUpgradeable.functionCall(
                _collection, abi.encodePacked(_functionSelector, abi.encode(LibMeta._msgSender()), _amountToClaim)
            );
        } else {
            // 1155
            AddressUpgradeable.functionCall(
                _collection,
                abi.encodePacked(
                    _functionSelector,
                    abi.encode(LibMeta._msgSender()),
                    LibEmitterStorage.layout().emittingIdToInfo[_emittingId].tokenId,
                    _amountToClaim
                )
            );
        }
    }

    function amountToClaim(uint64 _emittingId, bool _includePartialAmount) internal view returns (uint256, uint64) {
        EmittingInfo storage _emittingInfo = LibEmitterStorage.layout().emittingIdToInfo[_emittingId];

        if (!_emittingInfo.isActive) {
            return (0, 0);
        }

        uint256 _currentTimeForCalculation = _emittingInfo.endTime != 0 && block.timestamp > _emittingInfo.endTime
            ? _emittingInfo.endTime
            : block.timestamp;
        uint256 _timeSinceLastClaimWindow = _currentTimeForCalculation < _emittingInfo.lastClaimWindowTime
            ? 0
            : _currentTimeForCalculation - _emittingInfo.lastClaimWindowTime;

        uint256 _numberOfWindowsToClaim = _timeSinceLastClaimWindow / _emittingInfo.emittingFrequencyInSeconds;
        uint256 _amountToClaim = (
            _numberOfWindowsToClaim * _emittingInfo.emittingFrequencyInSeconds * _emittingInfo.amountToEmitPerSecond
        ) + _emittingInfo.additionalAmountToClaim;

        if (_includePartialAmount) {
            _amountToClaim += (_timeSinceLastClaimWindow % _emittingInfo.emittingFrequencyInSeconds)
                * _emittingInfo.amountToEmitPerSecond;
        }

        if (_amountToClaim == 0) {
            return (0, 0);
        }

        if (!_includePartialAmount && _emittingInfo.collectionType == EmittingCollectionType.ERC1155) {
            _amountToClaim = _amountToClaim / 1 ether;
        }

        return (
            _amountToClaim,
            _includePartialAmount
                ? uint64(block.timestamp)
                : uint64(
                    _emittingInfo.lastClaimWindowTime + (_numberOfWindowsToClaim * _emittingInfo.emittingFrequencyInSeconds)
                )
        );
    }

    function _setEmittingInstanceFrequencyAndRate(
        uint64 _emittingId,
        uint64 _emittingFrequencyInSeconds,
        uint256 _amountToEmitPerSecond
    ) private {
        EmittingInfo storage _emittingInfo = LibEmitterStorage.layout().emittingIdToInfo[_emittingId];

        bool _isSettingInitially = _emittingInfo.emittingFrequencyInSeconds == 0;

        if (_emittingFrequencyInSeconds == 0 || _amountToEmitPerSecond == 0) {
            revert LibEmitterStorage.BadEmittingRate();
        }

        if (!_isSettingInitially) {
            (uint256 _amountToClaim,) =
                amountToClaim(_emittingId, _emittingInfo.rateChangeBehavior == EmittingRateChangeBehavior.CLAIM_PARTIAL);

            _emittingInfo.additionalAmountToClaim = _amountToClaim;
            _emittingInfo.lastClaimWindowTime = uint64(block.timestamp);
        }

        _emittingInfo.emittingFrequencyInSeconds = _emittingFrequencyInSeconds;
        _emittingInfo.amountToEmitPerSecond = _amountToEmitPerSecond;

        emit LibEmitterStorage.EmittingInstanceRateChanged(
            _emittingId, _emittingFrequencyInSeconds, _amountToEmitPerSecond
        );
    }

    function _setEmittingInstanceEndTime(uint64 _emittingId, uint64 _endTime) private {
        EmittingInfo storage _emittingInfo = LibEmitterStorage.layout().emittingIdToInfo[_emittingId];

        if (_endTime != 0) {
            if (_emittingInfo.startTime >= _endTime) {
                revert LibEmitterStorage.BadEndTime();
            }
        }

        _emittingInfo.endTime = _endTime;

        emit LibEmitterStorage.EmittingInstanceEndTimeChanged(_emittingId, _endTime);
    }

    function _requireEmittingInstanceCreator(uint64 _emittingId) private view {
        if (LibMeta._msgSender() != LibEmitterStorage.layout().emittingIdToInfo[_emittingId].creator) {
            revert LibEmitterStorage.InstanceCreatorOnly();
        }
    }

    function _requireEmittingInstanceCanClaim(uint64 _emittingId) private view {
        if (!LibEmitterStorage.layout().emittingIdToInfo[_emittingId].addressToCanClaim[LibMeta._msgSender()]) {
            revert LibEmitterStorage.ApprovedClaimerOnly();
        }
    }

    function _requireEmittingInstanceActive(uint64 _emittingId) private view {
        if (!LibEmitterStorage.layout().emittingIdToInfo[_emittingId].isActive) {
            revert LibEmitterStorage.InstanceDeactivated();
        }
    }

    function _requireEmittingInstanceApproved(uint64 _emittingId) private view {
        if (!LibEmitterStorage.layout().emittingIdToInfo[_emittingId].isApprovedByCollection) {
            revert LibEmitterStorage.CollectionNotApproved();
        }
    }

    function _setEmittingInstanceCreator(uint64 _emittingId, address _creator) private {
        if (_creator == address(0)) {
            revert LibEmitterStorage.BadCreator();
        }

        address _oldCreator = LibEmitterStorage.layout().emittingIdToInfo[_emittingId].creator;
        LibEmitterStorage.layout().emittingIdToInfo[_emittingId].creator = _creator;

        emit LibEmitterStorage.EmittingInstanceCreatorChanged(_emittingId, _oldCreator, _creator);
    }

    function _setEmittingInstanceCanClaim(uint64 _emittingId, address _address, bool _canClaim) private {
        LibEmitterStorage.layout().emittingIdToInfo[_emittingId].addressToCanClaim[_address] = _canClaim;

        emit LibEmitterStorage.EmittingInstanceCanClaimChanged(_emittingId, _address, _canClaim);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { EmittingCollectionType, EmittingInfo, EmittingRateChangeBehavior } from "src/interfaces/IEmitter.sol";

/**
 * @title LibEmitterStorage library
 * @notice This library contains the storage layout and events/errors for the Emitter contract.
 */
library LibEmitterStorage {
    struct Layout {
        /**
         * @dev Store all information about the emitting
         */
        mapping(uint64 => EmittingInfo) emittingIdToInfo;
        uint64 currentEmittingId;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.emitter");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    event EmittingInstanceCreated(
        uint64 indexed emittingId,
        bytes32 organizationId,
        EmittingCollectionType collectionType,
        address collection,
        uint256 startTime,
        EmittingRateChangeBehavior rateChangeBehavior,
        uint256 tokenId,
        bytes4 emitFunctionSelector
    );

    event EmittingInstanceCreatorChanged(uint64 indexed emittingId, address oldCreator, address newCreator);

    event EmittingInstanceEndTimeChanged(uint64 indexed emittingId, uint256 endTime);

    event EmittingInstanceRateChanged(
        uint64 indexed emittingId, uint256 emittingFrequencyInSeconds, uint256 amountToEmitPerSecond
    );

    event EmittingInstanceCanClaimChanged(uint64 indexed emittingId, address user, bool canClaim);

    event EmittingInstanceCollectionApprovalChanged(uint64 indexed emittingId, address collection, bool isApproved);

    event EmittingInstanceClaimed(
        uint64 indexed emittingId, address claimedBy, uint256 amountClaimed, uint256 lastClaimWindowTime
    );

    event EmittingInstanceDeactivated(uint64 indexed emittingId);

    error InvalidStartTime();
    error BadEmittingRate();
    error BadEndTime();
    error BadCreator();
    error InstanceCreatorOnly();
    error ApprovedClaimerOnly();
    error CollectionNotApproved();
    error InstanceDeactivated();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    GuildManagerSettings, LibGuildManager, IGuildManager, LibOrganizationManager
} from "./GuildManagerSettings.sol";
import { ICustomGuildManager } from "src/interfaces/ICustomGuildManager.sol";
import { IGuildToken } from "src/interfaces/IGuildToken.sol";
import { GuildInfo, GuildUserInfo, GuildUserStatus, GuildStatus } from "src/interfaces/IGuildManager.sol";
import { LibUtilities } from "src/libraries/LibUtilities.sol";
import { LibAccessControlRoles } from "src/libraries/LibAccessControlRoles.sol";

contract GuildManager is GuildManagerSettings {
    /**
     * @inheritdoc IGuildManager
     */
    function GuildManager_init(address _guildTokenImplementationAddress)
        external
        facetInitializer(keccak256("GuildManager_init"))
    {
        __GuildManagerSettings_init();
        LibGuildManager.setGuildTokenBeacon(_guildTokenImplementationAddress);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function createGuild(bytes32 _organizationId)
        external
        contractsAreSet
        whenNotPaused
        supportsMetaTx(_organizationId)
    {
        LibGuildManager.createGuild(_organizationId);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function terminateGuild(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _reason
    ) external contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.terminateGuild(_organizationId, _guildId, _reason);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function grantGuildTerminator(
        address _account,
        bytes32 _organizationId,
        uint32 _guildId
    ) external contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.requireGuildOwner(_organizationId, _guildId, "GRANT_TERMINATOR_ROLE");
        LibAccessControlRoles.grantGuildTerminator(_account, _organizationId, _guildId);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function grantGuildAdmin(
        address _account,
        bytes32 _organizationId,
        uint32 _guildId
    ) external contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.requireGuildOwner(_organizationId, _guildId, "GRANT_ADMIN_ROLE");
        LibAccessControlRoles.grantGuildAdmin(_account, _organizationId, _guildId);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function updateGuildInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _name,
        string calldata _description
    ) external contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.requireGuildOwner(_organizationId, _guildId, "UPDATE_INFO");
        LibGuildManager.setGuildInfo(_organizationId, _guildId, _name, _description);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function updateGuildSymbol(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _symbolImageData,
        bool _isSymbolOnChain
    ) external contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.requireGuildOwner(_organizationId, _guildId, "UPDATE_SYMBOL");
        LibGuildManager.setGuildSymbol(_organizationId, _guildId, _symbolImageData, _isSymbolOnChain);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function adjustMemberLevel(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user,
        uint8 _memberLevel
    ) external whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.adjustMemberLevel(_organizationId, _guildId, _user, _memberLevel);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function inviteUsers(
        bytes32 _organizationId,
        uint32 _guildId,
        address[] calldata _users
    ) external whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.inviteUsers(_organizationId, _guildId, _users);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function acceptInvitation(
        bytes32 _organizationId,
        uint32 _guildId
    ) external whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.acceptInvitation(_organizationId, _guildId);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function changeGuildAdmins(
        bytes32 _organizationId,
        uint32 _guildId,
        address[] calldata _users,
        bool[] calldata _isAdmins
    ) external whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.changeGuildAdmins(_organizationId, _guildId, _users, _isAdmins);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function changeGuildOwner(
        bytes32 _organizationId,
        uint32 _guildId,
        address _newOwner
    ) external whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.changeGuildOwner(_organizationId, _guildId, _newOwner);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function leaveGuild(
        bytes32 _organizationId,
        uint32 _guildId
    ) external whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.leaveGuild(_organizationId, _guildId);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function kickOrRemoveInvitations(
        bytes32 _organizationId,
        uint32 _guildId,
        address[] calldata _users
    ) external whenNotPaused supportsMetaTx(_organizationId) {
        LibGuildManager.kickOrRemoveInvitations(_organizationId, _guildId, _users);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function getGuildStatus(bytes32 _organizationId, uint32 _guildId) public view returns (GuildStatus) {
        return LibGuildManager.getGuildStatus(_organizationId, _guildId);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function userCanCreateGuild(bytes32 _organizationId, address _user) public view returns (bool) {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        return LibGuildManager.userCanCreateGuild(_organizationId, _user);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function getGuildMemberStatus(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) public view returns (GuildUserStatus) {
        return LibGuildManager.getGuildUserInfo(_organizationId, _guildId, _user).userStatus;
    }

    /**
     * @inheritdoc IGuildManager
     */
    function getGuildMemberInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) public view returns (GuildUserInfo memory) {
        return LibGuildManager.getGuildUserInfo(_organizationId, _guildId, _user);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function isValidGuild(bytes32 _organizationId, uint32 _guildId) external view returns (bool) {
        return LibGuildManager.getGuildOrganizationInfo(_organizationId).guildIdCur > _guildId && _guildId != 0;
    }

    /**
     * @inheritdoc IGuildManager
     */
    function guildTokenAddress(bytes32 _organizationId) external view returns (address) {
        return LibGuildManager.getGuildOrganizationInfo(_organizationId).tokenAddress;
    }

    /**
     * @inheritdoc IGuildManager
     */
    function guildName(bytes32 _organizationId, uint32 _guildId) external view returns (string memory) {
        return LibGuildManager.getGuildInfo(_organizationId, _guildId).name;
    }

    /**
     * @inheritdoc IGuildManager
     */
    function guildDescription(bytes32 _organizationId, uint32 _guildId) external view returns (string memory) {
        return LibGuildManager.getGuildInfo(_organizationId, _guildId).description;
    }

    /**
     * @inheritdoc IGuildManager
     */
    function guildOwner(bytes32 _organizationId, uint32 _guildId) external view returns (address) {
        return LibGuildManager.getGuildInfo(_organizationId, _guildId).currentOwner;
    }

    /**
     * @inheritdoc IGuildManager
     */
    function maxUsersForGuild(bytes32 _organizationId, uint32 _guildId) public view returns (uint32) {
        return LibGuildManager.getMaxUsersForGuild(_organizationId, _guildId);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function guildSymbolInfo(
        bytes32 _organizationId,
        uint32 _guildId
    ) external view returns (string memory _symbolImageData, bool _isSymbolOnChain) {
        GuildInfo storage _guildInfo = LibGuildManager.getGuildInfo(_organizationId, _guildId);
        _symbolImageData = _guildInfo.symbolImageData;
        _isSymbolOnChain = _guildInfo.isSymbolOnChain;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { FacetInitializable } from "src/utils/FacetInitializable.sol";

import { LibGuildManager } from "src/libraries/LibGuildManager.sol";
import { IGuildManager } from "src/interfaces/IGuildManager.sol";
import { Modifiers } from "src/Modifiers.sol";
import { SupportsMetaTx } from "src/metatx/SupportsMetaTx.sol";

abstract contract GuildManagerBase is FacetInitializable, IGuildManager, Modifiers, SupportsMetaTx {
    function __GuildManagerBase_init() internal onlyFacetInitializing {
        _pause();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ADMIN_ROLE } from "src/libraries/LibAccessControlRoles.sol";
import { GuildManagerBase, LibGuildManager, IGuildManager } from "./GuildManagerBase.sol";

abstract contract GuildManagerContracts is GuildManagerBase {
    function __GuildManagerContracts_init() internal onlyFacetInitializing {
        GuildManagerBase.__GuildManagerBase_init();
    }

    function setContracts(address _guildTokenImplementationAddress) external onlyRole(ADMIN_ROLE) {
        LibGuildManager.setGuildTokenBeacon(_guildTokenImplementationAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns (bool) {
        return address(LibGuildManager.getGuildTokenBeacon()) != address(0);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function guildTokenImplementation() external view returns (address) {
        // Beacon hasn't been setup yet.
        if (address(LibGuildManager.getGuildTokenBeacon()) == address(0)) {
            return address(0);
        }

        return LibGuildManager.getGuildTokenBeacon().implementation();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ADMIN_ROLE } from "src/libraries/LibAccessControlRoles.sol";

import { GuildCreationRule, MaxUsersPerGuildRule, GuildOrganizationInfo } from "src/interfaces/IGuildManager.sol";
import { IGuildToken } from "src/interfaces/IGuildToken.sol";
import { GuildManagerContracts, LibGuildManager, IGuildManager } from "./GuildManagerContracts.sol";
import { LibOrganizationManager } from "src/libraries/LibOrganizationManager.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";

abstract contract GuildManagerSettings is GuildManagerContracts {
    function __GuildManagerSettings_init() internal onlyFacetInitializing {
        GuildManagerContracts.__GuildManagerContracts_init();
    }

    /**
     * @inheritdoc IGuildManager
     */
    function initializeForOrganization(
        bytes32 _organizationId,
        uint8 _maxGuildsPerUser,
        uint32 _timeoutAfterLeavingGuild,
        GuildCreationRule _guildCreationRule,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant,
        address _customGuildManagerAddress,
        bool _requireTreasureTagForGuilds
    ) external contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.initializeForOrganization(_organizationId);

        LibGuildManager.setMaxGuildsPerUser(_organizationId, _maxGuildsPerUser);
        LibGuildManager.setTimeoutAfterLeavingGuild(_organizationId, _timeoutAfterLeavingGuild);
        LibGuildManager.setGuildCreationRule(_organizationId, _guildCreationRule);
        LibGuildManager.setMaxUsersPerGuild(_organizationId, _maxUsersPerGuildRule, _maxUsersPerGuildConstant);
        LibGuildManager.setCustomGuildManagerAddress(_organizationId, _customGuildManagerAddress);
        LibGuildManager.setRequireTreasureTagForGuilds(_organizationId, _requireTreasureTagForGuilds);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setMaxGuildsPerUser(
        bytes32 _organizationId,
        uint8 _maxGuildsPerUser
    ) external onlyRole(ADMIN_ROLE) contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setMaxGuildsPerUser(_organizationId, _maxGuildsPerUser);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setTimeoutAfterLeavingGuild(
        bytes32 _organizationId,
        uint32 _timeoutAfterLeavingGuild
    ) external onlyRole(ADMIN_ROLE) contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setTimeoutAfterLeavingGuild(_organizationId, _timeoutAfterLeavingGuild);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setGuildCreationRule(
        bytes32 _organizationId,
        GuildCreationRule _guildCreationRule
    ) external onlyRole(ADMIN_ROLE) contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setGuildCreationRule(_organizationId, _guildCreationRule);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setMaxUsersPerGuild(
        bytes32 _organizationId,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant
    ) external onlyRole(ADMIN_ROLE) contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setMaxUsersPerGuild(_organizationId, _maxUsersPerGuildRule, _maxUsersPerGuildConstant);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setRequireTreasureTagForGuilds(
        bytes32 _organizationId,
        bool _requireTreasureTagForGuilds
    ) external onlyRole(ADMIN_ROLE) contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setRequireTreasureTagForGuilds(_organizationId, _requireTreasureTagForGuilds);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setCustomGuildManagerAddress(
        bytes32 _organizationId,
        address _customGuildManagerAddress
    ) external onlyRole(ADMIN_ROLE) contractsAreSet whenNotPaused supportsMetaTx(_organizationId) {
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        LibOrganizationManager.requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);

        LibGuildManager.setCustomGuildManagerAddress(_organizationId, _customGuildManagerAddress);
    }

    /**
     * @inheritdoc IGuildManager
     */
    function setTreasureTagNFTAddress(address _treasureTagNFTAddress) external onlyRole(ADMIN_ROLE) {
        LibGuildManager.setTreasureTagNFTAddress(_treasureTagNFTAddress);
    }

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IGuildManager
     */
    function getGuildOrganizationInfo(bytes32 _organizationId) external view returns (GuildOrganizationInfo memory) {
        return LibGuildManager.getGuildOrganizationInfo(_organizationId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {
    IGuildManager,
    GuildInfo,
    GuildCreationRule,
    GuildUserInfo,
    GuildUserStatus,
    GuildOrganizationInfo,
    GuildOrganizationUserInfo,
    MaxUsersPerGuildRule
} from "src/interfaces/IGuildManager.sol";
import { IGuildToken } from "src/interfaces/IGuildToken.sol";
import { ICustomGuildManager } from "src/interfaces/ICustomGuildManager.sol";

import { OrganizationManagerStorage } from "src/organizations/OrganizationManagerStorage.sol";

/**
 * @title GuildManagerStorage library
 * @notice This library contains the storage layout and events/errors for the GuildManagerFacet contract.
 */
library GuildManagerStorage {
    struct Layout {
        /**
         * @dev The implementation of the guild token contract to create new contracts from
         */
        UpgradeableBeacon guildTokenBeacon;
        /**
         * @dev The organizationId is the key for this mapping
         */
        mapping(bytes32 => GuildOrganizationInfo) guildOrganizationInfo;
        /**
         * @dev The organizationId is the key for the first mapping, the guildId is the key for the second mapping
         */
        mapping(bytes32 => mapping(uint32 => GuildInfo)) organizationIdToGuildIdToInfo;
        /**
         * @dev The organizationId is the key for the first mapping, the user is the key for the second mapping
         */
        mapping(bytes32 => mapping(address => GuildOrganizationUserInfo)) organizationIdToAddressToInfo;
        /**
         * @dev The address of the treasureTag NFT contract (for ensuring user has a treasureTag when joining guilds)
         */
        address treasureTagNFTAddress;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.guildmanager");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    // Guild Management Events

    /**
     * @dev Emitted when a guild organization is initialized.
     * @param organizationId The ID of the guild's organization
     * @param tokenAddress The token address associated with the guild organization
     */
    event GuildOrganizationInitialized(bytes32 organizationId, address tokenAddress);

    /**
     * @dev Emitted when the timeout period after leaving a guild is updated.
     * @param organizationId The ID of the guild's organization
     * @param timeoutAfterLeavingGuild The new timeout period (in seconds)
     */
    event TimeoutAfterLeavingGuild(bytes32 organizationId, uint32 timeoutAfterLeavingGuild);

    /**
     * @dev Emitted when the maximum number of guilds per user is updated.
     * @param organizationId The ID of the guild's organization
     * @param maxGuildsPerUser The new maximum number of guilds per user
     */
    event MaxGuildsPerUserUpdated(bytes32 organizationId, uint8 maxGuildsPerUser);

    /**
     * @dev Emitted when the maximum number of users per guild is updated.
     * @param organizationId The ID of the guild's organization
     * @param rule The rule for maximum users per guild
     * @param maxUsersPerGuildConstant The new maximum number of users per guild constant
     */
    event MaxUsersPerGuildUpdated(bytes32 organizationId, MaxUsersPerGuildRule rule, uint32 maxUsersPerGuildConstant);

    /**
     * @dev Emitted when the guild creation rule is updated.
     * @param organizationId The ID of the guild's organization
     * @param creationRule The new guild creation rule
     */
    event GuildCreationRuleUpdated(bytes32 organizationId, GuildCreationRule creationRule);

    /**
     * @dev Emitted when the custom guild manager address is updated.
     * @param organizationId The ID of the guild's organization
     * @param customGuildManagerAddress The new custom guild manager address
     */
    event CustomGuildManagerAddressUpdated(bytes32 organizationId, address customGuildManagerAddress);

    /**
     * @dev Emitted when the requirement for a treasure tag is updated.
     * @param organizationId The ID of the guild's organization
     * @param requireTreasureTagForGuildsUpdated Whether this org requires treasure tags
     */
    event RequireTreasureTagForGuildsUpdated(bytes32 organizationId, bool requireTreasureTagForGuildsUpdated);

    /**
     * @dev Emitted when a members level has been updated.
     * @param organizationId The ID of the guild's organization
     * @param guildId The guild ID
     * @param user The user
     * @param memberLevel The new member level
     */
    event MemberLevelUpdated(bytes32 organizationId, uint32 guildId, address user, uint8 memberLevel);

    // Guild Events

    /**
     * @dev Emitted when a new guild is created.
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the newly created guild
     */
    event GuildCreated(bytes32 organizationId, uint32 guildId);

    /**
     * @dev Emitted when a guild is terminated.
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the terminated guild
     * @param terminator The address of the initiator of the termination
     * @param reason The reason for the termination
     */
    event GuildTerminated(bytes32 organizationId, uint32 guildId, address terminator, string reason);

    /**
     * @dev Emitted when a guild's information is updated.
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the guild being updated
     * @param name The updated guild name
     * @param description The updated guild description
     */
    event GuildInfoUpdated(bytes32 organizationId, uint32 guildId, string name, string description);

    /**
     * @dev Emitted when a guild's symbol is updated.
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the guild being updated
     * @param symbolImageData The updated guild symbol image data
     * @param isSymbolOnChain Whether the updated guild symbol is stored on-chain
     */
    event GuildSymbolUpdated(bytes32 organizationId, uint32 guildId, string symbolImageData, bool isSymbolOnChain);

    /**
     * @dev Emitted when a user's status in a guild is changed.
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the guild
     * @param user The address of the user whose status is changed
     * @param status The updated status of the user
     */
    event GuildUserStatusChanged(bytes32 organizationId, uint32 guildId, address user, GuildUserStatus status);

    // Errors

    /**
     * @dev Emitted when a user attempts to interact with a function gated to treasure tag holders.
     * @param user The address of the sender
     */
    error UserDoesNotOwnTreasureTag(address user);

    /**
     * @dev Emitted when a guild organization has already been initialized.
     * @param organizationId The ID of the guild's organization
     */
    error GuildOrganizationAlreadyInitialized(bytes32 organizationId);

    /**
     * @dev Emitted when a user is not allowed to create a guild.
     * @param organizationId The ID of the guild's organization
     * @param user The address of the user attempting to create a guild
     */
    error UserCannotCreateGuild(bytes32 organizationId, address user);

    /**
     * @dev Emitted when the sender is not the guild owner and tries to perform an owner-only action.
     * @param sender The address of the sender attempting the action
     * @param action A description of the attempted action
     */
    error NotGuildOwner(address sender, string action);

    /**
     * @dev Emitted when the sender is neither the guild owner nor an admin and tries to perform an owner or admin action.
     * @param sender The address of the sender attempting the action
     * @param action A description of the attempted action
     */
    error NotGuildOwnerOrAdmin(address sender, string action);

    /**
     * @dev Emitted when a guild is full and cannot accept new members.
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the guild
     */
    error GuildFull(bytes32 organizationId, uint32 guildId);

    /**
     * @dev Emitted when a user is already a member of a guild.
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the guild
     * @param user The address of the user attempting to join the guild
     */
    error UserAlreadyInGuild(bytes32 organizationId, uint32 guildId, address user);

    /**
     * @dev Emitted when a user is a member of too many guilds.
     * @param organizationId The ID of the guild's organization
     * @param user The address of the user attempting to join another guild
     */
    error UserInTooManyGuilds(bytes32 organizationId, address user);

    /**
     * @dev Emitted when a user is not a member of a guild.
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the guild
     * @param user The address of the user attempting to perform a guild member action
     */
    error UserNotGuildMember(bytes32 organizationId, uint32 guildId, address user);

    /**
     * @dev Emitted when an invalid address is provided.
     * @param user The address that is invalid
     */
    error InvalidAddress(address user);

    /**
     * @dev Error when trying to interact with a terminated or inactive guild.
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the guild
     */
    error GuildIsNotActive(bytes32 organizationId, uint32 guildId);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibAccessControlRoles, ADMIN_ROLE, ADMIN_GRANTER_ROLE } from "src/libraries/LibAccessControlRoles.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";
import { LibUtilities } from "src/libraries/LibUtilities.sol";
import { GuildTokenContracts, LibGuildToken, IGuildToken } from "./GuildTokenContracts.sol";

contract GuildToken is GuildTokenContracts {
    /**
     * @inheritdoc IGuildToken
     */
    function initialize(bytes32 _organizationId) external facetInitializer(keccak256("initialize")) {
        GuildTokenContracts.__GuildTokenContracts_init();
        LibGuildToken.setOrganizationId(_organizationId);
        // The guild manager is the one that creates the GuildToken.
        LibGuildToken.setGuildManager(LibMeta._msgSender());

        _setRoleAdmin(ADMIN_ROLE, ADMIN_GRANTER_ROLE);
        _grantRole(ADMIN_GRANTER_ROLE, LibMeta._msgSender());

        // Give admin to the owner. May be revoked to prevent permanent administrative rights as owner
        _grantRole(ADMIN_ROLE, LibMeta._msgSender());
    }

    /**
     * @inheritdoc IGuildToken
     */
    function adminMint(address _to, uint256 _id, uint256 _amount) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _mint(_to, _id, _amount, "");
    }

    /**
     * @inheritdoc IGuildToken
     */
    function adminBurn(address _account, uint256 _id, uint256 _amount) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _burn(_account, _id, _amount);
    }

    /**
     * @inheritdoc IGuildToken
     */
    function guildManager() external view returns (address manager_) {
        manager_ = address(LibGuildToken.getGuildManager());
    }

    /**
     * @inheritdoc IGuildToken
     */
    function organizationId() external view returns (bytes32 organizationId_) {
        organizationId_ = LibGuildToken.getOrganizationId();
    }

    /**
     * @dev Returns the URI for a given token ID
     * @param _tokenId The id of the token to query
     * @return URI of the given token
     */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return LibGuildToken.uri(_tokenId);
    }

    /**
     * @dev Adds the following restrictions to transferring guild tokens:
     * - Only token admins can transfer guild tokens
     * - Guild tokens cannot be transferred while the contract is paused
     */
    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual override {
        super._beforeTokenTransfer(_operator, _from, _to, _ids, _amounts, _data);
        LibUtilities.requireNotPaused();
        LibAccessControlRoles.requireRole(ADMIN_ROLE, LibMeta._msgSender());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ContextUpgradeable } from "@openzeppelin/contracts-diamond/utils/ContextUpgradeable.sol";

import { AccessControlFacet } from "src/access/AccessControlFacet.sol";
import { ERC1155Facet } from "src/token/ERC1155Facet.sol";
import { IGuildToken } from "src/interfaces/IGuildToken.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";
import { LibUtilities } from "src/libraries/LibUtilities.sol";
import { LibGuildToken } from "src/libraries/LibGuildToken.sol";

/**
 * @title Guild Token Contract
 * @notice Token contract to manage all of the guilds within an organization. Each tokenId is a different guild
 * @dev This contract is not expected to me part of a diamond since it is an asset contract that is dynamically created
 *  by the GuildManager contract.
 */
abstract contract GuildTokenBase is IGuildToken, AccessControlFacet, ERC1155Facet {
    function __GuildTokenBase_init() internal onlyFacetInitializing {
        __ERC1155Facet_init("");
        __AccessControlEnumerable_init();
    }

    /**
     * @dev Overrides and passes through to ERC1155
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(AccessControlFacet, ERC1155Facet)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    modifier whenNotPaused() {
        LibUtilities.requireNotPaused();
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ADMIN_ROLE } from "src/libraries/LibAccessControlRoles.sol";
import { GuildTokenBase, IGuildToken, LibGuildToken } from "./GuildTokenBase.sol";

abstract contract GuildTokenContracts is GuildTokenBase {
    function __GuildTokenContracts_init() internal onlyFacetInitializing {
        GuildTokenBase.__GuildTokenBase_init();
    }

    function setContracts(address _guildManagerAddress) external onlyRole(ADMIN_ROLE) {
        LibGuildToken.setGuildManager(_guildManagerAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "GuildToken: Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns (bool) {
        return address(LibGuildToken.getGuildManager()) != address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibBBase64 } from "src/libraries/LibBBase64.sol";
import { IGuildManager } from "src/interfaces/IGuildManager.sol";

/**
 * @title GuildTokenStorage library
 * @notice This library contains the storage layout and events/errors for the GuildTokenFacet contract.
 */
library GuildTokenStorage {
    struct Layout {
        /**
         * @notice The manager that created this guild collection.
         */
        IGuildManager guildManager;
        /**
         * @notice The organization this 1155 collection is associated to.
         */
        bytes32 organizationId;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.guildtoken");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    /**
     * @dev Emitted when a guild organization has already been initialized.
     * @param organizationId The ID of the guild organization
     */
    error GuildOrganizationAlreadyInitialized(bytes32 organizationId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomGuildManager {
    /**
     * @dev Indicates if the given user can create a guild.
     *  ONLY called if creationRule is set to CUSTOM_RULE
     * @param _user The user to check if they can create a guild.
     * @param _organizationId The organization to find the guild within.
     */
    function canCreateGuild(address _user, bytes32 _organizationId) external view returns (bool);

    /**
     * @dev Called after a guild is created by the given owner. Additional state changes
     *  or checks can be put here. For example, if staking is required, transfers can occur.
     * @param _owner The owner of the guild.
     * @param _organizationId The organization to find the guild within.
     * @param _createdGuildId The guild that was created.
     */
    function onGuildCreation(address _owner, bytes32 _organizationId, uint32 _createdGuildId) external;

    /**
     * @dev Returns the maximum number of users that can be in a guild.
     *  Only called if maxUsersPerGuildRule is set to CUSTOM_RULE.
     * @param _organizationId The organization to find the guild within.
     * @param _guildId The guild to find the max users for.
     */
    function maxUsersForGuild(bytes32 _organizationId, uint32 _guildId) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev The type of collection that is being emitted. ERC721 is currently not supported.
 */
enum EmittingCollectionType {
    ERC20,
    ERC1155
}

/**
 * @dev The behavior of the emitter when the rate of the instance is changed.
 * If using CLAIM_PARTIAL, anything that has accrued before the emittingFrequnecy,
 * will be given to the user on the next claim.
 *
 * If using DISCARD_PARTIAL, anything that has been accrued before the emittingFrequnecy will be given up.
 *
 * In either case, resesting the rate or frequency will reset the time the emitting starts.
 */
enum EmittingRateChangeBehavior {
    CLAIM_PARTIAL,
    DISCARD_PARTIAL
}

/**
 * @dev Tracks all things related to emitting instance.
 * @param organizationId The ID of the organization this instance belongs to.
 * @param addressToCanClaim A mapping of addresses to whether they can claim the accrued 1155/20.
 * @param startTime The time this accruel should begin. Must be greater than 0.
 * @param endTime The time this accruel should end. If 0, the accruel is indefinite.
 * @param lastClaimWindowTime The last time the emitting instance was claimed. The timestamp will land on a window.
 * i.e. Claim 1 ERC1155 every 10 minutes. If claim at the 15 minute mark, this values will be the timestamp equivalent to the 10 minute mark.
 * @param collectionType The type of collection being accrued.
 * @param isApprovedByCollection Indicates if the owner or admin of the collection has approved this emitting instance.
 * @param isActive Indicates if this instance is active.
 * @param emitFunctionSelector The function selector on the collection to emit. For ERC1155 and ERC20, the parameters must be the common "mint" parameters.
 * @param rateChangeBehavior See EmittingRateChangeBehavior.
 * @param collection The address of the collection being accrued.
 * @param creator The creator of the instance. This person has control over the rate and ending the instance.
 * @param emittingFrequencyInSeconds The frequency, in seconds, that the user gets to claim.
 * i.e. Claim 1 ERC1155 every 10 minutes. At 10-19 minutes, 1 will have been accrued. At 20 minutes, 2 will have been accrued.
 * @param amountToEmitPerSecond The rate to accrue per second. ERC1155 is denoted where 1 ether = 1 full item. ERC20 should be in its decimal.
 * @param additionalAmountToClaim Used when the rate/frequency changes to carry over any unclaimed amount.
 * @param tokenId The tokenId to emit. Only useful for ERC1155.
 */
struct EmittingInfo {
    // Slot 1
    bytes32 organizationId;
    // Slot 2
    mapping(address => bool) addressToCanClaim;
    // Slot 3
    uint64 startTime;
    uint64 endTime;
    uint64 lastClaimWindowTime;
    EmittingCollectionType collectionType;
    bool isApprovedByCollection;
    bool isActive;
    bytes4 emitFunctionSelector;
    EmittingRateChangeBehavior rateChangeBehavior;
    // Slot 4 (160/256)
    address collection;
    // Slot 5 (224/256)
    address creator;
    uint64 emittingFrequencyInSeconds;
    // Slot 6
    uint256 amountToEmitPerSecond;
    // Slot 7
    uint256 additionalAmountToClaim;
    // Slot 8
    uint256 tokenId;
}

interface IEmitter {
    /**
     * @dev Sets all necessary state and permissions for the contract
     */
    function Emitter_init() external;

    /**
     * @dev Creates a new emitting instance. For more information about each parameter, see EmittingInfo.
     */
    function createEmittingInstance(
        bytes32 _organizationId,
        EmittingCollectionType _collectionType,
        address _collection,
        uint64 _emittingFrequencyInSeconds,
        uint256 _amountToEmitPerSecond,
        uint64 _startTime,
        uint64 _endTime,
        EmittingRateChangeBehavior _rateChangeBehavior,
        uint256 _tokenId,
        bytes4 _emitFunctionSelector
    ) external;

    /**
     * @dev Permanently deactivates the given emitting instance. Can only be called by the creator. All pending claims will be lost.
     * @param _emittingId the ID of the emitting instance to deactivate.
     */
    function deactivateEmittingInstance(uint64 _emittingId) external;

    /**
     * @notice Changes the creator of the emitting instance from the caller to the passed in address.
     * @param _emittingId The ID of the emitting instance
     * @param _newOwner The new owner. Cannot be the zero address.
     */
    function changeEmittingInstanceCreator(uint64 _emittingId, address _newOwner) external;

    /**
     * @notice Changes the frequency and rate of the emitting instance. See EmittingInfo for more information on frequency and rate
     * This will reset the collection approval status. The collection owner will need to reapproved the instance.
     */
    function changeEmittingInstanceFrequencyAndRate(
        uint64 _emittingId,
        uint64 _emittingFrequencyInSeconds,
        uint256 _amountToEmitPerSecond
    ) external;

    /**
     * @notice Adds or removes the ability for an address to claim an emitting instance. Only the creator can perform this action.
     * @param _emittingId the ID of the instance
     * @param _address the address to allow/disallow
     * @param _canClaim whether the given address should be able to be claimed or not.
     */
    function changeEmittingInstanceCanClaim(uint64 _emittingId, address _address, bool _canClaim) external;

    /**
     * @notice Called by the collection owner to approve or unapprove an instance
     * @param _emittingId the ID of the instance
     * @param _isApproved whether to approve or unapprove the instance.
     */
    function changeEmittingInstanceApproval(uint64 _emittingId, bool _isApproved) external;

    /**
     * @notice Claims any pending amount. If there is nothing to claim, this function will return.
     * @param _emittingId the ID of the instance
     */
    function claim(uint64 _emittingId) external;

    /**
     * @notice Returns the amount of ERC1155/ERC20 available to claim for the given instance.
     * @param _emittingId the ID of the instance
     */
    function amountToClaim(uint64 _emittingId) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155Consumer {
    function mintFromWorld(address, uint256, uint256) external;
    function isAdmin(address) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Consumer {
    function mintFromWorld(address, uint256) external;
    function isAdmin(address) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Consumer {
    function mintFromWorld(address, uint256) external;
    function isAdmin(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Info related to a specific organization. Think of organizations as systems/games. i.e. Bridgeworld, The Beacon, etc.
 * @param guildIdCur The next available guild id within this organization for newly created guilds
 * @param creationRule Describes who can create a guild within this organization
 * @param maxGuildsPerUser The number of guilds a user can join within the organization.
 * @param timeoutAfterLeavingGuild The timeout a user has before joining a new guild after being kicked or leaving another guild
 * @param tokenAddress The address of the 1155 token that represents guilds created within this organization
 * @param maxUsersPerGuildRule Indicates how the max number of users per guild is decided
 * @param maxUsersPerGuildConstant If maxUsersPerGuildRule is set to CONSTANT, this is the max
 * @param customGuildManagerAddress A contract address that handles custom guild creation requirements (i.e owning specific NFTs).
 *  This is used for guild creation if @param creationRule == CUSTOM_RULE
 */
struct GuildOrganizationInfo {
    uint32 guildIdCur;
    GuildCreationRule creationRule;
    uint8 maxGuildsPerUser;
    uint32 timeoutAfterLeavingGuild;
    // Slot 4 (202/256)
    address tokenAddress;
    MaxUsersPerGuildRule maxUsersPerGuildRule;
    uint32 maxUsersPerGuildConstant;
    bool requireTreasureTagForGuilds;
    // Slot 5 (160/256) - customGuildManagerAddress
    address customGuildManagerAddress;
}

/**
 * @dev Contains information about a user at the organization user.
 * @param guildsIdsAMemberOf A list of guild ids they are currently a member/admin/owner of. Excludes invitations
 * @param timeUserLeftGuild The time this user last left or was kicked from a guild. Useful for guild joining timeouts
 */
struct GuildOrganizationUserInfo {
    // Slot 1
    uint32[] guildIdsAMemberOf;
    // Slot 2 (64/256)
    uint64 timeUserLeftGuild;
}

/**
 * @dev Information about a guild within a given organization.
 * @param name The name of this guild
 * @param description A description of this guild
 * @param symbolImageData A symbol that represents this guild
 * @param isSymbolOnChain Indicates if symbolImageData is on chain or is a URL
 * @param currentOwner The current owner of this guild
 * @param usersInGuild Keeps track of the number of users in the guild. This includes MEMBER, ADMIN, and OWNER
 * @param guildStatus Current guild status (active or terminated)
 */
struct GuildInfo {
    // Slot 1
    string name;
    // Slot 2
    string description;
    // Slot 3
    string symbolImageData;
    // Slot 4 (168/256)
    bool isSymbolOnChain;
    address currentOwner;
    uint32 usersInGuild;
    // Slot 5
    mapping(address => GuildUserInfo) addressToGuildUserInfo;
    // Slot 6 (8/256)
    GuildStatus guildStatus;
}

/**
 * @dev Provides information regarding a user in a specific guild
 * @param userStatus Indicates the status of this user (i.e member, admin, invited)
 * @param timeUserJoined The time this user joined this guild
 * @param memberLevel The member level of this user
 */
struct GuildUserInfo {
    // Slot 1 (8+64+8/256)
    GuildUserStatus userStatus;
    uint64 timeUserJoined;
    uint8 memberLevel;
}

enum GuildUserStatus {
    NOT_ASSOCIATED,
    INVITED,
    MEMBER,
    ADMIN,
    OWNER
}

enum GuildCreationRule {
    ANYONE,
    ADMIN_ONLY,
    CUSTOM_RULE
}

enum MaxUsersPerGuildRule {
    CONSTANT,
    CUSTOM_RULE
}

enum GuildStatus {
    ACTIVE,
    TERMINATED
}

interface IGuildManager {
    /**
     * @dev Sets all necessary state and permissions for the contract
     * @param _guildTokenImplementationAddress The token implementation address for guild token contracts to proxy to
     */
    function GuildManager_init(address _guildTokenImplementationAddress) external;

    /**
     * @dev Creates a new guild within the given organization. Must pass the guild creation requirements.
     * @param _organizationId The organization to create the guild within
     */
    function createGuild(bytes32 _organizationId) external;

    /**
     * @dev Terminates a provided guild
     * @param _organizationId The organization of the guild
     * @param _guildId The guild to terminate
     * @param _reason The reason of termination for the guild
     */
    function terminateGuild(bytes32 _organizationId, uint32 _guildId, string calldata _reason) external;

    /**
     * @dev Grants a given user guild terminator priviliges under a certain guild
     * @param _account The user to give terminator
     * @param _organizationId The org they belong to
     * @param _guildId The guild they belong to
     */
    function grantGuildTerminator(address _account, bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Grants a given user guild admin priviliges under a certain guild
     * @param _account The user to give admin
     * @param _organizationId The org they belong to
     * @param _guildId The guild they belong to
     */
    function grantGuildAdmin(address _account, bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Updates the guild info for the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to update
     * @param _name The new name of the guild
     * @param _description The new description of the guild
     */
    function updateGuildInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _name,
        string calldata _description
    ) external;

    /**
     * @dev Updates the guild symbol for the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to update
     * @param _symbolImageData The new symbol for the guild
     * @param _isSymbolOnChain Indicates if symbolImageData is on chain or is a URL
     */
    function updateGuildSymbol(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _symbolImageData,
        bool _isSymbolOnChain
    ) external;

    /**
     * @dev Adjusts a given users member level
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild the user is in
     * @param _user The user to adjust
     * @param _memberLevel The memberLevel to adjust to
     */
    function adjustMemberLevel(bytes32 _organizationId, uint32 _guildId, address _user, uint8 _memberLevel) external;

    /**
     * @dev Invites users to the given guild. Can only be done by admins or the guild owner.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to invite users to
     * @param _users The users to invite
     */
    function inviteUsers(bytes32 _organizationId, uint32 _guildId, address[] calldata _users) external;

    /**
     * @dev Accepts an invitation to the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to accept the invitation to
     */
    function acceptInvitation(bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Changes the admin status of the given users within the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to change the admin status of users within
     * @param _users The users to change the admin status of
     * @param _isAdmins Indicates if the users should be admins or not
     */
    function changeGuildAdmins(
        bytes32 _organizationId,
        uint32 _guildId,
        address[] calldata _users,
        bool[] calldata _isAdmins
    ) external;

    /**
     * @dev Changes the owner of the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to change the owner of
     * @param _newOwner The new owner of the guild
     */
    function changeGuildOwner(bytes32 _organizationId, uint32 _guildId, address _newOwner) external;

    /**
     * @dev Leaves the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to leave
     */
    function leaveGuild(bytes32 _organizationId, uint32 _guildId) external;

    /**
     * @dev Kicks or cancels any invites of the given users from the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to kick users from
     * @param _users The users to kick
     */
    function kickOrRemoveInvitations(bytes32 _organizationId, uint32 _guildId, address[] calldata _users) external;

    /**
     * @dev Returns the current status of a guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to get the status of
     */
    function getGuildStatus(bytes32 _organizationId, uint32 _guildId) external view returns (GuildStatus);

    /**
     * @dev Returns whether or not the given user can create a guild within the given organization.
     * @param _organizationId The organization to check
     * @param _user The user to check
     * @return Whether or not the user can create a guild within the given organization
     */
    function userCanCreateGuild(bytes32 _organizationId, address _user) external view returns (bool);

    /**
     * @dev Returns the membership status of the given user within the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to get the membership status of the user within
     * @param _user The user to get the membership status of
     * @return The membership status of the user within the guild
     */
    function getGuildMemberStatus(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) external view returns (GuildUserStatus);

    /**
     * @dev Returns the guild user info struct of the given user within the given guild.
     * @param _organizationId The organization the guild is within
     * @param _guildId The guild to get the info struct of the user within
     * @param _user The user to get the info struct of
     * @return The info struct of the user within the guild
     */
    function getGuildMemberInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) external view returns (GuildUserInfo memory);

    /**
     * @dev Initializes the Guild feature for the given organization.
     *  This can only be done by admins on the GuildManager contract.
     * @param _organizationId The id of the organization to initialize
     * @param _maxGuildsPerUser The maximum number of guilds a user can join within the organization.
     * @param _timeoutAfterLeavingGuild The number of seconds a user has to wait before being able to rejoin a guild
     * @param _guildCreationRule The rule for creating new guilds
     * @param _maxUsersPerGuildRule Indicates how the max number of users per guild is decided
     * @param _maxUsersPerGuildConstant If maxUsersPerGuildRule is set to CONSTANT, this is the max
     * @param _customGuildManagerAddress A contract address that handles custom guild creation requirements (i.e owning specific NFTs).
     * @param _requireTreasureTagForGuilds Whether this org requires a treasure tag for guilds
     *  This is used for guild creation if @param _guildCreationRule == CUSTOM_RULE
     */
    function initializeForOrganization(
        bytes32 _organizationId,
        uint8 _maxGuildsPerUser,
        uint32 _timeoutAfterLeavingGuild,
        GuildCreationRule _guildCreationRule,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant,
        address _customGuildManagerAddress,
        bool _requireTreasureTagForGuilds
    ) external;

    /**
     * @dev Sets the max number of guilds a user can join within the organization.
     * @param _organizationId The id of the organization to set the max guilds per user for.
     * @param _maxGuildsPerUser The maximum number of guilds a user can join within the organization.
     */
    function setMaxGuildsPerUser(bytes32 _organizationId, uint8 _maxGuildsPerUser) external;

    /**
     * @dev Sets the cooldown period a user has to wait before joining a new guild within the organization.
     * @param _organizationId The id of the organization to set the guild joining timeout for.
     * @param _timeoutAfterLeavingGuild The cooldown period a user has to wait before joining a new guild within the organization.
     */
    function setTimeoutAfterLeavingGuild(bytes32 _organizationId, uint32 _timeoutAfterLeavingGuild) external;

    /**
     * @dev Sets the rule for creating new guilds within the organization.
     * @param _organizationId The id of the organization to set the guild creation rule for.
     * @param _guildCreationRule The rule that outlines how a user can create a new guild within the organization.
     */
    function setGuildCreationRule(bytes32 _organizationId, GuildCreationRule _guildCreationRule) external;

    /**
     * @dev Sets the max number of users per guild within the organization.
     * @param _organizationId The id of the organization to set the max number of users per guild for
     * @param _maxUsersPerGuildRule Indicates how the max number of users per guild is decided within the organization.
     * @param _maxUsersPerGuildConstant If maxUsersPerGuildRule is set to CONSTANT, this is the max.
     */
    function setMaxUsersPerGuild(
        bytes32 _organizationId,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant
    ) external;

    /**
     * @dev Sets whether an org requires treasure tags for guilds
     * @param _organizationId The id of the organization to adjust
     * @param _requireTreasureTagForGuilds Whether treasure tags are required
     */
    function setRequireTreasureTagForGuilds(bytes32 _organizationId, bool _requireTreasureTagForGuilds) external;

    /**
     * @dev Sets the contract address that handles custom guild creation requirements (i.e owning specific NFTs).
     * @param _organizationId The id of the organization to set the custom guild manager address for
     * @param _customGuildManagerAddress The contract address that handles custom guild creation requirements (i.e owning specific NFTs).
     *  This is used for guild creation if the saved `guildCreationRule` == CUSTOM_RULE
     */
    function setCustomGuildManagerAddress(bytes32 _organizationId, address _customGuildManagerAddress) external;

    /**
     * @dev Sets the treasure tag nft address
     * @param _treasureTagNFTAddress The address of the treasure tag nft contract
     */
    function setTreasureTagNFTAddress(address _treasureTagNFTAddress) external;

    /**
     * @dev Retrieves the stored info for a given organization. Used to wrap the tuple from
     *  calling the mapping directly from external contracts
     * @param _organizationId The organization to return guild management info for
     * @return The stored guild settings for a given organization
     */
    function getGuildOrganizationInfo(bytes32 _organizationId) external view returns (GuildOrganizationInfo memory);

    /**
     * @dev Retrieves the token address for guilds within the given organization
     * @param _organizationId The organization to return the guild token address for
     * @return The token address for guilds within the given organization
     */
    function guildTokenAddress(bytes32 _organizationId) external view returns (address);

    /**
     * @dev Retrieves the token implementation address for guild token contracts to proxy to
     * @return The beacon token implementation address
     */
    function guildTokenImplementation() external view returns (address);

    /**
     * @dev Determines if the given guild is valid for the given organization
     * @param _organizationId The organization to verify against
     * @param _guildId The guild to verify
     * @return If the given guild is valid within the given organization
     */
    function isValidGuild(bytes32 _organizationId, uint32 _guildId) external view returns (bool);

    /**
     * @dev Get a given guild's name
     * @param _organizationId The organization to find the given guild within
     * @param _guildId The guild to retrieve the name from
     * @return The name of the given guild within the given organization
     */
    function guildName(bytes32 _organizationId, uint32 _guildId) external view returns (string memory);

    /**
     * @dev Get a given guild's description
     * @param _organizationId The organization to find the given guild within
     * @param _guildId The guild to retrieve the description from
     * @return The description of the given guild within the given organization
     */
    function guildDescription(bytes32 _organizationId, uint32 _guildId) external view returns (string memory);

    /**
     * @dev Get a given guild's symbol info
     * @param _organizationId The organization to find the given guild within
     * @param _guildId The guild to retrieve the symbol info from
     * @return symbolImageData_ The symbol data of the given guild within the given organization
     * @return isSymbolOnChain_ Whether or not the returned data is a URL or on-chain
     */
    function guildSymbolInfo(
        bytes32 _organizationId,
        uint32 _guildId
    ) external view returns (string memory symbolImageData_, bool isSymbolOnChain_);

    /**
     * @dev Retrieves the current owner for a given guild within a organization.
     * @param _organizationId The organization to find the guild within
     * @param _guildId The guild to return the owner of
     * @return The current owner of the given guild within the given organization
     */
    function guildOwner(bytes32 _organizationId, uint32 _guildId) external view returns (address);

    /**
     * @dev Retrieves the current owner for a given guild within a organization.
     * @param _organizationId The organization to find the guild within
     * @param _guildId The guild to return the maxMembers of
     * @return The current maxMembers of the given guild within the given organization
     */
    function maxUsersForGuild(bytes32 _organizationId, uint32 _guildId) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGuildToken {
    /**
     * @dev Sets initial state of this facet. Must be called for contract to work properly
     * @param _organizationId The id of the organization that owns this guild collection
     */
    function initialize(bytes32 _organizationId) external;

    /**
     * @dev Mints ERC1155 tokens to the given address. Only callable by a privileged address (i.e. GuildManager contract)
     * @param _to Recipient of the minted token
     * @param _id The tokenId of the token to mint
     * @param _amount The number of tokens to mint
     */
    function adminMint(address _to, uint256 _id, uint256 _amount) external;

    /**
     * @dev Burns ERC1155 tokens from the given address. Only callable by a privileged address (i.e. GuildManager contract)
     * @param _from The account to burn the tokens from
     * @param _id The tokenId of the token to burn
     * @param _amount The number of tokens to burn
     */
    function adminBurn(address _from, uint256 _id, uint256 _amount) external;

    /**
     * @dev Returns the manager address for this token contract
     */
    function guildManager() external view returns (address manager_);

    /**
     * @dev Returns the organization id for this token contract
     */
    function organizationId() external view returns (bytes32 organizationId_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Info related to a specific organization. Think of organizations as systems/games. i.e. Bridgeworld, The Beacon, etc.
 * @param name The name of the organization
 * @param description A description of the organization
 * @param admin The admin of the organization. The only user that can modify organization settings. There is only 1
 */
struct OrganizationInfo {
    // Slot 1
    string name;
    // Slot 2
    string description;
    // Slot 3 (160/256)
    address admin;
}

interface IOrganizationManager {
    /**
     * @dev Creates a new organization. For now, this can only be done by admins on the GuildManager contract.
     * @param _newOrganizationId The id of the organization being created.
     * @param _name The name of the organization.
     * @param _description The description of the organization.
     */
    function createOrganization(
        bytes32 _newOrganizationId,
        string calldata _name,
        string calldata _description
    ) external;

    /**
     * @dev Sets the name and description for an organization.
     * @param _organizationId The organization to set the name and description for.
     * @param _name The new name of the organization.
     * @param _description The new description of the organization.
     */
    function setOrganizationNameAndDescription(
        bytes32 _organizationId,
        string calldata _name,
        string calldata _description
    ) external;

    /**
     * @dev Sets the admin for an organization.
     * @param _organizationId The organization to set the admin for.
     * @param _admin The new admin of the organization.
     */
    function setOrganizationAdmin(bytes32 _organizationId, address _admin) external;

    /**
     * @dev Retrieves the stored info for a given organization. Used to wrap the tuple from
     *  calling the mapping directly from external contracts
     * @param _organizationId The organization to return info for
     */
    function getOrganizationInfo(bytes32 _organizationId) external view returns (OrganizationInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @dev Used to track ERC20 payment feeds and decimals for conversions. Note that `decimals` equaling 0 means that the erc20
 *      information is not initialized/supported.
 * @param priceFeeds A mapping of any price feed that supports the pair of ERC20 tokens used for conversions.
 *      There are currently no price feeds for this, however if one were to exist, it would be supportable
 *      Ex. LINK / MAGIC would give an answer of "How much MAGIC equals 1 LINK?" -> 3.67 MAGIC (See https://coincodex.com/convert/chainlink/magic-token/)
 *      Ex. MAGIC / LINK would give an answer of "How much LINK equals 1 MAGIC?" -> 0.272600 LINK (See https://coincodex.com/convert/magic-token/chainlink/)
 * @param usdAggregator The price feed for the ERC20 token priced in USD
 *      Ex. LINK / USD would give an answer of "How much USD equals 1 LINK?" -> 7.26 USD (See https://coincodex.com/convert/chainlink/usd/)
 * @param pricedInGasTokenAggregator The price feed for ERC20 priced in gas tokens
 *      Ex. LINK / ETH would give an answer of "How much ETH equals 1 LINK?" -> 0.004 ETH (See https://coincodex.com/convert/chainlink/ethereum/)
 * @param gasTokenPricedInERC20Aggregator The price feed for the gas token priced in the ERC20.
 *      There are currently no price feeds for this, however if one were to exist, it would be supportable
 *      Ex. ETH / LINK would give an answer of "How much LINK equals 1 ETH" -> 249.13 LINK (See https://coincodex.com/convert/ethereum/chainlink/)
 * @param decimals The number of decimals of this ERC20.
 *      Needed to ensure proper funds transferring when decimals in the pair differ
 */
struct ERC20Info {
    // Slot 1: 256 bits
    mapping(address => AggregatorV3Interface) priceFeeds;
    // Slot 2: 160 bits
    AggregatorV3Interface usdAggregator;
    // Slot 3: 160 bits
    AggregatorV3Interface pricedInGasTokenAggregator;
    // Slot 4: 168 bits
    AggregatorV3Interface gasTokenPricedInERC20Aggregator;
    uint8 decimals;
}

/**
 * @dev Used to determine how to calculate the payment amount when taking a payment.
 *      STATIC: The payment amount is the input token without conversion.
 *      PRICED_IN_ERC20: The payment amount is priced in an ERC20 relative to the payment token.
 *      PRICED_IN_USD: The payment amount is priced in USD relative to the payment token.
 *      PRICED_IN_GAS_TOKEN: The payment amount is priced in the gas token relative to the payment token.
 */
enum PriceType {
    STATIC,
    PRICED_IN_ERC20,
    PRICED_IN_USD,
    PRICED_IN_GAS_TOKEN
}

interface IPayments {
    /**
     * @dev Emitted when a payment is made
     * @param payor The address of the sender of the payment
     * @param token The address of the token that was paid. If address(0), then it was gas token
     * @param amount The amount of the token that was paid
     * @param paymentsReceiver The address of the contract that received the payment. Supports IPaymentsReceiver
     */
    event PaymentSent(address payor, address token, uint256 amount, address paymentsReceiver);

    /**
     * @dev Make a payment in ERC20 to the recipient
     * @param _recipient The address of the recipient of the payment
     * @param _paymentERC20 The address of the ERC20 to take
     * @param _price The amount of the ERC20 to take
     */
    function makeStaticERC20Payment(address _recipient, address _paymentERC20, uint256 _price) external;

    /**
     * @dev Make a payment in gas token to the recipient.
     *      All this does is verify that the price matches the tx value
     * @param _recipient The address of the recipient of the payment
     * @param _price The amount of the gas token to take
     */
    function makeStaticGasTokenPayment(address _recipient, uint256 _price) external payable;

    /**
     * @dev Make a payment in ERC20 to the recipient priced in another token (Gas Token/USD/other ERC20)
     * @param _recipient The address of the payor to take the payment from
     * @param _paymentERC20 The address of the ERC20 to take
     * @param _paymentAmountInPricedToken The desired payment amount, priced in another token, depending on what `priceType` is
     * @param _priceType The type of currency that the payment amount is priced in
     * @param _pricedERC20 The address of the ERC20 that the payment amount is priced in. Only used if `_priceType` is PRICED_IN_ERC20
     */
    function makeERC20PaymentByPriceType(
        address _recipient,
        address _paymentERC20,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external;

    /**
     * @dev Take payment in gas tokens (ETH, MATIC, etc.) priced in another token (USD/ERC20)
     * @param _recipient The address to send the payment to
     * @param _paymentAmountInPricedToken The desired payment amount, priced in another token, depending on what `_priceType` is
     * @param _priceType The type of currency that the payment amount is priced in
     * @param _pricedERC20 The address of the ERC20 that the payment amount is priced in. Only used if `_priceType` is PRICED_IN_ERC20
     */
    function makeGasTokenPaymentByPriceType(
        address _recipient,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external payable;

    /**
     * @dev Admin-only function that initializes the ERC20 info for a given ERC20.
     *      Currently there are no price feeds for ERC20s, so those parameters are a placeholder
     * @param _paymentERC20 The ERC20 address
     * @param _decimals The number of decimals of this coin.
     * @param _pricedInGasTokenAggregator The aggregator for the gas coin (ETH, MATIC, etc.)
     * @param _usdAggregator The aggregator for USD
     * @param _pricedERC20s The ERC20s that have supported price feeds for the given ERC20
     * @param _priceFeeds The price feeds for the priced ERC20s
     */
    function initializeERC20(
        address _paymentERC20,
        uint8 _decimals,
        address _pricedInGasTokenAggregator,
        address _usdAggregator,
        address[] calldata _pricedERC20s,
        address[] calldata _priceFeeds
    ) external;

    /**
     * @dev Admin-only function that sets the price feed for a given ERC20.
     *      Currently there are no price feeds for ERC20s, so this is a placeholder
     * @param _paymentERC20 The ERC20 to set the price feed for
     * @param _pricedERC20 The ERC20 that is associated to the given price feed and `_paymentERC20`
     * @param _priceFeed The address of the price feed
     */
    function setERC20PriceFeedForERC20(address _paymentERC20, address _pricedERC20, address _priceFeed) external;

    /**
     * @dev Admin-only function that sets the price feed for the gas token for the given ERC20.
     * @param _pricedERC20 The ERC20 that is associated to the given price feed and `_paymentERC20`
     * @param _priceFeed The address of the price feed
     */
    function setERC20PriceFeedForGasToken(address _pricedERC20, address _priceFeed) external;

    /**
     * @param _paymentToken The token to convert from. If address(0), then the input is in gas tokens
     * @param _priceType The type of currency that the payment amount is priced in
     * @param _pricedERC20 The address of the ERC20 that the payment amount is priced in. Only used if `_priceType` is PRICED_IN_ERC20
     * @return supported_ Whether or not a price feed exists for the given payment token and price type
     */
    function isValidPriceType(
        address _paymentToken,
        PriceType _priceType,
        address _pricedERC20
    ) external view returns (bool supported_);

    /**
     * @dev Calculates the price of the input token relative to the output token
     * @param _paymentToken The token to convert from. If address(0), then the input is in gas tokens
     * @param _paymentAmountInPricedToken The desired payment amount, priced in either the `_pricedERC20`, gas token, or USD depending on `_priceType`
     *      used to calculate the output amount
     * @param _priceType The type of conversion to perform
     * @param _pricedERC20 The token to convert to. If address(0), then the output is in gas tokens or USD, depending on `_priceType`
     */
    function calculatePaymentAmountByPriceType(
        address _paymentToken,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external view returns (uint256 paymentAmount_);

    /**
     * @return magicAddress_ The address of the $MAGIC contract
     */
    function getMagicAddress() external view returns (address magicAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PriceType } from "src/interfaces/IPayments.sol";

interface IPaymentsReceiver {
    /**
     * @dev Emitted when a payment is made
     * @param payor The address of the sender of the payment
     * @param paymentERC20 The address of the token that was paid. If address(0), then it was gas token
     * @param paymentAmount The amount of the token that was paid
     * @param paymentAmountInPricedToken The payment amount of the given priced token. Used to have dynamic payments based on the value relative to another token
     * @param priceType The type of payment that was made. This can be static payment or priced in another currency
     * @param pricedERC20 The address of the ERC20 token that was used to price the payment. Only used if `_priceType` is PRICED_IN_ERC20
     */
    event PaymentReceived(
        address payor,
        address paymentERC20,
        uint256 paymentAmount,
        uint256 paymentAmountInPricedToken,
        PriceType priceType,
        address pricedERC20
    );

    /**
     * @dev Accepts a payment in ERC20 tokens
     * @param _payor The address of the payor for this payment
     * @param _paymentERC20 The address of the ERC20 token that was paid
     * @param _paymentAmount The amount of the ERC20 token that was paid
     * @param _paymentAmountInPricedToken The amount of the ERC20 token that was paid in the given priced token
     *      For example, if the payment is the amount of MAGIC that equals $10 USD,
     *      then this value would be 10 * 10**8 (the number of decimals for USD)
     * @param _priceType The type of payment that was made. This can be static payment or priced in another currency
     * @param _pricedERC20 The address of the ERC20 token that was used to price the payment. Only used if `_priceType` is `PriceType.PRICED_IN_ERC20`
     */
    function acceptERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external;

    /**
     * @dev Accepts a payment in gas tokens
     * @param _payor The address of the payor for this payment
     * @param _paymentAmount The amount of the gas token that was paid
     * @param _paymentAmountInPricedToken The amount of the gas token that was paid in the given priced token
     *      For example, if the payment is the amount of ETH that equals $10 USD,
     *      then this value would be 10 * 10**8 (the number of decimals for USD)
     * @param _priceType The type of payment that was made. This can be static payment or priced in another currency
     * @param _pricedERC20 The address of the ERC20 token that was used to price the payment. Only used if `_priceType` is `PriceType.PRICED_IN_ERC20`
     */
    function acceptGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Enum to define ERC type of a token.
 */
enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}

/**
 * @dev Struct that defines an ingredient within a crafting recipe
 * @param tokenAddress the address of the token
 * @param tokenType whether this is ERC20/720 or 1155
 * @param tokenId the tokenId if it is erc720/1155
 * @param tokenQuantity the quantity of the token if it is erc20/1155
 */
struct Ingredient {
    address tokenAddress;
    TokenType tokenType;
    //One or both of these will be used depending on the tokentype.
    uint256 tokenId;
    uint256 tokenQuantity;
}

/**
 * @dev Struct that defines a result for a crafting recipe
 * @param target the address to call with selector/params
 * @param selector the function selector to call
 * @param params the params to call with
 */
struct Result {
    address target;
    bytes4 selector;
    bytes params;
}

/**
 * @dev Struct that defines a crafting recipe
 * @param ingredients List of ingredients
 * @param results List of results
 */
struct CraftingRecipe {
    //Store array of essential ingredients
    Ingredient[] ingredients;
    //Store array of outputs
    Result[] results;
}

interface ISimpleCrafting {
    /**
     * @dev Emitted when a crafting recipe is created
     * @param craftingRecipeId The crafting recipe Id.
     */
    event CraftingRecipeCreated(uint256 craftingRecipeId);

    /**
     * @dev Emitted when a crafting recipe is crafting
     * @param craftingRecipeId The crafting recipe Id.
     * @param user The crafter.
     */
    event CraftingRecipeCrafted(uint256 craftingRecipeId, address user);

    /**
     * @dev Emitted when a user is not permitted to set a recipe as allowed.
     * @param account The user.
     */
    error UserNotPermitted(address account);

    /**
     * @dev Emitted when a recipe is not yet fully allowed
     * @param recipeId The recipeId.
     */
    error RecipeNotAllowed(uint256 recipeId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Struct that defines a collection role grant request
 * @param collection the address this role belongs to
 * @param nonce the nonce being used by this signer
 * @param receiver who the role is going to
 * @param role the role to add
 */
struct CollectionRoleGrantRequest {
    address collection;
    uint96 nonce;
    address receiver;
    bytes32 role;
}

interface ISpellcasterGM {
    /**
     * @dev Adds a trusted signer to spellcaster
     * @param _account The address of the signer.
     */
    function addTrustedSigner(address _account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Assumes we are going to use the AccessControlFacet at src/access/AccessControlStorage.sol
import { AccessControlStorage } from "@openzeppelin/contracts-diamond/access/AccessControlStorage.sol";
import { LibDiamond } from "../diamond/LibDiamond.sol";
import { AccessControlEnumerableStorage } from
    "@openzeppelin/contracts-diamond/access/AccessControlEnumerableStorage.sol";
import { LibMeta } from "./LibMeta.sol";

import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-diamond/utils/structs/EnumerableSetUpgradeable.sol";

bytes32 constant ADMIN_ROLE = keccak256("ADMIN");
bytes32 constant ADMIN_GRANTER_ROLE = keccak256("ADMIN_GRANTER");
bytes32 constant UPGRADER_ROLE = keccak256("UPGRADER");
bytes32 constant ROLE_GRANTER_ROLE = keccak256("ROLE_GRANTER");

library LibAccessControlRoles {
    using AccessControlEnumerableStorage for AccessControlEnumerableStorage.Layout;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Emitted when an account is missing a role from two options.
     * @param account The account address
     * @param roleOption1 The first role option
     * @param roleOption2 The second role option
     */
    error MissingEitherRole(address account, bytes32 roleOption1, bytes32 roleOption2);

    /**
     * @dev Emitted when an account does not have a given role and is not owner.
     * @param account The account address
     * @param role The role
     */
    error MissingRoleAndNotOwner(address account, bytes32 role);

    /**
     * @dev Emitted when an account does not have a given role.
     * @param account The account address
     * @param role The role
     */
    error MissingRole(address account, bytes32 role);

    /**
     * @dev Emitted when an account is not contract owner.
     * @param account The account address
     */
    error IsNotContractOwner(address account);

    /**
     * @dev Emitted when an account is not a collection admin.
     * @param account The account address
     * @param collection The collection address
     */
    error IsNotCollectionAdmin(address account, address collection);

    /**
     * @dev Emitted when an account is not a collection role granter.
     * @param account The account address
     * @param collection The collection address
     */
    error IsNotCollectionRoleGranter(address account, address collection);

    /**
     * @dev Error when trying to terminate a guild but you are not a guild terminator
     * @param account The address of the sender
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the guild
     */
    error IsNotGuildTerminator(address account, bytes32 organizationId, uint32 guildId);

    /**
     * @dev Error when trying to interact with an admin function of a guild but you are not a guild admin
     * @param account The address of the sender
     * @param organizationId The ID of the guild's organization
     * @param guildId The ID of the guild
     */
    error IsNotGuildAdmin(address account, bytes32 organizationId, uint32 guildId);

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

    // Taken from AccessControlUpgradeable
    function hasRole(bytes32 _role, address _account) internal view returns (bool) {
        return AccessControlStorage.layout()._roles[_role].members[_account];
    }

    /**
     * @dev Grants `role` to `_account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 _role, address _account) internal {
        if (!hasRole(_role, _account)) {
            AccessControlStorage.layout()._roles[_role].members[_account] = true;
            emit RoleGranted(_role, _account, LibMeta._msgSender());
        }

        AccessControlEnumerableStorage.layout()._roleMembers[_role].add(_account);
    }

    /**
     * @dev Revokes `role` from `_account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 _role, address _account) internal {
        if (hasRole(_role, _account)) {
            AccessControlStorage.layout()._roles[_role].members[_account] = false;
            emit RoleRevoked(_role, _account, LibMeta._msgSender());
        }

        AccessControlEnumerableStorage.layout()._roleMembers[_role].remove(_account);
    }

    /**
     * @dev Require an address has a specific role
     * @param _role The role to check.
     * @param _account The address to check.
     */
    function requireRole(bytes32 _role, address _account) internal view {
        if (!hasRole(_role, _account)) {
            revert MissingRole(_account, _role);
        }
    }

    /**
     * @dev Requires the inputted address to be the contract owner.
     * @param _account The address of the signer.
     */
    function requireOwner(address _account) internal view {
        if (_account != contractOwner()) {
            revert IsNotContractOwner(_account);
        }
    }

    /**
     * @dev Returns the current diamond contract owner.
     * @return contractOwner_ The address of the owner
     */
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamond.contractOwner();
    }

    /**
     * @dev Returns whether the inputted address is the inputted collection admin.
     * @param _account The address of the admin.
     * @param _collection The address of the collection.
     */
    function isCollectionAdmin(address _account, address _collection) internal view returns (bool) {
        return hasRole(getCollectionAdminRole(_collection), _account);
    }

    /**
     * @dev Returns whether the inputted address is the inputted collection role granter.
     * @param _account The address of the role granter.
     * @param _collection The address of the collection.
     */
    function isCollectionRoleGranter(address _account, address _collection) internal view returns (bool) {
        return hasRole(getCollectionRoleGranterRole(_collection), _account);
    }

    /**
     * @dev Requires the inputted address to be the inputted collection role granter.
     * @param _account The address of the admin.
     * @param _collection The address of the collection.
     */
    function requireCollectionAdmin(address _account, address _collection) internal view {
        if (!isCollectionAdmin(_account, _collection)) revert IsNotCollectionAdmin(_account, _collection);
    }

    /**
     * @dev Requires the inputted address to be the inputted collection role granter.
     * @param _account The address of the role granter.
     * @param _collection The address of the collection.
     */
    function requireCollectionRoleGranter(address _account, address _collection) internal view {
        if (!isCollectionRoleGranter(_account, _collection)) revert IsNotCollectionRoleGranter(_account, _collection);
    }

    /**
     * @dev Give the collection role granter role to this account.
     * @param _account The address of the account to grant.
     * @param _collection The address of the collection.
     */
    function grantCollectionRoleGranter(address _account, address _collection) internal {
        _grantRole(getCollectionRoleGranterRole(_collection), _account);
    }

    /**
     * @dev Give the collection admin role to this account.
     * @param _account The address of the account to grant.
     * @param _collection The address of the collection.
     */
    function grantCollectionAdmin(address _account, address _collection) internal {
        _grantRole(getCollectionAdminRole(_collection), _account);
    }

    function getCollectionRoleGranterRole(address _collection) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("COLLECTION_ROLE_GRANTER_ROLE_", _collection));
    }

    function getCollectionAdminRole(address _collection) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("COLLECTION_ADMIN_ROLE_", _collection));
    }

    /**
     * @dev Give the guild terminator role to this account.
     * @param _account The address of the account to grant.
     * @param _organizationId The organization Id of this guild
     * @param _guildId The guild Id
     */
    function grantGuildTerminator(address _account, bytes32 _organizationId, uint32 _guildId) internal {
        _grantRole(getGuildTerminatorRole(_organizationId, _guildId), _account);
    }

    function getGuildTerminatorRole(bytes32 _organizationId, uint32 _guildId) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "TERMINATOR_ROLE_", keccak256(abi.encodePacked(_organizationId)), keccak256(abi.encodePacked(_guildId))
            )
        );
    }

    /**
     * @dev Returns whether the inputted address is a guild terminator
     * @param _account The address of the account.
     * @param _organizationId The organization Id of this guild
     * @param _guildId The guild Id
     */
    function isGuildTerminator(
        address _account,
        bytes32 _organizationId,
        uint32 _guildId
    ) internal view returns (bool) {
        return hasRole(getGuildTerminatorRole(_organizationId, _guildId), _account);
    }

    function requireGuildTerminator(address _account, bytes32 _organizationId, uint32 _guildId) internal view {
        if (!isGuildTerminator(_account, _organizationId, _guildId)) {
            revert IsNotGuildTerminator(_account, _organizationId, _guildId);
        }
    }

    /**
     * @dev Give the guild admin role to this account.
     * @param _account The address of the account to grant.
     * @param _organizationId The organization Id of this guild
     * @param _guildId The guild Id
     */
    function grantGuildAdmin(address _account, bytes32 _organizationId, uint32 _guildId) internal {
        _grantRole(getGuildAdminRole(_organizationId, _guildId), _account);
    }

    function getGuildAdminRole(bytes32 _organizationId, uint32 _guildId) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "ADMIN_ROLE_", keccak256(abi.encodePacked(_organizationId)), keccak256(abi.encodePacked(_guildId))
            )
        );
    }

    /**
     * @dev Returns whether the inputted address is a guild admin
     * @param _account The address of the account.
     * @param _organizationId The organization Id of this guild
     * @param _guildId The guild Id
     */
    function isGuildAdmin(address _account, bytes32 _organizationId, uint32 _guildId) internal view returns (bool) {
        return hasRole(getGuildAdminRole(_organizationId, _guildId), _account);
    }

    function requireGuildAdmin(address _account, bytes32 _organizationId, uint32 _guildId) internal view {
        if (!isGuildAdmin(_account, _organizationId, _guildId)) {
            revert IsNotGuildAdmin(_account, _organizationId, _guildId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BBase64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in BBase64
library LibBBase64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return "";

        // load the _table into memory
        string memory _table = TABLE;

        // multiply by 4/3 rounded up
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory _result = new string(_encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(_result, _encodedLen)

            // prepare the lookup _table
            let tablePtr := add(_table, 1)

            // input ptr
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))

            // _result ptr, jump over length
            let resultPtr := add(_result, 32)

            // run over the input, 3 bytes at a time
            for { } lt(dataPtr, endPtr) { } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(_data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return _result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC721/IERC721Upgradeable.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import { LibAccessControlRoles } from "src/libraries/LibAccessControlRoles.sol";

import {
    IGuildManager,
    GuildInfo,
    GuildCreationRule,
    GuildUserInfo,
    GuildUserStatus,
    GuildOrganizationInfo,
    GuildOrganizationUserInfo,
    MaxUsersPerGuildRule,
    GuildStatus
} from "src/interfaces/IGuildManager.sol";
import { IGuildToken } from "src/interfaces/IGuildToken.sol";
import { ICustomGuildManager } from "src/interfaces/ICustomGuildManager.sol";
import { LibOrganizationManager } from "src/libraries/LibOrganizationManager.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";

import { GuildManagerStorage } from "src/guilds/guildmanager/GuildManagerStorage.sol";

/**
 * @title Guild Manager Library
 * @dev This library is used to implement features that use/update storage data for the Guild Manager contracts
 */
library LibGuildManager {
    // =============================================================
    //                    State Getters/Setters
    // =============================================================

    function setTreasureTagNFTAddress(address _treasureTagNFTAddress) internal {
        GuildManagerStorage.Layout storage _l = GuildManagerStorage.layout();

        _l.treasureTagNFTAddress = _treasureTagNFTAddress;
    }

    function setGuildTokenBeacon(address _beaconImplAddress) internal {
        GuildManagerStorage.Layout storage _l = GuildManagerStorage.layout();

        if (address(_l.guildTokenBeacon) == address(0)) {
            _l.guildTokenBeacon = new UpgradeableBeacon(_beaconImplAddress);
        } else if (_l.guildTokenBeacon.implementation() != _beaconImplAddress) {
            _l.guildTokenBeacon.upgradeTo(_beaconImplAddress);
        }
    }

    function getGuildTokenBeacon() internal view returns (UpgradeableBeacon beacon_) {
        beacon_ = GuildManagerStorage.layout().guildTokenBeacon;
    }

    /**
     * @param _organizationId The id of the org to retrieve info for
     * @return info_ The return struct is storage. This means all state changes to the struct will save automatically,
     *  instead of using a memory copy overwrite
     */
    function getGuildOrganizationInfo(bytes32 _organizationId)
        internal
        view
        returns (GuildOrganizationInfo storage info_)
    {
        info_ = GuildManagerStorage.layout().guildOrganizationInfo[_organizationId];
    }

    /**
     * @param _organizationId The id of the org that contains the guild to retrieve info for
     * @param _guildId The id of the guild within the given org to retrieve info for
     * @return info_ The return struct is storage. This means all state changes to the struct will save automatically,
     *  instead of using a memory copy overwrite
     */
    function getGuildInfo(bytes32 _organizationId, uint32 _guildId) internal view returns (GuildInfo storage info_) {
        info_ = GuildManagerStorage.layout().organizationIdToGuildIdToInfo[_organizationId][_guildId];
    }

    /**
     * @param _organizationId The id of the org that contains the user to retrieve info for
     * @param _user The id of the user within the given org to retrieve info for
     * @return info_ The return struct is storage. This means all state changes to the struct will save automatically,
     *  instead of using a memory copy overwrite
     */
    function getUserInfo(
        bytes32 _organizationId,
        address _user
    ) internal view returns (GuildOrganizationUserInfo storage info_) {
        info_ = GuildManagerStorage.layout().organizationIdToAddressToInfo[_organizationId][_user];
    }

    /**
     * @param _organizationId The id of the org that contains the user to retrieve info for
     * @param _guildId The id of the guild within the given org to retrieve user info for
     * @param _user The id of the user to retrieve info for
     * @return info_ The return struct is storage. This means all state changes to the struct will save automatically,
     *  instead of using a memory copy overwrite
     */
    function getGuildUserInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) internal view returns (GuildUserInfo storage info_) {
        info_ = GuildManagerStorage.layout().organizationIdToGuildIdToInfo[_organizationId][_guildId]
            .addressToGuildUserInfo[_user];
    }

    // =============================================================
    //                  GuildOrganization Settings
    // =============================================================

    function setMaxGuildsPerUser(bytes32 _organizationId, uint8 _maxGuildsPerUser) internal {
        require(_maxGuildsPerUser > 0, "maxGuildsPerUser cannot be 0");

        getGuildOrganizationInfo(_organizationId).maxGuildsPerUser = _maxGuildsPerUser;
        emit GuildManagerStorage.MaxGuildsPerUserUpdated(_organizationId, _maxGuildsPerUser);
    }

    function setTimeoutAfterLeavingGuild(bytes32 _organizationId, uint32 _timeoutAfterLeavingGuild) internal {
        getGuildOrganizationInfo(_organizationId).timeoutAfterLeavingGuild = _timeoutAfterLeavingGuild;
        emit GuildManagerStorage.TimeoutAfterLeavingGuild(_organizationId, _timeoutAfterLeavingGuild);
    }

    function setGuildCreationRule(bytes32 _organizationId, GuildCreationRule _guildCreationRule) internal {
        getGuildOrganizationInfo(_organizationId).creationRule = _guildCreationRule;
        emit GuildManagerStorage.GuildCreationRuleUpdated(_organizationId, _guildCreationRule);
    }

    function setMaxUsersPerGuild(
        bytes32 _organizationId,
        MaxUsersPerGuildRule _maxUsersPerGuildRule,
        uint32 _maxUsersPerGuildConstant
    ) internal {
        getGuildOrganizationInfo(_organizationId).maxUsersPerGuildRule = _maxUsersPerGuildRule;
        getGuildOrganizationInfo(_organizationId).maxUsersPerGuildConstant = _maxUsersPerGuildConstant;
        emit GuildManagerStorage.MaxUsersPerGuildUpdated(
            _organizationId, _maxUsersPerGuildRule, _maxUsersPerGuildConstant
        );
    }

    function setCustomGuildManagerAddress(bytes32 _organizationId, address _customGuildManagerAddress) internal {
        getGuildOrganizationInfo(_organizationId).customGuildManagerAddress = _customGuildManagerAddress;
        emit GuildManagerStorage.CustomGuildManagerAddressUpdated(_organizationId, _customGuildManagerAddress);
    }

    function setRequireTreasureTagForGuilds(bytes32 _organizationId, bool _requireTreasureTagForGuilds) internal {
        getGuildOrganizationInfo(_organizationId).requireTreasureTagForGuilds = _requireTreasureTagForGuilds;

        emit GuildManagerStorage.RequireTreasureTagForGuildsUpdated(_organizationId, _requireTreasureTagForGuilds);
    }

    // =============================================================
    //                  Guild Settings
    // =============================================================

    /**
     * @dev Assumes permissions have already been checked (only guild owner)
     */
    function setGuildInfo(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _name,
        string calldata _description
    ) internal onlyActiveGuild(_organizationId, _guildId) {
        GuildInfo storage _guildInfo = getGuildInfo(_organizationId, _guildId);

        _guildInfo.name = _name;
        _guildInfo.description = _description;

        emit GuildManagerStorage.GuildInfoUpdated(_organizationId, _guildId, _name, _description);
    }

    /**
     * @dev Assumes permissions have already been checked (only guild owner)
     */
    function setGuildSymbol(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _symbolImageData,
        bool _isSymbolOnChain
    ) internal onlyActiveGuild(_organizationId, _guildId) {
        GuildInfo storage _guildInfo = getGuildInfo(_organizationId, _guildId);

        _guildInfo.symbolImageData = _symbolImageData;
        _guildInfo.isSymbolOnChain = _isSymbolOnChain;

        emit GuildManagerStorage.GuildSymbolUpdated(_organizationId, _guildId, _symbolImageData, _isSymbolOnChain);
    }

    function getMaxUsersForGuild(bytes32 _organizationId, uint32 _guildId) internal view returns (uint32) {
        GuildManagerStorage.Layout storage _l = GuildManagerStorage.layout();
        address _guildOwner = _l.organizationIdToGuildIdToInfo[_organizationId][_guildId].currentOwner;
        require(_guildOwner != address(0), "Invalid guild");

        GuildOrganizationInfo storage _orgInfo = _l.guildOrganizationInfo[_organizationId];
        if (_orgInfo.maxUsersPerGuildRule == MaxUsersPerGuildRule.CONSTANT) {
            return _orgInfo.maxUsersPerGuildConstant;
        } else {
            require(_orgInfo.customGuildManagerAddress != address(0), "CUSTOM_RULE with no config set");
            return ICustomGuildManager(_orgInfo.customGuildManagerAddress).maxUsersForGuild(_organizationId, _guildId);
        }
    }

    // =============================================================
    //                        Create Functions
    // =============================================================

    /**
     * @dev Assumes that the organization already exists. This is used when creating a guild for an organization that
     *  already exists, but has not initialized the guild feature yet.
     * @param _organizationId The id of the organization to create a guild for
     */
    function initializeForOrganization(bytes32 _organizationId) internal {
        GuildManagerStorage.Layout storage _l = GuildManagerStorage.layout();
        if (_l.guildOrganizationInfo[_organizationId].tokenAddress != address(0)) {
            revert GuildManagerStorage.GuildOrganizationAlreadyInitialized(_organizationId);
        }

        // Create new 1155 token to represent this organization.
        bytes memory _guildTokenData = abi.encodeCall(IGuildToken.initialize, (_organizationId));
        address _guildTokenAddress = address(new BeaconProxy(address(_l.guildTokenBeacon), _guildTokenData));
        _l.guildOrganizationInfo[_organizationId].tokenAddress = _guildTokenAddress;

        // The first guild created will be ID 1.
        _l.guildOrganizationInfo[_organizationId].guildIdCur = 1;

        emit GuildManagerStorage.GuildOrganizationInitialized(_organizationId, _guildTokenAddress);
    }

    function createGuild(bytes32 _organizationId) internal {
        if (getGuildOrganizationInfo(_organizationId).requireTreasureTagForGuilds) {
            requireTreasureTagHolder(LibMeta._msgSender());
        }

        GuildManagerStorage.Layout storage _l = GuildManagerStorage.layout();

        // Check to make sure the user can create a guild
        if (!userCanCreateGuild(_organizationId, LibMeta._msgSender())) {
            revert GuildManagerStorage.UserCannotCreateGuild(_organizationId, LibMeta._msgSender());
        }

        uint32 _newGuildId = _l.guildOrganizationInfo[_organizationId].guildIdCur;
        _l.guildOrganizationInfo[_organizationId].guildIdCur++;

        //set guild status to active
        _l.organizationIdToGuildIdToInfo[_organizationId][_newGuildId].guildStatus = GuildStatus.ACTIVE;

        LibAccessControlRoles.grantGuildTerminator(LibMeta._msgSender(), _organizationId, _newGuildId);
        LibAccessControlRoles.grantGuildAdmin(LibMeta._msgSender(), _organizationId, _newGuildId);

        emit GuildManagerStorage.GuildCreated(_organizationId, _newGuildId);

        // Set the created user as the OWNER.
        // May revert depending on how many guilds this user is already apart of
        // and the rules of the organization.
        _changeUserStatus(_organizationId, _newGuildId, LibMeta._msgSender(), GuildUserStatus.OWNER);

        // Call the hook if they have it setup.
        if (_l.guildOrganizationInfo[_organizationId].customGuildManagerAddress != address(0)) {
            return ICustomGuildManager(_l.guildOrganizationInfo[_organizationId].customGuildManagerAddress)
                .onGuildCreation(LibMeta._msgSender(), _organizationId, _newGuildId);
        }
    }

    // =============================================================
    //                      Member Functions
    // =============================================================

    function inviteUsers(
        bytes32 _organizationId,
        uint32 _guildId,
        address[] calldata _users
    ) internal onlyGuildOwnerOrAdmin(_organizationId, _guildId, "INVITE") onlyActiveGuild(_organizationId, _guildId) {
        require(_users.length > 0, "No users to invite");

        for (uint256 i = 0; i < _users.length; i++) {
            address _userToInvite = _users[i];
            if (_userToInvite == address(0)) {
                revert GuildManagerStorage.InvalidAddress(_userToInvite);
            }

            GuildUserStatus _userStatus = getGuildUserInfo(_organizationId, _guildId, _userToInvite).userStatus;
            if (_userStatus != GuildUserStatus.NOT_ASSOCIATED) {
                revert GuildManagerStorage.UserAlreadyInGuild(_organizationId, _guildId, _userToInvite);
            }

            _changeUserStatus(_organizationId, _guildId, _userToInvite, GuildUserStatus.INVITED);
        }
    }

    function acceptInvitation(
        bytes32 _organizationId,
        uint32 _guildId
    ) internal onlyActiveGuild(_organizationId, _guildId) {
        if (getGuildOrganizationInfo(_organizationId).requireTreasureTagForGuilds) {
            requireTreasureTagHolder(LibMeta._msgSender());
        }

        GuildUserStatus _userStatus = getGuildUserInfo(_organizationId, _guildId, LibMeta._msgSender()).userStatus;
        require(_userStatus == GuildUserStatus.INVITED, "Not invited");

        // Will validate they are not joining too many guilds.
        _changeUserStatus(_organizationId, _guildId, LibMeta._msgSender(), GuildUserStatus.MEMBER);
    }

    function leaveGuild(bytes32 _organizationId, uint32 _guildId) internal {
        GuildUserStatus _userStatus = getGuildUserInfo(_organizationId, _guildId, LibMeta._msgSender()).userStatus;
        require(_userStatus != GuildUserStatus.OWNER, "Owner cannot leave guild");
        require(_userStatus == GuildUserStatus.MEMBER || _userStatus == GuildUserStatus.ADMIN, "Not member of guild");

        _changeUserStatus(_organizationId, _guildId, LibMeta._msgSender(), GuildUserStatus.NOT_ASSOCIATED);
    }

    function kickOrRemoveInvitations(
        bytes32 _organizationId,
        uint32 _guildId,
        address[] calldata _users
    ) internal onlyActiveGuild(_organizationId, _guildId) {
        require(_users.length > 0, "No users to kick");

        for (uint256 i = 0; i < _users.length; i++) {
            address _user = _users[i];
            GuildUserStatus _userStatus = getGuildUserInfo(_organizationId, _guildId, _user).userStatus;
            if (_userStatus == GuildUserStatus.OWNER) {
                revert("Cannot kick owner");
            } else if (_userStatus == GuildUserStatus.ADMIN) {
                requireGuildOwner(_organizationId, _guildId, "KICK");
            } else if (_userStatus == GuildUserStatus.NOT_ASSOCIATED) {
                revert("Cannot kick someone unassociated");
            } else {
                // MEMBER or INVITED
                requireGuildOwnerOrAdmin(_organizationId, _guildId, "KICK");
            }
            _changeUserStatus(_organizationId, _guildId, _user, GuildUserStatus.NOT_ASSOCIATED);
        }
    }

    // =============================================================
    //                Guild Administration Functions
    // =============================================================

    function changeGuildAdmins(
        bytes32 _organizationId,
        uint32 _guildId,
        address[] calldata _users,
        bool[] calldata _isAdmins
    ) internal onlyGuildOwner(_organizationId, _guildId, "CHANGE_ADMINS") onlyActiveGuild(_organizationId, _guildId) {
        require(_users.length > 0, "No users to change admin");
        require(_users.length == _isAdmins.length, "Mismatched input lengths");

        for (uint256 i = 0; i < _users.length; i++) {
            address _user = _users[i];
            bool _willBeAdmin = _isAdmins[i];

            GuildUserStatus _userStatus = getGuildUserInfo(_organizationId, _guildId, _user).userStatus;

            if (_willBeAdmin) {
                if (_userStatus != GuildUserStatus.MEMBER) {
                    revert GuildManagerStorage.UserNotGuildMember(_organizationId, _guildId, _user);
                }
                _changeUserStatus(_organizationId, _guildId, _user, GuildUserStatus.ADMIN);
            } else {
                require(_userStatus == GuildUserStatus.ADMIN, "Can only demote admins");
                _changeUserStatus(_organizationId, _guildId, _user, GuildUserStatus.MEMBER);
            }
        }
    }

    function adjustMemberLevel(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user,
        uint8 _memberLevel
    ) internal onlyActiveGuild(_organizationId, _guildId) {
        require(_memberLevel > 0 && _memberLevel < 6, "Not a valid member level.");

        //Make this require the specific role.
        LibAccessControlRoles.requireGuildAdmin(LibMeta._msgSender(), _organizationId, _guildId);

        GuildUserInfo storage _userInfo = getGuildUserInfo(_organizationId, _guildId, _user);

        _userInfo.memberLevel = _memberLevel;

        emit GuildManagerStorage.MemberLevelUpdated(_organizationId, _guildId, _user, _memberLevel);
    }

    function changeGuildOwner(
        bytes32 _organizationId,
        uint32 _guildId,
        address _newOwner
    ) internal onlyGuildOwner(_organizationId, _guildId, "TRANSFER_OWNER") onlyActiveGuild(_organizationId, _guildId) {
        GuildUserStatus _newOwnerOldStatus = getGuildUserInfo(_organizationId, _guildId, _newOwner).userStatus;
        require(
            _newOwnerOldStatus == GuildUserStatus.MEMBER || _newOwnerOldStatus == GuildUserStatus.ADMIN,
            "Can only make member owner"
        );

        _changeUserStatus(_organizationId, _guildId, LibMeta._msgSender(), GuildUserStatus.MEMBER);
        _changeUserStatus(_organizationId, _guildId, _newOwner, GuildUserStatus.OWNER);
    }

    function terminateGuild(
        bytes32 _organizationId,
        uint32 _guildId,
        string calldata _reason
    ) internal onlyActiveGuild(_organizationId, _guildId) {
        LibAccessControlRoles.requireGuildTerminator(LibMeta._msgSender(), _organizationId, _guildId);

        GuildManagerStorage.Layout storage _l = GuildManagerStorage.layout();

        _l.organizationIdToGuildIdToInfo[_organizationId][_guildId].guildStatus = GuildStatus.TERMINATED;

        emit GuildManagerStorage.GuildTerminated(_organizationId, _guildId, LibMeta._msgSender(), _reason);
    }

    // =============================================================
    //                        View Functions
    // =============================================================

    function userCanCreateGuild(bytes32 _organizationId, address _user) internal view returns (bool) {
        GuildManagerStorage.Layout storage _l = GuildManagerStorage.layout();
        GuildCreationRule _creationRule = _l.guildOrganizationInfo[_organizationId].creationRule;
        if (_creationRule == GuildCreationRule.ANYONE) {
            return true;
        } else if (_creationRule == GuildCreationRule.ADMIN_ONLY) {
            return _user == LibOrganizationManager.getOrganizationInfo(_organizationId).admin;
        } else {
            // CUSTOM_RULE
            address _customGuildManagerAddress = _l.guildOrganizationInfo[_organizationId].customGuildManagerAddress;
            require(_customGuildManagerAddress != address(0), "No manager for CUSTOM_RULE");

            return ICustomGuildManager(_customGuildManagerAddress).canCreateGuild(_user, _organizationId);
        }
    }

    function isGuildOwner(bytes32 _organizationId, uint32 _guildId, address _user) internal view returns (bool) {
        return getGuildUserInfo(_organizationId, _guildId, _user).userStatus == GuildUserStatus.OWNER;
    }

    function isGuildAdminOrOwner(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user
    ) internal view returns (bool) {
        GuildUserStatus _userStatus = getGuildUserInfo(_organizationId, _guildId, _user).userStatus;
        return _userStatus == GuildUserStatus.OWNER || _userStatus == GuildUserStatus.ADMIN;
    }

    function getGuildStatus(bytes32 _organizationId, uint32 _guildId) internal view returns (GuildStatus) {
        GuildManagerStorage.Layout storage _l = GuildManagerStorage.layout();

        return _l.organizationIdToGuildIdToInfo[_organizationId][_guildId].guildStatus;
    }

    // =============================================================
    //                         Assertions
    // =============================================================

    function requireGuildOwner(bytes32 _organizationId, uint32 _guildId, string memory _action) internal view {
        if (!isGuildOwner(_organizationId, _guildId, LibMeta._msgSender())) {
            revert GuildManagerStorage.NotGuildOwner(LibMeta._msgSender(), _action);
        }
    }

    function requireGuildOwnerOrAdmin(bytes32 _organizationId, uint32 _guildId, string memory _action) internal view {
        if (!isGuildAdminOrOwner(_organizationId, _guildId, LibMeta._msgSender())) {
            revert GuildManagerStorage.NotGuildOwnerOrAdmin(LibMeta._msgSender(), _action);
        }
    }

    function requireActiveGuild(bytes32 _organizationId, uint32 _guildId) internal view {
        GuildStatus _guildStatus = getGuildStatus(_organizationId, _guildId);

        if (_guildStatus != GuildStatus.ACTIVE) {
            revert GuildManagerStorage.GuildIsNotActive(_organizationId, _guildId);
        }
    }

    function requireTreasureTagHolder(address _user) internal view {
        GuildManagerStorage.Layout storage _l = GuildManagerStorage.layout();

        if (IERC721Upgradeable(_l.treasureTagNFTAddress).balanceOf(_user) == 0) {
            revert GuildManagerStorage.UserDoesNotOwnTreasureTag(_user);
        }
    }

    // =============================================================
    //                          Private
    // =============================================================

    // Changes the status for the given user/guild/org combination.
    // This function does validation and adjust user membership per organization.
    // This function does not do ANY permissions check to see if this user should be set
    // to the status.
    function _changeUserStatus(
        bytes32 _organizationId,
        uint32 _guildId,
        address _user,
        GuildUserStatus _newStatus
    ) private {
        GuildUserInfo storage _guildUserInfo = getGuildInfo(_organizationId, _guildId).addressToGuildUserInfo[_user];

        GuildUserStatus _oldStatus = _guildUserInfo.userStatus;

        require(_oldStatus != _newStatus, "Can't set user to same status.");

        _guildUserInfo.userStatus = _newStatus;

        if (_newStatus == GuildUserStatus.OWNER) {
            getGuildInfo(_organizationId, _guildId).currentOwner = _user;
        }

        bool _wasInGuild = _oldStatus != GuildUserStatus.NOT_ASSOCIATED && _oldStatus != GuildUserStatus.INVITED;
        bool _isNowInGuild = _newStatus != GuildUserStatus.NOT_ASSOCIATED && _newStatus != GuildUserStatus.INVITED;

        if (!_wasInGuild && _isNowInGuild) {
            _onUserJoinedGuild(_organizationId, _guildId, _user);
        } else if (_wasInGuild && !_isNowInGuild) {
            _onUserLeftGuild(_organizationId, _guildId, _user);
        }

        emit GuildManagerStorage.GuildUserStatusChanged(_organizationId, _guildId, _user, _newStatus);
    }

    function _onUserJoinedGuild(bytes32 _organizationId, uint32 _guildId, address _user) private {
        GuildOrganizationInfo storage _orgInfo = getGuildOrganizationInfo(_organizationId);
        GuildInfo storage _guildInfo = getGuildInfo(_organizationId, _guildId);
        GuildOrganizationUserInfo storage _orgUserInfo = getUserInfo(_organizationId, _user);
        GuildUserInfo storage _guildUserInfo = _guildInfo.addressToGuildUserInfo[_user];

        _orgUserInfo.guildIdsAMemberOf.push(_guildId);
        _guildUserInfo.timeUserJoined = uint64(block.timestamp);
        if (_orgInfo.maxGuildsPerUser < _orgUserInfo.guildIdsAMemberOf.length) {
            revert GuildManagerStorage.UserInTooManyGuilds(_organizationId, _user);
        }

        _guildUserInfo.memberLevel = 1;

        _guildInfo.usersInGuild++;

        uint32 _maxUsersForGuild = getMaxUsersForGuild(_organizationId, _guildId);
        if (_maxUsersForGuild < _guildInfo.usersInGuild) {
            revert GuildManagerStorage.GuildFull(_organizationId, _guildId);
        }

        // Mint their membership NFT
        IGuildToken(_orgInfo.tokenAddress).adminMint(_user, _guildId, 1);

        // Check to make sure the user is not in guild joining timeout
        require(
            block.timestamp >= _orgUserInfo.timeUserLeftGuild + _orgInfo.timeoutAfterLeavingGuild, "Cooldown not over."
        );
    }

    function _onUserLeftGuild(bytes32 _organizationId, uint32 _guildId, address _user) private {
        GuildUserInfo storage _guildUserInfo = getGuildInfo(_organizationId, _guildId).addressToGuildUserInfo[_user];
        GuildOrganizationUserInfo storage _orgUserInfo = getUserInfo(_organizationId, _user);

        for (uint256 i = 0; i < _orgUserInfo.guildIdsAMemberOf.length; i++) {
            uint32 _guildIdAMemberOf = _orgUserInfo.guildIdsAMemberOf[i];
            if (_guildIdAMemberOf == _guildId) {
                _orgUserInfo.guildIdsAMemberOf[i] =
                    _orgUserInfo.guildIdsAMemberOf[_orgUserInfo.guildIdsAMemberOf.length - 1];
                _orgUserInfo.guildIdsAMemberOf.pop();
                break;
            }
        }

        delete _guildUserInfo.timeUserJoined;
        delete _guildUserInfo.memberLevel;

        getGuildInfo(_organizationId, _guildId).usersInGuild--;

        // Burn their membership NFT
        IGuildToken(getGuildOrganizationInfo(_organizationId).tokenAddress).adminBurn(_user, _guildId, 1);

        // Mark down when the user is leaving the guild.
        _orgUserInfo.timeUserLeftGuild = uint64(block.timestamp);
    }

    // =============================================================
    //                      PRIVATE MODIFIERS
    // =============================================================

    modifier onlyGuildOwner(bytes32 _organizationId, uint32 _guildId, string memory _action) {
        requireGuildOwner(_organizationId, _guildId, _action);
        _;
    }

    modifier onlyGuildOwnerOrAdmin(bytes32 _organizationId, uint32 _guildId, string memory _action) {
        requireGuildOwnerOrAdmin(_organizationId, _guildId, _action);
        _;
    }

    modifier onlyActiveGuild(bytes32 _organizationId, uint32 _guildId) {
        requireActiveGuild(_organizationId, _guildId);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibBBase64 } from "./LibBBase64.sol";
import { GuildTokenStorage } from "src/guilds/guildtoken/GuildTokenStorage.sol";
import { IGuildManager } from "src/interfaces/IGuildManager.sol";

/**
 * @title Guild Manager Library
 * @dev This library is used to implement features that use/update storage data for the Guild Manager contracts
 */
library LibGuildToken {
    // =============================================================
    //                      State Helpers
    // =============================================================

    function getGuildManager() internal view returns (IGuildManager manager_) {
        manager_ = GuildTokenStorage.layout().guildManager;
    }

    function getOrganizationId() internal view returns (bytes32 orgId_) {
        orgId_ = GuildTokenStorage.layout().organizationId;
    }

    function setGuildManager(address _guildManagerAddress) internal {
        GuildTokenStorage.layout().guildManager = IGuildManager(_guildManagerAddress);
    }

    function setOrganizationId(bytes32 _orgId) internal {
        GuildTokenStorage.layout().organizationId = _orgId;
    }

    function uri(uint256 _tokenId) internal view returns (string memory) {
        GuildTokenStorage.Layout storage _l = GuildTokenStorage.layout();
        uint32 _castedtokenId = uint32(_tokenId);
        // For our purposes, token id and guild id are the same.
        //
        require(_l.guildManager.isValidGuild(_l.organizationId, _castedtokenId), "Not valid guild");

        (string memory _imageData, bool _isSymbolOnChain) =
            _l.guildManager.guildSymbolInfo(_l.organizationId, _castedtokenId);

        string memory _finalImageData;

        if (_isSymbolOnChain) {
            _finalImageData =
                string(abi.encodePacked("data:image/svg+xml;base64,", LibBBase64.encode(bytes(_drawSVG(_imageData)))));
        } else {
            // Probably a URL. Just return it raw.
            //
            _finalImageData = _imageData;
        }
        // solhint-disable quotes
        string memory _metadata = string(
            abi.encodePacked(
                '{"name": "',
                _l.guildManager.guildName(_l.organizationId, _castedtokenId),
                '", "description": "',
                _l.guildManager.guildDescription(_l.organizationId, _castedtokenId),
                '", "image": "',
                _finalImageData,
                '", "attributes": []}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", LibBBase64.encode(bytes(_metadata))));
    }

    // =============================================================
    //                          Private
    // =============================================================

    function _drawImage(string memory _data) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                _data,
                '"/>'
            )
        );
    }

    function _drawSVG(string memory _data) private pure returns (string memory) {
        string memory _svgString = string(abi.encodePacked(_drawImage(_data)));

        return string(
            abi.encodePacked(
                '<svg id="imageRender" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                _svgString,
                "</svg>"
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { MetaTxFacetStorage } from "src/metatx/MetaTxFacetStorage.sol";

/// @title Library for handling meta transactions with the EIP2771 standard
/// @notice The logic for getting msgSender and msgData are were copied from OpenZeppelin's
///  ERC2771ContextUpgradeable contract
library LibMeta {
    struct Layout {
        address trustedForwarder;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.metatx");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    // =============================================================
    //                      State Helpers
    // =============================================================

    function isTrustedForwarder(address _forwarder) internal view returns (bool isTrustedForwarder_) {
        isTrustedForwarder_ = layout().trustedForwarder == _forwarder;
    }

    // =============================================================
    //                      Meta Tx Helpers
    // =============================================================

    /**
     * @dev The only valid forwarding contract is the one that is going to run the executing function
     */
    function _msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender_ := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender_ = msg.sender;
        }
    }

    /**
     * @dev The only valid forwarding contract is the one that is going to run the executing function
     */
    function _msgData() internal view returns (bytes calldata data_) {
        if (msg.sender == address(this)) {
            data_ = msg.data[:msg.data.length - 20];
        } else {
            data_ = msg.data;
        }
    }

    function getMetaDelegateAddress() internal view returns (address delegateAddress_) {
        return address(MetaTxFacetStorage.layout().systemDelegateApprover);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OrganizationInfo } from "src/interfaces/IOrganizationManager.sol";
import { IGuildToken } from "src/interfaces/IGuildToken.sol";
import { ICustomGuildManager } from "src/interfaces/ICustomGuildManager.sol";
import { OrganizationManagerStorage } from "src/organizations/OrganizationManagerStorage.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";

/// @title Library for handling storage interfacing for Guild Manager contracts
library LibOrganizationManager {
    // =============================================================
    //                      Getters/Setters
    // =============================================================

    /**
     * @param _orgId The id of the org to retrieve info for
     * @return info_ The return struct is storage. This means all state changes to the struct will save automatically,
     *  instead of using a memory copy overwrite
     */
    function getOrganizationInfo(bytes32 _orgId) internal view returns (OrganizationInfo storage info_) {
        info_ = OrganizationManagerStorage.layout().organizationIdToInfo[_orgId];
    }

    /**
     * @dev Assumes that sender permissions have already been checked
     */
    function setOrganizationNameAndDescription(
        bytes32 _organizationId,
        string calldata _name,
        string calldata _description
    ) internal {
        OrganizationInfo storage _info = getOrganizationInfo(_organizationId);
        _info.name = _name;
        _info.description = _description;
        emit OrganizationManagerStorage.OrganizationInfoUpdated(_organizationId, _name, _description);
    }

    /**
     * @dev Assumes that sender permissions have already been checked
     */
    function setOrganizationAdmin(bytes32 _organizationId, address _admin) internal {
        if (_admin == address(0) || _admin == getOrganizationInfo(_organizationId).admin) {
            revert OrganizationManagerStorage.InvalidOrganizationAdmin(_admin);
        }
        getOrganizationInfo(_organizationId).admin = _admin;
        emit OrganizationManagerStorage.OrganizationAdminUpdated(_organizationId, _admin);
    }

    // =============================================================
    //                        Create Functions
    // =============================================================

    function createOrganization(
        bytes32 _newOrganizationId,
        string calldata _name,
        string calldata _description
    ) internal {
        if (getOrganizationInfo(_newOrganizationId).admin != address(0)) {
            revert OrganizationManagerStorage.OrganizationAlreadyExists(_newOrganizationId);
        }
        setOrganizationNameAndDescription(_newOrganizationId, _name, _description);
        setOrganizationAdmin(_newOrganizationId, LibMeta._msgSender());

        emit OrganizationManagerStorage.OrganizationCreated(_newOrganizationId);
    }

    // =============================================================
    //                       Helper Functionr
    // =============================================================

    function requireOrganizationAdmin(address _sender, bytes32 _organizationId) internal view {
        if (_sender != getOrganizationInfo(_organizationId).admin) {
            revert OrganizationManagerStorage.NotOrganizationAdmin(LibMeta._msgSender());
        }
    }

    function requireOrganizationValid(bytes32 _organizationId) internal view {
        if (LibOrganizationManager.getOrganizationInfo(_organizationId).admin == address(0)) {
            revert OrganizationManagerStorage.NonexistantOrganization(_organizationId);
        }
    }

    // =============================================================
    //                         Modifiers
    // =============================================================

    modifier onlyOrganizationAdmin(bytes32 _organizationId) {
        requireOrganizationAdmin(LibMeta._msgSender(), _organizationId);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { LibMeta } from "src/libraries/LibMeta.sol";
import { PaymentsStorage, ERC20Info } from "src/payments/PaymentsStorage.sol";

/// @title Library for handling storage interfacing for payments
library LibPayments {
    /**
     * @param _erc20Addr The address of the coin to retrieve info for
     * @return info_ The return struct is storage. This means all state changes to the struct will save automatically,
     *  instead of using a memory copy overwrite
     */
    function getERC20Info(address _erc20Addr) internal view returns (ERC20Info storage info_) {
        info_ = PaymentsStorage.layout().erc20ToInfo[_erc20Addr];
    }

    /**
     * @return priceFeed_ The price feed for the gas token valued in USD
     */
    function getGasTokenUSDPriceFeed() internal view returns (AggregatorV3Interface priceFeed_) {
        priceFeed_ = PaymentsStorage.layout().gasTokenUSDPriceFeed;
    }

    /**
     * @param _erc20Addr The address of the coin to retrieve the price feed for
     * @return priceFeed_ The price feed for the gas token valued in the ERC20 token
     */
    function getGasTokenERC20PriceFeed(address _erc20Addr) internal view returns (AggregatorV3Interface priceFeed_) {
        priceFeed_ = PaymentsStorage.layout().erc20ToInfo[_erc20Addr].gasTokenPricedInERC20Aggregator;
    }

    function getMagicAddress() internal view returns (address magicAddress_) {
        magicAddress_ = PaymentsStorage.layout().magicAddress;
    }

    /**
     * @param _priceFeedAddr The address of the price feed to set
     */
    function setGasTokenUSDPriceFeed(address _priceFeedAddr) internal {
        PaymentsStorage.layout().gasTokenUSDPriceFeed = AggregatorV3Interface(_priceFeedAddr);
    }

    /**
     * @param _erc20Addr The address of the ERC20 token to set the price feed for
     * @param _priceFeedAddr The address of the price feed to set
     */
    function setGasTokenERC20PriceFeed(address _erc20Addr, address _priceFeedAddr) internal {
        PaymentsStorage.layout().erc20ToInfo[_erc20Addr].gasTokenPricedInERC20Aggregator =
            AggregatorV3Interface(_priceFeedAddr);
    }

    /**
     * @param _magicAddress The address of the $MAGIC token
     */
    function setMagicAddress(address _magicAddress) internal {
        PaymentsStorage.layout().magicAddress = _magicAddress;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SimpleCraftingStorage } from "../crafting/SimpleCraftingStorage.sol";

library LibSimpleCrafting {
    /**
     * @dev Returns if a given recipeId for a collection is allowed
     * @param _collection The collection to check.
     * @param _recipeId The recipeId.
     */
    function getCollectionToRecipeIdToAllowed(address _collection, uint256 _recipeId) internal view returns (bool) {
        return SimpleCraftingStorage.getState().collectionToRecipeIdToAllowed[_collection][_recipeId];
    }

    /**
     * @dev sets a given recipeId for a collection to boolean
     * @param _collection The collection to set.
     * @param _recipeId The recipeId.
     * @param _allowed Whether this recipe is allowed.
     */
    function setCollectionToRecipeIdToAllowed(address _collection, uint256 _recipeId, bool _allowed) internal {
        SimpleCraftingStorage.getState().collectionToRecipeIdToAllowed[_collection][_recipeId] = _allowed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibAccessControlRoles } from "./LibAccessControlRoles.sol";

import { SpellcasterGMStorage } from "../spellcaster/SpellcasterGMStorage.sol";

import { LibMeta } from "./LibMeta.sol";

library LibSpellcasterGM {
    /**
     * @dev Emitted when an account is not a trusted signer.
     * @param account The signer address
     */
    error AccountIsNotTrustedSigner(address account);

    /**
     * @dev Emitted when a nonce is already used.
     * @param account The signer address
     * @param nonce The nonce
     */
    error NonceUsed(address account, uint256 nonce);

    /**
     * @dev Emitted when the msg sender was not the contact owner.
     * @param account The msg sender
     */
    error MsgSenderIsNotContractOwner(address account);

    /**
     * @dev Sets a trusted signer to spellcaster
     * @param _account The address of the signer.
     * @param _isTrusted Whether they are trusted or not
     */
    function setTrustedSigner(address _account, bool _isTrusted) internal {
        if (LibMeta._msgSender() != LibAccessControlRoles.contractOwner()) {
            revert MsgSenderIsNotContractOwner(_account);
        }

        SpellcasterGMStorage.layout().trustedSigners[_account] = _isTrusted;
    }

    /**
     * @dev Returns whether a signer is trusted
     * @param _account The address of the signer.
     */
    function isTrustedSigner(address _account) public view returns (bool) {
        return SpellcasterGMStorage.layout().trustedSigners[_account];
    }

    /**
     * @dev Use a nonce, and revert if already used
     * @param _account The address of the signer.
     * @param _nonce The nonce.
     */
    function useNonce(address _account, uint96 _nonce) internal {
        if (SpellcasterGMStorage.layout().trustedSignersToNonceToUsed[_account][_nonce]) {
            revert NonceUsed(_account, _nonce);
        }

        SpellcasterGMStorage.layout().trustedSignersToNonceToUsed[_account][_nonce] = true;
    }

    /**
     * @dev Function that reverts if passed account is not a trusted signer
     * @param _account The address of the signer.
     */
    function requireTrustedSigner(address _account) external view {
        if (!isTrustedSigner(_account)) revert AccountIsNotTrustedSigner(_account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PausableStorage } from "@openzeppelin/contracts-diamond/security/PausableStorage.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-diamond/utils/StringsUpgradeable.sol";
import { LibMeta } from "./LibMeta.sol";

library LibUtilities {
    event Paused(address account);
    event Unpaused(address account);

    error ArrayLengthMismatch(uint256 len1, uint256 len2);

    error IsPaused();
    error NotPaused();

    // =============================================================
    //                      Array Helpers
    // =============================================================

    function requireArrayLengthMatch(uint256 _length1, uint256 _length2) internal pure {
        if (_length1 != _length2) {
            revert ArrayLengthMismatch(_length1, _length2);
        }
    }

    function asSingletonArray(uint256 _item) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](1);
        array_[0] = _item;
    }

    function asSingletonArray(string memory _item) internal pure returns (string[] memory array_) {
        array_ = new string[](1);
        array_[0] = _item;
    }

    // =============================================================
    //                     Misc Functions
    // =============================================================

    function compareStrings(string memory _a, string memory _b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
    }

    function setPause(bool _paused) internal {
        PausableStorage.layout()._paused = _paused;
        if (_paused) {
            emit Paused(LibMeta._msgSender());
        } else {
            emit Unpaused(LibMeta._msgSender());
        }
    }

    function paused() internal view returns (bool) {
        return PausableStorage.layout()._paused;
    }

    function requirePaused() internal view {
        if (!paused()) {
            revert NotPaused();
        }
    }

    function requireNotPaused() internal view {
        if (paused()) {
            revert IsPaused();
        }
    }

    function toString(uint256 _value) internal pure returns (string memory) {
        return StringsUpgradeable.toString(_value);
    }

    /**
     * @notice This function takes the first 4 MSB of the given bytes32 and converts them to _a bytes4
     * @dev This function is useful for grabbing function selectors from calldata
     * @param _inBytes The bytes to convert to bytes4
     */
    function convertBytesToBytes4(bytes memory _inBytes) internal pure returns (bytes4 outBytes4_) {
        if (_inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4_ := mload(add(_inBytes, 32))
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ERC721TokenStorageData {
    address owner;
    bool stored;
}

library StakingStorage {
    struct Layout {
        mapping(address => mapping(uint256 => ERC721TokenStorageData)) tokenAddressToTokenIdToERC721TokenStorageData;
        mapping(address => mapping(address => uint256)) tokenAddressToAddressToTokensStored;
        mapping(address => mapping(uint256 => mapping(address => uint256))) tokenAddressToTokenIdToUserToQuantityStored;
        mapping(uint256 => bool) usedNonces;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.staking");

    function getState() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    function getERC721TokenStorageData(
        address _tokenAddress,
        uint256 _tokenId
    ) internal view returns (ERC721TokenStorageData memory) {
        return getState().tokenAddressToTokenIdToERC721TokenStorageData[_tokenAddress][_tokenId];
    }

    function setERC721TokenStorageData(
        address _tokenAddress,
        uint256 _tokenId,
        ERC721TokenStorageData memory _tokenStorageData
    ) internal {
        getState().tokenAddressToTokenIdToERC721TokenStorageData[_tokenAddress][_tokenId] = _tokenStorageData;
    }

    function getERC20TokensStored(address _tokenAddress, address _user) internal view returns (uint256) {
        return getState().tokenAddressToAddressToTokensStored[_tokenAddress][_user];
    }

    function setERC20TokensStored(address _tokenAddress, address _user, uint256 _amount) internal {
        getState().tokenAddressToAddressToTokensStored[_tokenAddress][_user] = _amount;
    }

    function getERC1155TokensStored(
        address _tokenAddress,
        uint256 _tokenId,
        address _user
    ) internal view returns (uint256) {
        return getState().tokenAddressToTokenIdToUserToQuantityStored[_tokenAddress][_tokenId][_user];
    }

    function setERC1155TokensStored(
        address _tokenAddress,
        uint256 _tokenId,
        address _user,
        uint256 _quantity
    ) internal {
        getState().tokenAddressToTokenIdToUserToQuantityStored[_tokenAddress][_tokenId][_user] = _quantity;
    }

    function getUsedNonce(uint256 _nonce) internal view returns (bool) {
        return getState().usedNonces[_nonce];
    }

    function setUsedNonce(uint256 _nonce, bool _set) internal {
        getState().usedNonces[_nonce] = _set;
    }

    function compareStrings(string memory _a, string memory _b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { ECDSAUpgradeable } from "@openzeppelin/contracts-diamond/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-diamond/utils/cryptography/EIP712Upgradeable.sol";

import { FacetInitializable } from "src/utils/FacetInitializable.sol";
import { LibAccessControlRoles } from "src/libraries/LibAccessControlRoles.sol";
import { LibUtilities } from "src/libraries/LibUtilities.sol";

import {
    MetaTxFacetStorage, ForwardRequest, ISystemDelegateApprover, FORWARD_REQ_TYPEHASH
} from "./MetaTxFacetStorage.sol";
import { SupportsMetaTx } from "./SupportsMetaTx.sol";

contract MetaTxFacet is SupportsMetaTx {
    using ECDSAUpgradeable for bytes32;

    event ExecutedMetaTx(address userAddress, address payable relayerAddress, bytes functionSignature);
    event DelegateApproverSet(address delegateApprover);

    /**
     * @dev Sets all necessary state and permissions for the contract
     *  behalf of the real sending account
     *  Assumes that the _systemDelegateApprover is already set
     */
    function __MetaTxFacet_init() internal onlyFacetInitializing { }

    function verify(
        ForwardRequest calldata _req,
        bytes calldata _signature,
        bool _shouldRevert
    ) public view returns (bool) {
        address _signer = _hashTypedDataV4(
            keccak256(
                abi.encode(FORWARD_REQ_TYPEHASH, _req.from, _req.nonce, _req.organizationId, keccak256(_req.data))
            )
        ).recover(_signature);
        if (MetaTxFacetStorage.layout().nonces[_req.from][_req.nonce]) {
            if (!_shouldRevert) {
                return false;
            }
            revert MetaTxFacetStorage.NonceAlreadyUsedForSender(_req.from, _req.nonce);
        }
        if (
            _signer != _req.from
                && !MetaTxFacetStorage.layout().systemDelegateApprover.isDelegateApprovedForSystem(
                    _req.from, _req.organizationId, _signer
                )
        ) {
            if (!_shouldRevert) {
                return false;
            }
            revert MetaTxFacetStorage.UnauthorizedSignerForSender(_signer, _req.from);
        }
        return true;
    }

    function execute(ForwardRequest calldata _req, bytes calldata _signature) public payable returns (bytes memory) {
        bytes4 _functionSelector = LibUtilities.convertBytesToBytes4(_req.data);
        if (_functionSelector == msg.sig) {
            revert MetaTxFacetStorage.CannotCallExecuteFromExecute();
        }
        verify(_req, _signature, true);

        MetaTxFacetStorage.Layout storage _l = MetaTxFacetStorage.layout();
        _l.nonces[_req.from][_req.nonce] = true;
        _l.sessionOrganizationId = _req.organizationId;

        (bool _success, bytes memory _returnData) = address(this).call(abi.encodePacked(_req.data, _req.from));

        if (!_success) {
            if (_returnData.length > 0) {
                // bubble up the error
                assembly {
                    revert(add(32, _returnData), mload(_returnData))
                }
            } else {
                revert("MetaTx: execute reverted");
            }
        }

        if (_l.sessionOrganizationId != "") {
            revert MetaTxFacetStorage.SessionOrganizationIdNotConsumed();
        }
        emit ExecutedMetaTx(_req.from, payable(msg.sender), _req.data);
        return _returnData;
    }

    /**
     * @notice This function is used to set the delegate approver address
     * @dev This function is only callable by the owner of the contract
     * @param _organizationDelegateApprover The delegate approver address that tracks which wallet can run txs on
     *  behalf of the real sending account
     */
    function setDelegateAddress(address _organizationDelegateApprover) external {
        if (_organizationDelegateApprover == address(0)) {
            revert MetaTxFacetStorage.InvalidDelegateApprover();
        }
        // Do not use _msgSender, as we want the owner themselves to change this.
        LibAccessControlRoles.requireOwner(msg.sender);
        MetaTxFacetStorage.layout().systemDelegateApprover = ISystemDelegateApprover(_organizationDelegateApprover);

        emit DelegateApproverSet(_organizationDelegateApprover);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibBBase64 } from "src/libraries/LibBBase64.sol";
import { IGuildManager } from "src/interfaces/IGuildManager.sol";

/**
 * @notice The contract that handles validating meta transaction delegate approvals
 * @dev References to 'System' are synonymous with 'Organization'
 */
interface ISystemDelegateApprover {
    function isDelegateApprovedForSystem(
        address _account,
        bytes32 _systemId,
        address _delegate
    ) external view returns (bool);
    function setDelegateApprovalForSystem(bytes32 _systemId, address _delegate, bool _approved) external;
    function setDelegateApprovalForSystemBySignature(
        bytes32 _systemId,
        address _delegate,
        bool _approved,
        address _signer,
        uint256 _nonce,
        bytes calldata _signature
    ) external;
}

/**
 * @notice The struct used for signing and validating meta transactions
 * @dev from+nonce is packed to a single storage slot to save calldata gas on rollups
 * @param from The address that is being called on behalf of
 * @param nonce The nonce of the transaction. Used to prevent replay attacks
 * @param organizationId The id of the invoking organization
 * @param data The calldata of the function to be called
 */
struct ForwardRequest {
    address from;
    uint96 nonce;
    bytes32 organizationId;
    bytes data;
}

/**
 * @dev The typehash of the ForwardRequest struct used when signing the meta transaction
 *  This must match the ForwardRequest struct, and must not have extra whitespace or it will invalidate the signature
 */
bytes32 constant FORWARD_REQ_TYPEHASH =
    keccak256("ForwardRequest(address from,uint96 nonce,bytes32 organizationId,bytes data)");

library MetaTxFacetStorage {
    /**
     * @dev Emitted when an invalid delegate approver is provided or not allowed.
     */
    error InvalidDelegateApprover();

    /**
     * @dev Emitted when the `execute` function is called recursively, which is not allowed.
     */
    error CannotCallExecuteFromExecute();

    /**
     * @dev Emitted when the session organization ID is not consumed or processed as expected.
     */
    error SessionOrganizationIdNotConsumed();

    /**
     * @dev Emitted when there is a mismatch between the session organization ID and the function organization ID.
     * @param sessionOrganizationId The session organization ID
     * @param functionOrganizationId The function organization ID
     */
    error SessionOrganizationIdMismatch(bytes32 sessionOrganizationId, bytes32 functionOrganizationId);

    /**
     * @dev Emitted when a nonce has already been used for a specific sender address.
     * @param sender The address of the sender
     * @param nonce The nonce that has already been used
     */
    error NonceAlreadyUsedForSender(address sender, uint256 nonce);

    /**
     * @dev Emitted when the signer is not authorized to sign on behalf of the sender address.
     * @param signer The address of the signer
     * @param sender The address of the sender
     */
    error UnauthorizedSignerForSender(address signer, address sender);

    struct Layout {
        /**
         * @notice The delegate approver that tracks which wallet can run txs on behalf of the real sending account
         * @dev References to 'System' are synonymous with 'Organization'
         */
        ISystemDelegateApprover systemDelegateApprover;
        /**
         * @notice Tracks which nonces have been used by the from address. Prevents replay attacks.
         * @dev Key1: from address, Key2: nonce, Value: used or not
         */
        mapping(address => mapping(uint256 => bool)) nonces;
        /**
         * @dev The organization id of the session. Set before invoking a meta transaction and requires the function to clear it
         *  to ensure the session organization matches the function organizationId
         */
        bytes32 sessionOrganizationId;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.facet.metatx");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { ECDSAUpgradeable } from "@openzeppelin/contracts-diamond/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-diamond/utils/cryptography/EIP712Upgradeable.sol";

import { FacetInitializable } from "src/utils/FacetInitializable.sol";
import { LibAccessControlRoles } from "src/libraries/LibAccessControlRoles.sol";
import { LibUtilities } from "src/libraries/LibUtilities.sol";

import {
    MetaTxFacetStorage, ForwardRequest, ISystemDelegateApprover, FORWARD_REQ_TYPEHASH
} from "./MetaTxFacetStorage.sol";

abstract contract SupportsMetaTx is FacetInitializable, EIP712Upgradeable {
    using ECDSAUpgradeable for bytes32;

    /**
     * @dev Sets all necessary state and permissions for the contract. Assumed to be called from an initializing script instead of a facet
     * @param _organizationDelegateApprover The delegate approver address that tracks which wallet can run txs on
     *  behalf of the real sending account
     */
    function __SupportsMetaTx_init(address _organizationDelegateApprover) internal onlyFacetInitializing {
        if (_organizationDelegateApprover == address(0)) {
            revert MetaTxFacetStorage.InvalidDelegateApprover();
        }
        __EIP712_init("Spellcaster", "1.0.0");

        MetaTxFacetStorage.layout().systemDelegateApprover = ISystemDelegateApprover(_organizationDelegateApprover);
    }

    /**
     * @dev Verifies and consumes the session ID, ensuring it matches the provided organization ID.
     *      If the call is from a meta transaction, the session ID is consumed and must match the organization ID.
     *      Resets the session ID before the call to ensure that subsequent calls do not keep validating.
     * @param _organizationId The organization ID to be verified against the session ID
     */
    function verifyAndConsumeSessionId(bytes32 _organizationId) internal {
        MetaTxFacetStorage.Layout storage _l = MetaTxFacetStorage.layout();
        bytes32 _sessionId = _l.sessionOrganizationId;

        if (_sessionId != "") {
            if (_sessionId != _organizationId) {
                revert MetaTxFacetStorage.SessionOrganizationIdMismatch(_sessionId, _organizationId);
            }

            _l.sessionOrganizationId = "";
        }
    }

    /**
     * @dev Returns the session organization ID from the MetaTxFacetStorage layout.
     * @return sessionId_ The session organization ID
     */
    function getSessionOrganizationId() internal view returns (bytes32 sessionId_) {
        sessionId_ = MetaTxFacetStorage.layout().sessionOrganizationId;
    }

    modifier supportsMetaTx(bytes32 _organizationId) virtual {
        MetaTxFacetStorage.Layout storage _l = MetaTxFacetStorage.layout();
        bytes32 _sessionId = _l.sessionOrganizationId;
        // If the call is from a meta tx, consume the session id and require it to match
        if (_sessionId != "") {
            if (_sessionId != _organizationId) {
                revert MetaTxFacetStorage.SessionOrganizationIdMismatch(_sessionId, _organizationId);
            }
            // Reset the session id before the call to ensure that subsequent calls do not keep validating
            _l.sessionOrganizationId = "";
        }
        _;
    }

    modifier supportsMetaTxNoId() virtual {
        _;

        MetaTxFacetStorage.Layout storage _l = MetaTxFacetStorage.layout();
        // If the call is from a meta tx, consume the session id
        if (_l.sessionOrganizationId != "") {
            // Reset the session id after the call to ensure that a subsequent call will validate the session id if applicable
            _l.sessionOrganizationId = "";
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC1155Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC1155/ERC1155Upgradeable.sol";
import { IERC1155Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC1155/IERC1155Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-diamond/access/OwnableUpgradeable.sol";

contract ERC1155Consumer is ERC1155Upgradeable, OwnableUpgradeable {
    address public worldAddress;

    mapping(address => bool) public isAdmin;

    // constructor() ERC1155Upgradeable("uri") {}

    function initialize() public initializer {
        __ERC1155_init("uri");
        __Ownable_init();
    }

    function setAdmin(address _address, bool _isAdmin) public onlyOwner {
        isAdmin[_address] = _isAdmin;
    }

    function setWorldAddress(address _worldAddress) public onlyOwner {
        worldAddress = _worldAddress;
    }

    function mintFromWorld(address _user, uint256 _tokenId, uint256 _quantity) public {
        require(msg.sender == worldAddress, "Sender not world");
        _mint(_user, _tokenId, _quantity, "");
    }

    function mintArbitrary(address _user, uint256 _tokenId, uint256 _quantity) public {
        _mint(_user, _tokenId, _quantity, "");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/ERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/IERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-diamond/access/OwnableUpgradeable.sol";

contract ERC20Consumer is ERC20Upgradeable, OwnableUpgradeable {
    address public worldAddress;

    mapping(address => bool) public isAdmin;

    // constructor() ERC20Upgradeable("ERC20Consumer", "ERC20C") {}
    function initialize() public initializer {
        __ERC20_init("name", "symbol");
        __Ownable_init();
    }

    function setAdmin(address _address, bool _isAdmin) public onlyOwner {
        isAdmin[_address] = _isAdmin;
    }

    function setWorldAddress(address _worldAddress) public onlyOwner {
        worldAddress = _worldAddress;
    }

    function mintFromWorld(address _user, uint256 _tokenId) public {
        require(msg.sender == worldAddress, "Sender not world");
        _mint(_user, _tokenId);
    }

    function mintArbitrary(address _user, uint256 _quantity) public {
        _mint(_user, _quantity);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721EnumerableUpgradeable } from
    "@openzeppelin/contracts-diamond/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC721/IERC721Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-diamond/access/OwnableUpgradeable.sol";

contract ERC721Consumer is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    uint256 internal counter;
    address public worldAddress;

    mapping(address => bool) public isAdmin;

    // constructor() ERC721Upgradeable("ERC721Consumer", "ERC721C") {}
    function initialize() public initializer {
        __ERC721_init("name", "symbol");
        __Ownable_init();
    }

    function setAdmin(address _address, bool _isAdmin) public onlyOwner {
        isAdmin[_address] = _isAdmin;
    }

    function setWorldAddress(address _worldAddress) public onlyOwner {
        worldAddress = _worldAddress;
    }

    function mintFromWorld(address _user, uint256 _tokenId) public {
        require(msg.sender == worldAddress, "Sender not world");
        _mint(_user, _tokenId);
    }

    function mintArbitrary(address _user, uint256 _quantity) public {
        for (uint256 i = counter; i < counter + _quantity; i++) {
            _mint(_user, counter + i);
        }
        counter += _quantity;
    }

    function walletOfOwner(address _user) public view returns (uint256[] memory) {
        uint256 _tokenCount = balanceOf(_user);
        uint256[] memory _tokens = new uint256[](_tokenCount);

        for (uint256 i = 0; i < _tokenCount; i++) {
            _tokens[i] = tokenOfOwnerByIndex(_user, i);
        }

        return _tokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PausableStorage } from "@openzeppelin/contracts-diamond/security/PausableStorage.sol";
import { LibUtilities } from "./libraries/LibUtilities.sol";
import { LibMeta } from "./libraries/LibMeta.sol";
import { LibAccessControlRoles } from "./libraries/LibAccessControlRoles.sol";

// abstract contract to include shared utility modifiers for ease of use
// also includes modifiers imported from PausableUpgradeable
/// @title Abstract contract to include shared utility across all facets.
/// @dev Modifiers can't go in a library so this is where they should go, also includes meta-tx helpers
abstract contract Modifiers {
    // =============================================================
    //                         Modifiers
    // =============================================================

    /// @dev Pass-through to Openzeppelin's AccessControl onlyRole. Changed name to avoid name conflicts
    /// @param _role Role to be verified against the sender
    modifier onlyRole(bytes32 _role) {
        LibAccessControlRoles.requireRole(_role, LibMeta._msgSender());
        _;
    }

    /// @notice Returns whether or not the sender has at least one of the provided roles
    /// @param _roleOption1 Role to be verified against the sender
    /// @param _roleOption2 Role to be verified against the sender
    modifier requireEitherRole(bytes32 _roleOption1, bytes32 _roleOption2) {
        if (!_hasRole(_roleOption1, LibMeta._msgSender()) && !_hasRole(_roleOption2, LibMeta._msgSender())) {
            revert LibAccessControlRoles.MissingEitherRole(LibMeta._msgSender(), _roleOption1, _roleOption2);
        }
        _;
    }

    modifier whenNotPaused() {
        LibUtilities.requireNotPaused();
        _;
    }

    modifier whenPaused() {
        LibUtilities.requirePaused();
        _;
    }

    // =============================================================
    //                      Utility functions
    // =============================================================

    // Taken from AccessControlUpgradeable, and renamed to avoid conflicts with any contract importing AccessControlUpgradeable
    // Purposefully not importing the entire contract to avoid bloating this base contract.
    // If this changes in AccessControlUpgradeable, it would be a breaking change and contracts using this wouldn't be able to update anyway.
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        return LibAccessControlRoles.hasRole(_role, _account);
    }

    function _pause() internal whenNotPaused {
        PausableStorage.layout()._paused = true;
        emit LibUtilities.Paused(LibMeta._msgSender());
    }

    function _unpause() internal whenPaused {
        PausableStorage.layout()._paused = false;
        emit LibUtilities.Unpaused(LibMeta._msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Modifiers } from "../Modifiers.sol";
import { FacetInitializable } from "../utils/FacetInitializable.sol";
import { LibUtilities } from "../libraries/LibUtilities.sol";
import { LibAccessControlRoles, ADMIN_ROLE, ADMIN_GRANTER_ROLE } from "../libraries/LibAccessControlRoles.sol";
import { LibMeta } from "../libraries/LibMeta.sol";
import { LibOrganizationManager } from "src/libraries/LibOrganizationManager.sol";
import { SupportsMetaTx } from "src/metatx/SupportsMetaTx.sol";

import { IOrganizationManager, OrganizationInfo } from "src/interfaces/IOrganizationManager.sol";
import { OrganizationManagerStorage } from "./OrganizationManagerStorage.sol";

/**
 * @title Organization Management Facet contract.
 * @dev Use this facet to consume the ability to segment feature adoption by organization.
 */
contract OrganizationFacet is FacetInitializable, Modifiers, IOrganizationManager, SupportsMetaTx {
    /**
     * @dev Initialize the facet. Can be called externally or internally.
     * Ideally referenced in an initialization script facet
     */
    function OrganizationFacet_init() public facetInitializer(keccak256("OrganizationFacet_init")) { }

    // =============================================================
    //                        Public functions
    // =============================================================

    /**
     * @inheritdoc IOrganizationManager
     */
    function createOrganization(
        bytes32 _newOrganizationId,
        string calldata _name,
        string calldata _description
    ) public override onlyRole(ADMIN_ROLE) whenNotPaused supportsMetaTx(_newOrganizationId) {
        LibOrganizationManager.createOrganization(_newOrganizationId, _name, _description);
    }

    /**
     * @inheritdoc IOrganizationManager
     */
    function setOrganizationNameAndDescription(
        bytes32 _organizationId,
        string calldata _name,
        string calldata _description
    ) public override whenNotPaused onlyOrganizationAdmin(_organizationId) supportsMetaTx(_organizationId) {
        LibOrganizationManager.setOrganizationNameAndDescription(_organizationId, _name, _description);
    }

    /**
     * @inheritdoc IOrganizationManager
     */
    function setOrganizationAdmin(
        bytes32 _organizationId,
        address _admin
    ) public override whenNotPaused onlyOrganizationAdmin(_organizationId) supportsMetaTx(_organizationId) {
        LibOrganizationManager.setOrganizationAdmin(_organizationId, _admin);
    }

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /**
     * @inheritdoc IOrganizationManager
     */
    function getOrganizationInfo(bytes32 _organizationId) external view override returns (OrganizationInfo memory) {
        return LibOrganizationManager.getOrganizationInfo(_organizationId);
    }

    // =============================================================
    //                         MODIFIERS
    // =============================================================

    modifier onlyOrganizationAdmin(bytes32 _organizationId) {
        LibOrganizationManager.requireOrganizationAdmin(msg.sender, _organizationId);
        _;
    }

    modifier onlyValidOrganization(bytes32 _organizationId) {
        if (LibOrganizationManager.getOrganizationInfo(_organizationId).admin == address(0)) {
            revert OrganizationManagerStorage.NonexistantOrganization(_organizationId);
        }
        LibOrganizationManager.requireOrganizationValid(_organizationId);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OrganizationInfo } from "src/interfaces/IOrganizationManager.sol";
import { IGuildToken } from "src/interfaces/IGuildToken.sol";
import { ICustomGuildManager } from "src/interfaces/ICustomGuildManager.sol";

/**
 * @title OrganizationManagerStorage library
 * @notice This library contains the storage layout and events/errors for the OrganizationFacet contract.
 */
library OrganizationManagerStorage {
    struct Layout {
        mapping(bytes32 => OrganizationInfo) organizationIdToInfo;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.organization.manager");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    /**
     * @dev Emitted when a new organization is created.
     * @param organizationId The ID of the newly created organization
     */
    event OrganizationCreated(bytes32 organizationId);

    /**
     * @dev Emitted when an organization's information is updated.
     * @param organizationId The ID of the organization being updated
     * @param name The updated organization name
     * @param description The updated organization description
     */
    event OrganizationInfoUpdated(bytes32 organizationId, string name, string description);

    /**
     * @dev Emitted when an organization's admin is updated.
     * @param organizationId The ID of the organization being updated
     * @param admin The updated organization admin address
     */
    event OrganizationAdminUpdated(bytes32 organizationId, address admin);

    /**
     * @dev Emitted when the sender is not an organization admin and tries to perform an admin-only action.
     * @param sender The address of the sender attempting the action
     */
    error NotOrganizationAdmin(address sender);

    /**
     * @dev Emitted when an invalid organization admin address is provided.
     * @param admin The invalid admin address
     */
    error InvalidOrganizationAdmin(address admin);

    /**
     * @dev Emitted when an organization does not exist.
     * @param organizationId The ID of the non-existent organization
     */
    error NonexistantOrganization(bytes32 organizationId);

    /**
     * @dev Emitted when an organization already exists.
     * @param organizationId The ID of the existing organization
     */
    error OrganizationAlreadyExists(bytes32 organizationId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC165Upgradeable } from "@openzeppelin/contracts-diamond/utils/introspection/IERC165Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-diamond/utils/AddressUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-diamond/security/ReentrancyGuardUpgradeable.sol";
import { UD60x18, ud, convert } from "@prb/math/UD60x18.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { FacetInitializable } from "src/utils/FacetInitializable.sol";
import { Modifiers } from "src/Modifiers.sol";

import { IPayments, ERC20Info, PriceType } from "src/interfaces/IPayments.sol";
import { IPaymentsReceiver } from "src/interfaces/IPaymentsReceiver.sol";

import { LibUtilities } from "src/libraries/LibUtilities.sol";
import { ADMIN_ROLE } from "src/libraries/LibAccessControlRoles.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";
import { LibPayments } from "src/libraries/LibPayments.sol";
import { PaymentsStorage } from "src/payments/PaymentsStorage.sol";

/**
 * @title Payments Facet contract.
 * @dev This facet exposes functionality to easily allow users to accept payments in ERC20 tokens or gas tokens (ETH, MATIC, etc.)
 *      Users can also pay in a token amount priced in USD, other ERC20, or gas tokens.
 */
contract PaymentsFacet is ReentrancyGuardUpgradeable, FacetInitializable, Modifiers, IPayments {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    /**
     * @dev Initialize the facet. Can be called externally or internally.
     * Ideally referenced in an initialization script facet
     */
    function PaymentsFacet_init(
        address _gasTokenUSDPriceFeed,
        address _magicAddress
    ) public facetInitializer(keccak256("PaymentsFacet_init")) {
        LibPayments.setGasTokenUSDPriceFeed(_gasTokenUSDPriceFeed);
        LibPayments.setMagicAddress(_magicAddress);
    }

    /**
     * @inheritdoc IPayments
     */
    function makeStaticERC20Payment(
        address _recipient,
        address _paymentERC20,
        uint256 _paymentAmount
    ) external nonReentrant onlyReceiver(_recipient) {
        _sendERC20(_recipient, _paymentERC20, _paymentAmount, _paymentAmount, PriceType.STATIC, address(0));
    }

    /**
     * @inheritdoc IPayments
     */
    function makeStaticGasTokenPayment(
        address _recipient,
        uint256 _paymentAmount
    ) external payable nonReentrant onlyReceiver(_recipient) {
        _sendGasToken(_recipient, _paymentAmount, _paymentAmount, PriceType.STATIC, address(0));
    }

    /**
     * @inheritdoc IPayments
     */
    function makeERC20PaymentByPriceType(
        address _recipient,
        address _paymentERC20,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external nonReentrant onlyReceiver(_recipient) {
        if (
            _priceType == PriceType.STATIC || (_priceType == PriceType.PRICED_IN_ERC20 && _pricedERC20 == _paymentERC20)
        ) {
            _sendERC20(
                _recipient,
                _paymentERC20,
                _paymentAmountInPricedToken,
                _paymentAmountInPricedToken,
                PriceType.STATIC,
                address(0)
            );
            return;
        }
        ERC20Info storage _baseInfo = LibPayments.getERC20Info(_paymentERC20);
        AggregatorV3Interface _priceFeed;

        if (_priceType == PriceType.PRICED_IN_USD) {
            _priceFeed = _baseInfo.usdAggregator;
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            _priceFeed = _baseInfo.priceFeeds[_pricedERC20];
        } else if (_priceType == PriceType.PRICED_IN_GAS_TOKEN) {
            _priceFeed = _baseInfo.pricedInGasTokenAggregator;
        } else {
            revert PaymentsStorage.InvalidPriceType();
        }
        if (address(_priceFeed) == address(0)) {
            revert PaymentsStorage.NonexistantPriceFeed(_paymentERC20, _priceType, _pricedERC20);
        }

        uint256 _price = _pricedTokenToPaymentAmount(_paymentAmountInPricedToken, _priceFeed, _baseInfo.decimals);

        _sendERC20(_recipient, _paymentERC20, _price, _paymentAmountInPricedToken, _priceType, _pricedERC20);
    }

    /**
     * @inheritdoc IPayments
     */
    function makeGasTokenPaymentByPriceType(
        address _recipient,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external payable nonReentrant onlyReceiver(_recipient) {
        if (_priceType == PriceType.STATIC || _priceType == PriceType.PRICED_IN_GAS_TOKEN) {
            if (msg.value != _paymentAmountInPricedToken) {
                revert PaymentsStorage.IncorrectPaymentAmount();
            }
            _sendGasToken(
                _recipient, _paymentAmountInPricedToken, _paymentAmountInPricedToken, PriceType.STATIC, address(0)
            );
            return;
        }
        AggregatorV3Interface _priceFeed;

        if (_priceType == PriceType.PRICED_IN_USD) {
            _priceFeed = LibPayments.getGasTokenUSDPriceFeed();
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            _priceFeed = LibPayments.getGasTokenERC20PriceFeed(_pricedERC20);
        } else {
            revert PaymentsStorage.InvalidPriceType();
        }
        if (address(_priceFeed) == address(0)) {
            revert PaymentsStorage.NonexistantPriceFeed(address(0), _priceType, _pricedERC20);
        }

        uint256 _price = _pricedTokenToPaymentAmount(
            _paymentAmountInPricedToken,
            _priceFeed,
            18 // GasToken assumed to have 18 decimals (ETH, MATIC, etc.)
        );

        _sendGasToken(_recipient, _price, _paymentAmountInPricedToken, _priceType, _pricedERC20);
    }

    /**
     * @inheritdoc IPayments
     */
    function initializeERC20(
        address _erc20,
        uint8 _decimals,
        address _pricedInGasTokenAggregator,
        address _usdAggregator,
        address[] calldata _pricedERC20s,
        address[] calldata _priceFeeds
    ) external onlyRole(ADMIN_ROLE) {
        uint256 _numQuotes = _pricedERC20s.length;
        LibUtilities.requireArrayLengthMatch(_numQuotes, _priceFeeds.length);
        ERC20Info storage _info = LibPayments.getERC20Info(_erc20);
        _info.decimals = _decimals;
        _info.pricedInGasTokenAggregator = AggregatorV3Interface(_pricedInGasTokenAggregator);
        _info.usdAggregator = AggregatorV3Interface(_usdAggregator);
        for (uint256 i = 0; i < _numQuotes; i++) {
            _info.priceFeeds[_pricedERC20s[i]] = AggregatorV3Interface(_priceFeeds[i]);
        }
    }

    /**
     * @inheritdoc IPayments
     */
    function setERC20PriceFeedForERC20(
        address _erc20,
        address _pricedERC20,
        address _priceFeed
    ) external onlyRole(ADMIN_ROLE) {
        ERC20Info storage _info = LibPayments.getERC20Info(_erc20);
        _info.priceFeeds[_pricedERC20] = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @inheritdoc IPayments
     */
    function setERC20PriceFeedForGasToken(address _pricedERC20, address _priceFeed) external onlyRole(ADMIN_ROLE) {
        LibPayments.setGasTokenERC20PriceFeed(_pricedERC20, _priceFeed);
    }

    /**
     * @inheritdoc IPayments
     */
    function getMagicAddress() external view override returns (address magicAddress_) {
        magicAddress_ = LibPayments.getMagicAddress();
    }

    /**
     * @inheritdoc IPayments
     */
    function isValidPriceType(
        address _paymentToken,
        PriceType _priceType,
        address _pricedERC20
    ) external view override returns (bool supported_) {
        if (
            _priceType == PriceType.STATIC || (_priceType == PriceType.PRICED_IN_ERC20 && _pricedERC20 == _paymentToken)
                || (_priceType == PriceType.PRICED_IN_GAS_TOKEN && _paymentToken == address(0))
        ) {
            return true;
        }
        AggregatorV3Interface _priceFeed = _getPriceFeed(_paymentToken, _pricedERC20, _priceType);
        return address(_priceFeed) != address(0);
    }

    /**
     * @inheritdoc IPayments
     */
    function calculatePaymentAmountByPriceType(
        address _paymentToken,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedToken
    ) external view override returns (uint256 paymentAmount_) {
        if (
            _priceType == PriceType.STATIC || (_priceType == PriceType.PRICED_IN_ERC20 && _pricedToken == _paymentToken)
                || (_priceType == PriceType.PRICED_IN_GAS_TOKEN && _paymentToken == address(0))
        ) {
            return _paymentAmountInPricedToken;
        }
        AggregatorV3Interface _priceFeed = _getPriceFeed(_paymentToken, _pricedToken, _priceType);
        if (address(_priceFeed) == address(0)) {
            revert PaymentsStorage.NonexistantPriceFeed(_paymentToken, _priceType, _pricedToken);
        }
        // GasToken conversion, assume 18 decimals
        if (_paymentToken == address(0)) {
            paymentAmount_ = _pricedTokenToPaymentAmount(_paymentAmountInPricedToken, _priceFeed, 18);
        } else {
            ERC20Info storage _baseInfo = LibPayments.getERC20Info(_paymentToken);
            paymentAmount_ = _pricedTokenToPaymentAmount(_paymentAmountInPricedToken, _priceFeed, _baseInfo.decimals);
        }
    }

    /**
     * @dev Sends payment and invokes the acceptance function on the recipient
     */
    function _sendERC20(
        address _recipient,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) internal {
        IERC20Upgradeable(_paymentERC20).safeTransferFrom(LibMeta._msgSender(), _recipient, _paymentAmount);
        IPaymentsReceiver(_recipient).acceptERC20(
            LibMeta._msgSender(), _paymentERC20, _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20
        );
        emit PaymentSent(LibMeta._msgSender(), _paymentERC20, _paymentAmount, _recipient);
    }

    /**
     * @dev Sends gas token payment and invokes the acceptance function on the recipient
     */
    function _sendGasToken(
        address _recipient,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) internal {
        if (msg.value < _paymentAmount) {
            revert PaymentsStorage.IncorrectPaymentAmount();
        }
        uint256 _overpayment;
        if (msg.value > _paymentAmount) {
            _overpayment = msg.value - _paymentAmount;
        }
        IPaymentsReceiver(_recipient).acceptGasToken{ value: _paymentAmount }(
            LibMeta._msgSender(), _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20
        );
        // Send back overpayments
        if (_overpayment > 0) {
            payable(LibMeta._msgSender()).sendValue(_overpayment);
        }
        emit PaymentSent(LibMeta._msgSender(), address(0), _paymentAmount, _recipient);
    }

    function _getPriceFeed(
        address _paymentToken,
        address _pricedToken,
        PriceType _priceType
    ) internal view returns (AggregatorV3Interface priceFeed_) {
        bool _baseIsGasToken = _paymentToken == address(0);
        if (_priceType == PriceType.PRICED_IN_USD) {
            priceFeed_ = _baseIsGasToken
                ? LibPayments.getGasTokenUSDPriceFeed()
                : LibPayments.getERC20Info(_paymentToken).usdAggregator;
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            priceFeed_ = _baseIsGasToken
                ? LibPayments.getGasTokenERC20PriceFeed(_pricedToken)
                : LibPayments.getERC20Info(_paymentToken).priceFeeds[_pricedToken];
        } else if (_priceType == PriceType.PRICED_IN_GAS_TOKEN) {
            priceFeed_ = LibPayments.getERC20Info(_paymentToken).pricedInGasTokenAggregator;
        } else {
            priceFeed_ = AggregatorV3Interface(address(0));
        }
    }

    /**
     * @dev returns the given _price in the given decimal format after converting the _price into the related value from the _price feed
     * @param _paymentAmountInPricedToken The _price to convert to the value from the given _price feed
     * @param _priceFeed The _price feed to use to convert the _price
     * @param _paymentDecimals The number of decimals to format the _price as
     * @return paymentAmount_ The _price in the given decimal format
     */
    function _pricedTokenToPaymentAmount(
        uint256 _paymentAmountInPricedToken,
        AggregatorV3Interface _priceFeed,
        uint8 _paymentDecimals
    ) internal view returns (uint256 paymentAmount_) {
        //  Because fixed precision is e18, value will be 5494505494505494505 and needs to be converted to payment token decimal
        // NOTE: It is assumed that the  _paymentAmountInPricedToken and the _price feed's _price are in the same decimal unit
        UD60x18 _priceFP = ud(_paymentAmountInPricedToken).div(ud(uint256(_getQuotePrice(_priceFeed))));
        // Lastly, we must convert the _price into the payment token's decimal amount
        if (_paymentDecimals > 18) {
            // Add digits equal to the difference of fp's 18 decimals and the payment token's decimals
            paymentAmount_ = _priceFP.unwrap() * 10 ** (_paymentDecimals - 18);
        } else {
            // Remove digits equal to the difference of fp's 18 decimals and the payment token's decimals
            paymentAmount_ = _priceFP.unwrap() / 10 ** (18 - _paymentDecimals);
        }
    }

    /**
     * @dev returns the current relative value of the given _price feed
     * @param _priceFeed The _price feed to get the _price of
     * @return price_ The current relative _price of the given _price feed
     */
    function _getQuotePrice(AggregatorV3Interface _priceFeed) internal view returns (uint256 price_) {
        (, int256 _quotePrice,,,) = _priceFeed.latestRoundData();
        // Unfortunately no way to determine this ahead of time, and likely will never occur, but is a possibility of the oracle
        if (_quotePrice < 0) {
            revert PaymentsStorage.InvalidPriceFeedQuote(address(_priceFeed), address(0));
        }
        price_ = uint256(_quotePrice);
    }

    modifier onlyReceiver(address _recipient) {
        if (!_recipient.isContract()) {
            revert PaymentsStorage.NonPaymentsReceiverRecipient(_recipient);
        }
        try IERC165Upgradeable(_recipient).supportsInterface(type(IPaymentsReceiver).interfaceId) returns (
            bool isSupported_
        ) {
            if (!isSupported_) {
                revert PaymentsStorage.NonPaymentsReceiverRecipient(_recipient);
            }
        } catch (bytes memory) {
            revert PaymentsStorage.NonPaymentsReceiverRecipient(_recipient);
        }

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC165Upgradeable } from "@openzeppelin/contracts-diamond/utils/introspection/IERC165Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/IERC20Upgradeable.sol";

import { FacetInitializable } from "src/utils/FacetInitializable.sol";
import { LibMeta } from "src/libraries/LibMeta.sol";

import { IPayments, PriceType } from "src/interfaces/IPayments.sol";
import { IPaymentsReceiver } from "src/interfaces/IPaymentsReceiver.sol";
import { PaymentsReceiverStorage } from "src/payments/PaymentsReceiverStorage.sol";

/**
 * @title Payments Receiver contract.
 * @dev This facet exposes functionality to easily allow developers to accept payments in ERC20 tokens or gas
 *      tokens (ETH, MATIC, etc.). Developers can also accept payment in a token amount priced in USD, other ERC20, or gas tokens.
 */
contract PaymentsReceiver is FacetInitializable, IPaymentsReceiver, IERC165Upgradeable {
    /**
     * @dev Initialize the facet. Must be called before any other functions.
     */
    function PaymentsReceiver_init(address _spellcasterPayments)
        public
        facetInitializer(keccak256("PaymentsReceiver"))
    {
        PaymentsReceiverStorage.layout().spellcasterPayments = IPayments(_spellcasterPayments);
    }

    /**
     * @inheritdoc IPaymentsReceiver
     */
    function acceptERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external override onlySpellcasterPayments {
        emit PaymentReceived(
            _payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20
        );

        if (
            _priceType == PriceType.STATIC || (_priceType == PriceType.PRICED_IN_ERC20 && _pricedERC20 == _paymentERC20)
        ) {
            if (_paymentAmount != _paymentAmountInPricedToken) {
                revert PaymentsReceiverStorage.IncorrectPaymentAmount(_paymentAmount, _paymentAmountInPricedToken);
            }
            if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptStaticMagicPayment(_payor, _paymentAmount);
            } else {
                _acceptStaticERC20Payment(_payor, _paymentERC20, _paymentAmount);
            }
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            if (_pricedERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptERC20PaymentPricedInMagic(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken);
            } else if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptMagicPaymentPricedInERC20(_payor, _paymentAmount, _pricedERC20, _paymentAmountInPricedToken);
            } else {
                _acceptERC20PaymentPricedInERC20(
                    _payor, _paymentERC20, _paymentAmount, _pricedERC20, _paymentAmountInPricedToken
                );
            }
        } else if (_priceType == PriceType.PRICED_IN_USD) {
            if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptMagicPaymentPricedInUSD(_payor, _paymentAmount, _paymentAmountInPricedToken);
            } else {
                _acceptERC20PaymentPricedInUSD(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken);
            }
        } else if (_priceType == PriceType.PRICED_IN_GAS_TOKEN) {
            if (_paymentERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptMagicPaymentPricedInGasToken(_payor, _paymentAmount, _paymentAmountInPricedToken);
            } else {
                _acceptERC20PaymentPricedInGasToken(_payor, _paymentERC20, _paymentAmount, _paymentAmountInPricedToken);
            }
        } else {
            revert PaymentsReceiverStorage.PaymentTypeNotAccepted("ERC20");
        }
    }

    /**
     * @inheritdoc IPaymentsReceiver
     */
    function acceptGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _paymentAmountInPricedToken,
        PriceType _priceType,
        address _pricedERC20
    ) external payable override onlySpellcasterPayments {
        emit PaymentReceived(_payor, address(0), _paymentAmount, _paymentAmountInPricedToken, _priceType, _pricedERC20);

        if (msg.value != _paymentAmount) {
            revert PaymentsReceiverStorage.IncorrectPaymentAmount(msg.value, _paymentAmountInPricedToken);
        }
        if (_priceType == PriceType.STATIC) {
            if (msg.value != _paymentAmountInPricedToken || _paymentAmount != _paymentAmountInPricedToken) {
                revert PaymentsReceiverStorage.IncorrectPaymentAmount(msg.value, _paymentAmountInPricedToken);
            }
            _acceptStaticGasTokenPayment(_payor, msg.value);
        } else if (_priceType == PriceType.PRICED_IN_ERC20) {
            if (_pricedERC20 == PaymentsReceiverStorage.layout().spellcasterPayments.getMagicAddress()) {
                _acceptGasTokenPaymentPricedInMagic(_payor, _paymentAmount, _paymentAmountInPricedToken);
            } else {
                _acceptGasTokenPaymentPricedInERC20(_payor, _paymentAmount, _pricedERC20, _paymentAmountInPricedToken);
            }
        } else if (_priceType == PriceType.PRICED_IN_USD) {
            _acceptGasTokenPaymentPricedInUSD(_payor, _paymentAmount, _paymentAmountInPricedToken);
        } else {
            revert PaymentsReceiverStorage.PaymentTypeNotAccepted("Gas Token");
        }
    }

    function _acceptStaticMagicPayment(address _payor, uint256 _paymentAmount) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("MAGIC ", string(abi.encode(_payor, _paymentAmount)))
        );
    }

    function _acceptMagicPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("MAGIC / USD ", string(abi.encode(_payor, _paymentAmount, _priceInUSD)))
        );
    }

    function _acceptMagicPaymentPricedInGasToken(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInGasToken
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("MAGIC / GAS TOKEN ", string(abi.encode(_payor, _paymentAmount, _priceInGasToken)))
        );
    }

    function _acceptMagicPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("MAGIC / ERC20 ", string(abi.encode(_payor, _paymentAmount, _pricedERC20, _priceInERC20)))
        );
    }

    function _acceptGasTokenPaymentPricedInMagic(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInMagic
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN / MAGIC ", string(abi.encode(_payor, _paymentAmount, _priceInMagic)))
        );
    }

    function _acceptStaticERC20Payment(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("ERC20 ", string(abi.encode(_payor, _paymentERC20, _paymentAmount)))
        );
    }

    function _acceptERC20PaymentPricedInERC20(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat(
                "ERC20 / ERC20 ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _pricedERC20, _priceInERC20))
            )
        );
    }

    function _acceptERC20PaymentPricedInUSD(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("ERC20 / USD ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _priceInUSD)))
        );
    }

    function _acceptERC20PaymentPricedInMagic(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInMagic
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("ERC20 / MAGIC ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _priceInMagic)))
        );
    }

    function _acceptERC20PaymentPricedInGasToken(
        address _payor,
        address _paymentERC20,
        uint256 _paymentAmount,
        uint256 _priceInGasToken
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat(
                "ERC20 / GAS TOKEN ", string(abi.encode(_payor, _paymentERC20, _paymentAmount, _priceInGasToken))
            )
        );
    }

    function _acceptStaticGasTokenPayment(address _payor, uint256 _paymentAmount) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN ", string(abi.encode(_payor, _paymentAmount)))
        );
    }

    function _acceptGasTokenPaymentPricedInUSD(
        address _payor,
        uint256 _paymentAmount,
        uint256 _priceInUSD
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN / USD ", string(abi.encode(_payor, _paymentAmount, _priceInUSD)))
        );
    }

    function _acceptGasTokenPaymentPricedInERC20(
        address _payor,
        uint256 _paymentAmount,
        address _pricedERC20,
        uint256 _priceInERC20
    ) internal virtual {
        revert PaymentsReceiverStorage.PaymentTypeNotAccepted(
            string.concat("GAS TOKEN / ERC20 ", string(abi.encode(_payor, _paymentAmount, _pricedERC20, _priceInERC20)))
        );
    }

    /**
     * @dev Enables external contracts to query if this contract implements the IPaymentsReceiver interface.
     *      Needed for compliant implementation of Spellcaster Payments.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IPaymentsReceiver).interfaceId || _interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev Modifier to make a function callable only by the Spellcaster Payments contract.
     */
    modifier onlySpellcasterPayments() {
        if (LibMeta._msgSender() != address(PaymentsReceiverStorage.layout().spellcasterPayments)) {
            revert PaymentsReceiverStorage.SenderNotSpellcasterPayments(LibMeta._msgSender());
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IPayments, ERC20Info, PriceType } from "src/interfaces/IPayments.sol";

/**
 * @title PaymentsReceiverStorage library
 * @notice This library contains the storage layout and events/errors for the PaymentsReceiver contract.
 */
library PaymentsReceiverStorage {
    struct Layout {
        IPayments spellcasterPayments;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.payments.receiver");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    /**
     * @dev Emitted when an incorrect payment amount is provided.
     * @param amount The provided payment amount
     * @param price The expected payment amount (price)
     */
    error IncorrectPaymentAmount(uint256 amount, uint256 price);

    /**
     * @dev Emitted when the sender is not a valid spellcaster payment address.
     * @param sender The address of the sender attempting the action
     */
    error SenderNotSpellcasterPayments(address sender);

    /**
     * @dev Emitted when a non-accepted payment type is provided.
     * @param paymentType The provided payment type
     */
    error PaymentTypeNotAccepted(string paymentType);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IPayments, ERC20Info, PriceType } from "src/interfaces/IPayments.sol";

/**
 * @title PaymentsStorage library
 * @notice This library contains the storage layout and events/errors for the PaymentsFacet contract.
 */
library PaymentsStorage {
    struct Layout {
        /**
         * @dev Input address: An ERC20 token address
         *      Output: The ERC20 token information, including price feeds and decimals
         */
        mapping(address => ERC20Info) erc20ToInfo;
        /**
         * @dev The gas token price feed for USD
         */
        AggregatorV3Interface gasTokenUSDPriceFeed;
        /**
         * @dev The address of the $MAGIC contract
         */
        address magicAddress;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.payments");

    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }

    /**
     * @dev Emitted when a price feed is not found for a token or gas token
     * @param paymentToken The payment ERC20 token or address(0) if gas token
     * @param priceType The type of the token or gas token pair
     * @param pricedToken The address of the token or gas token pair to the `paymentToken`
     */
    error NonexistantPriceFeed(address paymentToken, PriceType priceType, address pricedToken);

    /**
     * @dev Emitted when a type is given that hasn't been implemented
     */
    error InvalidPriceType();

    /**
     * @dev Emitted when a payment is made with an incorrect amount
     */
    error IncorrectPaymentAmount();

    /**
     * @dev Emitted when a payment recipient doesn't implement the PaymentsReceiver interface
     * @param recipient The address of the invalid recipient
     */
    error NonPaymentsReceiverRecipient(address recipient);

    /**
     * @dev Emitted when a price feed returns a zero value.
     * @param paymentToken The base token address
     * @param pricedToken The token address to get a quote for
     */
    error InvalidPriceFeedQuote(address paymentToken, address pricedToken);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-diamond/proxy/utils/Initializable.sol";
import { PausableStorage } from "@openzeppelin/contracts-diamond/security/PausableStorage.sol";
import { FacetInitializable } from "../utils/FacetInitializable.sol";

import { ADMIN_ROLE } from "../libraries/LibAccessControlRoles.sol";
import { Modifiers } from "../Modifiers.sol";

/**
 * @title Pausable facet wrapper for OZ's pausable contract.
 * @dev Using this facet ensures that contracts that depend on pausability can reference the internal functions via Modifiers.sol
 * @notice Exposes the paused() function for the diamond
 */
contract PausableFacet is FacetInitializable, Modifiers {
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return PausableStorage.layout()._paused;
    }

    function setPause(bool _shouldPause) external onlyRole(ADMIN_ROLE) {
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibSpellcasterGM } from "../libraries/LibSpellcasterGM.sol";
import { ISpellcasterGM } from "../interfaces/ISpellcasterGM.sol";

contract SpellcasterGM is ISpellcasterGM {
    /**
     * @inheritdoc ISpellcasterGM
     */
    function addTrustedSigner(address _account) external {
        LibSpellcasterGM.setTrustedSigner(_account, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SpellcasterGMStorage {
    struct Layout {
        /**
         * @dev Mapping of addres to bool, whether the account is a trusted signer
         */
        mapping(address => bool) trustedSigners;
        /**
         * @dev Mapping of address to uint to bool, whether an accounts nonce has been used.
         */
        mapping(address => mapping(uint256 => bool)) trustedSignersToNonceToUsed;
    }

    bytes32 internal constant FACET_STORAGE_POSITION = keccak256("spellcaster.storage.gamemaster");

    /**
     * @dev Returns the state struct at this storage slot
     */
    function layout() internal pure returns (Layout storage l_) {
        bytes32 _position = FACET_STORAGE_POSITION;
        assembly {
            l_.slot := _position
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC1155HolderUpgradeable } from
    "@openzeppelin/contracts-diamond/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { IERC1155Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC1155/IERC1155Upgradeable.sol";
import { IERC1155Consumer } from "./interfaces/IERC1155Consumer.sol";
import { StakingStorage, ERC721TokenStorageData } from "./libraries/StakingStorage.sol";

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct WithdrawRequest {
    address tokenAddress;
    address reciever;
    uint256 tokenId;
    uint256 amount;
    uint256 nonce;
    bool stored;
    Signature signature;
}

contract StakingERC1155 is ERC1155HolderUpgradeable {
    event ERC1155Deposited(address tokenAddress, address depositor, address reciever, uint256 tokenId, uint256 amount);
    event ERC1155Withdrawn(address tokenAddress, address reciever, uint256 tokenId, uint256 amount);

    function initialize() external initializer { }

    function depositERC1155(
        address _tokenAddress,
        address _reciever,
        uint256[] memory _tokenIds,
        uint256[] memory _quantities
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            //Require dey own it.
            require(
                IERC1155Upgradeable(_tokenAddress).balanceOf(msg.sender, _tokenIds[i]) == _quantities[i],
                "You don't own these tokens"
            );

            //Yoink it.
            IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
                msg.sender, address(this), _tokenIds[i], _quantities[i], ""
            );

            //Store it.
            StakingStorage.setERC1155TokensStored(
                _tokenAddress,
                _tokenIds[i],
                _reciever,
                _quantities[i] + StakingStorage.getERC1155TokensStored(_tokenAddress, _tokenIds[i], _reciever)
            );

            emit ERC1155Deposited(_tokenAddress, msg.sender, _reciever, _tokenIds[i], _quantities[i]);
        }
    }

    function verifyHash(bytes32 _hash, Signature calldata _signature) internal pure returns (address) {
        bytes32 _messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));

        return ecrecover(_messageDigest, _signature.v, _signature.r, _signature.s);
    }

    function withdrawERC1155(WithdrawRequest[] calldata _withdrawRequests) public {
        for (uint256 i = 0; i < _withdrawRequests.length; i++) {
            WithdrawRequest calldata _withdrawRequest = _withdrawRequests[i];
            address _tokenAddress = _withdrawRequest.tokenAddress;

            uint256 _ERC1155Stored =
                StakingStorage.getERC1155TokensStored(_tokenAddress, _withdrawRequest.tokenId, msg.sender);

            if (_withdrawRequest.stored) {
                //It's stored in the contract
                //Permissioned by chain

                require(_ERC1155Stored >= _withdrawRequest.amount, "Not enough balance of this item.");

                //Store it.
                StakingStorage.setERC721TokenStorageData(
                    _tokenAddress, _withdrawRequest.tokenId, ERC721TokenStorageData(address(0), false)
                );

                StakingStorage.setERC1155TokensStored(
                    _tokenAddress, _withdrawRequest.tokenId, msg.sender, _ERC1155Stored - _withdrawRequest.amount
                );

                //Send it back.
                IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
                    address(this), _withdrawRequest.reciever, _withdrawRequest.tokenId, _withdrawRequest.amount, ""
                );

                emit ERC1155Withdrawn(
                    _tokenAddress, _withdrawRequest.reciever, _withdrawRequest.tokenId, _withdrawRequest.amount
                );
            } else {
                //Not stored
                //Permissioned by admin

                //Compute that sig is correct
                //verifyHash returns the signer of this message.
                //message is a hash of three pieces of data: nonce, tokenAddress, tokenId, and the user.
                address _signer = verifyHash(
                    keccak256(
                        abi.encodePacked(
                            _withdrawRequest.nonce,
                            _withdrawRequest.tokenAddress,
                            _withdrawRequest.tokenId,
                            _withdrawRequest.amount,
                            _withdrawRequest.reciever
                        )
                    ),
                    _withdrawRequest.signature
                );

                //Require they are a valid signer.
                require(IERC1155Consumer(_tokenAddress).isAdmin(_signer), "Not a valid signed message.");

                //Make sure they aren't using sig twice.
                require(!StakingStorage.getUsedNonce(_withdrawRequest.nonce), "Nonce already used.");

                //Store nonce as used.
                StakingStorage.setUsedNonce(_withdrawRequest.nonce, true);

                //Mint the token
                IERC1155Consumer(_tokenAddress).mintFromWorld(
                    _withdrawRequest.reciever, _withdrawRequest.tokenId, _withdrawRequest.amount
                );

                emit ERC1155Withdrawn(
                    _tokenAddress, _withdrawRequest.reciever, _withdrawRequest.tokenId, _withdrawRequest.amount
                );
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-diamond/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC20/IERC20Upgradeable.sol";
import { StakingStorage } from "./libraries/StakingStorage.sol";
import { IERC20Consumer } from "./interfaces/IERC20Consumer.sol";

struct ERC20TokenStorageData {
    address owner;
    bool stored;
}

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct WithdrawRequest {
    address tokenAddress;
    address reciever;
    uint256 amount;
    uint256 nonce;
    bool stored;
    Signature signature;
}

contract StakingERC20 is Initializable {
    event ERC20Deposited(address tokenAddress, address depositor, address reciever, uint256 amount);
    event ERC20Withdrawn(address tokenAddress, address reciever, uint256 amount);

    function initialize() external initializer { }

    function depositERC20(address _tokenAddress, address _reciever, uint256 _amount) public {
        //Yoink it.
        IERC20Upgradeable(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

        //Store it.
        StakingStorage.setERC20TokensStored(_tokenAddress, _reciever, _amount);

        emit ERC20Deposited(_tokenAddress, msg.sender, _reciever, _amount);
    }

    function verifyHash(bytes32 _hash, Signature calldata _signature) internal pure returns (address) {
        bytes32 _messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));

        return ecrecover(_messageDigest, _signature.v, _signature.r, _signature.s);
    }

    function withdrawERC20(WithdrawRequest[] calldata _withdrawRequests) public {
        for (uint256 i = 0; i < _withdrawRequests.length; i++) {
            WithdrawRequest calldata _withdrawRequest = _withdrawRequests[i];
            address _tokenAddress = _withdrawRequest.tokenAddress;

            uint256 _amountStored = StakingStorage.getERC20TokensStored(_tokenAddress, msg.sender);

            if (_withdrawRequest.stored) {
                //It's stored in the contract
                //Permissioned by chain

                require(_amountStored >= _withdrawRequest.amount, "Not enough stored to withdraw.");

                StakingStorage.setERC20TokensStored(_tokenAddress, msg.sender, _amountStored - _withdrawRequest.amount);

                //Send it back
                IERC20Upgradeable(_tokenAddress).transfer(msg.sender, _withdrawRequest.amount);

                emit ERC20Withdrawn(_tokenAddress, _withdrawRequest.reciever, _withdrawRequest.amount);
            } else {
                //Not stored
                //Permissioned by admin

                //Compute that sig is correct
                //verifyHash returns the signer of this message.
                //message is a hash of three pieces of data: nonce, tokenAddress, amount, and the user.
                address _signer = verifyHash(
                    keccak256(
                        abi.encodePacked(
                            _withdrawRequest.nonce,
                            _withdrawRequest.tokenAddress,
                            _withdrawRequest.amount,
                            _withdrawRequest.reciever
                        )
                    ),
                    _withdrawRequest.signature
                );

                //Require they are a valid signer.
                require(IERC20Consumer(_tokenAddress).isAdmin(_signer), "Not a valid signed message.");

                //Make sure they aren't using sig twice.
                require(!StakingStorage.getUsedNonce(_withdrawRequest.nonce), "Nonce already used.");

                //Store nonce as used.
                StakingStorage.setUsedNonce(_withdrawRequest.nonce, true);

                //Mint the token
                IERC20Consumer(_tokenAddress).mintFromWorld(_withdrawRequest.reciever, _withdrawRequest.amount);

                emit ERC20Withdrawn(_tokenAddress, _withdrawRequest.reciever, _withdrawRequest.amount);
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-diamond/proxy/utils/Initializable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC721/IERC721Upgradeable.sol";
import { IERC721Consumer } from "./interfaces/IERC721Consumer.sol";
import { StakingStorage, ERC721TokenStorageData } from "./libraries/StakingStorage.sol";

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct WithdrawRequest {
    address tokenAddress;
    address reciever;
    uint256 tokenId;
    uint256 nonce;
    bool stored;
    Signature signature;
}

contract StakingERC721 is Initializable {
    event ERC721Deposited(address tokenAddress, address depositor, address reciever, uint256 tokenId);
    event ERC721Withdrawn(address tokenAddress, address reciever, uint256 tokenId);

    function initialize() external initializer { }

    function depositERC721(address _tokenAddress, address _reciever, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            //Require dey own it.
            require(IERC721Upgradeable(_tokenAddress).ownerOf(_tokenIds[i]) == msg.sender, "You don't own these tokens");

            //Yoink it.
            IERC721Upgradeable(_tokenAddress).transferFrom(msg.sender, address(this), _tokenIds[i]);

            //Store it.
            StakingStorage.setERC721TokenStorageData(
                _tokenAddress, _tokenIds[i], ERC721TokenStorageData(_reciever, true)
            );

            emit ERC721Deposited(_tokenAddress, msg.sender, _reciever, _tokenIds[i]);
        }
    }

    function verifyHash(bytes32 _hash, Signature calldata _signature) internal pure returns (address) {
        bytes32 _messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));

        return ecrecover(_messageDigest, _signature.v, _signature.r, _signature.s);
    }

    function withdrawERC721(WithdrawRequest[] calldata _withdrawRequests) public {
        for (uint256 i = 0; i < _withdrawRequests.length; i++) {
            WithdrawRequest calldata _withdrawRequest = _withdrawRequests[i];
            address _tokenAddress = _withdrawRequest.tokenAddress;

            ERC721TokenStorageData memory _ERC721TokenStorageData =
                StakingStorage.getERC721TokenStorageData(_tokenAddress, _withdrawRequest.tokenId);

            if (_withdrawRequest.stored) {
                //It's stored in the contract
                //Permissioned by chain

                require(_ERC721TokenStorageData.owner == _withdrawRequest.reciever, "You didn't store this ERC721.");

                //Store it.
                StakingStorage.setERC721TokenStorageData(
                    _tokenAddress, _withdrawRequest.tokenId, ERC721TokenStorageData(address(0), false)
                );

                //Send it back.
                IERC721Upgradeable(_tokenAddress).transferFrom(
                    address(this), _withdrawRequest.reciever, _withdrawRequest.tokenId
                );

                emit ERC721Withdrawn(_tokenAddress, _withdrawRequest.reciever, _withdrawRequest.tokenId);
            } else {
                //Not stored
                //Permissioned by admin

                //Compute that sig is correct
                //verifyHash returns the signer of this message.
                //message is a hash of three pieces of data: nonce, tokenAddress, tokenId, and the user.
                address _signer = verifyHash(
                    keccak256(
                        abi.encodePacked(
                            _withdrawRequest.nonce,
                            _withdrawRequest.tokenAddress,
                            _withdrawRequest.tokenId,
                            _withdrawRequest.reciever
                        )
                    ),
                    _withdrawRequest.signature
                );

                //Require they are a valid signer.
                require(IERC721Consumer(_tokenAddress).isAdmin(_signer), "Not a valid signed message.");

                //Make sure they aren't using sig twice.
                require(!StakingStorage.getUsedNonce(_withdrawRequest.nonce), "Nonce already used.");

                //Store nonce as used.
                StakingStorage.setUsedNonce(_withdrawRequest.nonce, true);

                //Mint the token
                IERC721Consumer(_tokenAddress).mintFromWorld(_withdrawRequest.reciever, _withdrawRequest.tokenId);

                emit ERC721Withdrawn(_tokenAddress, _withdrawRequest.reciever, _withdrawRequest.tokenId);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC1155Upgradeable } from "@openzeppelin/contracts-diamond/token/ERC1155/ERC1155Upgradeable.sol";
import { FacetInitializable } from "../utils/FacetInitializable.sol";
import { SupportsMetaTx } from "src/metatx/SupportsMetaTx.sol";

/**
 * @title ERC1155 facet wrapper for OZ's pausable contract.
 * @dev Use/inherit this facet to limit the spread of third-party dependency references and allow new functionality to be shared
 */
abstract contract ERC1155Facet is FacetInitializable, SupportsMetaTx, ERC1155Upgradeable {
    function __ERC1155Facet_init(string memory uri_) internal onlyFacetInitializing {
        ERC1155Upgradeable.__ERC1155_init(uri_);
    }

    // =============================================================
    //                        Override functions
    // =============================================================

    /**
     * @dev Overrides ERC1155Ugradeable and passes through to it.
     *  This is to have multiple inheritance overrides to be from this repo instead of OZ
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @dev Adding support for meta transactions
     */
    function setApprovalForAll(address _operator, bool _approved) public virtual override supportsMetaTxNoId {
        super.setApprovalForAll(_operator, _approved);
    }

    /**
     * @dev Adding support for meta transactions
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public virtual override supportsMetaTxNoId {
        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    /**
     * @dev Adding support for meta transactions
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual override supportsMetaTxNoId {
        super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUpgradeable } from "@openzeppelin/contracts-diamond/utils/AddressUpgradeable.sol";
import { InitializableStorage } from "@openzeppelin/contracts-diamond/proxy/utils/InitializableStorage.sol";
import { FacetInitializableStorage } from "./FacetInitializableStorage.sol";
import { LibUtilities } from "../libraries/LibUtilities.sol";

/**
 * @title Initializable using DiamondStorage pattern and supporting facet-specific initializers
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract FacetInitializable {
    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     * Name changed to prevent collision with OZ contracts
     */
    modifier facetInitializer(bytes32 _facetId) {
        // Allow infinite constructor initializations to support multiple inheritance.
        // Otherwise, this contract/facet must not have been previously initialized.
        if (
            InitializableStorage.layout()._initializing
                ? !_isConstructor()
                : FacetInitializableStorage.getState().initialized[_facetId]
        ) {
            revert FacetInitializableStorage.AlreadyInitialized(_facetId);
        }
        bool _isTopLevelCall = !InitializableStorage.layout()._initializing;
        // Always set facet initialized regardless of if top level call or not.
        // This is so that we can run through facetReinitializable() if needed, and lower level functions can protect themselves
        FacetInitializableStorage.getState().initialized[_facetId] = true;

        if (_isTopLevelCall) {
            InitializableStorage.layout()._initializing = true;
        }

        _;

        if (_isTopLevelCall) {
            InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to trick internal functions that use onlyInitializing / onlyFacetInitializing into thinking
     *  that the contract is being initialized.
     *  This should only be called via a diamond initialization script and makes a lot of assumptions.
     *  Handle with care.
     */
    modifier facetReinitializable() {
        InitializableStorage.layout()._initializing = true;
        _;
        InitializableStorage.layout()._initializing = false;
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyFacetInitializing() {
        require(InitializableStorage.layout()._initializing, "FacetInit: not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Storage to track facets in a diamond that have been initialized.
 * Needed to prevent accidental re-initializations
 * Name changed to prevent collision with OZ contracts
 * OZ's Initializable storage handles all of the _initializing state, which isn't facet-specific
 */
library FacetInitializableStorage {
    error AlreadyInitialized(bytes32 facetId);

    struct Layout {
        /*
         * @dev Indicates that the contract/facet has been initialized.
         * bytes32 is the contract/facetId (keccak of the contract name)
         * bool is whether or not the contract/facet has been initialized
         */
        mapping(bytes32 => bool) initialized;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("spellcaster.storage.utils.FacetInitializable");

    function getState() internal pure returns (Layout storage l_) {
        bytes32 _position = STORAGE_SLOT;
        assembly {
            l_.slot := _position
        }
    }

    function isInitialized(bytes32 _facetId) internal view returns (bool isInitialized_) {
        isInitialized_ = getState().initialized[_facetId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { FacetInitializableStorage } from "../utils/FacetInitializableStorage.sol";

/**
 * @title Contract to check Facet initialization state
 * @dev Only Facets using the FacetInitializable contract will be tracked here
 */
contract InitializedFacet {
    function isInitialized(bytes32 _facetId) public view returns (bool isInitialized_) {
        return FacetInitializableStorage.isInitialized(_facetId);
    }
}