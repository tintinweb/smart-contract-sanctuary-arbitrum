// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
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
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
        return _roles[role].members[account];
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
        _roles[role].adminRole = adminRole;
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
            _roles[role].members[account] = true;
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
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
 * ```
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
library StorageSlotUpgradeable {
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
import "../../staking/IUnlimitedStaking.sol";

pragma solidity ^0.8.0;

interface IStakingDepositNFTDesign{
    function buildTokenURI(
        uint tokenId,
        IUnlimitedStaking.UserInfo memory user,
        uint256 pendingRewards,
        uint256 userMultiplier,
        IUnlimitedStaking.EpochInfo memory epoch,
        uint256 currentEpochNumber,
        string memory assetSymbol,
        uint8 numberInputDecimals,
        uint8 numberOutputDecimals
    ) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import "./design/IStakingDepositNFTDesign.sol";
import "../staking/IUnlimitedStaking.sol";

/// @title IStakingDepositNFT interface for ERC721 staking deposit NFTs
/// @notice This contract defines the interface for staking deposit NFTs, which represent locked tokens in a staking contract.
interface IStakingDepositNFT is
    IERC165Upgradeable,
    IERC721EnumerableUpgradeable
{
    /// ERC165 bytes to add to interface array - set in parent contract
    ///
    /// _INTERFACE_ID_ERC4494 = 0x5604e225

    /// @notice Approves a spender to transfer an NFT on behalf of the owner, using a signed permit.
    /// @param spender The address to approve as a spender.
    /// @param tokenId The ID of the NFT to approve the spender on.
    /// @param deadline A timestamp that specifies the permit's expiration.
    /// @param sig A traditional or EIP-2098 signature.
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory sig
    ) external;

    /// @notice Returns the nonce of an NFT, which is useful for creating permits.
    /// @param tokenId The ID of the NFT to get the nonce of.
    /// @return The uint256 representation of the nonce.
    function nonces(uint256 tokenId) external view returns (uint256);

    /// @notice Returns the domain separator used in the encoding of the signature for permits, as defined by EIP-712.
    /// @return The bytes32 domain separator.
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Updates the NFT design with a new design.
    /// @param newValue The new design for the NFT.
    function updateDesign(IStakingDepositNFTDesign newValue) external;

    /// @notice Sets the UWUStaking contract.
    /// @param unlimitedStaking The UnlimitedStaking contract.
    function setUWUStaking(IUnlimitedStaking unlimitedStaking) external;

    /// @notice Updates the design decimals with a new value.
    /// @param newValue The new value for the design decimals.
    function updateDesignDecimals(uint8 newValue) external;

    /// @notice Mints a new NFT.
    /// @param to The address to mint the NFT to.
    /// @param tokenId The ID of the NFT to be minted.
    function mint(address to, uint tokenId) external;

    /// @notice Burns an existing NFT.
    /// @param tokenId The ID of the NFT to be burned.
    function burn(uint tokenId) external;

    /**
     * @notice Safe permit and transfer from.
     * @param from The address to approve as a spender.
     * @param to The address to approve as a spender.
     * @param tokenId The ID of the NFT to approve the spender on.
     * @param _data Data to send along with a safe transfer check.
     * @param deadline A timestamp that specifies the permit's expiration.
     * @param signature A traditional or EIP-2098 signature.
     */
    function safeTransferFromWithPermit(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data,
        uint256 deadline,
        bytes memory signature
    ) external;

    /// @notice Returns the URI of the specified NFT.
    /// @param tokenId The ID of the NFT to get the URI of.
    /// @return The string representation of the NFT's URI.
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IRewardWallet
 * @dev Interface for the RewardWallet contract, which holds tokens as a reward wallet
 * and allows for safe transfers to recipients. Only the owner or an authorized contract
 * can transfer tokens from this wallet.
 */
interface IRewardWallet {
    event TokensTransferred(address indexed to, uint256 amount);
    event UpdatedAuthorizedContract(address indexed newAuthorizedContract);
    event UpdatedTokenAddress(address indexed newTokenAddress);

    /**
     * @dev Sets the authorized contract address that can initiate transfers.
     * @param _authorizedContract The address of the contract to be authorized.
     */
    function setAuthorizedContract(address _authorizedContract) external;

    /**
     * @dev Sets the token address for the wallet.
     * @param _tokenAddress The address of the token to be managed by the wallet.
     */
    function setTokenAddress(address _tokenAddress) external;

    /**
     * @dev Returns the token address.
     * @return The address of the token managed by the wallet.
     */
    function getTokenAddress() external view returns (address);

    /**
     * @dev Safely transfers tokens from the wallet to the specified recipient.
     * Only the owner or an authorized contract can initiate transfers.
     * @param _to The address of the recipient.
     * @param _amount The amount of tokens to be transferred.
     */
    function safeTransfer(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IUnlimitedStaking
 * @notice Interface for the Unlimited Staking contract.
 * The UnlimitedStaking contract is a smart contract that allows users to stake their 
 * UWU tokens in order to earn rewards. The contract consists of several parts, including 
 * epochs, rewards, and user information. Epochs represent different staking options, each
 * lock period its unique multiplier. Users can deposit their UWU tokens
 * into a epoch and receive boosted shares, which are used to calculate their share of the
 * epoch's rewards.
 */
interface IUnlimitedStaking {
    /// @notice Info of each UnlimitedStaking epoch.
    /// `accRewardPerShare` The accumulated static reward per share (boosted amount) in the epoch.
    /// `accDynamicRewardPerShare` The accumulated dynamic reward (instantly calculated by balanceOf) per share (boosted amount) in the epoch.
    /// `endTime` The timestamp when the epoch ends.
    /// `totalCurrentBoostedShare` The total boosted share (staking amount multiplied by boost multiplier) for the current epoch.
    /// `totalNextBoostedShare` The total boosted share (staking amount multiplied by boost multiplier) for the next epoch.
    /// `totalNextResetBoostedShare` The total amount of boosted share to be reset in the next epoch.
    /// `totalAmountStaked` The total amount staked in the current epoch.
    /// `isUpdated` A flag indicating whether the epoch has been updated or not.
    ///
    /// There are two types of rewards: static rewards and dynamic rewards.
    /// Static rewards are distributed based on a predetermined rate, while dynamic 
    /// rewards are distributed based on the amount of UWU tokens held in a 
    /// separate dynamic rewards wallet.
    ///
    ///   Whenever a user deposits or withdraws UWU tokens to a pool. Here's what happens:
    ///   1. The pool's `accRewardPerShare`, `accDynamicRewardPerShare` gets updated.
    ///   1. The reward's `lastDynamicRewardBalance` gets updated.
    ///   3. User's `amount` gets updated. Reward's `totalNextBoostedShare` gets updated.
    struct EpochInfo {
        uint256 accRewardPerShare; // Accumulated reward per share
        uint256 accDynamicRewardPerShare; // Accumulated dynamic reward per share
        uint256 endTime; // End time of the epoch
        uint256 totalCurrentBoostedShare; // Total boosted share in the current epoch
        uint256 totalNextBoostedShare; // Total boosted share in the next epoch
        uint256 totalNextResetBoostedShare; // Total boosted share in the next reset epoch
        uint256 totalAmountStaked; // Total amount staked in the epoch
        bool isUpdated; // Whether the epoch has been updated
    }

    /// @notice Struct representing user information.
    struct UserInfo {
        uint256 amount; // Amount staked
        uint256 multiplier; // Multiplier of the stake
        uint256 resetEpoch; // Epoch at which the stake multiplier will reset
        uint256 lockPeriod; // Lock period of the stake
        uint256 depositDate; // Date when the stake was deposited
        uint256 withdrawEpoch; // Epoch at which the stake was requested to withdraw
        uint256 lastClaimEpoch; // Epoch at which the stake was last claimed
        uint256 compoundEpoch; // Epoch at which the stake was last compounded
        uint256 lastCompoundDelta; // Amount of tokens compounded since the last compound which will be activate in next epoch
    }

    /// @notice Struct representing reward information.
    struct RewardInfo {
        uint256 totalAmountStatic; // Total amount of static reward
        uint256 startEpoch; // Start epoch of the reward
        uint256 endEpoch; // End epoch of the reward
    }

    /// @notice Struct representing dynamic reward information.
    struct DynamicRewardInfo {
        uint256 totalRewardDept; // Total reward debt
        uint256 lastBalance; // Last balance of the reward pool
        uint256 lastBalanceUpdateTime; // Time when the last balance was updated
        uint256 startEpoch; // Start epoch of the reward
        uint256 endEpoch; // End epoch of the reward
    }

    event EpochUpdated(uint256 indexed epochNumber, uint256 accRewardPerShare);
    event EpochChanged(uint256 indexed epochNumber, uint256 totalCurrentBoostedShare, uint256 totalAmountStaked);
    event StaticRewardAdded(uint256 amount, uint256 startEpoch, uint256 endEpoch);
    event DynamicRewardAdded(uint256 startEpoch, uint256 endEpoch);
    event LockPeriodAdded(uint256 lockPeriod, uint256 multiplier);
    event LockPeriodEdited(uint256 lockPeriod, uint256 multiplier);
    event LockPeriodRemoved(uint256 lockPeriod);
    event Deposited(uint256 indexed tokenId, uint256 amount, uint256 lockPeriod, uint256 multiplier, uint256 epochNumber);
    event Claimed(uint256 indexed tokenId, address indexed user, uint256 amount);
    event WithdrawalRequested(uint256 indexed tokenId, address indexed user, uint256 epochNumber);
    event Withdraw(uint256 indexed tokenId, address indexed user, uint256 epochNumber);
    event Compounded(uint256 indexed tokenId, uint256 amount, uint256 epochNumber);

    /**
     * @notice Add static reward to the contract.
     * @param _amount Amount of tokens to add.
     * @param _startEpoch Start epoch of the reward.
     * @param _endEpoch End epoch of the reward.
     */
    function addStaticReward(
        uint256 _amount,
        uint256 _startEpoch,
        uint256 _endEpoch
    ) external;

    /**
     * @notice Add dynamic reward to the contract.
     * @param _startEpoch Start epoch of the reward.
     * @param _endEpoch End epoch of the reward.
     */
    function addDynamicReward(uint256 _startEpoch, uint256 _endEpoch) external;

    /**
     * @notice Add a new lock period.
     * @param _lockPeriod Lock period of the stake.
     * @param _multiplier Multiplier of the stake.
     */
    function addLockPeriod(uint256 _lockPeriod, uint256 _multiplier) external;

    /**
     * @notice Edit an existing lock period.
     * @param _lockPeriod New lock period of the stake.
     * @param _multiplier New multiplier of the stake.
     */
    function editLockPeriod(uint256 _lockPeriod, uint256 _multiplier) external;

    /**
     * @notice Remove an existing lock period.
     * @param _lockPeriod Lock period of the stake to remove.
     */
    function removeLockPeriod(uint256 _lockPeriod) external;

    /**
     * @dev Updates the information related to the current epoch.
     *
     * This function performs the following actions:
     * - If the current epoch has not been updated, it updates the accumulated static reward per share.
     * - Updates the accumulated dynamic reward per share.
     * - Sets the 'isUpdated' flag for the current epoch to true.
     * - If the current epoch has ended, it initializes the next epoch with the appropriate values.
     *
     * @return currentEpoch - The updated EpochInfo struct for the current epoch.
    */
    function updateEpoch() external returns (EpochInfo memory);

    /**
     * @notice Deposit tokens and create a new stake.
     *
     * This function performs the following actions:
     * - Updates the current epoch information.
     * - Transfers the tokens from the user to the contract.
     * - Creates a new UserInfo struct for the user's deposit.
     * - Mints a new NFT representing the stake.
     * - Updates the total boosted share for the epoch.
     *   it sets a reset epoch for the user's stake and updates the total next reset boosted share.
     *
     * @param _amount Amount of tokens to deposit.
     * @param _lockPeriod Lock period for the stake in epochs.
    */
    function deposit(uint256 _amount, uint256 _lockPeriod) external;

    /**
     * @notice Deposit tokens with a permit and create a new stake.
     * @param _amount Amount of tokens to deposit.
     * @param _lockPeriod Lock period for the stake in epochs.
     * @param _depositOwner Owner of the deposit.
     * @param _value Value of the permit.
     * @param _deadline Deadline for the permit.
     * @param _v Recovery byte of the permit signature.
     * @param _r First 32 bytes of the permit signature.
     * @param _s Second 32 bytes of the permit signature.
     */
    function depositPermit(
        uint256 _amount,
        uint256 _lockPeriod,
        address _depositOwner,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Claim the pending rewards for a specific stake represented by the token ID.
     *
     * This function performs the following actions:
     * - Updates the current epoch information.
     * - Verifies that the caller is the owner, has been approved, or has been granted approval for all.
     * - Ensures that the last claimed epoch is less than the current epoch.
     * - Settles the pending rewards for the stake.
     * - Updates the user's last claimed epoch to the current epoch.
     *
     * @param _tokenId The token ID representing the stake for which to claim rewards.
    */
    function claim(uint256 _tokenId) external;

    /**
     * @notice Claim rewards for all provided token IDs.
     * @param _tokenIds Array of token IDs to claim rewards for.
     */
    function claimAll(uint256[] memory _tokenIds) external;

    /**
    * @notice Request the withdrawal of a stake represented by the token ID.
     *
     * This function performs the following actions:
     * - Verifies that the caller is the owner, has been approved, or has been granted approval for all.
     * - Updates the current epoch information.
     * - Ensures that the current epoch number is greater than or equal to the user's last claimed epoch.
     * - Ensures that the current time is greater than unlock time.
     * - Sets the withdraw epoch for the user to the next epoch.
     * - Decreases the total boosted shares and total staked amount for the current epoch.
     *
     * @param _tokenId The token ID representing the stake for which to request a withdrawal.
    */
    function withdrawRequest(uint256 _tokenId) external;

    /**
     * @notice Withdraw tokens for a specific token ID.
     * @param _tokenId Token ID to withdraw tokens for.
     */
    function withdraw(uint256 _tokenId) external;

    /**
     * @notice Compound rewards for a specific token ID.
     * @param _tokenId Token ID to compound rewards for.
     */
    function compound(uint256 _tokenId) external;

    /**
     * @notice Compound rewards for all provided token IDs.
     * @param _tokenIds Array of token IDs to compound rewards for.
     */
    function compoundAll(uint256[] memory _tokenIds) external;

    /**
     * @notice Get the total number of static rewards.
     * @return rewards Total number of static rewards.
     */
    function rewardLength() external view returns (uint256 rewards);

    /**
     * @notice Get the static reward amount per epoch for a specific reward ID.
     * @param _uwuRewardId Reward ID to get the static reward amount for.
     * @return amount Static reward amount per epoch.
     */
    function uwuStaticPerBlock(
        uint256 _uwuRewardId
    ) external view returns (uint256 amount);

    /**
     * @notice Get the user's pending rewards for a specific token ID.
     * @param _tokenId Token ID to get pending rewards for.
     * @return amount Pending rewards amount.
     */
    function userPendingRewards(
        uint256 _tokenId
    ) external view returns (uint256 amount);

    /**
     * @notice Get the user's reward for a specific token ID and epoch.
     * @param _tokenId Token ID to get the reward for.
     * @param _epoch Epoch to get the reward for.
     * @return Reward amount for the specified token ID and epoch.
     */
    function getUserRewardForEpoch(
        uint256 _tokenId,
        uint256 _epoch
    ) external view returns (uint256);

    /**
     * @notice Get the user's staking information for a specific token ID.
     * @param _tokenId Token ID to get the user's staking information for.
     * @return userInfo Struct containing the user's staking information.
     */
    function getUserInfo(
        uint256 _tokenId
    ) external view returns (UserInfo memory);

    /**
     * @notice Get the user's multiplier for a specific token ID.
     * @param _tokenId Token ID to get the user's multiplier for.
     * @return multiplier The multiplier for the specified token ID.
     */
    function getUserMultiplier(
        uint256 _tokenId
    ) external view returns (uint256 multiplier);

    /**
     * @notice Get the information of the current epoch.
     * @return epochInfo Struct containing the current epoch's information.
     */
    function getCurrentEpochInfo() external view returns (EpochInfo memory);

    /**
     * @notice Get current epoch number.
     * @return currentEpochNumber Number of the current epoch.
     */
    function getCurrentEpochNumber() external view returns (uint256);

    /**
     * @notice Get the reward information for a specific reward ID.
     * @param _rewardId Reward ID to get the reward information for.
     * @return rewardInfo Struct containing the reward information for the specified reward ID.
     */
    function getRewardInfo(
        uint256 _rewardId
    ) external view returns (RewardInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IUnlimitedStaking.sol";
import "../reward-wallet/IRewardWallet.sol";
import "../deposit-nft/IStakingDepositNFT.sol";


/// @title UnlimitedStaking
/// @notice The UnlimitedStaking contract is a smart contract that allows users to stake their 
/// UWU tokens in order to earn rewards. The contract consists of several parts, including 
/// epochs, rewards, and user information. Epochs represent different staking options, each
/// lock period its unique multiplier. Users can deposit their UWU tokens
/// into a epoch and receive boosted shares, which are used to calculate their share of the
/// epoch's rewards.
contract UnlimitedStaking is IUnlimitedStaking, AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Address of UWU contract.
    IERC20Upgradeable public UWU;
    /// @notice Address of UWU Locked Deposit NFT.
    IStakingDepositNFT public uwuStakingNft;
    /// @notice Total count deposits of all time. Define UWU Locked Deposit NFT Id.
    uint256 public lockedDepositsCount;

    IRewardWallet public uwuStaticRewardWallet;
    IRewardWallet public uwuDynamicRewardWallet;

    RewardInfo[] public rewardInfo;
    DynamicRewardInfo public dynamicRewardInfo;

    mapping(uint256 => EpochInfo) public epochInfo;
    uint256 public currentEpochNumber;
    uint256 public epochPeriod;  

    mapping(uint256 => UserInfo) public userInfo;
    mapping(uint256 => uint256) public lockPeriodMultiplier;
    uint256[] public lockPeriods;

    uint256 public constant ACC_UWU_PRECISION = 1e18;

    /// @notice Basic boost factor, none boosted user's boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;
    /// @notice Hard limit for maxmium boost factor, it must greater than BOOST_PRECISION
    uint256 public constant MAX_BOOST_PRECISION = 200 * 1e10;

    bytes32 public constant INITIALIZER_FIRST_EPOCH_ROLE = keccak256("INITIALIZER_FIRST_EPOCH_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");
    bytes32 public constant LOCK_PERIOD_MANAGER_ROLE = keccak256("LOCK_PERIOD_MANAGER_ROLE");

    modifier onlyDepositOwner(uint256 _tokenId) {
        address depositOwner = uwuStakingNft.ownerOf(_tokenId);
        require(
            depositOwner == msg.sender ||
            uwuStakingNft.getApproved(_tokenId) == msg.sender ||
            uwuStakingNft.isApprovedForAll(depositOwner, msg.sender),
            "Not the owner or approved"
        );
        _;
    }

    function initialize(
        IERC20Upgradeable _UWU,
        IStakingDepositNFT _uwuNft,
        IRewardWallet _uwuStaticRewardWallet,
        IRewardWallet _uwuDynamicRewardWallet,
        uint256 _epochPeriod
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INITIALIZER_FIRST_EPOCH_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(REWARD_MANAGER_ROLE, msg.sender);
        _grantRole(LOCK_PERIOD_MANAGER_ROLE, msg.sender);

        UWU = _UWU;
        uwuStakingNft = _uwuNft;
        uwuStaticRewardWallet = _uwuStaticRewardWallet;
        uwuDynamicRewardWallet = _uwuDynamicRewardWallet;
        epochPeriod = _epochPeriod;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function initializeFirstEpoch() external onlyRole(INITIALIZER_FIRST_EPOCH_ROLE) {
        require(currentEpochNumber == 0, "Current epoch must be zero");
        uint256 lockSupply = epochInfo[currentEpochNumber].totalNextBoostedShare;
        uint256 totalAmountStaked = epochInfo[currentEpochNumber].totalAmountStaked;

        currentEpochNumber++;
        epochInfo[currentEpochNumber].totalCurrentBoostedShare = lockSupply;
        epochInfo[currentEpochNumber].totalNextBoostedShare = lockSupply;
        epochInfo[currentEpochNumber].totalAmountStaked = totalAmountStaked;
        epochInfo[currentEpochNumber].endTime = block.timestamp.add(epochPeriod);
        
        updateEpoch();
    }

    /**
     * @notice Get the total number of static rewards.
     * @return rewards Total number of static rewards.
     */
    function rewardLength() public view override returns (uint256 rewards) {
        rewards = rewardInfo.length;
    }

    /**
     * @notice Add static reward to the contract.
     * @param _amount Amount of tokens to add.
     * @param _startEpoch Start epoch of the reward.
     * @param _endEpoch End epoch of the reward.
     */
    function addStaticReward(
        uint256 _amount,
        uint256 _startEpoch,
        uint256 _endEpoch
    ) external override onlyRole(REWARD_MANAGER_ROLE) {
        updateEpoch();
        require(_startEpoch > currentEpochNumber, "Start must be > than current");
        require(_endEpoch > _startEpoch, "End must be > than start");
        require(_amount > 0, "Amount must be greater than 0");

        rewardInfo.push(
            RewardInfo({
                totalAmountStatic: _amount,
                startEpoch: _startEpoch,
                endEpoch: _endEpoch
            })
        );

        emit StaticRewardAdded(_amount, _startEpoch, _endEpoch);
    }

    /**
     * @notice Add dynamic reward to the contract.
     * @param _startEpoch Start epoch of the reward.
     * @param _endEpoch End epoch of the reward.
     */
    function addDynamicReward(
        uint256 _startEpoch,
        uint256 _endEpoch
    ) external override onlyRole(REWARD_MANAGER_ROLE) {
        updateEpoch();
        require(_startEpoch > currentEpochNumber, "Start must be > than current");
        require(_endEpoch > _startEpoch, "End must be > than start");
        require(currentEpochNumber > dynamicRewardInfo.endEpoch, "Already initialized");

        dynamicRewardInfo.totalRewardDept = 0;
        dynamicRewardInfo.lastBalance = UWU.balanceOf(address(uwuDynamicRewardWallet));
        dynamicRewardInfo.lastBalanceUpdateTime = block.timestamp;
        dynamicRewardInfo.startEpoch = _startEpoch;
        dynamicRewardInfo.endEpoch = _endEpoch;

        emit DynamicRewardAdded(_startEpoch, _endEpoch);
    }

    /**
     * @notice Add a new lock period.
     * @param _lockPeriod Lock period of the stake.
     * @param _multiplier Multiplier of the stake.
     */
    function addLockPeriod(
        uint256 _lockPeriod,
        uint256 _multiplier
    ) external override onlyRole(LOCK_PERIOD_MANAGER_ROLE) {
        require(_multiplier >= BOOST_PRECISION, "Multiplier must be >= to the min");
        require(_multiplier <= MAX_BOOST_PRECISION, "Multiplier must be <= to the max");
        require(lockPeriodMultiplier[_lockPeriod] == 0, "Lock period already exists");

        lockPeriodMultiplier[_lockPeriod] = _multiplier;
        lockPeriods.push(_lockPeriod);

        emit LockPeriodAdded(_lockPeriod, _multiplier);
    }

    /**
     * @notice Edit an existing lock period.
     * @param _lockPeriod New lock period of the stake.
     * @param _multiplier New multiplier of the stake.
     */
    function editLockPeriod(
        uint256 _lockPeriod,
        uint256 _multiplier
    ) external override onlyRole(LOCK_PERIOD_MANAGER_ROLE) {
        require(_multiplier >= BOOST_PRECISION, "Multiplier must be >= to the min");
        require(_multiplier <= MAX_BOOST_PRECISION, "Multiplier must be <= to the max");
        require(lockPeriodMultiplier[_lockPeriod] != 0, "Lock period does not exist");

        lockPeriodMultiplier[_lockPeriod] = _multiplier;

        emit LockPeriodEdited(_lockPeriod, _multiplier);
    }

    /**
     * @notice Remove an existing lock period.
     * @param _lockPeriod Lock period of the stake to remove.
     */
    function removeLockPeriod(uint256 _lockPeriod) external override onlyRole(LOCK_PERIOD_MANAGER_ROLE) {
        require(lockPeriodMultiplier[_lockPeriod] != 0, "Lock period does not exist");

        uint256 indexToRemove = lockPeriods.length;
        for (uint256 i = 0; i < lockPeriods.length; i++) {
            if (lockPeriods[i] == _lockPeriod) {
                indexToRemove = i;
                break;
            }
        }

        require(indexToRemove < lockPeriods.length, "Lock period not found in array");

        for (uint256 i = indexToRemove; i < lockPeriods.length - 1; i++) {
            lockPeriods[i] = lockPeriods[i + 1];
        }
        lockPeriods.pop();

        delete lockPeriodMultiplier[_lockPeriod];

        emit LockPeriodRemoved(_lockPeriod);
    }

    /**
     * @notice Get the static reward amount per epoch for a specific reward ID.
     * @param _uwuRewardId Reward ID to get the static reward amount for.
     * @return amount Static reward amount per epoch.
     */
    function uwuStaticPerBlock(uint256 _uwuRewardId) public view returns (uint256 amount) {
        RewardInfo memory reward = rewardInfo[_uwuRewardId]; 
        amount = reward.totalAmountStatic.div(reward.endEpoch.sub(reward.startEpoch));
    }

    /**
     * @notice Get the user's pending rewards for a specific token ID.
     * @param _tokenId Token ID to get pending rewards for.
     * @return amount Pending rewards amount.
     */
    function userPendingRewards(uint256 _tokenId) public view returns (uint256 amount) {
        UserInfo memory user = userInfo[_tokenId];
        (uint256 earliestUnclaimedEpoch, uint256 intervalMultiplier, uint256 latestUnclaimedEpoch) =
            calculateUnclaimedEpochIntervals(user.withdrawEpoch, user.resetEpoch, user.lastClaimEpoch, user.multiplier);

        (uint256 totalStaticUnclaimed, uint256 totalDynamicUnclaimed) =
            _calculateRewards(
                user.lastClaimEpoch,
                earliestUnclaimedEpoch,
                latestUnclaimedEpoch,
                user.compoundEpoch,
                user.lastCompoundDelta,
                user.amount,
                intervalMultiplier
            );

        return totalStaticUnclaimed.add(totalDynamicUnclaimed);
    }

    /**
     * @notice Get the user's reward for a specific token ID and epoch.
     * @param _tokenId Token ID to get the reward for.
     * @param _epoch Epoch to get the reward for.
     * @return Reward amount for the specified token ID and epoch.
     */
    function getUserRewardForEpoch(uint256 _tokenId, uint256 _epoch) public view override returns (uint256) {
        UserInfo memory user = userInfo[_tokenId];
        EpochInfo memory epoch = epochInfo[_epoch];

        if (epoch.endTime > user.depositDate.add(epochPeriod)) {
            uint256 userMultiplier = user.resetEpoch >= _epoch ? BOOST_PRECISION : user.multiplier;
            uint256 boostedAmount = user.amount.mul(userMultiplier).div(BOOST_PRECISION);
            uint256 totalStaticUnclaimed = boostedAmount.mul(epoch.accRewardPerShare).div(ACC_UWU_PRECISION);
            uint256 totalDynamicUnclaimed = boostedAmount.mul(epoch.accDynamicRewardPerShare).div(ACC_UWU_PRECISION);

            return totalStaticUnclaimed.add(totalDynamicUnclaimed);
        }

        return 0;
    }

    /**
     * @dev Updates the information related to the current epoch.
     *
     * This function performs the following actions:
     * - If the current epoch has not been updated, it updates the accumulated static reward per share.
     * - Updates the accumulated dynamic reward per share.
     * - Sets the 'isUpdated' flag for the current epoch to true.
     * - If the current epoch has ended, it initializes the next epoch with the appropriate values.
     *
     * @return currentEpoch - The updated EpochInfo struct for the current epoch.
    */
    function updateEpoch() public override whenNotPaused returns (EpochInfo memory) {
        EpochInfo memory currentEpoch = epochInfo[currentEpochNumber];
        uint256 lockSupply = currentEpoch.totalCurrentBoostedShare;

        if (lockSupply > 0) {
            if (!currentEpoch.isUpdated) {
                for (uint256 i = 0; i < rewardInfo.length; i++) {
                    RewardInfo memory reward = rewardInfo[i];
                    if (reward.startEpoch <= currentEpochNumber && reward.endEpoch > currentEpochNumber) {
                        uint256 uwuPerEpoch = reward.totalAmountStatic.div(reward.endEpoch.sub(reward.startEpoch));
                    
                        currentEpoch.accRewardPerShare = currentEpoch.accRewardPerShare.add((uwuPerEpoch.mul(ACC_UWU_PRECISION).div(lockSupply)));
                    }
                    emit EpochUpdated(currentEpochNumber, currentEpoch.accRewardPerShare);
                }
            }

            if (dynamicRewardInfo.startEpoch <= currentEpochNumber && dynamicRewardInfo.endEpoch > currentEpochNumber) {
                uint256 uwuDynamicBalance = UWU.balanceOf(address(uwuDynamicRewardWallet));
                uint256 uwuDynamicReward = uwuDynamicBalance.add(dynamicRewardInfo.totalRewardDept).sub(dynamicRewardInfo.lastBalance);
                currentEpoch.accDynamicRewardPerShare = currentEpoch.accDynamicRewardPerShare.add((uwuDynamicReward.mul(ACC_UWU_PRECISION).div(lockSupply)));

                dynamicRewardInfo.lastBalance = uwuDynamicBalance;
                dynamicRewardInfo.lastBalanceUpdateTime = block.timestamp;
            }
        }

        currentEpoch.isUpdated = true;
        epochInfo[currentEpochNumber] = currentEpoch;

        if (currentEpoch.endTime != 0 && block.timestamp > currentEpoch.endTime) {
            uint256 nextEpochNumber = ++currentEpochNumber;
            EpochInfo memory nextEpoch = epochInfo[nextEpochNumber];
            nextEpoch.endTime = currentEpoch.endTime.add(epochPeriod);
            nextEpoch.totalCurrentBoostedShare = currentEpoch.totalNextBoostedShare.sub(currentEpoch.totalNextResetBoostedShare);
            nextEpoch.totalNextBoostedShare = currentEpoch.totalNextBoostedShare.sub(currentEpoch.totalNextResetBoostedShare);
            nextEpoch.totalAmountStaked = currentEpoch.totalAmountStaked;
            
            epochInfo[nextEpochNumber] = nextEpoch;
            emit EpochChanged(nextEpochNumber, nextEpoch.totalCurrentBoostedShare, nextEpoch.totalAmountStaked);

            return updateEpoch();
        }

        return currentEpoch;
    }

    /**
     * @notice Deposit tokens and create a new stake.
     *
     * This function performs the following actions:
     * - Updates the current epoch information.
     * - Transfers the tokens from the user to the contract.
     * - Creates a new UserInfo struct for the user's deposit.
     * - Mints a new NFT representing the stake.
     * - Updates the total boosted share for the epoch.
     *   it sets a reset epoch for the user's stake and updates the total next reset boosted share.
     *
     * @param _amount Amount of tokens to deposit.
     * @param _lockPeriod Lock period for the stake in epochs.
    */
    function deposit(uint256 _amount, uint256 _lockPeriod) override external nonReentrant {
        _deposit(_amount, _lockPeriod, msg.sender);
    }

    function _deposit(uint256 _amount, uint256 _lockPeriod, address _owner) internal {
        require(_amount > 0, "Amount must be greater than 0");

        EpochInfo memory epoch = updateEpoch();
        uint256 multiplier = lockPeriodMultiplier[_lockPeriod];
        require(multiplier > 0, "Invalid lock period");

        uint256 before = UWU.balanceOf(address(this));
        UWU.safeTransferFrom(_owner, address(this), _amount);
        _amount = UWU.balanceOf(address(this)).sub(before);
        
        uint256 depositId = ++lockedDepositsCount;
        UserInfo storage user = userInfo[depositId];

        user.amount = _amount;
        user.depositDate = block.timestamp;
        user.multiplier = multiplier;
        user.lastClaimEpoch = currentEpochNumber + 1;
        user.lockPeriod = _lockPeriod;
        uwuStakingNft.mint(_owner, depositId);

        // Update total boosted share.
        uint256 userBoostedShare = _amount.mul(multiplier).div(BOOST_PRECISION);
        epoch.totalNextBoostedShare = epoch.totalNextBoostedShare.add(userBoostedShare);
        epoch.totalAmountStaked = epoch.totalAmountStaked.add(_amount);

        epochInfo[currentEpochNumber] = epoch;

        if (multiplier > BOOST_PRECISION && _lockPeriod > 0) {
            uint256 resetEpoch = _lockPeriod.div(epochPeriod).add(currentEpochNumber);
            user.resetEpoch = resetEpoch + 1;
            uint256 resetDelta = userBoostedShare.sub(_amount);
            epochInfo[resetEpoch].totalNextResetBoostedShare = epochInfo[resetEpoch].totalNextResetBoostedShare.add(resetDelta);
        }

        emit Deposited(depositId, _amount, _lockPeriod, multiplier, currentEpochNumber);
    }

    /**
     * @notice Deposit tokens with a permit and create a new stake.
     * @param _amount Amount of tokens to deposit.
     * @param _lockPeriod Lock period for the stake in epochs.
     * @param _depositOwner Owner of the deposit.
     * @param _value Value of the permit.
     * @param _deadline Deadline for the permit.
     * @param _v Recovery byte of the permit signature.
     * @param _r First 32 bytes of the permit signature.
     * @param _s Second 32 bytes of the permit signature.
     */
    function depositPermit(
        uint256 _amount, 
        uint256 _lockPeriod,
        address _depositOwner,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override nonReentrant {
        SafeERC20Upgradeable.safePermit(IERC20PermitUpgradeable(address(UWU)), _depositOwner, address(this), _value, _deadline, _v, _r, _s);

        _deposit(_amount, _lockPeriod, _depositOwner);
    }

    /**
     * @notice Claim rewards for all provided token IDs.
     * @param _tokenIds Array of token IDs to claim rewards for.
     */
    function claimAll(uint256[] memory _tokenIds) external override nonReentrant {
        updateEpoch();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _claim(_tokenIds[i]);
        }
    }

    /**
     * @notice Claim the pending rewards for a specific stake represented by the token ID.
     *
     * This function performs the following actions:
     * - Updates the current epoch information.
     * - Verifies that the caller is the owner, has been approved, or has been granted approval for all.
     * - Ensures that the last claimed epoch is less than the current epoch.
     * - Settles the pending rewards for the stake.
     * - Updates the user's last claimed epoch to the current epoch.
     *
     * @param _tokenId The token ID representing the stake for which to claim rewards.
    */
    function claim(uint256 _tokenId) external override nonReentrant {
        updateEpoch();
        _claim(_tokenId);        
    }

    function _claim(uint256 _tokenId) internal {
        address depositOwner = uwuStakingNft.ownerOf(_tokenId);

        require(depositOwner == msg.sender
            || uwuStakingNft.getApproved(_tokenId) == msg.sender
            || uwuStakingNft.isApprovedForAll(depositOwner, msg.sender), "Not the owner or approved");

        UserInfo storage user = userInfo[_tokenId];
        require(user.amount > 0, "User amount must be > 0");
        require(currentEpochNumber > user.lastClaimEpoch, "User last epoch number must be less than current epoch number");

        uint256 claimedAmount = settlePendingUwu(depositOwner, _tokenId);
        
        user.lastClaimEpoch = currentEpochNumber;
        userInfo[_tokenId] = user;

        emit Claimed(_tokenId, msg.sender, claimedAmount);
    }

    /**
    * @notice Request the withdrawal of a stake represented by the token ID.
     *
     * This function performs the following actions:
     * - Verifies that the caller is the owner, has been approved, or has been granted approval for all.
     * - Updates the current epoch information.
     * - Ensures that the current epoch number is greater than or equal to the user's last claimed epoch.
     * - Ensures that the current time is greater than unlock time.
     * - Sets the withdraw epoch for the user to the next epoch.
     * - Decreases the total boosted shares and total staked amount for the current epoch.
     *
     * @param _tokenId The token ID representing the stake for which to request a withdrawal.
    */
    function withdrawRequest(uint256 _tokenId) external override onlyDepositOwner(_tokenId) nonReentrant {
        EpochInfo memory epoch = updateEpoch();
        UserInfo storage user = userInfo[_tokenId];

        require(user.amount > 0, "Withdraw: Insufficient balance to withdraw");
        require(user.withdrawEpoch == 0, "Withdraw: A withdraw request has already been made for this deposit");
        require(currentEpochNumber >= user.lastClaimEpoch, "Withdraw: Cannot request before token is active");
        require(block.timestamp >= user.depositDate.add(user.lockPeriod), "Withdraw: Cannot request before the lock period is over");
        
        user.withdrawEpoch = currentEpochNumber + 1;
        epoch.totalNextBoostedShare = epoch.totalNextBoostedShare.sub(user.amount);
        epoch.totalAmountStaked = epoch.totalAmountStaked.sub(user.amount);

        epochInfo[currentEpochNumber] = epoch;
        userInfo[_tokenId] = user;

        emit WithdrawalRequested(_tokenId, msg.sender, currentEpochNumber);
    }

    /**
     * @notice Withdraw tokens for a specific token ID.
     * @param _tokenId Token ID to withdraw tokens for.
     */
    function withdraw(uint256 _tokenId) external override onlyDepositOwner(_tokenId) nonReentrant {
        updateEpoch();
        UserInfo storage user = userInfo[_tokenId];

        bool isRequsted = user.withdrawEpoch != 0 && currentEpochNumber >= user.withdrawEpoch;
        require(user.amount > 0, "Withdraw: Nothing to withdraw");
        require(
            isRequsted || user.lastClaimEpoch > currentEpochNumber, 
            "Withdraw: Invalid Epoch"
        );

        if (user.withdrawEpoch > user.lastClaimEpoch) {
            settlePendingUwu(msg.sender, _tokenId);
        }

        UWU.safeTransfer(msg.sender, user.amount);
        delete userInfo[_tokenId];
        uwuStakingNft.burn(_tokenId);

        emit Withdraw(_tokenId, msg.sender, currentEpochNumber);
    }

    /**
     * @notice Compound rewards for a specific token ID.
     * @param _tokenId Token ID to compound rewards for.
     */
    function compound(uint256 _tokenId) external override nonReentrant {
        updateEpoch();
        _compound(_tokenId);
    }

    /**
     * @notice Compound rewards for all provided token IDs.
     * @param _tokenIds Array of token IDs to compound rewards for.
     */
    function compoundAll(uint256[] memory _tokenIds) external override nonReentrant {
        updateEpoch();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _compound(_tokenIds[i]);
        }
    }

    function _compound(uint256 _tokenId) internal onlyDepositOwner(_tokenId) {
        EpochInfo memory epoch = epochInfo[currentEpochNumber];
        UserInfo storage user = userInfo[_tokenId];

        require(user.amount > 0, "Compound: Insufficient balance");
        require(user.withdrawEpoch == 0, "Compound: Withdraw initiated");
        require(currentEpochNumber > user.lastClaimEpoch, "Compound: Invalid epoch");

        uint256 depositAmount = settlePendingUwu(address(this), _tokenId);
        require(depositAmount > 0, "Compound: Reward amount must be greater than 0");

        user.amount = user.amount.add(depositAmount);
        user.compoundEpoch = currentEpochNumber;
        user.lastCompoundDelta = depositAmount;
        user.lastClaimEpoch = currentEpochNumber;

        // Update total boosted share
        bool isActiveMultiplier = user.resetEpoch > currentEpochNumber;
        uint256 userMultiplier = isActiveMultiplier ? user.multiplier : BOOST_PRECISION;
        uint256 userCompBoostedShare = depositAmount.mul(userMultiplier).div(BOOST_PRECISION);
        
        epoch.totalNextBoostedShare = epoch.totalNextBoostedShare.add(userCompBoostedShare);
        epoch.totalAmountStaked = epoch.totalAmountStaked.add(depositAmount);
        epochInfo[currentEpochNumber] = epoch;

        if (isActiveMultiplier) {
            uint256 resetDelta = userCompBoostedShare.sub(depositAmount);
            epochInfo[user.resetEpoch - 1].totalNextResetBoostedShare = epochInfo[user.resetEpoch - 1].totalNextResetBoostedShare.add(resetDelta);
        }

        emit Compounded(_tokenId, depositAmount, currentEpochNumber);
    }

    function setUwuStakingNft(IStakingDepositNFT _uwuStakingNft) external onlyRole(UPGRADER_ROLE) {
        uwuStakingNft = _uwuStakingNft;
    }

    function setStaticRewardWallet(IRewardWallet _staticRewardWallet) external onlyRole(UPGRADER_ROLE) {
        uwuStaticRewardWallet = _staticRewardWallet;
    }

    function setDynamicRewardWallet(IRewardWallet _dynamicRewardWallet) external onlyRole(UPGRADER_ROLE) {
        uwuDynamicRewardWallet = _dynamicRewardWallet;
    }

    /// @notice Settles, distribute the pending UWU rewards for given user.
    /// @param _user The user address for settling rewards.
    /// @param _tokenId The token id.
    function settlePendingUwu(
        address _user,
        uint256 _tokenId
    ) internal returns (uint256) {
        UserInfo memory user = userInfo[_tokenId];

        (uint256 earliestUnclaimedEpoch, uint256 intervalMultiplier, uint256 latestUnclaimedEpoch) =
            calculateUnclaimedEpochIntervals(user.withdrawEpoch, user.resetEpoch, user.lastClaimEpoch, user.multiplier);
        
        (uint256 totalStaticUnclaimed, uint256 totalDynamicUnclaimed) =
            _calculateRewards(
                user.lastClaimEpoch,
                earliestUnclaimedEpoch,
                latestUnclaimedEpoch,
                user.compoundEpoch,
                user.lastCompoundDelta,
                user.amount,
                intervalMultiplier
            );

        if (totalStaticUnclaimed > 0) {
            uwuStaticRewardWallet.safeTransfer(_user, totalStaticUnclaimed);
        }

        if (totalDynamicUnclaimed > 0) {
            dynamicRewardInfo.totalRewardDept = dynamicRewardInfo.totalRewardDept.add(totalDynamicUnclaimed);
            uwuStaticRewardWallet.safeTransfer(_user, totalDynamicUnclaimed);
        }

        return totalStaticUnclaimed.add(totalDynamicUnclaimed);
    }

    function _calculateRewards(
        uint256 fromEpoch,
        uint256 earliestUnclaimedEpoch,
        uint256 latestUnclaimedEpoch,
        uint256 compoundEpoch,
        uint256 lastCompoundDelta,
        uint256 amount,
        uint256 intervalMultiplier
    ) internal view returns (
        uint256 totalStaticUnclaimed,
        uint256 totalDynamicUnclaimed
    ) {
        bool isLastEpochCompound = compoundEpoch == fromEpoch;
        if (isLastEpochCompound && earliestUnclaimedEpoch > compoundEpoch) {
            (uint256 totalCompStaticUnclaimed, uint256 totalCompDynamicUnclaimed) = _calculateCompoundEpochRewards(
                amount, 
                intervalMultiplier, 
                fromEpoch, 
                fromEpoch + 1, 
                lastCompoundDelta
            );

            totalStaticUnclaimed = totalStaticUnclaimed.add(totalCompStaticUnclaimed);
            totalDynamicUnclaimed = totalDynamicUnclaimed.add(totalCompDynamicUnclaimed);
            fromEpoch++;
        }

        uint256 boostedAmount = amount.mul(intervalMultiplier).div(BOOST_PRECISION);
        (uint256 totalIntervalStaticUnclaimed, uint256 totalIntervalDynamicUnclaimed) = getAccumulatedRewards(fromEpoch, earliestUnclaimedEpoch, boostedAmount);
        totalStaticUnclaimed = totalStaticUnclaimed.add(totalIntervalStaticUnclaimed);
        totalDynamicUnclaimed = totalDynamicUnclaimed.add(totalIntervalDynamicUnclaimed);

        if (latestUnclaimedEpoch > 0) {

            // -----resetEpoch, compounEpoch, lastClaimEpoch------currentEpoch
            (uint256 totalStaticUnclaimedReseted, uint256 totalDynamicUnclaimedReseted) = _calculateResetEpochRewards(
                amount,
                earliestUnclaimedEpoch, 
                latestUnclaimedEpoch,
                compoundEpoch,
                lastCompoundDelta,
                isLastEpochCompound
            );

            totalStaticUnclaimed = totalStaticUnclaimed.add(totalStaticUnclaimedReseted);
            totalDynamicUnclaimed = totalDynamicUnclaimed.add(totalDynamicUnclaimedReseted);
        }

        return (totalStaticUnclaimed, totalDynamicUnclaimed);
    }

    function _calculateCompoundEpochRewards(
        uint256 amount,
        uint256 intervalMultiplier,
        uint256 fromEpoch,
        uint256 toEpoch,
        uint256 compoundDelta
    ) internal view returns (uint256, uint256) {
        uint256 boostedAmountSubDelta = amount.sub(compoundDelta).mul(intervalMultiplier).div(BOOST_PRECISION);
        return getAccumulatedRewards(fromEpoch, toEpoch, boostedAmountSubDelta);
    }

    function _calculateResetEpochRewards(
        uint256 amount,
        uint256 earliestUnclaimedEpoch,
        uint256 latestUnclaimedEpoch,
        uint256 compoundEpoch,
        uint256 compoundDelta,
        bool isLastEpochCompound
    ) internal view returns (uint256, uint256) {
        uint256 totalStaticUnclaimed;
        uint256 totalDynamicUnclaimed;
        if (isLastEpochCompound  && earliestUnclaimedEpoch == compoundEpoch && latestUnclaimedEpoch > earliestUnclaimedEpoch) {
            (uint256 totalCompStaticUnclaimed, uint256 totalCompDynamicUnclaimed) = _calculateCompoundEpochRewards(
                amount, 
                BOOST_PRECISION, 
                earliestUnclaimedEpoch, 
                earliestUnclaimedEpoch + 1, 
                compoundDelta
            );

            totalStaticUnclaimed = totalStaticUnclaimed.add(totalCompStaticUnclaimed);
            totalDynamicUnclaimed = totalDynamicUnclaimed.add(totalCompDynamicUnclaimed);
            earliestUnclaimedEpoch++;
        }

        (uint256 totalStaticUnclaimedReseted, uint256 totalDynamicUnclaimedReseted) = getAccumulatedRewards(
            earliestUnclaimedEpoch, 
            latestUnclaimedEpoch, 
            amount
        );

        return (totalStaticUnclaimed.add(totalStaticUnclaimedReseted), totalDynamicUnclaimed.add(totalDynamicUnclaimedReseted));
    }

    function getAccumulatedRewards(
        uint256 start, 
        uint256 end, 
        uint256 _boostedAmount
    ) internal view returns (
        uint256 totalStaticUnclaimed, 
        uint256 totalDynamicUnclaimed
    ) {
        for (uint256 i = start; i < end; i++) {
            EpochInfo memory epoch = epochInfo[i];
            totalStaticUnclaimed = totalStaticUnclaimed.add(_boostedAmount.mul(epoch.accRewardPerShare).div(ACC_UWU_PRECISION));
            totalDynamicUnclaimed = totalDynamicUnclaimed.add(_boostedAmount.mul(epoch.accDynamicRewardPerShare).div(ACC_UWU_PRECISION));
        }
        return (totalStaticUnclaimed, totalDynamicUnclaimed);
    }

    function calculateUnclaimedEpochIntervals(
        uint256 withdrawEpoch,
        uint256 resetEpoch,
        uint256 lastClaimEpoch,
        uint256 userMultiplier
    ) internal view returns (
        uint256 earliestUnclaimedEpoch,
        uint256 intervalMultiplier,
        uint256 latestUnclaimedEpoch
    ) {
        uint256 defaultEpoch = withdrawEpoch != 0 && withdrawEpoch <= currentEpochNumber ? withdrawEpoch : currentEpochNumber;

        if (lastClaimEpoch > resetEpoch) {
            earliestUnclaimedEpoch = defaultEpoch;
            intervalMultiplier = BOOST_PRECISION;
        } else if (currentEpochNumber > resetEpoch) {
            earliestUnclaimedEpoch = resetEpoch;
            intervalMultiplier = userMultiplier;
            latestUnclaimedEpoch = defaultEpoch;
        } else {
            earliestUnclaimedEpoch = currentEpochNumber;
            intervalMultiplier = userMultiplier;
        }
    }

    /**
     * @notice Get the information of the current epoch.
     * @return epochInfo Struct containing the current epoch's information.
     */
    function getCurrentEpochInfo() public view override returns (EpochInfo memory) {
        return epochInfo[currentEpochNumber];
    }

    /**
     * @notice Get current epoch number.
     * @return currentEpochNumber Number of the current epoch.
     */
    function getCurrentEpochNumber() public view override returns (uint256) {
        return currentEpochNumber;
    }

    /**
     * @notice Get the user's staking information for a specific token ID.
     * @param _tokenId Token ID to get the user's staking information for.
     * @return userInfo Struct containing the user's staking information.
     */
    function getUserInfo(uint256 _tokenId) public view override returns (UserInfo memory) {
        return userInfo[_tokenId];
    }

    /**
     * @notice Get the user's multiplier for a specific token ID.
     * @param _tokenId Token ID to get the user's multiplier for.
     * @return multiplier The multiplier for the specified token ID.
     */
    function getUserMultiplier(uint256 _tokenId) public view override returns (uint256 multiplier) {
        UserInfo memory user = userInfo[_tokenId];
        if (user.amount == 0) return 0;
        return user.resetEpoch > currentEpochNumber ? user.multiplier : BOOST_PRECISION;
    }

    /**
     * @notice Get the reward information for a specific reward ID.
     * @param _rewardId Reward ID to get the reward information for.
     * @return rewardInfo Struct containing the reward information for the specified reward ID.
     */
    function getRewardInfo(uint256 _rewardId) public view override returns (RewardInfo memory) {
        return rewardInfo[_rewardId];
    }
}